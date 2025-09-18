import Foundation
import Network
import os

/// Service for email/IMAP integration and testing
///
/// Handles IMAP connection testing and email validation
/// Provides test functionality for email settings
@MainActor
public final class EmailService: ObservableObject, @unchecked Sendable, EmailServiceProtocol {
  public static let shared = EmailService()

  @Published public var isTesting = false
  @Published public var lastTestResult: TestResult?
  @Published public var userFacingError: String?

  private let logger: Logger
  private let userSettingsManager: UserSettingsManager

  enum IMAPError: Error, UnifiedErrorProtocol {
    case connectionFailed(String)
    case authenticationFailed(String)
    case commandFailed(String)
    case invalidResponse(String)
    case timeout(String)
    case unsupportedServer(String)
    case gmailAppPasswordRequired(String)

    var localizedDescription: String {
      return userFriendlyMessage
    }

    /// Unique error code for categorization and debugging
    var errorCode: String {
      switch self {
      case .connectionFailed: return "IMAP_CONNECTION_001"
      case .authenticationFailed: return "IMAP_AUTH_001"
      case .commandFailed: return "IMAP_COMMAND_001"
      case .invalidResponse: return "IMAP_RESPONSE_001"
      case .timeout: return "IMAP_TIMEOUT_001"
      case .unsupportedServer: return "IMAP_SERVER_001"
      case .gmailAppPasswordRequired: return "IMAP_GMAIL_001"
      }
    }

    /// Category for grouping similar errors
    var errorCategory: ErrorCategory {
      switch self {
      case .connectionFailed, .timeout: return .network
      case .authenticationFailed, .gmailAppPasswordRequired: return .authentication
      case .commandFailed, .invalidResponse: return .system
      case .unsupportedServer: return .validation
      }
    }

    /// User-friendly error message for UI display
    var userFriendlyMessage: String {
      switch self {
      case .connectionFailed(let message):
        return "Connection failed: \(message)"
      case .authenticationFailed(let message):
        return "Authentication failed: \(message)"
      case .commandFailed(let message):
        return "Command failed: \(message)"
      case .invalidResponse(let message):
        return "Invalid response: \(message)"
      case .timeout(let message):
        return "Connection timeout: \(message)"
      case .unsupportedServer(let message):
        return "Unsupported server: \(message)"
      case .gmailAppPasswordRequired(let message):
        return "Gmail App Password required: \(message)"
      }
    }

    /// Technical details for debugging (optional)
    var technicalDetails: String? {
      switch self {
      case .connectionFailed(let message): return "IMAP connection establishment failed: \(message)"
      case .authenticationFailed(let message):
        return "IMAP authentication process failed: \(message)"
      case .commandFailed(let message): return "IMAP command execution failed: \(message)"
      case .invalidResponse(let message): return "IMAP server returned invalid response: \(message)"
      case .timeout(let message): return "IMAP operation exceeded timeout: \(message)"
      case .unsupportedServer(let message): return "IMAP server configuration issue: \(message)"
      case .gmailAppPasswordRequired(let message):
        return "Gmail App Password validation failed: \(message)"
      }
    }
  }

  public enum TestResult: Sendable {
    case success(String)
    case failure(String, provider: EmailProvider = .imap)

    public var isSuccess: Bool {
      switch self {
      case .success: return true
      case .failure: return false
      }
    }

    public var description: String {
      switch self {
      case .success(let message): return message
      case .failure(let message, _): return message
      }
    }
  }

  public enum EmailProvider: Sendable {
    case imap
    case gmail
  }

  /// Represents an email message.
  struct EmailMessage {
    let id: String
    let from: String
    let subject: String
    let body: String
    let date: Date
  }

  /// Main initializer supporting dependency injection for logger, userSettingsManager, and sharedCodePool.
  /// - Parameters:
  ///   - logger: Logger instance (default: ODYSSEY EmailService logger)
  ///   - userSettingsManager: UserSettingsManager instance (default: .shared)
  ///   - sharedCodePool: SharedVerificationCodePool instance (default: new instance)
  public init(
    logger: Logger,
    userSettingsManager: UserSettingsManager
  ) {
    self.logger = logger
    self.userSettingsManager = userSettingsManager
    logger.info("🔧 EmailService initialized (DI mode).")
  }

  // Keep the default singleton for app use
  convenience init() {
    self.init(
      logger: Logger(subsystem: AppConstants.loggingSubsystem, category: "EmailService"),
      userSettingsManager: UserSettingsManager.shared,
    )
  }

  deinit {
    logger.info("🧹 EmailService deinitialized.")
  }

  private static var lastIMAPConnectionTimestamp: Date?

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
  ///   - password: The password (should be an app password for Gmail).
  ///   - server: The IMAP server
  /// - Returns: Validation result
  private func validateGmailSettings(email: String, password: String, server: String) -> Result<
    Void, IMAPError
  > {
    guard ValidationService.shared.isGmailAccount(email) else { return .success(()) }

    // Check if server is correct for Gmail
    if server.lowercased() != AppConstants.gmailImapServer {
      return .failure(
        .gmailAppPasswordRequired("Gmail accounts must use 'imap.gmail.com' as the server."))
    }

    // Use centralized validation for Gmail app password
    let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
    guard ValidationService.shared.validateGmailAppPassword(trimmedPassword) else {
      return .failure(
        .gmailAppPasswordRequired("Gmail App Password must be in format: 'xxxx xxxx xxxx xxxx'"))
    }

    return .success(())
  }

  // MARK: - Public Methods

  /// Extracts verification code from email
  /// - Returns: The verification code if found, nil otherwise
  func extractVerificationCode() async -> String? {
    logger.info("📧 Checking for verification email from noreply@frontdesksuite.com.")

    // Check if we have the email settings needed
    guard
      !userSettingsManager.userSettings.imapEmail.isEmpty,
      !userSettingsManager.userSettings.imapPassword.isEmpty,
      !userSettingsManager.userSettings.imapServer.isEmpty
    else {
      logger.error("❌ Incomplete email settings.")
      return nil
    }

    // Use the existing IMAP connection to fetch verification codes
    let codes = await fetchVerificationCodesForToday(
      since: Date()
        .addingTimeInterval(-AppConstants.verificationCodeTimeout),
    )  // Last 5 minutes

    if let latestCode = codes.last {
      logger.info("✅ Found verification code: \(latestCode).")
      return latestCode
    }

    logger.info("📧 No verification code found in recent emails.")
    return nil
  }

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
    logger.info("🔗 Connecting to IMAP server: \(server):\(port).")

    // Test the connection first
    let testResult = await testIMAPConnection(
      email: username,
      password: password,
      server: server,
    )

    if case .failure(let error, provider: _) = testResult {
      throw IMAPError.connectionFailed(error)
    }

