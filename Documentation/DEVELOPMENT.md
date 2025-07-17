# ODYSSEY Development Guide

## Architecture Overview

ODYSSEY is a native macOS menu bar application for automating sports reservation bookings for Ottawa Recreation facilities. The app is built with SwiftUI, AppKit, Combine, and uses **WebKit (WKWebView)** for all web automation tasks.

### Key Components

- **SwiftUI**: Modern, declarative UI for macOS
- **AppKit**: Menu bar integration
- **WebKitService**: Native web automation engine (replaces all Chrome/ChromeDriver logic)
- **Combine**: Async operations and state management
- **UserDefaults**: Persistent configuration
- **os.log**: Structured logging

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Amet13/ODYSSEY.git
   cd ODYSSEY
   ```
2. **Install dependencies**
   ```bash
   brew install xcodegen
   brew install swiftlint
   ```
3. **Generate Xcode project**
   ```bash
   xcodegen
   ```
4. **Build and run**
   ```bash
   ./Scripts/build.sh
   ```

## Permissions

ODYSSEY uses minimal permissions for privacy and security:

- **Network Access**: Required for web automation (standard app capability)
- **Notifications**: Optional - for success/failure alerts (user-granted)
- **Standard App Sandbox**: For configuration storage and logging (built-in)

**No special permissions required!** ODYSSEY runs with standard macOS app permissions and doesn't need Full Disk Access, Automation, or Accessibility permissions.

## 🔔 Notification System

ODYSSEY includes a comprehensive notification system to keep users informed about reservation status.

### Implementation Details

- **Framework**: Uses `UserNotifications` framework for native macOS notifications
- **Permission Handling**: Automatic permission requests on app launch with proper error handling
- **Async Operations**: All notification operations use async/await for better performance
- **Error Handling**: Graceful fallback when permissions are denied

### Key Components

- **AppDelegate**: Requests notification permissions on app launch
- **ReservationManager**: Sends success/failure notifications after reservation attempts
- **Permission Checking**: `checkNotificationAuthorization()` method verifies permissions before sending

### Notification Types

1. **Success Notifications**:

   - Title: "🎉 Reservation Successful!"
   - Body: "[Sport] at [Facility]"
   - Sent when reservation completes successfully

2. **Failure Notifications**:
   - Title: "❌ Reservation Failed"
   - Body: "[Sport]: [Shortened Error Message]"
   - Sent when reservation fails with error details

### Testing Notifications

To test the notification system:

1. **Enable Notifications**:

   - System Preferences > Notifications & Focus > ODYSSEY > Allow Notifications

2. **Test Success Path**:

   - Run a reservation that should succeed
   - Verify success notification appears

3. **Test Failure Path**:

   - Run a reservation that should fail
   - Verify failure notification appears with error details

4. **Check Logs**:
   - Use `./Scripts/logs.sh` to monitor notification-related logs
   - Look for permission status and notification send attempts

### Debugging Notifications

Common issues and solutions:

- **"Cannot send notification - permission not granted"**: User needs to enable notifications in System Preferences
- **"Failed to send notification"**: Check for system-level notification issues
- **No notifications appearing**: Verify Focus mode isn't blocking ODYSSEY notifications

### Code Structure

```swift
// Permission request (AppDelegate)
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])

// Permission checking (ReservationManager)
private func checkNotificationAuthorization() async -> Bool

// Sending notifications (ReservationManager)
private func sendSuccessNotification(for config: ReservationConfig)
private func sendFailureNotification(for config: ReservationConfig, error: String)
```

## Web Automation

- All reservation automation is now handled by `WebKitService` using `WKWebView` and JavaScript injection.
- No external browsers or drivers are required.
- All automation runs natively and securely on the user's Mac.

## Testing

- Use the built-in UI and logs to test automation flows.
- All business logic and automation can be tested via unit and integration tests.

## Contributing

- Please follow the code style and commit guidelines in the main README.
- Pull requests are welcome!
