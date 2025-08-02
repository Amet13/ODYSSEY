# 🧑‍💻 **ODYSSEY development guide**

## 🎯 Overview

ODYSSEY is a **dual-interface application** with both GUI and CLI versions:

- **🖥️ GUI Version**: Native macOS menu bar app with SwiftUI interface
- **💻 CLI Version**: Command-line interface for remote automation

Both versions share the same backend services and automation engine, so contributions can affect both interfaces.

## 🖥️ System requirements

- **macOS 15.0 or later**
- **Xcode 16.0 or later**
- **Swift 6.1 or later**
- **Homebrew** (_for installing development dependencies_)

## 🚀 Quick start (for developers)

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

## 🏗️ Architecture principles

### Core design principles

- **Separation of concerns:** Each component has a single, well-defined responsibility.
- **Protocol-oriented design:** Use protocols for interfaces and dependency injection.
- **Dependency injection:** Centralized service management for better testability.
- **Concurrency safety:** Proper actor isolation and thread safety throughout.
- **Error handling:** Comprehensive error handling with clear categorization.
- **Security first:** Always use secure storage (_Keychain_) for sensitive data.
- **Performance:** Optimize for memory usage and responsiveness.
- **Validation:** Centralized input validation and sanitization.
- **Constants management:** Centralized constants for maintainability.

### Architecture layers

- **Presentation**: User interface and user interaction logic
- **Application**: Business logic orchestration and use cases
- **Domain**: Core business entities and domain logic
- **Infrastructure**: External services, automation, and data persistence

## 🧪 Code quality & testing

