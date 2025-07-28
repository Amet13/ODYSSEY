# 🤝 Contributing to ODYSSEY

Thank you for your interest in contributing to ODYSSEY! This document provides guidelines and information for contributors.

## 🎯 Overview

ODYSSEY is a **dual-interface application** with both GUI and CLI versions:

- **🖥️ GUI Version**: Native macOS menu bar app with SwiftUI interface
- **💻 CLI Version**: Command-line interface for remote automation

Both versions share the same backend services and automation engine, so contributions can affect both interfaces.

## 🎯 Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a feature branch**: `git checkout -b feature/amazing-feature`
4. **Make your changes** following our guidelines
5. **Test thoroughly** - ensure everything works
6. **Commit with clear messages**
7. **Push to your branch** and open a Pull Request

## 🏷️ Issue Labels & Good First Issues

We use the following labels to help contributors find suitable tasks:

### 🟢 Good First Issues

- `good first issue` - Perfect for new contributors
- `documentation` - Documentation improvements
- `ui/ux` - User interface improvements (including dark mode polish)
- `fun/polish` - Add or improve UI delight, animations, or polish

### 🟡 Intermediate Issues

- `enhancement` - New features or improvements
- `bug` - Bug fixes
- `performance` - Performance optimizations
- `refactoring` - Code improvements

### 🔴 Advanced Issues

- `architecture` - Major architectural changes
- `security` - Security-related improvements
- `automation` - Web automation enhancements
- `integration` - Third-party integrations
- `cli` - Command-line interface improvements

## 📝 How to Check Logs

- Open **Console.app** (Applications > Utilities)
- Search for `ODYSSEY` or `com.odyssey.app`
- Look for emoji log messages for quick status identification
- Sensitive data is masked or marked as private

## 🐞 How to Report Bugs

