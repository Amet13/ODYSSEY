import Foundation

/// User settings and configuration data for ODYSSEY
///
/// Stores personal information needed for reservations and notifications
/// including contact details, email settings, and optional Telegram integration
public struct UserSettings: Codable, Equatable, Sendable {
  public var phoneNumber: String = ""
  public var name: String = ""

  // Email Provider Type
  public enum EmailProvider: String, CaseIterable, Identifiable, Codable, Sendable {
    case imap = "IMAP"
    case gmail = "Gmail"
    public var id: String { rawValue }
  }

  public var emailProvider: EmailProvider = .imap

  // Email/IMAP Settings
  public var imapEmail: String = ""
  public var imapPassword: String = ""
  public var imapServer: String = ""

  // Language - English only
  public enum Language: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "English"
    public var id: String { rawValue }
  }

  public var language: Language = .english

  public var locale: Locale {
    return Locale(identifier: "en")
  }

  public var autoCloseDebugWindowOnFailure = false  // Default to false to show errors by default
  public var showBrowserWindow = false  // Default to false (invisible automation)

  // Custom autorun time settings
  public var useCustomAutorunTime = false  // Default to false (use 6:00 PM)
  public var customAutorunTime: Date = {
    let calendar = Calendar.current
    let now = Date()
    return calendar.date(
      bySettingHour: AppConstants.defaultAutorunHour,
      minute: AppConstants.defaultAutorunMinute,
      second: 0,
      of: now,
    ) ?? now
  }()

  // Custom prior days before reservation (God Mode / debugging)
  public var useCustomPriorDays = false  // Default to false (use 2 days prior)
  public var customPriorDays: Int = 2  // Default matches app behavior

  // MARK: - Notification Settings

  /// Whether to show notifications for reservation events
  public var showNotifications: Bool = true

  // MARK: - Equatable

  public static func == (lhs: UserSettings, rhs: UserSettings) -> Bool {
    lhs.phoneNumber == rhs.phoneNumber && lhs.name == rhs.name
      && lhs.emailProvider == rhs.emailProvider && lhs.imapEmail == rhs.imapEmail
      && lhs.imapPassword == rhs.imapPassword && lhs.imapServer == rhs.imapServer
      && lhs.language == rhs.language

      && lhs.autoCloseDebugWindowOnFailure == rhs.autoCloseDebugWindowOnFailure
      && lhs.showBrowserWindow == rhs.showBrowserWindow
      && lhs.useCustomAutorunTime == rhs.useCustomAutorunTime
      && lhs.customAutorunTime == rhs.customAutorunTime
      && lhs.useCustomPriorDays == rhs.useCustomPriorDays
      && lhs.customPriorDays == rhs.customPriorDays
      && lhs.showNotifications == rhs.showNotifications
  }

  // MARK: - Validation

  // Phone number validation (10 digits)
  public var isPhoneNumberValid: Bool {
    let cleaned = phoneNumber.replacingOccurrences(
      of: "[^0-9]", with: "", options: .regularExpression)
    return cleaned.count == 10
  }

  // Email validation
  public var isEmailValid: Bool {
    let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    return imapEmail.range(of: emailRegex, options: .regularExpression) != nil
  }

  // IMAP server validation (non-empty)
  public var isImapServerValid: Bool {
    !imapServer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  // IMAP password validation (non-empty)
  public var isImapPasswordValid: Bool {
    !imapPassword.isEmpty
  }

  // Gmail email validation
  public var isGmailEmailValid: Bool {
    let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    return imapEmail.range(of: emailRegex, options: .regularExpression) != nil
  }

  // Gmail app password validation (16 characters with spaces every 4)
  public var isGmailAppPasswordValid: Bool {
    let pattern = #"^[a-z]{4} [a-z]{4} [a-z]{4} [a-z]{4}$"#
    return imapPassword.range(of: pattern, options: .regularExpression) != nil
  }

  // MARK: - Helper Properties

  // Overall validation
  public var isValid: Bool {
    !phoneNumber.isEmpty && !name.isEmpty && hasEmailConfigured && isPhoneNumberValid
      && isEmailValid
  }

  // Email configuration check
  public var hasEmailConfigured: Bool {
    let isGmail = isGmailAccount(imapEmail)
    if isGmail {
      return !imapEmail.isEmpty && !imapPassword.isEmpty && isGmailEmailValid
        && isGmailAppPasswordValid
    } else {
      return !imapEmail.isEmpty && !imapPassword.isEmpty && !imapServer.isEmpty && isEmailValid
    }
  }

  // Current email (always use imapEmail)
  public var currentEmail: String {
    return imapEmail
  }

  // Current password (always use imapPassword)
  public var currentPassword: String {
    return imapPassword
  }

  // Current server (auto-detect for Gmail)
  public var currentServer: String {
    if isGmailAccount(imapEmail) {
      return "imap.gmail.com"
    }
    return imapServer
  }

  // Helper function to detect Gmail accounts
  public func isGmailAccount(_ email: String) -> Bool {
    let domain = email.components(separatedBy: "@").last?.lowercased() ?? ""
    return domain == "gmail.com" || domain.hasSuffix(".gmail.com")
  }

  // Helper methods
  public func getFormattedPhoneNumber() -> String {

    let cleaned = phoneNumber.replacingOccurrences(
      of: "[^0-9]", with: "", options: .regularExpression)
    if cleaned.count == 10 {
      return "(\(cleaned.prefix(3))) \(cleaned.dropFirst(3).prefix(3))-\(cleaned.dropFirst(6))"
    }
    return phoneNumber
  }

  public func getEmailDomain() -> String {
    let components = imapEmail.components(separatedBy: "@")
    return components.count > 1 ? components[1] : ""
  }
}
