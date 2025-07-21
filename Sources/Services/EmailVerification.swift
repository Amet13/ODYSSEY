import Foundation
import os.log

/// Email verification and testing functionality
/// Handles email validation, testing, and verification code management
@MainActor
extension EmailCore {
    // MARK: - Email Testing Methods

    /// Tests email configuration with current settings
    /// - Returns: TestResult indicating success or failure
    func testEmailConfiguration() async -> TestResult {
        logger.info("🧪 Testing email configuration")

        setTesting(true)
        defer { setTesting(false) }

        let settings = userSettingsManager.userSettings

        // Validate email settings
        guard settings.hasEmailConfigured else {
            logger.error("❌ Incomplete email settings")
            return .failure("Please configure all email settings (email, password, server)")
        }

        // Validate email format
        guard ValidationService.shared.validateEmail(settings.imapEmail) else {
            logger.error("❌ Invalid email format")
            return .failure("Invalid email format")
        }

        // Check if it's a Gmail account
        let isGmail = ValidationService.shared.isGmailAccount(settings.imapEmail)

        if isGmail {
            logger.info("📧 Testing Gmail configuration")
            return await testGmailConfiguration(settings: settings)
        } else {
            logger.info("📧 Testing standard IMAP configuration")
            return await testStandardIMAPConfiguration(settings: settings)
        }
    }

    /// Tests Gmail configuration
    /// - Parameter settings: User settings
    /// - Returns: TestResult indicating success or failure
    private func testGmailConfiguration(settings: UserSettings) async -> TestResult {
        logger.info("📧 Testing Gmail configuration for \(settings.imapEmail, privacy: .private)")

        // Validate Gmail app password
        guard ValidationService.shared.validateGmailAppPassword(settings.imapPassword) else {
            logger.error("❌ Invalid Gmail app password")
            return .failure(
                "Invalid Gmail app password. Please use a 16-character app password generated from Google Account settings.",
                provider: .gmail,
                )
        }

        // Test connection to Gmail IMAP
        let testResult = await testIMAPConnection(
            email: settings.imapEmail,
            password: settings.imapPassword,
            server: AppConstants.gmailImapServer,
            )

        if case let .failure(error, _) = testResult {
            logger.error("❌ Gmail connection test failed: \(error)")
            return .failure(
                "Gmail connection failed: \(error). Please check your app password and ensure 2-factor authentication is enabled.",
                provider: .gmail,
                )
        }

        logger.info("✅ Gmail configuration test successful")
        return .success("Gmail configuration is valid and connection successful")
    }

    /// Tests standard IMAP configuration
    /// - Parameter settings: User settings
    /// - Returns: TestResult indicating success or failure
    private func testStandardIMAPConfiguration(settings: UserSettings) async -> TestResult {
        logger.info("📧 Testing standard IMAP configuration for \(settings.imapEmail, privacy: .private)")

        // Validate server format
        guard ValidationService.shared.validateServer(settings.currentServer) else {
            logger.error("❌ Invalid server format")
            return .failure("Invalid server format. Please enter a valid IMAP server address.")
        }

        // Test connection to IMAP server
        let testResult = await testIMAPConnection(
            email: settings.imapEmail,
            password: settings.imapPassword,
            server: settings.currentServer,
            )

        if case let .failure(error, _) = testResult {
            logger.error("❌ IMAP connection test failed: \(error)")
            return .failure("IMAP connection failed: \(error). Please check your server, username, and password.")
        }

        logger.info("✅ Standard IMAP configuration test successful")
        return .success("IMAP configuration is valid and connection successful")
    }

    // MARK: - Verification Code Methods

    /// Waits for verification code to arrive
    /// - Parameters:
    ///   - timeout: Maximum time to wait in seconds
    ///   - checkInterval: Interval between checks in seconds
    /// - Returns: Verification code if found, nil if timeout
    func waitForVerificationCode(timeout: TimeInterval = 60.0, checkInterval: TimeInterval = 2.0) async -> String? {
        logger.info("⏳ Waiting for verification code (timeout: \(timeout)s)")

        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            // Check for verification code
            if let code = await extractVerificationCode() {
                logger.info("✅ Verification code received: \(code)")
                return code
            }

            // Wait before next check
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }

