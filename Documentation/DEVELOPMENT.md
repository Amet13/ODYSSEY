# 🎯 ODYSSEY Development Guide

This document provides comprehensive development guidelines, setup instructions, and workflow information for contributing to ODYSSEY.

## 📖 Table of Contents

1. [Overview](#-overview)
2. [System Requirements](#️-system-requirements)
3. [Quick Start (For Developers)](#️-quick-start-for-developers)
4. [Architecture Principles](#️-architecture-principles)
5. [Code Quality & Testing](#️-code-quality--testing)
6. [Development Workflow](#️-development-workflow)
7. [Testing](#️-testing)
8. [Release Process](#️-release-process)
9. [Common Pitfalls & Tips](#️-common-pitfalls--tips)
10. [Related Documentation](#️-related-documentation)
11. [Security & Compliance](#️-security--compliance)
12. [Need Help?](#️-need-help)
13. [Security Best Practices](#️-security-best-practices)

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

> **Note**: This guide is for contributors and developers. For user setup, see [USER_GUIDE.md](USER_GUIDE.md).

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

### **Core Design Principles**

- **Separation of Concerns**: Each component has a single, well-defined responsibility
- **Protocol-Oriented Design**: Use protocols for interfaces and dependency injection
- **Dependency Injection**: Centralized service management for better testability
- **Concurrency Safety**: Proper actor isolation and thread safety throughout
- **Error Handling**: Comprehensive error handling with clear categorization
- **Security First**: Always use secure storage (Keychain) for sensitive data
- **Performance**: Optimize for memory usage and responsiveness
- **Validation**: Centralized input validation and sanitization
- **Constants Management**: Centralized constants for maintainability

### **Architecture Layers**

- **Presentation**: User interface and user interaction logic
- **Application**: Business logic orchestration and use cases
- **Domain**: Core business entities and domain logic
- **Infrastructure**: External services, automation, and data persistence

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

The unified CI/CD pipeline (`.github/workflows/ci-cd.yml`) automatically runs all quality checks on every commit and pull request.

## 🏗️ Service Architecture

### **Modular Design Principles**

The codebase follows a modular service-oriented architecture with these key principles:

#### Service Categories

- **Email Services**: Handle email integration, authentication, and verification
- **Reservation Services**: Manage booking logic, status tracking, and orchestration
- **WebKit Services**: Provide browser automation and web interaction capabilities
- **Infrastructure Services**: Handle data persistence, configuration, and utilities

### Development Guidelines

#### Adding New Services

1. **Single Responsibility**: Each service should have one clear, well-defined purpose
2. **Protocol-First Design**: Define clear interfaces before implementation
3. **Dependency Injection**: Use centralized service management for testability
4. **Concurrency Safety**: Ensure proper actor isolation and thread safety
5. **Comprehensive Documentation**: Document all public APIs with clear examples

#### Testing Principles

- **Unit Tests**: Test each service in isolation
- **Integration Tests**: Verify service interactions
- **Mock Dependencies**: Use protocols for testable dependencies
- **Error Scenarios**: Test both success and failure cases

#### Code Quality Standards

- **SwiftLint Compliance**: Follow established code style guidelines
- **Documentation**: Use JSDoc-style comments for all public methods
- **Error Handling**: Implement comprehensive error handling
- **Performance**: Optimize for memory usage and responsiveness

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

- ✅ **Unified Script Usage**: GitHub Actions now use our existing scripts instead of duplicating commands
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
5. **Test GitHub Actions**: Verify `.github/workflows/scheduled-reservations.yml` works correctly

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

The release process uses two scripts for a complete workflow:

### 📋 Step 1: Prepare Release

1. **Update version and prepare release**:
   ```bash
   ./Scripts/create-release.sh 1.0.0
   ```
   This step:
   - Updates all version references in code
   - Adds changelog entry
   - Commits and tags the release
   - Triggers CI/CD pipeline

### 🚀 Step 2: Build and Deploy

1. **Build and deploy the release**:
   ```bash
   ./Scripts/deploy.sh release
   ```
   This step:
   - Builds both GUI and CLI applications
   - Creates DMG installer and CLI binary
   - Code signs both applications
   - Publishes to GitHub Releases

### 🔄 Automated CI/CD Pipeline

When you push a version tag, the CI/CD pipeline automatically:

- Builds both GUI and CLI applications
- Creates DMG installer and CLI binary
- Code signs both applications
- Publishes to GitHub Releases with comprehensive release notes
- Calculates and displays file sizes
- Generates changelog from git commits

### Automated CI/CD Features

- ✅ **Unified Script Usage**: GitHub Actions now use our existing scripts instead of duplicating commands
- ✅ **Version Validation**: Ensures tag version matches `project.yml` and `Info.plist`
- ✅ **Dual Build**: Creates both GUI app and CLI binary
- ✅ **Code Signing**: Automatically signs both applications
- ✅ **DMG Creation**: Creates professional installer with app icon
- ✅ **Release Notes**: Auto-generates comprehensive release notes with features and troubleshooting
- ✅ **File Size Tracking**: Displays app, DMG, and CLI sizes
- ✅ **Changelog Generation**: Creates changelog from git commits since last tag
- ✅ **GitHub Integration**: Automatically publishes to GitHub Releases
- ✅ **Comprehensive Linting**: Uses configuration files to ignore acceptable warnings while catching critical issues

### 🤖 Scheduled Reservations Workflow

The project also includes a separate workflow for automated reservation execution:

- ✅ **Scheduled Execution**: Runs daily at 5:53 PM EST (21:53 UTC)
- ✅ **Manual Triggers**: Can be triggered manually via GitHub Actions
- ✅ **CLI Integration**: Downloads latest CLI binary and runs reservations
- ✅ **Token Security**: Uses GitHub secrets for secure token storage
- ✅ **Error Handling**: Comprehensive logging and error reporting

## 🛠️ Development Workflow

The project includes various automation scripts in the `Scripts/` directory to streamline development tasks. These scripts handle building, testing, linting, and release management.

**Key Workflows:**

- **Development Setup**: Use setup scripts to configure your environment
- **Quality Assurance**: Run linting and testing scripts before committing
- **Release Management**: Use release scripts for version updates and deployment
- **Logging**: Monitor application logs for debugging and troubleshooting

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

- [Changelog](../CHANGELOG.md) - Release notes
- [README.md](../README.md) - User installation and setup
- [USER_GUIDE.md](USER_GUIDE.md) - GUI app user guide
- [CLI.md](CLI.md) - Command-line interface documentation

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