### Automated quality checks

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
./Scripts/odyssey.sh lint
```

### CI/CD pipeline integration

The unified CI/CD pipeline (`.github/workflows/ci-cd.yml`) automatically runs all quality checks on every commit and pull request.

## 🏗️ Service architecture

### JavaScript Centralized Library

ODYSSEY uses a **centralized JavaScript library** for all web automation functionality. This approach provides:

- **Clean Separation**: JavaScript code is completely separated from Swift code
- **Maintainability**: All JavaScript functions in one location
- **Reusability**: Reusable functions across all services
- **Consistency**: Standardized error handling and logging patterns
- **Debugging**: Easier to debug JavaScript issues in one centralized location

### Modular design principles

The codebase follows a modular service-oriented architecture with these key principles:

#### Service Categories

- **Email Services**: Handle email integration, authentication, and verification
- **Reservation Services**: Manage booking logic, status tracking, and orchestration
- **WebKit Services**: Provide browser automation and web interaction capabilities
- **Infrastructure Services**: Handle data persistence, configuration, and utilities

### Development guidelines

#### Adding New Services

1. **Single Responsibility**: Each service should have one clear, well-defined purpose
2. **Protocol-First Design**: Define clear interfaces before implementation
3. **Dependency Injection**: Use centralized service management for testability
4. **Concurrency Safety**: Ensure proper actor isolation and thread safety
5. **Comprehensive Documentation**: Document all public APIs with clear examples

#### Code Quality Standards

- **SwiftLint Compliance**: Follow established code style guidelines
- **Documentation**: Use JSDoc-style comments for all public methods
- **Error Handling**: Implement comprehensive error handling
- **Performance**: Optimize for memory usage and responsiveness

#### Unified pipeline structure

The pipeline includes:

- ✅ **Quality Checks**: SwiftLint, SwiftFormat, ShellCheck, YAML/Markdown linting
- ✅ **Build Validation**: Xcode project generation with XcodeGen
- ✅ **Debug and Release builds** for GUI app
- ✅ **CLI binary compilation** and testing
- ✅ **App structure analysis** and size validation
- ✅ **Build artifact uploads** for debugging
- ✅ **Documentation generation** and upload

#### Automated workflows

- ✅ **Unified Script Usage**: GitHub Actions now use our existing scripts instead of duplicating commands
- ✅ **Version consistency validation** (tag vs project.yml vs Info.plist)
- ✅ **Changelog generation** from git commits since last tag
- ✅ **DMG installer creation** with app icon
- ✅ **CLI binary packaging** with version naming
- ✅ **Code signing** for both applications
- ✅ **GitHub Releases publication** with comprehensive notes
- ✅ **File size tracking** and reporting
- ✅ **Professional release notes** with installation instructions

#### Pipeline benefits

- ✅ **Efficiency**: Single workflow eliminates duplication and maintenance overhead
- ✅ **Consistency**: Same build environment for all releases
- ✅ **Quality**: Automated quality checks prevent regressions
- ✅ **Automation**: No manual release steps required
- ✅ **Transparency**: All build artifacts and logs are preserved
- ✅ **Reliability**: Comprehensive validation ensures release quality
- ✅ **Resource Optimization**: Eliminates redundant builds and setup steps

## 🧪 Testing

### GUI testing

- **God Mode**: Activate it by pressing `Command+G` in the app to show **GOD MODE** button and **Advanced Settings**
- **Manual Testing**: Test all UI interactions and automation flows
- **Log Monitoring**: Use `./Scripts/logs.sh` to monitor real-time logs
- **Browser Window**: Optional for development and support. By default, automation runs invisibly. Enable "Show browser window" in God Mode Advanced Settings to monitor automation and diagnose issues.

### CLI testing

1. **Build CLI**: `./Scripts/build.sh`
2. **Test Commands**: `./.build/arm64-apple-macosx/debug/odyssey-cli help`
3. **Export Token**: Generate token from GUI for testing
4. **Test Automation**: `export ODYSSEY_EXPORT_TOKEN="<exported_token>" && ./odyssey-cli run`
5. **Test GitHub Actions**: Verify `.github/workflows/scheduled-reservations.yml` works correctly

### CLI integration

- **GitHub Actions**: Perfect for automated reservation scheduling
- **CI/CD**: Integrate with existing automation pipelines

## 🚀 Release process

The release process uses two scripts for a complete workflow:

### Step 1: Prepare release

1. **Update version and prepare release**:
   ```bash
   ./Scripts/create-release.sh 1.0.0
   ```
   This step:
   - Updates all version references in code
   - Adds changelog entry
   - Commits and tags the release
   - Triggers CI/CD pipeline

### Step 2: Build and deploy

1. **Build and deploy the release**:
   ```bash
   ./Scripts/deploy.sh release
   ```
   This step:
   - Builds both GUI and CLI applications
   - Creates DMG installer and CLI binary
   - Code signs both applications
   - Publishes to GitHub Releases

### Automated CI/CD pipeline

When you push a version tag, the CI/CD pipeline automatically:

- Builds both GUI and CLI applications
- Creates DMG installer and CLI binary
- Code signs both applications
- Publishes to GitHub Releases with comprehensive release notes
- Calculates and displays file sizes
- Generates changelog from git commits

### Automated CI/CD features

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

### 🤖 Scheduled reservations workflow

The project also includes a separate workflow for automated reservation execution:

- ✅ **Scheduled Execution**: Runs daily at 5:53 PM EST (21:53 UTC)
- ✅ **Manual Triggers**: Can be triggered manually via GitHub Actions
- ✅ **CLI Integration**: Downloads latest CLI binary and runs reservations
- ✅ **Token Security**: Uses GitHub secrets for secure token storage
- ✅ **Error Handling**: Comprehensive logging and error reporting

## 🛠️ Development workflow

The project includes various automation scripts in the `Scripts/` directory to streamline development tasks. These scripts handle building, testing, linting, and release management.

**Key Workflows:**

- **Development Setup**: Use setup scripts to configure your environment
- **Quality Assurance**: Run linting and testing scripts before committing
- **Release Management**: Use release scripts for version updates and deployment
- **Logging**: Monitor application logs for debugging and troubleshooting

## 📦 Related documentation

- [CHANGELOG.md](../CHANGELOG.md) - Release notes
- [README.md](../README.md) - User installation and setup
- [USER_GUIDE.md](USER_GUIDE.md) - GUI app user guide
- [CLI.md](CLI.md) - Command-line interface documentation

## 🛡️ Security & compliance

- **Credential Storage:** All sensitive credentials (e.g., email passwords) are securely stored in the macOS Keychain using Keychain Services. No credentials are ever stored in UserDefaults or plain text files.
- **Network Security:** All network requests use HTTPS. App Transport Security (ATS) is strictly enforced; there are no exceptions for ottawa.ca or any other domains.
- **Code Signing & Notarization:** The app is code signed for distribution, but is **not notarized by Apple** (no Apple Developer account). To enable notarization, see the commented steps in `Scripts/create-release.sh` and provide the required credentials.
- **Dependency Policy:** All runtime dependencies are native Swift/Apple frameworks. No third-party runtime code is included.
- **Input Validation:** All user input is validated and sanitized through the centralized `ValidationService`.
- **Data Privacy:** No user data is transmitted externally without explicit user consent. All automation runs locally on the user's machine.
- **Periodic Audits:** It is recommended to periodically audit all dependencies and review security practices as part of ongoing maintenance.

## 🙌 Need help?

- Open an issue on [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
- See the [README.md](../README.md) for user-facing instructions
- For advanced troubleshooting, check the logs in Console.app and enable "Show browser window" in God Mode Advanced Settings to monitor automation
