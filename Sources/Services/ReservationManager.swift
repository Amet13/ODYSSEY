import Combine
import Foundation
import os.log

/// Manages the automation of reservation bookings for Ottawa recreation facilities
///
/// This class handles the complete web automation process including:
/// - Web navigation to facility websites
/// - Form automation and data entry
/// - Slot selection and booking
/// - Error handling and logging
/// - Status tracking and user feedback
///
/// The manager uses WebDriver for Chrome automation and provides real-time status updates
/// through ObservableObject protocol for SwiftUI integration.
@MainActor
class ReservationManager: NSObject, ObservableObject {
    static let shared = ReservationManager()

    @Published var isRunning = false
    @Published var lastRunDate: Date?
    @Published var lastRunStatus: RunStatus = .idle
    @Published var currentTask: String = ""

    // Per-configuration last run status, date, and run type
    struct LastRunInfo: Codable {
        let status: RunStatusCodable
        let date: Date?
        let runType: RunType
    }

    enum RunStatusCodable: String, Codable {
        case idle, running, success, failed
        var toRunStatus: RunStatus {
            switch self {
            case .idle: .idle
            case .running: .running
            case .success: .success
            case .failed: .failed("") // error string not persisted
            }
        }

        static func from(_ status: RunStatus) -> RunStatusCodable {
            switch status {
            case .idle: .idle
            case .running: .running
            case .success: .success
            case .failed: .failed
            }
        }
    }

    // Remove the in-memory LastRunInfo struct
    @Published private(set) var lastRunInfo: [UUID: (status: RunStatus, date: Date?, runType: RunType)] = [:] {
        didSet { saveLastRunInfo() }
    }

    private let lastRunInfoKey = "ReservationManager.lastRunInfo"

    private var cancellables = Set<AnyCancellable>()
    private let configurationManager = ConfigurationManager.shared
    private let webKitService = WebKitService.shared
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ReservationManager")
    private var currentConfig: ReservationConfig?

    enum RunStatus: Equatable {
        case idle
        case running
        case success
        case failed(String)

        var description: String {
            switch self {
            case .idle: "Idle"
            case .running: "Running"
            case .success: "Success"
            case let .failed(error): "Failed: \(error)"
            }
        }

