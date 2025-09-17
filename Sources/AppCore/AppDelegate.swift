import Combine
import Foundation
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
    Settings { EmptyView() }
  }
}

/// App delegate to handle macOS-specific functionality
///
/// Manages the application lifecycle, status bar integration, and automated scheduling.
/// Handles background timer setup for reservation automation and notification permissions.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarController: StatusBarController?
  private var globalKeyMonitor: Any?
  private var isAutorunExecuting = false  // Prevent duplicate executions
  private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "AppDelegate")
  private let orchestrator = ReservationOrchestrator.shared

  override init() {
    super.init()
  }

  func applicationDidFinishLaunching(_: Notification) {
    // Check for scheduled execution command line argument
    let arguments = CommandLine.arguments
    let isScheduledExecution = arguments.contains("--scheduled")

    if isScheduledExecution {
      // Handle scheduled execution from Launch Agent
      handleScheduledExecution()
      return
    }

    // Normal app startup
    // Hide dock icon since this is a status bar app
    NSApp.setActivationPolicy(.accessory)

    // Initialize status bar controller (custom NSStatusItem for precise sizing)
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
    isAutorunExecuting = false

    // Remove global keyboard monitor
    if let monitor = globalKeyMonitor {
      NSEvent.removeMonitor(monitor)
      globalKeyMonitor = nil
    }

    // Clean up Launch Agent to prevent orphaned plist files
    cleanupLaunchAgent()

    // Emergency cleanup for any running automation
    Task {
      await orchestrator.emergencyCleanup(runType: .manual)
    }
  }

  deinit {}

  // MARK: - Private Methods

  private func initializeServices() {
    logger.info("🔧 Initializing services.")

    // Initialize notification service and request permissions
    Task {

    }

    logger.info("✅ Services initialized.")
  }

  private func performStartupMaintenance() {
    logger.info("🧹 Performing startup maintenance.")

    // Clean up old screenshots (older than 30 days)
    Task {
      let deletedCount = FileManager.cleanupOldScreenshots(maxAge: 30)
      if deletedCount > 0 {
        logger.info("🧹 Startup cleanup: \(deletedCount) old screenshots removed.")
      }
    }
  }

  private func setupGlobalKeyboardShortcuts() {
    logger.info("⌨️ Setting up global keyboard shortcuts.")

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

    // Observe distributed notifications from Launch Agent trigger instances
    DistributedNotificationCenter.default().addObserver(
      forName: NSNotification.Name("com.odyssey.triggerScheduledReservations"),
      object: nil,
      queue: .main,
      using: { [weak self] notification in
        Task { @MainActor in
          let receivedTime = Date()
          self?.logger.info(
            "📨 RECEIVED: Scheduled reservations trigger from Launch Agent at \(receivedTime).")
          self?.checkScheduledReservations()
        }
      }
    )
  }

  private func setupSchedulingTimer() {
    logger.info("🔧 Setting up precise autorun scheduling...")

    // Schedule precise autorun at exactly the configured time
    schedulePreciseAutorun()

    logger.info("✅ Precise autorun scheduling setup completed.")
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
    logger.info(
      "🕐 Autorun scheduled for \(autorunHour):\(autorunMinute):\(autorunSecond) (\(timeType)).")

    // Calculate the next autorun time using the determined time
    var nextAutorun =
      calendar
      .date(
        bySettingHour: autorunHour,
        minute: autorunMinute,
        second: AppConstants.defaultAutorunSecond,
        of: now
      ) ?? now

    if nextAutorun <= now {
      nextAutorun = calendar.date(byAdding: .day, value: 1, to: nextAutorun) ?? nextAutorun
    }

    let timeUntilAutorun = nextAutorun.timeIntervalSince(now)
    let timeString = String(format: "%02d:%02d:%02d", autorunHour, autorunMinute, autorunSecond)

    logger.info(
      "🕕 Scheduling precise autorun for \(nextAutorun) (custom time: \(timeString), in \(timeUntilAutorun) seconds)."
    )

    // Schedule autorun reminder notification (1 hour before)

    // Write LaunchAgent so the system triggers the app precisely at the configured time
    scheduleLaunchAgent(for: nextAutorun)
  }

  private func handleScheduledExecution() {
    let startTime = Date()
    logger.info("🕐 SCHEDULED EXECUTION - Triggered by Launch Agent at \(startTime).")

    // Check if another instance of the app is already running
    let runningApps = NSWorkspace.shared.runningApplications
    let odysseyApps = runningApps.filter { app in
      app.bundleIdentifier == Bundle.main.bundleIdentifier && app != NSRunningApplication.current
    }

    if !odysseyApps.isEmpty {
      // Another instance is running - this means the main app is open in tray
      // User expects autoruns to happen by schedule, so trigger reservations
      logger.info(
        "📱 Main app instance detected (running in tray) - triggering scheduled reservations.")

      // Send distributed notification to the main app instance
      let notificationTime = Date()
      let timeSinceStart = notificationTime.timeIntervalSince(startTime)
      logger.info(
        "📤 Sending notification to main app (\(String(format: "%.2f", timeSinceStart))s since trigger)."
      )

      let notificationCenter = DistributedNotificationCenter.default()
      notificationCenter.postNotificationName(
        NSNotification.Name("com.odyssey.triggerScheduledReservations"),
        object: nil,
        userInfo: nil,
        deliverImmediately: true
      )

      let exitTime = Date()
      let totalTime = exitTime.timeIntervalSince(startTime)
      logger.info(
        "📤 Notification sent to main app - exiting trigger instance (\(String(format: "%.2f", totalTime))s total)."
      )

      // Clean up Launch Agent after successful execution
      cleanupLaunchAgent()

      NSApplication.shared.terminate(nil)
    } else {
      // No other instance running - main app is closed
      // User doesn't want reservations to run if app is not in tray
      logger.info(
        "📱 No main app instance found - skipping scheduled reservations (app not running in tray).")

      let exitTime = Date()
      let totalTime = exitTime.timeIntervalSince(startTime)
      logger.info(
        "⏭️ Scheduled execution skipped - exiting trigger instance (\(String(format: "%.2f", totalTime))s total)."
      )

      // Clean up Launch Agent since execution was skipped
      cleanupLaunchAgent()

      // Exit without running any reservations
      NSApplication.shared.terminate(nil)
    }
  }

  private func scheduleLaunchAgent(for targetTime: Date) {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: targetTime)

    guard let hour = components.hour, let minute = components.minute else {
      logger.error("❌ Failed to extract time components from target time")
      return
    }

    // Resolve ODYSSEY binary path
    var appPath = ""

    // 1) Running bundle
    let currentAppPath = Bundle.main.bundlePath + "/Contents/MacOS/ODYSSEY"
    if FileManager.default.fileExists(atPath: currentAppPath) {
      appPath = currentAppPath
      logger.info("✅ Using current app path: \(appPath)")
    }

    // 2) Standard install locations
    if appPath.isEmpty {
      let standardLocations = [
        "/Applications/ODYSSEY.app/Contents/MacOS/ODYSSEY",
        "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications/ODYSSEY.app/Contents/MacOS/ODYSSEY",
      ]
      for location in standardLocations where FileManager.default.fileExists(atPath: location) {
        appPath = location
        logger.info("✅ Found app in standard location: \(appPath)")
        break
      }
    }

    // 3) Xcode DerivedData (dev builds)
    if appPath.isEmpty {
      let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
      let derivedDataPath = "\(homeDir)/Library/Developer/Xcode/DerivedData"
      if let enumerator = FileManager.default.enumerator(atPath: derivedDataPath) {
        for case let path as String in enumerator {
          if path.hasSuffix("ODYSSEY.app/Contents/MacOS/ODYSSEY") {
            appPath = "\(derivedDataPath)/\(path)"
            logger.info("✅ Found app in Xcode DerivedData: \(appPath)")
            break
          }
        }
      }
    }

    // Fallback to bundle
    if appPath.isEmpty {
      appPath = Bundle.main.bundlePath + "/Contents/MacOS/ODYSSEY"
      logger.info("⚠️ Using bundle path fallback: \(appPath)")
    }

    // Directories
    let launchAgentDir = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/LaunchAgents")
    let logsDir = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Logs/ODYSSEY")
    do {
      try FileManager.default.createDirectory(at: launchAgentDir, withIntermediateDirectories: true)
      try FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
    } catch {
      logger.error("❌ Failed to create directories: \(error.localizedDescription)")
      return
    }

    let plistPath = launchAgentDir.appendingPathComponent(AppConstants.launchAgentLabel + ".plist")
    let plistContent = """
      <?xml version=\"1.0\" encoding=\"UTF-8\"?>
      <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n
      <plist version=\"1.0\">
      <dict>
          <key>Label</key>
          <string>\(AppConstants.launchAgentLabel)</string>
          <key>ProgramArguments</key>
          <array>
              <string>\(appPath)</string>
              <string>--scheduled</string>
          </array>
          <key>StartCalendarInterval</key>
          <dict>
              <key>Hour</key>
              <integer>\(hour)</integer>
              <key>Minute</key>
              <integer>\(minute)</integer>
          </dict>
          <key>RunAtLoad</key>
          <false/>
          <key>StandardOutPath</key>
          <string>\(logsDir.path)/\(AppConstants.launchAgentScheduledLogFilename)</string>
          <key>StandardErrorPath</key>
          <string>\(logsDir.path)/\(AppConstants.launchAgentScheduledErrorLogFilename)</string>
      </dict>
      </plist>
      """

    do {
      try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)
      logger.info("✅ Launch Agent plist created: \(plistPath.path)")
    } catch {
      logger.error("❌ Failed to write Launch Agent plist: \(error.localizedDescription)")
      return
    }

    // Unload existing
    let unload = Process()
    unload.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    unload.arguments = ["bootout", "gui/\(getuid())", plistPath.path]
    try? unload.run()
    unload.waitUntilExit()

    // Load new
    let load = Process()
    load.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    load.arguments = ["bootstrap", "gui/\(getuid())", plistPath.path]
    do {
      try load.run()
      load.waitUntilExit()
      if load.terminationStatus == 0 {
        logger.info(
          "🚀 Launch Agent loaded for \(String(format: "%02d", hour)):\(String(format: "%02d", minute))"
        )
      } else {
        logger.error("❌ Failed to load Launch Agent (exit code: \(load.terminationStatus))")
      }
    } catch {
      logger.error("❌ Failed to execute launchctl: \(error.localizedDescription)")
    }
  }

  private func checkScheduledReservations() {
    let executionStartTime = Date()
    logger.info("🚀 Starting scheduled reservations execution at \(executionStartTime)")

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

    // Log all configurations for debugging
    logger.info(
      "🔍 Checking \(configManager.settings.configurations.count) configurations for scheduled execution:"
    )
    for (index, config) in configManager.settings.configurations.enumerated() {
      let enabledStatus = config.isEnabled ? "✅ enabled" : "❌ disabled"
      let daySlots = config.dayTimeSlots.compactMap { day, slots in
        slots.isEmpty ? nil : "\(day.rawValue): \(slots.count) slots"
      }.joined(separator: ", ")
      logger.info(
        "🔍 Config \(index + 1): '\(config.name)' - \(enabledStatus) - Days: [\(daySlots)]")
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
          userSettingsManager.userSettings.customAutorunTime
        } else {
          calendar.date(
            bySettingHour: AppConstants.defaultAutorunHour,
            minute: AppConstants.defaultAutorunMinute,
            second: AppConstants.defaultAutorunSecond,
            of: Date()
          ) ?? Date()
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

  /// Cleans up the Launch Agent plist file and unloads it from launchd
  private func cleanupLaunchAgent() {
    let launchAgentPlistPath = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/LaunchAgents/com.odyssey.scheduled.plist")

    logger.info("🧹 Cleaning up Launch Agent...")

    // Unload the agent from launchd if it's loaded
    let unloadProcess = Process()
    unloadProcess.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    unloadProcess.arguments = ["bootout", "gui/\(getuid())", launchAgentPlistPath.path]
    do {
      try unloadProcess.run()
      unloadProcess.waitUntilExit()
      if unloadProcess.terminationStatus == 0 {
        logger.info("✅ Launch Agent unloaded successfully")
      } else {
        logger.warning(
          "⚠️ Launch Agent unload returned non-zero exit code: \(unloadProcess.terminationStatus)")
      }
    } catch {
      logger.warning("⚠️ Failed to unload Launch Agent: \(error.localizedDescription)")
    }

    // Remove the plist file
    do {
      try FileManager.default.removeItem(at: launchAgentPlistPath)
      logger.info("✅ Launch Agent plist file removed: \(launchAgentPlistPath.path)")
    } catch {
      // It's okay if the file doesn't exist
      if (error as NSError).code != NSFileNoSuchFileError {
        logger.warning("⚠️ Failed to remove Launch Agent plist file: \(error.localizedDescription)")
      } else {
        logger.info("ℹ️ Launch Agent plist file was already removed")
      }
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

    // FIRST: Check if today is a valid autorun day for ANY of the configuration's enabled days
    var isValidAutorunDay = false
    var validAutorunTime: Date?

    for (day, timeSlots) in config.dayTimeSlots {
      guard !timeSlots.isEmpty else { continue }

      let targetWeekday = day.calendarWeekday
      let currentWeekday = calendar.component(.weekday, from: today)

      // Autorun should be priorDays before reservation day
      let priorDays: Int = {
        let settings = UserSettingsManager.shared.userSettings
        if settings.useCustomPriorDays { return max(0, min(7, settings.customPriorDays)) }
        return 2
      }()

      // Calculate the reservation day and autorun day
      let reservationDay: Date
      if targetWeekday == currentWeekday {
        // Today IS the reservation day - this is a special case for same-day reservations
        reservationDay = today
      } else {
        // Find the next occurrence of the reservation day
        var daysUntilTarget = targetWeekday - currentWeekday
        if daysUntilTarget <= 0 { daysUntilTarget += 7 }
        reservationDay = calendar.date(byAdding: .day, value: daysUntilTarget, to: today) ?? today
      }

      let autorunDay =
        calendar.date(byAdding: .day, value: -priorDays, to: reservationDay) ?? reservationDay

      logger
        .info(
          "📅 Config '\(config.name)' - Day: \(day.rawValue), target: \(targetWeekday), current: \(currentWeekday)",
        )
      logger
        .info(
          "📅 Days until target: \(targetWeekday == currentWeekday ? "0 (same day)" : "\(targetWeekday - currentWeekday)"), reservation: \(reservationDay), autorun: \(autorunDay), today: \(today)",
        )

      if calendar.isDate(today, inSameDayAs: autorunDay) {
        // Today IS a valid autorun day for this configuration
        isValidAutorunDay = true

        // Calculate the autorun time for this valid day
        if useCustomTime {
          let customTime = userSettingsManager.userSettings.customAutorunTime
          let customHour = calendar.component(.hour, from: customTime)
          let customMinute = calendar.component(.minute, from: customTime)
          let customSecond = calendar.component(.second, from: customTime)
          validAutorunTime =
            calendar.date(
              bySettingHour: customHour, minute: customMinute, second: customSecond, of: today)
            ?? today
        } else {
          // Use default 6:00 PM time for today
          validAutorunTime =
            calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today
        }
        break  // Found a match, no need to check other days
      }
    }

    // If today is NOT a valid autorun day for this configuration, don't run it
    guard isValidAutorunDay, let autorunTime = validAutorunTime else {
      logger.info("📅 Today is not a valid autorun day for configuration '\(config.name)'")
      return false
    }

    // SECOND: Now that we know today IS a valid autorun day, check the time
    let autorunHour = calendar.component(.hour, from: autorunTime)
    let autorunMinute = calendar.component(.minute, from: autorunTime)
    let autorunSecond = calendar.component(.second, from: autorunTime)

    // Allow a 5-second window for autorun triggering (reliable tolerance for system timing)
    let currentTimeInSeconds = currentHour * 3_600 + currentMinute * 60 + currentSecond
    let autorunTimeInSeconds = autorunHour * 3_600 + autorunMinute * 60 + autorunSecond
    let timeDifference = abs(currentTimeInSeconds - autorunTimeInSeconds)

    let currentTimeStr = "\(currentHour):\(currentMinute):\(currentSecond)"
    let autorunTimeStr = "\(autorunHour):\(autorunMinute):\(autorunSecond)"

    if timeDifference > AppConstants.autorunTimeToleranceSeconds {
      logger.info(
        "⏰ Time check: current \(currentTimeStr), scheduled \(autorunTimeStr) (\(timeDifference)s difference - outside tolerance window)",
      )
      return false
    } else {
      logger.info(
        "✅ Time match: current \(currentTimeStr), scheduled \(autorunTimeStr) (\(timeDifference)s difference - within tolerance window)",
      )
    }

    return true
  }
}
