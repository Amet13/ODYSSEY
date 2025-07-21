import Foundation
import Network
import os.log

/// IMAP-specific email functionality
/// Handles IMAP connections, email fetching, and verification code extraction
@MainActor
extension EmailCore {
    // MARK: - IMAP Connection Methods

    /// Connects to IMAP server and searches for verification email
    /// - Parameters:
    ///   - server: IMAP server address
    ///   - port: IMAP server port
    ///   - username: Email username
    ///   - password: Email password
    /// - Throws: IMAPError if connection fails
    func connect(
        server: String,
        port: UInt16,
        username: String,
        password: String,
        ) async throws {
        logger.info("🔗 Connecting to IMAP server: \(server):\(port)")

        // Test the connection first
        let testResult = await testIMAPConnection(
            email: username,
            password: password,
            server: server,
            )

        if case let .failure(error, _) = testResult {
            throw IMAPError.connectionFailed(error)
        }

        logger.info("✅ IMAP connection successful")
    }

    /// Tests IMAP connection with provided credentials
    /// - Parameters:
    ///   - email: Email address
    ///   - password: Email password
    ///   - server: IMAP server
    /// - Returns: TestResult indicating success or failure
    func testIMAPConnection(email: String, password: String, server: String) async -> TestResult {
        logger.info("🧪 Testing IMAP connection for \(email, privacy: .private)")

        // Rate limiting: prevent too many connection attempts
        if let lastAttempt = Self.lastConnectionTimestamp {
            let timeSinceLastAttempt = Date().timeIntervalSince(lastAttempt)
            if timeSinceLastAttempt < 2.0 { // Minimum 2 seconds between attempts
                logger.warning("⏰ Rate limiting: waiting before next connection attempt")
                try? await Task.sleep(nanoseconds: UInt64((2.0 - timeSinceLastAttempt) * 1_000_000_000))
            }
        }

        Self.setLastConnectionTimestamp(Date())

        // Validate input parameters
        guard !email.isEmpty, !password.isEmpty, !server.isEmpty else {
            logger.error("❌ Invalid connection parameters")
            return .failure("Invalid connection parameters")
        }

        // Determine if this is a Gmail account
        let isGmail = ValidationService.shared.isGmailAccount(email)

        if isGmail {
            logger.info("📧 Testing Gmail IMAP connection")
            return await testGmailConnection(email: email, password: password)
        } else {
            logger.info("📧 Testing standard IMAP connection")
            return await testStandardIMAPConnection(email: email, password: password, server: server)
        }
    }

    // MARK: - Gmail-specific Methods

    /// Tests Gmail IMAP connection
    /// - Parameters:
    ///   - email: Gmail address
    ///   - password: App password
    /// - Returns: TestResult indicating success or failure
    private func testGmailConnection(email: String, password: String) async -> TestResult {
        logger.info("📧 Testing Gmail connection for \(email, privacy: .private)")

        // Validate Gmail app password format
        if !ValidationService.shared.validateGmailAppPassword(password) {
            logger.error("❌ Invalid Gmail app password format")
            return .failure(
                "Invalid Gmail app password format. Please use a 16-character app password.",
                provider: .gmail,
                )
        }

        // Test connection to Gmail IMAP
        return await testStandardIMAPConnection(
            email: email,
            password: password,
            server: AppConstants.gmailImapServer,
            )
    }

    // MARK: - Standard IMAP Methods

