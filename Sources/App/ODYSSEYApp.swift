import Combine
import os.log
import SwiftUI

/// Main application entry point for ODYSSEY
///
/// ODYSSEY is a macOS menu bar application that automates sports reservation bookings
/// for Ottawa Recreation facilities. It runs quietly in the background and automatically
/// books preferred sports slots at optimal times.
@main
struct ODYSSEYApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
        _ = WebKitService._registered
        WebKitService.registerForDI()
        EmailService.registerForDI()
        KeychainService.registerForDI()
        // ... register other services as needed ...
    }

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
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var timer: Timer?
    private let logger = Logger(subsystem: "com.odyssey.app", category: "AppDelegate")
    private let orchestrator = ReservationOrchestrator.shared

    override init() {
        super.init()
    }

    func applicationDidFinishLaunching(_: Notification) {
        // Hide dock icon since this is a status bar app
        NSApp.setActivationPolicy(.accessory)

        // Initialize status bar controller
        statusBarController = StatusBarController()

        // Set up scheduling timer
        setupSchedulingTimer()

        // Initialize complete
    }

    func applicationWillTerminate(_: Notification) {
        // Clean up
        timer?.invalidate()
        timer = nil

        // Emergency cleanup for any running automation
        Task {
            await orchestrator.emergencyCleanup(runType: .manual)
        }
    }

    // MARK: - Private Methods

    private func setupSchedulingTimer() {
        // Schedule precise autorun at exactly 6:00:00 PM
        schedulePreciseAutorun()

        // Also keep a backup timer that checks every minute for any missed autoruns
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                let now = Date()
                let calendar = Calendar.current
                let currentHour = calendar.component(.hour, from: now)
                let currentMinute = calendar.component(.minute, from: now)
                let currentSecond = calendar.component(.second, from: now)

                // At 5:55pm, check if autorun is needed and prevent sleep if enabled
                if currentHour == 17, currentMinute == 55 {
                    let configManager = ConfigurationManager.shared
                    let userSettings = UserSettingsManager.shared.userSettings
                    if userSettings.preventSleepForAutorun {
                        // Check if any configs are scheduled for autorun today
                        let hasAutorun = configManager.settings.configurations.contains { config in
                            self.shouldRunReservation(
                                config: config,
                                at: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now,
                                )
                        }
                        if hasAutorun {
                            SleepManager.preventSleep(reason: "ODYSSEY: Preparing for 6pm autorun reservations")
                        }
                    }
                }

                // Backup check: if we're at exactly 6:00:00 PM and haven't run yet
                if currentHour == 18, currentMinute == 0, currentSecond == 0 {
                    self.checkScheduledReservations()
                }
            }
        }
    }

    private func schedulePreciseAutorun() {
        let calendar = Calendar.current
        let now = Date()

        // Calculate the next 6:00:00 PM
        var nextAutorun = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now

        // If it's already past 6:00 PM today, schedule for tomorrow
        if nextAutorun <= now {
            nextAutorun = calendar.date(byAdding: .day, value: 1, to: nextAutorun) ?? nextAutorun
        }

        let timeUntilAutorun = nextAutorun.timeIntervalSince(now)

        logger.info("🕕 Scheduling precise autorun for \(nextAutorun) (in \(timeUntilAutorun) seconds)")

        // Schedule the precise timer
        DispatchQueue.main.asyncAfter(deadline: .now() + timeUntilAutorun) { [self] in
            Task { @MainActor in
                logger.info("🕕 PRECISE 6:00:00 PM autorun triggered!")
                self.checkScheduledReservations()

                // Schedule the next day's autorun
                self.schedulePreciseAutorun()
            }
        }
    }

    private func checkScheduledReservations() {
        let configManager = ConfigurationManager.shared
        let orchestrator = ReservationOrchestrator.shared

        guard configManager.settings.globalEnabled else {
            return
        }

        // Collect all configurations that should run at 6:00 PM today
        var configsToRun: [ReservationConfig] = []

        for config in configManager.settings.configurations where shouldRunReservation(config: config, at: Date()) {
            configsToRun.append(config)
        }

        // Run all eligible configurations simultaneously (like God Mode)
        if !configsToRun.isEmpty {
            logger.info("🕕 6:00 PM automatic run: Starting \(configsToRun.count) configurations simultaneously")
            DispatchQueue.main.async {
                orchestrator.runMultipleReservations(for: configsToRun, runType: .automatic)
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
}
