import Foundation
import os.log

/// Core email service functionality.
/// Handles email testing and verification code management.
@MainActor
public final class EmailCore: ObservableObject {
    // MARK: - Published Properties

    @Published public var isTesting = false
    @Published public var lastTestResult: EmailService.TestResult?

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.odyssey.app", category: "EmailCore")
    private let emailService: EmailService

    // MARK: - Initialization

    public init(emailService: EmailService) {
        self.emailService = emailService
        logger.info("🔧 EmailCore initialized.")
    }

    // MARK: - Public Methods

    /// Resets the service state.
    func reset() {
        isTesting = false
        lastTestResult = nil
        logger.info("🔄 EmailCore service reset.")
    }

    /// Updates the test result.
    /// - Parameter result: The test result to set.
    func updateTestResult(_ result: EmailService.TestResult) {
        lastTestResult = result
        isTesting = false

        if result.isSuccess {
            logger.info("✅ Email test completed successfully.")
        } else {
            logger.error("❌ Email test failed: \(result.description).")
        }
    }

    /// Sets the testing state.
    /// - Parameter testing: Whether the service is currently testing.
    func setTesting(_ testing: Bool) {
        isTesting = testing
        if testing {
            logger.info("🔄 Starting email test.")
        }
    }
}
