import Foundation
import os.log

/**
 AuditLogEntry represents a single audit log entry.
 */
public struct AuditLogEntry: Codable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let type: AuditLogType
    public let message: String
    public let configId: UUID?
    public let configName: String?
    public let runType: ReservationRunType?
    public let status: ReservationRunStatus?
    public let errorMessage: String?
    public let metadata: [String: String]

    public init(
        type: AuditLogType,
        message: String,
        configId: UUID? = nil,
        configName: String? = nil,
        runType: ReservationRunType? = nil,
        status: ReservationRunStatus? = nil,
        errorMessage: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.message = message
        self.configId = configId
        self.configName = configName
        self.runType = runType
        self.status = status
        self.errorMessage = errorMessage
        self.metadata = metadata
    }
}

/**
 AuditLogType defines the different types of audit log entries.
 */
public enum AuditLogType: String, Codable, CaseIterable, Sendable {
    case reservationStarted = "reservation_started"
    case reservationSuccess = "reservation_success"
    case reservationFailure = "reservation_failure"
    case autorunScheduled = "autorun_scheduled"
    case autorunTriggered = "autorun_triggered"
    case configurationAdded = "configuration_added"
    case configurationUpdated = "configuration_updated"
    case configurationDeleted = "configuration_deleted"
    case settingsChanged = "settings_changed"
    case systemError = "system_error"
    case systemWarning = "system_warning"
    case emailTest = "email_test"
    case webkitError = "webkit_error"
    case userAction = "user_action"

    public var displayName: String {
        switch self {
        case .reservationStarted: return "Reservation Started"
        case .reservationSuccess: return "Reservation Success"
        case .reservationFailure: return "Reservation Failure"
        case .autorunScheduled: return "Autorun Scheduled"
        case .autorunTriggered: return "Autorun Triggered"
        case .configurationAdded: return "Configuration Added"
        case .configurationUpdated: return "Configuration Updated"
        case .configurationDeleted: return "Configuration Deleted"
        case .settingsChanged: return "Settings Changed"
        case .systemError: return "System Error"
        case .systemWarning: return "System Warning"
        case .emailTest: return "Email Test"
        case .webkitError: return "WebKit Error"
        case .userAction: return "User Action"
        }
    }

    public var emoji: String {
        switch self {
        case .reservationStarted: return "🔄"
        case .reservationSuccess: return "✅"
        case .reservationFailure: return "❌"
        case .autorunScheduled: return "⏰"
        case .autorunTriggered: return "🚀"
        case .configurationAdded: return "➕"
        case .configurationUpdated: return "✏️"
        case .configurationDeleted: return "🗑️"
        case .settingsChanged: return "⚙️"
        case .systemError: return "🚨"
        case .systemWarning: return "⚠️"
        case .emailTest: return "📧"
        case .webkitError: return "🌐"
        case .userAction: return "👤"
        }
    }
}

/**
 AuditLogService manages audit logging for automation runs, errors, and changes.

 Provides comprehensive tracking of all app activities with privacy controls
 and user-friendly viewing capabilities.

 ## Usage Example
 ```swift
 let auditService = AuditLogService.shared
 auditService.logReservationStarted(config: config, runType: .manual)
 auditService.logReservationSuccess(config: config)
 ```
 */
