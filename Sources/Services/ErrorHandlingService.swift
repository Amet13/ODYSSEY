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
        logger.error("\(errorMessage).")

        if userFacing {
            // Update user-facing error state
            DispatchQueue.main.async {
                // This could be expanded to show user notifications
                self.logger.warning("⚠️ User-facing error: \(errorMessage)")
            }
        }
    }

    /// Handles unified errors with enhanced formatting and categorization
    /// - Parameters:
    ///   - error: The unified error to handle
    ///   - context: The context where the error occurred
    ///   - userFacing: Whether to show a user-facing error message
    public nonisolated func handleUnifiedError(
        _ error: UnifiedErrorProtocol,
        context: String,
        userFacing: Bool = false,
        ) {
        let errorMessage = "\(error.errorCategory.emoji) \(context): \(error.userFriendlyMessage)"
        logger.error("\(errorMessage).")

        if userFacing {
            DispatchQueue.main.async {
                self.logger.warning("⚠️ User-facing unified error: \(errorMessage)")
            }
        }
    }

    /// Logs errors with consistent formatting
    /// - Parameters:
    ///   - message: The error message
    ///   - error: Optional error object
    ///   - context: The context where the error occurred
    public nonisolated func logError(_ message: String, error: Error? = nil, context: String = "General") {
        let fullMessage = error != nil ? "\(message): \(error?.localizedDescription ?? "Unknown error")" : message
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

    /// Converts any error to a user-friendly message
    /// - Parameter error: The error to convert
    /// - Returns: User-friendly error message
    public nonisolated func getUserFriendlyMessage(for error: Error) -> String {
        if let unifiedError = error as? UnifiedErrorProtocol {
            return unifiedError.userFriendlyMessage
        }

        // Handle specific error types
        if let reservationError = error as? ReservationError {
            return reservationError.errorDescription ?? "Reservation failed"
        }

        if let webDriverError = error as? WebDriverError {
            return webDriverError.errorDescription ?? "Web automation failed"
        }

        if let keychainError = error as? KeychainError {
            return keychainError.errorDescription ?? "Secure storage failed"
        }

        // Generic error handling
        let errorMessage = error.localizedDescription
        if errorMessage.contains("network") || errorMessage.contains("connection") {
            return "Network connection issue. Please check your internet connection and try again."
        } else if errorMessage.contains("timeout") {
            return "Operation timed out. Please try again."
        } else if errorMessage.contains("not found") || errorMessage.contains("404") {
            return "The requested page was not found. Please check the facility URL."
        } else {
            return "An error occurred: \(errorMessage). Please try again."
        }
    }
}

// MARK: - Error Handling Protocol

public protocol ErrorHandlingServiceProtocol: AnyObject {
    func handleError(_ error: Error, context: String, userFacing: Bool)
    func handleUnifiedError(_ error: UnifiedErrorProtocol, context: String, userFacing: Bool)
    func logError(_ message: String, error: Error?, context: String)
    func logWarning(_ message: String, context: String)
    func logInfo(_ message: String, context: String)
    func logSuccess(_ message: String, context: String)
    func getUserFriendlyMessage(for error: Error) -> String
}

extension ErrorHandlingService: ErrorHandlingServiceProtocol { }
