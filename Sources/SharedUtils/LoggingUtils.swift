import Foundation
import os

/// Centralized logging utilities to reduce duplication across the codebase
public enum LoggingUtils {
  private static func ensureTrailingPeriod(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.hasSuffix(".") { return text }
    return trimmed + "."
  }
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
    let base = context.map { "[\($0)] \(message)" } ?? message
    let formattedMessage = ensureTrailingPeriod(base)
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
    let base = context.map { "[\($0)] \(message)" } ?? message
    let formattedMessage = ensureTrailingPeriod(base)
    logger.info("✅ \(formattedMessage, privacy: .private)")
  }

  // MARK: - Error Messages

  /// Log an error message with standard format.
  /// - Parameters:
  ///   - logger: The logger instance.
  ///   - message: The error message.
  ///   - context: Optional context for the message.
  public static func logError(
    _ logger: Logger,
    _ message: String,
    context: String? = nil,
  ) {
    let base = context.map { "[\($0)] \(message)" } ?? message
    let formattedMessage = ensureTrailingPeriod(base)
    logger.error("❌ \(formattedMessage)")
  }

  /// Log an error with privacy protection.
  /// - Parameters:
  ///   - logger: The logger instance.
  ///   - message: The error message.
  ///   - privateData: Data to be marked as private.
  ///   - context: Optional context for the message.
  public static func logError(
    _ logger: Logger,
    _ message: String,
    privateData _: String,
    context: String? = nil,
  ) {
    let base = context.map { "[\($0)] \(message)" } ?? message
    let formattedMessage = ensureTrailingPeriod(base)
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
    let base = context.map { "[\($0)] \(message)" } ?? message
    let formattedMessage = ensureTrailingPeriod(base)
    logger.warning("⚠️ \(formattedMessage)")
  }

  // MARK: - Info Messages

  /// Log an info message with standard format.
  /// - Parameters:
  ///   - logger: The logger instance.
  ///   - message: The info message.
  ///   - context: Optional context for the message.
  public static func logInfo(
    _ logger: Logger,
    _ message: String,
    context: String? = nil,
  ) {
    let base = context.map { "[\($0)] \(message)" } ?? message
    let formattedMessage = ensureTrailingPeriod(base)
    logger.info("ℹ️ \(formattedMessage)")
  }

  /// Log an info message with privacy protection.
  /// - Parameters:
  ///   - logger: The logger instance.
  ///   - message: The info message.
  ///   - privateData: Data to be marked as private.
  ///   - context: Optional context for the message.
  public static func logInfo(
    _ logger: Logger,
    _ message: String,
    privateData _: String,
    context: String? = nil,
  ) {
    let base = context.map { "[\($0)] \(message)" } ?? message
    let formattedMessage = ensureTrailingPeriod(base)
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
    let base = context.map { "[\($0)] \(message)" } ?? message
    let formattedMessage = ensureTrailingPeriod(base)
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
    let formattedMessage = ensureTrailingPeriod(message)
    logger.info("\(emoji) \(service): \(formattedMessage)")
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
    let base = context.map { "[\($0)] \(message)" } ?? message
    let formattedMessage = ensureTrailingPeriod(base)
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
    let formattedMessage = ensureTrailingPeriod(message)
    logger.info("\(emoji) \(formattedMessage)")
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
    let formattedMessage = ensureTrailingPeriod(message)
    logger.info("\(emoji) \(formattedMessage)")
  }

  // MARK: - Automation Messages

  /// Log an automation-related message.
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
    let formattedMessage = ensureTrailingPeriod(message)
    logger.info("\(emoji) \(formattedMessage)")
  }

  // MARK: - Common Logging Patterns

  /// Log a success message with standard format
  /// - Parameters:
  ///   - logger: The logger instance
  ///   - message: The success message
  public static func logSuccess(_ logger: Logger, _ message: String) {
    let formattedMessage = ensureTrailingPeriod(message)
    logger.info("✅ \(formattedMessage)")
  }

  /// Log an error message with standard format
  /// - Parameters:
  ///   - logger: The logger instance
  ///   - message: The error message
  public static func logError(_ logger: Logger, _ message: String) {
    let formattedMessage = ensureTrailingPeriod(message)
    logger.error("❌ \(formattedMessage)")
  }

  /// Log a warning message with standard format
  /// - Parameters:
  ///   - logger: The logger instance
  ///   - message: The warning message
  public static func logWarning(_ logger: Logger, _ message: String) {
    let formattedMessage = ensureTrailingPeriod(message)
    logger.warning("⚠️ \(formattedMessage)")
  }

  /// Log an initialization message with standard format.
  /// - Parameters:
  ///   - logger: The logger instance
  ///   - serviceName: The name of the service being initialized
  public static func logInitialization(_ logger: Logger, _ serviceName: String) {
    logger.info("🔧 \(serviceName) initialized.")
  }

  /// Log a deinitialization message with standard format
  /// - Parameters:
  ///   - logger: The logger instance
  ///   - serviceName: The name of the service being deinitialized
  public static func logDeinitialization(_ logger: Logger, _ serviceName: String) {
    logger.info("🧹 \(serviceName) deinitialized.")
  }
}
