import Foundation
import os.log

/// Centralized logging service for consistent logging patterns across the application
@MainActor
public final class LoggingService: ObservableObject {
    public static let shared = LoggingService()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "LoggingService")

    private init() { }

    /// Logs info messages with consistent formatting
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category/context for the log
    public nonisolated func info(_ message: String, category: String = "General") {
        logger.info("ℹ️ [\(category)] \(message)")
    }

    /// Logs success messages with consistent formatting
    /// - Parameters:
    ///   - message: The success message to log
    ///   - category: The category/context for the log
    public nonisolated func success(_ message: String, category: String = "General") {
        logger.info("✅ [\(category)] \(message)")
    }

    /// Logs warning messages with consistent formatting
    /// - Parameters:
    ///   - message: The warning message to log
    ///   - category: The category/context for the log
    public nonisolated func warning(_ message: String, category: String = "General") {
        logger.warning("⚠️ [\(category)] \(message)")
    }

    /// Logs error messages with consistent formatting
    /// - Parameters:
    ///   - message: The error message to log
    ///   - error: Optional error object
    ///   - category: The category/context for the log
    public nonisolated func error(_ message: String, error: Error? = nil, category: String = "General") {
        let fullMessage = error != nil ? "\(message): \(error!.localizedDescription)" : message
        logger.error("❌ [\(category)] \(fullMessage)")
    }

    /// Logs debug messages with consistent formatting
    /// - Parameters:
    ///   - message: The debug message to log
    ///   - category: The category/context for the log
    public nonisolated func debug(_ message: String, category: String = "General") {
        logger.debug("🔍 [\(category)] \(message)")
    }

    /// Creates a logger for a specific category
    /// - Parameter category: The category name
    /// - Returns: A Logger instance for the specified category
    public nonisolated func logger(for category: String) -> Logger {
        Logger(subsystem: "com.odyssey.app", category: category)
    }
}

// MARK: - Logging Service Protocol

public protocol LoggingServiceProtocol: AnyObject {
    func info(_ message: String, category: String)
    func success(_ message: String, category: String)
    func warning(_ message: String, category: String)
    func error(_ message: String, error: Error?, category: String)
    func debug(_ message: String, category: String)
    func logger(for category: String) -> Logger
}

extension LoggingService: LoggingServiceProtocol { }
