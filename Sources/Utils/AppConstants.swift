import Foundation

public enum AppConstants {
    static let appName = "ODYSSEY"
    static let appVersion = "1.0.0"
    static let appBundleId = "com.odyssey.app"
    static let defaultTimeout: TimeInterval = 30.0
    static let pageLoadTimeout: TimeInterval = 15.0
    static let elementWaitTimeout: TimeInterval = 10.0
    static let imapConnectionTimeout: TimeInterval = 30.0
    static let verificationCodeTimeout: TimeInterval = 300.0
    static let minHumanDelay: TimeInterval = 0.5
    static let maxHumanDelay: TimeInterval = 0.9
    static let typingDelay: TimeInterval = 0.12
    static let pageTransitionDelay: TimeInterval = 1.2
    static let gmailImapServer = "imap.gmail.com"
    static let gmailImapPort: UInt16 = 993
    static let defaultImapPort: UInt16 = 993
    static let verificationEmailFrom = "noreply@frontdesksuite.com"
    static let verificationEmailSubject = "Verify your email"
    static let webKitWindowWidth = 1_440
    static let webKitWindowHeight = 900
    static let webKitDebugWindowX: CGFloat = 200
    static let webKitDebugWindowY: CGFloat = 200
    static let windowSizes = [(width: 1_440, height: 900), (width: 1_680, height: 1_050)]
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
    static let supportedLanguages = ["en": "English"]
    public static let ottawaFacilitiesURL = "https://ottawa.ca/en/recreation-and-parks/facilities"
    public static let gmailAppPasswordURL = "https://support.google.com/accounts/answer/185833"
    static let githubURL = "https://github.com/Amet13/ODYSSEY"
    static let lastRunInfoKey = "ReservationManager.lastRunInfo"
    static let userSettingsKey = "UserSettingsManager.userSettings"
    static let configurationsKey = "ConfigurationManager.configurations"
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
    static let errorMessages = [
        "incompleteEmailSettings": "Incomplete email settings",
        "webKitNotInitialized": "WebKit service not initialized",
        "navigationFailed": "Failed to navigate to reservation page",
        "elementNotFound": "Required element not found on page",
        "timeout": "Operation timed out",
        "connectionFailed": "Connection failed",
        "authenticationFailed": "Authentication failed"
    ]
    static let patterns = [
        "gmailAppPassword": "^[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}$",
        "verificationCode": "\\b\\d{4}\\b",
        "phoneNumber": "^\\+?[1-9]\\d{1,14}$",
        "email": "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    ]
}

extension AppConstants {
    static let windowMainWidth: CGFloat = 440
    static let windowMainHeight: CGFloat = 600
    static let windowAboutWidth: CGFloat = 380
    static let windowAboutHeight: CGFloat = 380
    static let windowDayPickerWidth: CGFloat = 380
    static let windowDayPickerHeight: CGFloat = 380
    static let windowDeleteModalWidth: CGFloat = 340
    static let iconLarge: CGFloat = 64
    static let iconSmall: CGFloat = 14
    static let paddingHorizontal: CGFloat = 20
    static let paddingHorizontalForm: CGFloat = 32
    static let paddingHorizontalSettings: CGFloat = 16
    static let paddingVertical: CGFloat = 16
    static let paddingVerticalForm: CGFloat = 24
    static let paddingVerticalSmall: CGFloat = 8
    static let paddingVerticalTiny: CGFloat = 4
    static let paddingDivider: CGFloat = 4
    static let paddingButton: CGFloat = 12
    static let paddingOverlay: CGFloat = 24
    static let fontTitle: CGFloat = 17
    static let fontTitle2: CGFloat = 16
    static let fontTitle3: CGFloat = 15
    static let fontBody: CGFloat = 15
    static let fontSubheadline: CGFloat = 14
    static let fontCaption: CGFloat = 13
    static let fontCaption2: CGFloat = 12
}
