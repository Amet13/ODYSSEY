import Foundation
import os.log

/// Centralized logging utilities to reduce duplication across the codebase
public enum LoggingUtils {
    // MARK: - Success Messages

    /// Log a success message with standard format
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The success message
    ///   - context: Optional context for the message
    public static func logSuccess(
        _ logger: Logger,
        _ message: String,
        context: String? = nil,
        ) {
        let formattedMessage = context.map { "[\($0)] \(message)" } ?? message
        logger.info("✅ \(formattedMessage)")
    }

    /// Log a success message with privacy protection
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The success message
    ///   - privateData: Data to be marked as private
    ///   - context: Optional context for the message
    public static func logSuccess(
        _ logger: Logger,
        _ message: String,
        privateData _: String,
        context: String? = nil,
        ) {
        let formattedMessage = context.map { "[\($0)] \(message)" } ?? message
        logger.info("✅ \(formattedMessage, privacy: .private)")
    }

    // MARK: - Error Messages

    /// Log an error message with standard format
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The error message
    ///   - context: Optional context for the message
    public static func logError(
        _ logger: Logger,
        _ message: String,
        context: String? = nil,
        ) {
        let formattedMessage = context.map { "[\($0)] \(message)" } ?? message
        logger.error("❌ \(formattedMessage)")
    }

    /// Log an error with privacy protection
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The error message
    ///   - privateData: Data to be marked as private
    ///   - context: Optional context for the message
    public static func logError(
        _ logger: Logger,
        _ message: String,
        privateData _: String,
        context: String? = nil,
        ) {
        let formattedMessage = context.map { "[\($0)] \(message)" } ?? message
        logger.error("❌ \(formattedMessage, privacy: .private)")
    }

    // MARK: - Warning Messages

    /// Log a warning message with standard format
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The warning message
    ///   - context: Optional context for the message
    public static func logWarning(
        _ logger: Logger,
        _ message: String,
        context: String? = nil,
        ) {
        let formattedMessage = context.map { "[\($0)] \(message)" } ?? message
        logger.warning("⚠️ \(formattedMessage)")
    }

    // MARK: - Info Messages

    /// Log an info message with standard format
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The info message
    ///   - context: Optional context for the message
    public static func logInfo(
        _ logger: Logger,
        _ message: String,
        context: String? = nil,
        ) {
        let formattedMessage = context.map { "[\($0)] \(message)" } ?? message
        logger.info("ℹ️ \(formattedMessage)")
    }

    /// Log an info message with privacy protection
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The info message
    ///   - privateData: Data to be marked as private
    ///   - context: Optional context for the message
    public static func logInfo(
        _ logger: Logger,
        _ message: String,
        privateData _: String,
        context: String? = nil,
        ) {
        let formattedMessage = context.map { "[\($0)] \(message)" } ?? message
        logger.info("ℹ️ \(formattedMessage, privacy: .private)")
    }

    // MARK: - Step Messages

    /// Log a step message (for progress tracking)
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The step message
    ///   - context: Optional context for the message
    public static func logStep(
        _ logger: Logger,
        _ message: String,
        context: String? = nil,
        ) {
        let formattedMessage = context.map { "[\($0)] \(message)" } ?? message
        logger.info("📋 \(formattedMessage)")
    }

    // MARK: - Service Messages

    /// Log a service-related message
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - service: The service name
    ///   - message: The message
    ///   - isSuccess: Whether this is a success message
    public static func logService(
        _ logger: Logger,
        service: String,
        _ message: String,
        isSuccess: Bool = true,
        ) {
        let emoji = isSuccess ? "✅" : "❌"
        logger.info("\(emoji) \(service): \(message)")
    }

    // MARK: - Cleanup Messages

    /// Log a cleanup message
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The cleanup message
    ///   - context: Optional context for the message
    public static func logCleanup(
        _ logger: Logger,
        _ message: String,
        context: String? = nil,
        ) {
        let formattedMessage = context.map { "[\($0)] \(message)" } ?? message
        logger.info("🧹 \(formattedMessage)")
    }

    // MARK: - Connection Messages

    /// Log a connection-related message
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The connection message
    ///   - isSuccess: Whether this is a success message
    public static func logConnection(
        _ logger: Logger,
        _ message: String,
        isSuccess: Bool = true,
        ) {
        let emoji = isSuccess ? "🔗" : "❌"
        logger.info("\(emoji) \(message)")
    }

    // MARK: - Navigation Messages

    /// Log a navigation-related message
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The navigation message
    ///   - isSuccess: Whether this is a success message
    public static func logNavigation(
        _ logger: Logger,
        _ message: String,
        isSuccess: Bool = true,
        ) {
        let emoji = isSuccess ? "🧭" : "❌"
        logger.info("\(emoji) \(message)")
    }

    // MARK: - Automation Messages

    /// Log an automation-related message
    /// - Parameters:
    ///   - logger: The logger instance
    ///   - message: The automation message
    ///   - isSuccess: Whether this is a success message
    public static func logAutomation(
        _ logger: Logger,
        _ message: String,
        isSuccess: Bool = true,
        ) {
        let emoji = isSuccess ? "🤖" : "❌"
        logger.info("\(emoji) \(message)")
    }
}
