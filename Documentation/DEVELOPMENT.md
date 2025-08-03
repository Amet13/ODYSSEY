# 🧑‍💻 ODYSSEY Development Guide

## 🎯 Overview

ODYSSEY is a **dual-interface application** with both GUI and CLI versions:

- **🖥️ GUI Version:** Native macOS menu bar app with SwiftUI interface.
- **💻 CLI Version:** Command-line interface for remote automation.

Both versions share the same backend services and automation engine, so contributions can affect both interfaces.

## 🖥️ System Requirements

- **macOS 15.0 or later**
- **Xcode 16.0 or later**
- **Swift 6.1 or later**
- **Homebrew** (_for installing development dependencies_)

## 🚀 Quick Start (for Developers)

> **Note:** This guide is for contributors and developers. For user setup, see **[USER_GUIDE.md](USER_GUIDE.md)**.

1. **Clone the repository**:

   ```bash
   git clone https://github.com/Amet13/ODYSSEY.git
   cd ODYSSEY
   ```

2. **Setup development environment**:

   ```bash
   ./Scripts/odyssey.sh setup
   ```

3. **Build the project**:

   ```bash
   ./Scripts/odyssey.sh build
   ```

4. **Monitor logs** (in another terminal):

   ```bash
   ./Scripts/odyssey.sh logs
   ```

5. **Run quality checks**:

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

### Architecture Layers

- **Presentation:** User interface and user interaction logic.
- **Application:** Business logic orchestration and use cases.
- **Domain:** Core business entities and domain logic.
- **Infrastructure:** External services, automation, and data persistence.

## 🧪 Code Quality & Testing

### Automated Quality Checks

The project includes comprehensive automated quality checks:

- ✅ Project structure validation.
- ✅ Comprehensive linting with `./Scripts/odyssey.sh lint`.
- ✅ CLI build and testing.
- ✅ Version consistency validation with `./Scripts/odyssey.sh validate`.

### Example: Running All Checks

```bash
# Run all quality checks
./Scripts/odyssey.sh lint

# Build the application
./Scripts/odyssey.sh build

# Clean build artifacts
./Scripts/odyssey.sh clean

# Validate version consistency
./Scripts/odyssey.sh validate
```

### CI/CD Pipeline Integration

The unified CI/CD pipeline (`.github/workflows/build-release.yml`) automatically runs all quality checks on every commit and pull request.

### 🧹 Code Quality Standards

The project maintains high code quality standards with:

- **📝 Consistent Logging**: All log messages use emojis and proper punctuation.
- **🎯 DRY Principle**: No code duplication, centralized validation and utilities.
- **🔧 Clean Architecture**: Modular services with clear separation of concerns.
- **📚 Comprehensive Documentation**: Up-to-date guides and examples.
- **⚡ Performance**: Optimized for speed and memory efficiency.
- **🛡️ Security**: Secure credential storage and input validation.

## 🏗️ Service Architecture

### JavaScript Centralized Library

ODYSSEY uses a **centralized JavaScript library** for all web automation functionality. This approach provides:

- **Clean Separation:** JavaScript code is completely separated from Swift code.
- **Maintainability:** All JavaScript functions in one location.
- **Reusability:** Reusable functions across all services.
- **Consistency:** Standardized error handling and logging patterns.
- **Debugging:** Easier to debug JavaScript issues in one centralized location.

### Modular Design Principles

The codebase follows a modular service-oriented architecture with these key principles:

#### Service Categories

- **Email Services**: Handle email integration, authentication, and verification.
- **Reservation Services**: Manage booking logic, status tracking, and orchestration.
- **WebKit Services**: Provide browser automation and web interaction capabilities.
- **Infrastructure Services**: Handle data persistence, configuration, and utilities.

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

#### Unified Pipeline Structure

The pipeline includes:

- ✅ **Quality Checks**: swift-format, ShellCheck, YAML/Markdown linting.
- ✅ **Build Validation**: Xcode project generation with XcodeGen.
- ✅ **Debug and Release builds** for GUI app.
- ✅ **CLI binary compilation** and testing.
- ✅ **App structure analysis** and size validation.
- ✅ **Build artifact uploads** for debugging.
- ✅ **Changelog generation** and upload.

