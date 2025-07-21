import Combine
import Foundation
import os.log

@MainActor
class ReservationOrchestrator: ObservableObject {
    static let shared = ReservationOrchestrator()

    private let statusManager = ReservationStatusManager.shared
    private let errorHandler = ReservationErrorHandler.shared
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ReservationOrchestrator")
    private let webKitService = WebKitService.shared
    private let configurationManager = ConfigurationManager.shared
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
            case .success: "Successful"
            case let .failed(error): "Failed: \(error)"
            }
        }

        static func == (lhs: RunStatus, rhs: RunStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.running, .running): return true
            case (.success, .success): return true
            case let (.failed(lhsError), .failed(rhsError)): return lhsError == rhsError
            default: return false
            }
        }
    }

    enum RunType: Codable {
        case manual
        case automatic
        case godmode
        var description: String {
            switch self {
            case .manual: "(manual)"
            case .automatic: "(auto)"
            case .godmode: "(god mode)"
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
        case contactInfoFieldNotFound
        case contactInfoConfirmButtonNotFound
        case emailVerificationFailed
        case reservationFailed
        case webKitCrash
        case webKitTimeout
        var errorDescription: String? {
            switch self {
            case .webDriverNotInitialized: "WebDriver not initialized"
            case .navigationFailed: "Failed to navigate to reservation page"
            case .sportButtonNotFound: "Sport button not found on page"
            case .pageLoadTimeout: "Page failed to load completely within timeout"
            case .groupSizePageLoadTimeout: "Group size page failed to load within timeout"
            case .numberOfPeopleFieldNotFound: "Number of people field not found on page"
            case .confirmButtonNotFound: "Confirm button not found on page"
            case .timeSelectionPageLoadTimeout: "Time selection page failed to load within timeout"
            case .timeSlotSelectionFailed: "Failed to select time slot"
            case .contactInfoPageLoadTimeout: "Contact information page failed to load within timeout"
            case .phoneNumberFieldNotFound: "Phone number field not found on page"
            case .emailFieldNotFound: "Email field not found on page"
            case .nameFieldNotFound: "Name field not found on page"
            case .contactInfoFieldNotFound: "Contact information fields not found on page"
            case .contactInfoConfirmButtonNotFound: "Contact information confirm button not found on page"
            case .emailVerificationFailed: "Email verification failed"
            case .reservationFailed: "Reservation was not successful"
            case .webKitCrash: "WebKit process crashed"
            case .webKitTimeout: "WebKit operation timed out"
            }
        }
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

    // MARK: - Orchestration Methods

    func runReservation(for config: ReservationConfig, runType: RunType = .manual) {
        guard !statusManager.isRunning else {
            logger.warning("⚠️ Reservation already running, skipping.")
            return
        }
        statusManager.isRunning = true
        statusManager.lastRunStatus = .running
        Task {
            do {
                try await withTimeout(seconds: 300) {
                    try await self.performReservation(for: config, runType: runType)
                }
            } catch {
                logger.error("⏰ Reservation timeout reached (5 minutes).")
                await errorHandler.handleReservationError(error, config: config, runType: runType)
            }
        }
    }

    func runMultipleReservations(for configs: [ReservationConfig], runType: RunType = .manual) {
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

    func stopAllReservations() async {
        if statusManager.isRunning, let config = currentConfig {
            logger.warning("🚨 Emergency cleanup triggered - capturing screenshot and sending notification.")
            logger.error("🚨 Emergency cleanup triggered for \(config.name): automation was interrupted unexpectedly.")
            await MainActor.run {
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

    func emergencyCleanup(runType _: RunType) async {
        if statusManager.isRunning, let config = currentConfig {
            logger.warning("🚨 Emergency cleanup triggered - capturing screenshot and sending notification.")
            logger.error("🚨 Emergency cleanup triggered for \(config.name): automation was interrupted unexpectedly.")
            await MainActor.run {
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

    func handleManualWindowClosure(runType _: RunType) async {
        logger.info("👤 Manual window closure detected - resetting reservation state.")
        await MainActor.run {
            if statusManager.isRunning {
                statusManager.isRunning = false
                statusManager.lastRunStatus = .failed("Reservation cancelled - window was closed manually")
                statusManager.currentTask = "Reservation cancelled by user"
                statusManager.lastRunDate = Date()
                if let config = self.currentConfig {
                    statusManager.setLastRunInfo(
                        for: config.id,
                        status: .failed("Reservation cancelled - window was closed manually"),
                        date: Date(),
                        runType: .manual,
                        )
                }
            }
        }
        await webKitService.forceReset()
    }

    // MARK: - Private Methods

    private func performReservation(for config: ReservationConfig, runType: RunType) async throws {
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
                throw ReservationError.groupSizePageLoadTimeout
            }
            logger.info("✅ Group size page loaded successfully.")
            await updateTask("Setting number of people: \(config.numberOfPeople)")
            let peopleFilled = await webKitService.fillNumberOfPeople(config.numberOfPeople)
            if !peopleFilled {
                logger.error("❌ Failed to fill number of people field.")
                throw ReservationError.numberOfPeopleFieldNotFound
            }
            logger.info("✅ Successfully filled number of people: \(config.numberOfPeople).")
            await updateTask("Confirming group size...")
            let confirmClicked = await webKitService.clickConfirmButton()
            if !confirmClicked {
                logger.error("❌ Failed to click confirm button.")
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
            let contactInfoPageReady = await withTimeout(seconds: 10) { [self] in
                await webKitService.waitForContactInfoPage()
            } ?? false
            if !contactInfoPageReady {
                logger.error("⏰ Contact information page failed to load within timeout.")
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
                statusManager.isRunning = false
                statusManager.lastRunStatus = .success
                statusManager.setLastRunInfo(for: config.id, status: .success, date: Date(), runType: runType)
                statusManager.lastRunDate = Date()
                statusManager.currentTask = "Reservation completed successfully"
            }
            logger.info("🎉 Reservation completed successfully for \(config.name).")
            logger.info("🧹 Cleaning up WebKit session after successful reservation.")
            await webKitService.disconnect(closeWindow: true)
            return
        } else {
            logger.error("❌ Failed to click sport button: \(config.sportName, privacy: .private).")
            await webKitService.disconnect(closeWindow: true)
            throw ReservationError.sportButtonNotFound
        }
    }

    private func updateTask(_ task: String) async {
        await MainActor.run {
            statusManager.currentTask = task
        }
    }

    private func runReservationWithSeparateWebKit(for config: ReservationConfig, runType: RunType) async {
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
                        }
                        await separateWebKitService.disconnect(closeWindow: false)
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
                }
                logger.info("🎉 Reservation completed successfully for \(config.name).")
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
            }
            await separateWebKitService.disconnect(closeWindow: false)
            return
        }
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
            group.addTask { await operation() }
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

    private func trackGodModeCompletion(configs: [ReservationConfig], runType _: RunType) async {
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
                    logger.info("🔄 ReservationOrchestrator: Keeping icon filled for 3 seconds to show completion.")
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        await MainActor.run {
                            self.statusManager.isRunning = false
                            logger
                                .info(
                                    "🔄 ReservationOrchestrator: Final God Mode status - isRunning: \(self.statusManager.isRunning), status: \(self.statusManager.lastRunStatus.description)",
                                    )
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
