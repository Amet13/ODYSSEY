import AppKit
import Combine
import Foundation
import os.log

// MARK: - ReservationRunStatusCodable (Top-level)

// Codable wrapper for run status, used for persistence and status tracking
public struct ReservationRunStatusCodable: Codable, Equatable {
  public let status: ReservationRunStatus
  public let date: Date?
  public let runType: ReservationRunType
}

@MainActor
public final class ReservationOrchestrator: ObservableObject, @unchecked Sendable,
  @preconcurrency ReservationOrchestratorProtocol
{
  public static let shared = ReservationOrchestrator()
  public var lastRunStatus: ReservationRunStatus { statusManager.lastRunStatus }

  // Core dependencies for orchestrating automation runs
  private let statusManager: ReservationStatusManager
  private let errorHandler: ReservationErrorHandler
  private let logger: Logger
  private let webKitService: WebKitServiceProtocol
  private let configurationManager: ConfigurationManager
  private var currentConfig: ReservationConfig?

  /// User-facing error message to be displayed in the UI.
  @Published public var userError: String?

  /// Main initializer supporting dependency injection for all major dependencies.
  /// - Parameters:
  ///   - statusManager: ReservationStatusManager instance (default: .shared)
  ///   - errorHandler: ReservationErrorHandler instance (default: .shared)
  ///   - logger: Logger instance (default: ODYSSEY ReservationOrchestrator logger)
  ///   - webKitService: WebKitServiceProtocol instance (default: ServiceRegistry)
  ///   - configurationManager: ConfigurationManager instance (default: .shared)
  public init(
    statusManager: ReservationStatusManager = ReservationStatusManager.shared,
    errorHandler: ReservationErrorHandler = ReservationErrorHandler.shared,
    logger: Logger = Logger(
      subsystem: AppConstants.loggingSubsystem,
      category: LoggerCategory.reservationOrchestrator.categoryName,
    ),
    webKitService: WebKitServiceProtocol = ServiceRegistry.shared.resolve(
      WebKitServiceProtocol.self),
    configurationManager: ConfigurationManager = ConfigurationManager.shared
  ) {
    self.statusManager = statusManager
    self.errorHandler = errorHandler
    self.logger = logger
    self.webKitService = webKitService
    self.configurationManager = configurationManager
  }

  // Keep the default singleton for app use
  convenience init() {
    self.init(
      statusManager: ReservationStatusManager.shared,
      errorHandler: ReservationErrorHandler.shared,
      logger: Logger(
        subsystem: AppConstants.loggingSubsystem,
        category: LoggerCategory.reservationOrchestrator.categoryName),
      webKitService: ServiceRegistry.shared.resolve(WebKitServiceProtocol.self),
      configurationManager: ConfigurationManager.shared,
    )
  }

  deinit {
    logger.info("🧹 ReservationOrchestrator deinitialized.")
  }

  // MARK: - Orchestration Methods

  /**
   Runs a single reservation for the given configuration and run type.
   - Parameters:
   - config: The reservation configuration to run.
   - runType: The type of run (manual, automatic, godmode).
   */
  public func runReservation(for config: ReservationConfig, runType: ReservationRunType = .manual) {
    guard !statusManager.isRunning else {
      logger.warning("⚠️ Reservation already running, skipping.")
      return
    }
    statusManager.isRunning = true
    statusManager.lastRunStatus = .running
    statusManager.setLastRunInfo(for: config.id, status: .running, date: Date(), runType: runType)
    Task {
      do {
        try await withTimeout(seconds: AppConstants.reservationTimeout) {
          try await self.performReservation(for: config, runType: runType)
        }
      } catch {
        // Set user-facing error
        await MainActor.run { self.userError = error.localizedDescription }
        logger.error("❌ Reservation failed with error: \(error.localizedDescription).")
        logger.error("🔍 Error type: \(type(of: error)).")
        logger.error("📋 Error details: \(error).")
        await errorHandler.handleReservationError(error, config: config, runType: runType)
      }
    }
  }

  // Protocol-compliant version
  public func runReservation(for config: ReservationConfig, type: ReservationRunType) async {
    // Call the original method with the correct parameter name
    runReservation(for: config, runType: type)
  }

  public func stopReservation() async {
    logger.info("🛑 Stopping reservation...")
    statusManager.lastRunStatus = .stopped
    statusManager.isRunning = false
    // Additional cleanup logic can be added here
  }

  /**
   Runs multiple reservations in parallel for the given configurations and run type.
   - Parameters:
   - configs: The reservation configurations to run.
   - runType: The type of run (manual, automatic, godmode).
   */
  public func runMultipleReservations(
    for configs: [ReservationConfig], runType: ReservationRunType = .manual
  ) {
    guard !configs.isEmpty else {
      logger.warning("⚠️ No configurations provided for multiple reservation run.")
      return
    }
    logger.info("🚀 Starting God Mode: Running \(configs.count) configurations simultaneously.")
    statusManager.isRunning = true
    statusManager.lastRunStatus = .running
    statusManager.currentTask = "God Mode: Running \(configs.count) configurations"
    statusManager.lastRunDate = Date()
    Task {
      await self.trackGodModeCompletion(configs: configs, runType: runType)
    }
    for config in configs {
      Task {
        await self.runReservationWithSeparateWebKit(for: config, runType: runType)
      }
    }
  }

  /**
   Cancels all running reservations and resets state.
   */
  public func stopAllReservations() async {
    if statusManager.isRunning, let config = currentConfig {
      logger.warning(
        "🚨 Emergency cleanup triggered - capturing screenshot and sending notification.")
      logger.error(
        "🚨 Emergency cleanup triggered for \(config.name): automation was interrupted unexpectedly."
      )
      await MainActor.run {
        // Always set isRunning = false for emergency cleanup
        statusManager.isRunning = false
        statusManager.lastRunStatus = .failed(
          "Emergency cleanup - automation was interrupted unexpectedly")
        statusManager.currentTask = "Emergency cleanup completed"
        statusManager.lastRunDate = Date()
        statusManager.setLastRunInfo(
          for: config.id,
          status: .failed("Emergency cleanup - automation was interrupted unexpectedly"),
          date: Date(),
          runType: .automatic,
        )
      }
    }
    await webKitService.disconnect(closeWindow: false)
  }

  public func emergencyCleanup(runType _: ReservationRunType) async {
    if statusManager.isRunning, let config = currentConfig {
      logger.warning(
        "🚨 Emergency cleanup triggered - capturing screenshot and sending notification.")
      logger.error(
        "🚨 Emergency cleanup triggered for \(config.name): automation was interrupted unexpectedly."
      )
      await MainActor.run {
        // Always set isRunning = false for emergency cleanup
        statusManager.isRunning = false
        statusManager.lastRunStatus = .failed(
          "Emergency cleanup - automation was interrupted unexpectedly")
        statusManager.currentTask = "Emergency cleanup completed"
        statusManager.lastRunDate = Date()
        statusManager.setLastRunInfo(
          for: config.id,
          status: .failed("Emergency cleanup - automation was interrupted unexpectedly"),
          date: Date(),
          runType: .automatic,
        )
      }
    }
    await webKitService.disconnect(closeWindow: false)
  }

  public func handleManualWindowClosure(runType: ReservationRunType) async {
    logger.info("👤 Manual window closure detected - resetting reservation state.")
    await MainActor.run {
      if runType == .manual {
        statusManager.isRunning = false
      }
      statusManager.lastRunStatus = .failed("Reservation cancelled - window was closed manually")
      statusManager.currentTask = "Reservation cancelled by user"
      statusManager.lastRunDate = Date()
      if let config = self.currentConfig {
        statusManager.setLastRunInfo(
          for: config.id,
          status: .failed("Reservation cancelled - window was closed manually"),
          date: Date(),
          runType: runType,
        )
      }
    }
    await webKitService.forceReset()
  }

  // MARK: - Private Methods

  /// Formats phone number by removing dashes
  private func formatPhoneNumber(_ phoneNumber: String) -> String {
    return phoneNumber.replacingOccurrences(of: "-", with: "")
  }

  /**
   Performs the reservation logic for a given configuration and run type.
   - Parameters:
   - config: The reservation configuration to run.
   - runType: The type of run.
   */
  private func performReservation(for config: ReservationConfig, runType: ReservationRunType)
    async throws
  {
    statusManager.currentTask = "Starting reservation for \(config.name)"
    currentConfig = config

    // Log to direct logging service
    LoggingService.shared.log(
      "Starting reservation for \(config.name)",
      level: .info,
      configId: config.id,
      configName: config.name,
    )

    await updateTask("Checking WebKit service state")
    if !webKitService.isServiceValid() {
      logger.info("🔄 WebKit service not in valid state, resetting.")
      LoggingService.shared.log(
        "WebKit service not in valid state, resetting",
        level: .warning,
        configId: config.id,
        configName: config.name,
      )
      await webKitService.reset()
    }
    webKitService.onWindowClosed = { [weak self] runType in
      Task { await self?.handleManualWindowClosure(runType: runType) }
    }
    await updateTask("Starting WebKit session")
    LoggingService.shared.log(
      "Starting WebKit session", level: .info, configId: config.id, configName: config.name)
    try await webKitService.connect()
    webKitService.currentConfig = config
    await updateTask("Navigating to facility")
    LoggingService.shared.log(
      "Navigating to facility", level: .info, configId: config.id, configName: config.name)
    try await webKitService.navigateToURL(config.facilityURL)
    await updateTask("Checking for cookie consent...")
    await updateTask("Waiting for page to load")
    let domReady = await webKitService.waitForDOMReady()
    if !domReady {
      logger.error("⏰ DOM failed to load properly within timeout.")
      LoggingService.shared.log(
        "DOM failed to load properly within timeout",
        level: .error,
        configId: config.id,
        configName: config.name,
      )
      self.userError = ReservationError.pageLoadTimeout.errorDescription
      throw ReservationError.pageLoadTimeout
    }

    LoggingService.shared.log(
      "Page loaded successfully",
      level: .success,
      configId: config.id,
      configName: config.name,
    )
    await updateTask("Looking for sport: \(config.sportName)")
    logger.info("🔍 Searching for sport button with text: '\(config.sportName, privacy: .private)'.")
    LoggingService.shared.log(
      "Searching for sport button: \(config.sportName)",
      level: .info,
      configId: config.id,
      configName: config.name,
    )
    let buttonClicked = await webKitService.findAndClickElement(withText: config.sportName)
    if buttonClicked {
      logger.info("✅ Successfully clicked sport button: \(config.sportName, privacy: .private).")
      LoggingService.shared.log(
        "Successfully clicked sport button",
        level: .success,
        configId: config.id,
        configName: config.name,
      )
      await updateTask("Waiting for group size page...")
      let groupSizePageReady = await webKitService.waitForGroupSizePage()
      if !groupSizePageReady {
        logger.error("⏰ Group size page failed to load within timeout.")
        LoggingService.shared.log(
          "Group size page failed to load within timeout",
          level: .error,
          configId: config.id,
          configName: config.name,
        )
        self.userError = ReservationError.groupSizePageLoadTimeout.errorDescription
        throw ReservationError.groupSizePageLoadTimeout
      }

      LoggingService.shared.log(
        "Group size page loaded successfully",
        level: .success,
        configId: config.id,
        configName: config.name,
      )
      await updateTask("Setting number of people: \(config.numberOfPeople)")
      let peopleFilled = await webKitService.fillNumberOfPeople(config.numberOfPeople)
      if !peopleFilled {
        logger.error("❌ Failed to fill number of people field.")
        LoggingService.shared.log(
          "Failed to fill number of people field",
          level: .error,
          configId: config.id,
          configName: config.name,
        )
        self.userError = ReservationError.numberOfPeopleFieldNotFound.errorDescription
        throw ReservationError.numberOfPeopleFieldNotFound
      }
      logger.info("✅ Successfully filled number of people: \(config.numberOfPeople).")
      LoggingService.shared.log(
        "Successfully filled number of people: \(config.numberOfPeople)",
        level: .success,
        configId: config.id,
        configName: config.name,
      )
      await updateTask("Confirming group size...")
      let confirmClicked = await webKitService.clickConfirmButton()
      if !confirmClicked {
        logger.error("❌ Failed to click confirm button.")
        LoggingService.shared.log(
          "Failed to click confirm button",
          level: .error,
          configId: config.id,
          configName: config.name,
        )
        self.userError = ReservationError.confirmButtonNotFound.errorDescription
        throw ReservationError.confirmButtonNotFound
      }
      logger.info("✅ Successfully clicked confirm button.")
      LoggingService.shared.log(
        "Successfully clicked confirm button",
        level: .success,
        configId: config.id,
        configName: config.name,
      )
      await updateTask("Waiting for time selection page...")
      logger.info("⏭️ Skipping time selection page detection - page already loaded.")
      await updateTask("Selecting time slot...")
      let selectedDay = config.dayTimeSlots.keys.first
      let selectedTimeSlot = selectedDay.flatMap { day in config.dayTimeSlots[day]?.first }
      if let day = selectedDay, let timeSlot = selectedTimeSlot {
        let dayName = day.shortName
        let timeString = timeSlot.formattedTime()
        logger.info("📅 Attempting to select: \(dayName) at \(timeString, privacy: .private).")
        LoggingService.shared.log(
          "Attempting to select time slot: \(dayName) at \(timeString)",
          level: .info,
          configId: config.id,
          configName: config.name,
        )

        // Use our new functions: expand day section first, then click time button
        let dayExpanded = await webKitService.expandDaySection(dayName: dayName)
        if !dayExpanded {
          logger.error("❌ Failed to expand day section: \(dayName, privacy: .private).")
          LoggingService.shared.log(
            "Failed to expand day section: \(dayName)",
            level: .error,
            configId: config.id,
            configName: config.name,
          )
          throw ReservationError.timeSlotSelectionFailed
        }

        // Wait for time buttons to load
        try await Task.sleep(nanoseconds: AppConstants.humanDelayNanoseconds)

        let timeSlotClicked = await webKitService.clickTimeButton(
          timeString: timeString, dayName: dayName)
        if !timeSlotClicked {
          logger.error("❌ Failed to click time button: \(timeString, privacy: .private).")
          LoggingService.shared.log(
            "Failed to click time button: \(timeString)",
            level: .error,
            configId: config.id,
            configName: config.name,
          )
          throw ReservationError.timeSlotSelectionFailed
        }

        logger.info(
          "✅ Successfully selected time slot: \(dayName) at \(timeString, privacy: .private).")
        LoggingService.shared.log(
          "Successfully selected time slot: \(dayName) at \(timeString)",
          level: .success,
          configId: config.id,
          configName: config.name,
        )
      } else {
        logger.warning("⚠️ No time slots configured, skipping time selection.")
        LoggingService.shared.log(
          "No time slots configured, skipping time selection",
          level: .warning,
          configId: config.id,
          configName: config.name,
        )
      }
      await updateTask("Waiting for contact information page...")
      let contactInfoPageReady =
        await withTimeout(
          seconds: 10,
          operation: { @MainActor in
            await self.webKitService.waitForContactInfoPage()
          }) ?? false
      if !contactInfoPageReady {
        logger.error("⏰ Contact information page failed to load within timeout.")
        LoggingService.shared.log(
          "Contact information page failed to load within timeout",
          level: .error,
          configId: config.id,
          configName: config.name,
        )
        self.userError = ReservationError.contactInfoPageLoadTimeout.errorDescription
        throw ReservationError.contactInfoPageLoadTimeout
      }

      LoggingService.shared.log(
        "Contact information page loaded successfully",
        level: .success,
        configId: config.id,
        configName: config.name,
      )
      await updateTask("Filling contact information...")
      LoggingService.shared.log(
        "Filling contact information",
        level: .info,
        configId: config.id,
        configName: config.name,
      )

      logger.info(
        "📝 Proceeding with browser autofill-style form filling to avoid triggering captchas.")
      await updateTask("Filling contact information with simultaneous autofill...")
      let userSettings = UserSettingsManager.shared.userSettings
      let phoneNumber = formatPhoneNumber(userSettings.phoneNumber)
      let allFieldsFilled = await webKitService.fillAllContactFieldsWithAutofillAndHumanMovements(
        phoneNumber: phoneNumber,
        email: userSettings.imapEmail,
        name: userSettings.name,
      )
      if !allFieldsFilled {
        logger.error("❌ Failed to fill all contact fields simultaneously.")
        LoggingService.shared.log(
          "Failed to fill all contact fields simultaneously",
          level: .error,
          configId: config.id,
          configName: config.name,
        )
        self.userError = ReservationError.contactInfoFieldNotFound.errorDescription
        throw ReservationError.contactInfoFieldNotFound
      }
      logger.info(
        "✅ Successfully filled all contact fields simultaneously with autofill and human movements."
      )
      LoggingService.shared.log(
        "Successfully filled all contact fields simultaneously",
        level: .success,
        configId: config.id,
        configName: config.name,
      )

      // Add delay after form filling and before clicking confirm button (1-2 seconds)
      let delaySeconds = Double.random(in: 1.0...2.0)
      logger.info(
        "⏱️ Adding delay of \(String(format: "%.1f", delaySeconds)) seconds after form filling...")
      try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))

      await updateTask("Confirming contact information...")
      let verificationStart = Date()
      var contactConfirmClicked = false
      var retryCount = 0
      let maxRetries = AppConstants.maxRetryAttemptsContactInfo
      while !contactConfirmClicked, retryCount < maxRetries {
        if retryCount > 0 {
          logger.info("🔄 Retry attempt \(retryCount) for confirm button click.")
          LoggingService.shared.log(
            "Retry attempt \(retryCount) for confirm button click",
            level: .warning,
            configId: config.id,
            configName: config.name,
          )
          await updateTask("Retrying confirmation... (Attempt \(retryCount + 1)/\(maxRetries))")
          logger.info("🛡️ Applying essential anti-detection for retry attempt \(retryCount).")
          await updateTask("Applying anti-detection measures...")
          await webKitService.addQuickPause()
          try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...1_800_000_000))
        }

        // Add delay before checking for retry text to allow form filling click to complete
        if retryCount == 0 {
          try? await Task.sleep(nanoseconds: AppConstants.humanDelayNanoseconds)
        }

        let retryTextDetected = await webKitService.detectRetryText()
        if retryTextDetected {
          logger.warning("⚠️ Retry text detected - handling captcha retry.")
          LoggingService.shared.log(
            "Retry text detected - handling captcha retry",
            level: .warning,
            configId: config.id,
            configName: config.name,
          )

          // Handle captcha retry with human behavior simulation
          let captchaRetryHandled = await webKitService.handleCaptchaRetry()
          if captchaRetryHandled {
            logger.info("✅ Captcha retry handled with human behavior simulation.")
            // Wait for the retry to complete
            try? await Task.sleep(nanoseconds: AppConstants.longDelayNanoseconds)

            // Check if retry text is still present after the retry
            let retryTextStillPresent = await webKitService.detectRetryText()
            if retryTextStillPresent {
              logger.warning("⚠️ Retry text still present after captcha retry - will try again.")
              contactConfirmClicked = false
              retryCount += 1
              continue
            } else {
              logger.info("✅ Captcha retry successful - no retry text detected.")
              contactConfirmClicked = true
              break
            }
          } else {
            logger.error("❌ Failed to handle captcha retry.")
            contactConfirmClicked = false
            retryCount += 1
            continue
          }
        }

        // If no retry text, try normal confirm button click
        contactConfirmClicked = await webKitService.clickContactInfoConfirmButtonWithRetry()
        if contactConfirmClicked {
          try? await Task.sleep(nanoseconds: AppConstants.shortDelayNanoseconds)
          let retryTextAfterClick = await webKitService.detectRetryText()
          if retryTextAfterClick {
            logger.warning("⚠️ Retry text detected after confirm button click.")
            LoggingService.shared.log(
              "Retry text detected after confirm button click",
              level: .warning,
              configId: config.id,
              configName: config.name,
            )
            contactConfirmClicked = false  // Will be handled in next iteration
            retryCount += 1
          } else {
            logger.info("✅ Successfully clicked contact confirm button (no retry text detected).")
            LoggingService.shared.log(
              "Successfully clicked contact confirm button",
              level: .success,
              configId: config.id,
              configName: config.name,
            )
            break
          }
        } else {
          retryCount += 1
        }
      }
      if !contactConfirmClicked {
        logger.error("❌ Failed to click contact confirm button after \(maxRetries) attempts.")
        LoggingService.shared.log(
          "Failed to click contact confirm button after \(maxRetries) attempts",
          level: .error,
          configId: config.id,
          configName: config.name,
        )
        self.userError = ReservationError.contactInfoConfirmButtonNotFound.errorDescription
        throw ReservationError.contactInfoConfirmButtonNotFound
      }
      logger.info("✅ Successfully clicked contact confirm button.")
      LoggingService.shared.log(
        "Successfully clicked contact confirm button",
        level: .success,
        configId: config.id,
        configName: config.name,
      )

      await updateTask("Checking for email verification...")
      try? await Task.sleep(nanoseconds: AppConstants.longDelayNanoseconds)
      let verificationRequired = await webKitService.isEmailVerificationRequired()
      if verificationRequired {
        logger.info("📧 Email verification required, starting verification process.")
        LoggingService.shared.log(
          "Email verification required, starting verification process",
          level: .info,
          configId: config.id,
          configName: config.name,
        )
        let verificationSuccess =
          await webKitService
          .handleEmailVerification(verificationStart: verificationStart)
        if !verificationSuccess {
          logger.error("❌ Email verification failed.")
          LoggingService.shared.log(
            "Email verification failed",
            level: .error,
            configId: config.id,
            configName: config.name,
          )
          self.userError = ReservationError.emailVerificationFailed.errorDescription
          throw ReservationError.emailVerificationFailed
        }
        logger.info("✅ Email verification completed successfully.")
        LoggingService.shared.log(
          "Email verification completed successfully",
          level: .success,
          configId: config.id,
          configName: config.name,
        )
        await updateTask("Waiting for confirmation page to load...")
        logger.info("⏳ Waiting for page navigation to complete after email verification.")
        try? await Task.sleep(nanoseconds: AppConstants.humanDelayNanoseconds)
        let domReady = await webKitService.waitForDOMReady()
        if domReady {
          LoggingService.shared.log(
            "Confirmation page loaded successfully",
            level: .success,
            configId: config.id,
            configName: config.name,
          )
        } else {
          logger.warning(
            "⚠️ DOM ready check failed, but continuing with click result as success indicator.")
          LoggingService.shared.log(
            "DOM ready check failed, but continuing",
            level: .warning,
            configId: config.id,
            configName: config.name,
          )
        }
      }

      await updateTask("Finishing reservation...")

      // Check if reservation is actually complete
      logger.info("🔍 Checking if reservation is complete...")
      let reservationComplete = await webKitService.checkReservationComplete()
      if reservationComplete {
        LoggingService.shared.log(
          "Reservation completion confirmed",
          level: .success,
          configId: config.id,
          configName: config.name,
        )
      } else {
        logger.info("⏳ Reservation completion not yet detected, but proceeding with cleanup...")
        LoggingService.shared.log(
          "Reservation completion not yet detected, but proceeding with cleanup",
          level: .info,
          configId: config.id,
          configName: config.name,
        )
      }

      logger.info("🎉 Reservation completed successfully - all steps completed.")
      LoggingService.shared.log(
        "Reservation completed successfully - all steps completed",
        level: .success,
        configId: config.id,
        configName: config.name,
      )

      await MainActor.run {
        if runType == .manual {
          statusManager.isRunning = false
        }
        statusManager.lastRunStatus = .success
        statusManager.setLastRunInfo(
          for: config.id, status: .success, date: Date(), runType: runType)
        statusManager.lastRunDate = Date()
        statusManager.currentTask = "Reservation completed successfully"
      }
      logger.info("🎉 Reservation completed successfully for \(config.name).")
      logger.info("🧹 Cleaning up WebKit session after successful reservation.")
      webKitService.onWindowClosed = nil

      // Always close windows on successful reservation (regardless of settings)
      await webKitService.disconnect(closeWindow: true)
      return
    } else {
      logger.error(
        "❌ Failed to find and click sport button: \(config.sportName, privacy: .private).")
      LoggingService.shared.log(
        "Failed to find and click sport button: \(config.sportName)",
        level: .error,
        configId: config.id,
        configName: config.name,
      )
      self.userError = ReservationError.sportButtonNotFound.errorDescription
      throw ReservationError.sportButtonNotFound
    }
  }

  private func updateTask(_ task: String) async {
    await MainActor.run {
      statusManager.currentTask = task
    }
  }

  /**
   Performs a reservation using a separate WebKit instance.
   - Parameters:
   - config: The reservation configuration to run.
   - runType: The type of run.
   */
  private func runReservationWithSeparateWebKit(
    for config: ReservationConfig, runType: ReservationRunType
  ) async {
    logger.info("🚀 Starting separate WebKit instance for \(config.name).")
    let instanceId = "godmode_\(config.id.uuidString.prefix(8))_\(Date().timeIntervalSince1970)"
    let separateWebKitService = WebKitService(forParallelOperation: true, instanceId: instanceId)
    do {
      await MainActor.run {
        statusManager.setLastRunInfo(
          for: config.id, status: .running, date: Date(), runType: runType)
      }
      separateWebKitService.onWindowClosed = { [weak self] runType in
        Task { await self?.handleManualWindowClosure(runType: runType) }
      }
      try await separateWebKitService.connect()
      separateWebKitService.currentConfig = config
      try await separateWebKitService.navigateToURL(config.facilityURL)
      let domReady = await separateWebKitService.waitForDOMReady()
      if !domReady {
        logger.error("❌ DOM failed to load properly for \(config.name).")
        throw ReservationError.pageLoadTimeout
      }

      // Ensure JavaScript library is available after navigation
      logger.info("🔧 Verifying JavaScript library availability for \(config.name)...")
      let jsAvailable = await separateWebKitService.verifyJavaScriptLibrary()
      if !jsAvailable {
        logger.warning("⚠️ JavaScript library not available for \(config.name), re-injecting...")
        separateWebKitService.reinjectScripts()
        try await Task.sleep(nanoseconds: AppConstants.humanDelayNanoseconds)
      }

      // Add additional wait to ensure page is fully loaded
      logger.info("⏳ Waiting for page to fully stabilize for \(config.name)...")
      try await Task.sleep(nanoseconds: AppConstants.longDelayNanoseconds)
      let buttonClicked = await separateWebKitService.findAndClickElement(
        withText: config.sportName)
      if buttonClicked {
        logger.info("⏳ Waiting for group size page for \(config.name).")
        let groupSizePageReady = await separateWebKitService.waitForGroupSizePage()
        if !groupSizePageReady {
          logger.error("⏰ Group size page failed to load for \(config.name).")
          throw ReservationError.groupSizePageLoadTimeout
        }

        logger.info("👥 Setting number of people for \(config.name): \(config.numberOfPeople).")
        let peopleFilled = await separateWebKitService.fillNumberOfPeople(config.numberOfPeople)
        if !peopleFilled {
          logger.error("❌ Failed to fill number of people field for \(config.name).")
          throw ReservationError.numberOfPeopleFieldNotFound
        }
        logger.info(
          "✅ Successfully filled number of people for \(config.name): \(config.numberOfPeople).")
        logger.info("✅ Confirming group size for \(config.name).")
        let confirmClicked = await separateWebKitService.clickConfirmButton()
        if !confirmClicked {
          logger.error("❌ Failed to click confirm button for \(config.name).")
          throw ReservationError.confirmButtonNotFound
        }
        logger.info("✅ Successfully clicked confirm button for \(config.name).")
        logger.info("⏳ Waiting for time selection page for \(config.name).")
        logger.info(
          "⏭️ Skipping time selection page detection for \(config.name) - page already loaded.")
        logger.info("📅 Selecting time slot for \(config.name).")
        let selectedDay = config.dayTimeSlots.keys.first
        let selectedTimeSlot = selectedDay.flatMap { day in config.dayTimeSlots[day]?.first }
        if let day = selectedDay, let timeSlot = selectedTimeSlot {
          let dayName = day.shortName
          let timeString = timeSlot.formattedTime()
          logger
            .info(
              "Attempting to select for \(config.name): \(dayName) at \(timeString, privacy: .private)"
            )

          logger.info("🔍 [\(config.name)] Starting time slot selection process...")
          logger.info("🔍 [\(config.name)] Day: \(dayName), Time: \(timeString).")

          // Verify JavaScript again before time slot selection
          let jsAvailableBeforeTimeSlot = await separateWebKitService.verifyJavaScriptLibrary()
          logger
            .info(
              "🔍 [\(config.name)] JavaScript available before time slot: \(jsAvailableBeforeTimeSlot)"
            )

          let timeSlotSelected = await separateWebKitService.selectTimeSlot(
            dayName: dayName,
            timeString: timeString,
          )
          if !timeSlotSelected {
            logger
              .error(
                "Failed to select time slot for \(config.name): \(dayName) at \(timeString, privacy: .private)",
              )
            throw ReservationError.timeSlotSelectionFailed
          }
          logger
            .info(
              "Successfully selected time slot for \(config.name): \(dayName) at \(timeString, privacy: .private)",
            )
        } else {
          logger.warning("⚠️ No time slots configured for \(config.name), skipping time selection.")
        }
        logger.info("📧 Waiting for contact information page for \(config.name).")
        let contactInfoPageReady =
          await withTimeout(seconds: AppConstants.shortTimeout) {
            await separateWebKitService.waitForContactInfoPage()
          } ?? false
        if !contactInfoPageReady {
          logger.error("⏰ Contact information page failed to load for \(config.name).")
          throw ReservationError.contactInfoPageLoadTimeout
        }

        logger.info("📝 Proceeding with browser autofill-style form filling for \(config.name).")
        logger.info("📝 Filling contact information with simultaneous autofill for \(config.name).")
        let userSettings = UserSettingsManager.shared.userSettings
        let phoneNumber = formatPhoneNumber(userSettings.phoneNumber)
        let allFieldsFilled =
          await separateWebKitService.fillAllContactFieldsWithAutofillAndHumanMovements(
            phoneNumber: phoneNumber,
            email: userSettings.imapEmail,
            name: userSettings.name,
          )
        if !allFieldsFilled {
          logger.error("❌ Failed to fill all contact fields for \(config.name).")
          throw ReservationError.contactInfoFieldNotFound
        }
        logger.info("✅ Successfully filled all contact fields for \(config.name).")
        logger.info("✅ Confirming contact information for \(config.name).")
        let verificationStart = Date()
        var contactConfirmClicked = false
        var retryCount = 0
        let maxRetries = AppConstants.maxRetryAttemptsContactInfo
        while !contactConfirmClicked, retryCount < maxRetries {
          if retryCount > 0 {
            logger.info(
              "🔄 Retry attempt \(retryCount) for confirm button click for \(config.name).")
            logger
              .info(
                "Applying essential anti-detection for retry attempt \(retryCount) for \(config.name)",
              )
            await separateWebKitService.addQuickPause()
            try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...1_800_000_000))
          }
          contactConfirmClicked =
            await separateWebKitService.clickContactInfoConfirmButtonWithRetry()
          if contactConfirmClicked {
            try? await Task.sleep(nanoseconds: AppConstants.shortDelayNanoseconds)
            let retryTextDetected = await separateWebKitService.detectRetryText()
            if retryTextDetected {
              logger
                .warning(
                  "Retry text detected after confirm button click for \(config.name) - will retry with enhanced measures",
                )
              contactConfirmClicked = false
              retryCount += 1
              logger
                .info(
                  "Applying additional essential measures after retry text detection for \(config.name)",
                )
              await separateWebKitService.addQuickPause()
              try? await Task.sleep(nanoseconds: UInt64.random(in: 1_500_000_000...2_200_000_000))
            } else {
              logger
                .info(
                  "Successfully clicked contact confirm button for \(config.name) (no retry text detected)",
                )
              break
            }
          } else {
            retryCount += 1
          }
        }
        if !contactConfirmClicked {
          logger
            .error(
              "Failed to click contact confirm button after \(maxRetries) attempts for \(config.name)"
            )
          throw ReservationError.contactInfoConfirmButtonNotFound
        }
        logger.info("✅ Successfully clicked contact confirm button for \(config.name).")
        logger.info("📧 Checking for email verification for \(config.name).")
        try? await Task.sleep(nanoseconds: AppConstants.longDelayNanoseconds)
        let verificationRequired = await separateWebKitService.isEmailVerificationRequired()
        if verificationRequired {
          logger.info(
            "📧 Email verification required for \(config.name), starting verification process.")
          let verificationSuccess =
            await separateWebKitService
            .handleEmailVerification(verificationStart: verificationStart)
          if !verificationSuccess {
            logger.error(
              "❌ Email verification failed for \(config.name). Setting status to failed.")
            await MainActor.run {
              statusManager.setLastRunInfo(
                for: config.id,
                status: .failed("Email verification failed."),
                date: Date(),
                runType: runType,
              )
              if runType == .manual {
                statusManager.isRunning = false
              }
            }
            let shouldClose = UserSettingsManager.shared.userSettings.autoCloseDebugWindowOnFailure
            if shouldClose {
              logger.info("🪟 Auto-close on failure enabled - closing window.")
              await separateWebKitService.disconnect(closeWindow: true)
            } else {
              logger.info("🪟 Auto-close on failure disabled - keeping window open to show error.")
              await separateWebKitService.disconnect(closeWindow: false)
            }
            return
          }
          logger.info("✅ Email verification completed successfully for \(config.name).")
          logger.info("⏳ Waiting for confirmation page to load for \(config.name).")
          try? await Task.sleep(nanoseconds: AppConstants.humanDelayNanoseconds)
          let domReady = await separateWebKitService.waitForDOMReady()
          if domReady {
          } else {
            logger
              .warning(
                "⚠️ DOM ready check failed for \(config.name), but continuing with click result as success indicator",
              )
          }
        }
        logger.info("🎉 Finishing reservation for \(config.name).")
        logger.info(
          "🎉 Reservation completed successfully for \(config.name) - all steps completed.")
        await MainActor.run {
          statusManager.setLastRunInfo(
            for: config.id, status: .success, date: Date(), runType: runType)
          if runType == .manual {
            statusManager.isRunning = false
          }
        }
        logger.info("🎉 Reservation completed successfully for \(config.name).")
        separateWebKitService.onWindowClosed = nil
      } else {
        logger.error("❌ Failed to click sport button for \(config.name).")
        throw ReservationError.sportButtonNotFound
      }
    } catch {
      logger.error("❌ Reservation failed for \(config.name): \(error.localizedDescription).")

      // Take screenshot before disconnecting if WebKit service is available
      var screenshotPath: String? = nil
      if separateWebKitService.isConnected, separateWebKitService.webView != nil {
        logger.info("📸 Taking failure screenshot for \(config.name)...")

        // Set screenshot directory on the WebKit service
        await MainActor.run {
          separateWebKitService.setScreenshotDirectory(FileManager.odysseyScreenshotsDirectory())
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = dateFormatter.string(from: Date())
        let filename =
          "\(config.name.replacingOccurrences(of: " ", with: "_"))_\(timestamp).jpg"
        screenshotPath = await separateWebKitService.takeScreenshot(
          filename: filename, quality: AppConstants.defaultScreenshotQuality,
          maxWidth: AppConstants.defaultScreenshotMaxWidth,
          format: AppConstants.defaultScreenshotFormat)
        if let path = screenshotPath {
          logger.info("📸 Failure screenshot saved: \(path).")
        } else {
          logger.error("❌ Failed to capture failure screenshot for \(config.name).")
        }
      } else {
        logger.warning("⚠️ WebKit service not available for screenshot capture.")
      }

      await MainActor.run {
        statusManager.setLastRunInfo(
          for: config.id,
          status: .failed(error.localizedDescription),
          date: Date(),
          runType: runType,
          screenshotPath: screenshotPath
        )
        if runType == .manual {
          statusManager.isRunning = false
        }
      }
      let shouldClose = UserSettingsManager.shared.userSettings.autoCloseDebugWindowOnFailure
      if shouldClose {
        logger.info("🪟 Auto-close on failure enabled - closing window.")
        await separateWebKitService.disconnect(closeWindow: true)
      } else {
        logger.info("🪟 Auto-close on failure disabled - keeping window open to show error.")
        await separateWebKitService.disconnect(closeWindow: false)
      }
      return
    }
    // Always close window on successful reservation (regardless of settings)
    logger.info("🎉 Reservation completed successfully - closing window.")
    await separateWebKitService.disconnect(closeWindow: true)
  }

  private func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
  ) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask { try await operation() }
      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        throw ReservationError.webKitTimeout
      }
      guard let result = try await group.next() else {
        throw ReservationError.webKitTimeout
      }
      group.cancelAll()
      return result
    }
  }

  private func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async -> T
  ) async -> T? {
    await withTaskGroup(of: T?.self) { group in
      group.addTask {
        await operation()
      }

      group.addTask {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        return nil
      }

      for await result in group {
        group.cancelAll()
        return result
      }

      return nil
    }
  }

  /**
   Tracks completion of godmode or multi-reservation runs, updating state and allowing sleep if needed.
   - Parameters:
   - configs: The reservation configurations that were run.
   - runType: The type of run.
   */
  private func trackGodModeCompletion(configs: [ReservationConfig], runType: ReservationRunType)
    async
  {
    logger.info("📊 Starting God Mode completion tracking for \(configs.count) configurations.")
    let maxWaitTime: TimeInterval = AppConstants.verificationCodeTimeout
    let checkInterval: TimeInterval = AppConstants.retryDelay
    let startTime = Date()
    while Date().timeIntervalSince(startTime) < maxWaitTime {
      let completedConfigs = configs.filter { config in
        if let lastRunInfo = self.statusManager.lastRunInfo[config.id] {
          switch lastRunInfo.status {
          case .success, .failed, .stopped: return true
          case .idle, .running: return false
          }
        }
        return false
      }
      logger.info(
        "📈 God Mode progress: \(completedConfigs.count)/\(configs.count) configurations completed.")
      if completedConfigs.count == configs.count {
        let successfulConfigs = configs.filter { config in
          if let lastRunInfo = self.statusManager.lastRunInfo[config.id] {
            return lastRunInfo.status == .success
          }
          return false
        }
        let failedConfigs = configs.filter { config in
          if let lastRunInfo = self.statusManager.lastRunInfo[config.id] {
            if case .failed = lastRunInfo.status { return true }
          }
          return false
        }
        await MainActor.run {
          logger.info("🔄 ReservationOrchestrator: Updating God Mode completion status.")
          if failedConfigs.isEmpty {
            self.statusManager.lastRunStatus = .success
            self.statusManager
              .currentTask = "God Mode: All \(configs.count) configurations completed successfully"
            logger.info("🎉 God Mode completed - All successful.")
          } else if successfulConfigs.isEmpty {
            self.statusManager.lastRunStatus = .failed("All \(configs.count) configurations failed")
            self.statusManager.currentTask = "God Mode: All configurations failed"
            logger.info("❌ God Mode completed - All failed.")
          } else {
            self.statusManager.lastRunStatus = .success
            self.statusManager
              .currentTask =
              "God Mode: \(successfulConfigs.count) successful, \(failedConfigs.count) failed"
            logger
              .info(
                "🔄 ReservationOrchestrator: God Mode completed - Mixed results: \(successfulConfigs.count) success, \(failedConfigs.count) failed",
              )
          }
          self.statusManager.lastRunDate = Date()
          logger.info(
            "🔄 ReservationOrchestrator: Keeping icon filled until all statuses are finalized.")
          Task {
            // Wait for all configurations to have final status (not running)
            var allFinalized = false
            var waitTime: TimeInterval = 0
            let maxWaitTime: TimeInterval = AppConstants.maxWaitTimeForGodModeSeconds
            let checkInterval: TimeInterval = AppConstants.checkIntervalShort

            while !allFinalized, waitTime < maxWaitTime {
              try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
              waitTime += checkInterval

              // Check if all configurations have final status
              allFinalized = configs.allSatisfy { config in
                if let lastRunInfo = self.statusManager.lastRunInfo[config.id] {
                  switch lastRunInfo.status {
                  case .success, .failed, .stopped: return true
                  case .idle, .running: return false
                  }
                }
                return false
              }

              if !allFinalized {
                logger.info("🔄 Waiting for all statuses to finalize... (\(waitTime)s).")
              }
            }

            // Additional wait time to ensure UI updates are visible
            try? await Task
              .sleep(
                nanoseconds: UInt64(
                  AppConstants
                    .additionalWaitTimeForUIUpdatesSeconds * 1_000_000_000,
                ))

            await MainActor.run {
              self.statusManager.isRunning = false
              logger.info(
                "🔄 ReservationOrchestrator: Final multiple reservation status - isRunning: \(self.statusManager.isRunning), status: \(self.statusManager.lastRunStatus.description)",
              )
            }
          }
        }
        logger
          .info(
            "📊 God Mode completed: \(successfulConfigs.count) successful, \(failedConfigs.count) failed."
          )
        WebKitService.printLiveInstanceCount()
        return
      }
      try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
    }
    logger.warning("⏰ God Mode completion tracking timed out after \(maxWaitTime) seconds.")
    await MainActor.run {
      logger.info("🔄 ReservationOrchestrator: God Mode timeout - updating status.")
      self.statusManager.lastRunStatus = .failed("God Mode timed out")
      self.statusManager.currentTask = "God Mode: Operation timed out"
      self.statusManager.lastRunDate = Date()
      self.statusManager.isRunning = false
      logger
        .info(
          "🔄 ReservationOrchestrator: God Mode timeout status - isRunning: \(self.statusManager.isRunning), status: \(self.statusManager.lastRunStatus.description)",
        )
    }
  }
}