1. Go to [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
2. Click 'New Issue' and use the bug report template
3. Include:
   - Steps to reproduce
   - Expected vs actual behavior
   - macOS version, ODYSSEY version, Xcode version
   - Relevant logs (from Console.app)
   - Screenshots if possible

## ✨ How to Suggest Features

1. Go to [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
2. Click 'New Issue' and use the feature request template
3. Describe your idea, motivation, and possible solutions

## 🚀 Code Contributions

### Getting Started

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes** following the coding guidelines
4. **Test thoroughly** - Ensure your changes work as expected
5. **Commit with clear messages**
6. **Push to your branch**
   ```bash
   git push origin feature/amazing-feature
   ```
7. **Open a Pull Request** on GitHub

## 🖥️ CLI Development

The CLI tool is an integral part of ODYSSEY, providing remote automation capabilities.

### CLI Contribution Guidelines

- **Shared Services**: CLI uses the same backend services as the GUI
- **Environment Variables**: All configuration should be environment-based
- **Error Handling**: Provide clear error messages for CLI users
- **Documentation**: Update CLI documentation when adding new commands
- **Testing**: Test CLI commands with real export tokens

### CLI Development Workflow

1. **Build CLI**: `swift build --product odyssey-cli`
2. **Test Commands**: `./.build/arm64-apple-macosx/debug/odyssey-cli help`
3. **Export Token**: Generate token from GUI for testing
4. **Test Automation**: `export ODYSSEY_EXPORT_TOKEN="<exported_token>" && ./odyssey-cli run`
5. **Test GitHub Actions**: Verify `.github/workflows/odyssey-automation.yml` works correctly

### Supported CLI Commands

- `run [--now] [--prior <days>]` - Run reservations (with optional immediate execution and prior days)
- `configs` - List all configurations from export token
- `settings [--unmask]` - Show user settings (with optional unmasking)
- `help` - Show CLI help and usage
- `version` - Show CLI version information

## 🧑‍💻 Coding Guidelines

### Swift Style Guide

- **Readability over brevity** - Code should be self-documenting
- **Consistency** - Follow existing patterns in the codebase
- **Safety** - Use Swift's type system and safety features
- **Performance** - Consider performance implications

#### Naming Conventions

```swift
// ✅ Good: Clear, descriptive names
struct ReservationConfiguration {
    let facilityURL: URL
    let sportName: String
    var isEnabled: Bool
}

// ✅ Good: Descriptive function names
func calculateNextAutorunTime() -> Date? {
    // Implementation
}

// ❌ Bad: Unclear names
struct Config {
    let url: URL
    let sport: String
    var enabled: Bool
}
```

### Architecture Principles

- **Protocol-Oriented Design** - Use protocols for interfaces
- **Separation of Concerns** - Each component has a single responsibility
- **Dependency Injection** - Use ServiceRegistry for dependency injection and singletons for shared services
- **Reactive Programming** - Use Combine for state management
- **Error Handling** - Use structured error handling throughout

## 🎨 UI/UX Guidelines

### Design Principles

- **Native macOS Feel** - Follow macOS design guidelines
- **Accessibility** - Ensure VoiceOver and keyboard navigation work
- **Dark Mode** - Support both light and dark appearances
- **Responsive** - Handle different window sizes gracefully

### Color Usage

```swift
// ✅ Use semantic colors that adapt to appearance
Color.odysseyPrimary
Color.odysseyBackground
Color.odysseyText

// ❌ Don't use hardcoded colors
Color.blue
Color.white
Color.black
```

## 🔒 Security Guidelines

### Data Privacy

- **Local Processing** - All automation runs locally
- **Secure Storage** - Use Keychain for sensitive data
- **Input Validation** - Validate and sanitize all inputs
- **Logging Privacy** - Mask sensitive data in logs

### Code Security

```swift
// ✅ Good: Secure credential storage
KeychainService.shared.storeCredentials(email: email, password: password)

// ❌ Bad: Plain text storage
UserDefaults.standard.set(password, forKey: "password")
```

## 📚 Documentation Standards

### Code Comments

- **JSDoc Style** - Use JSDoc-style comments for public APIs
- **Usage Examples** - Include usage examples in documentation
- **Parameter Documentation** - Document all parameters and return values
- **Error Documentation** - Document possible errors and exceptions

### README Updates

- **Feature Documentation** - Document new features in README
- **Installation Instructions** - Keep installation steps current
- **Usage Examples** - Provide clear usage examples
- **Troubleshooting** - Add common issues and solutions

## 🚀 Release Process

### Before Submitting a PR

1. **Run the build script**

   ```bash
   ./Scripts/build.sh
   ```

2. **Fix all linting errors**

   ```bash
   swiftlint lint
   ```

3. **Test thoroughly**

   - Test on different macOS versions
   - Test with different configurations
   - Test error scenarios

4. **Update documentation**
   - Update README if needed
   - Update CHANGELOG.md
   - Update inline documentation

### PR Review Process

1. **Self-Review** - Review your own changes first
2. **Code Review** - Address reviewer feedback
3. **Testing** - Ensure all tests pass
4. **Documentation** - Update documentation as needed
5. **Merge** - Merge after approval

## 🤝 Community Guidelines

### Communication

- **Be Respectful** - Treat everyone with respect
- **Be Helpful** - Help other contributors
- **Be Patient** - Understand that everyone is learning
- **Be Constructive** - Provide constructive feedback

### Getting Help

- **GitHub Issues** - For bugs and feature requests
- **Documentation** - Check existing documentation first
- **Code Examples** - Look at existing code for patterns

## 🛡️ Security Best Practices

- 🔒 **Credentials:** Always use the macOS Keychain for sensitive data.
- 🌐 **Network:** All requests must use HTTPS. No exceptions.
- 📝 **Code Signing:** All builds for distribution must be code signed.
- 🔍 **Input Validation:** Validate and sanitize all user inputs.
- 📊 **Logging:** Use `privacy: .private` for sensitive data in logs.

## 🙌 Need Help?

- Open an issue on [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
- See the [README](../README.md) for user-facing instructions
- For advanced troubleshooting, check the logs in Console.app and enable "Show browser window" in God Mode Advanced Settings to monitor automation

---

Thank you for contributing to ODYSSEY! 🚀
