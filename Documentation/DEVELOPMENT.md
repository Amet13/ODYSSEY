# ODYSSEY Development Guide

**Ottawa Drop-in Your Sports & Schedule Easily Yourself**

## Overview

ODYSSEY is a native macOS menu bar application that automates sports reservation bookings for Ottawa Recreation facilities. It is built with modern Apple technologies and robust architecture for reliability, security, and maintainability.

---

## 🏗️ Core Technologies

- **SwiftUI**: Declarative UI framework for macOS
- **AppKit**: Native menu bar integration and window management
- **WebKit (WKWebView)**: Native web automation engine (no external browsers)
- **Combine**: Reactive programming for async operations and state management
- **UserDefaults**: Persistent configuration storage
- **os.log**: Structured logging with emoji indicators
- **Keychain Services**: Secure credential storage
- **IMAP**: Email integration for verification code extraction
- **Timer**: Automated scheduling system

---

## 🚀 Features

- **Menu Bar Integration**: Runs quietly in the menu bar (not dock)
- **Web Automation**: Automates web-based reservation booking for Ottawa Recreation facilities
- **Modern SwiftUI Interface**: Clean, intuitive configuration management
- **Automated Scheduling**: Runs at 6:00 PM, 2 days before your reservation
- **Multiple Configurations**: Support for different sports, facilities, and time slots
- **Comprehensive Logging**: Structured logs with emojis for easy debugging
- **Email Verification**: Automated code extraction (IMAP and Gmail)
- **Secure Storage**: Credentials stored in macOS Keychain
- **Anti-Detection**: Human-like behavior simulation to avoid bot detection
- **Error Handling**: Graceful recovery from network, automation, and WebKit issues
- **Debug Window**: Essential for troubleshooting and support (must never be deleted)

---

## 🧩 Key Components

- **AppDelegate / ODYSSEYApp.swift**: Application lifecycle and scheduling
- **StatusBarController**: Menu bar integration and UI management
- **ConfigurationManager**: Settings and data persistence (singleton)
- **ReservationOrchestrator**: Orchestrates reservation runs and automation
- **WebKitService**: Core web automation engine (singleton)
- **FacilityService**: Web scraping and facility data management
- **EmailService**: IMAP integration and email testing
- **UserSettingsManager**: User configuration and settings management
- **ValidationService**: Centralized validation logic (singleton)
- **AppConstants**: Centralized application constants
- **LoadingStateManager**: In-app loading states and notifications
- **ReservationStatusManager**: Tracks reservation run status and updates UI

---

## 🛠️ Developer Setup

### Prerequisites

- macOS 15.0 or later
- Xcode 16.0 or later
- Node.js and npm (for JavaScript linting)
- Homebrew (for installing dependencies)

### Setup Steps

- Clone the repository
- Install dependencies: `brew install xcodegen swiftlint` and `npm install`
- Generate Xcode project: `xcodegen`
- Build and run: `./Scripts/build.sh`
- (Optional) Open in Xcode: `open Config/ODYSSEY.xcodeproj`
- Run code quality checks: `swiftlint lint` and `npm run lint`

---

## 🏛️ Architecture Principles

- **Protocol-Oriented Design**: Clear interfaces for all services and models
- **Separation of Concerns**: Each service/component has a single responsibility
- **Dependency Injection**: Use singletons for shared services
- **Reactive Programming**: Use Combine for state management and async operations
- **Centralized Validation**: All input validation in `ValidationService`
- **Centralized Constants**: All constants in `AppConstants`
- **Error Recovery**: Graceful error handling and fallback strategies
- **Performance**: Optimized for memory usage and responsiveness
- **Security**: Local processing, secure credential storage, and privacy by design

---

## 🐞 Debugging & Troubleshooting

- **Debug Window**: Essential for development, troubleshooting, and user support. Must never be deleted or removed from the application. Use it to monitor WebKit automation, diagnose issues, and provide logs for support.
- **Logging**: All logs use `os.log` with emoji indicators for quick identification. Sensitive data is masked or marked as private.
- **Console.app**: View logs by searching for `ODYSSEY` or `com.odyssey.app`.
- **Error Handling**: All errors are logged with context and user-friendly messages are shown in the UI.
- **LoadingStateManager**: Provides in-app banners and progress indicators for async operations and errors.

---

## 🧪 Code Quality & Testing

- **SwiftLint**: Enforced code style and best practices
- **SwiftFormat**: Automatic code formatting
- **Comprehensive Documentation**: All public APIs and services are documented
- **Unit & UI Testing**: Add tests for new features and bug fixes
- **Self-Review**: All changes should be self-reviewed before submission
- **Zero Linter Errors**: All code must pass SwiftLint and SwiftFormat before merging

---

## 📚 Related Documentation

- [Changelog](CHANGELOG.md) - Release notes
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute

---

For user installation and setup, see the main [README.md](../README.md).
