import Foundation
import os.log

// MARK: - Centralized Logging Service

/// Centralized logging service to consolidate logging patterns across the codebase
/// Reduces logger instances and provides consistent logging behavior
@MainActor
public final class CentralizedLoggingService {
    public static let shared = CentralizedLoggingService()

    // MARK: - Log Categories

    public enum LogCategory: String, CaseIterable {
        case app = "App"
        case webKit = "WebKit"
        case email = "Email"
        case reservation = "Reservation"
        case validation = "Validation"
        case network = "Network"
        case automation = "Automation"
        case ui = "UI"
        case cli = "CLI"
        case debug = "Debug"

        var logger: Logger {
            return Logger(subsystem: AppConstants.loggingSubsystem, category: rawValue)
        }
    }

    // MARK: - Log Levels

    public enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"

        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }

    // MARK: - Logging Methods

    /// Log a debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category (default: .debug)
    public func debug(_ message: String, category: LogCategory = .debug) {
        category.logger.debug("\(LogLevel.debug.emoji) \(message)")
    }

    /// Log an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category (default: .app)
    public func info(_ message: String, category: LogCategory = .app) {
        category.logger.info("\(LogLevel.info.emoji) \(message)")
    }

    /// Log a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category (default: .app)
    public func warning(_ message: String, category: LogCategory = .app) {
        category.logger.warning("\(LogLevel.warning.emoji) \(message)")
    }

    /// Log an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category (default: .app)
    public func error(_ message: String, category: LogCategory = .app) {
        category.logger.error("\(LogLevel.error.emoji) \(message)")
    }

    /// Log an error with additional context
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: The underlying error
    ///   - category: The log category (default: .app)
    public func error(_ message: String, error: Error, category: LogCategory = .app) {
        category.logger.error("\(LogLevel.error.emoji) \(message): \(error.localizedDescription)")
    }

    // MARK: - Specialized Logging Methods

    /// Log a success message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category (default: .app)
    public func success(_ message: String, category: LogCategory = .app) {
        category.logger.info("✅ \(message)")
    }

    /// Log a failure message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category (default: .app)
    public func failure(_ message: String, category: LogCategory = .app) {
        category.logger.error("❌ \(message)")
    }

    /// Log a network operation
    /// - Parameters:
    ///   - message: The message to log
    ///   - url: The URL being accessed (optional)
    public func network(_ message: String, url: String? = nil) {
        if let url {
            LogCategory.network.logger.info("🌐 \(message) - URL: \(url)")
        } else {
            LogCategory.network.logger.info("🌐 \(message)")
        }
    }

    /// Log an automation operation
    /// - Parameters:
    ///   - message: The message to log
    ///   - element: The element being interacted with (optional)
    public func automation(_ message: String, element: String? = nil) {
        if let element {
            LogCategory.automation.logger.info("🤖 \(message) - Element: \(element)")
        } else {
            LogCategory.automation.logger.info("🤖 \(message)")
        }
    }

    /// Log an email operation
    /// - Parameters:
    ///   - message: The message to log
    ///   - provider: The email provider (optional)
    public func email(_ message: String, provider: String? = nil) {
        if let provider {
            LogCategory.email.logger.info("📧 \(message) - Provider: \(provider)")
        } else {
            LogCategory.email.logger.info("📧 \(message)")
        }
    }

    /// Log a reservation operation
    /// - Parameters:
    ///   - message: The message to log
    ///   - config: The reservation configuration (optional)
    public func reservation(_ message: String, config: String? = nil) {
        if let config {
            LogCategory.reservation.logger.info("🎯 \(message) - Config: \(config)")
        } else {
            LogCategory.reservation.logger.info("🎯 \(message)")
        }
    }

    /// Log a WebKit operation
    /// - Parameters:
    ///   - message: The message to log
    ///   - instanceId: The WebKit instance ID (optional)
    public func webKit(_ message: String, instanceId: String? = nil) {
        if let instanceId {
            LogCategory.webKit.logger.info("🔧 \(message) - Instance: \(instanceId)")
        } else {
            LogCategory.webKit.logger.info("🔧 \(message)")
        }
    }

    // MARK: - Performance Logging

    /// Log the start of an operation with timing
    /// - Parameters:
    ///   - operation: The operation name
    ///   - category: The log category (default: .debug)
    /// - Returns: A closure to call when the operation completes
    public func startTiming(_ operation: String, category: LogCategory = .debug) -> () -> Void {
        let startTime = Date()
        category.logger.info("⏱️ Starting: \(operation)")

        return {
            let duration = Date().timeIntervalSince(startTime)
            category.logger.info("⏱️ Completed: \(operation) in \(String(format: "%.2f", duration))s")
        }
    }

    // MARK: - Batch Logging

    /// Log multiple messages in a batch
    /// - Parameters:
    ///   - messages: Array of messages to log
    ///   - category: The log category (default: .debug)
    public func batch(_ messages: [String], category: LogCategory = .debug) {
        for message in messages {
            category.logger.info("📋 \(message)")
        }
    }

    // MARK: - Debug Logging (Production Safe)

    /// Log debug information only in debug builds
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category (default: .debug)
    public func debugOnly(_ message: String, category: LogCategory = .debug) {
        #if DEBUG
            category.logger.debug("🔍 \(message)")
        #endif
    }

    // MARK: - Error Context Logging

    /// Log error context for debugging
    /// - Parameters:
    ///   - error: The error to log
    ///   - context: Additional context information
    ///   - category: The log category (default: .debug)
    public func errorContext(_ error: Error, context: String, category: LogCategory = .debug) {
        category.logger.error("🔍 Error context: \(context)")
        category.logger.error("🔍 Error type: \(type(of: error))")
        category.logger.error("🔍 Error details: \(error)")
    }
}

// MARK: - Convenience Extensions

public extension CentralizedLoggingService {
    /// Shorthand for shared instance
    static var log: CentralizedLoggingService {
        return shared
    }
}

// MARK: - Legacy Logger Compatibility
