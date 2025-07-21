import Foundation

/// User settings and configuration data for ODYSSEY
///
/// Stores personal information needed for reservations and notifications
/// including contact details, email settings, and optional Telegram integration
struct UserSettings: Codable, Equatable {
    // Contact Information
    var phoneNumber: String = ""
    var name: String = ""

    // Email Provider Type
    enum EmailProvider: String, CaseIterable, Identifiable, Codable {
        case imap = "IMAP"
        case gmail = "Gmail"
        var id: String { rawValue }
    }

    var emailProvider: EmailProvider = .imap

    // Email/IMAP Settings
    var imapEmail: String = ""
    var imapPassword: String = ""
    var imapServer: String = ""

    // Language - English only
    enum Language: String, CaseIterable, Identifiable, Codable {
        case english = "English"
        var id: String { rawValue }
    }

    var language: Language = .english

    var locale: Locale {
        return Locale(identifier: "en")
    }

    var preventSleepForAutorun: Bool = true // New setting: default to true for safety

    // MARK: - Equatable

    static func == (lhs: UserSettings, rhs: UserSettings) -> Bool {
        lhs.phoneNumber == rhs.phoneNumber &&
            lhs.name == rhs.name &&
            lhs.emailProvider == rhs.emailProvider &&
            lhs.imapEmail == rhs.imapEmail &&
            lhs.imapPassword == rhs.imapPassword &&
            lhs.imapServer == rhs.imapServer &&
            lhs.language == rhs.language
    }

    // MARK: - Validation

    // Phone number validation (10 digits)
    var isPhoneNumberValid: Bool {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleaned.count == 10
    }

    // Email validation
    var isEmailValid: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return imapEmail.range(of: emailRegex, options: .regularExpression) != nil
    }

    // IMAP server validation (non-empty)
    var isImapServerValid: Bool {
        !imapServer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // IMAP password validation (non-empty)
    var isImapPasswordValid: Bool {
        !imapPassword.isEmpty
    }

    // Gmail email validation
    var isGmailEmailValid: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return imapEmail.range(of: emailRegex, options: .regularExpression) != nil
    }

    // Gmail app password validation (16 characters with spaces every 4)
    var isGmailAppPasswordValid: Bool {
        let pattern = #"^[a-z]{4} [a-z]{4} [a-z]{4} [a-z]{4}$"#
        return imapPassword.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Helper Properties

    // Overall validation
    var isValid: Bool {
        !phoneNumber.isEmpty && !name.isEmpty && hasEmailConfigured && isPhoneNumberValid && isEmailValid
    }

    // Email configuration check
    var hasEmailConfigured: Bool {
        let isGmail = isGmailAccount(imapEmail)
        if isGmail {
            return !imapEmail.isEmpty && !imapPassword.isEmpty && isGmailEmailValid && isGmailAppPasswordValid
        } else {
            return !imapEmail.isEmpty && !imapPassword.isEmpty && !imapServer.isEmpty && isEmailValid
        }
    }

    // Current email (always use imapEmail)
    var currentEmail: String {
        return imapEmail
    }

    // Current password (always use imapPassword)
    var currentPassword: String {
        return imapPassword
    }

    // Current server (auto-detect for Gmail)
    var currentServer: String {
        if isGmailAccount(imapEmail) {
            return "imap.gmail.com"
        }
        return imapServer
    }

    // Helper function to detect Gmail accounts
    func isGmailAccount(_ email: String) -> Bool {
        let domain = email.components(separatedBy: "@").last?.lowercased() ?? ""
        return domain == "gmail.com" || domain.hasSuffix(".gmail.com")
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