        static func == (lhs: RunStatus, rhs: RunStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle):
                return true
            case (.running, .running):
                return true
            case (.success, .success):
                return true
            case let (.failed(lhsError), .failed(rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }

    enum RunType: Codable {
        case manual
        case automatic

        var description: String {
            switch self {
            case .manual: "(manual)"
            case .automatic: "(auto)"
            }
        }
    }

    enum ReservationError: Error, LocalizedError {
        case webDriverNotInitialized
        case navigationFailed
        case sportButtonNotFound
        case pageLoadTimeout
        case groupSizePageLoadTimeout
        case numberOfPeopleFieldNotFound
        case confirmButtonNotFound
        case timeSelectionPageLoadTimeout
        case timeSlotSelectionFailed
        case contactInfoPageLoadTimeout
        case phoneNumberFieldNotFound
        case emailFieldNotFound
        case nameFieldNotFound
        case contactInfoConfirmButtonNotFound
        case emailVerificationFailed
        case reservationFailed
        case webKitCrash
        case webKitTimeout

        var errorDescription: String? {
            switch self {
            case .webDriverNotInitialized:
                "WebDriver not initialized"
            case .navigationFailed:
                "Failed to navigate to reservation page"
            case .sportButtonNotFound:
                "Sport button not found on page"
            case .pageLoadTimeout:
                "Page failed to load completely within timeout"
            case .groupSizePageLoadTimeout:
                "Group size page failed to load within timeout"
            case .numberOfPeopleFieldNotFound:
                "Number of people field not found on page"
            case .confirmButtonNotFound:
                "Confirm button not found on page"
            case .timeSelectionPageLoadTimeout:
                "Time selection page failed to load within timeout"
            case .timeSlotSelectionFailed:
                "Failed to select time slot"
            case .contactInfoPageLoadTimeout:
                "Contact information page failed to load within timeout"
            case .phoneNumberFieldNotFound:
                "Phone number field not found on page"
            case .emailFieldNotFound:
                "Email field not found on page"
            case .nameFieldNotFound:
                "Name field not found on page"
            case .contactInfoConfirmButtonNotFound:
                "Contact information confirm button not found on page"
            case .emailVerificationFailed:
                "Email verification failed"
            case .reservationFailed:
                "Reservation was not successful"
            case .webKitCrash:
                "WebKit process crashed"
            case .webKitTimeout:
                "WebKit operation timed out"
            }
        }
    }

    override private init() {
        super.init()
        loadLastRunInfo()
    }

    private func saveLastRunInfo() {
        let codableDict = lastRunInfo.mapValues { status, date, runType in
            LastRunInfo(status: RunStatusCodable.from(status), date: date, runType: runType)
        }
        if let data = try? JSONEncoder().encode(codableDict) {
            UserDefaults.standard.set(data, forKey: lastRunInfoKey)
        }
    }

    private func loadLastRunInfo() {
        guard let data = UserDefaults.standard.data(forKey: lastRunInfoKey)
        else { return }
        if let codableDict = try? JSONDecoder().decode([UUID: LastRunInfo].self, from: data) {
            lastRunInfo = codableDict.mapValues { info in
                (info.status.toRunStatus, info.date, info.runType)
            }
        }
    }

    /// Handle WebKit crashes gracefully
    private func handleWebKitCrash() async {
        logger.error("WebKit crash detected, attempting recovery...")

        // Try to reset the WebKit service
        await webKitService.reset()
        logger.info("WebKit service reset successful")
    }

    /// Timeout wrapper for async operations
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

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

    // MARK: - Public Methods

    /// Runs reservation automation for a specific configuration
    /// - Parameters:
    ///   - config: The reservation configuration to execute
    ///   - runType: Whether this is a manual or automatic run
    func runReservation(for config: ReservationConfig, runType: RunType = .manual) {
        guard !isRunning else {
            logger.warning("Reservation already running, skipping")
            return
        }

        isRunning = true
        lastRunStatus = .running

        // Add timeout protection to prevent indefinite hanging
        Task {
            do {
                try await withTimeout(seconds: 300) { // 5 minutes timeout
                    try await self.performReservation(for: config, runType: runType)
                }
            } catch {
                logger.error("Reservation timeout reached (5 minutes)")
                await self.handleReservationError(error, config: config, runType: runType)
            }
        }
    }

    /// Handle reservation errors gracefully
    private func handleReservationError(_ error: Error, config: ReservationConfig, runType: RunType) async {
        logger.error("Reservation error: \(error.localizedDescription)")

        // Update status
        await MainActor.run {
            self.isRunning = false
            self.lastRunStatus = .failed(error.localizedDescription)
            self.lastRunInfo[config.id] = (status: .failed(error.localizedDescription), date: Date(), runType: runType)
            self.lastRunDate = Date()
            self.currentTask = "Reservation failed: \(error.localizedDescription)"
        }

        // Log failure
        logger.error("Reservation failed for \(config.name): \(error.localizedDescription)")

        // Cleanup WebKit session after error
        logger.info("Cleaning up WebKit session after error")
        await webKitService.disconnect(closeWindow: false)
    }

    /// Stops all running reservation processes
    func stopAllReservations() {
        isRunning = false
        lastRunStatus = .idle
        currentTask = ""

        // Stop WebKit session
        Task {
            await webKitService.disconnect(closeWindow: false)
        }
    }

    /// Emergency cleanup method for unexpected termination
    /// Captures screenshot and sends notification if automation was running
    func emergencyCleanup() async {
        if isRunning, let config = currentConfig {
            logger.warning("Emergency cleanup triggered - capturing screenshot and sending notification")

            // Log emergency failure
            logger.error("Emergency cleanup triggered for \(config.name): automation was interrupted unexpectedly")

            // Update status
            await MainActor.run {
                self.isRunning = false
                self.lastRunStatus = .failed("Emergency cleanup - automation was interrupted unexpectedly")
                self.currentTask = "Emergency cleanup completed"
                self.lastRunDate = Date()
                self.lastRunInfo[config.id] = (
                    status: .failed("Emergency cleanup - automation was interrupted unexpectedly"),
                    date: Date(),
                    runType: .automatic,
                    )
            }
        }

        // Always cleanup WebKit
        await webKitService.disconnect(closeWindow: false)
    }

    /// Handle manual window closure by user
    func handleManualWindowClosure() async {
        logger.info("Manual window closure detected - resetting reservation state")

        // Update status to reflect manual closure
        await MainActor.run {
            if self.isRunning {
                self.isRunning = false
                self.lastRunStatus = .failed("Reservation cancelled - window was closed manually")
                self.currentTask = "Reservation cancelled by user"
                self.lastRunDate = Date()

                // Update last run info if we have a current config
                if let config = self.currentConfig {
                    self.lastRunInfo[config.id] = (
                        status: .failed("Reservation cancelled - window was closed manually"),
                        date: Date(),
                        runType: .manual,
                        )
                }
            }
        }

        // Force reset WebKit service
        await webKitService.forceReset()
    }

    // MARK: - Private Methods

    private func performReservation(for config: ReservationConfig, runType: RunType) async throws {
        currentTask = "Starting reservation for \(config.name)"
        currentConfig = config

        // Step 1: Check if WebKit service is in valid state
        await updateTask("Checking WebKit service state")
        if !webKitService.isServiceValid() {
            logger.info("WebKit service not in valid state, resetting...")
            await webKitService.reset()
        }

        // Set up window closure callback
        webKitService.onWindowClosed = { [weak self] in
            Task {
                await self?.handleManualWindowClosure()
            }
        }

        // Step 2: Start WebKit session and navigate directly to the URL
        await updateTask("Starting WebKit session")
        try await webKitService.connect()

        // Set current configuration for error reporting
        webKitService.currentConfig = config

        // Step 2: Navigate to facility URL
        await updateTask("Navigating to facility")
        try await webKitService.navigateToURL(config.facilityURL)

        // Step 2.5: Handle cookie consent if present
        await updateTask("Checking for cookie consent...")
        // Note: Cookie consent handling will be implemented in WebKit service

        // Step 3: Wait for page to load
        await updateTask("Waiting for page to load")

        // Wait for DOM to be fully ready with sport buttons
        let domReady = await webKitService.waitForDOMReady()
        if !domReady {
            logger.error("DOM failed to load properly within timeout")
            throw ReservationError.pageLoadTimeout
        }

        logger.info("Page loaded successfully")

        // Step 4: Find and click sport button
        await updateTask("Looking for sport: \(config.sportName)")
        logger.info("Searching for sport button with text: '\(config.sportName, privacy: .private)'")
        let buttonClicked = await webKitService.findAndClickElement(withText: config.sportName)
        if buttonClicked {
            logger.info("Successfully clicked sport button: \(config.sportName, privacy: .private)")

            // Step 5: Wait for group size page to load
            await updateTask("Waiting for group size page...")
            let groupSizePageReady = await webKitService.waitForGroupSizePage()
            if !groupSizePageReady {
                logger.error("Group size page failed to load within timeout")
                throw ReservationError.groupSizePageLoadTimeout
            }

            logger.info("Group size page loaded successfully")

            // Step 6: Fill number of people field
            await updateTask("Setting number of people: \(config.numberOfPeople)")

            let peopleFilled = await webKitService.fillNumberOfPeople(config.numberOfPeople)
            if !peopleFilled {
                logger.error("Failed to fill number of people field")
                throw ReservationError.numberOfPeopleFieldNotFound
            }

            logger.info("Successfully filled number of people: \(config.numberOfPeople)")

            // Step 7: Click confirm button
            await updateTask("Confirming group size...")

            let confirmClicked = await webKitService.clickConfirmButton()
            if !confirmClicked {
                logger.error("Failed to click confirm button")
                throw ReservationError.confirmButtonNotFound
            }

            logger.info("Successfully clicked confirm button")

            // Step 8: Wait for time selection page to load
            await updateTask("Waiting for time selection page...")
            // Skip time selection page detection since the page is already loaded
            // and we can see the "Select a date and time" text and ⊕ elements
            logger.info("Skipping time selection page detection - page already loaded")

            // Step 9: Select time slot based on configuration
            await updateTask("Selecting time slot...")

            // Get the first available day and time from configuration
            let selectedDay = config.dayTimeSlots.keys.first
            let selectedTimeSlot = selectedDay.flatMap { day in
                config.dayTimeSlots[day]?.first
            }

            if let day = selectedDay, let timeSlot = selectedTimeSlot {
                let dayName = day.shortName // Use short name like "Tue"
                let timeString = timeSlot.formattedTime() // Format like "8:30 AM"

                logger.info("Attempting to select: \(dayName) at \(timeString, privacy: .private)")

                let timeSlotSelected = await webKitService.selectTimeSlot(
                    dayName: dayName,
                    timeString: timeString,
                    )
                if !timeSlotSelected {
                    logger.error("Failed to select time slot: \(dayName) at \(timeString, privacy: .private)")
                    throw ReservationError.timeSlotSelectionFailed
                }

                logger.info("Successfully selected time slot: \(dayName) at \(timeString, privacy: .private)")
            } else {
                logger.warning("No time slots configured, skipping time selection")
            }

            // Step 10: Wait for contact information page to load
            await updateTask("Waiting for contact information page...")

            // Wait for contact info page with timeout
            let contactInfoPageReady = await withTimeout(seconds: 10) { [self] in
                await webKitService.waitForContactInfoPage()
            } ?? false

            if !contactInfoPageReady {
                logger.error("Contact information page failed to load within timeout")
                throw ReservationError.contactInfoPageLoadTimeout
            }

            logger.info("Contact information page loaded successfully")

            // Step 11: Proceed with browser autofill-style form filling (less likely to trigger captchas)
            logger.info("Proceeding with browser autofill-style form filling to avoid triggering captchas")

            // Step 12: Fill contact information form with browser autofill behavior
            await updateTask("Filling contact information with autofill...")

            // Get user settings for contact information
            let userSettings = UserSettingsManager.shared.userSettings

            // Fill phone number using browser autofill behavior (remove hyphens as per form instructions)
            let phoneNumber = userSettings.phoneNumber.replacingOccurrences(of: "-", with: "")
            let phoneFilled = await webKitService.fillPhoneNumberWithAutofill(phoneNumber)
            if !phoneFilled {
                logger.error("Failed to fill phone number with autofill")
                throw ReservationError.phoneNumberFieldNotFound
            }

            logger.info("Successfully filled phone number with autofill")

            // Minimal pause between fields (autofill is faster than human typing)
            try? await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000 ... 500_000_000))

            // Fill email address using browser autofill behavior
            let emailFilled = await webKitService.fillEmailWithAutofill(userSettings.imapEmail)
            if !emailFilled {
                logger.error("Failed to fill email address with autofill")
                throw ReservationError.emailFieldNotFound
            }

            logger.info("Successfully filled email address with autofill")

            // Minimal pause between fields (autofill is faster than human typing)
            try? await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000 ... 500_000_000))

