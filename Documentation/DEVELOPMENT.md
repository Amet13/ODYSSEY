# 🧑‍💻 ODYSSEY Development Guide

## 🎯 Overview

ODYSSEY is a macOS menu bar application built with SwiftUI.

## 🖥️ System Requirements

- **macOS 26.0 or later.**
- **Xcode 26.0 or later.**
- **Swift 6.2 or later.**
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

ODYSSEY uses a **modular Swift Package Manager** architecture with a single main target:

- **`ODYSSEY`:** macOS menu bar application built with SwiftUI that includes both UI and backend services.
- **Backend Services:** Integrated backend services and automation engine within the main application target.

### Architecture Layers

- **Presentation:** User interface and user interaction logic (`Views/`, `Controllers/`).
- **Application:** Business logic orchestration and use cases (`Application/`).
- **Domain:** Core business entities and domain logic (`Domain/`).
- **Infrastructure:** External services, automation, and data persistence (`Infrastructure/`, `Services/`).
- **Shared:** Common utilities and protocols (`SharedUtils/`, `SharedCore/`).

## Notification System

ODYSSEY implements a built-in notification system that works without requiring macOS system notification permissions. The system provides:

- **Success Notifications:** Alerts when reservations are successfully booked
- **Failure Notifications:** Critical alerts when reservation attempts fail
- **Completion Notifications:** Summary alerts when automation runs complete
- **Delivery Methods:** Uses NSAlert modal dialogs and temporary menu bar title updates
- **User Control:** Can be enabled/disabled in Advanced Settings
- **No System Permissions:** Works entirely within app sandbox without external notification permissions

## 🧪 Code Quality & Testing

### Automated Quality Checks

The project includes comprehensive automated quality checks:

- Project structure validation.
- Comprehensive linting with `./Scripts/odyssey.sh lint`.

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

- **Application:** Built using Xcode project generated from `Config/project.yml` using `xcodegen` and `xcodebuild`.
- **All-in-One Target:** Single `ODYSSEY` target contains both UI and backend services.
- **Unified Build:** Always use `./Scripts/odyssey.sh build` for consistent builds across development and CI/CD.

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

## 🧪 Testing

### App Testing

- **God Mode:** Activate it by pressing `Command+G` in the main app window to toggle the **GOD MODE** UI. When enabled, a "GOD MODE" button appears in the header that allows running all enabled reservations immediately, bypassing the normal scheduling system.
- **Advanced Settings:** Available to all users for customizing:
  - Browser window visibility during automation
  - Custom autorun timing (default: 6:00 PM)
  - Custom prior days before reservation (default: 2 days)
  - Notification preferences
  - Browser window behavior on failures
- **Manual Testing:** Test all UI interactions and automation flows:
  - Configuration creation and editing
  - Manual reservation runs
  - Email testing and verification
  - Settings validation
- **Log Monitoring:** Use `./Scripts/odyssey.sh logs` to monitor real-time logs with emoji-prefixed messages.
- **Build Testing:** The app is built using Xcode project generation via `xcodegen` and `xcodebuild`.

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

- Validate the version format and check for existing tags.
- Update version numbers in `Config/project.yml`, `Sources/AppCore/Info.plist`, and `Sources/SharedUtils/AppConstants.swift`.
- Build and test the application using the unified build script.
- Commit changes with a descriptive message.
- Create and push git tag to trigger automated release.
- Push changes to main branch.
- Trigger GitHub Actions workflow for DMG creation and release publishing.

### Build System Details

- **Application:** Uses Xcode project generation via `xcodegen` from `Config/project.yml` and `xcodebuild` for compilation.
- **Single Target:** All functionality is contained within the main `ODYSSEY` target (no separate backend library).
- **Unified Approach:** Always use `./Scripts/odyssey.sh build` for consistent builds across development and CI/CD.
- **Code Signing:** Automatic code signing for distribution (not notarized by Apple).

### 🤖 Automated CI/CD Workflow

The project includes a comprehensive CI/CD workflow (`.github/workflows/build-release.yml`):

- **Unified Script Usage:** GitHub Actions use existing scripts instead of duplicating commands.
- **Version Validation:** Ensures tag version matches `Config/project.yml` and `Sources/AppCore/Info.plist`.
- **Code Signing:** Automatically signs the application for distribution.
- **DMG Creation:** Creates professional installer DMG with app icon using `create-dmg`.
- **Release Notes:** Auto-generates comprehensive release notes with features and troubleshooting.
- **Changelog Generation:** Creates changelog from git commits since last tag.
- **GitHub Integration:** Automatically publishes to GitHub Releases.
- **Quality Checks:** Runs linting and build validation before releases.
- **Cross-Platform:** Works on both Intel and Apple Silicon Macs.

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
