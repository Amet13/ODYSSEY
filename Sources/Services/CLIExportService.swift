import CryptoKit
import Foundation
import os.log

/// Service for exporting ODYSSEY configurations for CLI use
@MainActor
public final class CLIExportService: ObservableObject {
    public static let shared = CLIExportService()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "CLIExportService")

    public init() { }

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
            version: String = "1.0.0"
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
            logger.info("🔍 Config \(index + 1): \(config.name)")
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

        logger.info("✅ CI export created with \(selectedConfigs.count) configurations")

        return base64String
    }

    /// Generate GitHub Actions workflow content
    public func generateGitHubActionsWorkflow(exportToken _: String, cronSchedule: String = "0 18 * * *") -> String {
        return """
        name: ODYSSEY Reservation Automation

        on:
          schedule:
            - cron: '\(cronSchedule)'  # 6:00 PM daily
          workflow_dispatch:  # Allow manual runs

        jobs:
          run-reservations:
            runs-on: macos-latest

            steps:
              - name: Checkout code
                uses: actions/checkout@v4

              - name: Download ODYSSEY CLI
                run: |
                  # Download latest CLI from releases
                  curl -L -o odyssey-cli "https://github.com/Amet13/ODYSSEY/releases/latest/download/odyssey-cli-$(curl -s https://api.github.com/repos/Amet13/ODYSSEY/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)"
                  chmod +x odyssey-cli

              - name: Run Reservations
                run: ./odyssey-cli run
                env:
                  ODYSSEY_EXPORT_TOKEN: ${{ secrets.ODYSSEY_EXPORT_TOKEN }}

              - name: Upload Logs
                if: always()
                uses: actions/upload-artifact@v4
                with:
                  name: odyssey-logs
                  path: |
                    ~/.odyssey-cli/
                    *.log
        """
    }

    /// Generate setup instructions
    public func generateSetupInstructions(exportToken: String) -> String {
        return """
        # ODYSSEY CLI Setup Instructions

        ## 1. GitHub Repository Setup

        Create a new GitHub repository and add this secret:

        ### Required Secret:
        - `ODYSSEY_EXPORT_TOKEN`: \(exportToken)

        ## 2. Add Workflow File

        Create `.github/workflows/odyssey.yml` with the generated workflow content.

        ## 3. Schedule

        The workflow will run automatically at 6:00 PM daily.
        You can also trigger it manually from the Actions tab.

        ## 4. Monitoring

        Check the Actions tab to monitor runs and download logs.

        ## Security Notes:
        - All secrets are encrypted by GitHub
        - The CLI runs in a clean macOS environment
        - No data is stored permanently on GitHub servers
        - Uses pre-built CLI binaries from releases (no compilation needed)
        """
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