#### Automated Workflows

- ✅ **Unified Script Usage:** GitHub Actions now use our existing scripts instead of duplicating commands.
- ✅ **Version consistency validation** (tag vs project.yml vs Info.plist).
- ✅ **DMG installer creation** with app icon.
- ✅ **CLI binary packaging** with version naming.
- ✅ **Code signing** for both applications.
- ✅ **GitHub Releases publication** with comprehensive notes.
- ✅ **File size tracking** and reporting.
- ✅ **Professional release notes** with installation instructions.

#### Pipeline Benefits

- ✅ **Efficiency:** Single workflow eliminates duplication and maintenance overhead.
- ✅ **Consistency:** Same build environment for all releases.
- ✅ **Quality:** Automated quality checks prevent regressions.
- ✅ **Automation:** No manual release steps required.
- ✅ **Transparency:** All build artifacts and logs are preserved.
- ✅ **Reliability:** Comprehensive validation ensures release quality.
- ✅ **Resource Optimization:** Eliminates redundant builds and setup steps.

## 🧪 Testing

### GUI Testing

- **God Mode:** Activate it by pressing `Command+G` in the app to show **GOD MODE** button and **Advanced Settings**.
- **Manual Testing:** Test all UI interactions and automation flows.
- **Log Monitoring:** Use `./Scripts/odyssey.sh logs` to monitor real-time logs.
- **Browser Window:** Optional for development and support. By default, automation runs invisibly. Enable "Show browser window" in God Mode Advanced Settings to monitor automation and diagnose issues.

### CLI Testing

1. **Build CLI**: `./Scripts/odyssey.sh build`.
2. **Test Commands**: `./.build/arm64-apple-macosx/debug/odyssey-cli`.
3. **Export Token**: Generate token from GUI for testing.
4. **Test GitHub Actions**: Verify `.github/workflows/build-release.yml` works correctly.

### CLI Integration

- **Scheduled Reservations:** Refer to `.github/workflows/scheduled-reservations.yml` for automated reservation booking.

## 🚀 Release Process

The release process uses a streamlined workflow with automated CI/CD and centralized version management.

### Version Management

ODYSSEY uses a centralized version management system with the `odyssey.sh` script:

```bash
# Create a new version tag (updates all files and creates git tag)
./Scripts/odyssey.sh tag vX.Y.Z

# Validate version consistency across all files
./Scripts/odyssey.sh validate
```

**Version Management Features:**

- ✅ **Centralized versioning** with `VERSION` file as single source of truth
- ✅ **Automatic file updates** across all version locations
- ✅ **Version consistency validation** to prevent mismatches
- ✅ **Git integration** with automatic commits and tag creation
- ✅ **Safety checks** for uncommitted changes and existing tags

### Automated Release Process

The release process is fully automated through GitHub Actions:

1. **Create a version tag** using the unified script:

   ```bash
   ./Scripts/odyssey.sh tag vX.Y.Z
   ```

2. **GitHub Actions automatically**:

   - Runs CI pipeline (setup, lint, build)
   - Builds both GUI and CLI applications in release mode
   - Creates DMG installer and CLI binary
   - Code signs both applications
   - Generates commit-based changelog
   - Publishes to GitHub Releases with comprehensive release notes

### Automated CI/CD Pipeline

When you push a version tag, the CI/CD pipeline automatically:

- Builds both GUI and CLI applications.
- Creates DMG installer and CLI binary.
- Code signs both applications.
- Publishes to GitHub Releases with comprehensive release notes.
- Calculates and displays file sizes.
- Generates changelog from git commits.

### Automated CI/CD Features

- ✅ **Unified Script Usage:** GitHub Actions now use our existing scripts instead of duplicating commands.
- ✅ **Version Validation:** Ensures tag version matches `project.yml` and `Info.plist`.
- ✅ **Dual Build:** Creates both GUI app and CLI binary.
- ✅ **Code Signing:** Automatically signs both applications.
- ✅ **DMG Creation:** Creates professional installer with app icon.
- ✅ **Release Notes:** Auto-generates comprehensive release notes with features and troubleshooting.
- ✅ **File Size Tracking:** Displays app, DMG, and CLI sizes.
- ✅ **Changelog Generation:** Creates changelog from git commits since last tag.
- ✅ **GitHub Integration:** Automatically publishes to GitHub Releases.
- ✅ **Comprehensive Linting:** Uses configuration files to ignore acceptable warnings while catching critical issues.