        logger.warning("⏰ Verification code timeout reached")
        return nil
    }

    /// Validates verification code format
    /// - Parameter code: The verification code to validate
    /// - Returns: True if code is valid, false otherwise
    func validateVerificationCode(_ code: String) -> Bool {
        // Check if code is exactly 4 digits
        let isValid = code.count == 4 && code.allSatisfy(\.isNumber)

        if isValid {
            logger.info("✅ Verification code format is valid")
        } else {
            logger.error("❌ Invalid verification code format")
        }

        return isValid
    }

    /// Stores verification code in shared pool
    /// - Parameters:
    ///   - email: Email address
    ///   - code: Verification code
    func storeVerificationCode(email: String, code: String) {
        logger.info("💾 Storing verification code for \(email, privacy: .private)")

        // Validate code format
        guard validateVerificationCode(code) else {
            logger.error("❌ Cannot store invalid verification code")
            return
        }

        // Store in shared pool
        verificationCodePool.addCode(for: email, code: code)

        logger.info("✅ Verification code stored successfully")
    }

    /// Retrieves verification code from shared pool
    /// - Parameter email: Email address
    /// - Returns: Verification code if found and not expired, nil otherwise
    func retrieveVerificationCode(email: String) -> String? {
        logger.info("📧 Retrieving verification code for \(email, privacy: .private)")

        let code = verificationCodePool.getCode(for: email)

        if code != nil {
            logger.info("✅ Verification code retrieved successfully")
        } else {
            logger.warning("⚠️ No verification code found or code expired")
        }

        return code
    }

    /// Clears verification code for specific email
    /// - Parameter email: Email address
    func clearVerificationCode(email: String) {
        logger.info("🧹 Clearing verification code for \(email, privacy: .private)")
        verificationCodePool.removeCode(for: email)
    }

    /// Clears all verification codes
    func clearAllVerificationCodes() {
        logger.info("🧹 Clearing all verification codes")
        verificationCodePool.clearAllCodes()
    }

    // MARK: - Email Validation Methods

    /// Validates complete email configuration
    /// - Returns: True if configuration is valid, false otherwise
    func validateEmailConfiguration() -> Bool {
        logger.info("🔍 Validating email configuration")

        let settings = userSettingsManager.userSettings

        // Check if all required fields are filled
        guard settings.hasEmailConfigured else {
            logger.error("❌ Incomplete email configuration")
            return false
        }

        // Validate email format
        guard ValidationService.shared.validateEmail(settings.imapEmail) else {
            logger.error("❌ Invalid email format")
            return false
        }

        // Check if it's a Gmail account
        let isGmail = ValidationService.shared.isGmailAccount(settings.imapEmail)

        if isGmail {
            // Validate Gmail app password
            guard ValidationService.shared.validateGmailAppPassword(settings.imapPassword) else {
                logger.error("❌ Invalid Gmail app password format")
                return false
            }
        } else {
            // Validate server format for non-Gmail
            guard ValidationService.shared.validateServer(settings.currentServer) else {
                logger.error("❌ Invalid server format")
                return false
            }
        }

        logger.info("✅ Email configuration validation successful")
        return true
    }

    /// Gets email configuration status
    /// - Returns: String describing the configuration status
    func getEmailConfigurationStatus() -> String {
        let settings = userSettingsManager.userSettings

        if !settings.hasEmailConfigured {
            return "Email configuration incomplete"
        }

        if !ValidationService.shared.validateEmail(settings.imapEmail) {
            return "Invalid email format"
        }

        let isGmail = ValidationService.shared.isGmailAccount(settings.imapEmail)

        if isGmail {
            if !ValidationService.shared.validateGmailAppPassword(settings.imapPassword) {
                return "Invalid Gmail app password format"
            }
            return "Gmail configuration ready"
        } else {
            if !ValidationService.shared.validateServer(settings.currentServer) {
                return "Invalid server format"
            }
            return "IMAP configuration ready"
        }
    }

    // MARK: - Diagnostic Methods

    /// Gets email configuration diagnostics
    /// - Returns: Dictionary with diagnostic information
    func getEmailConfigurationDiagnostics() -> [String: Any] {
        let settings = userSettingsManager.userSettings

        var diagnostics: [String: Any] = [:]

        // Basic configuration
        diagnostics["hasEmailConfigured"] = settings.hasEmailConfigured
        diagnostics["emailLength"] = settings.imapEmail.count
        diagnostics["passwordLength"] = settings.imapPassword.count
        diagnostics["serverLength"] = settings.currentServer.count

        // Validation results
        diagnostics["isValidEmail"] = ValidationService.shared.validateEmail(settings.imapEmail)
        diagnostics["isGmailAccount"] = ValidationService.shared.isGmailAccount(settings.imapEmail)
        diagnostics["isValidServer"] = ValidationService.shared.validateServer(settings.currentServer)

        if ValidationService.shared.isGmailAccount(settings.imapEmail) {
            diagnostics["isValidGmailAppPassword"] = ValidationService.shared
                .validateGmailAppPassword(settings.imapPassword)
        }

        // Connection status
        diagnostics["lastConnectionTimestamp"] = Self.lastConnectionTimestamp?.timeIntervalSince1970
        diagnostics["activeCodeCount"] = verificationCodePool.activeCodeCount

        return diagnostics
    }
}
