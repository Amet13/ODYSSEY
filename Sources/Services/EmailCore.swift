import Foundation
import Network
import os.log

/// Core email service functionality
/// Handles basic email operations, enums, and data structures
@MainActor
class EmailCore: ObservableObject {
    // MARK: - Published Properties

    @Published var isTesting = false
    @Published var lastTestResult: TestResult?

    // MARK: - Core Properties

    let logger = Logger(subsystem: "com.odyssey.app", category: "EmailCore")
    let userSettingsManager = UserSettingsManager.shared

    // Shared code pool for managing verification codes across multiple instances
    private let sharedCodePool = SimpleVerificationCodePool()

    // Add a static variable to track last connection attempt time
    private static var lastIMAPConnectionTimestamp: Date?

    // MARK: - Initialization

    private init() { }

    // MARK: - Core Enums

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
            case let .connectionFailed(message): "Connection failed: \(message)"
            case let .authenticationFailed(message): "Authentication failed: \(message)"
            case let .commandFailed(message): "Command failed: \(message)"
            case let .invalidResponse(message): "Invalid response: \(message)"
            case let .timeout(message): "Connection timeout: \(message)"
            case let .unsupportedServer(message): "Unsupported server: \(message)"
            case let .gmailAppPasswordRequired(message): "Gmail App Password required: \(message)"
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
                let prefix = provider == .gmail ? "Gmail test failed:" : "IMAP test failed:"
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

    // MARK: - Data Structures

    /// Represents an email message
    struct EmailMessage {
        let id: String
        let from: String
        let subject: String
        let body: String
        let date: Date
    }

    // MARK: - Public Methods

    /// Gets the shared code pool for verification codes
    var verificationCodePool: SimpleVerificationCodePool {
        return sharedCodePool
    }

    /// Gets the last IMAP connection timestamp
    static var lastConnectionTimestamp: Date? {
        return lastIMAPConnectionTimestamp
    }

    /// Sets the last IMAP connection timestamp
    static func setLastConnectionTimestamp(_ timestamp: Date) {
        lastIMAPConnectionTimestamp = timestamp
    }

    /// Resets the service state
    func reset() {
        isTesting = false
        lastTestResult = nil
        logger.info("🔄 EmailCore service reset.")
    }

    /// Updates the test result
    /// - Parameter result: The test result to set
    func updateTestResult(_ result: TestResult) {
        lastTestResult = result
        isTesting = false

        if result.isSuccess {
            logger.info("✅ Email test completed successfully.")
        } else {
            logger.error("❌ Email test failed: \(result.description)")
        }
    }

    /// Sets the testing state
    /// - Parameter testing: Whether the service is currently testing
    func setTesting(_ testing: Bool) {
        isTesting = testing
        if testing {
            logger.info("🔄 Starting email test.")
        }
    }
}

// MARK: - Simple Verification Code Pool

/// Simple verification code pool for email verification
final class SimpleVerificationCodePool: @unchecked Sendable {
    private var codes: [String: (code: String, timestamp: Date)] = [:]
    private let queue = DispatchQueue(label: "com.odyssey.email.simplecodepool", attributes: .concurrent)
    private let logger = Logger(subsystem: "com.odyssey.app", category: "SimpleVerificationCodePool")

    /// Adds a verification code for a specific email
    /// - Parameters:
    ///   - email: The email address
    ///   - code: The verification code
    func addCode(for email: String, code: String) {
        queue.async(flags: .barrier) {
            self.codes[email] = (code: code, timestamp: Date())
            self.logger.info("📧 Added verification code for \(email, privacy: .private)")
        }
    }

    /// Gets a verification code for a specific email
    /// - Parameter email: The email address
    /// - Returns: The verification code if found and not expired
    func getCode(for email: String) -> String? {
        return queue.sync {
            guard let entry = codes[email] else { return nil }

            // Check if code is expired (5 minutes)
            let expirationTime: TimeInterval = 300 // 5 minutes
            if Date().timeIntervalSince(entry.timestamp) > expirationTime {
                codes.removeValue(forKey: email)
                logger.info("⏰ Verification code expired for \(email, privacy: .private)")
                return nil
            }

            logger.info("📧 Retrieved verification code for \(email, privacy: .private)")
            return entry.code
        }
    }

    /// Removes a verification code for a specific email
    /// - Parameter email: The email address
    func removeCode(for email: String) {
        queue.async(flags: .barrier) {
            self.codes.removeValue(forKey: email)
            self.logger.info("🧹 Removed verification code for \(email, privacy: .private)")
        }
    }

    /// Clears all verification codes
    func clearAllCodes() {
        queue.async(flags: .barrier) {
            self.codes.removeAll()
            self.logger.info("🧹 Cleared all verification codes.")
        }
    }

    /// Gets the count of active verification codes
    var activeCodeCount: Int {
        return queue.sync {
            return codes.count
        }
    }
}
