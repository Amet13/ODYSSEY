# 🧑‍💻 ODYSSEY Development Guide

## 🎯 Overview

ODYSSEY is a macOS menu bar application built with SwiftUI.

## 🖥️ System Requirements

- **macOS 15.0 or later.**
- **Xcode 16.0 or later.**
- **Swift 6.1 or later.**
- **Homebrew** (_for installing development dependencies_)

## 🚀 Quick Start (for Developers)

> **Note:** This guide is for contributors and developers. For user setup, see **[USER_GUIDE.md](USER_GUIDE.md)**.

- **Clone the repository**:

```bash
git clone https://github.com/Amet13/ODYSSEY.git
cd ODYSSEY
```

- **Setup development environment**:

```bash
./Scripts/odyssey.sh setup
```

- **Build the project**:

```bash
./Scripts/odyssey.sh build
```

- **Monitor logs** (in another terminal):

```bash
./Scripts/odyssey.sh logs
```

- **Run quality checks**:

```bash
./Scripts/odyssey.sh lint
```

## 🏗️ Architecture Principles

### Core Design Principles

- **Separation of concerns:** Each component has a single, well-defined responsibility.
- **Protocol-oriented design:** Use protocols for interfaces and dependency injection.
- **Dependency injection:** Centralized service management for better testability.
- **Concurrency safety:** Proper actor isolation and thread safety throughout.
- **Error handling:** Comprehensive error handling with clear categorization.
- **Security first:** Always use secure storage (_Keychain_) for sensitive data.
- **Performance:** Optimize for memory usage and responsiveness.
- **Validation:** Centralized input validation and sanitization.
- **Constants management:** Centralized constants for maintainability.

### Modular Architecture

ODYSSEY uses a **modular Swift Package Manager** architecture with two main targets:

- **`ODYSSEY`:** macOS menu bar application built with SwiftUI.
- **`ODYSSEYBackend` (Library):** Shared backend services and automation engine.

### Architecture Layers

- **Presentation:** User interface and user interaction logic (`Views/`, `Controllers/`)
- **Application:** Business logic orchestration and use cases (`Application/`)
- **Domain:** Core business entities and domain logic (`Domain/`)
- **Infrastructure:** External services, automation, and data persistence (`Infrastructure/`, `Services/`)
- **Shared:** Common utilities and protocols (`SharedUtils/`, `SharedCore/`)

## Notification System

ODYSSEY implements a simple, reliable notification system that works without requiring system permissions. The system focuses on essential notifications only and uses safe delivery methods.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    NotificationService                      │
├─────────────────────────────────────────────────────────────┤
│  • Settings Integration                                    │
│  • Safe Notification Methods                               │
│  • Multi-Layer Delivery                                    │
│  • Essential Events Only                                   │
│  • Crash Prevention                                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                Safe Notification Methods                    │
├─────────────────────────────────────────────────────────────┤
│  • Status Bar Updates                                      │
│  • Alert Dialogs                                           │
│  • No Permissions Required                                 │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

- **`NotificationService`**: Central service managing all notification operations
- **Settings Integration**: Single toggle in Advanced Settings
- **Safe Methods**: Uses only crash-safe AppKit features
- **Multi-Layer Delivery**: Status bar and alerts for reliability
- **Essential Events Only**: Only reservation success, failure, and automation completion
- **Crash Prevention**: No complex UI objects or weak reference issues

### Notification Types

- **Success**: Informational alerts (reservation successful)
- **Failure**: Critical alerts (reservation failed)
- **Warning**: Warning alerts (automation completed with no success)

### Benefits

- **Simplicity**: Single setting to enable/disable all notifications
- **Reliability**: Works without system permissions
- **Stability**: No crashes from memory management issues
- **Focus**: Only shows notifications for important events
- **Immediate Delivery**: No delays or scheduling issues

## 🧪 Code Quality & Testing

### Automated Quality Checks

