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
    return ValidationService.shared.validateGmailAppPassword(appPassword)
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
}
