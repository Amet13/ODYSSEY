import Foundation
import os

/// Manages user settings and configuration data
///
/// Provides centralized access to user information including contact details,
/// email settings, and optional Telegram integration settings.
@MainActor
public final class UserSettingsManager: ObservableObject, @unchecked Sendable {
  public static let shared = UserSettingsManager()

  @Published public var userSettings: UserSettings {
    didSet {
      saveSettings()
    }
  }

  // Store last successful configs
  private var lastSuccessfulIMAPConfig: IMAPConfig?
  private var lastSuccessfulGmailConfig: GmailConfig?

  private struct IMAPConfig {
    let email: String
    let password: String
    let server: String
  }

  private struct GmailConfig {
    let email: String
    let appPassword: String
  }

  private let userDefaults: UserDefaults
  private let settingsKey: String
  private let logger: Logger

  /// Main initializer supporting dependency injection for logger and userDefaults.
  /// - Parameters:
  ///   - logger: Logger instance (default: ODYSSEY UserSettingsManager logger)
  ///   - userDefaults: UserDefaults instance (default: .standard)
  ///   - settingsKey: Key for storing user settings (default: "ODYSSEY_UserSettings")
  public init(
    logger: Logger = Logger(
      subsystem: AppConstants.loggingSubsystem, category: "UserSettingsManager"),
    userDefaults: UserDefaults = .standard,
    settingsKey: String = "ODYSSEY_UserSettings"
  ) {
    self.logger = logger
    self.userDefaults = userDefaults
    self.settingsKey = settingsKey
    // Load saved settings or use defaults
    if let data = userDefaults.data(forKey: settingsKey) {
      if let savedSettings = try? JSONDecoder().decode(UserSettings.self, from: data) {
        userSettings = savedSettings
      } else {
        userSettings = UserSettings()
      }
    } else {
      userSettings = UserSettings()
    }
  }

  // Keep the default singleton for app use
  private convenience init() {
    self.init(
      logger: Logger(subsystem: AppConstants.loggingSubsystem, category: "UserSettingsManager"),
      userDefaults: .standard,
      settingsKey: "ODYSSEY_UserSettings",
    )
  }

  // MARK: - Public Methods

  /// Updates user settings
  /// - Parameter settings: The new user settings
  public func updateSettings(_ settings: UserSettings) {
    userSettings = settings
    storeCredentialsInKeychain()
    userSettings.imapPassword = ""
    saveSettings()
  }

  /// Resets user settings to defaults
  public func resetToDefaults() {
    userSettings = UserSettings()
  }

  /// Checks if user settings are valid for automation
  /// - Returns: True if all required fields are filled
  public func isSettingsValid() -> Bool {
    userSettings.isValid
  }

  /// Gets formatted user information for display
  /// - Returns: Dictionary with user information
  public func getUserInfo() -> [String: String] {
    [
      "name": userSettings.name,
      "phone": userSettings.getFormattedPhoneNumber(),
      "email": userSettings.imapEmail,
      "server": userSettings.imapServer,
    ]
  }

  // MARK: - Last Successful Config Management

  public func saveLastSuccessfulIMAPConfig(email: String, password: String, server: String) {
    lastSuccessfulIMAPConfig = IMAPConfig(email: email, password: password, server: server)
  }

  public func saveLastSuccessfulGmailConfig(email: String, appPassword: String) {
    lastSuccessfulGmailConfig = GmailConfig(email: email, appPassword: appPassword)
  }

  public func restoreIMAPConfigIfAvailable() {
    if let config = lastSuccessfulIMAPConfig {
      userSettings.imapEmail = config.email
      userSettings.imapPassword = config.password
      userSettings.imapServer = config.server
    }
  }

  public func restoreGmailConfigIfAvailable() {
    if let config = lastSuccessfulGmailConfig {
      userSettings.imapEmail = config.email
      userSettings.imapPassword = config.appPassword
    }
  }

  // MARK: - Keychain Credential Management

  /// Stores email credentials in KeychainService
  public func storeCredentialsInKeychain() {
    let email = userSettings.imapEmail
    let password = userSettings.imapPassword
    let server = userSettings.imapServer
    let port = Int(AppConstants.defaultImapPort)
    guard !email.isEmpty, !password.isEmpty, !server.isEmpty else { return }
    let result = KeychainService.shared.storeEmailCredentials(
      email: email,
      password: password,
      server: server,
      port: port
    )
    if case .failure(let error) = result {
      logger.error("❌ Keychain storage error: \(error.localizedDescription, privacy: .private).")
    }
  }

  /// Removes email credentials from KeychainService
  public func clearCredentialsFromKeychain() {
    let email = userSettings.imapEmail
    let server = userSettings.imapServer
    let port = Int(AppConstants.defaultImapPort)
    guard !email.isEmpty, !server.isEmpty else { return }
    let result = KeychainService.shared.deleteEmailCredentials(
      email: email, server: server, port: port)
    if case .failure(let error) = result {
      logger.error("❌ Keychain deletion error: \(error.localizedDescription, privacy: .private).")
    }
  }

  // MARK: - Private Methods

  public func saveSettings() {
    do {
      let data = try JSONEncoder().encode(userSettings)
      userDefaults.set(data, forKey: settingsKey)
    } catch {
      logger.error(
        "❌ Failed to save user settings: \(error.localizedDescription, privacy: .private).")
    }
  }
}
