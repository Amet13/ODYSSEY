import Foundation
import Network
import os

@MainActor
public final class EmailIMAPStreamDelegate: NSObject, StreamDelegate {
  private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "EmailIMAPStream")

  // MARK: - IMAPStreamDelegate

  /**
   * Handles IMAP connection state changes.
   * - Parameter state: The new connection state.
   */
  public func connectionStateChanged(_ state: NWConnection.State) {
    switch state {
    case .ready:
      logger.info("✅ IMAP connection ready.")
    case .failed(let error):
      logger.error("❌ IMAP connection failed: \(error).")
    case .cancelled:
      logger.info("🛑 IMAP connection cancelled.")
    case .waiting(let error):
      logger.warning("⏳ IMAP connection waiting: \(error).")
    case .preparing:
      logger.info("🔧 IMAP connection preparing.")
    case .setup:
      logger.info("🔧 IMAP connection setup.")
    @unknown default:
      logger.info("ℹ️ IMAP connection state: \(String(describing: state)).")
    }
  }

  /**
   * Handles IMAP connection errors.
   * - Parameter error: The connection error.
   */
  public func didReceiveError(_ error: Error) {
    logger.error("❌ IMAP connection error: \(error.localizedDescription).")
  }

  /**
   * Handles IMAP connection completion.
   */
  public func didCompleteConnection() {
    logger.info("✅ IMAP connection completed.")
  }

  /**
   * Handles IMAP connection cancellation.
   */
  public func didCancelConnection() {
    logger.info("🛑 IMAP connection cancelled.")
  }

  /**
   * Handles IMAP connection timeout.
   */
  public func didTimeoutConnection() {
    logger.warning("⏰ IMAP connection timed out.")
  }

  /**
   * Handles IMAP authentication success.
   */
  public func didAuthenticateSuccessfully() {
    logger.info("✅ IMAP authentication successful.")
  }

  /**
   * Handles IMAP authentication failure.
   * - Parameter error: The authentication error.
   */
  public func didFailAuthentication(_ error: Error) {
    logger.error("❌ IMAP authentication failed: \(error.localizedDescription).")
  }

  /**
   * Handles IMAP command failure.
   * - Parameters:
   *   - command: The failed command.
   *   - error: The command error.
   */
  public func didFailCommand(_ command: String, error: Error) {
    logger.error("❌ IMAP command failed: \(command) - \(error.localizedDescription).")
  }
}
