import Foundation
import SwiftUI

public enum AppConstants {
    // MARK: - App Information

    public static let appName = "ODYSSEY"
    public static let appVersion = "1.0.0"
    public static let appBundleId = "com.odyssey.app"

    // MARK: - Timeouts and Delays

    public static let defaultTimeout: TimeInterval = 30.0

    public static let imapConnectionTimeout: TimeInterval = 30.0
    public static let verificationCodeTimeout: TimeInterval = 300.0
    public static let minHumanDelay: TimeInterval = 0.5
    public static let maxHumanDelay: TimeInterval = 0.9
    public static let typingDelay: TimeInterval = 0.12
    public static let pageTransitionDelay: TimeInterval = 1.2

    // Additional timeout constants (consolidated)
    public static let retryDelay: TimeInterval = 2.0
    public static let pollInterval: TimeInterval = 1.0
    public static let initialWait: TimeInterval = 5.0
    public static let maxTotalWait: TimeInterval = verificationCodeTimeout
    public static let shortTimeout: TimeInterval = 10.0
    public static let mediumTimeout: TimeInterval = 60.0
    public static let timeWindowMinutes: TimeInterval = 5.0 * 60.0
    public static let waitInterval: TimeInterval = 10.0
    public static let checkIntervalShort: TimeInterval = 0.5
    public static let pageLoadTimeout: TimeInterval = 30.0
    public static let elementWaitTimeout: TimeInterval = 10.0

    // MARK: - Network and Email

    public static let gmailImapServer = "imap.gmail.com"
    public static let gmailImapPort: UInt16 = 993
    public static let verificationEmailFrom = "noreply@frontdesksuite.com"
    public static let verificationEmailSubject = "Verify your email"

    // MARK: - User Agent Strings

    public static let defaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
    public static let safariUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"
    public static let chromeUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    // MARK: - Error Codes

    public static let errorCodes = [
        "navigationFailed": "WEBDRIVER_NAVIGATION_001",
        "elementNotFound": "WEBDRIVER_ELEMENT_001",
        "clickFailed": "WEBDRIVER_CLICK_001",
        "typeFailed": "WEBDRIVER_TYPE_001",
        "scriptExecutionFailed": "WEBDRIVER_SCRIPT_001",
        "timeout": "WEBDRIVER_TIMEOUT_001",
        "connectionFailed": "WEBDRIVER_CONNECTION_001",
        "invalidSelector": "WEBDRIVER_SELECTOR_001",
        "staleElement": "WEBDRIVER_STALE_001",
        "emailConnectionFailed": "EMAIL_CONNECTION_001",
        "emailAuthFailed": "EMAIL_AUTH_001",
    ]

    // MARK: - WebKit Configuration

    public static let webKitWindowWidth = 1_440
    public static let webKitWindowHeight = 900
    public static let webKitDebugWindowX: CGFloat = 200
    public static let webKitDebugWindowY: CGFloat = 200
    public static let windowSizes = [(width: 1_440, height: 900), (width: 1_680, height: 1_050)]

    // MARK: - URLs

    public static let ottawaFacilitiesURL = "https://ottawa.ca/en/recreation-and-parks/facilities"
    public static let gmailAppPasswordURL = "https://support.google.com/accounts/answer/185833"
    public static let githubURL = "https://github.com/Amet13/ODYSSEY"

    // MARK: - Storage Keys

    public static let lastRunInfoKey = "ReservationManager.lastRunInfo"
    public static let userSettingsKey = "UserSettingsManager.userSettings"
    public static let configurationsKey = "ConfigurationManager.configurations"
    public static let loggingSubsystem = "com.odyssey.app"

    // MARK: - Notification Names

    public static let addConfigurationNotification = Notification.Name("addConfiguration")
    public static let openSettingsNotification = Notification.Name("openSettings")
    public static let rescheduleAutorunNotification = Notification.Name("rescheduleAutorun")

    // MARK: - Validation Patterns

    public static let patterns = [
        "gmailAppPassword": "^[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}$",
        "verificationCode": "\\b\\d{4}\\b",
        "phoneNumber": "^\\+?[1-9]\\d{1,14}$",
        "email": "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",
    ]

    // MARK: - Magic Numbers and Limits

    // Time-related constants (consolidated)
    public static let emailSearchWindowMinutes: TimeInterval = 10.0
    public static let codePoolRefreshIntervalSeconds: TimeInterval = verificationCodeTimeout
    public static let maxWaitTimeForGodModeSeconds: TimeInterval = verificationCodeTimeout
    public static let additionalWaitTimeForUIUpdatesSeconds: TimeInterval = 2.0

    // Validation limits
    public static let maxNumberOfPeople: Int = 2
    public static let minNumberOfPeople: Int = 1
    public static let maxVerificationCodeLength: Int = 4
    public static let maxPhoneNumberLength: Int = 10
    public static let maxEmailLength: Int = 254

