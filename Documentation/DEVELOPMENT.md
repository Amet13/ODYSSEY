# 🎯 ODYSSEY Development Guide

This document provides comprehensive development guidelines, setup instructions, and workflow information for contributing to ODYSSEY.

## 🎯 Overview

ODYSSEY is a **dual-interface application** with both GUI and CLI versions:

- **🖥️ GUI Version**: Native macOS menu bar app with SwiftUI interface
- **💻 CLI Version**: Command-line interface for remote automation

Both versions share the same backend services and automation engine, so contributions can affect both interfaces.

## 🖥️ System Requirements

- **macOS 15.0 or later**
- **Xcode 16.0 or later**
- **Swift 6.1 or later**
- **Homebrew** (for installing development dependencies)

## 🚀 Quick Start (For Developers)

1. **Clone the repository**:

   ```bash
   git clone https://github.com/Amet13/ODYSSEY.git
   cd ODYSSEY
   ```

2. **Setup development environment**:

   ```bash
   ./Scripts/setup-dev.sh setup
   ```

3. **Build the project**:

   ```bash
   ./Scripts/build.sh
   ```

4. **Open in Xcode**:

   ```bash
   open Config/ODYSSEY.xcodeproj
   ```

5. **Run the app**:

   ```bash
   ./Scripts/build.sh
   ```

6. **Monitor logs** (in another terminal):
   ```bash
   ./Scripts/logs.sh
   ```

## 🏗️ Architecture Principles

### **Clean Architecture Layers**

- **Presentation Layer**: SwiftUI views and controllers
- **Application Layer**: Use cases and orchestration logic
- **Domain Layer**: Business entities and core logic
- **Infrastructure Layer**: WebKit automation, email services, storage

### **Service-Oriented Design**

- **Protocol-Oriented Design**: Use protocols for interfaces and dependency injection
- **Single Responsibility**: Each service has a single, well-defined responsibility
- **Dependency Injection**: Centralized `DependencyContainer` for service management
- **Concurrency Safety**: `@MainActor` and `Sendable` conformance throughout
- **Error Handling**: Unified `DomainError` system with hierarchical categorization
- **Security First**: Always use Keychain for sensitive data
- **Performance**: Optimize for memory usage and responsiveness
- **Validation**: Centralized validation in `ValidationService`
- **Constants**: Centralized constants in `AppConstants`

## 🧪 Code Quality & Testing

### Automated Quality Checks

The project includes comprehensive automated quality checks:

- ✅ SwiftLint code quality checks
- ✅ SwiftFormat code formatting validation
- ✅ ShellCheck bash script linting
- ✅ YAML and Markdown linting
- ✅ GitHub Actions workflow validation
- ✅ Project structure validation
- ✅ Comprehensive linting with `lint-all.sh`
- ✅ CLI build and testing

### Example: Running All Checks

```bash
# Run all quality checks
./Scripts/lint-all.sh

# Build and test
./Scripts/build.sh

# Monitor logs
./Scripts/logs.sh
```

### CI/CD Pipeline Integration

The unified CI/CD pipeline (`.github/workflows/pipeline.yml`) automatically runs all quality checks on every commit and pull request.

## 🏗️ Service Architecture

### **Current Service Structure**

The codebase has been transformed into a modular architecture with 11 focused services:

#### **Email Services (6 services)**

- `EmailGmailSupport.swift` - Gmail-specific functionality
- `EmailConfigurationDiagnostics.swift` - Email diagnostics
- `EmailKeychainHelper.swift` - Secure credential management
- `EmailIMAPStreamDelegate.swift` - IMAP connection handling
- `EmailClient.swift` - Email server connections
- `EmailParser.swift` - Email content parsing

#### **Reservation Services (3 services)**

- `ReservationError.swift` - Error definitions
- `ReservationRunStatus.swift` - Status management
- `ReservationOrchestrationMethods.swift` - Core orchestration

#### **WebKit Services (2 services)**

- `WebKitAutofillService.swift` - Browser autofill methods
- `WebKitReservationMethods.swift` - Reservation automation

