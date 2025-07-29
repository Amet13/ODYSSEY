import Foundation
import os.log

@MainActor
public final class EmailGmailSupport {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "EmailGmail")

    // MARK: - Gmail Support

    /**
     * Validates Gmail App Password format and requirements.
     * - Parameter appPassword: The Gmail App Password to validate.
     * - Returns: True if valid, false otherwise.
     */
    public func validateGmailAppPassword(_ appPassword: String) -> Bool {
        logger.info("🔐 Validating Gmail App Password format")

        // Gmail App Password must be 16 characters and contain only letters and numbers
        let appPasswordRegex = "^[A-Za-z0-9]{16}$"
        let isValid = appPassword.range(of: appPasswordRegex, options: .regularExpression) != nil

        if isValid {
            logger.info("✅ Gmail App Password format is valid")
        } else {
            logger.warning("⚠️ Gmail App Password format is invalid")
        }

        return isValid
    }

    /**
     * Checks if the email provider is Gmail.
     * - Parameter email: The email address to check.
     * - Returns: True if Gmail, false otherwise.
     */
    public func isGmailProvider(_ email: String) -> Bool {
        let gmailDomains = ["gmail.com", "googlemail.com"]
        let domain = email.lowercased().split(separator: "@").last ?? ""
        return gmailDomains.contains(String(domain))
    }

    /**
     * Gets Gmail IMAP server configuration.
     * - Returns: Gmail IMAP server settings.
     */
    public func getGmailIMAPConfig() -> (server: String, port: Int, useSSL: Bool) {
        return (
            server: "imap.gmail.com",
            port: 993,
            useSSL: true,
        )
    }

    /**
     * Validates Gmail email settings.
     * - Parameters:
     *   - email: The Gmail email address.
     *   - appPassword: The Gmail App Password.
     * - Returns: Validation result with error message if invalid.
     */
    public func validateGmailSettings(email: String, appPassword: String) -> (isValid: Bool, errorMessage: String?) {
        logger.info("🔍 Validating Gmail settings")

        // Check if it's a Gmail address
        guard isGmailProvider(email) else {
            return (false, "Email must be a Gmail address")
        }

        // Check App Password format
        guard validateGmailAppPassword(appPassword) else {
            return (false, "Gmail App Password must be 16 characters and contain only letters and numbers")
        }

        logger.info("✅ Gmail settings are valid")
        return (true, nil)
    }

    /**
     * Provides Gmail App Password setup instructions.
     * - Returns: Instructions for setting up Gmail App Password.
     */
    public func getGmailAppPasswordInstructions() -> String {
        return """
        To set up Gmail App Password:

        1. Go to your Google Account settings
        2. Navigate to Security > 2-Step Verification
        3. Scroll down to "App passwords"
        4. Generate a new app password for "Mail"
        5. Use the 16-character password (no spaces)
        6. Enable IMAP in Gmail settings

        Note: Regular Gmail password won't work with IMAP.
        """
    }
}
