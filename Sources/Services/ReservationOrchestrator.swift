import Combine
import Foundation
import os.log

/**
 ReservationError defines all possible errors that can occur during the reservation automation process.

 This enum is used throughout the automation flow to provide detailed, user-friendly error messages and to support structured error handling and logging.
 */
public enum ReservationError: Error, Codable, LocalizedError, UnifiedErrorProtocol {
    /// Network error with a message.
    case network(String)
    /// Facility not found with a message.
    case facilityNotFound(String)
    /// Slot unavailable with a message.
    case slotUnavailable(String)
    /// Automation failed with a message
    case automationFailed(String)
    /// Unknown error with a message
    case unknown(String)
    /// Page failed to load in time
    case pageLoadTimeout
    /// Group size page failed to load in time
    case groupSizePageLoadTimeout
    /// Number of people field not found
    case numberOfPeopleFieldNotFound
    /// Confirm button not found
    case confirmButtonNotFound
    /// Failed to select time slot
    case timeSlotSelectionFailed
    /// Contact info page failed to load in time
    case contactInfoPageLoadTimeout
    /// Contact info field not found
    case contactInfoFieldNotFound
    /// Contact info confirm button not found
    case contactInfoConfirmButtonNotFound
    /// Email verification failed
    case emailVerificationFailed
    /// Sport button not found
    case sportButtonNotFound
    /// WebKit operation timed out
    case webKitTimeout

    /// Human-readable error description for each case
    public var errorDescription: String? {
        return userFriendlyMessage
    }

    /// Unique error code for categorization and debugging
    public var errorCode: String {
        switch self {
        case .network: return "RESERVATION_NETWORK_001"
        case .facilityNotFound: return "RESERVATION_FACILITY_001"
        case .slotUnavailable: return "RESERVATION_SLOT_001"
        case .automationFailed: return "RESERVATION_AUTOMATION_001"
        case .unknown: return "RESERVATION_UNKNOWN_001"
        case .pageLoadTimeout: return "RESERVATION_TIMEOUT_001"
        case .groupSizePageLoadTimeout: return "RESERVATION_TIMEOUT_002"
        case .numberOfPeopleFieldNotFound: return "RESERVATION_ELEMENT_001"
        case .confirmButtonNotFound: return "RESERVATION_ELEMENT_002"
        case .timeSlotSelectionFailed: return "RESERVATION_SELECTION_001"
        case .contactInfoPageLoadTimeout: return "RESERVATION_TIMEOUT_003"
        case .contactInfoFieldNotFound: return "RESERVATION_ELEMENT_003"
        case .contactInfoConfirmButtonNotFound: return "RESERVATION_ELEMENT_004"
        case .emailVerificationFailed: return "RESERVATION_EMAIL_001"
        case .sportButtonNotFound: return "RESERVATION_ELEMENT_005"
        case .webKitTimeout: return "RESERVATION_TIMEOUT_004"
        }
    }

    /// Category for grouping similar errors
    public var errorCategory: ErrorCategory {
        switch self {
        case .network: return .network
        case .facilityNotFound, .slotUnavailable: return .validation
        case .automationFailed, .sportButtonNotFound, .confirmButtonNotFound, .numberOfPeopleFieldNotFound,
             .contactInfoFieldNotFound, .contactInfoConfirmButtonNotFound: return .automation
        case .pageLoadTimeout, .groupSizePageLoadTimeout, .contactInfoPageLoadTimeout, .webKitTimeout: return .system
        case .emailVerificationFailed: return .authentication
        case .timeSlotSelectionFailed: return .automation
        case .unknown: return .unknown
        }
    }

