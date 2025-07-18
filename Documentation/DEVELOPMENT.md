# ODYSSEY Development Guide

## Architecture Overview

ODYSSEY is a native macOS menu bar application for automating sports reservation bookings for Ottawa Recreation facilities. The app is built with SwiftUI, AppKit, Combine, and uses **WebKit (WKWebView)** for all web automation tasks.

### Key Components

- **SwiftUI**: Modern, declarative UI for macOS
- **AppKit**: Menu bar integration via `StatusBarController`
- **WebKitService**: Native web automation engine (replaces all Chrome/ChromeDriver logic)
- **Combine**: Async operations and state management
- **UserDefaults**: Persistent configuration via `ConfigurationManager`
- **os.log**: Structured logging for debugging and monitoring

### Architecture Principles

- **Protocol-Oriented Design**: Clear interfaces defined in `Sources/Utils/Protocols.swift`
- **Singleton Services**: Shared services for WebKit, Configuration, and User Settings
- **Separation of Concerns**: Each service has a single responsibility
- **Error Handling**: Comprehensive error handling with structured logging
- **Validation**: Centralized validation in `ValidationService`
- **Constants**: Centralized constants in `AppConstants`

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

## Contributing

- Please follow the code style and commit guidelines in the main README
- Pull requests are welcome!
- Ensure all code passes SwiftLint and SwiftFormat
- Add tests for new functionality