            // Fill name using browser autofill behavior
            let nameFilled = await webKitService.fillNameWithAutofill(userSettings.name)
            if !nameFilled {
                logger.error("Failed to fill name with autofill")
                throw ReservationError.nameFieldNotFound
            }

            logger.info("Successfully filled name with autofill")

            // Before clicking confirm, optimized review pause (1.0–1.8s)
            try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000 ... 1_800_000_000))

            // Step 13: Click confirm button for contact information with retry logic
            await updateTask("Confirming contact information...")

            // Record timestamp before clicking confirm
            let verificationStart = Date()

            // Try clicking confirm button up to 6 times with retry logic (increased from 3)
            var contactConfirmClicked = false
            var retryCount = 0
            let maxRetries = 6

            while !contactConfirmClicked, retryCount < maxRetries {
                if retryCount > 0 {
                    logger.info("Retry attempt \(retryCount) for confirm button click")
                    await updateTask("Retrying confirmation... (Attempt \(retryCount + 1)/\(maxRetries))")

                    // Apply essential anti-detection before retry
                    logger.info("Applying essential anti-detection for retry attempt \(retryCount)")
                    await updateTask("Applying anti-detection measures...")

                    // Essential anti-detection sequence
                    await webKitService.addQuickPause()

                    // Optimized wait before retry to avoid reCAPTCHA (1.0-1.8s)
                    try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000 ... 1_800_000_000))
                }

                contactConfirmClicked = await webKitService.clickContactInfoConfirmButtonWithRetry()

                if contactConfirmClicked {
                    // Check if retry text appears after clicking
                    try? await Task.sleep(nanoseconds: 300_000_000) // Wait 0.3s
                    let retryTextDetected = await webKitService.detectRetryText()

                    if retryTextDetected {
                        logger
                            .warning(
                                "Retry text detected after confirm button click - will retry with enhanced measures",
                                )
                        contactConfirmClicked = false
                        retryCount += 1

                        // Additional essential measures after retry text detection
                        logger.info("Applying additional essential measures after retry text detection")
                        await updateTask("Applying additional anti-detection measures...")

                        // Essential anti-detection
                        await webKitService.addQuickPause()

                        // Optimized wait after retry text detection to avoid reCAPTCHA (1.5-2.2s)
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_500_000_000 ... 2_200_000_000))
                    } else {
                        logger.info("Successfully clicked contact confirm button (no retry text detected)")
                        break
                    }
                } else {
                    retryCount += 1
                }
            }

            if !contactConfirmClicked {
                logger.error("Failed to click contact confirm button after \(maxRetries) attempts")
                throw ReservationError.contactInfoConfirmButtonNotFound
            }

            logger.info("Successfully clicked contact confirm button")

            // Step 14: Handle email verification if required
            await updateTask("Checking for email verification...")

            // Wait for the page to fully load
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds

            let verificationRequired = await webKitService.isEmailVerificationRequired()
            if verificationRequired {
                logger.info("Email verification required, starting verification process...")
                let verificationSuccess = await webKitService
                    .handleEmailVerification(verificationStart: verificationStart)
                if !verificationSuccess {
                    logger.error("Email verification failed")
                    throw ReservationError.emailVerificationFailed
                }
                logger.info("Email verification completed successfully")

                // Wait for page navigation to complete after email verification
                await updateTask("Waiting for confirmation page to load...")
                logger.info("Waiting for page navigation to complete after email verification...")
                try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second for navigation

                // Wait for DOM to be ready on the new page
                let domReady = await webKitService.waitForDOMReady()
                if domReady {
                    logger.info("Confirmation page loaded successfully")
                } else {
                    logger.warning("DOM ready check failed, but continuing with click result as success indicator")
                }
            }

            // Step 15: Determine success based on whether we completed all steps
            await updateTask("Finishing reservation...")

            // If we reached this point and email verification was successful (if required),
            // or if no email verification was needed, then the reservation is successful
            logger.info("Reservation completed successfully - all steps completed!")
            await MainActor.run {
                self.isRunning = false
                self.lastRunStatus = .success
                self.lastRunInfo[config.id] = (status: .success, date: Date(), runType: runType)
                self.lastRunDate = Date()
                self.currentTask = "Reservation completed successfully"
            }

            // Log success
            logger.info("Reservation completed successfully for \(config.name)")

            logger.info("Cleaning up WebKit session after successful reservation")
            await webKitService.disconnect(closeWindow: true)
            return // <-- Ensure we exit after success
        } else {
            logger.error("Failed to click sport button: \(config.sportName, privacy: .private)")
            throw ReservationError.sportButtonNotFound
        }
    }

    private func updateTask(_ task: String) async {
        await MainActor.run {
            currentTask = task
        }
    }

    private func handleError(_ error: String, configId: UUID?, runType: RunType = .manual) async {
        await MainActor.run {
            self.isRunning = false
            self.lastRunStatus = .failed(error)
            self.currentTask = "Error: \(error)"
            self.lastRunDate = Date()
            if let configId {
                self.lastRunInfo[configId] = (status: .failed(error), date: Date(), runType: runType)
            }
        }
        logger.error("Reservation error: \(error)")

        // Log failure if we have the current config
        if let currentConfig {
            logger.error("Reservation failed for \(currentConfig.name): \(error)")
        }

        // Always cleanup WebKit session
        logger.info("Cleaning up WebKit session after error")
        await webKitService.disconnect(closeWindow: false)
    }

    // Helper to get last run info for a config
    func getLastRunInfo(for configId: UUID) -> (status: RunStatus, date: Date?, runType: RunType)? {
        lastRunInfo[configId]
    }

    // Helper function to add timeout to async operations
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
}