    /// User-friendly error message for UI display
    public var userFriendlyMessage: String {
        switch self {
        case let .network(msg): return "Network error: \(msg)"
        case let .facilityNotFound(msg): return "Facility not found: \(msg)"
        case let .slotUnavailable(msg): return "Slot unavailable: \(msg)"
        case let .automationFailed(msg): return "Automation failed: \(msg)"
        case let .unknown(msg): return "Unknown error: \(msg)"
        case .pageLoadTimeout: return "Page failed to load in time."
        case .groupSizePageLoadTimeout: return "Group size page failed to load in time."
        case .numberOfPeopleFieldNotFound: return "Number of people field not found."
        case .confirmButtonNotFound: return "Confirm button not found."
        case .timeSlotSelectionFailed: return "Failed to select time slot."
        case .contactInfoPageLoadTimeout: return "Contact info page failed to load in time."
        case .contactInfoFieldNotFound: return "Contact info field not found."
        case .contactInfoConfirmButtonNotFound: return "Contact info confirm button not found."
        case .emailVerificationFailed: return "Email verification failed."
        case .sportButtonNotFound: return "Sport button not found."
        case .webKitTimeout: return "WebKit operation timed out."
        }
    }

    /// Technical details for debugging (optional)
    public var technicalDetails: String? {
        switch self {
        case let .network(msg): return "Network request failed: \(msg)"
        case let .facilityNotFound(msg): return "Facility URL validation failed: \(msg)"
        case let .slotUnavailable(msg): return "Time slot selection failed: \(msg)"
        case let .automationFailed(msg): return "Web automation sequence failed: \(msg)"
        case let .unknown(msg): return "Unexpected error occurred: \(msg)"
        case .pageLoadTimeout: return "Page load exceeded timeout threshold"
        case .groupSizePageLoadTimeout: return "Group size page load exceeded timeout threshold"
        case .numberOfPeopleFieldNotFound: return "DOM element for number of people not found"
        case .confirmButtonNotFound: return "DOM element for confirm button not found"
        case .timeSlotSelectionFailed: return "Time slot selection automation failed"
        case .contactInfoPageLoadTimeout: return "Contact info page load exceeded timeout threshold"
        case .contactInfoFieldNotFound: return "DOM element for contact info not found"
        case .contactInfoConfirmButtonNotFound: return "DOM element for contact info confirm button not found"
        case .emailVerificationFailed: return "Email verification process failed"
        case .sportButtonNotFound: return "DOM element for sport selection not found"
        case .webKitTimeout: return "WebKit operation exceeded timeout threshold"
        }
    }
}

// MARK: - ReservationRunStatusCodable (Top-level)

// Codable wrapper for run status, used for persistence and status tracking
public struct ReservationRunStatusCodable: Codable, Equatable {
    public let status: ReservationRunStatus
    public let date: Date?
    public let runType: ReservationRunType
}

// MARK: - Reservation Run Types and Status (Top-level)

// Run type for automation (manual, automatic, godmode)
public enum ReservationRunType: String, Codable, Equatable, Sendable {
    case manual
    case automatic
    case godmode
    public var description: String {
        switch self {
        case .manual: return "(manual)"
        case .automatic: return "(auto)"
        case .godmode: return "(god mode)"
        }
    }
}

// Status of a reservation automation run, with Codable for persistence
public enum ReservationRunStatus: Codable, Equatable, Sendable {
    case idle
    case running
    case success
    case failed(String)

    public var description: String {
        switch self {
        case .idle: return "Idle"
        case .running: return "Running"
        case .success: return "Successful"
        case let .failed(error): return "Failed: \(error)"
        }
    }

    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case idle, running, success, failed
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.idle) { self = .idle } else if container.contains(.running) { self = .running }
        else if container.contains(.success) { self = .success } else if container.contains(.failed) {
            let error = try container.decode(String.self, forKey: .failed)
            self = .failed(error)
        } else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown ReservationRunStatus",
            ))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .idle: try container.encode(true, forKey: .idle)
        case .running: try container.encode(true, forKey: .running)
        case .success: try container.encode(true, forKey: .success)
        case let .failed(error): try container.encode(error, forKey: .failed)
        }
    }

    public static func == (lhs: ReservationRunStatus, rhs: ReservationRunStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.running, .running): return true
        case (.success, .success): return true
        case let (.failed(lhsError), .failed(rhsError)): return lhsError == rhsError
        default: return false
        }
    }
}

