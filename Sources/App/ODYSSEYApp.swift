import os.log
import SwiftUI
import UserNotifications

/// Main application entry point for ODYSSEY
///
/// ODYSSEY is a macOS menu bar application that automates sports reservation bookings
/// for Ottawa Recreation facilities. It runs quietly in the background and automatically
/// books preferred sports slots at optimal times.
@main
struct ODYSSEYApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

/// App delegate to handle macOS-specific functionality
///
/// Manages the application lifecycle, status bar integration, and automated scheduling.
/// Handles background timer setup for reservation automation and notification permissions.
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var timer: Timer?
    private let logger = Logger(subsystem: "com.odyssey.app", category: "AppDelegate")

    func applicationDidFinishLaunching(_: Notification) {
        // Hide dock icon since this is a status bar app
        NSApp.setActivationPolicy(.accessory)

        // Initialize status bar controller
        statusBarController = StatusBarController()

        // Set up scheduling timer
        setupSchedulingTimer()

        // Request notification permissions
        requestNotificationPermissions()
    }

    func applicationWillTerminate(_: Notification) {
        // Clean up
        timer?.invalidate()
        timer = nil

        // Emergency cleanup for any running automation
        Task {
            await ReservationManager.shared.emergencyCleanup()
        }
    }

    // MARK: - Private Methods

    private func setupSchedulingTimer() {
        // Check every minute for scheduled reservations
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.checkScheduledReservations()
        }
    }

    private func checkScheduledReservations() {
        let configManager = ConfigurationManager.shared
        let reservationManager = ReservationManager.shared

        guard configManager.settings.globalEnabled else {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)

        // Convert Calendar weekday to our Weekday enum
        let weekday: ReservationConfig.Weekday
        switch currentWeekday {
        case 1: weekday = .sunday
        case 2: weekday = .monday
        case 3: weekday = .tuesday
        case 4: weekday = .wednesday
        case 5: weekday = .thursday
        case 6: weekday = .friday
        case 7: weekday = .saturday
        default:
            logger.warning("Invalid weekday: \(currentWeekday)")
            return
        }

        let configsForToday = configManager.getConfigurationsForDay(weekday)

        for config in configsForToday where shouldRunReservation(config: config, at: now) {
            DispatchQueue.main.async {
                reservationManager.runReservation(for: config)
            }
        }
    }

    private func shouldRunReservation(config: ReservationConfig, at date: Date) -> Bool {
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute], from: date)

        guard
            let currentHour = currentTime.hour,
            let currentMinute = currentTime.minute
        else {
            logger.warning("Could not extract time components from date")
            return false
        }

        // Only trigger at exactly 6:00pm
        if currentHour != 18 || currentMinute != 0 {
            return false
        }

        // For each enabled day, check if today is 2 days before that day
        let today = calendar.startOfDay(for: date)
        for (day, timeSlots) in config.dayTimeSlots {
            guard !timeSlots.isEmpty else { continue }
            // Find the next occurrence of the reservation day
            let targetWeekday = day.calendarWeekday
            let currentWeekday = calendar.component(.weekday, from: today)
            var daysUntilTarget = targetWeekday - currentWeekday
            if daysUntilTarget <= 0 { daysUntilTarget += 7 }
            let reservationDay = calendar.date(byAdding: .day, value: daysUntilTarget, to: today) ?? today
            // Autorun should be 2 days before reservation day
            let autorunDay = calendar.date(byAdding: .day, value: -2, to: reservationDay) ?? reservationDay
            if calendar.isDate(today, inSameDayAs: autorunDay) {
                return true
            }
        }
        return false
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error {
                self.logger.error("Notification permission error: \(error.localizedDescription)")
            } else {
                // self.logger.info("Notification permissions granted: \(granted)") // Removed as per edit hint
            }
        }
    }
}
