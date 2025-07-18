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

- **Menu Bar Integration** - Runs quietly in the menu bar (not dock)
- **Web Automation** - Automates web-based reservation booking for Ottawa Recreation facilities
- **Native WebKit Engine** - Uses **Swift + WebKit** for robust, native web automation (no external dependencies)
- **Modern SwiftUI Interface** - Clean, intuitive configuration management with sport-specific icons
- **Smart Scheduling** - Automatic runs based on configured time slots
- **Multi-Configuration Support** - Multiple sports and facilities simultaneously
- **Sport-Specific Icons** - Visual icons for 100+ sports and activities including Ottawa Recreation favorites
- **Email Integration** - IMAP support for verification code extraction
- **Comprehensive Logging** - Structured logging with os.log for debugging
- **Human-like Behavior** - Anti-detection measures to avoid reCAPTCHA
- **Error Recovery** - Graceful handling of network issues and automation failures

## 🏗️ Architecture & Technology Stack

### **Core Technologies**

- **SwiftUI** - Modern, declarative UI framework for macOS
- **AppKit** - Native macOS menu bar integration via `StatusBarController`
- **WebKit (WKWebView)** - Native web automation engine for browser automation
- **Combine** - Reactive programming for async operations and state management
- **UserDefaults** - Persistent configuration storage via `ConfigurationManager`
- **Timer** - Automated scheduling system for reservation automation
- **os.log** - Structured logging for debugging and monitoring

### **Key Components**

1. **AppDelegate** - Application lifecycle and scheduling management
2. **StatusBarController** - Menu bar integration and UI management
3. **ConfigurationManager** - Settings and data persistence (singleton)
4. **ReservationManager** - Web automation orchestration
5. **WebKitService** - Native web automation engine (singleton)
6. **FacilityService** - Web scraping and facility data management
7. **EmailService** - IMAP integration and email testing
8. **UserSettingsManager** - User configuration and settings management

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
- **Standard App Sandbox:** For configuration storage and logging (built-in)

**No special permissions required!** ODYSSEY runs with standard macOS app permissions and doesn't need Full Disk Access, Automation, or Accessibility permissions.

## 🔧 Troubleshooting

### **Common Issues**

**Automation not working:**

- Check that the facility URL is correct and accessible
- Verify your user settings (name, phone, email) are complete
- Ensure the sport name matches exactly what's on the website
- Check the logs in Console.app for detailed error messages

**Email verification failing:**

- For Gmail accounts, ensure you're using an App Password (not your regular password)
- Verify IMAP is enabled in your Gmail settings
- Check that the email server settings are correct

**App not appearing in menu bar:**

- Ensure the app is running (check Activity Monitor)
- Try restarting the app
- Check that no other instances are running

**Build issues:**

- Ensure you have Xcode 16.0+ installed
- Run `brew install xcodegen swiftlint` to install dependencies
- Try cleaning the build folder: `rm -rf ~/Library/Developer/Xcode/DerivedData/ODYSSEY-*`

### **Getting Help**

- **Logs:** Check Console.app → search for "ODYSSEY" or "com.odyssey.app"
- **GitHub Issues:** Report bugs and feature requests
- **Debug Mode:** The app includes a debug window for troubleshooting automation

## 📝 Documentation

- See `Documentation/DEVELOPMENT.md` for development workflow and architecture details.
- See `Documentation/CHANGELOG.md` for release notes.

## 🧑‍💻 Contributing

Pull requests are welcome! Please see `Documentation/CONTRIBUTING.md` for guidelines.

## 📄 License

MIT
