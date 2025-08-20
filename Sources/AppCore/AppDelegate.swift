import Combine
import SwiftUI
import os.log

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
  private var isAutorunExecuting = false  // Prevent duplicate executions
  private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "AppDelegate")
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

    // Perform startup maintenance (cleanup old screenshots, etc.)
    performStartupMaintenance()

    // Initialize complete
  }

  func applicationWillTerminate(_: Notification) {
    // Clean up
    timer?.invalidate()
    timer = nil
    isAutorunExecuting = false

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

  deinit {}

  // MARK: - Private Methods

  private func initializeServices() {
    logger.info("🔧 Initializing services...")

    // Don't auto-check notification status on startup
    // Let user manually request permission when needed

    logger.info("✅ Services initialized.")
  }

  private func performStartupMaintenance() {
    logger.info("🧹 Performing startup maintenance...")

    // Clean up old screenshots (older than 30 days)
    Task {
      let deletedCount = FileManager.cleanupOldScreenshots(maxAge: 30)
      if deletedCount > 0 {
        logger.info("🧹 Startup cleanup: \(deletedCount) old screenshots removed.")
      }
    }
  }

  private func setupGlobalKeyboardShortcuts() {
    logger.info("⌨️ Setting up global keyboard shortcuts...")

    // Set up global keyboard monitor for various shortcuts
    globalKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      // Check for Command+G (God Mode toggle)
      if event.modifierFlags.contains(.command), event.keyCode == 5 {  // keyCode 5 is 'g'
        self?.logger.info("⌨️ Global Command+G detected - toggling God Mode UI.")

        // Toggle God Mode UI through the status bar controller
        DispatchQueue.main.async {
          self?.statusBarController?.toggleGodModeUI()
        }

        return nil  // Consume the event
      }

      // Check for Command+N (Add Configuration)
      if event.modifierFlags.contains(.command), event.keyCode == 45 {  // keyCode 45 is 'n'
        self?.logger.info("⌨️ Global Command+N detected - adding configuration.")

        // Add configuration through the status bar controller
        DispatchQueue.main.async {
          self?.statusBarController?.addConfiguration()
        }

        return nil  // Consume the event
      }

      // Check for Command+, (Settings)
      if event.modifierFlags.contains(.command), event.keyCode == 43 {  // keyCode 43 is ','
        self?.logger.info("⌨️ Global Command+, detected - opening settings.")

        // Open settings through the status bar controller
        DispatchQueue.main.async {
          self?.statusBarController?.openSettings()
        }

        return nil  // Consume the event
      }

      return event  // Pass through other events
    }

    logger.info("✅ Global keyboard shortcuts initialized.")
  }

  private func setupNotificationObservers() {
    // Observe reschedule autorun notifications
    NotificationCenter.default.addObserver(
      forName: AppConstants.rescheduleAutorunNotification,
      object: nil,
      queue: .main,
    ) { [weak self] _ in
      Task { @MainActor in
        self?.logger.info("🔄 Rescheduling autorun due to settings change.")
        self?.schedulePreciseAutorun()
      }
    }
  }

  private func setupSchedulingTimer() {
    // Schedule precise autorun at exactly 6:00:00 PM
    schedulePreciseAutorun()

    // Simple backup timer that checks every minute to ensure autorun is scheduled
    // This is just a safety net, not a replacement for the precise timer
    timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      guard let self = self else { return }

      // Use main queue for UI operations and logging
      DispatchQueue.main.async {
        // Only log once per minute to avoid spam
        let now = Date()
        let calendar = Calendar.current
        let currentMinute = calendar.component(.minute, from: now)

        // Log every 10 minutes to show the timer is working
        if currentMinute % 10 == 0 {
          self.logger.info("⏰ Backup timer check - ensuring autorun is properly scheduled.")
        }

        // The backup timer is just for logging, precise scheduling is handled by Timer.scheduledTimer
      }
    }
  }

  private func schedulePreciseAutorun() {
    let calendar = Calendar.current
    let now = Date()
    let userSettingsManager = UserSettingsManager.shared

    // Determine which time to use based on user settings
    let useCustomTime = userSettingsManager.userSettings.useCustomAutorunTime
    let autorunTime: Date =
      if useCustomTime {
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
    var nextAutorun =
      calendar
      .date(bySettingHour: autorunHour, minute: autorunMinute, second: autorunSecond, of: now)
      ?? now

    if nextAutorun <= now {
      nextAutorun = calendar.date(byAdding: .day, value: 1, to: nextAutorun) ?? nextAutorun
    }

    let timeUntilAutorun = nextAutorun.timeIntervalSince(now)
    let timeString = String(format: "%02d:%02d:%02d", autorunHour, autorunMinute, autorunSecond)

    logger
      .info(
        "🕕 Scheduling precise autorun for \(nextAutorun) (custom time: \(timeString), in \(timeUntilAutorun) seconds)",
      )

    // No need to cancel anything since we're using simple Timer.scheduledTimer

    // Use DispatchQueue.main.asyncAfter for precise timing without actor isolation issues
    DispatchQueue.main.asyncAfter(deadline: .now() + timeUntilAutorun) { [weak self] in
      guard let self = self else { return }

      let currentTime = Date()
      let cal = Calendar.current
      let hour = cal.component(.hour, from: currentTime)
      let minute = cal.component(.minute, from: currentTime)
      let second = cal.component(.second, from: currentTime)
      let timeStr = "\(hour):\(String(format: "%02d", minute)):\(String(format: "%02d", second))"

      self.logger.info("🕕 PRECISE \(timeStr) autorun triggered.")
      self.checkScheduledReservations()

      // Schedule the next day's autorun after a short delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
        self?.schedulePreciseAutorun()
      }
    }
  }

  private func checkScheduledReservations() {
    // Prevent duplicate executions
    guard !isAutorunExecuting else {
      logger.info("🔄 Autorun already executing, skipping duplicate call.")
      return
    }

    let configManager = ConfigurationManager.shared
    let orchestrator = ReservationOrchestrator.shared

    guard configManager.settings.globalEnabled else {
      logger.info("❌ Global automation is disabled, skipping autorun.")
      return
    }

    // Collect all configurations that should run at the custom autorun time today
    var configsToRun: [ReservationConfig] = []

    for config in configManager.settings.configurations
    where shouldRunReservation(config: config, at: Date()) {
      configsToRun.append(config)
    }

    // Run all eligible configurations simultaneously (like God Mode)
    if !configsToRun.isEmpty {
      isAutorunExecuting = true

      let userSettingsManager = UserSettingsManager.shared
      let calendar = Calendar.current
      let useCustomTime = userSettingsManager.userSettings.useCustomAutorunTime
      let autorunTime: Date =
        if useCustomTime {
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
      logger.info(
        "🕕 \(timeString) automatic run: Starting \(configsToRun.count) configurations simultaneously"
      )
      DispatchQueue.main.async {
        orchestrator.runMultipleReservations(for: configsToRun, runType: .automatic)

        // Reset execution flag after completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
          self?.isAutorunExecuting = false
        }
      }
    } else {
      logger.info("ℹ️ No configurations eligible for autorun at this time.")
    }
  }

  private func shouldRunReservation(config: ReservationConfig, at date: Date) -> Bool {
    // First check if this specific configuration has autorun enabled
    guard config.isEnabled else {
      logger.info("🚫 Configuration '\(config.name)' has autorun disabled, skipping.")
      return false
    }

    let calendar = Calendar.current
    let currentTime = calendar.dateComponents([.hour, .minute, .second], from: date)

    guard
      let currentHour = currentTime.hour,
      let currentMinute = currentTime.minute,
      let currentSecond = currentTime.second
    else {
      logger.warning("⚠️ Could not extract time components from date.")
      return false
    }

    let userSettingsManager = UserSettingsManager.shared
    let useCustomTime = userSettingsManager.userSettings.useCustomAutorunTime

    // Calculate autorun time based on TODAY's date, not the current time
    let today = calendar.startOfDay(for: date)
    let autorunTime: Date
    if useCustomTime {
      // Use the custom time set by the user, but for today
      let customTime = userSettingsManager.userSettings.customAutorunTime
      let customHour = calendar.component(.hour, from: customTime)
      let customMinute = calendar.component(.minute, from: customTime)
      let customSecond = calendar.component(.second, from: customTime)
      autorunTime =
        calendar.date(
          bySettingHour: customHour, minute: customMinute, second: customSecond, of: today) ?? today
    } else {
      // Use default 6:00 PM time for today
      autorunTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today
    }

    // Extract time components from the calculated autorun time for today
    let autorunHour = calendar.component(.hour, from: autorunTime)
    let autorunMinute = calendar.component(.minute, from: autorunTime)
    let autorunSecond = calendar.component(.second, from: autorunTime)

    // Allow a 5-second window for autorun triggering (reliable tolerance for system timing)
    let currentTimeInSeconds = currentHour * 3_600 + currentMinute * 60 + currentSecond
    let autorunTimeInSeconds = autorunHour * 3_600 + autorunMinute * 60 + autorunSecond
    let timeDifference = abs(currentTimeInSeconds - autorunTimeInSeconds)

    let currentTimeStr = "\(currentHour):\(currentMinute):\(currentSecond)"
    let autorunTimeStr = "\(autorunHour):\(autorunMinute):\(autorunSecond)"

    if timeDifference > 5 {
      logger.info(
        "🔍 DEBUG: Time mismatch - current: \(currentTimeStr), autorun: \(autorunTimeStr), difference: \(timeDifference)s (outside 5s window)",
      )
      return false
    } else {
      logger.info(
        "✅ DEBUG: Time match found - current: \(currentTimeStr), autorun: \(autorunTimeStr), difference: \(timeDifference)s (within 5s window)",
      )
    }

    // For each enabled day, check if today is N days before that day
    for (day, timeSlots) in config.dayTimeSlots {
      guard !timeSlots.isEmpty else { continue }
      // Find the next occurrence of the reservation day
      let targetWeekday = day.calendarWeekday
      let currentWeekday = calendar.component(.weekday, from: today)
      var daysUntilTarget = targetWeekday - currentWeekday
      if daysUntilTarget <= 0 { daysUntilTarget += 7 }
      let reservationDay = calendar.date(byAdding: .day, value: daysUntilTarget, to: today) ?? today
      // Autorun should be priorDays before reservation day
      let priorDays: Int = {
        let settings = UserSettingsManager.shared.userSettings
        if settings.useCustomPriorDays { return max(0, min(7, settings.customPriorDays)) }
        return 2
      }()
      let autorunDay =
        calendar.date(byAdding: .day, value: -priorDays, to: reservationDay) ?? reservationDay

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