### **Development Guidelines**

#### **Adding New Services**

1. **Follow Single Responsibility Principle**: Each service should have one clear purpose
2. **Implement Protocols**: Define clear interfaces for testability
3. **Use Dependency Injection**: Register new services in `DependencyContainer`
4. **Add Concurrency Safety**: Use `@MainActor` and `Sendable` where appropriate
5. **Document Public APIs**: Use JSDoc-style comments for all public methods

#### **Service Testing**

```swift
// Example: Testing a new service
class NewServiceTests: XCTestCase {
    func testServiceFunctionality() {
        let service = NewService()
        let result = service.performAction()
        XCTAssertTrue(result)
    }
}
```

#### **Protocol Conformance**

```swift
// Define protocol for new service
protocol NewServiceProtocol: ServiceProtocol {
    func performAction() -> Bool
}

// Implement service
class NewService: NewServiceProtocol {
    func performAction() -> Bool {
        // Implementation
        return true
    }
}
```

#### Unified Pipeline Structure

The pipeline includes:

- ✅ **Quality Checks**: SwiftLint, SwiftFormat, ShellCheck, YAML/Markdown linting
- ✅ **Build Validation**: Xcode project generation with XcodeGen
- ✅ **Debug and Release builds** for GUI app
- ✅ **CLI binary compilation** and testing
- ✅ **App structure analysis** and size validation
- ✅ **Build artifact uploads** for debugging
- ✅ **Documentation generation** and upload

#### Automated Workflows

- ✅ **Version consistency validation** (tag vs project.yml vs Info.plist)
- ✅ **Changelog generation** from git commits since last tag
- ✅ **DMG installer creation** with app icon
- ✅ **CLI binary packaging** with version naming
- ✅ **Code signing** for both applications
- ✅ **GitHub Releases publication** with comprehensive notes
- ✅ **File size tracking** and reporting
- ✅ **Professional release notes** with installation instructions

#### Pipeline Benefits

- ✅ **Efficiency**: Single workflow eliminates duplication and maintenance overhead
- ✅ **Consistency**: Same build environment for all releases
- ✅ **Quality**: Automated quality checks prevent regressions
- ✅ **Automation**: No manual release steps required
- ✅ **Transparency**: All build artifacts and logs are preserved
- ✅ **Reliability**: Comprehensive validation ensures release quality
- ✅ **Resource Optimization**: Eliminates redundant builds and setup steps

## 🧪 Testing

### GUI Testing

- **Manual Testing**: Test all UI interactions and automation flows
- **Log Monitoring**: Use `./Scripts/logs.sh` to monitor real-time logs
- **Browser Window**: Optional for development and support. By default, automation runs invisibly. Enable "Show browser window" in God Mode Advanced Settings to monitor automation and diagnose issues.

### CLI Testing

1. **Build CLI**: `swift build --product odyssey-cli`
2. **Test Commands**: `./.build/arm64-apple-macosx/debug/odyssey-cli help`
3. **Export Token**: Generate token from GUI for testing
4. **Test Automation**: `export ODYSSEY_EXPORT_TOKEN="<exported_token>" && ./odyssey-cli run`
5. **Test GitHub Actions**: Verify `.github/workflows/reservation-automation.yml` works correctly

### Supported CLI Commands

- `run [--now] [--prior <days>]` - Run reservations (with optional immediate execution and prior days)
- `configs` - List all configurations from export token
- `settings [--unmask]` - Show user settings (with optional unmasking)
- `help` - Show CLI help and usage
- `version` - Show CLI version information

### CLI Integration

- **GitHub Actions**: Perfect for automated reservation scheduling
- **CI/CD**: Integrate with existing automation pipelines

## 🚀 Release Process

1. **Update version numbers** in `Info.plist`, `AppConstants.swift`, and documentation.
2. **Update the changelog** (`CHANGELOG.md`).
3. **Run all tests and linting** to ensure a clean build:
   ```bash
   ./Scripts/build.sh
   ```
