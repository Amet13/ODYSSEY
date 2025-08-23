import Foundation
import os.log

protocol EmailParserProtocol {
  func parseVerificationCode(_ email: Email) -> String?
  func parseEmailBody(_ email: Email) -> String
  func extractVerificationCodes(_ emails: [Email]) -> [String]
  func isVerificationEmail(_ email: Email) -> Bool
}

class EmailParser: EmailParserProtocol {
  private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "EmailParser")

  func parseVerificationCode(_ email: Email) -> String? {
    logger.info("🔍 Parsing verification code from email: \(email.subject).")

    // Check if this is a verification email
    guard isVerificationEmail(email) else {
      logger.info("❌ Email is not a verification email.")
      return nil
    }

    // Extract verification code using regex
    let verificationCode = extractVerificationCodeFromText(email.body)

    if let code = verificationCode {
      logger.info("✅ Verification code found: \(code).")
    } else {
      logger.info("❌ No verification code found in email.")
    }

    return verificationCode
  }

  func parseEmailBody(_ email: Email) -> String {
    logger.info("📄 Parsing email body.")

    // Clean up HTML tags if present
    let cleanBody = removeHTMLTags(from: email.body)
    logger.info("✅ Email body parsed successfully.")

    return cleanBody
  }

  func extractVerificationCodes(_ emails: [Email]) -> [String] {
    logger.info("🔍 Extracting verification codes from \(emails.count) emails.")

    let codes = emails.compactMap { email in
      parseVerificationCode(email)
    }

    logger.info("✅ Extracted \(codes.count) verification codes.")
    return codes
  }

  func isVerificationEmail(_ email: Email) -> Bool {
    // Check if email is from verification sender
    let isFromVerificationSender = email.from.contains(AppConstants.verificationEmailFrom)

    // Check if subject contains verification keywords
    let subject = email.subject.lowercased()
    let hasVerificationKeywords =
      subject.contains("verify") || subject.contains("verification") || subject.contains("code")

    // Check if body contains verification code pattern
    let body = email.body.lowercased()
    let hasVerificationPattern =
      body.contains("verification code") || body.contains("your code is") || body.contains("code:")

    return isFromVerificationSender || hasVerificationKeywords || hasVerificationPattern
  }

  // MARK: - Private Methods

  private func extractVerificationCodeFromText(_ text: String) -> String? {
    // Common verification code patterns
    let patterns = [
      "\\b\\d{6}\\b",  // 6-digit code
      "\\b\\d{4}\\b",  // 4-digit code
      "verification code[\\s:]*([A-Z0-9]{4,8})",  // "verification code: ABC123"
      "your code is[\\s:]*([A-Z0-9]{4,8})",  // "your code is ABC123"
      "code[\\s:]*([A-Z0-9]{4,8})",  // "code: ABC123"
    ]

    for pattern in patterns {
      if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        for match in matches {
          if match.numberOfRanges > 1 {
            // Use the captured group
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: text) {
              let code = String(text[swiftRange])
              if isValidVerificationCode(code) {
                return code
              }
            }
          } else {
            // Use the full match
            let range = match.range(at: 0)
            if let swiftRange = Range(range, in: text) {
              let code = String(text[swiftRange])
              if isValidVerificationCode(code) {
                return code
              }
            }
          }
        }
      }
    }

    return nil
  }

  private func isValidVerificationCode(_ code: String) -> Bool {
    // Verification codes are typically 4-8 characters, alphanumeric
    let pattern = "^[A-Z0-9]{4,8}$"
    return code.range(of: pattern, options: .regularExpression) != nil
  }

  private func removeHTMLTags(from text: String) -> String {

    let pattern = "<[^>]+>"
    return text.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
