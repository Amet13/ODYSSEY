import Combine
import Foundation
import os.log

/// Manages application configuration and settings persistence.
@MainActor
public final class ConfigurationManager: ObservableObject, @unchecked Sendable {
  public static let shared = ConfigurationManager()

  @Published public var settings: AppSettings {
    didSet {
      saveSettings()
    }
  }

  private let userDefaults: UserDefaults
  private let settingsKey: String
  private let logger: Logger

  /// Main initializer supporting dependency injection for logger and userDefaults.
  /// - Parameters:
  ///   - logger: Logger instance (default: ODYSSEY ConfigurationManager logger).
  ///   - userDefaults: UserDefaults instance (default: .standard).
  ///   - settingsKey: Key for storing settings (default: "ODYSSEY_Settings").
  public init(
    logger: Logger = Logger(
      subsystem: AppConstants.loggingSubsystem, category: "ConfigurationManager"),
    userDefaults: UserDefaults = .standard,
    settingsKey: String = "ODYSSEY_Settings"
  ) {
    self.logger = logger
    self.userDefaults = userDefaults
    self.settingsKey = settingsKey
    // Load saved settings or use defaults.
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

  // Keep the default singleton for app use.
  private convenience init() {
    self.init(
      logger: Logger(subsystem: AppConstants.loggingSubsystem, category: "ConfigurationManager"),
      userDefaults: .standard,
      settingsKey: "ODYSSEY_Settings",
    )
  }

  // MARK: - Configuration Management

  public func addConfiguration(_ config: ReservationConfig) {
    settings.configurations.append(config)
    saveSettings()

    logger.info("➕ Configuration '\(config.name)' added.")
  }

  public func updateConfiguration(_ config: ReservationConfig) {
    if let index = settings.configurations.firstIndex(where: { $0.id == config.id }) {
      settings.configurations[index] = config
      saveSettings()

      logger.info("✏️ Configuration '\(config.name)' updated.")
    } else {
      logger.warning("⚠️ Configuration not found for update: \(config.id).")
    }
  }

  public func removeConfiguration(_ config: ReservationConfig) {
    settings.configurations.removeAll { $0.id == config.id }
    saveSettings()

    logger.info("🗑️ Configuration '\(config.name)' deleted.")
  }

  public func toggleConfiguration(at index: Int) {
    guard index < settings.configurations.count else { return }

    settings.configurations[index].isEnabled.toggle()
    saveSettings()

    let configName = settings.configurations[index].name
    let isEnabled = settings.configurations[index].isEnabled
    let status = isEnabled ? "enabled" : "disabled"
    logger.info("📝 Configuration '\(configName)' \(status).")
  }

  // MARK: - Configuration Queries

  public func getEnabledConfigurations() -> [ReservationConfig] {
    settings.configurations.filter(\.isEnabled)
  }

  public func getConfigurationsForDay(_ weekday: ReservationConfig.Weekday) -> [ReservationConfig] {
    getEnabledConfigurations().filter { $0.dayTimeSlots[weekday]?.isEmpty == false }
  }

  // MARK: - Settings Management

  private func saveSettings() {
    do {
      let data = try JSONEncoder().encode(settings)
      userDefaults.set(data, forKey: settingsKey)
    } catch {
      logger.error("❌ Failed to save settings: \(error.localizedDescription).")
    }
  }
}