4. **Create and push a version tag:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
5. **Automated Release Pipeline:**
   - The CI/CD pipeline automatically detects the tag
   - Builds both GUI and CLI applications
   - Creates DMG installer and CLI binary
   - Code signs both applications
   - Publishes to GitHub Releases with comprehensive release notes
   - Calculates and displays file sizes
   - Generates changelog from git commits

### Automated Release Features

- ✅ **Version Validation**: Ensures tag version matches `project.yml` and `Info.plist`
- ✅ **Dual Build**: Creates both GUI app and CLI binary
- ✅ **Code Signing**: Automatically signs both applications
- ✅ **DMG Creation**: Creates professional installer with app icon
- ✅ **Release Notes**: Auto-generates comprehensive release notes with features and troubleshooting
- ✅ **File Size Tracking**: Displays app, DMG, and CLI sizes
- ✅ **Changelog Generation**: Creates changelog from git commits since last tag
- ✅ **GitHub Integration**: Automatically publishes to GitHub Releases
- ✅ **Comprehensive Linting**: Uses configuration files to ignore acceptable warnings while catching critical issues

### Manual Release (Alternative)

If you prefer manual releases, you can still use the scripts:

- **Create DMG**: `./Scripts/create-release.sh`
- **Code Sign**: `codesign --force --deep --sign - /path/to/app`
- **Notarize**: See `Scripts/create-release.sh` for notarization steps

## 💡 Common Pitfalls & Tips

- ⚠️ **Xcode version mismatch:** Make sure you are using Xcode 16+ (check with `xcodebuild -version`).
- 🛑 **Build errors after pulling changes:** Run `./Scripts/build.sh` to auto-format and lint the code.
- 🔑 **Keychain issues:** If you see credential errors, re-enter credentials in Settings and restart the app.
- 📝 **Documentation:** Always update docs and comments when making changes.
- 🧹 **Clean builds:** If you encounter strange build errors, try cleaning the build folder in Xcode (`Shift+Cmd+K`).

## 📦 Related Documentation

- [Changelog](CHANGELOG.md) - Release notes
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute
- [README.md](../README.md) - User installation and setup

## 🛡️ Security & Compliance

- **Credential Storage:** All sensitive credentials (e.g., email passwords) are securely stored in the macOS Keychain using Keychain Services. No credentials are ever stored in UserDefaults or plain text files.
- **Network Security:** All network requests use HTTPS. App Transport Security (ATS) is strictly enforced; there are no exceptions for ottawa.ca or any other domains.
- **Code Signing & Notarization:** The app is code signed for distribution, but is **not notarized by Apple** (no Apple Developer account). To enable notarization, see the commented steps in `Scripts/create-release.sh` and provide the required credentials.
- **Dependency Policy:** All runtime dependencies are native Swift/Apple frameworks. No third-party runtime code is included.
- **Input Validation:** All user input is validated and sanitized through the centralized `ValidationService`.
- **Data Privacy:** No user data is transmitted externally without explicit user consent. All automation runs locally on the user's machine.
- **Periodic Audits:** It is recommended to periodically audit all dependencies and review security practices as part of ongoing maintenance.

## 🙌 Need Help?

- Open an issue on [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
- See the [README](../README.md) for user-facing instructions
- For advanced troubleshooting, check the logs in Console.app and enable "Show browser window" in God Mode Advanced Settings to monitor automation

## 🛡️ Security Best Practices

- 🔒 **Credentials:** Always use the macOS Keychain for sensitive data.
- 🌐 **Network:** All requests must use HTTPS. No exceptions.
- 📝 **Code Signing:** All builds for distribution must be code signed.
- 🚫 **Privacy:** Never transmit user data externally without explicit consent.
- 🧪 **Audit:** Periodically review dependencies and security settings.

## 📚 Additional Resources

- **[SCRIPTS.md](SCRIPTS.md)** - Complete scripts documentation and usage guide
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Detailed contribution guidelines
- **[CLI.md](CLI.md)** - Command-line interface documentation
- **[USER_GUIDE.md](USER_GUIDE.md)** - User guide for the application
