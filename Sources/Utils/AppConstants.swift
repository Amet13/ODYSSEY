import Foundation

// MARK: - Application Constants

/// Centralized constants for the ODYSSEY application
enum AppConstants {
    // MARK: - Application Info

    static let appName = "ODYSSEY"
    static let appVersion = "1.0.0"
    static let appBundleId = "com.odyssey.app"

    // MARK: - Timeouts

    static let defaultTimeout: TimeInterval = 30.0
    static let pageLoadTimeout: TimeInterval = 15.0
    static let elementWaitTimeout: TimeInterval = 10.0
    static let imapConnectionTimeout: TimeInterval = 30.0
    static let verificationCodeTimeout: TimeInterval = 300.0 // 5 minutes

    // MARK: - Delays

    static let minHumanDelay: TimeInterval = 0.5
    static let maxHumanDelay: TimeInterval = 0.9
    static let typingDelay: TimeInterval = 0.12
    static let pageTransitionDelay: TimeInterval = 1.2

    // MARK: - Email Configuration

    static let gmailImapServer = "imap.gmail.com"
    static let gmailImapPort: UInt16 = 993
    static let defaultImapPort: UInt16 = 993
    static let verificationEmailFrom = "noreply@frontdesksuite.com"
    static let verificationEmailSubject = "Verify your email"

    // MARK: - WebKit Configuration

    static let webKitWindowWidth = 1_440
    static let webKitWindowHeight = 900
    static let webKitDebugWindowX: CGFloat = 200
    static let webKitDebugWindowY: CGFloat = 200

    // MARK: - User Agent Strings

    static let userAgents = [
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
            "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
            "(KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
            "(KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 " +
            "(KHTML, like Gecko) Version/17.1 Safari/605.1.15",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 " +
            "(KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    ]

    // MARK: - Window Sizes

    static let windowSizes = [
        (width: 1_440, height: 900), // MacBook Air 13"
        (width: 1_680, height: 1_050) // MacBook Pro 15"
    ]

    // MARK: - Sports Keywords

    static let sportsKeywords = [
        "basketball",
        "volleyball",
        "badminton",
        "tennis",
        "soccer",
        "hockey",
        "swimming",
        "fitness",
        "gym",
        "sport"
    ]

    // MARK: - Supported Languages

    static let supportedLanguages = [
        "en": "English"
    ]

    // MARK: - URLs

    static let ottawaFacilitiesURL = "https://ottawa.ca/en/recreation-and-parks/recreation-facilities"
    static let gmailAppPasswordURL = "https://support.google.com/accounts/answer/185833"
    static let githubURL = "https://github.com/Amet13/ODYSSEY"

    // MARK: - UserDefaults Keys

    static let lastRunInfoKey = "ReservationManager.lastRunInfo"
    static let userSettingsKey = "UserSettingsManager.userSettings"
    static let configurationsKey = "ConfigurationManager.configurations"

    // MARK: - Logging Categories

    static let loggingSubsystem = "com.odyssey.app"
    static let loggingCategories = [
        "AppDelegate",
        "WebKitService",
        "ReservationManager",
        "EmailService",
        "ConfigurationManager",
        "UserSettingsManager",
        "FacilityService",
        "StatusBarController"
    ]

    // MARK: - Error Messages

    static let errorMessages = [
        "incompleteEmailSettings": "Incomplete email settings",
        "webKitNotInitialized": "WebKit service not initialized",
        "navigationFailed": "Failed to navigate to reservation page",
        "elementNotFound": "Required element not found on page",
        "timeout": "Operation timed out",
        "connectionFailed": "Connection failed",
        "authenticationFailed": "Authentication failed"
    ]

    // MARK: - Validation Patterns

    static let patterns = [
        "gmailAppPassword": "^[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}$",
        "verificationCode": "\\b\\d{4}\\b",
        "phoneNumber": "^\\+?[1-9]\\d{1,14}$",
        "email": "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    ]
}