@MainActor
public final class ReservationOrchestrator: ObservableObject, @unchecked Sendable {
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
            subsystem: "com.odyssey.app",
            category: LoggerCategory.reservationOrchestrator.categoryName,
        ),
        webKitService: WebKitServiceProtocol = ServiceRegistry.shared.resolve(WebKitServiceProtocol.self),
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
            logger: Logger(subsystem: "com.odyssey.app", category: LoggerCategory.reservationOrchestrator.categoryName),
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
                try await withTimeout(seconds: 300) {
                    try await self.performReservation(for: config, runType: runType)
                }
            } catch {
                // Set user-facing error
                await MainActor.run { self.userError = error.localizedDescription }
                logger.error("⏰ Reservation timeout reached (5 minutes).")
                await errorHandler.handleReservationError(error, config: config, runType: runType)
            }
        }
    }

    /**
     Runs multiple reservations in parallel for the given configurations and run type.
     - Parameters:
     - configs: The reservation configurations to run.
     - runType: The type of run (manual, automatic, godmode).
     */
    public func runMultipleReservations(for configs: [ReservationConfig], runType: ReservationRunType = .manual) {
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
            logger.warning("🚨 Emergency cleanup triggered - capturing screenshot and sending notification.")
            logger.error("🚨 Emergency cleanup triggered for \(config.name): automation was interrupted unexpectedly.")
            await MainActor.run {
                // Always set isRunning = false for emergency cleanup
                statusManager.isRunning = false
                statusManager.lastRunStatus = .failed("Emergency cleanup - automation was interrupted unexpectedly")
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
            logger.warning("🚨 Emergency cleanup triggered - capturing screenshot and sending notification.")
            logger.error("🚨 Emergency cleanup triggered for \(config.name): automation was interrupted unexpectedly.")
            await MainActor.run {
                // Always set isRunning = false for emergency cleanup
                statusManager.isRunning = false
                statusManager.lastRunStatus = .failed("Emergency cleanup - automation was interrupted unexpectedly")
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
            // Only set isRunning = false for single reservations (manual runs)
            // For multiple reservations (godmode/automatic), let trackGodModeCompletion handle it
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

    /**
     Performs the reservation logic for a given configuration and run type.
     - Parameters:
     - config: The reservation configuration to run.
     - runType: The type of run.
     */
    private func performReservation(for config: ReservationConfig, runType: ReservationRunType) async throws {
        statusManager.currentTask = "Starting reservation for \(config.name)"
        currentConfig = config
        await updateTask("Checking WebKit service state")
        if !webKitService.isServiceValid() {
            logger.info("🔄 WebKit service not in valid state, resetting.")
            await webKitService.reset()
        }
        webKitService.onWindowClosed = { [weak self] runType in
            Task { await self?.handleManualWindowClosure(runType: runType) }
        }
        await updateTask("Starting WebKit session")
        try await webKitService.connect()
        webKitService.currentConfig = config
        await updateTask("Navigating to facility")
        try await webKitService.navigateToURL(config.facilityURL)
        await updateTask("Checking for cookie consent...")
        await updateTask("Waiting for page to load")
        let domReady = await webKitService.waitForDOMReady()
        if !domReady {
            logger.error("⏰ DOM failed to load properly within timeout.")
            self.userError = ReservationError.pageLoadTimeout.errorDescription
            throw ReservationError.pageLoadTimeout
        }
        logger.info("✅ Page loaded successfully.")
        await updateTask("Looking for sport: \(config.sportName)")
        logger.info("🔍 Searching for sport button with text: '\(config.sportName, privacy: .private)'.")
        let buttonClicked = await webKitService.findAndClickElement(withText: config.sportName)
        if buttonClicked {
            logger.info("✅ Successfully clicked sport button: \(config.sportName, privacy: .private).")
            await updateTask("Waiting for group size page...")
            let groupSizePageReady = await webKitService.waitForGroupSizePage()
            if !groupSizePageReady {
                logger.error("⏰ Group size page failed to load within timeout.")
                self.userError = ReservationError.groupSizePageLoadTimeout.errorDescription
                throw ReservationError.groupSizePageLoadTimeout
            }
            logger.info("✅ Group size page loaded successfully.")
            await updateTask("Setting number of people: \(config.numberOfPeople)")
            let peopleFilled = await webKitService.fillNumberOfPeople(config.numberOfPeople)
            if !peopleFilled {
                logger.error("❌ Failed to fill number of people field.")
                self.userError = ReservationError.numberOfPeopleFieldNotFound.errorDescription
                throw ReservationError.numberOfPeopleFieldNotFound
            }
            logger.info("✅ Successfully filled number of people: \(config.numberOfPeople).")
            await updateTask("Confirming group size...")
            let confirmClicked = await webKitService.clickConfirmButton()
            if !confirmClicked {
                logger.error("❌ Failed to click confirm button.")
                self.userError = ReservationError.confirmButtonNotFound.errorDescription
                throw ReservationError.confirmButtonNotFound
            }
            logger.info("✅ Successfully clicked confirm button.")
            await updateTask("Waiting for time selection page...")
            logger.info("⏭️ Skipping time selection page detection - page already loaded.")
            await updateTask("Selecting time slot...")
            let selectedDay = config.dayTimeSlots.keys.first
            let selectedTimeSlot = selectedDay.flatMap { day in config.dayTimeSlots[day]?.first }
            if let day = selectedDay, let timeSlot = selectedTimeSlot {
                let dayName = day.shortName
                let timeString = timeSlot.formattedTime()
                logger.info("📅 Attempting to select: \(dayName) at \(timeString, privacy: .private).")
                let timeSlotSelected = await webKitService.selectTimeSlot(dayName: dayName, timeString: timeString)
                if !timeSlotSelected {
                    logger.error("❌ Failed to select time slot: \(dayName) at \(timeString, privacy: .private).")
                    throw ReservationError.timeSlotSelectionFailed
                }
                logger.info("✅ Successfully selected time slot: \(dayName) at \(timeString, privacy: .private).")
            } else {
                logger.warning("⚠️ No time slots configured, skipping time selection.")
            }
            await updateTask("Waiting for contact information page...")
            let contactInfoPageReady = await withTimeout(seconds: 10, operation: { @MainActor in
                await self.webKitService.waitForContactInfoPage()
            }) ?? false
            if !contactInfoPageReady {
                logger.error("⏰ Contact information page failed to load within timeout.")
                self.userError = ReservationError.contactInfoPageLoadTimeout.errorDescription
                throw ReservationError.contactInfoPageLoadTimeout
            }
            logger.info("✅ Contact information page loaded successfully.")
            logger.info("📝 Proceeding with browser autofill-style form filling to avoid triggering captchas.")
            await updateTask("Filling contact information with simultaneous autofill...")
            let userSettings = UserSettingsManager.shared.userSettings
            let phoneNumber = userSettings.phoneNumber.replacingOccurrences(of: "-", with: "")
            let allFieldsFilled = await webKitService.fillAllContactFieldsWithAutofillAndHumanMovements(
                phoneNumber: phoneNumber,
                email: userSettings.imapEmail,
                name: userSettings.name,
            )
            if !allFieldsFilled {
                logger.error("❌ Failed to fill all contact fields simultaneously.")
                self.userError = ReservationError.contactInfoFieldNotFound.errorDescription
                throw ReservationError.contactInfoFieldNotFound
            }
            logger.info("✅ Successfully filled all contact fields simultaneously with autofill and human movements.")
            await updateTask("Confirming contact information...")
            let verificationStart = Date()
            var contactConfirmClicked = false
            var retryCount = 0
            let maxRetries = 6
            while !contactConfirmClicked, retryCount < maxRetries {
                if retryCount > 0 {
                    logger.info("🔄 Retry attempt \(retryCount) for confirm button click.")
                    await updateTask("Retrying confirmation... (Attempt \(retryCount + 1)/\(maxRetries))")
                    logger.info("🛡️ Applying essential anti-detection for retry attempt \(retryCount).")
                    await updateTask("Applying anti-detection measures...")
                    await webKitService.addQuickPause()
                    try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000 ... 1_800_000_000))
                }
                contactConfirmClicked = await webKitService.clickContactInfoConfirmButtonWithRetry()
                if contactConfirmClicked {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    let retryTextDetected = await webKitService.detectRetryText()
                    if retryTextDetected {
                        logger
                            .warning(
                                "Retry text detected after confirm button click - will retry with enhanced measures",
                            )
                        contactConfirmClicked = false
                        retryCount += 1
                        logger.info("🛡️ Applying additional essential measures after retry text detection.")
                        await updateTask("Applying additional anti-detection measures...")
                        await webKitService.addQuickPause()
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_500_000_000 ... 2_200_000_000))
                    } else {
                        logger.info("✅ Successfully clicked contact confirm button (no retry text detected).")
                        break
                    }
                } else {
                    retryCount += 1
                }
            }
            if !contactConfirmClicked {
                logger.error("❌ Failed to click contact confirm button after \(maxRetries) attempts.")
                self.userError = ReservationError.contactInfoConfirmButtonNotFound.errorDescription
                throw ReservationError.contactInfoConfirmButtonNotFound
            }
            logger.info("✅ Successfully clicked contact confirm button.")
            await updateTask("Checking for email verification...")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            let verificationRequired = await webKitService.isEmailVerificationRequired()
            if verificationRequired {
                logger.info("📧 Email verification required, starting verification process.")
                let verificationSuccess = await webKitService
                    .handleEmailVerification(verificationStart: verificationStart)
                if !verificationSuccess {
                    logger.error("❌ Email verification failed.")
                    self.userError = ReservationError.emailVerificationFailed.errorDescription
                    throw ReservationError.emailVerificationFailed
                }
                logger.info("✅ Email verification completed successfully.")
                await updateTask("Waiting for confirmation page to load...")
                logger.info("⏳ Waiting for page navigation to complete after email verification.")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let domReady = await webKitService.waitForDOMReady()
                if domReady {
                    logger.info("✅ Confirmation page loaded successfully.")
                } else {
                    logger.warning("⚠️ DOM ready check failed, but continuing with click result as success indicator.")
                }
            }
            await updateTask("Finishing reservation...")
            logger.info("🎉 Reservation completed successfully - all steps completed.")
            await MainActor.run {
                // Only set isRunning = false for single reservations (manual runs)
                // For multiple reservations (godmode/automatic), let trackGodModeCompletion handle it
                if runType == .manual {
                    statusManager.isRunning = false
                }
                statusManager.lastRunStatus = .success
                statusManager.setLastRunInfo(for: config.id, status: .success, date: Date(), runType: runType)
                statusManager.lastRunDate = Date()
                statusManager.currentTask = "Reservation completed successfully"
            }
            logger.info("🎉 Reservation completed successfully for \(config.name).")
            logger.info("🧹 Cleaning up WebKit session after successful reservation.")
            webKitService.onWindowClosed = nil
            await webKitService.disconnect(closeWindow: true)
            return
        } else {
            logger.error("❌ Failed to click sport button: \(config.sportName, privacy: .private).")
            self.userError = ReservationError.sportButtonNotFound.errorDescription
            await webKitService.disconnect(closeWindow: true)
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
    private func runReservationWithSeparateWebKit(for config: ReservationConfig, runType: ReservationRunType) async {
        logger.info("🚀 Starting separate WebKit instance for \(config.name).")
        let instanceId = "godmode_\(config.id.uuidString.prefix(8))_\(Date().timeIntervalSince1970)"
        let separateWebKitService = WebKitService(forParallelOperation: true, instanceId: instanceId)
        do {
            await MainActor.run {
                statusManager.setLastRunInfo(for: config.id, status: .running, date: Date(), runType: runType)
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
            let buttonClicked = await separateWebKitService.findAndClickElement(withText: config.sportName)
            if buttonClicked {
                logger.info("✅ Successfully clicked sport button for \(config.name).")
                logger.info("⏳ Waiting for group size page for \(config.name).")
                let groupSizePageReady = await separateWebKitService.waitForGroupSizePage()
                if !groupSizePageReady {
                    logger.error("⏰ Group size page failed to load for \(config.name).")
                    throw ReservationError.groupSizePageLoadTimeout
                }
                logger.info("✅ Group size page loaded successfully for \(config.name).")
                logger.info("👥 Setting number of people for \(config.name): \(config.numberOfPeople).")
                let peopleFilled = await separateWebKitService.fillNumberOfPeople(config.numberOfPeople)
                if !peopleFilled {
                    logger.error("❌ Failed to fill number of people field for \(config.name).")
                    throw ReservationError.numberOfPeopleFieldNotFound
                }
                logger.info("✅ Successfully filled number of people for \(config.name): \(config.numberOfPeople).")
                logger.info("✅ Confirming group size for \(config.name).")
                let confirmClicked = await separateWebKitService.clickConfirmButton()
                if !confirmClicked {
                    logger.error("❌ Failed to click confirm button for \(config.name).")
                    throw ReservationError.confirmButtonNotFound
                }
                logger.info("✅ Successfully clicked confirm button for \(config.name).")
                logger.info("⏳ Waiting for time selection page for \(config.name).")
                logger.info("⏭️ Skipping time selection page detection for \(config.name) - page already loaded.")
                logger.info("📅 Selecting time slot for \(config.name).")
                let selectedDay = config.dayTimeSlots.keys.first
                let selectedTimeSlot = selectedDay.flatMap { day in config.dayTimeSlots[day]?.first }
                if let day = selectedDay, let timeSlot = selectedTimeSlot {
                    let dayName = day.shortName
                    let timeString = timeSlot.formattedTime()
                    logger
                        .info("Attempting to select for \(config.name): \(dayName) at \(timeString, privacy: .private)")
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
                let contactInfoPageReady = await withTimeout(seconds: 10) {
                    await separateWebKitService.waitForContactInfoPage()
                } ?? false
                if !contactInfoPageReady {
                    logger.error("⏰ Contact information page failed to load for \(config.name).")
                    throw ReservationError.contactInfoPageLoadTimeout
                }
                logger.info("✅ Contact information page loaded successfully for \(config.name).")
                logger.info("📝 Proceeding with browser autofill-style form filling for \(config.name).")
                logger.info("📝 Filling contact information with simultaneous autofill for \(config.name).")
                let userSettings = UserSettingsManager.shared.userSettings
                let phoneNumber = userSettings.phoneNumber.replacingOccurrences(of: "-", with: "")
                let allFieldsFilled = await separateWebKitService.fillAllContactFieldsWithAutofillAndHumanMovements(
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
                let maxRetries = 6
                while !contactConfirmClicked, retryCount < maxRetries {
                    if retryCount > 0 {
                        logger.info("🔄 Retry attempt \(retryCount) for confirm button click for \(config.name).")
                        logger
                            .info(
                                "Applying essential anti-detection for retry attempt \(retryCount) for \(config.name)",
                            )
                        await separateWebKitService.addQuickPause()
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000 ... 1_800_000_000))
                    }
                    contactConfirmClicked = await separateWebKitService.clickContactInfoConfirmButtonWithRetry()
                    if contactConfirmClicked {
                        try? await Task.sleep(nanoseconds: 300_000_000)
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
                            try? await Task.sleep(nanoseconds: UInt64.random(in: 1_500_000_000 ... 2_200_000_000))
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
                        .error("Failed to click contact confirm button after \(maxRetries) attempts for \(config.name)")
                    throw ReservationError.contactInfoConfirmButtonNotFound
                }
                logger.info("✅ Successfully clicked contact confirm button for \(config.name).")
                logger.info("📧 Checking for email verification for \(config.name).")
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                let verificationRequired = await separateWebKitService.isEmailVerificationRequired()
                if verificationRequired {
                    logger.info("📧 Email verification required for \(config.name), starting verification process.")
                    let verificationSuccess = await separateWebKitService
                        .handleEmailVerification(verificationStart: verificationStart)
                    if !verificationSuccess {
                        logger.error("❌ Email verification failed for \(config.name). Setting status to failed.")
                        await MainActor.run {
                            statusManager.setLastRunInfo(
                                for: config.id,
                                status: .failed("Email verification failed."),
                                date: Date(),
                                runType: runType,
                            )
                            // Only set isRunning = false for single reservations (manual runs)
                            // For multiple reservations (godmode/automatic), let trackGodModeCompletion handle it
                            if runType == .manual {
                                statusManager.isRunning = false
                            }
                        }
                        let shouldClose = UserSettingsManager.shared.userSettings.autoCloseDebugWindowOnFailure
                        await separateWebKitService.disconnect(closeWindow: shouldClose)
                        return
                    }
                    logger.info("✅ Email verification completed successfully for \(config.name).")
                    logger.info("⏳ Waiting for confirmation page to load for \(config.name).")
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    let domReady = await separateWebKitService.waitForDOMReady()
                    if domReady {
                        logger.info("✅ Confirmation page loaded successfully for \(config.name).")
                    } else {
                        logger
                            .warning(
                                "⚠️ DOM ready check failed for \(config.name), but continuing with click result as success indicator",
                            )
                    }
                }
                logger.info("🎉 Finishing reservation for \(config.name).")
                logger.info("🎉 Reservation completed successfully for \(config.name) - all steps completed.")
                await MainActor.run {
                    statusManager.setLastRunInfo(for: config.id, status: .success, date: Date(), runType: runType)
                    // Only set isRunning = false for single reservations (manual runs)
                    // For multiple reservations (godmode/automatic), let trackGodModeCompletion handle it
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
            await MainActor.run {
                statusManager.setLastRunInfo(
                    for: config.id,
                    status: .failed(error.localizedDescription),
                    date: Date(),
                    runType: runType,
                )
                // Only set isRunning = false for single reservations (manual runs)
                // For multiple reservations (godmode/automatic), let trackGodModeCompletion handle it
                if runType == .manual {
                    statusManager.isRunning = false
                }
            }
            let shouldClose = UserSettingsManager.shared.userSettings.autoCloseDebugWindowOnFailure
            await separateWebKitService.disconnect(closeWindow: shouldClose)
            return
        }
        // Close window on success if showBrowserWindow is enabled
        let shouldCloseOnSuccess = UserSettingsManager.shared.userSettings.showBrowserWindow
        await separateWebKitService.disconnect(closeWindow: shouldCloseOnSuccess)
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
    private func trackGodModeCompletion(configs: [ReservationConfig], runType: ReservationRunType) async {
        let completionRunType = runType // capture for closure
        logger.info("📊 Starting God Mode completion tracking for \(configs.count) configurations.")
        let maxWaitTime: TimeInterval = 300
        let checkInterval: TimeInterval = 2.0
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < maxWaitTime {
            let completedConfigs = configs.filter { config in
                if let lastRunInfo = self.statusManager.lastRunInfo[config.id] {
                    switch lastRunInfo.status {
                    case .success, .failed: return true
                    case .idle, .running: return false
                    }
                }
                return false
            }
            logger.info("📈 God Mode progress: \(completedConfigs.count)/\(configs.count) configurations completed.")
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
                    logger.info("🔄 ReservationOrchestrator: Keeping icon filled until all statuses are finalized.")
                    Task {
                        // Wait for all configurations to have final status (not running)
                        var allFinalized = false
                        var waitTime: TimeInterval = 0
                        let maxWaitTime: TimeInterval = AppConstants.maxWaitTimeForGodModeSeconds
                        let checkInterval: TimeInterval = 0.5

                        while !allFinalized, waitTime < maxWaitTime {
                            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                            waitTime += checkInterval

                            // Check if all configurations have final status
                            allFinalized = configs.allSatisfy { config in
                                if let lastRunInfo = self.statusManager.lastRunInfo[config.id] {
                                    switch lastRunInfo.status {
                                    case .success, .failed: return true
                                    case .idle, .running: return false
                                    }
                                }
                                return false
                            }

                            if !allFinalized {
                                logger.info("🔄 Waiting for all statuses to finalize... (\(waitTime)s)")
                            }
                        }

                        // Additional wait time to ensure UI updates are visible
                        try? await Task
                            .sleep(nanoseconds: UInt64(
                                AppConstants
                                    .additionalWaitTimeForUIUpdatesSeconds * 1_000_000_000,
                            ))

                        await MainActor.run {
                            self.statusManager.isRunning = false
                            logger
                                .info(
                                    "🔄 ReservationOrchestrator: Final multiple reservation status - isRunning: \(self.statusManager.isRunning), status: \(self.statusManager.lastRunStatus.description)",
                                )
                            // Allow sleep after autorun (automatic) reservations are done
                            if completionRunType == .automatic {
                                SleepManager.allowSleep()
                            }
                        }
                    }
                }
                logger
                    .info("📊 God Mode completed: \(successfulConfigs.count) successful, \(failedConfigs.count) failed.")
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