The project includes comprehensive automated quality checks:

- ✅ Project structure validation.
- ✅ Comprehensive linting with `./Scripts/odyssey.sh lint`.

### Example: Running All Checks

```bash
# Run all quality checks
./Scripts/odyssey.sh lint

# Build the application
./Scripts/odyssey.sh build

# Clean build artifacts
./Scripts/odyssey.sh clean
```

### CI/CD Pipeline Integration

The unified CI/CD pipeline (`.github/workflows/build-release.yml`) automatically runs all quality checks on every commit and pull request.

### 🧹 Code Quality Standards

The project maintains high code quality standards with:

- **📝 Consistent Logging:** All log messages use emojis and proper punctuation.
- **🎯 DRY Principle:** No code duplication, centralized validation and utilities.
- **🔧 Clean Architecture:** Modular services with clear separation of concerns.
- **📚 Comprehensive Documentation:** Up-to-date guides and examples.
- **⚡ Performance:** Optimized for speed and memory efficiency.
- **🛡️ Security:** Secure credential storage and input validation.

## 🏗️ Service Architecture

### JavaScript Modular Library

ODYSSEY uses a **modular JavaScript library** for all web automation functionality, organized across multiple specialized files. This approach provides:

- **Clean Separation:** JavaScript code is completely separated from Swift code.
- **Modular Organization:** JavaScript functions are organized by purpose across multiple files:
  - `JavaScriptCore.swift`: Core automation functions and element interactions.
  - `JavaScriptForms.swift`: Form handling and field filling functionality.
  - `JavaScriptPages.swift`: Page detection and state checking functions.
  - `JavaScriptLibrary.swift`: Main library that combines all modules.
- **Maintainability:** Related functions are grouped together for easier maintenance.
- **Reusability:** Reusable functions across all services.
- **Consistency:** Standardized error handling and logging patterns.
- **Debugging:** Easier to debug JavaScript issues with organized, modular structure.

### Modular Design Principles

The codebase follows a modular service-oriented architecture with these key principles:

#### Service Categories

- **Email Services:** Handle email integration, authentication, and verification (`EmailService`, `EmailKeychainHelper`).
- **Reservation Services:** Manage booking logic, status tracking, and orchestration (`ReservationOrchestrator`, `ReservationErrorHandler`).
- **WebKit Services:** Provide browser automation and web interaction capabilities (`WebKitService`, `WebKitAntiDetection`).
- **Infrastructure Services:** Handle data persistence, configuration, and utilities (`ConfigurationService`, `UserSettingsManager`).

#### Build System

- **Application:** Built using Xcode project (generated from `Config/project.yml`) with `xcodebuild`.
- **Shared Library:** `ODYSSEYBackend` provides common services to the app.
- **Unified Build:** Always use `./Scripts/odyssey.sh build` for consistent builds.

### Development Guidelines

#### Adding New Services

1. **Single Responsibility:** Each service should have one clear, well-defined purpose.
2. **Protocol-First Design:** Define clear interfaces before implementation.
3. **Dependency Injection:** Use centralized service management for testability.
4. **Concurrency Safety:** Ensure proper actor isolation and thread safety.
5. **Comprehensive Documentation:** Document all public APIs with clear examples.

#### Code Quality Standards

- **swift-format Compliance:** Follow established code style guidelines.
- **Documentation:** Use JSDoc-style comments for all public methods.
- **Error Handling:** Implement comprehensive error handling.
- **Performance:** Optimize for memory usage and responsiveness.

#### Automated Workflows

- ✅ **Unified Script Usage:** GitHub Actions now use our existing scripts instead of duplicating commands.
- ✅ **Version consistency validation** (tag vs project.yml vs Info.plist).
- ✅ **DMG installer creation** with app icon.
- ✅ **Code signing** for the application.
- ✅ **GitHub Releases publication** with comprehensive notes.
- ✅ **File size tracking** and reporting.
- ✅ **Professional release notes** with installation instructions.

