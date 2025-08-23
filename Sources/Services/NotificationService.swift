import AppKit
import Foundation
import os.log

// Simple notification system using safe methods only
public enum NotificationType {
  case success
  case failure
  case info
  case warning
}

/// Service for managing native macOS notifications
///
/// Handles notification permissions, scheduling, and delivery for reservation events
/// including success confirmations, reminders, and error notifications.
public final class NotificationService: ObservableObject {
  @MainActor
  public static let shared = NotificationService()

  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem,
    category: "NotificationService"
  )

  @MainActor
  private init() {
    logger.info("🔔 NotificationService initializing.")
  }

  // MARK: - Simple Notification Methods

  // MARK: - Alternative Native Notification Methods

  /// Show a safe notification using reliable methods
  @MainActor
  public func showNotification(
    title: String,
    body: String,
    type: NotificationType = .info
  ) {
    // Check if notifications are enabled
    guard UserSettingsManager.shared.userSettings.showNotifications else {
      logger.info("🔇 Notifications disabled, skipping: \(title).")
      return
    }

    logger.info("🔔 Showing safe notification: \(title).")

    // Use safe notification method
    _ = showSafeNotification(title: title, body: body, type: type)
  }

  @MainActor
  private func showSafeNotification(title: String, body: String, type: NotificationType = .info)
    -> Bool
  {
    // Safe notification method that avoids potential crashes
    // Uses only basic AppKit features with proper memory management

    // 1. Update status bar (safe)
    let notificationText = "🔔 \(title): \(body)"
    NotificationCenter.default.post(
      name: NSNotification.Name("UpdateMenuBarTitle"),
      object: notificationText
    )

    // Reset after 10 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
      NotificationCenter.default.post(
        name: NSNotification.Name("UpdateMenuBarTitle"),
        object: "ODYSSEY"
      )
    }

    // 2. Show simple alert (safe)
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = body

    // Set alert style based on type
    switch type {
    case .success:
      alert.alertStyle = .informational
    case .failure:
      alert.alertStyle = .critical
    case .warning:
      alert.alertStyle = .warning
    case .info:
      alert.alertStyle = .informational
    }

    alert.addButton(withTitle: "OK")

    // Show alert safely on main thread
    DispatchQueue.main.async {
      alert.runModal()
    }

    logger.info("🛡️ Safe notification shown (status bar + alert): \(title).")
    return true
  }

  // MARK: - Reservation-Specific Notifications

  /// Shows a successful reservation notification
  /// - Parameters:
  ///   - facilityName: Name of the facility
  ///   - date: Date of the reservation
  ///   - time: Time of the reservation
  @MainActor
  public func showReservationSuccess(
    facilityName: String,
    date: String,
    time: String
  ) {
    showNotification(
      title: "Reservation Successful! 🎯",
      body: "Booked \(facilityName) for \(date) at \(time)",
      type: .success
    )
  }

  /// Shows a reservation failure notification
  /// - Parameters:
  ///   - facilityName: Name of the facility
  ///   - error: Description of what went wrong
  @MainActor
  public func showReservationFailure(
    facilityName: String,
    error: String
  ) {
    showNotification(
      title: "Reservation Failed ❌",
      body: "Could not book \(facilityName): \(error)",
      type: .failure
    )
  }

  /// Shows an automation completion notification
  /// - Parameters:
  ///   - successCount: Number of successful reservations
  ///   - totalAttempts: Total number of attempts made
  @MainActor
  public func showAutomationComplete(
    successCount: Int,
    totalAttempts: Int
  ) {
    let title = successCount > 0 ? "Automation Complete! ✅" : "Automation Complete ⚠️"
    let body =
      successCount > 0
      ? "Successfully booked \(successCount) out of \(totalAttempts) reservations"
      : "No reservations were booked after \(totalAttempts) attempts"

    showNotification(
      title: title,
      body: body,
      type: successCount > 0 ? .success : .warning
    )
  }

}
