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
        currentTask = "Starting reservation for \(config.name)"
        currentConfig = config

        // Start automation in background task
        Task {
            await performReservation(for: config, runType: runType)
        }
    }

    /// Stops all running reservation processes
    func stopAllReservations() {
        isRunning = false
        lastRunStatus = .idle
        currentTask = ""

        // Stop WebKit session
        Task {
            await webKitService.disconnect()
        }
    }

    /// Emergency cleanup method for unexpected termination
    /// Captures screenshot and sends notification if automation was running
    func emergencyCleanup() async {
        if isRunning, let config = currentConfig {
            logger.warning("Emergency cleanup triggered - capturing screenshot and sending notification")

            // Capture screenshot before cleanup
            let screenshotData = try? await webKitService.takeScreenshot()
            if screenshotData != nil {
                logger.info("Emergency screenshot captured successfully")
            } else {
                logger.warning("Failed to capture emergency screenshot")
            }

            // Send emergency failure notification to Telegram
            // Remove all Telegram notification logic

            // Update status
            await MainActor.run {
                self.isRunning = false
                self.lastRunStatus = .failed("Emergency cleanup - automation was interrupted unexpectedly")
                self.currentTask = "Emergency cleanup completed"
                self.lastRunDate = Date()
                self.lastRunInfo[config.id] = (
                    .failed("Emergency cleanup - automation was interrupted unexpectedly"),
                    Date(),
                    .automatic,
                )
            }
        }

        // Always cleanup WebKit
        await webKitService.disconnect()
    }

    // MARK: - Private Methods

    private func performReservation(for config: ReservationConfig, runType: RunType) async {
        // Set up a timeout for the entire reservation process (5 minutes)
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(Constants.reservationTimeout) * 1_000_000_000) // 5 minutes
            logger.error("Reservation timeout reached (5 minutes)")
            await handleError(
                "Reservation timed out after 5 minutes",
                configId: config.id,
                runType: runType,
            )
            await webKitService.disconnect()
        }

        let reservationTask = Task {
            do {
                // Step 1: Start WebKit session and navigate directly to the URL
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
                    let contactInfoPageReady = await webKitService.waitForContactInfoPage()
                    if !contactInfoPageReady {
                        logger.error("Contact information page failed to load within timeout")
                        throw ReservationError.contactInfoPageLoadTimeout
                    }

                    logger.info("Contact information page loaded successfully")

                    // Step 11: Proceed with human-like form filling (invisible reCAPTCHA will be handled automatically)
                    logger.info("Proceeding with human-like form filling to avoid triggering invisible reCAPTCHA")

                    // Step 12: Fill contact information form with human-like behavior
                    await updateTask("Filling contact information...")

                    // Enhance human-like behavior before form filling
                    await webKitService.enhanceHumanLikeBehavior()

                    // Get user settings for contact information
                    let userSettings = UserSettingsManager.shared.userSettings

                    // Fill phone number (remove hyphens as per form instructions)
                    let phoneNumber = userSettings.phoneNumber.replacingOccurrences(of: "-", with: "")
                    let phoneFilled = await webKitService.fillPhoneNumber(phoneNumber)
                    if !phoneFilled {
                        logger.error("Failed to fill phone number")
                        throw ReservationError.phoneNumberFieldNotFound
                    }

                    logger.info("Successfully filled phone number")

                    // Fill email address
                    let emailFilled = await webKitService.fillEmail(userSettings.imapEmail)
                    if !emailFilled {
                        logger.error("Failed to fill email address")
                        throw ReservationError.emailFieldNotFound
                    }

                    logger.info("Successfully filled email address")

                    // Fill name
                    let nameFilled = await webKitService.fillName(userSettings.name)
                    if !nameFilled {
                        logger.error("Failed to fill name")
                        throw ReservationError.nameFieldNotFound
                    }

                    logger.info("Successfully filled name")

                    // Step 13: Click confirm button for contact information with retry logic
                    await updateTask("Confirming contact information...")

                    // Record timestamp before clicking confirm
                    let verificationStart = Date()

                    // Try clicking confirm button up to 3 times with retry logic
                    var contactConfirmClicked = false
                    var retryCount = 0
                    let maxRetries = 3

                    while !contactConfirmClicked, retryCount < maxRetries {
                        if retryCount > 0 {
                            logger.info("Retry attempt \(retryCount) for confirm button click")
                            await updateTask("Retrying confirmation... (Attempt \(retryCount + 1)/\(maxRetries))")

                            // Wait 0.5 seconds before retry
                            try? await Task.sleep(nanoseconds: 500_000_000)

                            // Re-enhance human-like behavior before retry
                            await webKitService.enhanceHumanLikeBehavior()
                        }

                        contactConfirmClicked = await webKitService.clickContactInfoConfirmButtonWithRetry()

                        if contactConfirmClicked {
                            // Check if retry text appears after clicking
                            try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5s
                            let retryTextDetected = await webKitService.detectRetryText()

                            if retryTextDetected {
                                logger.warning("Retry text detected after confirm button click - will retry")
                                contactConfirmClicked = false
                                retryCount += 1
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
                    let verificationRequired = await webKitService.isEmailVerificationRequired()
                    if verificationRequired {
                        logger.info("Email verification required, starting verification process...")
                        let verificationSuccess = await webKitService
                            .handleEmailVerification(verificationStart: verificationStart)
                        if !verificationSuccess {
                            logger.error("Email verification failed")

                            // Capture screenshot before throwing error
                            let screenshotData = try? await webKitService.takeScreenshot()
                            if screenshotData != nil {
                                logger.info("Screenshot captured for email verification failure")
                            } else {
                                logger.warning("Failed to capture screenshot for email verification failure")
                            }

                            // Send failure notification with screenshot to Telegram
                            // Remove all Telegram notification logic

                            throw ReservationError.emailVerificationFailed
                        }
                        logger.info("Email verification completed successfully")
                    } else {
                        logger.info("No email verification required")
                    }

                    // Step 15: Check for success
                    await updateTask("Checking reservation success...")
                    let success = await webKitService.checkReservationSuccess()
                    if success {
                        logger.info("🎉 Reservation completed successfully!")

                        // Update status to success
                        await MainActor.run {
                            self.isRunning = false
                            self.lastRunStatus = .success
                            self.lastRunInfo[config.id] = (.success, Date(), runType)
                            self.lastRunDate = Date()
                            self.currentTask = "Reservation completed successfully"
                        }

                        // Send notifications if configured
                        // Remove all Telegram notification logic

                        // Cleanup WebKit session after successful reservation
                        logger.info("Cleaning up WebKit session after successful reservation")
                        await webKitService.disconnect()
                    } else {
                        logger.error("Reservation was not successful")
                        throw ReservationError.reservationFailed
                    }

                } else {
                    logger.error("Failed to click sport button: \(config.sportName, privacy: .private)")
                    throw ReservationError.sportButtonNotFound
                }

            } catch {
                logger.error("Reservation failed with error: \(error)")
                await handleError(
                    error.localizedDescription,
                    configId: config.id,
                    runType: runType,
                )

                // Cleanup WebKit session on error
                await webKitService.disconnect()
            }
        }

        // Wait for either the reservation to complete or timeout
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await reservationTask.value }
            group.addTask { await timeoutTask.value }

            // Wait for the first task to complete
            for await _ in group {
                // Cancel the other task
                timeoutTask.cancel()
                reservationTask.cancel()
                break
            }
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
                self.lastRunInfo[configId] = (.failed(error), Date(), runType)
            }
        }
        logger.error("Reservation error: \(error)")

        // Capture screenshot and send Telegram notification for automation failures
        if currentConfig != nil {
            // Capture screenshot before cleanup
            let screenshotData = try? await webKitService.takeScreenshot()
            if screenshotData != nil {
                logger.info("Screenshot captured successfully for failure notification")
            } else {
                logger.warning("Failed to capture screenshot for failure notification")
            }

            // Send failure notification with screenshot to Telegram
            // Remove all Telegram notification logic
        }

        // Always cleanup WebKit session
        logger.info("Cleaning up WebKit session after error")
        await webKitService.disconnect()
    }

    // Helper to get last run info for a config
    func getLastRunInfo(for configId: UUID) -> (status: RunStatus, date: Date?, runType: RunType)? {
        lastRunInfo[configId]
    }
}
