import Foundation

/// Application-wide constants
enum Constants {
    // MARK: - App Information

    static let appName = "ODYSSEY"
    static let appVersion = "2.2.0"
    static let bundleIdentifier = "com.odyssey.app"

    // MARK: - URLs

    static let ottawaFacilitiesURL = "https://ottawa.ca/en/recreation-and-parks/recreation-facilities"
    static let reservationBaseURL = "https://reservation.frontdesksuite.ca/rcfs/"

    // MARK: - Timeouts

    static let webViewTimeout: TimeInterval = 30
    static let sportsDetectionTimeout: TimeInterval = 15
    static let reservationTimeout: TimeInterval = 60

    // MARK: - UI Constants

    static let popoverWidth: CGFloat = 400
    static let popoverHeight: CGFloat = 600
    static let statusBarIconSize: CGFloat = 18

    // MARK: - Scheduling

    static let schedulingCheckInterval: TimeInterval = 60 // 1 minute
    static let reservationDelay: TimeInterval = 2 // 2 seconds between reservations

    // MARK: - Logging

    static let logSubsystem = "com.odyssey.app"

    // MARK: - UserDefaults Keys

    static let settingsKey = "ODYSSEY_Settings"

    // MARK: - WebKit Message Handlers

    static let facilityMessageHandler = "facilityHandler"
    static let odysseyMessageHandler = "odysseyHandler"

    // MARK: - Validation Patterns

    static let facilityURLPattern = #"^https://reservation\.frontdesksuite\.ca/rcfs/[^/]+/?$"#
    static let facilityNamePattern = #"https://reservation\.frontdesksuite\.ca/rcfs/([^/]+)"#

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
        "sport",
    ]

    static let supportedLanguages = [
        "en": "English",
        "fr": "Français",
    ]
}
