import Foundation
import SwiftUI

public enum AppConstants {
  // MARK: - App Information

  public static let appName = "ODYSSEY"
  public static let appVersion = "2.0.0"
  public static let appBundleId = "com.odyssey.app"

  // MARK: - Timeouts and Delays

  public static let defaultTimeout: TimeInterval = 30.0

  public static let imapConnectionTimeout: TimeInterval = defaultTimeout
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
  public static let verificationEmailSubject = "Verify your email."

  // MARK: - User Agent Strings

  public static let defaultUserAgent =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
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

  // MARK: - Screenshot Configuration

  public static let defaultScreenshotQuality: Float = 0.7
  public static let defaultScreenshotMaxWidth: CGFloat = 1920
  public static let defaultScreenshotFormat: ScreenshotFormat = .jpg

  // MARK: - Time and Delay Constants

  // Human behavior delays
  public static let humanDelayNanoseconds: UInt64 = 1_000_000_000  // 1 second in nanoseconds
  public static let shortDelayNanoseconds: UInt64 = 100_000_000  // 0.1 seconds in nanoseconds
  public static let mediumDelayNanoseconds: UInt64 = 500_000_000  // 0.5 seconds in nanoseconds
  public static let longDelayNanoseconds: UInt64 = 2_000_000_000  // 2 seconds in nanoseconds
  public static let extraLongDelayNanoseconds: UInt64 = 3_000_000_000  // 3 seconds in nanoseconds
  public static let veryLongDelayNanoseconds: UInt64 = 5_000_000_000  // 5 seconds in nanoseconds

  // Timeout constants
  public static let connectionTimeoutSeconds: TimeInterval = 30.0
  public static let fallbackTimeoutSeconds: TimeInterval = 35.0
  public static let emailSearchWindowMinutes: TimeInterval = 10.0
  public static let emailSearchWindowSeconds: TimeInterval = 600.0  // 10 minutes
  public static let emailSearchWindowShortSeconds: TimeInterval = 900.0  // 15 minutes
  public static let reservationTimeout: TimeInterval = 300.0  // 5 minutes for reservation completion

  // Polling and retry constants
  public static let maxPollAttempts: Int = 300  // 5 minutes timeout
  public static let progressUpdateInterval: Int = 10  // Show progress every 10 seconds
  public static let groupSizePollInterval: TimeInterval = 0.5
  public static let groupSizeMaxWaitTime: TimeInterval = 60.0

  // Retry and attempt limits
  public static let maxRetryAttempts: Int = 6
  public static let maxRetryAttemptsContactInfo: Int = 6

  // MARK: - Network and Port Constants

  public static let defaultImapPort: UInt16 = 993
  public static let fallbackImapPort: UInt16 = 143
  public static let defaultSmtpPort: UInt16 = 587

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
    "facilityURL": "^https://reservation\\.frontdesksuite\\.ca/rcfs/[^/]+/?$",
    "emailRegex": "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}",
  ]

  // Direct constants for common patterns
  public static let emailRegexPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

  // MARK: - Magic Numbers and Limits

  // Time-related constants (consolidated)
  public static let codePoolRefreshIntervalSeconds: TimeInterval = verificationCodeTimeout
  public static let maxWaitTimeForGodModeSeconds: TimeInterval = verificationCodeTimeout
  public static let additionalWaitTimeForUIUpdatesSeconds: TimeInterval = 2.0

  // MARK: - Verification Code Filtering

  // Suspicious verification codes that should be filtered out
  public static let suspiciousVerificationCodes = ["0000", "1234", "1111"]

  // Validation limits
  public static let maxNumberOfPeople: Int = 2
  public static let minNumberOfPeople: Int = 1
  public static let maxVerificationCodeLength: Int = 4
  public static let maxPhoneNumberLength: Int = 10
  public static let maxEmailLength: Int = 254

  // UI limits
  public static let maxConfigurationNameLength: Int = 60
  public static let maxSportNameLength: Int = 50
  public static let maxFacilityNameLength: Int = 30

  // Default values
  public static let defaultNumberOfPeople: Int = 1
  public static let defaultAutorunHour: Int = 18
  public static let defaultAutorunMinute: Int = 0

  // MARK: - File Management Constants

  // Screenshot cleanup
  public static let defaultScreenshotRetentionDays: Int = 30
  public static let screenshotRetentionSeconds: TimeInterval = 30 * 24 * 60 * 60  // 30 days

  // MARK: - WebKit Constants

  // User agent strings
  public static let chromeUserAgentV119 =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
  public static let chromeUserAgentV118 =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
  public static let safariUserAgentV171 =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15"
  public static let safariUserAgentV170 =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

  // WebKit configuration
  public static let webKitModifiedSinceEpoch: TimeInterval = 0
  public static let webKitMaxReceiveLength: Int = 65_536

  // Window positioning
  public static let windowOffsetRange: Int = 200
  public static let windowOffsetBase: Int = 50

  // MARK: - Text and Content Limits

  // Text and content limits
  public static let pageSourcePreviewLength: Int = 500
  public static let pageSourceErrorLength: Int = 1000
  public static let serverResponsePreviewLength: Int = 200
  public static let emailBodyPreviewLength: Int = 500
}

