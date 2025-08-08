import Foundation
import ODYSSEYBackend
import os.log

// ANSI escape codes for text formatting
private enum ANSI {
  static let bold = "\u{001B}[1m"
  static let reset = "\u{001B}[0m"
  static let green = "\u{001B}[32m"
  static let yellow = "\u{001B}[33m"
  static let red = "\u{001B}[31m"
  static let blue = "\u{001B}[34m"
}

// Direct terminal logging for CLI
private func logToTerminal(_ message: String, level: String = "INFO") {
  let formatter = DateFormatter()
  formatter.dateFormat = "HH:mm:ss"
  let timestamp = formatter.string(from: Date())

  let color: String =
    switch level {
    case "SUCCESS": ANSI.green
    case "WARNING": ANSI.yellow
    case "ERROR": ANSI.red
    case "INFO": ANSI.blue
    default: ""
    }

  print("\(color)[\(timestamp)] \(message)\(ANSI.reset)")
}

// Initialize services for CLI
@MainActor
private func initializeServices() {
  // Register services for dependency injection
  WebKitService.registerForDI()
  EmailService.registerForDI()
  KeychainService.registerForDI()

  // Verify services are registered by resolving them
  _ = ServiceRegistry.shared.resolve(WebKitServiceProtocol.self)
  _ = ServiceRegistry.shared.resolve(KeychainServiceProtocol.self)
  _ = ServiceRegistry.shared.resolve(EmailServiceProtocol.self)
}

