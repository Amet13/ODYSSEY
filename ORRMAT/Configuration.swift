import Foundation
import Combine
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
    private let settingsKey = "ORRMAT_Settings"
    private let logger = Logger(subsystem: "com.orrmat.app", category: "ConfigurationManager")
    
    private init() {
        // Load saved settings or use defaults
        if let data = userDefaults.data(forKey: settingsKey),
           let savedSettings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = savedSettings
            logger.info("Settings loaded successfully")
        } else {
            self.settings = AppSettings()
            logger.info("Using default settings")
        }
    }
    
    // MARK: - Configuration Management
    
    func addConfiguration(_ config: ReservationConfig) {
        settings.configurations.append(config)
        logger.info("Added configuration: \(config.name)")
    }
    
    func updateConfiguration(_ config: ReservationConfig) {
        if let index = settings.configurations.firstIndex(where: { $0.id == config.id }) {
            settings.configurations[index] = config
            logger.info("Updated configuration: \(config.name)")
        } else {
            logger.warning("Configuration not found for update: \(config.id)")
        }
    }
    
    func removeConfiguration(_ config: ReservationConfig) {
        settings.configurations.removeAll { $0.id == config.id }
        logger.info("Removed configuration: \(config.name)")
    }
    
    func toggleConfigurationEnabled(_ config: ReservationConfig) {
        if let index = settings.configurations.firstIndex(where: { $0.id == config.id }) {
            settings.configurations[index].isEnabled.toggle()
            let status = settings.configurations[index].isEnabled ? "enabled" : "disabled"
            logger.info("Configuration \(config.name) \(status)")
        } else {
            logger.warning("Configuration not found for toggle: \(config.id)")
        }
    }
    
    func getConfiguration(by id: UUID) -> ReservationConfig? {
        return settings.configurations.first { $0.id == id }
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: settingsKey)
            logger.debug("Settings saved successfully")
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription)")
        }
    }
    
    func resetToDefaults() {
        settings = AppSettings()
        logger.info("Settings reset to defaults")
    }
    
    // MARK: - Convenience Methods
    
    func getEnabledConfigurations() -> [ReservationConfig] {
        return settings.configurations.filter { $0.isEnabled }
    }
    
    func getConfigurationsForDay(_ weekday: ReservationConfig.Weekday) -> [ReservationConfig] {
        return getEnabledConfigurations().filter { $0.dayTimeSlots[weekday]?.isEmpty == false }
    }
    
    func isAnyConfigurationEnabled() -> Bool {
        return settings.globalEnabled && !getEnabledConfigurations().isEmpty
    }
} 