    logger.info("✅ IMAP connection successful.")
  }

  /// Connects to IMAP server and searches for verification email
  /// - Parameters:
  ///   - server: IMAP server address
  ///   - port: IMAP server port
  ///   - username: Email username
  ///   - password: Email password
  /// - Returns: Email with verification code if found
  func searchVerificationEmail(from: String, subject: String) async throws -> EmailMessage? {
    logger.info("🔍 Searching for verification email from: \(from) with subject: \(subject).")

    // For now, we'll use the existing fetchVerificationCodesForToday method
    // and look for the most recent email that matches our criteria
    let codes = await fetchVerificationCodesForToday(
      since: Date()
        .addingTimeInterval(-AppConstants.verificationCodeTimeout),
    )  // Last 5 minutes

    if let latestCode = codes.last {
      // Create a mock email message with the verification code
      let emailBody = """
        Your verification code is:
        \(latestCode).

        The code must be entered on the booking page to confirm your booking."

        You can also confirm your email or phone number at the link below:"
        \(AppConstants.verificationExternalLink)
        """

      return EmailMessage(
        id: UUID().uuidString,
        from: from,
        subject: subject,
        body: emailBody,
        date: Date(),
      )
    }

    logger.warning("⚠️ No verification email found.")
    return nil
  }

  /// Fetches all verification codes from emails from noreply@frontdesksuite.com received in the last 15 minutes.
  /// - Returns: Array of 4-digit codes (chronological order).
  func fetchVerificationCodesForToday(since: Date) async -> [String] {
    let connectionID = UUID().uuidString
    let now = Date()
    let lastAttempt = EmailService.lastIMAPConnectionTimestamp
    EmailService.lastIMAPConnectionTimestamp = now

    // Use a 15-minute window to catch all recent verification emails
    let searchSince = since.timeIntervalSinceNow > -900 ? since : Date().addingTimeInterval(-900)

    if let last = lastAttempt {
      let interval = now.timeIntervalSince(last)
      logger.info("⏰ [IMAP][\(connectionID)] Time since last connection: \(interval) seconds.")
    } else {
      logger.info("🆕 [IMAP][\(connectionID)] First connection attempt in this session.")
    }
    logger.info("🚀 [IMAP][\(connectionID)] Starting fetchVerificationCodesForToday() at \(now).")
    logger.info("📧 EmailService: Starting fetchVerificationCodesForToday().")
    logger.info("📧 EmailService: Using searchSince: \(searchSince).")
    logger.info("📧 EmailService: Original since parameter was: \(since).")
    logger.info("📧 EmailService: Time difference: \(searchSince.timeIntervalSince(since)) seconds.")

    let settings = userSettingsManager.userSettings
    guard settings.hasEmailConfigured else {
      logger.error("❌ EmailService: Incomplete email settings for code extraction.")
      return []
    }

    logger.info("✅ EmailService: Email settings are configured.")

    // Use the same NWConnection-based implementation that works for the test
    // ---
    // The following function will aggregate all unique IDs from all search strategies
    return await fetchVerificationCodesWithSameConnection(since: searchSince)
  }

  /// Fetches and consumes verification codes for a specific instance
  /// - Parameters:
  ///   - since: The date since which to fetch codes
  ///   - instanceId: Unique identifier for the WebKit instance
  /// - Returns: Array of verification codes for this instance
  func fetchAndConsumeVerificationCodes(since: Date, instanceId: String) async -> [String] {
    logger.info("📧 EmailService: Fetching and consuming codes for instance: \(instanceId).")

    // Use a shared code pool to ensure each instance gets unique codes
    return await SharedVerificationCodePool.shared.consumeCodes(for: instanceId, since: since)
  }

  /// Checks if a verification code has already been consumed by another instance
  /// - Parameters:
  ///   - code: The verification code to check
  ///   - currentInstanceId: The ID of the current instance
  /// - Returns: True if the code has been consumed by another instance
  func isCodeConsumedByOtherInstance(_ code: String, currentInstanceId: String) async -> Bool {
    return SharedVerificationCodePool.shared.isCodeConsumedByOtherInstance(
      code,
      currentInstanceId: currentInstanceId,
    )
  }

  /// Marks a verification code as consumed by a specific instance
  /// - Parameters:
  ///   - code: The verification code to mark as consumed
  ///   - instanceId: The ID of the instance that consumed the code
  func markCodeAsConsumed(_ code: String, byInstanceId instanceId: String) async {
    SharedVerificationCodePool.shared.markCodeAsConsumed(code, byInstanceId: instanceId)
  }

  /// Fetches verification codes using the same connection logic as the test
  private func fetchVerificationCodesWithSameConnection(since: Date) async -> [String] {
    logger.info("🔍 EmailService: Fetching verification codes with same connection logic.")

    // Use the same NWConnection-based implementation that works for the test
    return await fetchVerificationCodesWithNWConnection(since: since)
  }

  /// Fetches verification codes using NWConnection (same implementation as test)
  private func fetchVerificationCodesWithNWConnection(since: Date) async -> [String] {
    let settings = userSettingsManager.userSettings

    logger.info("🔍 EmailService: Fetching verification codes with NWConnection.")

    // Determine port and TLS settings based on server
    let server = settings.currentServer
    let port: UInt16 =
      server == AppConstants.gmailImapServer
      ? AppConstants.gmailImapPort
      : AppConstants
        .gmailImapPort  // Default to 993 for most IMAP servers
    let useTLS = true  // Most modern IMAP servers require TLS

    // Create a new connection for the actual email fetching
    let parameters = NWParameters.tcp
    if useTLS {
      parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolTLS.Options(), at: 0)
    }
    let connection = NWConnection(
      host: NWEndpoint.Host(server),
      port: NWEndpoint.Port(integerLiteral: port),
      using: parameters,
    )

    return await withCheckedContinuation { (continuation: CheckedContinuation<[String], Never>) in
      connection.stateUpdateHandler = { [weak self] (state: NWConnection.State) in
        guard let self else { return }
        switch state {
        case .ready:
          Task {
            await self.performEmailSearch(
              connection: connection,
              since: since,
              continuation: continuation,
            )
          }
        case .failed(let error):
          self.logger.error("❌ EmailService: Connection failed: \(error).")
          continuation.resume(returning: [])
        case .cancelled:
          self.logger.error("❌ EmailService: Connection cancelled.")
          continuation.resume(returning: [])
        default:
          break
        }
      }
      connection.start(queue: .global())
    }
  }

  /// Performs email search and code extraction using NWConnection
  private func performEmailSearch(
    connection: NWConnection,
    since: Date,
    continuation: CheckedContinuation<[String], Never>,
  ) async {
    let settings = userSettingsManager.userSettings
    let isGmail = settings.isGmailAccount(settings.imapEmail)
    let provider: EmailProvider = isGmail ? .gmail : .imap

    // Determine port and TLS settings based on server
    let useTLS = true

    // First authenticate
    await performIMAPHandshake(
      connection: connection,
      email: settings.currentEmail,
      password: settings.currentPassword,
      useTLS: useTLS,
      isGmail: isGmail,
      provider: provider,
    ) { [weak self] result in
      guard let self else {
        continuation.resume(returning: [])
        return
      }

      switch result {
      case .success:
        // Now search for verification emails
        Task {
          await self.searchForVerificationEmails(
            connection: connection,
            since: since,
            continuation: continuation,
          )
        }
      case .failure(let error, _):
        self.logger.error("❌ EmailService: Authentication failed: \(error).")
        continuation.resume(returning: [])
      }
    }
  }

  /// Searches for verification emails and extracts codes
  private func searchForVerificationEmails(
    connection: NWConnection,
    since: Date,
    continuation: CheckedContinuation<[String], Never>,
  ) async {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd-MMM-yyyy"

    // Use the provided since parameter, but ensure we have a reasonable lookback window

    let searchSince = since.timeIntervalSinceNow > -600 ? since : Date().addingTimeInterval(-600)
    let sinceDateStr = dateFormatter.string(from: searchSince)

    logger.info("📧 EmailService: NWConnection search using timestamp: \(searchSince).")
    logger.info("📧 EmailService: Original since parameter was: \(since).")
    logger.info("📧 EmailService: Time difference: \(searchSince.timeIntervalSince(since)) seconds.")

    // First try: Search for emails with specific subject
    let specificSearchCommand =
      "a001 SEARCH SINCE \(sinceDateStr) FROM \"\(AppConstants.verificationEmailFrom)\" SUBJECT \"\(AppConstants.verificationEmailSubject)\"\r\n"

    await sendIMAPCommand(connection: connection, command: specificSearchCommand) {
      [weak self] result in
      guard let self else {
        continuation.resume(returning: [])
        return
      }

      switch result {
      case .success(let searchResponse):
        self.logger.info("📧 EmailService: Specific subject search response: \(searchResponse).")

        // Parse message IDs from search response
        let lines = searchResponse.components(separatedBy: .newlines)
        let searchLine = lines.first(where: { $0.contains("SEARCH") }) ?? ""
        let parts = searchLine.components(separatedBy: " ")
        let ids = parts.dropFirst().compactMap { Int($0) }

        if !ids.isEmpty {
          self.logger.info("📧 EmailService: Found \(ids.count) emails with specific subject.")
          self.fetchAndExtractCodes(connection: connection, ids: ids, continuation: continuation)
          return
        }

        // Fallback: Search for any emails from the sender
        self.logger.info(
          "📧 EmailService: No emails with specific subject found, trying fallback search")
        let fallbackSearchCommand =
          "a002 SEARCH SINCE \(sinceDateStr) FROM \"noreply@frontdesksuite.com\"\r\n"

        Task {
          await self
            .sendIMAPCommand(connection: connection, command: fallbackSearchCommand) {
              [weak self] result in
              guard let self else {
                continuation.resume(returning: [])
                return
              }

              switch result {
              case .success(let fallbackResponse):
                self.logger.info("📧 EmailService: Fallback search response: \(fallbackResponse).")

                let fallbackLines = fallbackResponse.components(separatedBy: .newlines)
                let fallbackSearchLine = fallbackLines.first(where: { $0.contains("SEARCH") }) ?? ""
                let fallbackParts = fallbackSearchLine.components(separatedBy: " ")
                let fallbackIds = fallbackParts.dropFirst().compactMap { Int($0) }

                if !fallbackIds.isEmpty {
                  self.logger
                    .info(
                      "📧 EmailService: Found \(fallbackIds.count) emails from sender (fallback)",
                    )
                  self.fetchAndExtractCodes(
                    connection: connection,
                    ids: fallbackIds,
                    continuation: continuation,
                  )
                } else {
                  self.logger.info(
                    "📧 EmailService: No verification emails found in fallback search")
                  continuation.resume(returning: [])
                }

              case .failure(let error):
                self.logger.error("❌ EmailService: Fallback search failed: \(error).")
                continuation.resume(returning: [])
              }
            }
        }

      case .failure(let error):
        self.logger.error("❌ EmailService: Specific subject search failed: \(error).")
        continuation.resume(returning: [])
      }
    }
  }

  /// Helper method to fetch and extract codes from email IDs
  private nonisolated func fetchAndExtractCodes(
    connection: NWConnection,
    ids: [Int],
    continuation: CheckedContinuation<[String], Never>,
  ) {
    // Fetch ALL emails, not just the last one
    self.logger.info("📧 EmailService: Fetching \(ids.count) emails for verification codes.")

    Task {
      var allCodes: Set<String> = []
      let totalEmails = ids.count

      // Process each email sequentially to avoid overwhelming the IMAP server
      for (index, emailId) in ids.enumerated() {
        let fetchCommand = "a00\(3 + index) FETCH \(emailId) BODY[TEXT]\r\n"

        do {
          let fetchResponse = try await withCheckedThrowingContinuation {
            (
              continuation: CheckedContinuation<
                String,
                Error
              >
            ) in
            Task {
              await self.sendIMAPCommand(connection: connection, command: fetchCommand) { result in
                switch result {
                case .success(let response):
                  continuation.resume(returning: response)
                case .failure(let error):
                  continuation.resume(throwing: error)
                }
              }
            }
          }

          self.logger
            .info(
              "📧 EmailService: Fetch response received for email \(emailId) (\(index + 1)/\(totalEmails))",
            )

          // Extract verification codes from email body
          let codes = await self.extractVerificationCodes(from: fetchResponse)
          self.logger
            .info(
              "📧 EmailService: Email \(emailId) contained \(codes.count) verification codes: \(codes)"
            )

          // Add codes to the set
          for code in codes {
            allCodes.insert(code)
          }

        } catch {
          self.logger.error("❌ EmailService: Fetch failed for email \(emailId): \(error).")
          // Continue with next email even if this one fails
        }
      }

      let uniqueCodes = Array(allCodes).sorted()
      self.logger
        .info(
          "📧 EmailService: Processed all \(totalEmails) emails, extracted \(uniqueCodes.count) unique verification codes: \(uniqueCodes)",
        )
      continuation.resume(returning: uniqueCodes)
    }
  }

  /// Runs email configuration diagnostic and returns detailed report
  /// - Returns: Diagnostic report string
  func runEmailDiagnostic() async -> String {
    logger.info("🔍 Running email configuration diagnostic.")
    return await diagnoseEmailConfiguration()
  }

  func testGmailConnection(email: String, appPassword: String) async -> TestResult {
    return await testIMAPConnection(
      email: email,
      password: appPassword,
      server: AppConstants.gmailImapServer,
      isGmail: true,
      provider: .gmail,
    )
  }

  public func testIMAPConnection(
    email _: String,
    password _: String,
    server _: String,
    isGmail _: Bool = false,
    provider: EmailProvider = .imap,
  ) async -> TestResult {
    isTesting = true
    defer { isTesting = false }

    // Always retrieve credentials from Keychain
    guard let creds = getCredentialsFromKeychain() else {
      return .failure("Credentials not found in Keychain", provider: provider)
    }
    let email = creds.email
    let password = creds.password
    let server = creds.server

    guard !email.isEmpty else {
      return .failure("Email address is empty", provider: provider)
    }
    guard !password.isEmpty else {
      return .failure("Password is empty", provider: provider)
    }
    guard !server.isEmpty else {
      return .failure("IMAP server is empty", provider: provider)
    }

    // Validate Gmail settings if applicable
    let gmailValidation = validateGmailSettings(email: email, password: password, server: server)
    if case .failure(let error) = gmailValidation {
      return .failure(error.localizedDescription, provider: provider)
    }

    let emailRegex = AppConstants.emailRegexPattern
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    guard emailPredicate.evaluate(with: email) else {
      return .failure("Invalid email format", provider: provider)
    }

    // For Gmail, only try port 993 with SSL/TLS
    let portConfigurations: [(port: UInt16, useTLS: Bool, description: String)] =
      if server == AppConstants.gmailImapServer {
        [
          (port: UInt16(AppConstants.gmailImapPort), useTLS: true, description: "SSL/TLS (Gmail)")
        ]
      } else {
        [
          (port: UInt16(AppConstants.gmailImapPort), useTLS: true, description: "SSL/TLS"),
          (port: UInt16(143), useTLS: false, description: "Plain"),
          (port: UInt16(143), useTLS: true, description: "STARTTLS"),
        ]
      }

    for config in portConfigurations {
      logger.info("🔗 Trying IMAP connection to \(server):\(config.port) (\(config.description)).")
      let result = await connectToIMAP(
        server: server,
        port: config.port,
        useTLS: config.useTLS,
        email: email,
        password: password,
      )
      if case .success = result { return result }
      if case .failure(let error, _) = result {
        logger.warning("⚠️ IMAP connection failed on \(server):\(config.port): \(error).")
      }
    }
    return .failure(
      "All IMAP connection attempts failed",
      provider: provider,
    )
  }

  /// Connects to IMAP server and performs authentication
  /// - Parameters:
  ///   - server: IMAP server address
  ///   - port: IMAP server port
  ///   - useTLS: Whether to use TLS encryption
  ///   - email: Email address for authentication
  ///   - password: Password for authentication
  /// - Returns: Connect result
  private func connectToIMAP(
    server: String,
    port: UInt16,
    useTLS: Bool,
    email: String,
    password: String,
  ) async -> TestResult {
    return await withCheckedContinuation { (continuation: CheckedContinuation<TestResult, Never>) in
      self.startIMAPConnection(
        continuation: continuation,
        server: server,
        port: port,
        useTLS: useTLS,
        email: email,
        password: password,
      )
    }
  }

  private func startIMAPConnection(
    continuation: CheckedContinuation<TestResult, Never>,
    server: String,
    port: UInt16,
    useTLS: Bool,
    email: String,
    password: String,
  ) {
    let connectionID = UUID().uuidString
    let now = Date()
    let lastAttempt = EmailService.lastIMAPConnectionTimestamp
    EmailService.lastIMAPConnectionTimestamp = now
    if let last = lastAttempt {
      let interval = now.timeIntervalSince(last)
      logger.info("⏰ [IMAP][\(connectionID)] Time since last connection: \(interval) seconds.")
    } else {
      logger.info("🆕 [IMAP][\(connectionID)] First connection attempt in this session.")
    }
    logger.info("🚀 [IMAP][\(connectionID)] Starting connectToIMAP at \(now).")
    logger.info(
      "🔗 [IMAP][\(connectionID)] Attempting connection to \(server):\(port) TLS=\(useTLS).")

    let provider: EmailProvider = server == AppConstants.gmailImapServer ? .gmail : .imap
    logger
      .info(
        "[IMAP] Attempting connection to \(server):\(port) TLS=\(useTLS) for provider \(String(describing: provider))",
      )

    let connection = NWConnection(
      host: NWEndpoint.Host(server),
      port: NWEndpoint.Port(integerLiteral: port),
      using: .tls,
    )

    let state = IMAPConnectionState()

    connection.stateUpdateHandler = { [weak self] nwState in
      let config = IMAPStateConfig(
        connection: connection,
        connectionID: connectionID,
        server: server,
        port: port,
        useTLS: useTLS,
        email: email,
        password: password,
        continuation: continuation,
        stateObj: state,
      )
      self?.handleIMAPState(state: nwState, config: config)
    }

    connection.start(queue: .global())

    // Set a timeout for the entire connection process
    DispatchQueue.global().asyncAfter(deadline: .now() + AppConstants.connectionTimeoutSeconds) {
      [self] in
      if !state.authenticationCompleted, !state.didResume {
        logger
          .error(
            "[IMAP][\(connectionID)] Connection to \(server):\(port) timed out after \(AppConstants.connectionTimeoutSeconds) seconds (TLS=\(useTLS))",
          )
        connection.cancel()
        let provider: EmailProvider = server == "imap.gmail.com" ? .gmail : .imap
        state.didResume = true
        continuation.resume(
          returning: .failure(
            "Connection timed out after \(AppConstants.connectionTimeoutSeconds) seconds",
            provider: provider,
          ))
      }
    }

    // Fallback: ensure continuation is always resumed
    DispatchQueue.global().asyncAfter(deadline: .now() + AppConstants.fallbackTimeoutSeconds) {
      [self] in
      if !state.didResume {
        state.didResume = true
        let provider: EmailProvider = server == "imap.gmail.com" ? .gmail : .imap
        logger.error(
          "[IMAP][\(connectionID)] Fallback: forcibly resuming continuation after \(AppConstants.fallbackTimeoutSeconds)s."
        )
        continuation.resume(
          returning: .failure(
            "IMAP connection did not complete or resume in time (internal fallback)",
            provider: provider,
          ))
      }
    }
  }

  /// Configuration for IMAP connection state handling
  private struct IMAPStateConfig {
    let connection: NWConnection
    let connectionID: String
    let server: String
    let port: UInt16
    let useTLS: Bool
    let email: String
    let password: String
    let continuation: CheckedContinuation<TestResult, Never>
    let stateObj: IMAPConnectionState
  }

  private nonisolated func handleIMAPState(
    state: NWConnection.State,
    config: IMAPStateConfig,
  ) {
    let staticLogger = Logger(subsystem: AppConstants.loggingSubsystem, category: "IMAP")
    config.stateObj.connectionState = "\(state)"
    let stateMsg =
      "[IMAP][\(config.connectionID)] Connection state for \(config.server):\(config.port) is \(state) (TLS=\(config.useTLS))"
    staticLogger.info("\(stateMsg, privacy: .public)")

    switch state {
    case .ready:
      let readyMsg =
        "[IMAP][\(config.connectionID)] Connection ready for \(config.server):\(config.port) (TLS=\(config.useTLS))"
      staticLogger.info("\(readyMsg, privacy: .public)")
      if !config.stateObj.handshakeCompleted {
        config.stateObj.handshakeCompleted = true
        let handshakeMsg =
          "[IMAP][\(config.connectionID)] Starting handshake for \(config.server) connection (TLS=\(config.useTLS))"
        staticLogger.info("\(handshakeMsg, privacy: .public)")
        let provider: EmailProvider = config.server == "imap.gmail.com" ? .gmail : .imap
        Task {
          await self.performIMAPHandshake(
            connection: config.connection,
            email: config.email,
            password: config.password,
            useTLS: config.useTLS,
            isGmail: config.server == "imap.gmail.com",
            provider: provider,
          ) { result in
            config.stateObj.authenticationCompleted = true
            if !config.stateObj.didResume {
              config.stateObj.didResume = true
              config.continuation.resume(returning: result)
            }
          }
        }
      }
    case .failed(let error):
      let failMsg =
        "[IMAP][\(config.connectionID)] Connection failed for \(config.server):\(config.port) (TLS=\(config.useTLS)): \(error)"
      staticLogger.error("\(failMsg, privacy: .public)")
      let provider: EmailProvider = config.server == AppConstants.gmailImapServer ? .gmail : .imap
      if !config.stateObj.didResume {
        config.stateObj.didResume = true
        config.continuation.resume(
          returning: .failure(
            "Connection failed: \(error.localizedDescription)",
            provider: provider,
          ))
      }
    case .cancelled:
      if config.stateObj.authenticationCompleted {
        let cancelMsg =
          "[IMAP][\(config.connectionID)] Connection cancelled after successful authentication "
          + "for \(config.server):\(config.port) (TLS=\(config.useTLS))"
        staticLogger.info("\(cancelMsg, privacy: .public)")
      } else {
        let cancelMsg =
          "❌ [IMAP][\(config.connectionID)] Connection cancelled on \(config.server):\(config.port) "
          + "(TLS=\(config.useTLS)): Connection was cancelled"
        staticLogger.error("\(cancelMsg, privacy: .public)")
        if !config.stateObj.didResume {
          config.stateObj.didResume = true
          let provider: EmailProvider = config.server == "imap.gmail.com" ? .gmail : .imap
          config.continuation.resume(
            returning: .failure(
              "Connection cancelled before authentication",
              provider: provider,
            ))
        }
      }
    default:
      break
    }
  }

  private func performIMAPHandshake(
    connection: NWConnection,
    email: String,
    password: String,
    useTLS: Bool,
    isGmail: Bool,
    provider: EmailProvider,
    completion: @escaping @Sendable (TestResult) -> Void,
  ) async {
    logger.info(
      "[IMAP] Starting handshake for \(provider == .gmail ? "Gmail" : "IMAP") connection (TLS=\(useTLS))"
    )

    await receiveIMAPResponse(connection: connection) {
      [weak self] (result: Result<String, IMAPError>) in
      guard let self else { return }
      switch result {
      case .success(let greeting):
        logger.info("👋 [IMAP] Greeting received: \(greeting.prefix(200)).")

        // Check for authentication errors in the greeting
        if greeting.contains("NO"), greeting.lowercased().contains("login") {
          logger.error("❌ [IMAP] Authentication failed in greeting: \(greeting).")
          completion(
            .failure(
              "Authentication failed: Invalid email or password",
              provider: provider,
            ))
          return
        }

        if greeting.contains("BAD") {
          logger.error("❌ [IMAP] Server rejected connection: \(greeting).")
          completion(
            .failure(
              "Server rejected connection: \(greeting)",
              provider: provider,
            ))
          return
        }

        if !useTLS, greeting.contains("STARTTLS") {
          logger.info("🔒 [IMAP] Server supports STARTTLS, upgrading connection.")
          Task {
            await self
              .upgradeToTLS(
                connection: connection,
                isGmail: isGmail,
                provider: provider,
              ) { tlsResult in
                switch tlsResult {
                case .success:
                  Task {
                    await self.continueIMAPHandshake(
                      connection: connection,
                      email: email,
                      password: password,
                      isGmail: isGmail,
                      provider: provider,
                      completion: completion,
                    )
                  }
                case .failure(let error):
                  completion(.failure(error.localizedDescription, provider: provider))
                }
              }
          }
        } else {
          logger.info("🔐 [IMAP] Proceeding with authentication.")
          Task {
            await self.continueIMAPHandshake(
              connection: connection,
              email: email,
              password: password,
              isGmail: isGmail,
              provider: provider,
              completion: completion,
            )
          }
        }
      case .failure(let error):
        logger.error(
          "❌ [IMAP] Failed to receive greeting: \(error.localizedDescription, privacy: .private).")

        // Provide more specific error messages
        if error.localizedDescription.contains("timeout") {
          completion(
            .failure(
              "Server did not respond with IMAP greeting. Check if IMAP is enabled on port \(useTLS ? String(AppConstants.gmailImapPort) : String(AppConstants.defaultImapPort))",
              provider: provider,
            ))
        } else {
          completion(.failure(error.localizedDescription, provider: provider))
        }
      }
    }
  }

  private func continueIMAPHandshake(
    connection: NWConnection,
    email: String,
    password: String,
    isGmail _: Bool,
    provider: EmailProvider,
    completion: @escaping @Sendable (TestResult) -> Void,
  ) async {
    await sendIMAPCommand(
      connection: connection,
      command: "a001 CAPABILITY\r\n",
    ) { [weak self] (result: Result<String, IMAPError>) in
      guard let self else { return }
      switch result {
      case .success:
        let loginCommand = "a002 LOGIN \"\(email)\" \"\(password)\"\r\n"
        Task {
          await self
            .sendIMAPCommand(connection: connection, command: loginCommand) {
              [weak self]
              (
                result: Result<
                  String,
                  IMAPError
                >
              ) in
              guard let self else { return }
              switch result {
              case .success(let loginResponse):
                self.logger.info("🔐 [IMAP] LOGIN response: \(loginResponse).")
                // Parse response lines for the LOGIN tag (a002)
                let loginLines = loginResponse.components(separatedBy: .newlines)
                self.logger.info("📋 [IMAP] LOGIN response lines: \(loginLines).")

                // Check ALL lines for authentication result, not just the first tagged line
                var authenticationResult: String?
                for line in loginLines {
                  let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                  if trimmedLine.hasPrefix("a002") {
                    authenticationResult = trimmedLine
                    self.logger.info("🏷️ [IMAP] Found tagged line: '\(trimmedLine)'.")
                    break
                  }
                }

                if authenticationResult == nil {
                  for line in loginLines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if trimmedLine.contains("OK") || trimmedLine.contains("NO")
                      || trimmedLine
                        .contains("BAD")
                    {
                      authenticationResult = trimmedLine
                      self.logger.info("🔍 [IMAP] Found auth result line: '\(trimmedLine)'.")
                      break
                    }
                  }
                }

                if let result = authenticationResult {
                  if result.contains("OK") {
                    self.logger.info("✅ [IMAP] Authentication successful: \(result).")
                    // Continue with SELECT INBOX
                    let selectCommand = "a003 SELECT INBOX\r\n"
                    Task {
                      await self
                        .sendIMAPCommand(
                          connection: connection,
                          command: selectCommand,
                        ) {
                          [weak self]
                          (
                            result: Result<
                              String,
                              IMAPError
                            >
                          ) in
                          guard let self else { return }
                          switch result {
                          case .success(let selectResponse):
                            self.logger
                              .info("[IMAP] SELECT INBOX response: \(selectResponse)")
                            // After selecting INBOX, search for the latest email
                            // Use RECENT for efficiency - only searches recently received
                            // emails
                            let searchCommand = "a004 SEARCH RECENT\r\n"
                            self.logger
                              .info("[IMAP] Using search command: \(searchCommand)")
                            Task {
                              await self.sendIMAPCommand(
                                connection: connection,
                                command: searchCommand,
                              ) { [weak self] (result: Result<String, IMAPError>) in
                                guard let self else { return }
                                switch result {
                                case .success(let searchResponse):
                                  self.logger
                                    .info(
                                      "[IMAP] SEARCH response: \(searchResponse)",
                                    )
                                  // Parse the search response for message IDs
                                  let lines =
                                    searchResponse
                                    .components(separatedBy: .newlines)
                                  let searchLine =
                                    lines
                                    .first(where: { $0.contains("SEARCH") }) ?? ""
                                  self.logger
                                    .info("[IMAP] Search line: \(searchLine)")
                                  let parts = searchLine.components(separatedBy: " ")
                                  let ids = parts.dropFirst().compactMap { Int($0) }
                                  self.logger
                                    .info(
                                      "[IMAP] Found \(ids.count) email IDs: \(ids)",
                                    )
                                  if let lastId = ids.last {
                                    self.logger
                                      .info(
                                        "[IMAP] Fetching subject for email ID: \(lastId)",
                                      )
                                    let fetchCommand =
                                      "a005 FETCH \(lastId) BODY[HEADER.FIELDS (SUBJECT)]\r\n"
                                    Task {
                                      await self.sendIMAPCommand(
                                        connection: connection,
                                        command: fetchCommand,
                                      ) {
                                        [weak self]
                                        (
                                          result: Result<
                                            String,
                                            IMAPError
                                          >
                                        ) in
                                        guard let self else { return }
                                        switch result {
                                        case .success(let fetchResponse):
                                          self.logger
                                            .info(
                                              "[IMAP] FETCH response: \(fetchResponse)",
                                            )
                                          // Extract subject
                                          let subject =
                                            self
                                            .parseEmailSubject(
                                              from: fetchResponse,
                                            )
                                          let baseMessage =
                                            "IMAP connection successful!"
                                          let fullMessage =
                                            subject
                                              .isEmpty
                                            ? baseMessage
                                            : "\(baseMessage) Latest email: \(subject)"
                                          completion(.success(fullMessage))
                                        case .failure(let error):
                                          self.logger
                                            .error(
                                              "[IMAP] FETCH failed: \(error.localizedDescription)",
                                            )
                                          completion(
                                            .failure(
                                              "Failed to fetch email: "
                                                + error.localizedDescription,
                                              provider: provider,
                                            ))
                                        }
                                      }
                                    }
                                  } else {
                                    // No emails found
                                    completion(
                                      .success(
                                        "IMAP connection successful!",
                                      ))
                                  }
                                case .failure(let error):
                                  self.logger
                                    .error(
                                      "[IMAP] SEARCH failed: \(error.localizedDescription)",
                                    )
                                  completion(
                                    .failure(
                                      "Failed to search mailbox: " + error.localizedDescription,
                                      provider: provider,
                                    ))
                                }
                              }
                            }
                          case .failure(let error):
                            self.logger
                              .error(
                                "[IMAP] SELECT INBOX failed: \(error.localizedDescription)",
                              )
                            completion(
                              .failure(
                                "Mailbox selection failed: "
                                  + error
                                  .localizedDescription,
                                provider: provider,
                              ))
                          }
                        }
                    }
                  } else if result.contains("NO") || result.lowercased().contains("login") {
                    self.logger.error("❌ [IMAP] Authentication failed: \(result).")
                    completion(
                      .failure(
                        "Authentication failed: Invalid email or password",
                        provider: provider,
                      ))
                  } else if result.contains("BAD") {
                    self.logger.error("❌ [IMAP] Authentication error: \(result).")
                    completion(
                      .failure(
                        "Authentication error: " + result,
                        provider: provider,
                      ))
                  } else {
                    self.logger.error("❓ [IMAP] Unknown authentication result: \(result).")
                    completion(
                      .failure(
                        "Authentication failed: Unknown response",
                        provider: provider,
                      ))
                  }
                } else {
                  self.logger.error("❌ [IMAP] No authentication result found in response.")
                  completion(
                    .failure(
                      "Authentication failed: No response from server",
                      provider: provider,
                    ))
                }
              case .failure(let error):
                completion(
                  .failure(
                    "Authentication failed: \(error.localizedDescription)",
                    provider: provider,
                  ))
              }
            }
        }
      case .failure(let error):
        let errorMessage = "IMAP capability command failed: \(error.localizedDescription)"
        self.logger.error("❌ \(errorMessage).")
        completion(
          .failure(
            "IMAP command failed: \(error.localizedDescription)",
            provider: provider,
          ))
      }
    }
  }

  private func upgradeToTLS(
    connection: NWConnection,
    isGmail _: Bool,
    provider _: EmailProvider,
    completion: @escaping @Sendable (Result<Void, IMAPError>) -> Void,
  ) async {
    await sendIMAPCommand(
      connection: connection,
      command: "a001 STARTTLS\r\n",
    ) { (result: Result<String, IMAPError>) in
      switch result {
      case .success:
        DispatchQueue.global().asyncAfter(deadline: .now() + AppConstants.animationDurationNormal) {
          completion(.success(()))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  private func sendIMAPCommand(
    connection: NWConnection,
    command: String,
    completion: @escaping @Sendable (Result<String, IMAPError>) -> Void,
  ) async {
    let data = Data(command.utf8)
    logger.info("📤 IMAP Command: \(command.trimmingCharacters(in: .whitespacesAndNewlines)).")

    connection.send(
      content: data,
      completion: .contentProcessed { [self] error in
        if let error {
          logger.error("❌ IMAP send error: \(error.localizedDescription, privacy: .private).")
          completion(.failure(.commandFailed("Send failed: \(error.localizedDescription)")))
          return
        }
        logger.info("✅ IMAP command sent successfully.")
        Task { await self.receiveIMAPResponse(connection: connection, completion: completion) }
      })
  }

  private func receiveIMAPResponse(
    connection: NWConnection,
    completion: @escaping @Sendable (Result<String, IMAPError>) -> Void,
  ) async {
    connection.receive(
      minimumIncompleteLength: 1, maximumLength: AppConstants.webKitMaxReceiveLength
    ) {
      [self] data, _, _, error in
      if let error {
        logger.error("❌ [IMAP] Receive error: \(error.localizedDescription, privacy: .private).")
        completion(.failure(.invalidResponse("Receive failed: \(error.localizedDescription)")))
        return
      }
      guard let data, let response = String(data: data, encoding: .utf8) else {
        logger.error("❌ [IMAP] Invalid response data (empty or not UTF-8).")
        completion(.failure(.invalidResponse("Invalid response data")))
        return
      }
      logger.info(
        "[IMAP] Raw server response: \(response.prefix(AppConstants.serverResponsePreviewLength)).")
      completion(.success(response))
    }
  }

  private nonisolated func parseEmailSubject(from response: String) -> String {
    let lines = response.components(separatedBy: .newlines)
    for line in lines where line.lowercased().hasPrefix("subject:") {
      let subject =
        line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
        .last?
        .trimmingCharacters(in: .whitespaces) ?? ""
      return subject.isEmpty ? "No subject" : subject
    }
    return "No subject"
  }

  private func parseEmailHeaders(_ response: String) -> String {
    let lines = response.components(separatedBy: .newlines)
    var from = "Unknown"
    var subject = "No Subject"
    var date = "Unknown Date"
    for line in lines {
      if line.hasPrefix("From:") {
        from = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
      } else if line.hasPrefix("Subject:") {
        subject = String(line.dropFirst(9)).trimmingCharacters(in: .whitespaces)
      } else if line.hasPrefix("Date:") {
        date = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
      }
    }
    return "From: \(from) - Subject: \(subject) - Date: \(date)"
  }

  /// Extracts the email body from IMAP FETCH response
  /// - Parameter response: The IMAP FETCH response
  /// - Returns: The email body content
  private func extractBodyFromResponse(_ response: String) async -> String {
    // IMAP FETCH response format: * <id> FETCH (BODY[TEXT] {<size>}\r\n<content>\r\n)
    // We need to find the content after the size declaration and before the closing parenthesis

    // Look for the pattern: BODY[TEXT] {<size>}
    if let sizePattern = response.range(
      of: "BODY\\[TEXT\\] \\{[0-9]+\\}", options: .regularExpression)
    {
      // Find the end of the size pattern
      let sizeEnd = sizePattern.upperBound

      // Look for the first \r\n after the size pattern
      if let bodyStart = response.range(of: "\r\n", range: sizeEnd..<response.endIndex) {
        let contentStart = bodyStart.upperBound

        // Look for the closing parenthesis
        if let bodyEnd = response.range(of: ")", range: contentStart..<response.endIndex) {
          return String(response[contentStart..<bodyEnd.lowerBound])
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

  /// Extracts verification codes from email body
  /// - Parameter body: The email body text
  /// - Returns: Array of 4-digit verification codes found
  private func extractVerificationCodes(from body: String) async -> [String] {
    logger.info("🔍 Extracting verification codes from email body.")

    // Contextual patterns (case-insensitive, allow line breaks)
    let contextualPatterns: [(String, String)] = [
      ("verification code is[:\\s\\r\\n]*([0-9]{4})", "verification code is"),
      ("your verification code is[:\\s\\r\\n]*([0-9]{4})", "your verification code is"),
      ("your code is[:\\s\\r\\n]*([0-9]{4})", "your code is"),
      ("code is[:\\s\\r\\n]*([0-9]{4})", "code is"),
      ("verification code[\\s:]*([0-9]{4})", "verification code"),
      ("code[\\s:]*([0-9]{4})", "code"),
    ]
    var foundCodes: [String] = []
    for (pattern, context) in contextualPatterns {
      do {
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let matches = regex.matches(
          in: body,
          options: [],
          range: NSRange(location: 0, length: body.utf16.count),
        )
        let codes = matches.compactMap { match -> String? in
          guard
            match.numberOfRanges > 1,
            let range = Range(match.range(at: 1), in: body)
          else { return nil }
          return String(body[range])
        }

        foundCodes.append(contentsOf: codes)
      } catch {
        logger.error("❌ Regex error for pattern \(context): \(error.localizedDescription).")
      }
    }
    foundCodes = Array(Set(foundCodes))  // Unique
    if !foundCodes.isEmpty {
      // Filter out suspicious codes
      let filtered = foundCodes.filter { code in
        !AppConstants.suspiciousVerificationCodes.contains(code)
      }
      if !filtered.isEmpty {
        logger.info(
          "📋 Extracted \(filtered.count) unique verification codes (contextual): \(filtered)")
        return filtered
      } else {
        logger.warning("⚠️ All contextual codes were filtered out as suspicious: \(foundCodes).")
      }
    }
    logger.error("⚠️ No contextual code found, using fallback pattern: \\b\\d{4}\\b.")
    // Fallback pattern
    do {
      let fallbackPattern = "\\b\\d{4}\\b"
      let regex = try NSRegularExpression(pattern: fallbackPattern)
      let matches = regex.matches(
        in: body, options: [], range: NSRange(location: 0, length: body.utf16.count))
      let codes = matches.compactMap { match -> String? in
        guard let range = Range(match.range(at: 0), in: body) else { return nil }
        return String(body[range])
      }
      // Filter out suspicious codes
      let filtered = codes.filter { code in
        !AppConstants.suspiciousVerificationCodes.contains(code)
      }

      if !filtered.isEmpty {
        logger.info(
          "📋 Extracted \(filtered.count) unique verification codes (fallback): \(filtered)")
        return filtered
      } else {
        logger.warning("⚠️ All fallback codes were filtered out as suspicious: \(codes).")
      }
    } catch {
      logger.error(
        "❌ Regex error for fallback pattern: \(error.localizedDescription, privacy: .private).")
    }
    logger.error("⚠️ No verification codes found in email body.")
    return []
  }

  /// Fetches verification codes from emails using IMAP
  /// - Returns: Array of verification codes found
  private func fetchVerificationCodesFromEmails(since: Date) async -> [String] {
    return await { [self] in
      let settings = self.userSettingsManager.userSettings
      let port: UInt16 = AppConstants.defaultImapPort
      let server = settings.currentServer
      let email = settings.currentEmail
      let password = settings.currentPassword
      let fromAddress = "noreply@frontdesksuite.com"

      logger.info("📧 Email configuration - Email: \(email).")
      logger.info("📧 Email configuration - Is Gmail: \(settings.isGmailAccount(email)).")

      // Additional Gmail App Password validation
      if settings.isGmailAccount(email) {
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        // Validate Gmail App Password format
        let appPasswordPattern = "^[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}$"
        let appPasswordRegex = try? NSRegularExpression(pattern: appPasswordPattern)
        if let regex = appPasswordRegex {
          let range = NSRange(trimmedPassword.startIndex..., in: trimmedPassword)
          let matches = regex.firstMatch(in: trimmedPassword, range: range)
          if matches == nil {
            logger.warning("⚠️ Gmail App Password format validation failed.")
          }
        }
      }
      // Make subject search more flexible to catch variations
      let subject = "Verify your email."
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "d-MMM-yyyy"
      dateFormatter.locale = Locale(identifier: "en_US_POSIX")

      // Use a more recent timestamp to ensure we catch all verification emails
      let searchSince = Date().addingTimeInterval(-AppConstants.emailSearchWindowSeconds)  // 10 minutes ago
      let sinceDate = dateFormatter.string(from: searchSince)

      // Log search parameters
      logger.info("📅 IMAP search window sinceDate: \(sinceDate).")
      logger.info(
        "📅 IMAP search using timestamp: \(searchSince) (\(AppConstants.emailSearchWindowMinutes) minutes ago)."
      )
      logger.info("📅 IMAP original since parameter was: \(since).")

      logger.info("🔗 Connecting to IMAP server \(server):\(port) for user \(email).")

      var inputStream: InputStream?
      var outputStream: OutputStream?

      // For port 993, we need SSL/TLS
      Stream.getStreamsToHost(
        withName: server,
        port: Int(port),
        inputStream: &inputStream,
        outputStream: &outputStream,
      )
      if port == AppConstants.gmailImapPort {
        inputStream?.setProperty(StreamSocketSecurityLevel.tlSv1, forKey: .socketSecurityLevelKey)
        outputStream?.setProperty(StreamSocketSecurityLevel.tlSv1, forKey: .socketSecurityLevelKey)
      }

      guard let inputStream, let outputStream else {
        logger.error("❌ Failed to open IMAP streams.")
        return []
      }

      // Set up stream delegates for better error handling
      let streamDelegate = EmailIMAPStreamDelegate()
      inputStream.delegate = streamDelegate
      outputStream.delegate = streamDelegate

      inputStream.open()
      outputStream.open()

      // Wait for streams to open
      let startTime = Date()
      while (inputStream.streamStatus != .open || outputStream.streamStatus != .open)
        && Date().timeIntervalSince(startTime) < AppConstants.emailSearchWindowMinutes
      {
        try? await Task.sleep(nanoseconds: AppConstants.shortDelayNanoseconds)  // 0.1 seconds
      }

      if inputStream.streamStatus != .open || outputStream.streamStatus != .open {
        logger.error(
          "❌ Failed to open IMAP streams - status: input=\(inputStream.streamStatus.rawValue), output=\(outputStream.streamStatus.rawValue).",
        )
        return []
      }

      logger.info("✅ IMAP streams opened successfully.")

      defer {
        inputStream.close()
        outputStream.close()
      }

      func sendCommand(_ cmd: String) {
        let data = Array((cmd + "\r\n").utf8)
        data.withUnsafeBytes { bytes in
          guard let baseAddress = bytes.bindMemory(to: UInt8.self).baseAddress else {
            return
          }
          outputStream.write(baseAddress, maxLength: data.count)
        }
      }

      func expect(_ tag: String) async -> String {
        var buffer = [UInt8](repeating: 0, count: 4_096)
        var response = ""
        let startTime = Date()
        let timeout: TimeInterval = AppConstants.shortTimeout  // 10 second timeout

        while Date().timeIntervalSince(startTime) < timeout {
          // Check if we have bytes available
          if inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 {
              if let part = String(bytes: buffer[0..<bytesRead], encoding: .utf8) {
                response += part
              }
            } else if bytesRead == 0 {
              // End of stream
              break
            }
          }

          // Check if we have a complete response
          if response.contains("\(tag) OK") || response.contains("\(tag) BAD")
            || response
              .contains("\(tag) NO")
          {
            return response
          }

          // Small delay to avoid busy waiting
          try? await Task.sleep(nanoseconds: AppConstants.shortDelayNanoseconds)  // 0.1 seconds
        }

        logger.warning("⏰ IMAP expect timeout for tag \(tag) after \(timeout) seconds.")
        return response
      }

      // Read greeting
      let greeting = await expect("*")
      logger.info("📨 IMAP greeting: \(greeting.prefix(200)).")
      logger.error("❌ IMAP greeting (raw): \(String(describing: greeting)).")

      // For Gmail, try CAPABILITY first to see what's supported
      if settings.isGmailAccount(email) {
        logger.info("🔍 Checking Gmail IMAP capabilities.")
        sendCommand("a0 CAPABILITY")
        let capabilityResp = await expect("a0")
        logger.info("📋 Gmail capabilities: \(capabilityResp.prefix(200)).")
      }

      // LOGIN
      logger.info("🔐 Attempting IMAP login.")
      sendCommand("a1 LOGIN \"\(email)\" \"\(password)\"")
      let loginResp = await expect("a1")

      logger.error("❌ IMAP login response: \(String(describing: loginResp)).")

      guard loginResp.contains("a1 OK") else {
        logger.error("❌ IMAP login failed: \(String(describing: loginResp)).")

        let lines = loginResp.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
          logger.error("❌ Login response line \(index): \(String(describing: line)).")
        }

        // Try to extract the actual error message by looking for patterns
        if loginResp.contains("NO") {
          logger.error("❌ IMAP NO response detected - authentication failed.")
        }
        if loginResp.contains("BAD") {
          logger.error("❌ IMAP BAD response detected - command syntax error.")
        }

        // Log response analysis
        logger.error("❌ Response length: \(loginResp.count).")
        return []
      }
      logger.info("✅ IMAP login successful, about to search for verification emails.")

      // Try multiple search strategies to find verification emails
      var ids: [Int] = []

      // Strategy 1: Search by FROM only (since the provided timestamp)
      let searchCmd1 = "a3 SEARCH SINCE \(sinceDate) FROM \"\(fromAddress)\""
      sendCommand(searchCmd1)
      let searchResp1 = await expect("a3")
      let searchLines1 = searchResp1.components(separatedBy: "\n")
      let searchLine1 = searchLines1.first(where: { $0.contains("SEARCH") }) ?? ""
      let ids1 = searchLine1.components(separatedBy: " ").dropFirst()
        .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
      ids.append(contentsOf: ids1)

      // Strategy 2: Search by FROM and SUBJECT (exact match, since the provided timestamp)
      if ids.isEmpty {
        let searchCmd2 =
          "a4 SEARCH SINCE \(sinceDate) FROM \"\(fromAddress)\" SUBJECT \"\(subject)\""
        sendCommand(searchCmd2)
        let searchResp2 = await expect("a4")
        let searchLines2 = searchResp2.components(separatedBy: "\n")
        let searchLine2 = searchLines2.first(where: { $0.contains("SEARCH") }) ?? ""
        let ids2 = searchLine2.components(separatedBy: " ").dropFirst()
          .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        ids.append(contentsOf: ids2)
      }

      // Strategy 3: Search for any email with "verification" in subject (broader, since the provided timestamp)
      if ids.isEmpty {
        sendCommand("a5 SEARCH SINCE \(sinceDate) SUBJECT \"verification\"")
        let searchResp3 = await expect("a5")
        let searchLines3 = searchResp3.components(separatedBy: "\n")
        let searchLine3 = searchLines3.first(where: { $0.contains("SEARCH") }) ?? ""
        let ids3 = searchLine3.components(separatedBy: " ").dropFirst()
          .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        ids.append(contentsOf: ids3)
      }

      // Strategy 4: Search in INBOX explicitly (some servers need this)
      if ids.isEmpty {
        sendCommand("a6 SELECT INBOX")
        _ = await expect("a6")

        let searchCmd4 = "a7 SEARCH SINCE \(sinceDate) FROM \"\(fromAddress)\""
        sendCommand(searchCmd4)
        let searchResp4 = await expect("a7")
        let searchLines4 = searchResp4.components(separatedBy: "\n")
        let searchLine4 = searchLines4.first(where: { $0.contains("SEARCH") }) ?? ""
        let ids4 = searchLine4.components(separatedBy: " ").dropFirst()
          .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        ids.append(contentsOf: ids4)
      }

      if ids.isEmpty {
        logger
          .warning(
            "⚠️ No email IDs found in any search strategy. Listing all emails since provided timestamp for debug...",
          )
        // Search for all emails since the provided timestamp
        sendCommand("a8 SEARCH SINCE \(sinceDate)")
        let searchRespAll = await expect("a8")
        let searchLinesAll = searchRespAll.components(separatedBy: "\n")
        let searchLineAll = searchLinesAll.first(where: { $0.contains("SEARCH") }) ?? ""
        let idsAll = searchLineAll.components(separatedBy: " ").dropFirst()
          .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        // For each email, fetch and log subject and sender
        for id in idsAll {
          sendCommand("a9 FETCH \(id) (BODY[HEADER.FIELDS (SUBJECT FROM DATE)])")
          let headerResp = await expect("a9")
          logger.info("📧 Email ID \(id) header: \n\(headerResp).")
        }
      }

      ids = Array(Set(ids)).sorted()

      if ids.isEmpty {
        logger.warning("⚠️ No email IDs found in any search strategy.")
        return []
      }

      // Process each email
      var codes: [String] = []
      let headerDateFormatter = DateFormatter()
      headerDateFormatter.locale = Locale(identifier: "en_US_POSIX")
      headerDateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"  // IMAP RFC822

      // Alternative date formatter for different IMAP server formats
      let altDateFormatter = DateFormatter()
      altDateFormatter.locale = Locale(identifier: "en_US_POSIX")
      altDateFormatter.dateFormat = "d MMM yyyy HH:mm:ss Z"

      for id in ids {
        logger.info("📄 Processing email ID \(id).")
        sendCommand("a4 FETCH \(id) BODY[HEADER.FIELDS (DATE FROM SUBJECT)]")
        let headerResp = await expect("a4")
        logger.info("📬 Email ID \(id) headers: \(headerResp.prefix(500)).")

        // Parse Date: header
        let dateLine = headerResp.components(separatedBy: "\n")
          .first(where: { $0.lowercased().hasPrefix("date:") })
        guard
          let dateLine,
          let dateStr = dateLine.split(
            separator: ":",
            maxSplits: 1,
            omittingEmptySubsequences: false,
          ).last?.trimmingCharacters(in: .whitespacesAndNewlines)
        else {
          logger.info("📅 Skipping email ID \(id): Could not find date header.")
          continue
        }

        // Try multiple date formats
        var emailDate: Date?
        emailDate = headerDateFormatter.date(from: dateStr)
        if emailDate == nil {
          emailDate = altDateFormatter.date(from: dateStr)
        }

        guard let emailDate else {
          logger.info("📅 Skipping email ID \(id): Could not parse date '\(dateStr)'.")
          continue
        }

        if emailDate < since {
          logger
            .info(
              "⏰ Skipping email ID \(id, privacy: .private): Outside time range (\(emailDate, privacy: .private))",
            )
          continue
        }

        logger.info("✅ Email ID \(id) is recent enough, fetching body...")

        // Fetch email body
        sendCommand("a5 FETCH \(id) BODY[TEXT]")
        let bodyResp = await expect("a5")
        let body = await extractBodyFromResponse(bodyResp)
        logger.info("📧 Email ID \(id) body (truncated): \(body.prefix(500)).")

        // Extract verification codes
        let emailCodes = await extractVerificationCodes(from: body)
        logger.info("🔢 Email ID \(id) contains codes: \(emailCodes).")
        codes.append(contentsOf: emailCodes)
      }

      logger.info("📋 Found \(codes.count) verification codes: \(codes).")
      return codes
    }()
  }

  // MARK: - Email Configuration Diagnostics

  /// Comprehensive email configuration diagnostic
  /// - Returns: Detailed diagnostic information
  func diagnoseEmailConfiguration() async -> String {
    let settings = userSettingsManager.userSettings
    var diagnostic = "=== EMAIL CONFIGURATION DIAGNOSTIC ===\n\n"

    // Check if email settings are configured
    if !settings.hasEmailConfigured {
      diagnostic += "❌ Email settings are not configured\n"
      diagnostic += "Please configure your email settings in the app preferences.\n\n"
      return diagnostic
    }

    diagnostic += "📧 Email: \(settings.imapEmail)\n"
    diagnostic += "🔒 Server: \(settings.imapServer)\n"
    diagnostic += "🔑 Password: \(settings.imapPassword.isEmpty ? "Not set" : "Set")\n\n"

    // Check if it's a Gmail account
    let isGmail = settings.isGmailAccount(settings.imapEmail)
    if isGmail {
      diagnostic += "📧 Detected Gmail account\n"
      diagnostic += "For Gmail, you need to:\n"
      diagnostic += "1. Enable 2-factor authentication\n"
      diagnostic += "2. Generate an App Password.\n"
      diagnostic += "3. Use 'imap.gmail.com' as server\n"
      diagnostic += "4. Use port 993 with SSL/TLS\n\n"

      // Validate Gmail settings
      let gmailValidation = validateGmailSettings(
        email: settings.imapEmail,
        password: settings.imapPassword,
        server: settings.imapServer,
      )

      if case .failure(let error) = gmailValidation {
        diagnostic += "❌ Gmail configuration error: \(error.localizedDescription)\n\n"
      } else {
        diagnostic += "✅ Gmail configuration appears valid\n\n"
      }
    }

    // Test IMAP connection
    diagnostic += "🔍 Testing IMAP connection...\n"
    let testResult = await testIMAPConnection(
      email: settings.imapEmail,
      password: settings.imapPassword,
      server: settings.imapServer,
      isGmail: isGmail,
      provider: isGmail ? .gmail : .imap,
    )

    switch testResult {
    case .success(let message):
      diagnostic += "✅ IMAP connection successful: \(message)\n\n"
    case .failure(let error, let provider):
      diagnostic += "❌ \(provider == .gmail ? "Gmail" : "IMAP") connection failed: \(error)\n\n"

      // Provide specific troubleshooting advice
      if error.contains("Invalid email or password") {
        diagnostic += "💡 Troubleshooting:\n"
        if isGmail {
          diagnostic +=
            "- Make sure you're using an App Password, not your regular Gmail password.\n"
          diagnostic += "- Generate a new App Password: Google Account → Security → App passwords\n"
          diagnostic += "- App Password format: xxxx xxxx xxxx xxxx\n"
        } else {
          diagnostic += "- Check your email and password\n"
          diagnostic += "- Make sure your email provider allows IMAP access\n"
          diagnostic += "- Try enabling 2-factor authentication and using an app password.\n"
        }
      } else if error.contains("Connection failed") {
        diagnostic += "💡 Troubleshooting:\n"
        diagnostic += "- Check your internet connection\n"
        diagnostic += "- Verify the IMAP server address is correct\n"
        diagnostic += "- Try different ports: 993 (SSL), 143 (plain), 143 (STARTTLS)\n"
        diagnostic += "- Check if your email provider blocks IMAP connections\n"
      } else if error.contains("timeout") {
        diagnostic += "💡 Troubleshooting:\n"
        diagnostic += "- Check your internet connection\n"
        diagnostic += "- The server might be slow or overloaded\n"
        diagnostic += "- Try again in a few minutes\n"
      }
    }

    diagnostic += "\n=== END DIAGNOSTIC ==="
    return diagnostic
  }

  // MARK: - Notification Methods

  /// Validates Gmail App Password format using centralized validation
  static func validateGmailAppPassword(_ password: String) -> Bool {
    return ValidationService.shared.validateGmailAppPassword(password)
  }

  /// Validates Gmail App Password format with detailed error message
  static func validateGmailAppPasswordWithError(_ password: String) -> (
    isValid: Bool, error: String?
  ) {
    if password.isEmpty {
      return (false, "Gmail App Password cannot be empty")
    }

    if password.count != 19 {
      return (
        false,
        "Gmail App Password must be 19 characters (16 letters + 3 spaces)",
      )
    }

    let pattern = #"^[a-z]{4}\s[a-z]{4}\s[a-z]{4}\s[a-z]{4}$"#
    let regex = try? NSRegularExpression(pattern: pattern)
    let range = NSRange(location: 0, length: password.utf16.count)

    if regex?.firstMatch(in: password, range: range) != nil {
      return (true, nil)
    } else {
      return (
        false,
        "Gmail App Password must be in format: 'xxxx xxxx xxxx xxxx'",
      )
    }
  }

  /**
   Cleans up any resources or cached data used by the EmailService.
   */
  func cleanup() {
    logger.info("🧹 EmailService cleanup called.")
  }

  // MARK: - Keychain Credential Helper

  /// Email credentials structure
  private struct EmailCredentials {
    let email: String
    let password: String
    let server: String
    let port: Int
  }

  /// Retrieves email credentials from KeychainService
  /// - Returns: EmailCredentials if found, else nil
  private func getCredentialsFromKeychain() -> EmailCredentials? {
    let settings = userSettingsManager.userSettings
    let email = settings.imapEmail
    let server = settings.imapServer
    let port = AppConstants.gmailImapPort  // Default IMAP port; adjust if needed
    guard !email.isEmpty, !server.isEmpty else {
      Task { @MainActor in
        self.userFacingError = "Email or server is missing. Please check your settings."
      }
      return nil
    }
    let passwordResult = KeychainService.shared.retrieveEmailPassword(
      email: email, server: server, port: Int(port))
    switch passwordResult {
    case .success(let password):
      Task { @MainActor in self.userFacingError = nil }
      return EmailCredentials(email: email, password: password, server: server, port: Int(port))
    case .failure(let error):
      Task { @MainActor in
        self.userFacingError = error.localizedDescription
        logger.error("❌ Email service error: \(error.localizedDescription, privacy: .private).")
      }
      return nil
    }
  }

  public func searchForVerificationEmails() async throws -> [Email] {
    logger.info("🔍 Searching for verification emails.")

    let settings = userSettingsManager.userSettings
    guard settings.hasEmailConfigured else {
      logger.error("❌ Email settings not configured.")
      throw IMAPError.connectionFailed("Email settings not configured")
    }

    // Use the existing verification code fetching logic
    let verificationCodes = await fetchVerificationCodesForToday(
      since: Date()
        .addingTimeInterval(-900),
    )  // Last 15 minutes

    // Convert verification codes to Email objects
    let emails = verificationCodes.map { code in
      Email(
        id: UUID().uuidString,
        from: AppConstants.verificationEmailFrom,
        subject: AppConstants.verificationEmailSubject,
        body: "Your verification code is: \(code).",
        date: Date(),
      )
    }

    logger.info("✅ Found \(emails.count) verification emails.")
    return emails
  }
}

private final class IMAPConnectionState: @unchecked Sendable {
  var connectionState = "preparing"
  var handshakeCompleted = false
  var authenticationCompleted = false
  var didResume = false
}

/// Helper function to add timeout to async operations
func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async -> T)
  async -> T?
{
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

// Register the singleton for DI
extension EmailService {
  public static func registerForDI() {
    ServiceRegistry.shared.register(EmailService.shared, for: EmailServiceProtocol.self)
  }
}