### 🤖 Automated CI/CD Workflow

The project includes a comprehensive CI/CD workflow:

- ✅ **Automated Builds:** Triggers on version tags.
- ✅ **Dual Artifacts:** Creates both GUI app and CLI binary.
- ✅ **Code Signing:** Automatically signs applications.
- ✅ **DMG Creation:** Creates professional installer.
- ✅ **Release Notes:** Auto-generates changelog from commits.
- ✅ **GitHub Integration:** Publishes to GitHub Releases.
- ✅ **Comprehensive Linting:** Runs all quality checks.

**Key Workflows:**

- **Development Setup:** Use setup scripts to configure your environment.
- **Quality Assurance:** Run linting and testing scripts before committing.
- **Release Management:** Use release scripts for version updates and deployment.
- **Logging:** Monitor application logs for debugging and troubleshooting.

## 🛠️ Development Scripts

### odyssey.sh - Unified Development Script

The `./Scripts/odyssey.sh` script provides a unified interface for all development tasks:

```bash
# Development Commands
./Scripts/odyssey.sh setup      # Setup development environment
./Scripts/odyssey.sh build      # Build application and CLI
./Scripts/odyssey.sh lint       # Run comprehensive linting
./Scripts/odyssey.sh clean      # Clean build artifacts

# Version Management
./Scripts/odyssey.sh tag vX.Y.Z # Update version and create git tag
./Scripts/odyssey.sh validate   # Validate version consistency

# CI/CD Commands
./Scripts/odyssey.sh ci         # Run CI pipeline (setup, lint, build)
./Scripts/odyssey.sh deploy     # Deploy and create release artifacts
./Scripts/odyssey.sh changelog  # Generate commit-based changelog

# Utility Commands
./Scripts/odyssey.sh logs       # Show application logs
./Scripts/odyssey.sh help       # Show help message
```

**Key Features:**

- ✅ **Unified interface** for all development tasks
- ✅ **Automated environment setup** with dependency installation
- ✅ **Comprehensive linting** with multiple tools
- ✅ **Version management** with consistency validation
- ✅ **CI/CD integration** for automated releases
- ✅ **Error handling** with clear status messages

### Script Categories

**Development Commands:**

- `setup` - Install dependencies and configure development environment
- `build` - Build both GUI app and CLI binary
- `lint` - Run comprehensive code quality checks
- `clean` - Remove build artifacts and temporary files

**Version Management:**

- `tag vX.Y.Z` - Update version across all files and create git tag
- `validate` - Check version consistency across all project files

**CI/CD Commands:**

- `ci` - Run complete CI pipeline (setup, lint, build)
- `deploy` - Create release artifacts and DMG installer
- `changelog` - Generate changelog from git commits

**Utility Commands:**

- `logs` - Monitor application logs in real-time
- `help` - Display command usage and examples

## 📦 Related Documentation

- [README.md](../README.md) - User installation and setup.
- [USER_GUIDE.md](USER_GUIDE.md) - GUI app user guide.
- [CLI.md](CLI.md) - Command-line interface documentation.

## 🛡️ Security & Compliance

- **Credential Storage:** All sensitive credentials (e.g., email passwords) are securely stored in the macOS Keychain using Keychain Services. No credentials are ever stored in UserDefaults or plain text files.
- **Network Security:** All network requests use HTTPS. App Transport Security (ATS) is strictly enforced; there are no exceptions for ottawa.ca or any other domains.
- **Code Signing & Notarization:** The app is code signed for distribution, but is **not notarized by Apple** (no Apple Developer account).
- **Dependency Policy:** All runtime dependencies are native Swift/Apple frameworks. No third-party runtime code is included.
- **Input Validation:** All user input is validated and sanitized through the centralized `ValidationService`.
- **Data Privacy:** No user data is transmitted externally without explicit user consent. All automation runs locally on the user's machine.
- **Periodic Audits:** It is recommended to periodically audit all dependencies and review security practices as part of ongoing maintenance.
