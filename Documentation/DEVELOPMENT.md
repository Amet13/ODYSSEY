# ODYSSEY Development Guide

**Ottawa Drop-in Your Sports & Schedule Easily Yourself**

## Overview

ODYSSEY (Ottawa Drop-in Your Sports & Schedule Easily Yourself) is a native macOS menu bar application for automating sports reservation bookings for Ottawa Recreation facilities. The app is built with SwiftUI, AppKit, Combine, and uses **WebKit (WKWebView)** for all web automation tasks.

## 🏗️ Architecture & Technology Stack

### Core Technologies

- **SwiftUI** - Modern, declarative UI framework for macOS
- **AppKit** - Native macOS menu bar integration via `StatusBarController`
- **WebKit (WKWebView)** - Native web automation engine for browser automation
- **Combine** - Reactive programming for async operations and state management
- **UserDefaults** - Persistent configuration storage via `ConfigurationManager`
- **Timer** - Automated scheduling system for reservation automation
- **os.log** - Structured logging for debugging and monitoring

### Key Components

1. **AppDelegate** - Application lifecycle and scheduling management
2. **StatusBarController** - Menu bar integration and UI management
3. **ConfigurationManager** - Settings and data persistence (singleton)
4. **ReservationManager** - Web automation orchestration
5. **WebKitService** - Native web automation engine (singleton)
6. **FacilityService** - Web scraping and facility data management
7. **EmailService** - IMAP integration and email testing
8. **UserSettingsManager** - User configuration and settings management

### Architecture Principles

- **Protocol-Oriented Design**: Clear interfaces defined in `Sources/Utils/Protocols.swift`
- **Singleton Services**: Shared services for WebKit, Configuration, and User Settings
- **Separation of Concerns**: Each service has a single responsibility
- **Error Handling**: Comprehensive error handling with structured logging
- **Validation**: Centralized validation in `ValidationService`
- **Constants**: Centralized constants in `AppConstants`

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

## 🔧 Setup

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

## Web Automation

- All reservation automation is handled by `WebKitService` using `WKWebView` and JavaScript injection
- No external browsers or drivers are required
- All automation runs natively and securely on the user's Mac
- Includes anti-detection measures to avoid reCAPTCHA
- Human-like behavior simulation for realistic automation

## Code Organization

### Directory Structure

```
Sources/
├── App/                 # Application entry point and constants
├── Controllers/         # AppKit controllers (StatusBarController)
├── Models/             # Data models (ReservationConfig, UserSettings)
├── Services/           # Business logic services
├── Utils/              # Utilities, extensions, and protocols
└── Views/              # SwiftUI views
    ├── Configuration/  # Configuration management views
    ├── Main/          # Main app views
    └── Settings/      # Settings views
```

### Key Files

- `Sources/Utils/AppConstants.swift` - Centralized constants
- `Sources/Utils/Extensions.swift` - Reusable Swift extensions
- `Sources/Utils/Protocols.swift` - Protocol definitions
- `Sources/Utils/ValidationService.swift` - Validation logic
- `Sources/Services/WebKitService.swift` - Web automation engine
- `Sources/Services/ReservationManager.swift` - Reservation orchestration

## 🛡️ Permissions & Security

ODYSSEY uses minimal permissions for privacy and security:

- **Network Access:** Required for web automation (standard app capability)
- **Standard App Sandbox:** For configuration storage and logging (built-in)

**No special permissions required!** ODYSSEY runs with standard macOS app permissions and doesn't need Full Disk Access, Automation, or Accessibility permissions.

## Testing

- Use the built-in UI and logs to test automation flows
- All business logic and automation can be tested via unit and integration tests
- Debug window available for troubleshooting automation issues
- Comprehensive logging with os.log for debugging

## Code Quality

- **SwiftLint**: Code style enforcement
- **SwiftFormat**: Automatic code formatting
- **Protocol-Oriented Design**: Clear interfaces and testability
- **Error Handling**: Structured error handling throughout
- **Documentation**: Comprehensive code documentation

## 🔧 Build Issues & Troubleshooting

### Common Build Issues

**Build issues:**

- Ensure you have Xcode 16.0+ installed
- Run `brew install xcodegen swiftlint` to install dependencies
- Try cleaning the build folder: `rm -rf ~/Library/Developer/Xcode/DerivedData/ODYSSEY-*`

### Getting Help

- **Logs:** Check Console.app → search for "ODYSSEY" or "com.odyssey.app"
- **GitHub Issues:** Report bugs and feature requests
- **Debug Mode:** The app includes a debug window for troubleshooting automation

## Contributing

- Please follow the code style and commit guidelines in the main README
- Pull requests are welcome!
- Ensure all code passes SwiftLint and SwiftFormat
- Add tests for new functionality

## 📚 Related Documentation

- [Autofill Approach](AUTOFILL_APPROACH.md) - Technical details about form filling
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute
- [Changelog](CHANGELOG.md) - Release notes
