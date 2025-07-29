import Foundation
import os.log

/// Centralized logging service for consistent logging patterns across the application
@MainActor
public final class LoggingService: ObservableObject {
    public static let shared = LoggingService()

    @Published public var recentLogs: [LogEntry] = []
    private let maxLogEntries = 50
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "LoggingService")

    private init() { }

    public struct LogEntry: Identifiable, Sendable {
        public let id = UUID()
        public let timestamp: Date
        public let message: String
        public let level: LogLevel
        public let configId: UUID?
        public let configName: String?

        public enum LogLevel: String, CaseIterable, Sendable {
            case info = "INFO"
            case warning = "WARNING"
            case error = "ERROR"
            case success = "SUCCESS"
        }
    }

    public func log(
        _ message: String,
        level: LogEntry.LogLevel = .info,
        configId: UUID? = nil,
        configName: String? = nil,
        ) {
        let entry = LogEntry(
            timestamp: Date(),
            message: message,
            level: level,
            configId: configId,
            configName: configName,
            )

        recentLogs.append(entry)

        // Keep only the most recent logs
        if recentLogs.count > maxLogEntries {
            recentLogs.removeFirst(recentLogs.count - maxLogEntries)
        }

        // Also log to system logger for debugging
        switch level {
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .success:
            logger.info("✅ \(message)")
        }
    }

    public func getRecentLogs(for configId: UUID? = nil, limit: Int = 10) -> [LogEntry] {
        let filtered = configId != nil ? recentLogs.filter { $0.configId == configId } : recentLogs
        return Array(filtered.suffix(limit))
    }

    public func clearLogs() {
        recentLogs.removeAll()
    }
}

// MARK: - Logging Service Protocol

public protocol LoggingServiceProtocol: AnyObject {
    func info(_ message: String, category: LoggerCategory)
    func success(_ message: String, category: LoggerCategory)
    func warning(_ message: String, category: LoggerCategory)
    func error(_ message: String, error: Error?, category: LoggerCategory)
    func debug(_ message: String, category: LoggerCategory)
    func logUnifiedError(_ error: UnifiedErrorProtocol, context: String, category: LoggerCategory)
    func logger(for category: LoggerCategory) -> Logger
}

extension LoggingService: LoggingServiceProtocol {
    public nonisolated func info(_ message: String, category _: LoggerCategory) {
        Task { @MainActor in
            log(message, level: .info)
        }
    }

    public nonisolated func success(_ message: String, category _: LoggerCategory) {
        Task { @MainActor in
            log(message, level: .success)
        }
    }

    public nonisolated func warning(_ message: String, category _: LoggerCategory) {
        Task { @MainActor in
            log(message, level: .warning)
        }
    }

    public nonisolated func error(_ message: String, error: Error?, category _: LoggerCategory) {
        Task { @MainActor in
            let fullMessage = error != nil ? "\(message): \(error?.localizedDescription ?? "Unknown error")" : message
            log(fullMessage, level: .error)
        }
    }

    public nonisolated func debug(_ message: String, category _: LoggerCategory) {
        Task { @MainActor in
            log(message, level: .info) // Map debug to info for CLI display
        }
    }

    public nonisolated func logUnifiedError(
        _ error: UnifiedErrorProtocol,
        context: String,
        category _: LoggerCategory,
        ) {
        Task { @MainActor in
            let contextPrefix = context.isEmpty ? "" : "[\(context)] "
            let technicalDetails = error.technicalDetails != nil ? " (\(error.technicalDetails ?? "No details"))" : ""
            let message = "\(contextPrefix)\(error.userFriendlyMessage)\(technicalDetails)"
            log("\(error.errorCode): \(message)", level: .error)
        }
    }

    public nonisolated func logger(for category: LoggerCategory) -> Logger {
        Logger(subsystem: AppConstants.loggingSubsystem, category: category.categoryName)
    }
}