@MainActor
public final class AuditLogService: ObservableObject, @unchecked Sendable {
    public static let shared = AuditLogService()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "AuditLogService")
    private let userDefaults = UserDefaults.standard
    private let auditLogKey = "ODYSSEY_AuditLog"

    @Published public private(set) var auditLog: [AuditLogEntry] = []
    @Published public var isLoggingEnabled = true
    @Published public var maxLogEntries = 1_000 // Keep last 1000 entries

    private init() {
        loadAuditLog()
        logger.info("🔧 AuditLogService initialized.")
    }

    // MARK: - Logging Methods

    /**
     Logs a reservation start event.
     - Parameters:
     - config: The reservation configuration
     - runType: The type of run (manual/automatic)
     */
    public func logReservationStarted(config: ReservationConfig, runType: ReservationRunType) {
        let entry = AuditLogEntry(
            type: .reservationStarted,
            message: "Started \(config.sportName) reservation at \(ReservationConfig.extractFacilityName(from: config.facilityURL))",
            configId: config.id,
            configName: config.name,
            runType: runType,
            metadata: [
                "sport": config.sportName,
                "facility": ReservationConfig.extractFacilityName(from: config.facilityURL),
                "runType": runType.rawValue
            ],
            )
        addEntry(entry)
    }

    /**
     Logs a successful reservation.
     - Parameter config: The reservation configuration
     */
    public func logReservationSuccess(config: ReservationConfig) {
        let entry = AuditLogEntry(
            type: .reservationSuccess,
            message: "Successfully booked \(config.sportName) at \(ReservationConfig.extractFacilityName(from: config.facilityURL))",
            configId: config.id,
            configName: config.name,
            status: .success,
            metadata: [
                "sport": config.sportName,
                "facility": ReservationConfig.extractFacilityName(from: config.facilityURL)
            ],
            )
        addEntry(entry)
    }

    /**
     Logs a failed reservation.
     - Parameters:
     - config: The reservation configuration
     - error: The error message
     - runType: The type of run
     */
    public func logReservationFailure(config: ReservationConfig, error: String, runType: ReservationRunType) {
        let entry = AuditLogEntry(
            type: .reservationFailure,
            message: "Failed to book \(config.sportName): \(error)",
            configId: config.id,
            configName: config.name,
            runType: runType,
            status: .failed(error),
            errorMessage: error,
            metadata: [
                "sport": config.sportName,
                "facility": ReservationConfig.extractFacilityName(from: config.facilityURL),
                "runType": runType.rawValue
            ],
            )
        addEntry(entry)
    }

    /**
     Logs an autorun scheduling event.
     - Parameter config: The reservation configuration
     - Parameter scheduledTime: When the autorun is scheduled
     */
    public func logAutorunScheduled(config: ReservationConfig, scheduledTime: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        let entry = AuditLogEntry(
            type: .autorunScheduled,
            message: "Scheduled autorun for \(config.sportName) at \(formatter.string(from: scheduledTime))",
            configId: config.id,
            configName: config.name,
            metadata: [
                "sport": config.sportName,
                "scheduledTime": formatter.string(from: scheduledTime)
            ],
            )
        addEntry(entry)
    }

    /**
     Logs an autorun trigger event.
     - Parameter config: The reservation configuration
     */
    public func logAutorunTriggered(config: ReservationConfig) {
        let entry = AuditLogEntry(
            type: .autorunTriggered,
            message: "Autorun triggered for \(config.sportName)",
            configId: config.id,
            configName: config.name,
            runType: .automatic,
            metadata: [
                "sport": config.sportName,
                "facility": ReservationConfig.extractFacilityName(from: config.facilityURL)
            ],
            )
        addEntry(entry)
    }

    /**
     Logs a configuration addition.
     - Parameter config: The added configuration
     */
    public func logConfigurationAdded(config: ReservationConfig) {
        let entry = AuditLogEntry(
            type: .configurationAdded,
            message: "Added configuration: \(config.name)",
            configId: config.id,
            configName: config.name,
            metadata: [
                "sport": config.sportName,
                "facility": ReservationConfig.extractFacilityName(from: config.facilityURL)
            ],
            )
        addEntry(entry)
    }

    /**
     Logs a configuration update.
     - Parameter config: The updated configuration
     */
    public func logConfigurationUpdated(config: ReservationConfig) {
        let entry = AuditLogEntry(
            type: .configurationUpdated,
            message: "Updated configuration: \(config.name)",
            configId: config.id,
            configName: config.name,
            metadata: [
                "sport": config.sportName,
                "facility": ReservationConfig.extractFacilityName(from: config.facilityURL)
            ],
            )
        addEntry(entry)
    }

    /**
     Logs a configuration deletion.
     - Parameter configName: The name of the deleted configuration
     - Parameter configId: The ID of the deleted configuration
     */
    public func logConfigurationDeleted(configName: String, configId: UUID) {
        let entry = AuditLogEntry(
            type: .configurationDeleted,
            message: "Deleted configuration: \(configName)",
            configId: configId,
            configName: configName,
            )
        addEntry(entry)
    }

    /**
     Logs a settings change.
     - Parameter setting: The setting that was changed
     - Parameter oldValue: The old value
     - Parameter newValue: The new value
     */
    public func logSettingsChanged(setting: String, oldValue: String, newValue: String) {
        let entry = AuditLogEntry(
            type: .settingsChanged,
            message: "Changed \(setting) from \(oldValue) to \(newValue)",
            metadata: [
                "setting": setting,
                "oldValue": oldValue,
                "newValue": newValue
            ],
            )
        addEntry(entry)
    }

    /**
     Logs a system error.
     - Parameters:
     - error: The error message
     - context: Additional context
     */
    public func logSystemError(_ error: String, context: String? = nil) {
        let message = context != nil ? "\(context!): \(error)" : error
        let entry = AuditLogEntry(
            type: .systemError,
            message: message,
            errorMessage: error,
            metadata: context != nil ? ["context": context!] : [:],
            )
        addEntry(entry)
    }

    /**
     Logs a system warning.
     - Parameters:
     - warning: The warning message
     - context: Additional context
     */
    public func logSystemWarning(_ warning: String, context: String? = nil) {
        let message = context != nil ? "\(context!): \(warning)" : warning
        let entry = AuditLogEntry(
            type: .systemWarning,
            message: message,
            metadata: context != nil ? ["context": context!] : [:],
            )
        addEntry(entry)
    }

    /**
     Logs an email test event.
     - Parameter success: Whether the test was successful
     - Parameter error: Error message if failed
     */
    public func logEmailTest(success: Bool, error: String? = nil) {
        let message = success ? "Email test successful" : "Email test failed: \(error ?? "Unknown error")"
        let entry = AuditLogEntry(
            type: .emailTest,
            message: message,
            errorMessage: error,
            metadata: ["success": String(success)],
            )
        addEntry(entry)
    }

    /**
     Logs a WebKit error.
     - Parameters:
     - error: The error message
     - configId: The configuration ID if applicable
     */
    public func logWebKitError(_ error: String, configId: UUID? = nil) {
        let entry = AuditLogEntry(
            type: .webkitError,
            message: "WebKit error: \(error)",
            configId: configId,
            errorMessage: error,
            )
        addEntry(entry)
    }

    /**
     Logs a user action.
     - Parameter action: The action description
     - Parameter metadata: Additional metadata
     */
    public func logUserAction(_ action: String, metadata: [String: String] = [:]) {
        let entry = AuditLogEntry(
            type: .userAction,
            message: action,
            metadata: metadata,
            )
        addEntry(entry)
    }

    // MARK: - Query Methods

    /**
     Gets audit log entries filtered by type.
     - Parameter type: The type to filter by
     - Returns: Filtered audit log entries
     */
    public func getEntries(of type: AuditLogType) -> [AuditLogEntry] {
        return auditLog.filter { $0.type == type }
    }

    /**
     Gets audit log entries for a specific configuration.
     - Parameter configId: The configuration ID
     - Returns: Filtered audit log entries
     */
    public func getEntries(for configId: UUID) -> [AuditLogEntry] {
        return auditLog.filter { $0.configId == configId }
    }

    /**
     Gets audit log entries within a date range.
     - Parameters:
     - startDate: Start date
     - endDate: End date
     - Returns: Filtered audit log entries
     */
    public func getEntries(from startDate: Date, to endDate: Date) -> [AuditLogEntry] {
        return auditLog.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    /**
     Gets recent audit log entries.
     - Parameter count: Number of entries to return
     - Returns: Recent audit log entries
     */
    public func getRecentEntries(_ count: Int = 50) -> [AuditLogEntry] {
        return Array(auditLog.suffix(count))
    }

    /**
     Gets error entries from the audit log.
     - Returns: Error audit log entries
     */
    public func getErrorEntries() -> [AuditLogEntry] {
        return auditLog.filter { $0.type == .reservationFailure || $0.type == .systemError || $0.type == .webkitError }
    }

    // MARK: - Management Methods

    /**
     Clears all audit log entries.
     */
    public func clearAuditLog() {
        auditLog.removeAll()
        saveAuditLog()
        logger.info("🧹 Audit log cleared.")
    }

    /**
     Exports audit log to JSON format.
     - Returns: JSON string representation of audit log
     */
    public func exportAuditLog() -> String? {
        do {
            let data = try JSONEncoder().encode(auditLog)
            return String(data: data, encoding: .utf8)
        } catch {
            logger.error("❌ Failed to export audit log: \(error.localizedDescription).")
            return nil
        }
    }

    /**
     Gets audit log statistics.
     - Returns: Dictionary with statistics
     */
    public func getAuditLogStats() -> [String: Any] {
        let totalEntries = auditLog.count
        let errorCount = getErrorEntries().count
        let successCount = getEntries(of: .reservationSuccess).count
        let failureCount = getEntries(of: .reservationFailure).count

        let typeCounts = Dictionary(grouping: auditLog, by: { $0.type })
            .mapValues { $0.count }

        return [
            "totalEntries": totalEntries,
            "errorCount": errorCount,
            "successCount": successCount,
            "failureCount": failureCount,
            "typeCounts": typeCounts,
            "dateRange": [
                "oldest": auditLog.first?.timestamp,
                "newest": auditLog.last?.timestamp
            ]
        ]
    }

    // MARK: - Private Methods

    private func addEntry(_ entry: AuditLogEntry) {
        guard isLoggingEnabled else { return }

        auditLog.append(entry)

        // Trim to max entries
        if auditLog.count > maxLogEntries {
            auditLog = Array(auditLog.suffix(maxLogEntries))
        }

        saveAuditLog()
        logger.info("📝 Audit log entry added: \(entry.type.emoji) \(entry.message).")
    }

    private func saveAuditLog() {
        do {
            let data = try JSONEncoder().encode(auditLog)
            userDefaults.set(data, forKey: auditLogKey)
        } catch {
            logger.error("❌ Failed to save audit log: \(error.localizedDescription).")
        }
    }

    private func loadAuditLog() {
        guard let data = userDefaults.data(forKey: auditLogKey) else { return }

        do {
            auditLog = try JSONDecoder().decode([AuditLogEntry].self, from: data)
            logger.info("📝 Loaded \(self.auditLog.count) audit log entries.")
        } catch {
            logger.error("❌ Failed to load audit log: \(error.localizedDescription).")
            auditLog = []
        }
    }
}
