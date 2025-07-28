# ODYSSEY Development Guide

## 🎯 Overview

ODYSSEY is a **dual-interface application** with both GUI and CLI versions:

- **🖥️ GUI Version**: Native macOS menu bar app with SwiftUI interface
- **💻 CLI Version**: Command-line interface for remote automation

Both versions share the same backend services and automation engine.

## 🖥️ System Requirements

- macOS 15 or later
- Xcode 16 or later
- Homebrew (for installing dependencies)

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
- **Dependency Injection:** Use ServiceRegistry for dependency injection and singletons for shared services
- **Reactive Programming:** Use Combine for state management and async operations
- **Centralized Validation:** All input validation in `ValidationService`
- **Centralized Constants:** All constants in `AppConstants`
- **Error Recovery:** Graceful error handling and fallback strategies
- **Performance:** Optimized for memory usage and responsiveness
- **Security:** Local processing, secure credential storage, and privacy by design

## 🐞 Debugging & Troubleshooting

- **Browser Window:** Optional for development and support. By default, automation runs invisibly. All advanced settings (including browser window controls) are only available in God Mode. Enable "Show browser window" in God Mode Advanced Settings to monitor automation and diagnose issues.
- **Logs:** All logs use `os.log` with emoji indicators. Sensitive data is masked or marked as private.
- **Console.app:** View logs by searching for `ODYSSEY` or `com.odyssey.app`.
- **Error Handling:** All errors are logged with context and user-friendly messages are shown in the UI.
- **LoadingStateManager:** Provides in-app banners and progress indicators for async operations and errors.

## 🧪 Code Quality & Testing

- **SwiftLint:** Enforced code style and best practices
- **SwiftFormat:** Automatic code formatting
- **Comprehensive Documentation:** All public APIs and services are documented
- **Self-Review:** All changes should be self-reviewed before submission
- **Zero Linter Errors:** All code must pass SwiftLint and SwiftFormat before merging

### Example: Running All Checks

```bash
./Scripts/build.sh
# This will run SwiftFormat and SwiftLint automatically
```

## 🧪 Testing

- **Manual Testing:**
  - Always test new features manually in the app UI.
- **CLI Testing:**
  - Test CLI commands: `./.build/arm64-apple-macosx/debug/odyssey-cli help`
  - Verify CLI builds with: `swift build --product odyssey-cli`
- **Linting:**
  - Run `./Scripts/build.sh` to check formatting and linting before every commit.
- **GitHub Actions:**
  - Test the workflow file: `.github/workflows/odyssey-automation.yml`
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
- **Cron Jobs**: Run on servers for reliable automation
- **CI/CD**: Integrate with existing automation pipelines

## 🚀 Release Process

1. **Update version numbers** in `Info.plist`, `AppConstants.swift`, and documentation.
2. **Update the changelog** (`CHANGELOG.md`).
3. **Run all tests and linting** to ensure a clean build.
4. **Build the app and CLI:**
   ```bash
   ./Scripts/build.sh
   ```
5. **Create a DMG installer** (see `Scripts/create-release.sh`).
6. **Code sign** the app for distribution.
7. **(Optional) Notarize** the app with Apple (see `DEVELOPMENT.md` for steps).
8. **Publish the release** on GitHub with release notes and the DMG.

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
