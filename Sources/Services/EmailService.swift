import Foundation
import Network
import os.log

/// Service for email/IMAP integration and testing
///
/// Handles IMAP connection testing and email validation
/// Provides test functionality for email settings
///
/// ## Gmail Support
///
/// For Gmail accounts, you must:
/// 1. Enable 2-factor authentication on your Google account
/// 2. Generate an "App Password" (not your regular password)
/// 3. Use `imap.gmail.com` as the server
/// 4. Use port 993 with SSL/TLS
///
/// ### Gmail App Password Setup:
/// 1. Go to Google Account settings → Security
/// 2. Enable 2-Step Verification if not already enabled
/// 3. Go to "App passwords" (under 2-Step Verification)
/// 4. Generate a new app password for "Mail"
/// 5. Use this 16-character password in ODYSSEY settings
@MainActor
class EmailService: ObservableObject {
    static let shared = EmailService()

    @Published var isTesting = false
    @Published var lastTestResult: TestResult?

    private let logger = Logger(subsystem: "com.odyssey.app", category: "EmailService")
    private let userSettingsManager = UserSettingsManager.shared

    enum IMAPError: Error {
        case connectionFailed(String)
        case authenticationFailed(String)
        case commandFailed(String)
        case invalidResponse(String)
        case timeout(String)
        case unsupportedServer(String)
        case gmailAppPasswordRequired(String)

        var localizedDescription: String {
            switch self {
            case let .connectionFailed(message): UserSettingsManager.shared.userSettings
                .localized("Connection failed:") + " \(message)"
            case let .authenticationFailed(message): UserSettingsManager.shared.userSettings
                .localized("Authentication failed:") + " \(message)"
            case let .commandFailed(message): UserSettingsManager.shared.userSettings
                .localized("Command failed:") + " \(message)"
            case let .invalidResponse(message): UserSettingsManager.shared.userSettings
                .localized("Invalid response:") + " \(message)"
            case let .timeout(message): UserSettingsManager.shared.userSettings
                .localized("Connection timeout:") + " \(message)"
            case let .unsupportedServer(message): UserSettingsManager.shared.userSettings
                .localized("Unsupported server:") + " \(message)"
            case let .gmailAppPasswordRequired(message): UserSettingsManager.shared.userSettings
                .localized("Gmail App Password required:") + " \(message)"
            }
        }
    }

    enum TestResult {
        case success(String)
        case failure(String, provider: EmailProvider = .imap)

        var description: String {
            switch self {
            case let .success(message):
                return message
            case let .failure(error, provider):
                let prefix = provider == .gmail ?
                    UserSettingsManager.shared.userSettings.localized("Gmail test failed:") :
                    UserSettingsManager.shared.userSettings.localized("IMAP test failed:")
                return prefix + " \(error)"
            }
        }

        var isSuccess: Bool {
            switch self {
            case .success: true
            case .failure: false
            }
        }
    }

    enum EmailProvider {
        case imap
        case gmail
    }

    private init() { }

    // MARK: - Gmail Support

    /// Checks if the email settings are for a Gmail account
    /// - Parameter email: The email address to check
    /// - Returns: True if this is a Gmail account
    private func isGmailAccount(_ email: String) -> Bool {
        let domain = email.components(separatedBy: "@").last?.lowercased() ?? ""
        return domain == "gmail.com" || domain.hasSuffix(".gmail.com")
    }

    /// Validates Gmail-specific requirements
    /// - Parameters:
    ///   - email: The email address
    ///   - password: The password (should be an app password for Gmail)
    ///   - server: The IMAP server
    /// - Returns: Validation result
    private func validateGmailSettings(email: String, password: String, server: String) -> Result<Void, IMAPError> {
        guard isGmailAccount(email) else { return .success(()) }

        // Check if server is correct for Gmail
        if server.lowercased() != "imap.gmail.com" {
            return .failure(.gmailAppPasswordRequired("Gmail accounts must use 'imap.gmail.com' as the server"))
        }

        // Validate Gmail app password format: 16 characters in format "xxxx xxxx xxxx xxxx"
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if password matches the expected format: 4 groups of 4 characters separated by spaces
        let appPasswordPattern = "^[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}$"
        let appPasswordRegex = try? NSRegularExpression(pattern: appPasswordPattern)

        if let regex = appPasswordRegex {
            let range = NSRange(trimmedPassword.startIndex..., in: trimmedPassword)
            if regex.firstMatch(in: trimmedPassword, range: range) == nil {
                return .failure(
                    .gmailAppPasswordRequired(
                        "Gmail App Password must be in format: 'xxxx xxxx xxxx xxxx' (16 lowercase letters with spaces every 4 characters).",
                    ),
                )
            }
        } else {
            // Fallback validation if regex fails
            let cleanedPassword = trimmedPassword.replacingOccurrences(of: " ", with: "")
            if cleanedPassword.count != 16 || !cleanedPassword.allSatisfy({ $0.isLetter && $0.isLowercase }) {
                return .failure(
                    .gmailAppPasswordRequired(
                        "Gmail App Password must be 16 lowercase letters in format: 'xxxx xxxx xxxx xxxx'.",
                    ),
                )
            }
        }

        return .success(())
    }

    // MARK: - Public Methods

