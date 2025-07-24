import Foundation
import os.log
@preconcurrency import UserNotifications

/**
 NotificationService handles native macOS notifications for ODYSSEY.

 Provides user-friendly notifications for:
 - Reservation success/failure
 - Upcoming autoruns
 - Errors and warnings
 - System status updates

 ## Usage Example
 ```swift
 let notificationService = NotificationService.shared
 await notificationService.requestPermission()
 await notificationService.sendReservationSuccess(for: config)
 ```
 */
public final class NotificationService: NSObject, ObservableObject, @unchecked Sendable {
    public static let shared = NotificationService()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "NotificationService")
    private var notificationCenter: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    @Published @MainActor public var isPermissionGranted = false

    override private init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
        // Don't auto-check permission on init to avoid issues
    }

    // MARK: - Setup Methods

    /**
     Sets up notification categories for different types of notifications.
     */
    private func setupNotificationCategories() {
        // Reservation Success Category
        let successCategory = UNNotificationCategory(
            identifier: "RESERVATION_SUCCESS",
            actions: [],
            intentIdentifiers: [],
            options: [],
            )

        // Reservation Failure Category
        let failureCategory = UNNotificationCategory(
            identifier: "RESERVATION_FAILURE",
            actions: [],
            intentIdentifiers: [],
            options: [],
            )

        // Autorun Reminder Category
        let autorunCategory = UNNotificationCategory(
            identifier: "AUTORUN_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: [],
            )

        // System Error Category
        let errorCategory = UNNotificationCategory(
            identifier: "SYSTEM_ERROR",
            actions: [],
            intentIdentifiers: [],
            options: [],
            )

        // Status Update Category
        let statusCategory = UNNotificationCategory(
            identifier: "STATUS_UPDATE",
            actions: [],
            intentIdentifiers: [],
            options: [],
            )

        // Register all categories
        notificationCenter.setNotificationCategories([
            successCategory,
            failureCategory,
            autorunCategory,
            errorCategory,
            statusCategory
        ])

        logger.info("🔔 Notification categories set up.")
    }

    // MARK: - Permission Management

    /**
     Requests notification permission from the user.
     - Returns: True if permission was granted
     */
    @MainActor
    public func requestPermission() async -> Bool {
        logger.info("🔔 Requesting notification permission.")

        do {
            // First check current status
            let settings = await notificationCenter.notificationSettings()

            // If already authorized, don't request again
            if settings.authorizationStatus == .authorized {
                self.isPermissionGranted = true
                logger.info("✅ Notification permission already granted.")
                return true
            }

            // If denied, don't request again
            if settings.authorizationStatus == .denied {
                self.isPermissionGranted = false
                logger.warning("⚠️ Notification permission previously denied.")
                return false
            }

            // Request permission
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            self.isPermissionGranted = granted

            if granted {
                logger.info("✅ Notification permission granted.")
            } else {
                logger.warning("⚠️ Notification permission denied.")
            }

            return granted
        } catch {
            logger.error("❌ Failed to request notification permission: \(error.localizedDescription).")
            logger.error("❌ Error details: \(error)")
            return false
        }
    }

    /**
     Checks the current notification permission status.
     */
    @MainActor
    public func checkPermissionStatus() async {
        let settings = await notificationCenter.notificationSettings()
        let isAuthorized = settings.authorizationStatus == .authorized
        let statusRawValue = settings.authorizationStatus.rawValue
        self.isPermissionGranted = isAuthorized
        self.logger.info("🔔 Notification permission status: \(statusRawValue).")
    }

    // MARK: - Notification Methods

    /**
     Sends a notification for successful reservation.
     - Parameter config: The reservation configuration that succeeded
     */
    @MainActor
    public func sendReservationSuccess(for config: ReservationConfig) async {
        guard isPermissionGranted else {
            logger.info("🔔 Skipping success notification - permission not granted.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🎉 Reservation Successful!"
        content
            .body =
            "Successfully booked \(config.sportName) at \(ReservationConfig.extractFacilityName(from: config.facilityURL))"
        content.sound = .default
        content.categoryIdentifier = "RESERVATION_SUCCESS"

        let request = UNNotificationRequest(
            identifier: "reservation-success-\(config.id.uuidString)",
            content: content,
            trigger: nil,
            )

        do {
            try await notificationCenter.add(request)
            logger.info("✅ Success notification sent for \(config.name).")
        } catch {
            logger.error("❌ Failed to send success notification: \(error.localizedDescription).")
        }
    }

    /**
     Sends a notification for failed reservation.
     - Parameters:
     - config: The reservation configuration that failed
     - error: The error that caused the failure
     */
    @MainActor
    public func sendReservationFailure(for config: ReservationConfig, error: String) async {
        guard isPermissionGranted else {
            logger.info("🔔 Skipping failure notification - permission not granted.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "❌ Reservation Failed"
        content.body = "Failed to book \(config.sportName): \(error)"
        content.sound = .default
        content.categoryIdentifier = "RESERVATION_FAILURE"

        let request = UNNotificationRequest(
            identifier: "reservation-failure-\(config.id.uuidString)",
            content: content,
            trigger: nil,
            )

        do {
            try await notificationCenter.add(request)
            logger.info("❌ Failure notification sent for \(config.name).")
        } catch {
            logger.error("❌ Failed to send failure notification: \(error.localizedDescription).")
        }
    }

    /**
     Sends a notification for upcoming autorun.
     - Parameter config: The reservation configuration that will run
     - Parameter timeUntilRun: Time until the autorun in minutes
     */
    @MainActor
    public func sendUpcomingAutorun(for config: ReservationConfig, timeUntilRun: Int) async {
        guard isPermissionGranted else {
            logger.info("🔔 Skipping autorun notification - permission not granted.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "⏰ Autorun Starting Soon"
        content.body = "\(config.sportName) reservation will be attempted in \(timeUntilRun) minutes"
        content.sound = .default
        content.categoryIdentifier = "AUTORUN_REMINDER"

        let request = UNNotificationRequest(
            identifier: "autorun-reminder-\(config.id.uuidString)",
            content: content,
            trigger: nil,
            )

        do {
            try await notificationCenter.add(request)
            logger.info("⏰ Autorun reminder sent for \(config.name).")
        } catch {
            logger.error("❌ Failed to send autorun reminder: \(error.localizedDescription).")
        }
    }

    /**
     Sends a notification for system errors.
     - Parameter error: The error message
     - Parameter context: Additional context about the error
     */
    @MainActor
    public func sendSystemError(_ error: String, context: String? = nil) async {
        guard isPermissionGranted else {
            logger.info("🔔 Skipping error notification - permission not granted.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🚨 System Error"
        content.body = context != nil ? "\(context!): \(error)" : error
        content.sound = .default
        content.categoryIdentifier = "SYSTEM_ERROR"

        let request = UNNotificationRequest(
            identifier: "system-error-\(UUID().uuidString)",
            content: content,
            trigger: nil,
            )

        do {
            try await notificationCenter.add(request)
            logger.info("🚨 System error notification sent.")
        } catch {
            logger.error("❌ Failed to send system error notification: \(error.localizedDescription).")
        }
    }

    /**
     Sends a notification for system status updates.
     - Parameter message: The status message
     - Parameter isSuccess: Whether this is a success or info message
     */
    @MainActor
    public func sendStatusUpdate(_ message: String, isSuccess: Bool = false) async {
        guard isPermissionGranted else {
            logger.info("🔔 Skipping status notification - permission not granted.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = isSuccess ? "✅ Status Update" : "ℹ️ Status Update"
        content.body = message
        content.sound = nil // No sound for status updates
        content.categoryIdentifier = "STATUS_UPDATE"

        let request = UNNotificationRequest(
            identifier: "status-update-\(UUID().uuidString)",
            content: content,
            trigger: nil,
            )

        do {
            try await notificationCenter.add(request)
            logger.info("ℹ️ Status notification sent: \(message).")
        } catch {
            logger.error("❌ Failed to send status notification: \(error.localizedDescription).")
        }
    }

    /**
     Clears all pending notifications.
     */
    @MainActor
    public func clearAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        logger.info("🧹 All notifications cleared.")
    }

    /**
     Clears notifications for a specific configuration.
     - Parameter configId: The configuration ID
     */
    @MainActor
    public func clearNotifications(for configId: UUID) async {
        let identifiers = [
            "reservation-success-\(configId.uuidString)",
            "reservation-failure-\(configId.uuidString)",
            "autorun-reminder-\(configId.uuidString)"
        ]

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
        logger.info("🧹 Notifications cleared for config \(configId).")
    }

    /**
     Sends a test notification to verify the system is working.
     */
    @MainActor
    public func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "This is a test notification from ODYSSEY"
        content.sound = .default
        content.categoryIdentifier = "STATUS_UPDATE"

        let request = UNNotificationRequest(
            identifier: "test-notification-\(UUID().uuidString)",
            content: content,
            trigger: nil,
            )

        do {
            try await notificationCenter.add(request)
            logger.info("✅ Test notification sent successfully.")
        } catch {
            logger.error("❌ Failed to send test notification: \(error.localizedDescription).")
            logger.error("❌ Error details: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void,
        ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void,
        ) {
        // Handle notification taps here if needed
        logger.info("🔔 Notification tapped: \(response.notification.request.identifier).")
        completionHandler()
    }
}