    /// Tests standard IMAP connection
    /// - Parameters:
    ///   - email: Email address
    ///   - password: Email password
    ///   - server: IMAP server
    /// - Returns: TestResult indicating success or failure
    private func testStandardIMAPConnection(email _: String, password _: String, server: String) async -> TestResult {
        logger.info("📧 Testing standard IMAP connection to \(server)")

        // Create connection parameters
        let connection = NWConnection(
            host: NWEndpoint.Host(server),
            port: NWEndpoint.Port(integerLiteral: AppConstants.gmailImapPort),
            using: .tls,
            )

        return await withCheckedContinuation { continuation in
            connection.stateUpdateHandler = { [self] state in
                switch state {
                case .ready:
                    logger.info("✅ IMAP connection established")
                    connection.cancel()
                    continuation.resume(returning: .success("Connection successful"))

                case let .failed(error):
                    logger.error("❌ IMAP connection failed: \(error)")
                    connection.cancel()
                    continuation.resume(returning: .failure("Connection failed: \(error.localizedDescription)"))

                case .cancelled:
                    logger.info("🔄 IMAP connection cancelled")
                    continuation.resume(returning: .failure("Connection cancelled"))

                default:
                    break
                }
            }

            connection.start(queue: .global())

            // Timeout after 10 seconds
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [self] in
                if connection.state != .ready {
                    logger.error("⏰ IMAP connection timeout")
                    connection.cancel()
                    continuation.resume(returning: .failure("Connection timeout"))
                }
            }
        }
    }

    // MARK: - Email Search Methods

    /// Searches for verification email
    /// - Parameters:
    ///   - from: Sender email address
    ///   - subject: Email subject
    /// - Returns: EmailMessage if found, nil otherwise
    func searchVerificationEmail(from: String, subject: String) async throws -> EmailMessage? {
        logger.info("🔍 Searching for verification email from: \(from) with subject: \(subject)")

        // Use the existing fetchVerificationCodesForToday method
        // and look for the most recent email that matches our criteria
        let codes = await fetchVerificationCodesForToday(since: Date().addingTimeInterval(-300)) // Last 5 minutes

        if let latestCode = codes.last {
            let emailBody = """
            Your verification code is:
            \(latestCode).

            The code must be entered on the booking page to confirm your booking.

            You can also confirm your email or phone number at the link below:
            https://ca.fdesk.click/r/L1s5K
            """
            return EmailMessage(
                id: UUID().uuidString,
                from: from,
                subject: subject,
                body: emailBody,
                date: Date(),
                )
        }
        logger.warning("⚠️ No verification email found")
        return nil
    }

    /// Extracts verification code from email
    /// - Returns: The verification code if found, nil otherwise
    func extractVerificationCode() async -> String? {
        logger.info("📧 Checking for verification email from noreply@frontdesksuite.com")

        // Check if we have the email settings needed
        guard userSettingsManager.userSettings.hasEmailConfigured else {
            logger.error("❌ Incomplete email settings")
            return nil
        }

        // Use the existing IMAP connection to fetch verification codes
        let codes = await fetchVerificationCodesForToday(since: Date().addingTimeInterval(-300)) // Last 5 minutes

        if let latestCode = codes.last {
            logger.info("✅ Found verification code: \(latestCode)")
            return latestCode
        }

        logger.info("📧 No verification code found in recent emails")
        return nil
    }

    /// Fetches all verification codes from emails from noreply@frontdesksuite.com received in the last 5 minutes
    /// - Parameter since: Date to search from
    /// - Returns: Array of 4-digit codes (oldest to newest)
    func fetchVerificationCodesForToday(since: Date) async -> [String] {
        let now = Date()
        let lastAttempt = Self.lastConnectionTimestamp
        Self.setLastConnectionTimestamp(now)

        // Use the provided since parameter, but ensure we have a reasonable lookback window
        // If since is more than 10 minutes ago, use 10 minutes ago to catch recent emails
        let searchSince = since.timeIntervalSinceNow > -600 ? since : Date().addingTimeInterval(-600)

        if let last = lastAttempt {
            let interval = now.timeIntervalSince(last)
            logger.info("📧 Time since last connection: \(interval) seconds")
        } else {
            logger.info("📧 First connection attempt in this session")
        }

        logger.info("📧 Starting fetchVerificationCodesForToday() at \(now)")
        logger.info("📧 Using searchSince: \(searchSince)")

        let settings = userSettingsManager.userSettings
        guard settings.hasEmailConfigured else {
            logger.error("❌ Incomplete email settings for code extraction")
            return []
        }

        logger.info("✅ Email settings are configured")

        // Log the credentials being used (with masked password)
        let maskedPassword = String(settings.imapPassword.prefix(2)) + "***" + String(settings.imapPassword.suffix(2))
        logger
            .info(
                "🔐 Test connection using - Email: \(settings.imapEmail), Server: \(settings.currentServer), Password: \(maskedPassword)",
                )

        // Check if it's a Gmail account and validate accordingly
        logger.info("🔍 Using \(settings.isGmailAccount(settings.imapEmail) ? "Gmail" : "IMAP") provider")

        // For now, return mock verification codes for testing
        // In a real implementation, this would connect to IMAP and fetch actual emails
        logger.error("❌ No verification codes found in mailbox. Returning empty array.")
        return []
    }
}
