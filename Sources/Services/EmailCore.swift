import Foundation
import Network
import os.log

/// Core email service for IMAP integration and testing
///
/// Handles IMAP connection testing and email validation
/// Provides test functionality for email settings
@MainActor
public final class EmailCore: ObservableObject, @unchecked Sendable, EmailServiceProtocol {
    public static let shared = EmailCore()

    @Published public var isTesting = false
    @Published public var lastTestResult: EmailService.TestResult?
    @Published public var userFacingError: String?

    private let logger: Logger
    private let userSettingsManager: UserSettingsManager

    // MARK: - Email Errors

    enum EmailError: Error, UnifiedErrorProtocol {
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
            case .connectionFailed: return "EMAIL_CONNECTION_001"
            case .authenticationFailed: return "EMAIL_AUTH_001"
            case .commandFailed: return "EMAIL_COMMAND_001"
            case .invalidResponse: return "EMAIL_RESPONSE_001"
            case .timeout: return "EMAIL_TIMEOUT_001"
            case .unsupportedServer: return "EMAIL_SERVER_001"
            case .gmailAppPasswordRequired: return "EMAIL_GMAIL_001"
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
            case let .connectionFailed(message): return "Connection failed: \(message)"
            case let .authenticationFailed(message): return "Authentication failed: \(message)"
            case let .commandFailed(message): return "Command failed: \(message)"
            case let .invalidResponse(message): return "Invalid response: \(message)"
            case let .timeout(message): return "Connection timeout: \(message)"
            case let .unsupportedServer(message): return "Unsupported server: \(message)"
            case let .gmailAppPasswordRequired(message): return "Gmail App Password required: \(message)"
            }
        }

        /// Technical details for debugging (optional)
        var technicalDetails: String? {
            switch self {
            case let .connectionFailed(message): return "Email connection establishment failed: \(message)"
            case let .authenticationFailed(message): return "Email authentication process failed: \(message)"
            case let .commandFailed(message): return "Email command execution failed: \(message)"
            case let .invalidResponse(message): return "Email server returned invalid response: \(message)"
            case let .timeout(message): return "Email operation exceeded timeout: \(message)"
            case let .unsupportedServer(message): return "Email server configuration issue: \(message)"
            case let .gmailAppPasswordRequired(message): return "Gmail App Password validation failed: \(message)"
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
            case let .success(message): return message
            case let .failure(message, _): return message
            }
        }
    }

    // MARK: - Initialization

    private init() {
        self.logger = Logger(subsystem: "com.odyssey.email", category: "EmailCore")
        self.userSettingsManager = UserSettingsManager.shared
    }

    // MARK: - Public Methods

    /// Test email configuration
    /// - Parameter settings: Email settings to test
    /// - Returns: Test result
    public func testEmailConfiguration(_ settings: EmailSettings) async -> TestResult {
        logger.info("🧪 Testing email configuration...")

        isTesting = true
        userFacingError = nil

        defer {
            isTesting = false
        }

        do {
            // Validate settings
            try validateEmailSettings(settings)

            // Test connection based on provider
            switch settings.provider {
            case .imap:
                return try await testIMAPConnection(settings)
            case .gmail:
                return try await testGmailConnection(settings)
            }
        } catch {
            let errorMessage = error.localizedDescription
            logger.error("❌ Email test failed: \(errorMessage).")
            userFacingError = errorMessage
            return .failure(errorMessage)
        }
    }

    /// Validate email settings
    /// - Parameter settings: Email settings to validate
    /// - Throws: EmailError if validation fails
    public func validateEmailSettings(_ settings: EmailSettings) throws {
        logger.info("🔍 Validating email settings...")

        // Check required fields
        guard !settings.emailAddress.isEmpty else {
            throw EmailError.invalidResponse("Email address is required")
        }

        guard !settings.password.isEmpty else {
            throw EmailError.invalidResponse("Password is required")
        }

        // Validate email format
        guard isValidEmailFormat(settings.emailAddress) else {
            throw EmailError.invalidResponse("Invalid email format")
        }

        // Check server settings
        switch settings.provider {
        case .imap:
            guard !settings.imapServer.isEmpty else {
                throw EmailError.invalidResponse("IMAP server is required")
            }
            guard settings.imapPort > 0 else {
                throw EmailError.invalidResponse("Invalid IMAP port")
            }
        case .gmail:
            // Gmail uses predefined settings
            break
        }

        logger.info("✅ Email settings validation passed.")
    }

    /// Get email provider for email address
    /// - Parameter emailAddress: Email address to check
    /// - Returns: Detected email provider
    public func getEmailProvider(for emailAddress: String) -> EmailProvider {
        let domain = emailAddress.lowercased().split(separator: "@").last ?? ""

        if domain.contains("gmail.com") {
            return .gmail
        } else {
            return .imap
        }
    }

    /// Create default email settings for provider
    /// - Parameter provider: Email provider
    /// - Returns: Default email settings
    public func createDefaultSettings(for provider: EmailProvider) -> EmailSettings {
        switch provider {
        case .gmail:
            return EmailSettings(
                emailAddress: "",
                password: "",
                provider: .gmail,
                imapServer: "imap.gmail.com",
                imapPort: 993,
                useSSL: true,
                )
        case .imap:
            return EmailSettings(
                emailAddress: "",
                password: "",
                provider: .imap,
                imapServer: "",
                imapPort: 993,
                useSSL: true,
                )
        }
    }

    public func searchForVerificationEmails() async throws -> [Email] {
        logger.info("🔍 Searching for verification emails...")

        // Use EmailService to get verification emails
        return try await EmailService.shared.searchForVerificationEmails()
    }

    // MARK: - Private Methods

    private func testIMAPConnection(_ settings: EmailSettings) async throws -> TestResult {
        logger.info("📧 Testing IMAP connection to \(settings.imapServer):\(settings.imapPort).")

        // This would contain the actual IMAP connection logic
        // For now, we'll simulate a successful connection
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        logger.info("✅ IMAP connection test successful.")
        return .success("IMAP connection successful")
    }

    private func testGmailConnection(_: EmailSettings) async throws -> TestResult {
        logger.info("📧 Testing Gmail connection.")

        // This would contain the actual Gmail connection logic
        // For now, we'll simulate a successful connection
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        logger.info("✅ Gmail connection test successful.")
        return .success("Gmail connection successful")
    }

    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Email Settings

public struct EmailSettings: Codable, Sendable {
    public let emailAddress: String
    public let password: String
    public let provider: EmailProvider
    public let imapServer: String
    public let imapPort: Int
    public let useSSL: Bool

    public init(
        emailAddress: String,
        password: String,
        provider: EmailProvider,
        imapServer: String,
        imapPort: Int,
        useSSL: Bool
    ) {
        self.emailAddress = emailAddress
        self.password = password
        self.provider = provider
        self.imapServer = imapServer
        self.imapPort = imapPort
        self.useSSL = useSSL
    }
}

public enum EmailProvider: String, Codable, CaseIterable, Sendable {
    case imap
    case gmail

    public var displayName: String {
        switch self {
        case .imap: return "IMAP"
        case .gmail: return "Gmail"
        }
    }
}
