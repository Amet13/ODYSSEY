<div align="center">
  <img src="logo.svg" alt="ODYSSEY Logo" width="120" height="120">
  <h1>ODYSSEY</h1>
  <p><strong>Ottawa Drop-in Your Sports & Schedule Easily Yourself (macOS Automation)</strong></p>
  
  <p>
    <a href="https://github.com/Amet13/ODYSSEY/actions/workflows/ci.yml">
      <img src="https://github.com/Amet13/ODYSSEY/actions/workflows/ci.yml/badge.svg" alt="CI Status">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/issues">
      <img src="https://img.shields.io/badge/Support-GitHub%20Issues-orange" alt="GitHub Issues">
    </a>
  </p>
  
  <p>
    <a href="#installation">
      <img src="https://img.shields.io/badge/Build%20from%20Source-Development-blue?style=for-the-badge&logo=swift" alt="Build from Source">
    </a>
  </p>
</div>

# ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself

ODYSSEY is a native macOS menu bar application that automates sports reservation bookings for Ottawa Recreation facilities.

## 🚀 Features

- Runs quietly in the menu bar (not dock)
- Automates web-based reservation booking for Ottawa Recreation facilities
- Uses **Swift + WebKit** for robust, native web automation
- Modern SwiftUI interface for configuration management
- Schedules automatic runs based on configured time slots
- Supports multiple configurations for different sports and facilities
- Comprehensive logging and error handling

## 🏗️ Architecture & Technology Stack

- **SwiftUI** - Modern, declarative UI framework for macOS
- **AppKit** - Native macOS menu bar integration
- **WebKit (WKWebView)** - Native web automation engine
- **Combine** - Reactive programming for async operations and state management
- **UserDefaults** - Persistent configuration storage
- **Timer** - Automated scheduling system
- **os.log** - Structured logging for debugging and monitoring

## 🔧 Setup

```bash
# Clone repository
git clone https://github.com/Amet13/ODYSSEY.git
cd ODYSSEY

# Install dependencies
brew install xcodegen
brew install swiftlint

# Generate Xcode project
xcodegen

# Build and run
./Scripts/build.sh
```

## 🛡️ Permissions

ODYSSEY uses minimal permissions for privacy and security:

- **Network Access:** Required for web automation (standard app capability)
- **Notifications:** Optional - for success/failure alerts (user-granted)
- **Standard App Sandbox:** For configuration storage and logging (built-in)

**No special permissions required!** ODYSSEY runs with standard macOS app permissions and doesn't need Full Disk Access, Automation, or Accessibility permissions.

## 🔔 Notifications

ODYSSEY can send system notifications to alert you when reservations succeed or fail. Here's how to enable them:

### Enabling Notifications

1. **First Launch:** When you first run ODYSSEY, it will automatically request notification permissions
2. **System Preferences:** If you missed the initial request or want to change settings:
   - Open **System Preferences** (or **System Settings** on macOS 13+)
   - Go to **Notifications & Focus** (or **Notifications** on older versions)
   - Find **ODYSSEY** in the list of apps
   - Enable **Allow Notifications**
   - Choose your preferred notification style (Banner, Alert, or None)

### Notification Types

- **🎉 Success Notifications:** Sent when a reservation is completed successfully
- **❌ Failure Notifications:** Sent when a reservation fails (with error details)

### Troubleshooting Notifications

If you're not receiving notifications:

1. **Check System Preferences:**

   - Ensure ODYSSEY has notification permissions enabled
   - Verify notification style is set to "Banner" or "Alert" (not "None")

2. **Check Focus Mode:**

   - Make sure Focus mode isn't blocking notifications from ODYSSEY
   - Add ODYSSEY to allowed apps in Focus settings if needed

3. **Restart the App:**

   - Quit and relaunch ODYSSEY to re-request permissions

4. **Check Logs:**
   - Use `./Scripts/logs.sh` to see if notification permission errors are logged
   - Look for messages like "Notification permission denied" or "Cannot send notification - permission not granted"

### Notification Content

- **Success:** "🎉 Reservation Successful! [Sport] at [Facility]"
- **Failure:** "❌ Reservation Failed [Sport]: [Error Message]"

Notifications are sent immediately when reservations complete, helping you stay informed about your booking status.

## 📝 Documentation

- See `Documentation/DEVELOPMENT.md` for development workflow and architecture details.
- See `Documentation/CHANGELOG.md` for release notes.

## 🧑‍💻 Contributing

Pull requests are welcome! Please see `Documentation/CONTRIBUTING.md` for guidelines.

## 📄 License

MIT
