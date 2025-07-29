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
    public nonisolated func info(_ message: String, category: LoggerCategory = .general) {
        logger.info("\(category.emoji) [\(category.categoryName)] \(message)")
    }

    /// Logs success messages with consistent formatting
    /// - Parameters:
    ///   - message: The success message to log
    ///   - category: The category/context for the log
    public nonisolated func success(_ message: String, category: LoggerCategory = .general) {
        logger.info("✅ [\(category.categoryName)] \(message)")
    }

    /// Logs warning messages with consistent formatting
    /// - Parameters:
    ///   - message: The warning message to log
    ///   - category: The category/context for the log
    public nonisolated func warning(_ message: String, category: LoggerCategory = .general) {
        logger.warning("⚠️ [\(category.categoryName)] \(message)")
    }

    /// Logs error messages with consistent formatting
    /// - Parameters:
    ///   - message: The error message to log
    ///   - error: Optional error object
    ///   - category: The category/context for the log
    public nonisolated func error(_ message: String, error: Error? = nil, category: LoggerCategory = .general) {
        let fullMessage = error != nil ? "\(message): \(error!.localizedDescription)" : message
        logger.error("❌ [\(category.categoryName)] \(fullMessage)")
    }

    /// Logs debug messages with consistent formatting
    /// - Parameters:
    ///   - message: The debug message to log
    ///   - category: The category/context for the log
    public nonisolated func debug(_ message: String, category: LoggerCategory = .general) {
        logger.debug("🔍 [\(category.categoryName)] \(message)")
    }

    /// Logs unified errors with enhanced formatting
    /// - Parameters:
    ///   - error: The unified error to log
    ///   - context: Additional context information
    ///   - category: The category/context for the log
    public nonisolated func logUnifiedError(
        _ error: UnifiedErrorProtocol,
        context: String = "",
        category: LoggerCategory = .general,
        ) {
        let contextPrefix = context.isEmpty ? "" : "[\(context)] "
        let technicalDetails = error.technicalDetails != nil ? " (\(error.technicalDetails!))" : ""
        let message = "\(contextPrefix)\(error.userFriendlyMessage)\(technicalDetails)"
        logger.error("\(error.errorCategory.emoji) [\(category.categoryName)] \(error.errorCode): \(message)")
    }

    /// Creates a logger for a specific category
    /// - Parameter category: The category name
    /// - Returns: A Logger instance for the specified category
    public nonisolated func logger(for category: LoggerCategory) -> Logger {
        Logger(subsystem: "com.odyssey.app", category: category.categoryName)
    }

    /// Creates a logger for a specific category using string (for backward compatibility)
    /// - Parameter category: The category name
    /// - Returns: A Logger instance for the specified category
    public nonisolated func logger(for category: String) -> Logger {
        Logger(subsystem: "com.odyssey.app", category: category)
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

extension LoggingService: LoggingServiceProtocol { }