/// CLI for ODYSSEY that provides remote automation capabilities
@main
struct CLI {
  private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "CLI")

  static func main() async {
    // Initialize services for CLI
    await MainActor.run {
      initializeServices()
    }

    let arguments = Array(CommandLine.arguments.dropFirst())

    guard !arguments.isEmpty else {
      printUsage()
      exit(0)
    }

    guard let command = arguments.first else {
      printUsage()
      exit(0)
    }
    let remainingArgs = Array(arguments.dropFirst())

    switch command {
    case "run":
      await runReservations(remainingArgs)
    case "configs":
      await listConfigurations()
    case "settings":
      await showUserSettings(unmask: remainingArgs.contains("--unmask"))

    case "help":
      printUsage()
      exit(0)
    case "version":
      printVersion()
      exit(0)
    default:
      print("❌ Unknown command: \(command)")
      printUsage()
      exit(1)
    }
  }

  private static func printUsage() {
    print(
      """
      🚀 ODYSSEY CLI - Ottawa Drop-in Your Sports & Schedule Easily Yourself.

      This CLI provides remote automation capabilities.

      Usage: odyssey-cli <command> [options]

      Commands:
        run                   Run reservations for configurations
        configs               List all available configurations
        settings              Show user settings from export token
        help                  Show this help message
        version               Show version information

      Examples:
        odyssey-cli run                    # Run configurations scheduled for today
        odyssey-cli run --now              # Run configurations immediately
        odyssey-cli run --prior 3          # Run 3 days before reservation (default: 2)
        odyssey-cli run --hide             # Hide sensitive information in output
        odyssey-cli run --screenshots      # Enable screenshot capture on failure

        odyssey-cli configs                # List all configurations

        odyssey-cli settings               # Show user settings from export token
        odyssey-cli settings --unmask      # Show unmasked settings

      Environment Variables:
        ODYSSEY_EXPORT_TOKEN=<exported_token>     # Required: Export token from GUI
      """)
  }

  private static func printVersion() {
    print("ODYSSEY CLI v\(AppConstants.appVersion)")
  }

  private static func bold(_ text: String) -> String {
    return "\(ANSI.bold)\(text)\(ANSI.reset)"
  }

  private static func updateUserSettingsForCLI(_ cliUserSettings: CLIExportService.CLIUserSettings)
    async
  {
    // Update UserSettingsManager with CLI settings
    await MainActor.run {
      var userSettings = UserSettingsManager.shared.userSettings
      userSettings.name = cliUserSettings.name
      userSettings.phoneNumber = cliUserSettings.phoneNumber
      userSettings.imapEmail = cliUserSettings.imapEmail
      userSettings.imapPassword = cliUserSettings.imapPassword
      userSettings.imapServer = cliUserSettings.imapServer
      userSettings.emailProvider =
        UserSettings.EmailProvider
        .imap
      userSettings.preventSleepForAutorun = cliUserSettings.preventSleepForAutorun
      userSettings.autoCloseDebugWindowOnFailure = cliUserSettings.autoCloseDebugWindowOnFailure

      // CLI always runs in headless mode - browser window will be hidden
      userSettings.showBrowserWindow = false
      logger.info("🕶️ CLI mode - browser window will be hidden.")

      UserSettingsManager.shared.userSettings = userSettings
    }

    logger.info("✅ Updated UserSettingsManager with CLI user settings.")
  }

  private static func updateConfigurationManagerForCLI(_ configs: [ReservationConfig]) async {
    // Update ConfigurationManager with CLI configurations
    await MainActor.run {
      ConfigurationManager.shared.settings.configurations = configs
    }

    logger.info("✅ Updated ConfigurationManager with \(configs.count) CLI configurations.")
  }

  private static func parseArguments(_ args: [String]) -> (
    runNow: Bool, priorDays: Int, hideInfo: Bool, enableScreenshots: Bool
  ) {
    let runNow = args.contains("--now")
    let hideInfo = args.contains("--hide")
    let enableScreenshots = args.contains("--screenshots")
    var priorDays = 2  // Default: 2 days before reservation

    // Parse --prior flag
    if let priorIndex = args.firstIndex(of: "--prior") {
      if priorIndex + 1 < args.count {
        let priorValue = args[priorIndex + 1]
        if let prior = Int(priorValue), prior > 0 {
          priorDays = prior
          print("📅 Using \(priorDays) days prior to reservation (--prior flag)")
        } else {
          print("❌ Invalid --prior value: \(priorValue). Must be a positive number.")
          exit(1)
        }
      } else {
        print("❌ --prior flag requires a number value")
        exit(1)
      }
    }

    if runNow {
      print("⚡ Running reservations immediately (--now flag detected)")
    }

    if hideInfo {
      print("🕶️ Hiding sensitive information (--hide flag detected)")
    }

    if enableScreenshots {
      print("📸 Screenshot capture enabled (--screenshots flag detected)")
    }

    return (runNow, priorDays, hideInfo, enableScreenshots)
  }

  private static func getExportToken() -> String {
    guard let exportToken = ProcessInfo.processInfo.environment["ODYSSEY_EXPORT_TOKEN"] else {
      print("❌ ODYSSEY_EXPORT_TOKEN environment variable not set")
      print("💡 Please set your export token:")
      print("   export ODYSSEY_EXPORT_TOKEN=\"<exported_token>\"")
      exit(1)
    }
    return exportToken
  }

  private static func setupScreenshotDirectory() async {
    // Create screenshots directory in current working directory
    let screenshotDir = "screenshots"

    let webKitService = await ServiceRegistry.shared.resolve(WebKitServiceProtocol.self)
    await MainActor.run {
      webKitService.setScreenshotDirectory(screenshotDir)
    }

    logger.info("📸 Screenshot directory configured: \(screenshotDir).")
  }

  private static func captureFailureScreenshots(configStatuses: [UUID: ReservationRunStatus]) async
  {
    let failedConfigs = configStatuses.filter { _, status in
      if case .failed = status { return true }
      return false
    }

    if failedConfigs.isEmpty {
      return
    }

    print("📸 Screenshots were captured during reservation failures.")
    print("📸 Check the 'screenshots/' directory for failure screenshots.")

    // List any existing screenshot files
    let fileManager = FileManager.default
    let screenshotDir = "screenshots"

    if fileManager.fileExists(atPath: screenshotDir) {
      do {
        let files = try fileManager.contentsOfDirectory(atPath: screenshotDir)
        let screenshotFiles = files.filter { $0.hasSuffix(".png") }

        if !screenshotFiles.isEmpty {
          print("📸 Found \(screenshotFiles.count) screenshot file(s):")
          for file in screenshotFiles {
            print("   📸 \(file)")
          }
        }
      } catch {
        print("⚠️ Could not list screenshot files: \(error.localizedDescription)")
      }
    }
  }

  private static func printConfigurationSummary(
    _ exportConfig: CLIExportService.CLIExportConfig, hideInfo: Bool = false
  ) {
    if hideInfo {
      print("👤 User: ***")
      print("📧 Email: ***@***")
      print("📋 Configurations: \(exportConfig.selectedConfigurations.count)")
    } else {
      print("👤 User: \(exportConfig.userSettings.name)")
      print(
        "📧 Email: ***@\(exportConfig.userSettings.imapEmail.components(separatedBy: "@").last ?? "unknown")"
      )
      print("📋 Configurations: \(exportConfig.selectedConfigurations.count)")
    }
    print()
  }

  private static func handleEmptyConfigurations(
    _ exportConfig: CLIExportService.CLIExportConfig, priorDays: Int, hideInfo: Bool = false
  ) {
    print("❌ No configurations are scheduled to run today")
    print("📅 Today's date: \(formatDate(Date()))")
    print()
    print("📋 All configurations:")
    for (index, config) in exportConfig.selectedConfigurations.enumerated() {
      let nextRunDate = getNextRunDate(for: config, priorDays: priorDays)
      if hideInfo {
        print("   - Configuration \(index + 1): Next run \(formatDate(nextRunDate))")
      } else {
        print("   - \(config.name): Next run \(formatDate(nextRunDate))")
      }
    }
  }

  private static func waitForReservationCompletion(
    configIds: [UUID],
    hideInfo: Bool = false,
    enableScreenshots: Bool = false
  ) async {
    var attempts = 0
    let maxAttempts = 300  // 5 minutes timeout
    var lastStatus = ReservationRunStatus.idle
    var lastProgressUpdate = 0
    var lastLogCheck = 0
    var hasStarted = false
    var configStatuses: [UUID: ReservationRunStatus] = [:]

    // Initialize config statuses
    for configId in configIds {
      configStatuses[configId] = .idle
    }

    print("📊 Monitoring reservation progress...")
    print()

    while attempts < maxAttempts {
      let status = await MainActor.run {
        ReservationOrchestrator.shared.lastRunStatus
      }

      // Check individual config statuses
      let currentConfigStatuses = await getCurrentConfigStatuses(configStatuses: configStatuses)

      // Handle status changes
      await handleStatusChange(status: status, lastStatus: &lastStatus, hasStarted: &hasStarted)

      // Handle individual config status changes
      await handleConfigStatusChanges(
        currentConfigStatuses: currentConfigStatuses,
        configStatuses: &configStatuses,
        hideInfo: hideInfo,
      )

      // Show logs and progress
      await showLogsAndProgress(
        attempts: attempts,
        lastLogCheck: &lastLogCheck,
        lastProgressUpdate: &lastProgressUpdate,
      )

      // Check if all configs are done
      if await areAllConfigsDone(configStatuses: configStatuses) {
        await printDetailedResults(configIds: configIds, finalStatuses: configStatuses)

        // Capture screenshots for failed configurations (only if enabled)
        if enableScreenshots {
          await captureFailureScreenshots(configStatuses: configStatuses)
        }

        break
      }

      try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
      attempts += 1
    }

    // If timed out, print summary with current statuses
    if attempts >= maxAttempts {
      print("⏰ Reservations timed out after 5 minutes")
      logToTerminal("⏰ Reservations timed out after 5 minutes", level: "ERROR")
      await printDetailedResults(
        configIds: configIds, finalStatuses: configStatuses, timedOut: true)

      // Capture screenshots for timed out configurations (only if enabled)
      if enableScreenshots {
        await captureFailureScreenshots(configStatuses: configStatuses)
      }
    }
  }

  private static func getCurrentConfigStatuses(configStatuses: [UUID: ReservationRunStatus]) async
    -> [UUID: ReservationRunStatus]
  {
    await MainActor.run {
      let statusManager = ReservationStatusManager.shared
      return configStatuses.keys.reduce(into: [UUID: ReservationRunStatus]()) { result, configId in
        if let lastRunInfo = statusManager.getLastRunInfo(for: configId) {
          result[configId] = lastRunInfo.status
        }
      }
    }
  }

  private static func handleStatusChange(
    status: ReservationRunStatus,
    lastStatus: inout ReservationRunStatus,
    hasStarted: inout Bool,
  ) async {
    if status != lastStatus {
      switch status {
      case .running:
        if !hasStarted {
          print("🔄 Status: Starting automation...")
          logToTerminal("🚀 Reservation automation started", level: "INFO")
          hasStarted = true
        }
      case .success:
        // Do not print success here; wait for all configs to finish
        break
      case let .failed(error):
        print("❌ Status: Some reservations failed!")
        print("💡 Error: \(error)")
        logToTerminal("❌ Reservation failed: \(error)", level: "ERROR")
      case .idle:
        if hasStarted {
          print("ℹ️ Status: Automation idle")
        }
      case .stopped:
        print("⏹️ Status: Automation stopped")
        logToTerminal("⏹️ Automation stopped", level: "WARNING")
      }
      lastStatus = status
    }
  }

  private static func handleConfigStatusChanges(
    currentConfigStatuses: [UUID: ReservationRunStatus],
    configStatuses: inout [UUID: ReservationRunStatus],
    hideInfo: Bool = false,
  ) async {
    for (configId, configStatus) in currentConfigStatuses {
      if configStatuses[configId] != configStatus {
        configStatuses[configId] = configStatus
        if let configName = await getConfigName(for: configId) {
          printConfigStatus(configName: configName, status: configStatus, hideInfo: hideInfo)
        }
      }
    }
  }

  private static func printConfigStatus(
    configName: String, status: ReservationRunStatus, hideInfo: Bool = false
  ) {
    let displayName = hideInfo ? "Configuration" : configName
    switch status {
    case .running:
      print("   🔄 \(displayName): Starting...")
    case .success:
      print("   ✅ \(displayName): Completed successfully!")
    case let .failed(error):
      print("   ❌ \(displayName): Failed - \(error)")
    case .idle:
      break  // Don't show idle status
    case .stopped:
      print("   ⏹️ \(displayName): Stopped")
    }
  }

  private static func showLogsAndProgress(
    attempts: Int,
    lastLogCheck: inout Int,
    lastProgressUpdate: inout Int,
  ) async {
    // Show real-time logs every 2 seconds
    if attempts % 2 == 0, attempts > lastLogCheck {
      await showRecentLogs()
      lastLogCheck = attempts
    }

    // Show progress updates every 10 seconds
    if attempts % 10 == 0, attempts > lastProgressUpdate {
      print("⏳ Still running... (\(attempts)s)")
      lastProgressUpdate = attempts
    }
  }

  private static func areAllConfigsDone(configStatuses: [UUID: ReservationRunStatus]) async -> Bool
  {
    configStatuses.values.count(where: { status in
      switch status {
      case .success, .failed: return true
      default: return false
      }
    }) == configStatuses.count
  }

  private static func getConfigName(for configId: UUID) async -> String? {
    // Try to get config name from ConfigurationManager
    await MainActor.run {
      let configs = ConfigurationManager.shared.settings.configurations
      return configs.first { $0.id == configId }?.name ?? "Unknown Config"
    }
  }

  private static func showRecentLogs() async {
    // Get logs directly from LoggingService
    let recentLogs = await MainActor.run {
      LoggingService.shared.getRecentLogs(limit: 5)
    }

    for logEntry in recentLogs {
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm:ss"
      let timestamp = formatter.string(from: logEntry.timestamp)

      let levelIcon =
        switch logEntry.level {
        case .success: "✅"
        case .warning: "⚠️"
        case .error: "❌"
        case .info: "📝"
        }

      let configPrefix = logEntry.configName.map { "[\($0)] " } ?? ""
      print("   \(levelIcon) [\(timestamp)] \(configPrefix)\(logEntry.message)")
    }

    // If no recent logs, show a progress indicator
    if recentLogs.isEmpty {
      print("   ⏳ Processing reservation steps...")
    }
  }

  private static func printDetailedResults(
    configIds: [UUID],
    finalStatuses: [UUID: ReservationRunStatus],
    timedOut: Bool = false,
  ) async {
    print("\n📊 Detailed Results:")
    print("===================")
    let configs = await MainActor.run { ConfigurationManager.shared.settings.configurations }
    var allSucceeded = true
    for configId in configIds {
      let configName = configs.first { $0.id == configId }?.name ?? "Unknown Config"
      let status = finalStatuses[configId] ?? .idle
      switch status {
      case .success:
        print("✅ \(configName): Success")
      case let .failed(error):
        print("❌ \(configName): Failed - \(error)")
        allSucceeded = false
      case .running:
        if timedOut {
          print("⏳ \(configName): Timed out (did not complete)")
        } else {
          print("⏳ \(configName): Still running (unexpected)")
        }
        allSucceeded = false
      case .idle:
        print("⚪️ \(configName): Idle (not started)")
        allSucceeded = false
      case .stopped:
        print("⏹️ \(configName): Stopped")
        allSucceeded = false
      }
    }
    print()
    if allSucceeded {
      print("✅ All reservations completed successfully!")
    } else if timedOut {
      print("⏰ Some reservations did not complete in time.")
    } else {
      print("❌ Some reservations failed.")
    }
  }

  private static func runReservations(_ args: [String]) async {
    logger.info("🚀 Starting CLI reservation run.")

    // Parse command line arguments
    let (runNow, priorDays, hideInfo, enableScreenshots) = parseArguments(args)

    // Get export token
    let exportToken = getExportToken()

    do {
      // Decode configuration from token
      let exportConfig = try decodeExportToken(exportToken)

      // Print configuration summary
      printConfigurationSummary(exportConfig, hideInfo: hideInfo)

      // Filter configurations that should run today (priorDays before reservation day)
      let configsToRun = exportConfig.selectedConfigurations.filter { config in
        shouldRunReservation(config: config, at: Date(), priorDays: priorDays)
      }

      print(
        "🔍 Found \(configsToRun.count) configurations scheduled for today (\(priorDays) days before reservation)",
      )

      if configsToRun.isEmpty {
        handleEmptyConfigurations(exportConfig, priorDays: priorDays, hideInfo: hideInfo)
        return
      }

      // Setup screenshot directory for failure captures (only if screenshots enabled)
      if enableScreenshots {
        await setupScreenshotDirectory()
      }

      // Check current time and wait if necessary (skip if --now is used)
      if !runNow {
        let targetTime = getDefaultTargetTime()
        await waitUntilTargetTime(targetTime)
      } else {
        print("⏰ Skipping time check (--now flag)")
      }

      // Update managers with CLI data
      await updateUserSettingsForCLI(exportConfig.userSettings)
      await updateConfigurationManagerForCLI(exportConfig.selectedConfigurations)

      // Run all reservations in parallel using God Mode
      print("🚀 Starting reservation automation for \(configsToRun.count) configurations...")

      // Run all reservations in parallel using MainActor
      await MainActor.run {
        let orchestrator = ReservationOrchestrator.shared
        print("🚀 Starting automation for \(configsToRun.count) configurations...")
        for (index, config) in configsToRun.enumerated() {
          let configName = config.name.isEmpty ? "Config \(index + 1)" : config.name
          print("   📋 \(index + 1). \(configName) - \(config.sportName)")
        }
        print()
        orchestrator.runMultipleReservations(for: configsToRun, runType: .manual)
      }

      // Wait for completion
      await waitForReservationCompletion(
        configIds: configsToRun.map(\.id),
        hideInfo: hideInfo,
        enableScreenshots: enableScreenshots
      )

      print()

      logger.info("✅ CLI reservation run completed.")

    } catch {
      logger.error("❌ Failed to load configuration from token: \(error.localizedDescription).")
      print("❌ Error loading configuration: \(error.localizedDescription)")
      exit(1)
    }
  }

  private static func getDefaultTargetTime() -> Date {
    let calendar = Calendar.current
    let now = Date()

    // Set timezone to Toronto
    guard let torontoTimeZone = TimeZone(identifier: "America/Toronto") else {
      logger.error("❌ Failed to get Toronto timezone.")
      return now
    }
    var torontoCalendar = calendar
    torontoCalendar.timeZone = torontoTimeZone

    // Create target time: 6:00:01 PM today
    var components = torontoCalendar.dateComponents([.year, .month, .day], from: now)
    components.hour = 18
    components.minute = 0
    components.second = 1
    components.timeZone = torontoTimeZone

    return torontoCalendar.date(from: components) ?? now
  }

  private static func waitUntilTargetTime(_ targetTime: Date) async {
    let calendar = Calendar.current
    guard let torontoTimeZone = TimeZone(identifier: "America/Toronto") else {
      logger.error("❌ Failed to get Toronto timezone.")
      return
    }
    var torontoCalendar = calendar
    torontoCalendar.timeZone = torontoTimeZone

    let now = Date()

    if now >= targetTime {
      print("⏰ Current time is \(formatTime(now)) - proceeding immediately")
      return
    }

    let timeInterval = targetTime.timeIntervalSince(now)
    print("⏰ Current time is \(formatTime(now))")
    print("⏰ Waiting until \(formatTime(targetTime)) (Toronto timezone)")
    print("⏰ Waiting \(Int(timeInterval)) seconds...")

    // Wait in 10-second intervals to show progress
    let waitInterval: TimeInterval = AppConstants.waitInterval
    var remainingTime = timeInterval

    while remainingTime > 0 {
      let sleepTime = min(waitInterval, remainingTime)
      try? await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
      remainingTime -= sleepTime

      if remainingTime > 0 {
        print("⏰ Still waiting... \(Int(remainingTime)) seconds remaining")
      }
    }

    print("⏰ Target time reached! Starting reservations...")
  }

  private static func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    formatter.timeZone = TimeZone(identifier: "America/Toronto") ?? TimeZone.current
    return formatter.string(from: date)
  }

  private static func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeZone = TimeZone(identifier: "America/Toronto") ?? TimeZone.current
    return formatter.string(from: date)
  }

  private static func decodeExportToken(_ base64String: String) throws
    -> CLIExportService.CLIExportConfig
  {
    guard let data = Data(base64Encoded: base64String) else {
      throw CLIExportError.invalidBase64
    }

    // Decompress data
    let decompressedData = try (data as NSData).decompressed(using: .lzfse)

    // Decode JSON
    let decoder = JSONDecoder()
    let exportConfig = try decoder.decode(
      CLIExportService.CLIExportConfig.self, from: decompressedData as Data)

    return exportConfig
  }

  private static func shouldRunReservation(
    config: ReservationConfig, at date: Date, priorDays: Int = 2
  ) -> Bool {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: date)

    // For each enabled day, check if today is priorDays before that day
    for (day, timeSlots) in config.dayTimeSlots {
      guard !timeSlots.isEmpty else { continue }

      // Check if today is the autorun day for any upcoming reservation
      for weekOffset in 0...4 {
        let baseDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today) ?? today

        // Find the next occurrence of the reservation day from the base date
        let targetWeekday = day.calendarWeekday
        let baseWeekday = calendar.component(.weekday, from: baseDate)
        var daysUntilTarget = targetWeekday - baseWeekday
        if daysUntilTarget <= 0 { daysUntilTarget += 7 }
        let reservationDay =
          calendar.date(byAdding: .day, value: daysUntilTarget, to: baseDate) ?? baseDate

        // Autorun should be priorDays before reservation day
        let autorunDay =
          calendar.date(byAdding: .day, value: -priorDays, to: reservationDay) ?? reservationDay

        if calendar.isDate(today, inSameDayAs: autorunDay) {
          return true
        }
      }
    }
    return false
  }

  private static func getNextRunDate(for config: ReservationConfig, priorDays: Int = 2) -> Date {
    let calendar = Calendar.current
    let now = Date()
    let today = calendar.startOfDay(for: now)

    var nextRunDate: Date?

    // For each enabled day, find the next autorun date
    for (day, timeSlots) in config.dayTimeSlots {
      guard !timeSlots.isEmpty else { continue }

      // Look for the next autorun date that hasn't passed yet
      // We need to check multiple weeks ahead to find the next valid autorun date
      for weekOffset in 0...4 {
        let baseDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today) ?? today

        // Find the next occurrence of the reservation day from the base date
        let targetWeekday = day.calendarWeekday
        let baseWeekday = calendar.component(.weekday, from: baseDate)
        var daysUntilTarget = targetWeekday - baseWeekday
        if daysUntilTarget <= 0 { daysUntilTarget += 7 }
        let reservationDay =
          calendar.date(byAdding: .day, value: daysUntilTarget, to: baseDate) ?? baseDate

        // Autorun should be priorDays before reservation day
        let autorunDay =
          calendar.date(byAdding: .day, value: -priorDays, to: reservationDay) ?? reservationDay

        // Only consider autorun dates that are today or in the future
        if autorunDay >= today {
          if let currentNextRunDate = nextRunDate {
            if autorunDay < currentNextRunDate {
              nextRunDate = autorunDay
            }
          } else {
            nextRunDate = autorunDay
          }
          // Found a valid autorun date, no need to check more weeks
          break
        }
      }
    }

    return nextRunDate ?? today
  }

  private static func listConfigurations() async {
    // Check for export token in environment
    guard let exportToken = ProcessInfo.processInfo.environment["ODYSSEY_EXPORT_TOKEN"] else {
      print("❌ ODYSSEY_EXPORT_TOKEN environment variable not set")
      print("💡 Please set your export token:")
      print("   export ODYSSEY_EXPORT_TOKEN=\"<exported_token>\"")
      exit(1)
    }

    do {
      // Decode configuration from token
      let exportConfig = try decodeExportToken(exportToken)

      print("📋 Available Configurations:")
      print(String(repeating: "=", count: 50))

      for (index, config) in exportConfig.selectedConfigurations.enumerated() {
        let status = config.isEnabled ? "✅" : "❌"
        print("\(index + 1). \(status) \(config.name)")
        print("   \(bold("Sport")): \(config.sportName)")
        print(
          "   \(bold("Facility")): \(ReservationConfig.extractFacilityName(from: config.facilityURL))"
        )
        print("   \(bold("People")): \(config.numberOfPeople)")
        print("   \(bold("Time Slots")):")

        // Sort weekdays for consistent display
        let sortedDays = config.dayTimeSlots.keys.sorted { day1, day2 in
          guard
            let index1 = ReservationConfig.Weekday.allCases.firstIndex(of: day1),
            let index2 = ReservationConfig.Weekday.allCases.firstIndex(of: day2)
          else {
            return false
          }
          return index1 < index2
        }

        for day in sortedDays {
          if let timeSlots = config.dayTimeSlots[day], !timeSlots.isEmpty {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeStrings = timeSlots.map { formatter.string(from: $0.time) }.sorted()
            let dayName = day.localizedShortName
            print("     \(dayName): \(timeStrings.joined(separator: ", "))")
          }
        }
        print()
      }
    } catch {
      logger.error("❌ Failed to load configuration from token: \(error.localizedDescription).")
      print("❌ Error loading configuration: \(error.localizedDescription)")
      exit(1)
    }
  }

  // MARK: - Settings Management

  private static func showUserSettings(unmask: Bool = false) async {
    // Check for export token in environment
    guard let exportToken = ProcessInfo.processInfo.environment["ODYSSEY_EXPORT_TOKEN"] else {
      print("❌ ODYSSEY_EXPORT_TOKEN environment variable not set")
      print("💡 Please set your export token:")
      print("   export ODYSSEY_EXPORT_TOKEN=\"<exported_token>\"")
      exit(1)
    }

    do {
      // Decode configuration from token
      let exportConfig = try decodeExportToken(exportToken)

      print("📋 User Settings:")
      print(String(repeating: "=", count: 30))
      print("\(bold("Name")): \(exportConfig.userSettings.name)")

      if unmask {
        print("\(bold("Phone")): \(exportConfig.userSettings.phoneNumber)")
        print("\(bold("Email")): \(exportConfig.userSettings.imapEmail)")
        print("\(bold("IMAP Password")): \(exportConfig.userSettings.imapPassword)")
      } else {
        print("\(bold("Phone")): ***\(String(exportConfig.userSettings.phoneNumber.suffix(3)))")
        print(
          "\(bold("Email")): ***@\(exportConfig.userSettings.imapEmail.components(separatedBy: "@").last ?? "unknown")",
        )
        print("\(bold("IMAP Password")): ***")
      }

      print("\(bold("IMAP Server")): \(exportConfig.userSettings.imapServer)")

      print()

    } catch {
      logger.error("❌ Failed to load configuration from token: \(error.localizedDescription).")
      print("❌ Error loading configuration: \(error.localizedDescription)")
      exit(1)
    }
  }

}
