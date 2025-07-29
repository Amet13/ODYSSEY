# ODYSSEY Development Guide

## 🎯 Overview

ODYSSEY is a **dual-interface application** with both GUI and CLI versions:

- **🖥️ GUI Version**: Native macOS menu bar app with SwiftUI interface
- **💻 CLI Version**: Command-line interface for remote automation

Both versions share the same backend services and automation engine.

## 🖥️ System Requirements

See [REQUIREMENTS.md](REQUIREMENTS.md) for complete system requirements.

## 🚀 Quick Start (For Developers)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Amet13/ODYSSEY.git
   cd ODYSSEY
   ```
2. **Install dependencies:**
   ```bash
   brew install xcodegen swiftlint
   ```
3. **Generate Xcode project:**
   ```bash
   xcodegen
   ```
4. **Build and run:**
   ```bash
   ./Scripts/build.sh
   ```
5. **(Optional) Open in Xcode:**
   ```bash
   open Config/ODYSSEY.xcodeproj
   ```
6. **Run code quality checks:**
   ```bash
   swiftlint lint
   ```

## 🏗️ Architecture Principles

- **Protocol-Oriented Design:** Clear interfaces for all services and models
- **Separation of Concerns:** Each service/component has a single responsibility
- **Dependency Injection:** Use singletons for shared services and dependency injection patterns
- **Reactive Programming:** Use Combine for state management and async operations
- **Centralized Validation:** All input validation in `ValidationService`
- **Centralized Constants:** All constants in `AppConstants`
- **Error Recovery:** Graceful error handling and fallback strategies
- **Performance:** Optimized for memory usage and responsiveness
- **Security:** Local processing, secure credential storage, and privacy by design

## 🐞 Debugging & Troubleshooting

- **Browser Window:** Optional for development and support. By default, automation runs invisibly. Enable "Show browser window" in God Mode Advanced Settings to monitor automation and diagnose issues.
- **God Mode:** Advanced parallel execution mode accessible via Cmd+G keyboard shortcut for running multiple reservations simultaneously.
- **Logs:** All logs use `os.log` with emoji indicators. Sensitive data is masked or marked as private.
- **Console.app:** View logs by searching for `ODYSSEY` or `com.odyssey.app`.
- **Error Handling:** All errors are logged with context and user-friendly messages are shown in the UI.
- **LoadingStateManager:** Provides in-app banners and progress indicators for async operations and errors.

## 🧪 Code Quality & Testing

- **SwiftLint:** Enforced code style and best practices
- **SwiftFormat:** Automatic code formatting
- **ShellCheck:** Bash script linting and best practices
- **YAML Linting:** yamllint for configuration and workflow files
- **Markdown Linting:** markdownlint for documentation quality
- **GitHub Actions Linting:** actionlint for workflow validation
- **Comprehensive Documentation:** All public APIs and services are documented
- **Self-Review:** All changes should be self-reviewed before submission
- **Zero Linter Errors:** All code must pass all linters before merging

### Example: Running All Checks

```bash
# Run all linters locally
./Scripts/lint-all.sh

# Or run individual linters
./Scripts/build.sh
shellcheck Scripts/*.sh
yamllint Config/project.yml .github/workflows/*.yml
markdownlint README.md Documentation/*.md .github/*.md
actionlint .github/workflows/*.yml
```

### CI/CD Pipeline Integration

The project includes a unified CI/CD automation pipeline through GitHub Actions that handles both continuous integration and releases:

#### Unified Pipeline Structure

**Single Workflow**: `.github/workflows/pipeline.yml` handles all automation:

- **Quality Checks**: Runs on every push and pull request
- **Build & Analysis**: Creates and analyzes both Debug and Release builds
- **Documentation Generation**: Auto-generates project documentation
- **Release Pipeline**: Automated release creation (triggered by version tags)

#### Automated Workflows

**Quality Checks (Every Push/PR)**

- ✅ SwiftLint code quality checks
- ✅ SwiftFormat code formatting validation
- ✅ ShellCheck bash script linting
- ✅ YAML and Markdown linting
- ✅ GitHub Actions workflow validation
- ✅ Project structure validation
- ✅ Comprehensive linting with `lint-all.sh`
- ✅ CLI build and testing

**Build & Analysis (After Quality Checks)**

- ✅ Xcode project generation with XcodeGen
- ✅ Debug and Release builds for GUI app
- ✅ CLI binary compilation and testing
- ✅ App structure analysis and size validation
- ✅ Build artifact uploads for debugging
- ✅ Documentation generation and upload

**Release Pipeline (Tag-triggered)**

- ✅ Version consistency validation (tag vs project.yml vs Info.plist)
- ✅ Changelog generation from git commits since last tag
- ✅ DMG installer creation with app icon
- ✅ CLI binary packaging with version naming
- ✅ Code signing for both applications
- ✅ GitHub Releases publication with comprehensive notes
- ✅ File size tracking and reporting
- ✅ Professional release notes with installation instructions

#### Pipeline Benefits

- ✅ **Efficiency**: Single workflow eliminates duplication and maintenance overhead
- ✅ **Consistency**: Same build environment for all releases
- ✅ **Quality**: Automated quality checks prevent regressions
- ✅ **Automation**: No manual release steps required
- ✅ **Transparency**: All build artifacts and logs are preserved
- ✅ **Reliability**: Comprehensive validation ensures release quality
- ✅ **Resource Optimization**: Eliminates redundant builds and setup steps

## 🧪 Testing

- **Manual Testing:**
  - Always test new features manually in the app UI.
- **CLI Testing:**
  - Test CLI commands: `./.build/arm64-apple-macosx/debug/odyssey-cli help`
  - Verify CLI builds with: `swift build --product odyssey-cli`
- **Linting:**
  - Run `./Scripts/build.sh` to check formatting and linting before every commit.
- **GitHub Actions:**
  - Test the workflow file: `.github/workflows/reservation-automation.yml`
  - Verify it works with real export tokens in a fork

## 🖥️ CLI Development

The CLI tool shares the same backend services as the GUI app, providing remote automation capabilities.

### CLI Architecture

- **Shared Services**: Uses the same `WebKitService`, `ConfigurationManager`, and other core services
- **Environment-Based**: Configured via environment variables for CI/CD integration
- **Token-Based**: Uses export tokens from the GUI for configuration
- **Headless Mode**: Runs without browser windows for server environments

### CLI Development Workflow

1. **Build CLI**: `swift build --product odyssey-cli`
2. **Test Commands**: `./.build/arm64-apple-macosx/debug/odyssey-cli help`
3. **Export Token**: Use GUI to generate export token for testing
4. **Test Automation**: `export ODYSSEY_EXPORT_TOKEN="<exported_token>" && ./odyssey-cli run`

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