    /// Extracts verification code from email
    /// - Returns: The verification code if found, nil otherwise
    func extractVerificationCode() async -> String? {
        let settings = userSettingsManager.userSettings

        logger.info("Checking for verification email from noreply@frontdesksuite.com")

        // For now, we'll use a simple approach to check for the verification email
        // In a full implementation, this would connect to IMAP and search for the email

        // Check if we have the email settings needed
        guard
            !settings.imapEmail.isEmpty,
            !settings.imapPassword.isEmpty,
            !settings.imapServer.isEmpty
        else {
            logger.error("Incomplete email settings")
            return nil
        }

        // TODO: Implement actual IMAP connection to check for verification email
        // For now, return nil to indicate no verification code found
        // This will be implemented when we add full IMAP email checking functionality

        logger.warning("Email verification code extraction not yet implemented")
        return nil
    }

    /// Fetches all verification codes from emails from noreply@frontdesksuite.com received in the last 5 minutes
    /// - Returns: Array of 4-digit codes (oldest to newest)
    func fetchVerificationCodesForToday() async -> [String] {
        logger.info("📧 EmailService: Starting fetchVerificationCodesForToday()")

        let settings = userSettingsManager.userSettings
        guard settings.hasEmailConfigured else {
            logger.error("❌ EmailService: Incomplete email settings for code extraction")
            return []
        }

        logger.info("✅ EmailService: Email settings are configured")

        // Check if it's a Gmail account and validate accordingly
        let isGmail = settings.isGmailAccount(settings.imapEmail)
        logger.info("📧 EmailService: Is Gmail account: \(isGmail)")

        if isGmail {
            let gmailValidation = validateGmailSettings(
                email: settings.imapEmail,
                password: settings.imapPassword,
                server: settings.currentServer,
            )
            if case let .failure(error) = gmailValidation {
                logger.error("❌ EmailService: Gmail validation failed: \(error.localizedDescription)")
                return []
            }
            logger.info("✅ EmailService: Gmail validation passed")
        }

        // Use the unified approach for both Gmail and IMAP
        let result = await testIMAPConnection(
            email: settings.currentEmail,
            password: settings.currentPassword,
            server: settings.currentServer,
            isGmail: isGmail,
            provider: isGmail ? .gmail : .imap,
        )

        switch result {
        case let .success(message):
            logger.info("✅ EmailService: IMAP connection successful: \(message)")
        case let .failure(error, provider):
            logger.error("❌ EmailService: \(provider == .gmail ? "Gmail" : "IMAP") connection failed: \(error)")
            return []
        }

        // Now fetch the actual verification codes
        logger.info("🔍 EmailService: Fetching verification codes from emails...")
        let codes = await fetchVerificationCodesFromEmails()
        logger.info("📋 EmailService: Found \(codes.count) verification codes: \(codes)")

        return codes
    }

    func testGmailConnection(email: String, appPassword: String) async -> TestResult {
        return await testIMAPConnection(
            email: email,
            password: appPassword,
            server: "imap.gmail.com",
            isGmail: true,
            provider: .gmail,
        )
    }

    func testIMAPConnection(
        email: String,
        password: String,
        server: String,
        isGmail: Bool = false,
        provider: EmailProvider = .imap,
    ) async -> TestResult {
        isTesting = true
        defer { isTesting = false }
        guard !email.isEmpty else {
            return .failure(userSettingsManager.userSettings.localized("Email address is empty"), provider: provider)
        }
        guard !password.isEmpty else {
            return .failure(userSettingsManager.userSettings.localized("Password is empty"), provider: provider)
        }
        guard !server.isEmpty else {
            return .failure(userSettingsManager.userSettings.localized("IMAP server is empty"), provider: provider)
        }

        // Validate Gmail settings if applicable
        let gmailValidation = validateGmailSettings(email: email, password: password, server: server)
        if case let .failure(error) = gmailValidation {
            return .failure(error.localizedDescription, provider: provider)
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            return .failure(userSettingsManager.userSettings.localized("Invalid email format"), provider: provider)
        }

        // For Gmail, only try port 993 with SSL/TLS
        let portConfigurations: [(port: UInt16, useTLS: Bool, description: String)] = if server == "imap.gmail.com" {
            [
                (port: UInt16(993), useTLS: true, description: "SSL/TLS (Gmail)"),
            ]
        } else {
            [
                (port: UInt16(993), useTLS: true, description: "SSL/TLS"),
                (port: UInt16(143), useTLS: false, description: "Plain"),
                (port: UInt16(143), useTLS: true, description: "STARTTLS"),
            ]
        }

        for config in portConfigurations {
            logger.info("Trying IMAP connection to \(server):\(config.port) (\(config.description))")
            let result = await connectToIMAP(
                server: server,
                port: config.port,
                useTLS: config.useTLS,
                email: email,
                password: password,
                isGmail: isGmail,
                provider: provider,
            )
            if case .success = result { return result }
            if case let .failure(error, _) = result {
                logger.warning("IMAP connection failed on \(server):\(config.port): \(error)")
            }
        }
        return .failure(
            userSettingsManager.userSettings.localized("All IMAP connection attempts failed"),
            provider: provider,
        )
    }

