import Foundation
import os.log

/// Manages user settings and configuration data
///
/// Provides centralized access to user information including contact details,
/// email settings, and optional Telegram integration settings.
class UserSettingsManager: ObservableObject {
    static let shared = UserSettingsManager()

    @Published var userSettings: UserSettings {
        didSet {
            saveSettings()
        }
    }

    private let userDefaults = UserDefaults.standard
    private let settingsKey = "ODYSSEY_UserSettings"
    private let logger = Logger(subsystem: "com.odyssey.app", category: "UserSettingsManager")

    private init() {
        // Load saved settings or use defaults
        if let data = userDefaults.data(forKey: settingsKey),
           let savedSettings = try? JSONDecoder().decode(UserSettings.self, from: data)
        {
            userSettings = savedSettings
        } else {
            userSettings = UserSettings()
        }
    }

    // MARK: - Public Methods

    /// Updates user settings
    /// - Parameter settings: The new user settings
    func updateSettings(_ settings: UserSettings) {
        userSettings = settings
    }

    /// Resets user settings to defaults
    func resetToDefaults() {
        userSettings = UserSettings()
    }

    /// Checks if user settings are valid for automation
    /// - Returns: True if all required fields are filled
    func isSettingsValid() -> Bool {
        userSettings.isValid
    }

    /// Gets formatted user information for display
    /// - Returns: Dictionary with user information
    func getUserInfo() -> [String: String] {
        [
            "name": userSettings.name,
            "phone": userSettings.getFormattedPhoneNumber(),
            "email": userSettings.imapEmail,
            "server": userSettings.imapServer,
            "hasTelegram": userSettings.hasTelegramConfigured ? "Yes" : "No",
        ]
    }

    // MARK: - Private Methods

    private func saveSettings() {
        do {
            let data = try JSONEncoder().encode(userSettings)
            userDefaults.set(data, forKey: settingsKey)
        } catch {
            logger.error("Failed to save user settings: \(error.localizedDescription)")
        }
    }
}
