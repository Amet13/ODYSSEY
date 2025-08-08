import CryptoKit
import Foundation
import os.log

/// Service for exporting ODYSSEY configurations for CLI use
@MainActor
public final class CLIExportService: ObservableObject {
  public static let shared = CLIExportService()

  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem, category: "CLIExportService")

  public init() {}

  /// Simplified User Settings for CLI export (excludes language, custom time, and email provider)
  public struct CLIUserSettings: Codable, Sendable {
    public let phoneNumber: String
    public let name: String
    public let imapEmail: String
    public let imapPassword: String
    public let imapServer: String
    public let preventSleepForAutorun: Bool
    public let autoCloseDebugWindowOnFailure: Bool
    public let showBrowserWindow: Bool

    public init(from userSettings: UserSettings) {
      self.phoneNumber = userSettings.phoneNumber
      self.name = userSettings.name
      self.imapEmail = userSettings.imapEmail
      self.imapPassword = userSettings.imapPassword
      self.imapServer = userSettings.imapServer
      self.preventSleepForAutorun = userSettings.preventSleepForAutorun
      self.autoCloseDebugWindowOnFailure = userSettings.autoCloseDebugWindowOnFailure
      self.showBrowserWindow = userSettings.showBrowserWindow
    }
  }

  /// CLI Export Configuration with selected configs and simplified user settings
  public struct CLIExportConfig: Codable, Sendable {
    public let userSettings: CLIUserSettings
    public let selectedConfigurations: [ReservationConfig]
    public let exportDate: Date
    public let version: String
    public let exportId: String

    public init(
      userSettings: UserSettings,
      selectedConfigurations: [ReservationConfig],
      version: String = "1.2.1"
    ) {
      self.userSettings = CLIUserSettings(from: userSettings)
      self.selectedConfigurations = selectedConfigurations
      self.exportDate = Date()
      self.version = version
      self.exportId = UUID().uuidString
    }
  }

  /// Export configuration for CLI use
  public func exportForCLI(selectedConfigIds: [String]) async throws -> String {
    let configManager = ConfigurationManager.shared
    let userSettingsManager = UserSettingsManager.shared

    // Get selected configurations
    let selectedConfigs = configManager.settings.configurations.filter { config in
      selectedConfigIds.contains(config.id.uuidString)
    }

    guard !selectedConfigs.isEmpty else {
      throw CLIExportError.noConfigurationsSelected
    }

    for (index, config) in selectedConfigs.enumerated() {
      logger.info("🔍 Config \(index + 1): \(config.name).")
      logger.info("   - Day time slots count: \(config.dayTimeSlots.count)")
      for (day, slots) in config.dayTimeSlots {
        logger.info("   - \(day.rawValue): \(slots.count) slots")
        for slot in slots {
          let formatter = DateFormatter()
          formatter.timeStyle = .short
          logger.info("     - \(formatter.string(from: slot.time))")
        }
      }
    }

    // Create export config
    let exportConfig = CLIExportConfig(
      userSettings: userSettingsManager.userSettings,
      selectedConfigurations: selectedConfigs,
    )

    // Encode to JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try encoder.encode(exportConfig)

    // Compress and encode to base64
    let compressedData = try (jsonData as NSData).compressed(using: .lzfse)
    let base64String = compressedData.base64EncodedString()

    logger.info("✅ CI export created with \(selectedConfigs.count) configurations.")

    return base64String
  }
}

// MARK: - Errors

public enum CLIExportError: LocalizedError, UnifiedErrorProtocol {
  case noConfigurationsSelected
  case invalidBase64
  case compressionFailed

  public var errorDescription: String? {
    return userFriendlyMessage
  }

  /// Unique error code for categorization and debugging
  public var errorCode: String {
    switch self {
    case .noConfigurationsSelected: return "CLI_EXPORT_NOSELECT_001"
    case .invalidBase64: return "CLI_EXPORT_BASE64_001"
    case .compressionFailed: return "CLI_EXPORT_COMPRESS_001"
    }
  }

  /// Category for grouping similar errors
  public var errorCategory: ErrorCategory {
    switch self {
    case .noConfigurationsSelected: return .validation
    case .invalidBase64, .compressionFailed: return .system
    }
  }

  /// User-friendly error message for UI display
  public var userFriendlyMessage: String {
    switch self {
    case .noConfigurationsSelected:
      return "No configurations selected for export"
    case .invalidBase64:
      return "Invalid base64 encoded configuration"
    case .compressionFailed:
      return "Failed to compress configuration data"
    }
  }

  /// Technical details for debugging (optional)
  public var technicalDetails: String? {
    switch self {
    case .noConfigurationsSelected: return "No configurations were selected for CLI export"
    case .invalidBase64: return "Base64 decoding failed for configuration data"
    case .compressionFailed: return "Data compression failed during CLI export"
    }
  }
}