    private func connectToIMAP(
        server: String,
        port: UInt16,
        useTLS: Bool,
        email: String,
        password: String,
        isGmail: Bool = false,
        provider: EmailProvider = .imap,
    ) async -> TestResult {
        let parameters = NWParameters.tcp
        if useTLS {
            parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolTLS.Options(), at: 0)
        }
        let connection = NWConnection(
            host: NWEndpoint.Host(server),
            port: NWEndpoint.Port(integerLiteral: port),
            using: parameters,
        )
        return await withCheckedContinuation { continuation in
            let hasResumed = AtomicBool(false)
            @Sendable func safeResume(_ result: TestResult) {
                if hasResumed.testAndSet() {
                    Task { @MainActor in
                        self.isTesting = false
                        self.lastTestResult = result
                        continuation.resume(returning: result)
                    }
                }
            }
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                safeResume(.failure(
                    IMAPError.timeout("Connection timed out after 30 seconds").localizedDescription,
                    provider: provider,
                ))
            }
            connection.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    let isGmailCopy = isGmail
                    Task {
                        await self.performIMAPHandshake(
                            connection: connection,
                            email: email,
                            password: password,
                            useTLS: useTLS,
                            isGmail: isGmailCopy,
                            provider: provider,
                        ) { result in
                            timeoutTask.cancel()
                            safeResume(result)
                            connection.cancel()
                        }
                    }
                case let .failed(error):
                    timeoutTask.cancel()
                    safeResume(.failure(
                        IMAPError.connectionFailed(error.localizedDescription).localizedDescription,
                        provider: provider,
                    ))
                    connection.cancel()
                case .cancelled:
                    timeoutTask.cancel()
                    safeResume(.failure(
                        IMAPError.connectionFailed("Connection cancelled").localizedDescription,
                        provider: provider,
                    ))
                case let .waiting(error):
                    logger.warning("IMAP connection waiting: \(error)")
                default:
                    break
                }
            }
            connection.start(queue: .global())
        }
    }

    private func performIMAPHandshake(
        connection: NWConnection,
        email: String,
        password: String,
        useTLS: Bool,
        isGmail: Bool,
        provider: EmailProvider,
        completion: @escaping (TestResult) -> Void,
    ) async {
        receiveIMAPResponse(connection: connection) { [weak self] (result: Result<String, IMAPError>) in
            guard let self else { return }
            switch result {
            case let .success(greeting):
                logger.info("IMAP greeting received: \(greeting.prefix(100))")
                if !useTLS, greeting.contains("STARTTLS") {
                    let isGmailCopy = isGmail
                    Task {
                        await self
                            .upgradeToTLS(
                                connection: connection,
                                isGmail: isGmailCopy,
                                provider: provider,
                            ) { tlsResult in
                                switch tlsResult {
                                case .success:
                                    let isGmailCopy2 = isGmailCopy
                                    Task { await self.continueIMAPHandshake(
                                        connection: connection,
                                        email: email,
                                        password: password,
                                        isGmail: isGmailCopy2,
                                        provider: provider,
                                        completion: completion,
                                    )
                                    }
                                case let .failure(error):
                                    completion(.failure(error.localizedDescription, provider: provider))
                                }
                            }
                    }
                } else {
                    let isGmailCopy = isGmail
                    Task { await self.continueIMAPHandshake(
                        connection: connection,
                        email: email,
                        password: password,
                        isGmail: isGmailCopy,
                        provider: provider,
                        completion: completion,
                    )
                    }
                }
            case let .failure(error):
                completion(.failure(error.localizedDescription, provider: provider))
            }
        }
    }

    private func continueIMAPHandshake(
        connection: NWConnection,
        email: String,
        password: String,
        isGmail: Bool,
        provider: EmailProvider,
        completion: @escaping (TestResult) -> Void,
    ) async {
        await sendIMAPCommand(
            connection: connection,
            command: "a001 CAPABILITY\r\n",
        ) { [weak self] (result: Result<String, IMAPError>) in
            guard let self else { return }
            let isGmailCopy = isGmail
            switch result {
            case .success:
                let loginCommand = "a002 LOGIN \"\(email)\" \"\(password)\"\r\n"
                Task {
                    await self
                        .sendIMAPCommand(connection: connection, command: loginCommand) { [weak self] (result: Result<
                            String,
                            IMAPError
                        >) in
                            guard let self else { return }
                            switch result {
                            case .success:
                                let selectCommand = "a003 SELECT INBOX\r\n"
                                Task {
                                    let isGmailCopy2 = isGmailCopy
                                    await self
                                        .sendIMAPCommand(
                                            connection: connection,
                                            command: selectCommand,
                                        ) { [weak self] (result: Result<
                                            String,
                                            IMAPError
                                        >) in
                                            guard let self else { return }
                                            switch result {
                                            case .success:
                                                let searchCommand = "a004 SEARCH ALL\r\n"
                                                Task {
                                                    let isGmailCopy3 = isGmailCopy2
                                                    await self
                                                        .sendIMAPCommand(
                                                            connection: connection,
                                                            command: searchCommand,
                                                        ) { [weak self] (result: Result<
                                                            String,
                                                            IMAPError
                                                        >) in
                                                            guard let self else { return }
                                                            switch result {
                                                            case let .success(searchResponse):
                                                                let lines = searchResponse
                                                                    .components(separatedBy: .newlines)
                                                                let searchLine = lines
                                                                    .first(where: { $0.contains("SEARCH") }) ?? ""
                                                                let parts = searchLine.components(separatedBy: " ")
                                                                let ids = parts.dropFirst().compactMap { Int($0) }
                                                                if let lastId = ids.last {
                                                                    let fetchCommand =
                                                                        "a005 FETCH \(lastId) BODY[HEADER.FIELDS (FROM SUBJECT DATE)]\r\n"
                                                                    Task {
                                                                        let isGmailCopy4 = isGmailCopy3
                                                                        await self.sendIMAPCommand(
                                                                            connection: connection,
                                                                            command: fetchCommand,
                                                                        ) { (result: Result<String, IMAPError>) in
                                                                            switch result {
                                                                            case let .success(fetchResponse):
                                                                                let subject = self
                                                                                    .parseEmailSubject(
                                                                                        from: fetchResponse,
                                                                                    )
                                                                                let baseMessage = isGmailCopy4 ?
                                                                                    "Gmail connection successful!" :
                                                                                    "IMAP connection successful!"
                                                                                let fullMessage = subject.isEmpty ?
                                                                                    baseMessage :
                                                                                    "\(baseMessage) Latest email: \(subject)"
                                                                                completion(.success(
                                                                                    self.userSettingsManager
                                                                                        .userSettings
                                                                                        .localized(fullMessage),
                                                                                ))
                                                                            case let .failure(error):
                                                                                self.logger
                                                                                    .error(
                                                                                        "IMAP: FETCH failed: \(error.localizedDescription)",
                                                                                    )
                                                                                completion(.failure(
                                                                                    self.userSettingsManager
                                                                                        .userSettings
                                                                                        .localized(
                                                                                            "Failed to fetch email:",
                                                                                        ) +
                                                                                        " \(error.localizedDescription)",
                                                                                    provider: provider,
                                                                                ))
                                                                            }
                                                                        }
                                                                    }
                                                                } else {
                                                                    completion(.success(
                                                                        userSettingsManager.userSettings
                                                                            .localized(
                                                                                isGmailCopy3 ?
                                                                                    "Gmail connection successful!" :
                                                                                    "IMAP connection successful!",
                                                                            ),
                                                                    ))
                                                                }
                                                            case let .failure(error):
                                                                completion(.failure(
                                                                    userSettingsManager.userSettings
                                                                        .localized("Failed to search mailbox:") +
                                                                        " \(error.localizedDescription)",
                                                                    provider: provider,
                                                                ))
                                                            }
                                                        }
                                                }
                                            case let .failure(error):
                                                completion(.failure(
                                                    userSettingsManager.userSettings
                                                        .localized("Failed to select INBOX:") +
                                                        " \(error.localizedDescription)",
                                                    provider: provider,
                                                ))
                                            }
                                        }
                                }
                            case let .failure(error):
                                completion(.failure(
                                    userSettingsManager.userSettings
                                        .localized("Authentication failed:") + " \(error.localizedDescription)",
                                    provider: provider,
                                ))
                            }
                        }
                }
            case let .failure(error):
                completion(.failure(
                    userSettingsManager.userSettings
                        .localized("IMAP handshake failed:") + " \(error.localizedDescription)",
                    provider: provider,
                ))
            }
        }
    }

    private func upgradeToTLS(
        connection: NWConnection,
        isGmail _: Bool,
        provider _: EmailProvider,
        completion: @escaping (Result<Void, IMAPError>) -> Void,
    ) async {
        await sendIMAPCommand(
            connection: connection,
            command: "a001 STARTTLS\r\n",
        ) { (result: Result<String, IMAPError>) in
            switch result {
            case .success:
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    completion(.success(()))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func sendIMAPCommand(
        connection: NWConnection,
        command: String,
        completion: @escaping (Result<String, IMAPError>) -> Void,
    ) async {
        guard let data = command.data(using: .utf8) else {
            completion(.failure(.commandFailed(userSettingsManager.userSettings.localized("Invalid command encoding"))))
            return
        }
        let localizedSendError = userSettingsManager.userSettings.localized("Send error:")
        connection.send(content: data, completion: .contentProcessed { error in
            if let error {
                completion(.failure(.commandFailed(localizedSendError + " \(error.localizedDescription)")))
                return
            }
            Task { @MainActor in
                self.receiveIMAPResponse(connection: connection, completion: completion)
            }
        })
    }

    private func receiveIMAPResponse(
        connection: NWConnection,
        completion: @escaping (Result<String, IMAPError>) -> Void,
    ) {
        let localizedReceiveError = userSettingsManager.userSettings.localized("Receive error:")
        let localizedIMAPError = userSettingsManager.userSettings.localized("IMAP error:")
        let localizedInvalidResponse = userSettingsManager.userSettings.localized("Invalid response")

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { content, _, _, error in
            if let error {
                completion(.failure(.commandFailed(localizedReceiveError + " \(error.localizedDescription)")))
                return
            }
            if let data = content, let response = String(data: data, encoding: .utf8) {
                if response.contains("OK") {
                    completion(.success(response))
                } else if response.contains("NO") || response.contains("BAD") {
                    completion(.failure(.commandFailed(localizedIMAPError + " \(response)")))
                } else {
                    completion(.success(response))
                }
            } else {
                completion(.failure(.invalidResponse(localizedInvalidResponse)))
            }
        }
    }

    private func parseEmailSubject(from response: String) -> String {
        let lines = response.components(separatedBy: .newlines)
        for line in lines {
            if line.lowercased().hasPrefix("subject:") {
                let subject = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
                    .last?
                    .trimmingCharacters(in: .whitespaces) ?? ""
                return subject.isEmpty ? "No subject" : subject
            }
        }
        return "No subject"
    }

    private func parseEmailHeaders(_ response: String) -> String {
        let lines = response.components(separatedBy: .newlines)
        var from = userSettingsManager.userSettings.localized("Unknown")
        var subject = userSettingsManager.userSettings.localized("No Subject")
        var date = userSettingsManager.userSettings.localized("Unknown Date")
        for line in lines {
            if line.hasPrefix("From:") {
                from = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Subject:") {
                subject = String(line.dropFirst(9)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Date:") {
                date = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            }
        }
        return "\(userSettingsManager.userSettings.localized("From:")) \(from) - \(userSettingsManager.userSettings.localized("Subject:")) \(subject) - \(userSettingsManager.userSettings.localized("Date:")) \(date)"
    }

    /// Extracts the email body from IMAP FETCH response
    /// - Parameter response: The IMAP FETCH response
    /// - Returns: The email body content
    private func extractBodyFromResponse(_ response: String) async -> String {
        // IMAP FETCH response format: * <id> FETCH (BODY[TEXT] {<size>}\r\n<content>\r\n)
        // We need to find the content after the size declaration and before the closing parenthesis

        // Look for the pattern: BODY[TEXT] {<size>}
        if let sizePattern = response.range(of: "BODY\\[TEXT\\] \\{[0-9]+\\}", options: .regularExpression) {
            // Find the end of the size pattern
            let sizeEnd = sizePattern.upperBound

            // Look for the first \r\n after the size pattern
            if let bodyStart = response.range(of: "\r\n", range: sizeEnd ..< response.endIndex) {
                let contentStart = bodyStart.upperBound

                // Look for the closing parenthesis
                if let bodyEnd = response.range(of: ")", range: contentStart ..< response.endIndex) {
                    return String(response[contentStart ..< bodyEnd.lowerBound])
                }
            }
        }

        // Fallback: try to find content between \r\n sequences
        let lines = response.components(separatedBy: "\r\n")
        if lines.count >= 2 {
            // Skip the first line (FETCH response header) and return the content
            return lines.dropFirst().joined(separator: "\r\n")
        }

        return response
    }

    /// Extracts verification codes from email body using regex
    /// - Parameter body: The email body content
    /// - Returns: Array of 4-digit verification codes found
    private func extractVerificationCodes(from body: String) async -> [String] {
        var codes: [String] = []

        // Try multiple patterns to catch different formats
        let patterns = [
            "\\b\\d{4}\\b", // Basic 4-digit pattern
            "verification code is:\\s*(\\d{4})", // "Your verification code is: 3583"
            "code is:\\s*(\\d{4})", // "code is: 3583"
            "code:\\s*(\\d{4})", // "code: 3583"
        ]

        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex?.matches(in: body, range: NSRange(body.startIndex..., in: body)) ?? []

            for match in matches {
                if let range = Range(match.range, in: body) {
                    let matchText = String(body[range])

                    // Extract just the 4-digit code
                    let codeRegex = try? NSRegularExpression(pattern: "\\d{4}")
                    if
                        let codeMatch = codeRegex?.firstMatch(
                            in: matchText,
                            range: NSRange(matchText.startIndex..., in: matchText),
                        ),
                        let codeRange = Range(codeMatch.range, in: matchText)
                    {
                        let code = String(matchText[codeRange])
                        if !codes.contains(code) {
                            codes.append(code)
                            logger.info("🔢 Found verification code: \(code) using pattern: \(pattern)")
                        }
                    }
                }
            }
        }

        return codes
    }

    /// Fetches verification codes from emails using IMAP
    /// - Returns: Array of verification codes found
    private func fetchVerificationCodesFromEmails() async -> [String] {
        // Remove timeout wrapper to allow IMAP operation to complete
        return await { [self] in
            let settings = self.userSettingsManager.userSettings
            let port: UInt16 = 993
            let server = settings.currentServer
            let email = settings.currentEmail
            let password = settings.currentPassword
            let fromAddress = "noreply@frontdesksuite.com"

            // Debug logging for password selection
            logger.info("🔐 Password debug - Email: \(email)")
            logger.info("🔐 Password debug - Is Gmail: \(settings.isGmailAccount(email))")
            logger.info("🔐 Password debug - Using password: \(password.prefix(4))...")

            // Additional Gmail App Password validation
            if settings.isGmailAccount(email) {
                let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
                logger.info("🔐 Gmail App Password validation:")
                logger.info("🔐 - Password length: \(trimmedPassword.count)")
                logger.info("🔐 - Contains spaces: \(trimmedPassword.contains(" "))")
                logger.info("🔐 - All lowercase: \(trimmedPassword.allSatisfy { $0.isLetter ? $0.isLowercase : true })")
                logger.info("🔐 - Password format: \(trimmedPassword)")

                // Check if it matches the expected Gmail App Password format
                let appPasswordPattern = "^[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}$"
                let appPasswordRegex = try? NSRegularExpression(pattern: appPasswordPattern)
                if let regex = appPasswordRegex {
                    let range = NSRange(trimmedPassword.startIndex..., in: trimmedPassword)
                    let matches = regex.firstMatch(in: trimmedPassword, range: range)
                    logger.info("🔐 - Matches Gmail App Password format: \(matches != nil)")
                }
            }
            // Make subject search more flexible to catch variations
            let subject = "Verify your email"
            let now = Date()
            // Search for emails from the last 15 minutes to catch recent verification emails
            let fifteenMinutesAgo = now.addingTimeInterval(-15 * 60)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d-MMM-yyyy"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            let sinceDate = dateFormatter.string(from: fifteenMinutesAgo)

            // Log the current date, sinceDate, and timezone for debugging
            logger.info("🕒 System time: \(Date()) (timezone: \(TimeZone.current.identifier))")
            logger.info("🔍 IMAP search window sinceDate: \(sinceDate)")

            logger.info("🔗 Connecting to IMAP server \(server):\(port) for user \(email)")

            var inputStream: InputStream?
            var outputStream: OutputStream?

            // For port 993, we need SSL/TLS
            Stream.getStreamsToHost(
                withName: server,
                port: Int(port),
                inputStream: &inputStream,
                outputStream: &outputStream,
            )
            if port == 993 {
                inputStream?.setProperty(StreamSocketSecurityLevel.tlSv1, forKey: .socketSecurityLevelKey)
                outputStream?.setProperty(StreamSocketSecurityLevel.tlSv1, forKey: .socketSecurityLevelKey)
            }

            guard let inputStream, let outputStream else {
                logger.error("❌ Failed to open IMAP streams")
                return []
            }

            // Set up stream delegates for better error handling
            let streamDelegate = IMAPStreamDelegate()
            inputStream.delegate = streamDelegate
            outputStream.delegate = streamDelegate

            inputStream.open()
            outputStream.open()

            // Wait for streams to open
            let startTime = Date()
            while
                (inputStream.streamStatus != .open || outputStream.streamStatus != .open) &&
                Date().timeIntervalSince(startTime) < 10
            {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }

            if inputStream.streamStatus != .open || outputStream.streamStatus != .open {
                logger
                    .error(
                        "❌ Failed to open IMAP streams - status: input=\(inputStream.streamStatus.rawValue), output=\(outputStream.streamStatus.rawValue)",
                    )
                return []
            }

            logger.info("✅ IMAP streams opened successfully")

            defer {
                inputStream.close()
                outputStream.close()
            }

            func sendCommand(_ cmd: String) {
                let data = Array((cmd + "\r\n").utf8)
                _ = data.withUnsafeBytes { outputStream.write(
                    $0.bindMemory(to: UInt8.self).baseAddress!,
                    maxLength: data.count,
                ) }
            }

            func expect(_ tag: String) async -> String {
                var buffer = [UInt8](repeating: 0, count: 4_096)
                var response = ""
                let startTime = Date()
                let timeout: TimeInterval = 10 // 10 second timeout

                while Date().timeIntervalSince(startTime) < timeout {
                    // Check if we have bytes available
                    if inputStream.hasBytesAvailable {
                        let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
                        if bytesRead > 0 {
                            if let part = String(bytes: buffer[0 ..< bytesRead], encoding: .utf8) {
                                response += part
                                logger.debug("📨 IMAP response chunk: \(part.prefix(100))")
                            }
                        } else if bytesRead == 0 {
                            // End of stream
                            break
                        }
                    }

                    // Check if we have a complete response
                    if
                        response.contains("\(tag) OK") || response.contains("\(tag) BAD") || response
                            .contains("\(tag) NO")
                    {
                        logger.debug("✅ IMAP response complete for tag \(tag)")
                        return response
                    }

                    // Small delay to avoid busy waiting
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }

                logger.warning("⏰ IMAP expect timeout for tag \(tag) after \(timeout) seconds")
                return response
            }

            // Read greeting
            let greeting = await expect("*")
            logger.info("📨 IMAP greeting: \(greeting.prefix(200))")
            logger.error("📨 IMAP greeting (raw): \(String(describing: greeting))")

            // For Gmail, try CAPABILITY first to see what's supported
            if settings.isGmailAccount(email) {
                logger.info("🔍 Checking Gmail IMAP capabilities...")
                sendCommand("a0 CAPABILITY")
                let capabilityResp = await expect("a0")
                logger.info("🔍 Gmail capabilities: \(capabilityResp.prefix(200))")
            }

            // LOGIN
            logger.info("🔐 Attempting IMAP login...")
            sendCommand("a1 LOGIN \"\(email)\" \"\(password)\"")
            let loginResp = await expect("a1")

            // Log the full login response for debugging (without privacy protection)
            logger.error("🔐 Full IMAP login response (raw): \(String(describing: loginResp))")

            guard loginResp.contains("a1 OK") else {
                logger.error("❌ IMAP login failed: \(String(describing: loginResp))")
                // Log each line of the response separately to see the full error
                let lines = loginResp.components(separatedBy: "\n")
                for (index, line) in lines.enumerated() {
                    logger.error("🔐 Login response line \(index) (raw): \(String(describing: line))")
                }

                // Also log the raw response without privacy protection
                logger.error("🔐 Raw login response: \(String(describing: loginResp))")

                // Try to extract the actual error message by looking for patterns
                if loginResp.contains("NO") {
                    logger.error("🔐 IMAP NO response detected - authentication failed")
                }
                if loginResp.contains("BAD") {
                    logger.error("🔐 IMAP BAD response detected - command syntax error")
                }

                // Log the response length and character codes to help debug
                logger.error("🔐 Response length: \(loginResp.count)")
                // logger.error("🔐 Response contains 'OK': \(loginResp.contains(\"OK\"))")
                // logger.error("🔐 Response contains 'NO': \(loginResp.contains(\"NO\"))")
                // logger.error("🔐 Response contains 'BAD': \(loginResp.contains(\"BAD\"))")

                // Log the response as hex to see exactly what we're getting
                let hexString = loginResp.data(using: .utf8)?.map { String(format: "%02x", $0) }.joined() ?? "nil"
                logger.error("🔐 Response as hex: \(hexString.prefix(100))")
                return []
            }
            logger.info("✅ IMAP login successful, about to search for verification emails")

            // Note: Debug logging removed for production

            // Try multiple search strategies to find verification emails
            var ids: [Int] = []

            // Strategy 1: Search by FROM only (last 30 minutes - extended window)
            logger.info("🔍 Strategy 1: Searching by FROM only (last 30 minutes)")
            let thirtyMinutesAgo = now.addingTimeInterval(-30 * 60)
            let sinceDate30Min = dateFormatter.string(from: thirtyMinutesAgo)
            let searchCmd1 = "a3 SEARCH SINCE \(sinceDate30Min) FROM \"\(fromAddress)\""
            logger.info("🔍 Strategy 1 command: \(searchCmd1)")
            sendCommand(searchCmd1)
            let searchResp1 = await expect("a3")
            logger.info("🔍 Strategy 1 response: \(searchResp1.prefix(500))")
            let searchLines1 = searchResp1.components(separatedBy: "\n")
            let searchLine1 = searchLines1.first(where: { $0.contains("SEARCH") }) ?? ""
            let ids1 = searchLine1.components(separatedBy: " ").dropFirst()
                .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            ids.append(contentsOf: ids1)

            // Strategy 2: Search by FROM and SUBJECT (exact match, last 30 minutes)
            if ids.isEmpty {
                logger.info("🔍 Strategy 2: Searching by FROM and SUBJECT (exact, last 30 minutes)")
                let searchCmd2 = "a4 SEARCH SINCE \(sinceDate30Min) FROM \"\(fromAddress)\" SUBJECT \"\(subject)\""
                logger.info("🔍 Strategy 2 command: \(searchCmd2)")
                sendCommand(searchCmd2)
                let searchResp2 = await expect("a4")
                logger.info("🔍 Strategy 2 response: \(searchResp2.prefix(500))")
                let searchLines2 = searchResp2.components(separatedBy: "\n")
                let searchLine2 = searchLines2.first(where: { $0.contains("SEARCH") }) ?? ""
                let ids2 = searchLine2.components(separatedBy: " ").dropFirst()
                    .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                ids.append(contentsOf: ids2)
            }

            // Strategy 3: Search for any email with "verification" in subject (broader, last 30 minutes)
            if ids.isEmpty {
                logger.info("🔍 Strategy 3: Searching for any email with 'verification' in subject (last 30 minutes)")
                sendCommand("a5 SEARCH SINCE \(sinceDate30Min) SUBJECT \"verification\"")
                let searchResp3 = await expect("a5")
                logger.info("🔍 Strategy 3 response: \(searchResp3.prefix(500))")
                let searchLines3 = searchResp3.components(separatedBy: "\n")
                let searchLine3 = searchLines3.first(where: { $0.contains("SEARCH") }) ?? ""
                let ids3 = searchLine3.components(separatedBy: " ").dropFirst()
                    .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                ids.append(contentsOf: ids3)
            }

            // Strategy 4: Search in INBOX explicitly (some servers need this)
            if ids.isEmpty {
                logger.info("🔍 Strategy 4: Searching in INBOX explicitly (last 30 minutes)")
                sendCommand("a6 SELECT INBOX")
                let selectResp = await expect("a6")
                logger.info("🔍 INBOX select response: \(selectResp.prefix(200))")

                let searchCmd4 = "a7 SEARCH SINCE \(sinceDate30Min) FROM \"\(fromAddress)\""
                logger.info("🔍 Strategy 4 command: \(searchCmd4)")
                sendCommand(searchCmd4)
                let searchResp4 = await expect("a7")
                logger.info("🔍 Strategy 4 response: \(searchResp4.prefix(500))")
                let searchLines4 = searchResp4.components(separatedBy: "\n")
                let searchLine4 = searchLines4.first(where: { $0.contains("SEARCH") }) ?? ""
                let ids4 = searchLine4.components(separatedBy: " ").dropFirst()
                    .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                ids.append(contentsOf: ids4)
            }

            // After all search strategies, if no IDs found, log all recent emails for debugging
            if ids.isEmpty {
                logger
                    .warning(
                        "⚠️ No email IDs found in any search strategy. Listing all emails from last 30 minutes for debug...",
                    )
                // Search for all emails from the last 30 minutes
                let thirtyMinutesAgo = now.addingTimeInterval(-30 * 60)
                let sinceDate30Min = dateFormatter.string(from: thirtyMinutesAgo)
                sendCommand("a8 SEARCH SINCE \(sinceDate30Min)")
                let searchRespAll = await expect("a8")
                logger.info("🔍 All email search response: \(searchRespAll.prefix(500))")
                let searchLinesAll = searchRespAll.components(separatedBy: "\n")
                let searchLineAll = searchLinesAll.first(where: { $0.contains("SEARCH") }) ?? ""
                let idsAll = searchLineAll.components(separatedBy: " ").dropFirst()
                    .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                logger.info("🔍 All email IDs in last 30 minutes: \(idsAll)")
                // For each email, fetch and log subject and sender
                for id in idsAll {
                    sendCommand("a9 FETCH \(id) (BODY[HEADER.FIELDS (SUBJECT FROM DATE)])")
                    let headerResp = await expect("a9")
                    logger.info("📧 Email ID \(id) header: \n\(headerResp)")
                }
            }

            // Remove duplicates
            ids = Array(Set(ids)).sorted()
            logger.info("🔍 Combined search found IDs: \(ids)")

            if ids.isEmpty {
                logger.warning("⚠️ No email IDs found in any search strategy")
                return []
            }

            // Process each email
            var codes: [String] = []
            let headerDateFormatter = DateFormatter()
            headerDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            headerDateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z" // IMAP RFC822

            // Alternative date formatter for different IMAP server formats
            let altDateFormatter = DateFormatter()
            altDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            altDateFormatter.dateFormat = "d MMM yyyy HH:mm:ss Z"

            for id in ids {
                logger.info("📄 Processing email ID \(id)")
                sendCommand("a4 FETCH \(id) BODY[HEADER.FIELDS (DATE FROM SUBJECT)]")
                let headerResp = await expect("a4")
                logger.info("📬 Email ID \(id) headers: \(headerResp.prefix(500))")

                // Parse Date: header
                let dateLine = headerResp.components(separatedBy: "\n")
                    .first(where: { $0.lowercased().hasPrefix("date:") })
                guard
                    let dateLine, let dateStr = dateLine.split(
                        separator: ":",
                        maxSplits: 1,
                        omittingEmptySubsequences: false,
                    ).last?.trimmingCharacters(in: .whitespacesAndNewlines)
                else {
                    logger.info("📅 Skipping email ID \(id): Could not find date header")
                    continue
                }

                // Try multiple date formats
                var emailDate: Date?
                emailDate = headerDateFormatter.date(from: dateStr)
                if emailDate == nil {
                    emailDate = altDateFormatter.date(from: dateStr)
                }

                guard let emailDate else {
                    logger.info("📅 Skipping email ID \(id): Could not parse date '\(dateStr)'")
                    continue
                }

                // Skip emails older than 30 minutes (matching search window)
                if emailDate < thirtyMinutesAgo {
                    logger.info("⏰ Skipping email ID \(id): Too old (\(emailDate))")
                    continue
                }

                logger.info("✅ Email ID \(id) is recent enough, fetching body...")

                // Fetch email body
                sendCommand("a5 FETCH \(id) BODY[TEXT]")
                let bodyResp = await expect("a5")
                let body = await extractBodyFromResponse(bodyResp)
                logger.info("📧 Email ID \(id) body (truncated): \(body.prefix(500))")

                // Extract verification codes
                let emailCodes = await extractVerificationCodes(from: body)
                logger.info("🔢 Email ID \(id) contains codes: \(emailCodes)")
                codes.append(contentsOf: emailCodes)
            }

            logger.info("📋 Found \(codes.count) verification codes: \(codes)")
            return codes
        }()
    }

    // MARK: - Notification Methods

    /// Sends a success notification email when a reservation is completed
    /// - Parameter config: The reservation configuration that was successfully executed
    func sendSuccessNotification(for config: ReservationConfig) async {
        guard userSettingsManager.userSettings.hasEmailConfigured else {
            logger.info("Email notifications are disabled")
            return
        }

        await MainActor.run {
            self.logger.info("Sending success notification email for \(config.name, privacy: .private)")
            // For now, just log the success
            // In a full implementation, this would send an actual email
            let facilityName = ReservationConfig.extractFacilityName(from: config.facilityURL)
            self.logger
                .info(
                    "Success notification would be sent for \(config.name, privacy: .private) at \(facilityName, privacy: .private) to \(self.userSettingsManager.userSettings.imapEmail, privacy: .private)",
                )
        }
    }
}

final class AtomicBool {
    private let lock = NSLock()
    private var value: Bool
    init(_ value: Bool) { self.value = value }
    func testAndSet() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if value { return false }
        value = true
        return true
    }
}

/// Helper function to add timeout to async operations
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> T {
    await withTaskGroup(of: T.self) { group in
        group.addTask {
            await operation()
        }

        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            // Return a default value that indicates timeout
            // For arrays, return empty array
            if T.self == [String].self {
                return [] as! T
            }
            // For other types, we'd need to handle them specifically
            fatalError("Timeout not implemented for type \(T.self)")
        }

        for await result in group {
            return result
        }

        // This should never be reached
        fatalError("Unexpected timeout behavior")
    }
}

// MARK: - IMAPStreamDelegate

class IMAPStreamDelegate: NSObject, StreamDelegate {
    func stream(_: Stream, handle _: Stream.Event) {
        // No-op for now; can be expanded for error handling or logging
    }
}
