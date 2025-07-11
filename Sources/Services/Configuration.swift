import Combine
import Foundation
import os.log

/// Manages application configuration and settings persistence
class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()

    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }

    private let userDefaults = UserDefaults.standard
    private let settingsKey = "ODYSSEY_Settings"
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ConfigurationManager")

    private init() {
        // Load saved settings or use defaults
        if let data = userDefaults.data(forKey: settingsKey) {
            if let savedSettings = try? JSONDecoder().decode(AppSettings.self, from: data) {
                settings = savedSettings
            } else {
                settings = AppSettings()
            }
        } else {
            settings = AppSettings()
        }
    }

    // MARK: - Configuration Management

    func addConfiguration(_ config: ReservationConfig) {
        settings.configurations.append(config)
    }

    func updateConfiguration(_ config: ReservationConfig) {
        if let index = settings.configurations.firstIndex(where: { $0.id == config.id }) {
            settings.configurations[index] = config
        } else {
            logger.warning("Configuration not found for update: \(config.id)")
        }
    }

    func removeConfiguration(_ config: ReservationConfig) {
        settings.configurations.removeAll { $0.id == config.id }
    }

    func toggleConfiguration(at index: Int) {
        guard index < settings.configurations.count else { return }

        settings.configurations[index].isEnabled.toggle()
        saveSettings()

        let configName = settings.configurations[index].name
        let isEnabled = settings.configurations[index].isEnabled
        let status = isEnabled ? "enabled" : "disabled"
        logger.info("Configuration '\(configName)' \(status)")
    }

    func getConfiguration(by id: UUID) -> ReservationConfig? {
        settings.configurations.first { $0.id == id }
    }

    // MARK: - Persistence

    private func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: settingsKey)
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription)")
        }
    }

    func resetToDefaults() {
        settings = AppSettings()
    }

    // MARK: - Convenience Methods

    func getEnabledConfigurations() -> [ReservationConfig] {
        settings.configurations.filter(\.isEnabled)
    }

    func getConfigurationsForDay(_ weekday: ReservationConfig.Weekday) -> [ReservationConfig] {
        getEnabledConfigurations().filter { $0.dayTimeSlots[weekday]?.isEmpty == false }
    }

    func isAnyConfigurationEnabled() -> Bool {
        settings.globalEnabled && !getEnabledConfigurations().isEmpty
    }
}
