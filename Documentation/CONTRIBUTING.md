# 🤝 Contributing to ODYSSEY

Thank you for your interest in contributing to ODYSSEY! This document provides guidelines and information for contributors.

## 🎯 Overview

ODYSSEY is a **dual-interface application**:

- **🖥️ GUI Version**: Native macOS menu bar app with SwiftUI interface
- **💻 CLI Version**: Command-line interface for remote automation

Both versions use the same powerful WebKit automation engine, ensuring consistent behavior and reliability.

## 🎯 Quick Start

1. **📋 Read the Documentation**: Start with [DEVELOPMENT.md](DEVELOPMENT.md) for development setup
2. **🔧 Setup Environment**: Run `./Scripts/setup-dev.sh setup`
3. **🏗️ Build Project**: Run `./Scripts/build.sh`
4. **📝 Choose an Issue**: Pick an issue from the [Issues](https://github.com/Amet13/ODYSSEY/issues) page
5. **🔀 Create Branch**: Create a feature branch for your work
6. **💻 Make Changes**: Follow the coding guidelines below
7. **🧪 Test Changes**: Ensure all tests pass and linting is clean
8. **📋 Submit PR**: Create a pull request with detailed description

## 🏷️ Issue Labels & Good First Issues

### 🟢 Good First Issues

These are perfect for new contributors:

- **🐞 Bug fixes**: Small, isolated bugs
- **📝 Documentation**: Improving docs and comments
- **🎨 UI polish**: Minor UI improvements
- **🔧 Configuration**: Adding new linting rules or build configurations
- **📊 Logging**: Improving log messages and formatting

### 🟡 Intermediate Issues

These require more experience:

- **✨ New features**: Adding new functionality
- **🔧 Architecture**: Improving code structure
- **⚡ Performance**: Optimizing existing code
- **🛡️ Security**: Security improvements
- **🧪 Testing**: Adding tests and test coverage

### 🔴 Advanced Issues

These are complex and require deep understanding:

- **🏗️ Core architecture**: Major architectural changes
- **🔄 Automation engine**: WebKit automation improvements
- **🔒 Security features**: Advanced security implementations
- **📱 Platform features**: macOS-specific features

## 📝 How to Check Logs

ODYSSEY uses comprehensive logging with emoji indicators:

```bash
# Monitor logs in real-time
./Scripts/logs.sh

# Or use Console.app
open -a Console
# Search for: com.odyssey.app
```

**Log Categories**:

- 🚀 Success messages
- ⚠️ Warning messages
- ❌ Error messages
- 🔍 Debug information
- ℹ️ General information

## 🐞 How to Report Bugs

1. **🔍 Check Existing Issues**: Search [Issues](https://github.com/Amet13/ODYSSEY/issues) first
2. **📝 Use Bug Template**: Use the bug report template
3. **📊 Include Logs**: Attach relevant logs from Console.app
4. **🖥️ System Info**: Include macOS version and ODYSSEY version
5. **📋 Steps to Reproduce**: Provide clear, step-by-step instructions

## ✨ How to Suggest Features

1. **💡 Check Roadmap**: See if it's already planned
2. **📝 Use Feature Template**: Use the feature request template
3. **🎯 Be Specific**: Describe the problem and proposed solution
4. **📊 Consider Impact**: Explain how it benefits users
5. **🔧 Consider Implementation**: Think about technical feasibility

## 🚀 Code Contributions

### 📋 Getting Started

1. **🔧 Setup Environment**:

   ```bash
   ./Scripts/setup-dev.sh setup
   ```

2. **🏗️ Build Project**:

   ```bash
   ./Scripts/build.sh
   ```

3. **🔀 Create Branch**:

   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **💻 Make Changes**: Follow coding guidelines below

5. **🧪 Test Changes**:

   ```bash
   ./Scripts/lint-all.sh
   ./Scripts/build.sh
   ```

6. **📋 Submit PR**: Create pull request with detailed description

### 💻 CLI Development

#### 🔧 CLI Architecture

The CLI uses the same backend services as the GUI:

- **🔄 Shared Services**: WebKitService, ConfigurationManager, etc.
- **📋 Environment Variables**: All configuration via environment
- **🛡️ Headless Mode**: Always runs without browser window
- **📊 Token-Based**: Uses export tokens from GUI for configuration

#### 🔧 CLI Development Workflow

1. **📋 Export Token**: Generate token from GUI app
2. **⚙️ Set Environment**: `export ODYSSEY_EXPORT_TOKEN="<token>"`
3. **🧪 Test Commands**: Test all CLI commands
4. **📊 Monitor Logs**: Use `./Scripts/logs.sh` for debugging

#### 📋 Supported CLI Commands

- `run` - Execute reservations
- `configs` - List configurations
- `settings` - Show user settings
- `help` - Show help
- `version` - Show version

#### 🔄 CLI Integration

- **🚀 GitHub Actions**: Automated reservation booking
- **🖥️ Remote Servers**: macOS server deployment
- **📊 CI/CD**: Integration with build pipelines

## 🧑‍💻 Coding Guidelines

### 📋 Swift Style Guide

Follow the official Swift style guide and project-specific rules:

#### 📝 Naming Conventions

```swift
// ✅ Good: Clear, descriptive names
let reservationConfiguration: ReservationConfig
let webKitService: WebKitServiceProtocol

// ✅ Good: Descriptive function names
func simulateHumanClick(in webView: WKWebView, selector: String)
func validateConfiguration(_ config: ReservationConfig) -> Bool

// ❌ Bad: Unclear names
let config: Config
let service: Service
func click()
func validate()
```

#### 🏗️ Architecture Principles

- **📋 Protocol-Oriented**: Use protocols for better testability
- **🔧 Dependency Injection**: Use ServiceRegistry for shared services
- **📊 Error Handling**: Use structured error types
- **🔒 Security**: Always use Keychain for sensitive data
- **📱 UI/UX**: Follow macOS Human Interface Guidelines

#### 🎨 Design Principles

- **📱 Native Feel**: Use native macOS UI patterns
- **🎨 Accessibility**: Support VoiceOver and accessibility features
- **🌙 Dark Mode**: Support both light and dark appearances
- **📊 Responsive**: Handle different window sizes gracefully

#### 🎨 Color Usage

```swift
// ✅ Use semantic colors that adapt to appearance
Text("Hello")
    .foregroundColor(.primary)

// ❌ Don't use hardcoded colors
Text("Hello")
    .foregroundColor(.black)
```

### 🔒 Security Guidelines

- **🔐 Credentials**: Always use Keychain for sensitive data
- **🛡️ Validation**: Validate all user inputs
- **📊 Logging**: Never log sensitive information
- **🔒 Network**: Use HTTPS for all network requests

```swift
// ✅ Good: Secure credential storage
KeychainService.shared.storeValue("password", forKey: "email")

// ❌ Bad: Plain text storage
UserDefaults.standard.set("password", forKey: "email")
```

### 📚 Documentation Standards

- **📝 Code Comments**: Use JSDoc-style comments for all public APIs
- **📋 README Updates**: Update documentation when adding features
- **📊 API Documentation**: Document all public interfaces
- **📝 Changelog**: Update CHANGELOG.md for all changes

```swift
/// Simulates human-like clicking behavior in a WebView
/// - Parameters:
///   - webView: The WebView to interact with
///   - selector: The CSS selector for the element to click
///   - description: Description for logging purposes
/// - Throws: WebKitError if the click operation fails
func simulateHumanClick(in webView: WKWebView, selector: String, description: String) async throws
```

### 📋 Before Submitting a PR

1. **🧪 Run Tests**: Ensure all tests pass
2. **📊 Run Linting**: `./Scripts/lint-all.sh`
3. **🏗️ Build Project**: `./Scripts/build.sh`
4. **📝 Update Docs**: Update relevant documentation
5. **📋 Check Logs**: Verify logging is consistent
6. **🎨 Test UI**: Test on both light and dark mode
7. **📱 Test Accessibility**: Test with VoiceOver

### 📋 PR Review Process

1. **📋 Automated Checks**: CI/CD pipeline runs automatically
2. **👀 Code Review**: Maintainers review the code
3. **🧪 Testing**: Verify functionality works as expected
4. **📊 Documentation**: Ensure docs are updated
5. **🎨 UI/UX**: Verify UI changes follow guidelines
6. **🔒 Security**: Check for security implications
7. **📋 Merge**: Merge after approval

## 🤝 Community Guidelines

### 💬 Communication

- **🤝 Be Respectful**: Treat everyone with respect
- **📝 Be Clear**: Use clear, concise language
- **🔍 Be Helpful**: Help others when you can
- **📊 Be Patient**: Understand that maintainers are volunteers

### 🆘 Getting Help

- **📋 Documentation**: Check [DEVELOPMENT.md](DEVELOPMENT.md) first
- **🐞 Issues**: Search existing issues for solutions
- **💬 Discussions**: Use GitHub Discussions for questions
- **📧 Contact**: Reach out to maintainers if needed

## 🛡️ Security Best Practices

- **🔐 Never commit secrets**: Use environment variables and secrets
- **🛡️ Validate inputs**: Always validate user inputs
- **📊 Secure logging**: Never log sensitive information
- **🔒 Use Keychain**: Always use Keychain for credentials
- **📱 Follow guidelines**: Follow Apple's security guidelines