// MARK: - UI Constants

extension AppConstants {
  // MARK: - Window Sizes

  public static let windowMainWidth: CGFloat = 450
  public static let windowMainHeight: CGFloat = 600
  public static let windowAboutWidth: CGFloat = 300
  public static let windowAboutHeight: CGFloat = 300
  public static let windowDayPickerWidth: CGFloat = 300
  public static let windowDayPickerHeight: CGFloat = 350
  public static let windowDeleteModalWidth: CGFloat = 300

  // MARK: - Icon Sizes

  public static let iconLarge: CGFloat = 32
  public static let iconMedium: CGFloat = 24
  public static let iconSmall: CGFloat = 16
  public static let iconTiny: CGFloat = 12

  // MARK: - Spacing System

  public static let spacingNone: CGFloat = 0
  public static let spacingTiny: CGFloat = 2
  public static let spacingSmall: CGFloat = 4
  public static let spacingMedium: CGFloat = 8
  public static let spacingLarge: CGFloat = 12
  public static let spacingXLarge: CGFloat = 16
  public static let spacingXXLarge: CGFloat = 20

  // MARK: - Padding System

  public static let paddingNone: CGFloat = 0
  public static let paddingTiny: CGFloat = 4
  public static let paddingSmall: CGFloat = 8
  public static let paddingMedium: CGFloat = 12
  public static let paddingLarge: CGFloat = 16
  public static let paddingXLarge: CGFloat = 20
  public static let paddingXXLarge: CGFloat = 24

  // MARK: - Typography System

  public static let fontTiny: CGFloat = 9
  public static let fontSmall: CGFloat = 10
  public static let fontMedium: CGFloat = 11
  public static let fontLarge: CGFloat = 12
  public static let fontXLarge: CGFloat = 13
  public static let fontXXLarge: CGFloat = 14
  public static let fontHuge: CGFloat = 16
  public static let fontGiant: CGFloat = 20
  public static let fontMassive: CGFloat = 24
  public static let fontEnormous: CGFloat = 28
  public static let fontColossal: CGFloat = 32

  // MARK: - Typography Aliases

  // Common font size aliases for consistency
  public static let fontTitle: CGFloat = fontXXLarge
  public static let fontTitle2: CGFloat = fontXXLarge
  public static let fontTitle3: CGFloat = fontXLarge
  public static let fontBody: CGFloat = fontXLarge
  public static let fontSubheadline: CGFloat = fontLarge
  public static let fontCaption: CGFloat = fontMedium
  public static let fontCaption2: CGFloat = fontSmall
  public static let fontHeadline: CGFloat = fontXXLarge

  // MARK: - Corner Radius

  public static let cornerRadiusNone: CGFloat = 0
  public static let cornerRadiusSmall: CGFloat = 4
  public static let cornerRadiusMedium: CGFloat = 6
  public static let cornerRadiusLarge: CGFloat = 8
  public static let cornerRadiusXLarge: CGFloat = 12
  public static let cornerRadiusXXLarge: CGFloat = 16

