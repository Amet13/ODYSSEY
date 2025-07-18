import Foundation

/// Application-wide constants
///
/// @deprecated Use AppConstants from Sources/Utils/AppConstants.swift instead
/// This file is kept for backward compatibility and will be removed in a future version
enum Constants {
    // MARK: - App Information

    static let appName = AppConstants.appName
    static let appVersion = AppConstants.appVersion
    static let bundleIdentifier = AppConstants.appBundleId

    // MARK: - URLs

    static let ottawaFacilitiesURL = AppConstants.ottawaFacilitiesURL
    static let reservationBaseURL = "https://reservation.frontdesksuite.ca/rcfs/"

    // MARK: - Timeouts

    static let webViewTimeout: TimeInterval = AppConstants.defaultTimeout
    static let sportsDetectionTimeout: TimeInterval = AppConstants.pageLoadTimeout
    static let reservationTimeout: TimeInterval = AppConstants.verificationCodeTimeout

    // MARK: - UI Constants

    static let popoverWidth: CGFloat = 400
    static let popoverHeight: CGFloat = 500
    static let statusBarIconSize: CGFloat = 18

    // MARK: - Scheduling

    static let schedulingCheckInterval: TimeInterval = 60 // 1 minute
    static let reservationDelay: TimeInterval = 2 // 2 seconds between reservations

    // MARK: - Logging

    static let logSubsystem = AppConstants.loggingSubsystem

    // MARK: - UserDefaults Keys

    static let settingsKey = "ODYSSEY_Settings"

    // MARK: - WebKit Message Handlers

    static let facilityMessageHandler = "facilityHandler"
    static let odysseyMessageHandler = "odysseyHandler"

    // MARK: - Validation Patterns

    static let facilityURLPattern = #"^https://reservation\.frontdesksuite\.ca/rcfs/[^/]+/?$"#
    static let facilityNamePattern = #"https://reservation\.frontdesksuite\.ca/rcfs/([^/]+)"#

    // MARK: - Sports Keywords

    static let sportsKeywords = AppConstants.sportsKeywords

    static let supportedLanguages = AppConstants.supportedLanguages
}