    // UI limits
    public static let maxConfigurationNameLength: Int = 30
    public static let maxSportNameLength: Int = 50
    public static let maxFacilityNameLength: Int = 30

    // Default values
    public static let defaultNumberOfPeople: Int = 1
    public static let defaultAutorunHour: Int = 18
    public static let defaultAutorunMinute: Int = 0
    public static let defaultGmailPort: UInt16 = 993
    public static let defaultImapPort: UInt16 = 993
}

// MARK: - UI Constants

public extension AppConstants {
    // MARK: - Window Sizes

    static let windowMainWidth: CGFloat = 440
    static let windowMainHeight: CGFloat = 600
    static let windowAboutWidth: CGFloat = 300
    static let windowAboutHeight: CGFloat = 300
    static let windowDayPickerWidth: CGFloat = 300
    static let windowDayPickerHeight: CGFloat = 370
    static let windowDeleteModalWidth: CGFloat = 300

    // MARK: - Icon Sizes

    static let iconLarge: CGFloat = 32
    static let iconMedium: CGFloat = 24
    static let iconSmall: CGFloat = 16
    static let iconTiny: CGFloat = 12

    // MARK: - Spacing System

    static let spacingNone: CGFloat = 0
    static let spacingTiny: CGFloat = 2
    static let spacingSmall: CGFloat = 4
    static let spacingMedium: CGFloat = 8
    static let spacingLarge: CGFloat = 12
    static let spacingXLarge: CGFloat = 16
    static let spacingXXLarge: CGFloat = 20
    static let spacingHuge: CGFloat = 32

    // MARK: - Padding System

    static let paddingNone: CGFloat = 0
    static let paddingTiny: CGFloat = 4
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 12
    static let paddingLarge: CGFloat = 16
    static let paddingXLarge: CGFloat = 20
    static let paddingXXLarge: CGFloat = 24

    // MARK: - Typography System

    static let fontTiny: CGFloat = 9
    static let fontSmall: CGFloat = 10
    static let fontMedium: CGFloat = 11
    static let fontLarge: CGFloat = 12
    static let fontXLarge: CGFloat = 13
    static let fontXXLarge: CGFloat = 14
    static let fontHuge: CGFloat = 16
    static let fontGiant: CGFloat = 20
    static let fontMassive: CGFloat = 24
    static let fontEnormous: CGFloat = 28
    static let fontColossal: CGFloat = 32

    // MARK: - Typography Aliases

    // Common font size aliases for consistency
    static let fontTitle: CGFloat = fontXXLarge
    static let fontTitle2: CGFloat = fontXXLarge
    static let fontTitle3: CGFloat = fontXLarge
    static let fontBody: CGFloat = fontXLarge
    static let fontSubheadline: CGFloat = fontLarge
    static let fontCaption: CGFloat = fontMedium
    static let fontCaption2: CGFloat = fontSmall
    static let fontHeadline: CGFloat = fontXXLarge

    // MARK: - Corner Radius

    static let cornerRadiusNone: CGFloat = 0
    static let cornerRadiusSmall: CGFloat = 4
    static let cornerRadiusMedium: CGFloat = 6
    static let cornerRadiusLarge: CGFloat = 8
    static let cornerRadiusXLarge: CGFloat = 12
    static let cornerRadiusXXLarge: CGFloat = 16

    // MARK: - Border Width

    static let borderWidthNone: CGFloat = 0
    static let borderWidthThin: CGFloat = 0.5
    static let borderWidthSmall: CGFloat = 1
    static let borderWidthMedium: CGFloat = 2
    static let borderWidthLarge: CGFloat = 3

    // MARK: - Shadow

    static let shadowRadiusSmall: CGFloat = 2
    static let shadowRadiusMedium: CGFloat = 4
    static let shadowRadiusLarge: CGFloat = 8
    static let shadowRadiusXLarge: CGFloat = 12
    static let shadowRadiusXXLarge: CGFloat = 16

    // MARK: - Opacity

    static let opacityNone: Double = 0
    static let opacitySubtle: Double = 0.1
    static let opacityLight: Double = 0.2
    static let opacityMedium: Double = 0.5
    static let opacityStrong: Double = 0.7
    static let opacityFull: Double = 1.0

    // MARK: - Animation Durations

    static let animationDurationFast: Double = 0.15
    static let animationDurationNormal: Double = 0.25
    static let animationDurationSlow: Double = 0.35
    static let animationDurationVerySlow: Double = 0.5

    // MARK: - Scale Effects

    static let scaleEffectSmall: Double = 0.8
    static let scaleEffectMedium: Double = 1.0
    static let scaleEffectLarge: Double = 1.5

    // MARK: - Component Heights

    static let buttonHeightSmall: CGFloat = 28
    static let buttonHeightMedium: CGFloat = 32
    static let buttonHeightLarge: CGFloat = 36
    static let buttonHeightXLarge: CGFloat = 40

