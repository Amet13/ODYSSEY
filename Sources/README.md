# ODYSSEY Sources

This directory contains all the source code for the ODYSSEY macOS application.

> **ODYSSEY: Ottawa Drop-in Your Sports & Schedule Easily Yourself (macOS Automation)**

## Directory Structure

```
Sources/
├── App/                    # Application entry point
│   ├── ODYSSEYApp.swift    # Main app delegate
│   ├── Constants.swift     # Application constants
│   └── Info.plist         # App configuration
├── Views/                  # SwiftUI views
│   ├── Main/              # Main application views
│   │   └── ContentView.swift
│   ├── Configuration/     # Configuration-related views
│   │   └── ConfigurationDetailView.swift
│   └── Components/        # Reusable UI components
├── Models/                 # Data models
│   └── ReservationConfig.swift
├── Services/              # Business logic and services
│   ├── Configuration.swift
│   ├── ReservationManager.swift
│   ├── FacilityService.swift
│   ├── WebDriverService.swift
│   ├── EmailService.swift
│   └── TelegramService.swift
├── Controllers/           # AppKit controllers
│   └── StatusBarController.swift
└── Resources/             # App resources
    ├── Assets.xcassets/   # Images and icons
    └── AppIcon.icns       # App icon
```

## Architecture Overview

### App Layer

- **ODYSSEYApp.swift** - Main application entry point and app delegate
- **Constants.swift** - Application-wide constants and configuration
- **Info.plist** - Application configuration and permissions

### Views Layer

- **Main** - Primary application interface
- **Configuration** - Settings and configuration management
- **Components** - Reusable UI components and styles

### Models Layer

- **ReservationConfig.swift** - Core data model for reservation configurations

### Services Layer

- **Configuration.swift** - Settings management and persistence
- **ReservationManager.swift** - Web automation and reservation booking
- **FacilityService.swift** - Facility data fetching and sports detection
- **WebKitService.swift** - Native web automation via WKWebView
- **EmailService.swift** - IMAP integration and email
- **TelegramService.swift** - Telegram bot integration and notifications

### Controllers Layer

- **StatusBarController.swift** - Menu bar integration and UI management

### Resources Layer

- **Assets.xcassets** - Image assets and app icons
- **AppIcon.icns** - Application icon file

## Key Features

### Core Functionality

- **Menu Bar Integration** - Native macOS menu bar app using AppKit
- **Web Automation** - Native web automation via WKWebView for reservation booking
- **Configuration Management** - Persistent settings and reservation configurations
- **Scheduling System** - Automated reservation triggering based on time slots
- **Real-time Status** - Live updates and countdown timers

### Modern Architecture

- **SwiftUI** - Modern, declarative UI framework
- **Combine** - Reactive programming for state management
- **WebKit** - Native WKWebView for web automation
- **UserDefaults** - Persistent configuration storage
- **os.log** - Structured logging system

### Integration Features

- **IMAP Integration** - Email service validation

## Development Guidelines

### Code Organization

- Follow the established directory structure
- Use clear, descriptive file and class names
- Implement proper separation of concerns
- Add comprehensive documentation for public APIs

### Error Handling

- Use structured logging with os.log
- Implement graceful error recovery
- Provide user-friendly error messages
- Log all automation steps and failures

### Performance

- Optimize memory usage and avoid retain cycles
- Use async/await for concurrent operations
- Implement proper cleanup in deinit methods
- Monitor app size and build performance

## Build Process

The project uses XcodeGen for project generation:

```bash
# Generate Xcode project
xcodegen --spec Config/project.yml

# Build and run
./Scripts/build.sh
```

## Dependencies

- **macOS 12.0+** - Minimum deployment target
- **Swift 5.7+** - Language version
- **Xcode 14.0+** - Development environment
- **WebKit** - Built-in web automation framework
- **No External Dependencies** - All automation runs natively

## Security Considerations

- All automation runs locally on user's machine
- No data is transmitted to external servers (except IMAP when configured)
- User consent required for all permissions
- Secure network connections with App Transport Security
- Input validation and sanitization throughout

---

**For more information, see the main [README.md](../README.md) and [Documentation/](../Documentation/) directory.**
