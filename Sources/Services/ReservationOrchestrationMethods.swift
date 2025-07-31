import Foundation
import os.log

@MainActor
public final class ReservationOrchestrationMethods {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "ReservationOrchestration")

    // MARK: - Orchestration Methods

    /**
     * Runs a single reservation for the given configuration and run type.
     * - Parameters:
     *   - config: The reservation configuration to run.
     *   - runType: The type of run (manual, automatic, godmode).
     */
    public func runReservation(for config: ReservationConfig, runType: ReservationRunType = .manual) async throws {
        logger.info("🎯 Starting reservation for config: \(config.name).")

        // Validate configuration
        try validateReservationConfig(config)

        // Update status
        updateReservationStatus(.running, for: config.id.uuidString, runType: runType)

        do {
            // Perform the reservation
            try await performReservation(for: config, runType: runType)

            // Update status on success
            updateReservationStatus(.success, for: config.id.uuidString, runType: runType)
            logger.info("✅ Reservation completed successfully for: \(config.name).")

        } catch {
            // Update status on failure
            updateReservationStatus(.failed(error.localizedDescription), for: config.id.uuidString, runType: runType)
            logger.error("❌ Reservation failed for \(config.name): \(error.localizedDescription).")
            throw error
        }
    }

    /**
     * Stops the current reservation run.
     */
    public func stopReservation() async {
        logger.info("🛑 Stopping reservation...")
        updateReservationStatus(.stopped, for: nil, runType: .manual)
    }

    /**
     * Runs multiple reservations in parallel (God Mode).
     * - Parameter configs: Array of reservation configurations to run.
     */
    public func runGodModeReservations(configs: [ReservationConfig]) async {
        logger.info("🚀 Starting God Mode with \(configs.count) configurations.")

        // Initialize all configurations
        for config in configs {
            updateReservationStatus(.idle, for: config.id.uuidString, runType: .godmode)
        }

        // Run all reservations in parallel
        await withTaskGroup(of: Void.self) { group in
            for config in configs {
                group.addTask {
                    do {
                        try await self.runReservation(for: config, runType: .godmode)
                    } catch {
                        self.logger
                            .error("❌ God Mode reservation failed for \(config.name): \(error.localizedDescription)")
                    }
                }
            }
        }

        logger.info("✅ God Mode completed.")
    }

    /**
     * Validates a reservation configuration.
     * - Parameter config: The configuration to validate.
     * - Throws: ValidationError if configuration is invalid.
     */
    private func validateReservationConfig(_ config: ReservationConfig) throws {
        logger.info("🔍 Validating reservation configuration: \(config.name).")

        // Check required fields
        guard !config.facilityURL.isEmpty else {
            throw ReservationError.facilityNotFound("Facility URL is required")
        }

        guard !config.sportName.isEmpty else {
            throw ReservationError.automationFailed("Sport name is required")
        }

        guard config.numberOfPeople > 0 else {
            throw ReservationError.automationFailed("Number of people must be greater than 0")
        }

        guard !config.dayTimeSlots.isEmpty else {
            throw ReservationError.automationFailed("At least one time slot must be configured")
        }

        logger.info("✅ Configuration validation passed.")
    }

    /**
     * Performs the actual reservation automation.
     * - Parameters:
     *   - config: The reservation configuration.
     *   - runType: The type of run.
     * - Throws: ReservationError if automation fails.
     */
    private func performReservation(for config: ReservationConfig, runType _: ReservationRunType) async throws {
        logger.info("🤖 Performing reservation automation for: \(config.name).")

        // Get dependencies
        let webKitService = WebKitService.shared
        let emailService = EmailService.shared

        // Navigate to facility
        try await webKitService.navigateToURL(config.facilityURL)

        // Wait for page to load
        let domReady = await webKitService.waitForDOMReady()
        guard domReady else {
            throw ReservationError.pageLoadTimeout
        }

        // Select sport only
        try await selectSport(config: config)

        // Fill number of people
        try await fillNumberOfPeople(config.numberOfPeople)

        // Select time slot
        try await selectTimeSlot(config: config)

        // Fill contact information
        try await fillContactInformation(config: config)

        // Handle email verification if required
        let verificationRequired = await webKitService.isEmailVerificationRequired()
        if verificationRequired {
            try await handleEmailVerification(emailService: emailService)
        }

        // Submit reservation
        try await submitReservation()

        logger.info("✅ Reservation automation completed successfully.")
    }

    /**
     * Selects sport for the reservation.
     * - Parameter config: The reservation configuration.
     * - Throws: ReservationError if selection fails.
     */
    private func selectSport(config: ReservationConfig) async throws {
        logger.info("🏀 Selecting sport.")

        // Select sport
        let sportClicked = await WebKitService.shared
            .findAndClickElement("input[name='sport'], select[name='sport'], .sport-selector")
        guard sportClicked else {
            throw ReservationError.sportButtonNotFound
        }

        // Type sport name
        let sportTyped = await WebKitService.shared.typeText(
            config.sportName,
            into: "input[name='sport'], select[name='sport'], .sport-selector",
            )
        guard sportTyped else {
            throw ReservationError.sportButtonNotFound
        }

        logger.info("✅ Sport selected.")
    }

    /**
     * Selects time slot for the reservation.
     * - Parameter config: The reservation configuration.
     * - Throws: ReservationError if selection fails.
     */
    private func selectTimeSlot(config: ReservationConfig) async throws {
        logger.info("⏰ Selecting time slot.")

        // Select first available time slot
        if let firstTimeSlot = config.dayTimeSlots.values.first?.first {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let timeString = timeFormatter.string(from: firstTimeSlot.time)

            let timeClicked = await WebKitService.shared
                .findAndClickElement("input[name='time'], select[name='time'], .time-selector")
            guard timeClicked else {
                throw ReservationError.timeSlotSelectionFailed
            }

            let timeTyped = await WebKitService.shared.typeText(
                timeString,
                into: "input[name='time'], select[name='time'], .time-selector",
                )
            guard timeTyped else {
                throw ReservationError.timeSlotSelectionFailed
            }
        }

        logger.info("✅ Time slot selected.")
    }

    /**
     * Fills the number of people field.
     * - Parameter count: The number of people.
     * - Throws: ReservationError if filling fails.
     */
    private func fillNumberOfPeople(_ count: Int) async throws {
        logger.info("👥 Filling number of people: \(count).")

        let peopleClicked = await WebKitService.shared
            .findAndClickElement("input[name='people'], input[name='participants'], .people-input")
        guard peopleClicked else {
            throw ReservationError.numberOfPeopleFieldNotFound
        }

        let peopleTyped = await WebKitService.shared.typeText(
            "\(count)",
            into: "input[name='people'], input[name='participants'], .people-input",
            )
        guard peopleTyped else {
            throw ReservationError.numberOfPeopleFieldNotFound
        }

        logger.info("✅ Number of people filled.")
    }

    /**
     * Fills contact information for the reservation.
     * - Parameter config: The reservation configuration.
     * - Throws: ReservationError if filling fails.
     */
    private func fillContactInformation(config _: ReservationConfig) async throws {
        logger.info("👤 Filling contact information.")

        let userSettings = UserSettingsManager.shared.userSettings

        let contactFilled = await WebKitService.shared.fillAllContactFieldsWithAutofillAndHumanMovements(
            phoneNumber: userSettings.phoneNumber,
            email: userSettings.imapEmail,
            name: userSettings.name,
            )

        guard contactFilled else {
            throw ReservationError.contactInfoFieldNotFound
        }

        logger.info("✅ Contact information filled.")
    }

    /**
     * Handles email verification if required.
     * - Parameter emailService: The email service to use.
     * - Throws: ReservationError if verification fails.
     */
    private func handleEmailVerification(emailService: EmailService) async throws {
        logger.info("📧 Handling email verification.")

        // Search for verification emails
        let emails = try await emailService.searchForVerificationEmails()

        guard let verificationEmail = emails.first else {
            throw ReservationError.emailVerificationFailed
        }

        // Extract verification code
        let verificationCode = extractVerificationCode(from: verificationEmail.body)
        guard let code = verificationCode else {
            throw ReservationError.emailVerificationFailed
        }

        // Enter verification code
        let codeClicked = await WebKitService.shared
            .findAndClickElement("input[name='code'], input[name='verification'], .code-input")
        guard codeClicked else {
            throw ReservationError.emailVerificationFailed
        }

        let codeTyped = await WebKitService.shared.typeText(
            code,
            into: "input[name='code'], input[name='verification'], .code-input",
            )
        guard codeTyped else {
            throw ReservationError.emailVerificationFailed
        }

        // Submit verification
        let verifyClicked = await WebKitService.shared.findAndClickElement("button[type='submit'], .verify-button")
        guard verifyClicked else {
            throw ReservationError.emailVerificationFailed
        }

        logger.info("✅ Email verification completed.")
    }

    /**
     * Submits the reservation.
     * - Throws: ReservationError if submission fails.
     */
    private func submitReservation() async throws {
        logger.info("📤 Submitting reservation.")

        let submitClicked = await WebKitService.shared
            .findAndClickElement("button[type='submit'], input[type='submit'], .submit-button, .reserve-button")
        guard submitClicked else {
            throw ReservationError.confirmButtonNotFound
        }

        // Wait for submission to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        logger.info("✅ Reservation submitted.")
    }

    /**
     * Extracts verification code from email body.
     * - Parameter content: The email body content.
     * - Returns: The verification code if found, nil otherwise.
     */
    private func extractVerificationCode(from content: String) -> String? {
        // Look for common verification code patterns
        let patterns = [
            "verification code is: (\\d{4,6})",
            "code: (\\d{4,6})",
            "verification: (\\d{4,6})",
            "code is (\\d{4,6})",
        ]

        for pattern in patterns {
            if
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                let match = regex.firstMatch(
                    in: content,
                    options: [],
                    range: NSRange(location: 0, length: content.count),
                    )
            {
                guard let range = Range(match.range(at: 1), in: content) else {
                    continue
                }

                let code = String(content[range])
                logger.info("🔐 Extracted verification code: \(code).")
                return code
            }
        }

        return nil
    }

    /**
     * Updates the reservation status.
     * - Parameters:
     *   - status: The new status.
     *   - configId: The configuration ID (optional).
     *   - runType: The run type.
     */
    private func updateReservationStatus(
        _ status: ReservationRunStatus,
        for configId: String?,
        runType _: ReservationRunType,
        ) {
        // This would typically update a status manager
        logger.info("📊 Updated reservation status: \(status.description) for config: \(configId ?? "unknown").")
    }
}
