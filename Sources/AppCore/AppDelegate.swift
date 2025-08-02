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
        _ = WebKitService.registered
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
    private var globalKeyMonitor: Any?
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

        // Set up global keyboard shortcuts
        setupGlobalKeyboardShortcuts()

        // Set up scheduling timer
        setupSchedulingTimer()

        // Set up notification observers
        setupNotificationObservers()

        // Initialize services
        initializeServices()

        // Initialize complete
    }

    func applicationWillTerminate(_: Notification) {
        // Clean up
        timer?.invalidate()
        timer = nil

        // Remove global keyboard monitor
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyMonitor = nil
        }

        // Emergency cleanup for any running automation
        Task {
            await orchestrator.emergencyCleanup(runType: .manual)
        }
    }

    deinit { }

    // MARK: - Private Methods

    private func initializeServices() {
        logger.info("🔧 Initializing services...")

        // Don't auto-check notification status on startup
        // Let user manually request permission when needed

        logger.info("✅ Services initialized")
    }

    private func setupGlobalKeyboardShortcuts() {
        logger.info("⌨️ Setting up global keyboard shortcuts...")

        // Set up global keyboard monitor for various shortcuts
        globalKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Command+G (God Mode toggle)
            if event.modifierFlags.contains(.command), event.keyCode == 5 { // keyCode 5 is 'g'
                self?.logger.info("⌨️ Global Command+G detected - toggling God Mode UI.")

                // Toggle God Mode UI through the status bar controller
                DispatchQueue.main.async {
                    self?.statusBarController?.toggleGodModeUI()
                }

                return nil // Consume the event
            }

            // Check for Command+N (Add Configuration)
            if event.modifierFlags.contains(.command), event.keyCode == 45 { // keyCode 45 is 'n'
                self?.logger.info("⌨️ Global Command+N detected - adding configuration.")

                // Add configuration through the status bar controller
                DispatchQueue.main.async {
                    self?.statusBarController?.addConfiguration()
                }

                return nil // Consume the event
            }

            // Check for Command+, (Settings)
            if event.modifierFlags.contains(.command), event.keyCode == 43 { // keyCode 43 is ','
                self?.logger.info("⌨️ Global Command+, detected - opening settings.")

                // Open settings through the status bar controller
                DispatchQueue.main.async {
                    self?.statusBarController?.openSettings()
                }

                return nil // Consume the event
            }

            return event // Pass through other events
        }

        logger.info("✅ Global keyboard shortcuts initialized")
    }

    private func setupNotificationObservers() {
        // Observe reschedule autorun notifications
        NotificationCenter.default.addObserver(
            forName: AppConstants.rescheduleAutorunNotification,
            object: nil,
            queue: .main,
            ) { [weak self] _ in
            Task { @MainActor in
                self?.logger.info("🔄 Rescheduling autorun due to settings change")
                self?.schedulePreciseAutorun()
            }
        }
    }

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

                // Check if we're 5 minutes before the autorun time and prevent sleep if enabled
                let userSettingsManager = UserSettingsManager.shared
                let useCustomTime = userSettingsManager.userSettings.useCustomAutorunTime
                let autorunTime: Date = if useCustomTime {
                    // Use the custom time set by the user
                    userSettingsManager.userSettings.customAutorunTime
                } else {
                    // Use default 6:00 PM time
                    calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
                }

                let autorunHour = calendar.component(.hour, from: autorunTime)
                let autorunMinute = calendar.component(.minute, from: autorunTime)

                // Calculate 5 minutes before autorun time
                let sleepPreventionTime = calendar.date(byAdding: .minute, value: -5, to: autorunTime) ?? autorunTime
                let sleepPreventionHour = calendar.component(.hour, from: sleepPreventionTime)
                let sleepPreventionMinute = calendar.component(.minute, from: sleepPreventionTime)

                if currentHour == sleepPreventionHour, currentMinute == sleepPreventionMinute {
                    let configManager = ConfigurationManager.shared
                    let userSettings = userSettingsManager.userSettings
                    if userSettings.preventSleepForAutorun {
                        // Check if any configs are scheduled for autorun today
                        let hasAutorun = configManager.settings.configurations.contains { config in
                            self.shouldRunReservation(config: config, at: autorunTime)
                        }
                        if hasAutorun {
                            let timeString = String(format: "%02d:%02d", autorunHour, autorunMinute)
                            SleepManager
                                .preventSleep(reason: "ODYSSEY: Preparing for \(timeString) autorun reservations")
                        }
                    }
                }

                // Backup check: if we're at exactly the autorun time and haven't run yet
                let autorunSecond = calendar.component(.second, from: autorunTime)

                if currentHour == autorunHour, currentMinute == autorunMinute, currentSecond == autorunSecond {
                    self.checkScheduledReservations()
                }
            }
        }
    }

    private func schedulePreciseAutorun() {
        let calendar = Calendar.current
        let now = Date()
        let userSettingsManager = UserSettingsManager.shared

        // Determine which time to use based on user settings
        let useCustomTime = userSettingsManager.userSettings.useCustomAutorunTime
        let autorunTime: Date = if useCustomTime {
            // Use the custom time set by the user
            userSettingsManager.userSettings.customAutorunTime
        } else {
            // Use default 6:00 PM time
            calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
        }

        let autorunHour = calendar.component(.hour, from: autorunTime)
        let autorunMinute = calendar.component(.minute, from: autorunTime)
        let autorunSecond = calendar.component(.second, from: autorunTime)

        let timeType = useCustomTime ? "custom" : "default"
        logger
            .info(
                "🔍 DEBUG: Current autorun time is set to \(autorunHour):\(autorunMinute):\(autorunSecond) (\(timeType))",
                )

        // Calculate the next autorun time using the determined time
        var nextAutorun = calendar
            .date(bySettingHour: autorunHour, minute: autorunMinute, second: autorunSecond, of: now) ?? now

        if nextAutorun <= now {
            nextAutorun = calendar.date(byAdding: .day, value: 1, to: nextAutorun) ?? nextAutorun
        }

        let timeUntilAutorun = nextAutorun.timeIntervalSince(now)
        let timeString = String(format: "%02d:%02d:%02d", autorunHour, autorunMinute, autorunSecond)

        logger
            .info(
                "🕕 Scheduling precise autorun for \(nextAutorun) (custom time: \(timeString), in \(timeUntilAutorun) seconds)",
                )

        // Schedule the precise timer
        DispatchQueue.main.asyncAfter(deadline: .now() + timeUntilAutorun) { [self] in
            Task { @MainActor in
                logger.info("🕕 PRECISE \(timeString) autorun triggered!")
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

        // Collect all configurations that should run at the custom autorun time today
        var configsToRun: [ReservationConfig] = []

        for config in configManager.settings.configurations where shouldRunReservation(config: config, at: Date()) {
            configsToRun.append(config)
        }

        // Run all eligible configurations simultaneously (like God Mode)
        if !configsToRun.isEmpty {
            let userSettingsManager = UserSettingsManager.shared
            let calendar = Calendar.current
            let useCustomTime = userSettingsManager.userSettings.useCustomAutorunTime
            let autorunTime: Date = if useCustomTime {
                // Use the custom time set by the user
                userSettingsManager.userSettings.customAutorunTime
            } else {
                // Use default 6:00 PM time
                calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
            }

            let autorunHour = calendar.component(.hour, from: autorunTime)
            let autorunMinute = calendar.component(.minute, from: autorunTime)
            let autorunSecond = calendar.component(.second, from: autorunTime)
            let timeString = String(format: "%02d:%02d:%02d", autorunHour, autorunMinute, autorunSecond)
            logger.info("🕕 \(timeString) automatic run: Starting \(configsToRun.count) configurations simultaneously")
            DispatchQueue.main.async {
                orchestrator.runMultipleReservations(for: configsToRun, runType: .automatic)
            }
        }
    }

    private func shouldRunReservation(config: ReservationConfig, at date: Date) -> Bool {
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute, .second], from: date)

        guard
            let currentHour = currentTime.hour,
            let currentMinute = currentTime.minute,
            let currentSecond = currentTime.second
        else {
            logger.warning("Could not extract time components from date")
            return false
        }

        // Only trigger at exactly the autorun time (including seconds)
        let userSettingsManager = UserSettingsManager.shared
        let useCustomTime = userSettingsManager.userSettings.useCustomAutorunTime
        let autorunTime: Date = if useCustomTime {
            // Use the custom time set by the user
            userSettingsManager.userSettings.customAutorunTime
        } else {
            // Use default 6:00 PM time
            calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date) ?? date
        }

        // Extract time components from the stored autorun time
        let autorunHour = calendar.component(.hour, from: autorunTime)
        let autorunMinute = calendar.component(.minute, from: autorunTime)
        let autorunSecond = calendar.component(.second, from: autorunTime)

        // Allow a 2-second window for autorun triggering (minimal tolerance for system timing)
        let currentTimeInSeconds = currentHour * 3_600 + currentMinute * 60 + currentSecond
        let autorunTimeInSeconds = autorunHour * 3_600 + autorunMinute * 60 + autorunSecond
        let timeDifference = abs(currentTimeInSeconds - autorunTimeInSeconds)

        let currentTimeStr = "\(currentHour):\(currentMinute):\(currentSecond)"
        let autorunTimeStr = "\(autorunHour):\(autorunMinute):\(autorunSecond)"

        if timeDifference > 2 {
            logger.info(
                "🔍 DEBUG: Time mismatch - current: \(currentTimeStr), autorun: \(autorunTimeStr), difference: \(timeDifference)s",
                )
            return false
        } else {
            logger.info(
                "✅ DEBUG: Time match found - current: \(currentTimeStr), autorun: \(autorunTimeStr), difference: \(timeDifference)s",
                )
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

            logger
                .info(
                    "🔍 DEBUG: Config '\(config.name)' - Day: \(day.rawValue), targetWeekday: \(targetWeekday), currentWeekday: \(currentWeekday)",
                    )
            logger
                .info(
                    "🔍 DEBUG: daysUntilTarget: \(daysUntilTarget), reservationDay: \(reservationDay), autorunDay: \(autorunDay), today: \(today)",
                    )

            if calendar.isDate(today, inSameDayAs: autorunDay) {
                return true
            }
        }
        return false
    }
}