    static let textFieldHeightSmall: CGFloat = 28
    static let textFieldHeightMedium: CGFloat = 32
    static let textFieldHeightLarge: CGFloat = 36

    static let rowHeightSmall: CGFloat = 32
    static let rowHeightMedium: CGFloat = 40
    static let rowHeightLarge: CGFloat = 48
    static let rowHeightXLarge: CGFloat = 56

    // MARK: - Layout Constants

    static let maxContentWidth: CGFloat = 600
    static let minContentWidth: CGFloat = 300
    static let maxContentHeight: CGFloat = 800
    static let minContentHeight: CGFloat = 400

    // MARK: - Grid System

    static let gridColumns: Int = 12
    static let gridGutter: CGFloat = spacingMedium
    static let gridMargin: CGFloat = paddingLarge
}

// MARK: - UI Helper Extensions

public extension AppConstants {
    // MARK: - Common Spacing Combinations

    static let contentSpacing: CGFloat = spacingLarge
    static let sectionSpacing: CGFloat = spacingXXLarge
    static let groupSpacing: CGFloat = spacingMedium
    static let itemSpacing: CGFloat = spacingSmall

    // MARK: - Common Padding Combinations

    static let contentPadding: CGFloat = paddingLarge
    static let sectionPadding: CGFloat = paddingXXLarge
    static let cardPadding: CGFloat = paddingLarge
    static let buttonPadding: CGFloat = paddingMedium

    // MARK: - Common Font Combinations

    static let primaryFont: CGFloat = fontXLarge
    static let secondaryFont: CGFloat = fontLarge
    static let tertiaryFont: CGFloat = fontMedium
    static let accentFont: CGFloat = fontXXLarge

    // MARK: - Common Corner Radius Combinations

    static let cardCornerRadius: CGFloat = cornerRadiusMedium
    static let buttonCornerRadius: CGFloat = cornerRadiusSmall
    static let modalCornerRadius: CGFloat = cornerRadiusXXLarge
    static let inputCornerRadius: CGFloat = cornerRadiusSmall
}

// MARK: - Logger Categories

/**
 * Enum defining all logging categories used throughout the application.
 * This prevents typos and ensures consistent category naming.
 */
public enum LoggerCategory: String, CaseIterable {
    case general = "General"
    case webKit = "WebKit"
    case webKitService = "WebKitService"
    case webKitCore = "WebKitCore"
    case webKitNavigation = "WebKitNavigation"
    case webKitAntiDetection = "WebKitAntiDetection"
    case webKitHumanBehavior = "WebKitHumanBehavior"
    case webKitDebugWindowManager = "WebKitDebugWindowManager"
    case webKitScriptManager = "WebKitScriptManager"
    case reservationOrchestrator = "ReservationOrchestrator"
    case reservationStatusManager = "ReservationStatusManager"
    case reservationErrorHandler = "ReservationErrorHandler"
    case conflictDetectionService = "ConflictDetectionService"
    case emailService = "EmailService"
    case emailCore = "EmailCore"
    case keychainService = "KeychainService"
    case configurationManager = "ConfigurationManager"
    case userSettingsManager = "UserSettingsManager"
    case validationService = "ValidationService"
    case errorHandlingService = "ErrorHandlingService"
    case loggingService = "LoggingService"
    case facilityService = "FacilityService"
    case godModeStateManager = "GodModeStateManager"
    case sharedVerificationCodePool = "SharedVerificationCodePool"
    case cliExportService = "CLIExportService"
    case appDelegate = "AppDelegate"
    case statusBarController = "StatusBarController"
    case configurationValidator = "ConfigurationValidator"
    case cli = "CLI"

    /// Returns the category name for use in logging
    public var categoryName: String {
        return rawValue
    }

    /// Returns the emoji prefix for visual identification in logs
    var emoji: String {
        switch self {
        case .general: return "ℹ️"
        case .webKit, .webKitService, .webKitCore, .webKitNavigation: return "🌐"
        case .webKitAntiDetection, .webKitHumanBehavior: return "🤖"
        case .webKitDebugWindowManager, .webKitScriptManager: return "🔧"
        case .reservationOrchestrator, .reservationStatusManager: return "🚀"
        case .reservationErrorHandler: return "❌"
        case .conflictDetectionService: return "⚠️"
        case .emailService, .emailCore: return "📧"
        case .keychainService: return "🔐"
        case .configurationManager, .userSettingsManager: return "⚙️"
        case .validationService: return "✅"
        case .errorHandlingService: return "🚨"
        case .loggingService: return "📝"
        case .facilityService: return "🏟️"
        case .godModeStateManager: return "⌨️"
        case .sharedVerificationCodePool: return "📦"
        case .cliExportService: return "📤"
        case .appDelegate: return "📱"
        case .statusBarController: return "🍎"
        case .configurationValidator: return "🔍"
        case .cli: return "💻"
        }
    }
}
