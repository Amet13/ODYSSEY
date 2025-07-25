import Foundation

// MARK: - Application Constants

/// Centralized constants for the ODYSSEY application
/**
 AppConstants provides centralized static constants for configuration, timeouts, URLs, and more.

 ## Usage Example
 ```swift
 let timeout = AppConstants.defaultTimeout
 let version = AppConstants.appVersion
 let facilityURL = AppConstants.ottawaFacilitiesURL
 let errorMsg = AppConstants.errorMessages["timeout"]
 let pattern = AppConstants.patterns["email"]
 ```
 */
public enum AppConstants {
    // MARK: - Application Info

    /// The application name
    static let appName = "ODYSSEY"
    /// The current app version
    static let appVersion = "1.0.0"
    /// The app bundle identifier
    static let appBundleId = "com.odyssey.app"

    // MARK: - Timeouts

    /// Default timeout for general operations (seconds)
    static let defaultTimeout: TimeInterval = 30.0
    /// Timeout for page loads (seconds)
    static let pageLoadTimeout: TimeInterval = 15.0
    /// Timeout for waiting for elements (seconds)
    static let elementWaitTimeout: TimeInterval = 10.0
    /// Timeout for IMAP connection (seconds)
    static let imapConnectionTimeout: TimeInterval = 30.0
    /// Timeout for email verification code (seconds)
    static let verificationCodeTimeout: TimeInterval = 300.0 // 5 minutes

    // MARK: - Delays

    /// Minimum human-like delay (seconds)
    static let minHumanDelay: TimeInterval = 0.5
    /// Maximum human-like delay (seconds)
    static let maxHumanDelay: TimeInterval = 0.9
    /// Typing delay per character (seconds)
    static let typingDelay: TimeInterval = 0.12
    /// Delay for page transitions (seconds)
    static let pageTransitionDelay: TimeInterval = 1.2

    // MARK: - Email Configuration

    /// Default Gmail IMAP server
    static let gmailImapServer = "imap.gmail.com"
    /// Default Gmail IMAP port
    static let gmailImapPort: UInt16 = 993
    /// Default IMAP port
    static let defaultImapPort: UInt16 = 993
    /// Expected sender for verification emails
    static let verificationEmailFrom = "noreply@frontdesksuite.com"
    /// Expected subject for verification emails
    static let verificationEmailSubject = "Verify your email"

    // MARK: - WebKit Configuration

    /// Default width for WebKit browser window
    static let webKitWindowWidth = 1_440
    /// Default height for WebKit browser window
    static let webKitWindowHeight = 900
    /// Default X position for WebKit browser window
    static let webKitDebugWindowX: CGFloat = 200
    /// Default Y position for WebKit browser window
    static let webKitDebugWindowY: CGFloat = 200

    // MARK: - User Agent Strings

    // (User agent constants can be added here)

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

    public static let ottawaFacilitiesURL = "https://ottawa.ca/en/recreation-and-parks/facilities"
    public static let gmailAppPasswordURL = "https://support.google.com/accounts/answer/185833"
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

/**
 AppConstants extension for window and icon sizes.

 ## Usage Example
 ```swift
 let mainWidth = AppConstants.windowMainWidth
 let iconLarge = AppConstants.iconLarge
 ```
 */
extension AppConstants {
    // MARK: - Window Sizes

    static let windowMainWidth: CGFloat = 440
    static let windowMainHeight: CGFloat = 600
    static let windowAboutWidth: CGFloat = 380
    static let windowAboutHeight: CGFloat = 380
    static let windowDayPickerWidth: CGFloat = 380
    static let windowDayPickerHeight: CGFloat = 380
    static let windowDeleteModalWidth: CGFloat = 340

    // MARK: - Icon Sizes

    static let iconLarge: CGFloat = 64
    static let iconSmall: CGFloat = 14

    // MARK: - Standardized Padding System

    /// Standard horizontal padding for main content areas
    static let paddingHorizontal: CGFloat = 20
    /// Standard horizontal padding for configuration forms
    static let paddingHorizontalForm: CGFloat = 32
    /// Standard horizontal padding for settings content
    static let paddingHorizontalSettings: CGFloat = 16
    /// Standard vertical padding for sections
    static let paddingVertical: CGFloat = 16
    /// Standard vertical padding for forms
    static let paddingVerticalForm: CGFloat = 24
    /// Standard vertical padding for small elements
    static let paddingVerticalSmall: CGFloat = 8
    /// Standard vertical padding for tiny elements
    static let paddingVerticalTiny: CGFloat = 4
    /// Standard padding for dividers
    static let paddingDivider: CGFloat = 4
    /// Standard padding for buttons
    static let paddingButton: CGFloat = 12
    /// Standard padding for overlays
    static let paddingOverlay: CGFloat = 24
}
