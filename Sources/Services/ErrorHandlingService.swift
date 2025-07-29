import Foundation
import os.log

/// Centralized error handling service for consistent error management across the application
@MainActor
public final class ErrorHandlingService: ObservableObject {
    public static let shared = ErrorHandlingService()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ErrorHandlingService")

    private init() { }

    /// Handles errors with consistent logging and user-friendly messages
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: The context where the error occurred
    ///   - userFacing: Whether to show a user-facing error message
    public nonisolated func handleError(_ error: Error, context: String, userFacing: Bool = false) {
        let errorMessage = "❌ \(context): \(error.localizedDescription)"
        logger.error("\(errorMessage)")

        if userFacing {
            // Update user-facing error state
            DispatchQueue.main.async {
                // This could be expanded to show user notifications
                self.logger.warning("⚠️ User-facing error: \(errorMessage)")
            }
        }
    }

    /// Logs errors with consistent formatting
    /// - Parameters:
    ///   - message: The error message
    ///   - error: Optional error object
    ///   - context: The context where the error occurred
    public nonisolated func logError(_ message: String, error: Error? = nil, context: String = "General") {
        let fullMessage = error != nil ? "\(message): \(error!.localizedDescription)" : message
        logger.error("❌ [\(context)] \(fullMessage)")
    }

    /// Logs warnings with consistent formatting
    /// - Parameters:
    ///   - message: The warning message
    ///   - context: The context where the warning occurred
    public nonisolated func logWarning(_ message: String, context: String = "General") {
        logger.warning("⚠️ [\(context)] \(message)")
    }

    /// Logs info messages with consistent formatting
    /// - Parameters:
    ///   - message: The info message
    ///   - context: The context where the info occurred
    public nonisolated func logInfo(_ message: String, context: String = "General") {
        logger.info("ℹ️ [\(context)] \(message)")
    }

    /// Logs success messages with consistent formatting
    /// - Parameters:
    ///   - message: The success message
    ///   - context: The context where the success occurred
    public nonisolated func logSuccess(_ message: String, context: String = "General") {
        logger.info("✅ [\(context)] \(message)")
    }
}

// MARK: - Error Handling Protocol

public protocol ErrorHandlingServiceProtocol: AnyObject {
    func handleError(_ error: Error, context: String, userFacing: Bool)
    func logError(_ message: String, error: Error?, context: String)
    func logWarning(_ message: String, context: String)
    func logInfo(_ message: String, context: String)
    func logSuccess(_ message: String, context: String)
}

extension ErrorHandlingService: ErrorHandlingServiceProtocol { }
