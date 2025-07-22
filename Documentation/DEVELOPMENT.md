# ODYSSEY Development Guide

**Ottawa Drop-in Your Sports & Schedule Easily Yourself**

---

## 🖥️ System Requirements

- macOS 15.0 or later
- Xcode 16.0 or later
- Node.js and npm (for JavaScript linting)
- Homebrew (for installing dependencies)

---

## 🚀 Quick Start

1. Clone the repository
2. Install dependencies: `brew install xcodegen swiftlint` and `npm install`
3. Generate Xcode project: `xcodegen`
4. Build and run: `./Scripts/build.sh`
5. (Optional) Open in Xcode: `open Config/ODYSSEY.xcodeproj`
6. Run code quality checks: `swiftlint lint` and `npm run lint`

---

## 🏗️ Architecture Principles

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

- **Debug Window**: Essential for development and support. Use it to monitor automation and diagnose issues.
- **Logs**: All logs use `os.log` with emoji indicators. Sensitive data is masked or marked as private.
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

## 📦 Related Documentation

- [Changelog](CHANGELOG.md) - Release notes
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute

---

For user installation and setup, see the main [README.md](../README.md).

---

## 🛡️ Security & Compliance

- **Credential Storage:** All sensitive credentials (e.g., email passwords) are securely stored in the macOS Keychain using Keychain Services. No credentials are ever stored in UserDefaults or plain text files.
- **Network Security:** All network requests use HTTPS. App Transport Security (ATS) is strictly enforced; there are no exceptions for ottawa.ca or any other domains.
- **Code Signing & Notarization:** The app is code signed for distribution, but is **not notarized by Apple** (no Apple Developer account). To enable notarization, see the commented steps in `Scripts/create-release.sh` and provide the required credentials.
- **Dependency Policy:** All runtime dependencies are native Swift/Apple frameworks. JavaScript development dependencies (e.g., ESLint) are MIT or similarly permissive. No third-party runtime code is included.
- **Input Validation:** All user input is validated and sanitized through the centralized `ValidationService`.
- **Data Privacy:** No user data is transmitted externally without explicit user consent. All automation runs locally on the user's machine.
- **Periodic Audits:** It is recommended to periodically audit all dependencies and review security practices as part of ongoing maintenance.
