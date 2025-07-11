import Foundation

/// Application-wide constants
enum Constants {
    // MARK: - App Information

    static let appName = "ODYSSEY"
    static let appVersion = "2.0.0"
    static let bundleIdentifier = "com.odyssey.app"

    // MARK: - URLs

    static let ottawaFacilitiesURL = "https://ottawa.ca/en/recreation-and-parks/recreation-facilities"
    static let reservationBaseURL = "https://reservation.frontdesksuite.ca/rcfs/"

    // MARK: - Timeouts

    static let webViewTimeout: TimeInterval = 30
    static let sportsDetectionTimeout: TimeInterval = 15
    static let reservationTimeout: TimeInterval = 30

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
        "basketball", "volleyball", "badminton", "tennis", "soccer", "football",
        "hockey", "swimming", "gym", "fitness", "yoga", "pilates", "dance",
        "skating", "curling", "baseball", "softball", "cricket", "rugby",
        "lacrosse", "field hockey", "table tennis", "ping pong", "racquetball",
        "squash", "handball", "boxing", "martial arts", "karate", "taekwondo",
        "judo", "wrestling", "gymnastics", "cheerleading", "track", "running",
        "cross country", "cycling", "biking", "rowing", "canoeing", "kayaking",
        "sailing", "golf", "mini golf", "bowling", "billiards", "pool",
        "archery", "shooting", "fencing", "rock climbing", "bouldering",
        "weightlifting", "powerlifting", "bodybuilding", "aerobics", "zumba",
        "spinning", "cycling", "rowing", "elliptical", "treadmill", "stairmaster",
    ]

    // MARK: - Excluded Terms for Sports Detection

    static let excludedTerms = [
        "login", "sign", "register", "search", "filter", "date", "time",
        "submit", "cancel", "back", "next", "previous", "close", "menu",
        "home", "about", "contact", "help", "settings", "profile", "account",
        "logout", "sign out", "signout", "sign up", "signup", "create account",
        "new account", "forgot password", "reset password", "change password",
        "update profile", "edit profile", "my account", "my profile",
        "my settings", "my preferences", "my bookings", "my reservations",
        "my history", "my schedule", "my calendar", "my activities",
        "my sports", "my classes", "my programs", "my sessions",
        "my times", "my slots", "my time slots",
    ]
}
