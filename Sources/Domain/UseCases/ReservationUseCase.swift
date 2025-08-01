import Foundation
import os.log

protocol ReservationUseCaseProtocol {
    func createReservation(_ config: ReservationConfig) async throws -> Reservation
    func executeReservation(_ reservation: Reservation) async throws -> ReservationResult
    func cancelReservation(_ reservation: Reservation) async throws
    func getReservationStatus(_ id: UUID) async throws -> ReservationStatus
    func getReservations() async throws -> [Reservation]
}

@MainActor
class ReservationUseCase: ReservationUseCaseProtocol {
    private let repository: any ReservationRepositoryProtocol
    private let webKitService: WebKitServiceProtocol
    private let emailService: EmailServiceProtocol
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "ReservationUseCase")

    init(
        repository: any ReservationRepositoryProtocol,
        webKitService: WebKitServiceProtocol,
        emailService: EmailServiceProtocol
    ) {
        self.repository = repository
        self.webKitService = webKitService
        self.emailService = emailService
    }

    func createReservation(_ config: ReservationConfig) async throws -> Reservation {
        logger.info("📝 Creating reservation for configuration: \(config.name)")

        // Validate configuration
        try validateConfiguration(config)

        // Create reservation
        let reservation = Reservation(configuration: config)

        // Save to repository
        try await repository.save(reservation)

        logger.info("✅ Reservation created successfully: \(reservation.id)")
        return reservation
    }

    func executeReservation(_ reservation: Reservation) async throws -> ReservationResult {
        logger.info("🚀 Executing reservation: \(reservation.id)")

        // Update status to in progress
        var updatedReservation = reservation
        updatedReservation = Reservation(
            id: reservation.id,
            configuration: reservation.configuration,
            status: .inProgress,
            createdAt: reservation.createdAt,
            updatedAt: Date(),
            result: nil,
        )

        try await repository.save(updatedReservation)

        do {
            // Execute the reservation using WebKit service
            let result = try await executeReservationAutomation(reservation)

            // Update reservation with result
            let finalReservation = Reservation(
                id: reservation.id,
                configuration: reservation.configuration,
                status: result.success ? .completed : .failed,
                createdAt: reservation.createdAt,
                updatedAt: Date(),
                result: result,
            )

            try await repository.save(finalReservation)

            logger.info("✅ Reservation execution completed: \(reservation.id)")
            return result

        } catch {
            // Update reservation with error
            let errorResult = ReservationResult(
                success: false,
                message: error.localizedDescription,
                details: ["error": String(describing: error)],
            )

            let failedReservation = Reservation(
                id: reservation.id,
                configuration: reservation.configuration,
                status: .failed,
                createdAt: reservation.createdAt,
                updatedAt: Date(),
                result: errorResult,
            )

            try await repository.save(failedReservation)

            logger.error("❌ Reservation execution failed: \(error.localizedDescription)")
            throw error
        }
    }

    func cancelReservation(_ reservation: Reservation) async throws {
        logger.info("❌ Cancelling reservation: \(reservation.id)")

        guard reservation.status != .completed, reservation.status != .failed else {
            throw DomainError.validation(.invalidFormat("Cannot cancel completed or failed reservation"))
        }

        let cancelledReservation = Reservation(
            id: reservation.id,
            configuration: reservation.configuration,
            status: .cancelled,
            createdAt: reservation.createdAt,
            updatedAt: Date(),
            result: reservation.result,
        )

        try await repository.save(cancelledReservation)
        logger.info("✅ Reservation cancelled successfully")
    }

    func getReservationStatus(_ id: UUID) async throws -> ReservationStatus {
        guard let reservation = try await repository.fetch(id.uuidString) else {
            throw DomainError.storage(.notFound("Reservation not found"))
        }

        return reservation.status
    }

    func getReservations() async throws -> [Reservation] {
        return try await repository.fetchAll()
    }

    // MARK: - Private Methods

    private func validateConfiguration(_ config: ReservationConfig) throws {
        guard !config.name.isEmpty else {
            throw DomainError.validation(.requiredFieldMissing("Configuration name"))
        }

        guard !config.sportName.isEmpty else {
            throw DomainError.validation(.requiredFieldMissing("Sport name"))
        }

        guard config.numberOfPeople > 0 else {
            throw DomainError.validation(.invalidFormat("Number of people must be greater than 0"))
        }
    }

    private func executeReservationAutomation(_ reservation: Reservation) async throws -> ReservationResult {
        logger.info("🤖 Starting automation for reservation: \(reservation.id)")

        let config = reservation.configuration

        // Navigate to the facility URL
        try await webKitService.navigateToURL(config.facilityURL)

        // Wait for page to load and DOM to be ready
        let domReady = await webKitService.waitForDOMReady()
        guard domReady else {
            throw DomainError.automation(.pageLoadTimeout("DOM not ready"))
        }

        // Select sport
        try await selectSport(config.sportName)

        // Select time slot
        if let firstTimeSlot = config.dayTimeSlots.values.first?.first {
            try await selectTimeSlot(firstTimeSlot)
        }

        // Fill contact information if available
        try await fillContactInformation(config)

        // Handle email verification if required (check if verification is needed)
        let verificationRequired = await webKitService.isEmailVerificationRequired()
        if verificationRequired {
            try await handleEmailVerification()
        }

        // Submit reservation
        try await submitReservation()

        logger.info("✅ Automation completed successfully")
        return ReservationResult(
            success: true,
            message: "Reservation completed successfully",
            details: [
                "facility": extractFacilityName(from: config.facilityURL),
                "sport": config.sportName,
                "time": extractTimeSlot(from: config.dayTimeSlots),
            ],
        )
    }

    private func handleEmailVerification() async throws {
        logger.info("📧 Handling email verification...")

        // Search for verification emails
        let emails = try await emailService.searchForVerificationEmails()

        guard
            let verificationCode = emails.compactMap({ email in
                // Parse verification code from email content
                return extractVerificationCode(from: email.body)
            }).first
        else {
            throw DomainError.automation(.humanBehaviorFailed("Verification code not found"))
        }

        // Enter verification code
        let codeSelector = "input[name='code'], input[name='verification'], .code-input"
        let codeClicked = await webKitService.findAndClickElement(codeSelector)
        guard codeClicked else {
            throw DomainError.automation(.elementNotFound("Verification code input"))
        }

        let codeTyped = await webKitService.typeText(verificationCode, into: codeSelector)
        guard codeTyped else {
            throw DomainError.automation(.elementNotFound("Verification code field"))
        }

        // Submit verification
        let verifySelector = "button[type='submit'], .verify-button"
        let verifyClicked = await webKitService.findAndClickElement(verifySelector)
        guard verifyClicked else {
            throw DomainError.automation(.elementNotFound("Verify button"))
        }

        logger.info("✅ Email verification completed")
    }

    private func extractVerificationCode(from content: String) -> String? {
        // Extract 6-digit verification code using regex
        let pattern = "\\b\\d{6}\\b"
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content))
        else {
            return nil
        }

        guard let range = Range(match.range, in: content) else {
            return nil
        }
        let code = String(content[range])
        logger.info("🔐 Extracted verification code: \(code)")
        return code
    }

    // MARK: - Helper Methods

    private func selectSport(_ sportName: String) async throws {
        logger.info("🏀 Selecting sport: \(sportName)")

        // Find and click sport selection
        let sportSelector = "input[name='sport'], select[name='sport'], .sport-selector"
        let sportClicked = await webKitService.findAndClickElement(sportSelector)
        guard sportClicked else {
            throw DomainError.automation(.elementNotFound("Sport selector"))
        }

        // Type sport name
        let sportTyped = await webKitService.typeText(sportName, into: sportSelector)
        guard sportTyped else {
            throw DomainError.automation(.elementNotFound("Sport input"))
        }

        logger.info("✅ Sport selected")
    }

    private func selectTimeSlot(_ timeSlot: TimeSlot) async throws {
        logger.info("⏰ Selecting time slot: \(timeSlot.time)")

        // Select time slot
        let timeSelector = "input[name='time'], select[name='time'], .time-selector"
        let timeClicked = await webKitService.findAndClickElement(timeSelector)
        guard timeClicked else {
            throw DomainError.automation(.elementNotFound("Time selector"))
        }

        // Convert Date to String for time slot
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: timeSlot.time)

        let timeTyped = await webKitService.typeText(timeString, into: timeSelector)
        guard timeTyped else {
            throw DomainError.automation(.elementNotFound("Time input"))
        }

        logger.info("✅ Time slot selected")
    }

    private func fillContactInformation(_: ReservationConfig) async throws {
        logger.info("📝 Filling contact information")

        // Get user settings for contact information
        let userSettings = UserSettingsManager.shared.userSettings

        // Use the existing contact filling method from WebKitService
        // This method handles all contact fields with autofill and human-like movements
        let contactFilled = await webKitService.fillAllContactFieldsWithAutofillAndHumanMovements(
            phoneNumber: userSettings.phoneNumber,
            email: userSettings.imapEmail,
            name: userSettings.name,
        )

        guard contactFilled else {
            throw DomainError.automation(.elementNotFound("Contact form"))
        }

        logger.info("✅ Contact information filled")
    }

    private func submitReservation() async throws {
        logger.info("📤 Submitting reservation")

        let submitSelector = "button[type='submit'], input[type='submit'], .submit-button, .reserve-button"
        let submitClicked = await webKitService.findAndClickElement(submitSelector)
        guard submitClicked else {
            throw DomainError.automation(.elementNotFound("Submit button"))
        }

        // Wait for submission to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        logger.info("✅ Reservation submitted")
    }

    private func extractFacilityName(from urlString: String) -> String {
        guard let url = URL(string: urlString) else {
            return urlString
        }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let host = components?.host else {
            return url.lastPathComponent
        }
        return host
    }

    private func extractTimeSlot(from dayTimeSlots: [ReservationConfig.Weekday: [TimeSlot]]) -> String {
        let sortedSlots = dayTimeSlots.values.flatMap(\.self).sorted { $0.time < $1.time }
        if let firstSlot = sortedSlots.first {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: firstSlot.time)
        }
        return ""
    }
}

// MARK: - Protocol Extensions for WebKit Service

// Using existing protocols from Sources/Utils/Protocols.swift
