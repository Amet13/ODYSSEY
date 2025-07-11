import Foundation

/// User settings and configuration data for ODYSSEY
///
/// Stores personal information needed for reservations and notifications
/// including contact details, email settings, and optional Telegram integration
struct UserSettings: Codable {
    // Contact Information
    var phoneNumber: String = ""
    var name: String = ""

    // Email/IMAP Settings
    var imapEmail: String = ""
    var imapPassword: String = ""
    var imapServer: String = ""

    // Telegram Integration (Optional)
    var telegramEnabled: Bool = false
    var telegramBotToken: String = ""
    var telegramChatId: String = ""

    // Validation
    var isValid: Bool {
        !phoneNumber.isEmpty && !name.isEmpty && !imapEmail.isEmpty && !imapPassword.isEmpty && !imapServer.isEmpty &&
            isPhoneNumberValid && isEmailValid
    }

    var hasTelegramConfigured: Bool {
        telegramEnabled && !telegramBotToken.isEmpty && !telegramChatId.isEmpty
    }

    var hasEmailConfigured: Bool {
        !imapEmail.isEmpty && !imapPassword.isEmpty && !imapServer.isEmpty && isEmailValid
    }

    // Phone number validation (10 digits)
    var isPhoneNumberValid: Bool {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleaned.count == 10
    }

    // Email validation
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: imapEmail)
    }

    // Telegram bot token validation (format: number:letters)
    var isTelegramBotTokenValid: Bool {
        let tokenRegex = "^[0-9]+:[A-Za-z0-9_-]+$"
        let tokenPredicate = NSPredicate(format: "SELF MATCHES %@", tokenRegex)
        return tokenPredicate.evaluate(with: telegramBotToken)
    }

    // Telegram chat ID validation (numbers only)
    var isTelegramChatIdValid: Bool {
        let cleaned = telegramChatId.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleaned == telegramChatId && !cleaned.isEmpty
    }

    // Helper methods
    func getFormattedPhoneNumber() -> String {
        // Basic phone number formatting
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if cleaned.count == 10 {
            return "(\(cleaned.prefix(3))) \(cleaned.dropFirst(3).prefix(3))-\(cleaned.dropFirst(6))"
        }
        return phoneNumber
    }

    func getEmailDomain() -> String {
        let components = imapEmail.components(separatedBy: "@")
        return components.count > 1 ? components[1] : ""
    }
}