  // MARK: - Border Width

  // MARK: - Shadow

  public static let shadowRadiusSmall: CGFloat = 2
  public static let shadowRadiusMedium: CGFloat = 4
  public static let shadowRadiusLarge: CGFloat = 8
  public static let shadowRadiusXLarge: CGFloat = 12
  public static let shadowRadiusXXLarge: CGFloat = 16

  // MARK: - Opacity

  public static let opacityNone: Double = 0
  public static let opacitySubtle: Double = 0.1
  public static let opacityLight: Double = 0.2
  public static let opacityMedium: Double = 0.5
  public static let opacityStrong: Double = 0.7
  public static let opacityFull: Double = 1.0

  // MARK: - Animation Durations

  public static let animationDurationFast: Double = 0.15
  public static let animationDurationNormal: Double = 0.25
  public static let animationDurationSlow: Double = 0.35
  public static let animationDurationVerySlow: Double = 0.5

  // MARK: - Scale Effects

  public static let scaleEffectSmall: Double = 0.8
  public static let scaleEffectMedium: Double = 1.0
  public static let scaleEffectLarge: Double = 1.5

  // MARK: - Component Heights

  public static let buttonHeightSmall: CGFloat = 28
  public static let buttonHeightMedium: CGFloat = 32
  public static let buttonHeightLarge: CGFloat = 36
  public static let buttonHeightXLarge: CGFloat = 40

  public static let textFieldHeightSmall: CGFloat = 28
  public static let textFieldHeightMedium: CGFloat = 32
  public static let textFieldHeightLarge: CGFloat = 36

  public static let rowHeightSmall: CGFloat = 32
  public static let rowHeightMedium: CGFloat = 40
  public static let rowHeightLarge: CGFloat = 48
  public static let rowHeightXLarge: CGFloat = 56

  // MARK: - Layout Constants

  public static let maxContentWidth: CGFloat = 600
  public static let minContentWidth: CGFloat = 300
  public static let maxContentHeight: CGFloat = 800
  public static let minContentHeight: CGFloat = 400

  // MARK: - Grid System
}

// MARK: - UI Helper Extensions

extension AppConstants {
  // MARK: - Common Spacing Combinations

  public static let contentSpacing: CGFloat = spacingLarge
  public static let sectionSpacing: CGFloat = spacingXXLarge
  public static let groupSpacing: CGFloat = spacingMedium
  public static let itemSpacing: CGFloat = spacingSmall
  // Standard vertical spacing around dividers separating sections
  public static let sectionDividerSpacing: CGFloat = screenPadding

  // MARK: - Common Padding Combinations

  public static let contentPadding: CGFloat = paddingLarge
  public static let sectionPadding: CGFloat = paddingXXLarge
  // Unified outer screen padding for consistent margins across views
  public static let screenPadding: CGFloat = contentPadding
  public static let cardPadding: CGFloat = paddingLarge
  public static let buttonPadding: CGFloat = paddingMedium

  // MARK: - Common Font Combinations

  public static let primaryFont: CGFloat = fontXLarge
  public static let secondaryFont: CGFloat = fontLarge
  public static let tertiaryFont: CGFloat = fontMedium
  public static let accentFont: CGFloat = fontXXLarge

  // MARK: - Common Corner Radius Combinations

  public static let cardCornerRadius: CGFloat = cornerRadiusMedium
  public static let buttonCornerRadius: CGFloat = cornerRadiusSmall
  public static let modalCornerRadius: CGFloat = cornerRadiusXXLarge
  public static let inputCornerRadius: CGFloat = cornerRadiusSmall
}

// MARK: - Logger Categories

/// Enum defining all logging categories used throughout the application.
/// This prevents typos and ensures consistent category naming.
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

  case appDelegate = "AppDelegate"
  case statusBarController = "StatusBarController"
  case configurationValidator = "ConfigurationValidator"

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

    case .appDelegate: return "📱"
    case .statusBarController: return "🍎"
    case .configurationValidator: return "🔍"

    }
  }
}