## 🧪 Testing

### App Testing

- **God Mode:** Activate it by pressing `Command+G` in the app to show **GOD MODE** button to run all enabled reservations immediately.
- **Advanced Settings:** Always available to all users for customizing browser window behavior, autorun timing, and prior days configuration.
- **Manual Testing:** Test all UI interactions and automation flows.
- **Log Monitoring:** Use `./Scripts/odyssey.sh logs` to monitor real-time logs.
- **Build Testing:** The app is built using Xcode project generation and `xcodebuild`.

### 📸 Screenshots and Retention

- Failure screenshots are saved under `~/Library/Application Support/ODYSSEY/Screenshots`.
- Retention policy: 30 days. Old screenshots are cleaned on app startup via `FileManager.cleanupOldScreenshots(maxAge:)` using `AppConstants.defaultScreenshotRetentionDays`.

## 🚀 Release Process

The release process uses a streamlined workflow with automated CI/CD:

### Automated Release Process

The release process is fully automated through GitHub Actions and can be initiated using the unified script:

1. **Create a new release** using the unified script:

```bash
./Scripts/odyssey.sh release 1.1.1
```

This command will:

- Validate the version format.
- Update version in all files (`project.yml`, `Info.plist`, `AppConstants.swift`).
- Build and test the application.
- Commit changes with a descriptive message.
- Create and push git tag.
- Push changes to main branch.

### Build System Details

- **Application:** Uses Xcode project generation (`xcodegen`) and `xcodebuild`.
- **Shared Library:** `ODYSSEYBackend` provides common services to the app target.
- **Unified Approach:** Always use `./Scripts/odyssey.sh build` for consistent builds.

### 🤖 Automated CI/CD Workflow

The project includes a comprehensive CI/CD workflow:

- ✅ **Unified Script Usage:** GitHub Actions use our existing scripts instead of duplicating commands.
- ✅ **Version Validation:** Ensures tag version matches `project.yml` and `Info.plist`.
- ✅ **Code Signing:** Automatically signs the application.
- ✅ **DMG Creation:** Creates professional installer with app icon.
- ✅ **Release Notes:** Auto-generates comprehensive release notes with features and troubleshooting.
- ✅ **Changelog Generation:** Creates changelog from git commits since last tag.
- ✅ **GitHub Integration:** Automatically publishes to GitHub Releases.
- ✅ **Comprehensive Linting:** Uses configuration files to ignore acceptable warnings while catching critical issues.

**Key Workflows:**

- **Development Setup:** Use setup scripts to configure your environment.
- **Quality Assurance:** Run linting and testing scripts before committing.
- **Release Management:** Use release scripts for version updates and deployment.
- **Logging:** Monitor application logs for debugging and troubleshooting.
- **Build Management:** The app uses Xcode project generation.

## 📦 Related Documentation

- [README.md](../README.md) - User installation and setup.
- [USER_GUIDE.md](USER_GUIDE.md) - User guide.

## 🛡️ Security & Compliance

- **Credential Storage:** All sensitive credentials (e.g., email passwords) are securely stored in the macOS Keychain using Keychain Services. No credentials are ever stored in UserDefaults or plain text files.
- **Network Security:** All network requests use HTTPS. App Transport Security (ATS) is strictly enforced; there are no exceptions for ottawa.ca or any other domains.
- **Code Signing & Notarization:** The app is code signed for distribution, but is **not notarized by Apple** (no Apple Developer account).
- **Dependency Policy:** All runtime dependencies are native Swift/Apple frameworks. No third-party runtime code is included.
- **Input Validation:** All user input is validated and sanitized through the centralized `ValidationService`.
- **Data Privacy:** No user data is transmitted externally without explicit user consent. All automation runs locally on the user's machine.
- **Periodic Audits:** It is recommended to periodically audit all dependencies and review security practices as part of ongoing maintenance.
