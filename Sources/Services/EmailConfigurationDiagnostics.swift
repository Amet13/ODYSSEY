import Foundation
import os.log

@MainActor
public final class EmailConfigurationDiagnostics {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "EmailDiagnostics")

    // MARK: - Email Configuration Diagnostics

    /**
     * Performs comprehensive email configuration diagnostics.
     * - Parameter settings: The email settings to diagnose.
     * - Returns: Diagnostic results with issues and recommendations.
     */
    public func performEmailDiagnostics(settings: EmailSettings) -> EmailDiagnosticResult {
        logger.info("🔍 Performing email configuration diagnostics.")

        var issues: [String] = []
        var recommendations: [String] = []

        // Check email format
        if !isValidEmailFormat(settings.emailAddress) {
            issues.append("Invalid email format")
            recommendations.append("Enter a valid email address")
        }

        // Check server configuration
        if settings.imapServer.isEmpty {
            issues.append("IMAP server not configured")
            recommendations.append("Enter your email provider's IMAP server")
        }

        // Check port configuration
        if settings.imapPort <= 0 {
            issues.append("Invalid IMAP port")
            recommendations.append("Enter a valid port number (usually 993 for SSL, 143 for non-SSL)")
        }

        // Check password
        if settings.password.isEmpty {
            issues.append("Password not configured")
            recommendations.append("Enter your email password or App Password")
        }

        // Gmail-specific checks
        if isGmailProvider(settings.emailAddress) {
            if !isValidGmailAppPassword(settings.password) {
                issues.append("Invalid Gmail App Password format")
                recommendations.append("Use a 16-character App Password from Google Account settings")
            }
        }

        let severity: DiagnosticSeverity = issues.isEmpty ? .success : .warning
        let isHealthy = issues.isEmpty

        logger.info("✅ Email diagnostics completed - \(issues.count) issues found.")

        return EmailDiagnosticResult(
            isHealthy: isHealthy,
            severity: severity,
            issues: issues,
            recommendations: recommendations,
        )
    }

    /**
     * Validates email format.
     * - Parameter email: The email address to validate.
     * - Returns: True if valid format, false otherwise.
     */
    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    /**
     * Checks if the email provider is Gmail.
     * - Parameter email: The email address to check.
     * - Returns: True if Gmail, false otherwise.
     */
    private func isGmailProvider(_ email: String) -> Bool {
        let gmailDomains = ["gmail.com", "googlemail.com"]
        let domain = email.lowercased().split(separator: "@").last ?? ""
        return gmailDomains.contains(String(domain))
    }

    /**
     * Validates Gmail App Password format.
     * - Parameter password: The password to validate.
     * - Returns: True if valid Gmail App Password format, false otherwise.
     */
    private func isValidGmailAppPassword(_ password: String) -> Bool {
        let appPasswordRegex = "^[A-Za-z0-9]{16}$"
        return password.range(of: appPasswordRegex, options: .regularExpression) != nil
    }
}

// MARK: - Supporting Types

public struct EmailDiagnosticResult {
    public let isHealthy: Bool
    public let severity: DiagnosticSeverity
    public let issues: [String]
    public let recommendations: [String]

    public init(isHealthy: Bool, severity: DiagnosticSeverity, issues: [String], recommendations: [String]) {
        self.isHealthy = isHealthy
        self.severity = severity
        self.issues = issues
        self.recommendations = recommendations
    }
}

public enum DiagnosticSeverity {
    case success
    case warning
    case error
}
