# 🚀 ODYSSEY Development Guide

## 📋 Overview

This guide covers development setup, building, testing, and deployment for the ODYSSEY project.

## 🛠️ Development Setup

### Prerequisites

- **macOS 15 or later**
- **Xcode 16+** (for development)
- **Homebrew** (for dependencies)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/Amet13/ODYSSEY.git
cd ODYSSEY

# Setup development environment
./Scripts/odyssey.sh setup

# Build the application
./Scripts/odyssey.sh build

# Run tests
./Scripts/odyssey.sh test
```

## 🔧 Development Commands

### Single Master Script

All development operations are now consolidated into a single script:

```bash
# Setup development environment
./Scripts/odyssey.sh setup

# Build application and CLI
./Scripts/odyssey.sh build

# Run comprehensive linting
./Scripts/odyssey.sh lint

# Run tests and validation
./Scripts/odyssey.sh test

# Clean build artifacts
./Scripts/odyssey.sh clean

# Show application logs
./Scripts/odyssey.sh logs
```

### Options

```bash
# Dry run (show what would be executed)
./Scripts/odyssey.sh build --dry-run

# Verbose output
./Scripts/odyssey.sh build --verbose

# Show help
./Scripts/odyssey.sh --help
```

## 🏗️ Build Process

### Manual Build

```bash
# Full build process
./Scripts/odyssey.sh build
```

This includes:

1. **Prerequisites Check**: Verify Xcode, Swift, and dependencies
2. **Project Generation**: Generate Xcode project from `project.yml`
3. **Code Quality**: Run SwiftFormat and SwiftLint
4. **Application Build**: Build the macOS app
5. **CLI Build**: Build the command-line tool
6. **Code Signing**: Sign the CLI tool
7. **Launch**: Launch the application

### Build Artifacts

- **Application**: `Config/ODYSSEY.xcodeproj` (generated)
- **App Bundle**: `DerivedData/ODYSSEY-*/Build/Products/Debug/ODYSSEY.app`
- **CLI Tool**: `.build/arm64-apple-macosx/debug/odyssey-cli`

## 🧪 Testing

### Test Commands

```bash
# Run all tests (lint + build)
./Scripts/odyssey.sh test

# Run linting only
./Scripts/odyssey.sh lint

# Run build only
./Scripts/odyssey.sh build
```

### Code Quality

- **SwiftFormat**: Automatic code formatting
- **SwiftLint**: Code style and quality checks
- **Build Validation**: Ensures code compiles correctly

## 🚀 CI/CD Pipeline

### Local CI/CD

```bash
# Run CI pipeline (setup, lint, build)
./Scripts/odyssey.sh ci

# Run full release pipeline
./Scripts/odyssey.sh release

# Deploy and create release artifacts
./Scripts/odyssey.sh deploy

# Code sign applications
./Scripts/odyssey.sh sign

# Generate changelog
./Scripts/odyssey.sh changelog
```

### GitHub Actions

The project uses GitHub Actions for automated CI/CD:

- **CI Pipeline**: Runs on PRs and main branch pushes
- **Release Pipeline**: Runs on version tags
- **Scheduled Reservations**: Runs daily for automated bookings

## 🏗️ Architecture

### Simplified Service Architecture

The project uses a simplified architecture with direct singleton access:

#### Core Services

1. **ConfigurationManager**: Settings and data persistence (singleton)
2. **ReservationOrchestrator**: Web automation orchestration
3. **WebKitService**: Native web automation engine (singleton)
4. **FacilityService**: Web scraping and facility data management
5. **EmailService**: IMAP integration and email testing
6. **UserSettingsManager**: User configuration and settings management
7. **ValidationService**: Centralized validation logic (singleton)
8. **CentralizedLoggingService**: Unified logging service (singleton)

#### Key Principles

- **Direct Singleton Access**: No complex dependency injection
- **Unified Error Handling**: Single `UnifiedError` enum
- **Centralized Logging**: Consistent logging across all components
- **Simplified Architecture**: Easy to understand and maintain

## 🔧 Development Guidelines

### Code Style & Standards

- **Swift Style**: Follow official Swift style guide and SwiftLint rules
- **Documentation**: Use JSDoc-style comments for all public methods and classes
- **Error Handling**: Use unified error handling with `UnifiedError` and proper error propagation
- **Memory Management**: Use `[weak self]` capture lists and proper cleanup
- **Naming**: Use clear, descriptive names following Swift conventions
- **Logging**: Use centralized logging with consistent emojis and punctuation

### Architecture Principles

- **Simplified Architecture**: Direct singleton access for shared services
- **Separation of Concerns**: Each service has a single responsibility
- **Unified Error Handling**: Single `UnifiedError` enum for all error types
- **Centralized Logging**: `CentralizedLoggingService` for consistent logging
- **Reactive Programming**: Use Combine for state management and async operations
- **Error Recovery**: Implement graceful error handling throughout
- **Performance**: Optimize for memory usage and responsiveness
- **Validation**: Centralized validation in `ValidationService`
- **Constants**: Centralized constants in `AppConstants`

### Security & Privacy

- **Local Processing**: All automation runs locally on user's machine
- **User Consent**: Require explicit permission for all external integrations
- **Data Privacy**: No user data transmitted without consent
- **Secure Connections**: Use HTTPS and App Transport Security
- **Input Validation**: Validate and sanitize all user inputs

### WebKit Integration

- **Native Approach**: Uses WKWebView for web automation
- **No External Dependencies**: No ChromeDriver, no Chrome, no non-native browsers required
- **Better Performance**: Native macOS integration
- **Smaller Footprint**: No additional browser dependencies
- **No Permission Issues**: Standard app sandbox permissions only

### CLI Development Guidelines

- **Shared Services**: CLI uses the same backend services as the GUI
- **Environment Variables**: All CLI configuration should be environment-based
- **Error Handling**: Provide clear error messages for CLI users
- **Documentation**: Update CLI documentation when adding new commands
- **Testing**: Test CLI commands with real export tokens
- **Headless Mode**: CLI always runs without browser windows
- **Token-Based**: Uses export tokens from GUI for configuration

### Error Handling

- **WebKit Management**: Handle WebKit crashes and timeouts gracefully
- **Network Issues**: Implement retry logic for network failures
- **Process Management**: Handle WebKit startup/shutdown gracefully
- **Fallback Strategies**: Provide clear error messages for automation failures

## 🔧 Development Workflow

### Git Commit Guidelines

- **Do NOT commit code with git until explicitly told to do so**
- Always wait for explicit permission before committing changes
- Use descriptive commit messages when committing
- Test thoroughly before requesting commit permission

### Build Process

- **Always rebuild app using `./Scripts/odyssey.sh build` after changing or fixing code**
- The build process includes: `swiftlint`, `swiftformat`
- Never skip the build step after making changes
- Verify the app launches successfully after each build
- Check for any build warnings or errors

### Documentation Standards

- **Always update documentation if something changes**
- Keep README.md and other docs in sync with code changes
- Update any relevant documentation when adding new features
- Maintain accurate and current documentation

### Code Quality

- **All code must pass SwiftLint with zero errors and minimal warnings before pushing or releasing**
- All linter violations must be fixed or explicitly justified in code review
- Do not push or release code with unresolved SwiftLint errors
- Keep the repository clean by removing duplicate information
- **Protocol-Oriented Design**: Use protocols for better testability and maintainability
- **Extensions**: Use Swift extensions for code organization and reusability
- **Validation**: Use centralized validation for consistency
- **Constants**: Use centralized constants for maintainability

### User Experience

- **Loading States**: Always show loading indicators for async operations
- **Progress Indicators**: Display progress for long-running operations
- **Feedback**: Provide immediate visual feedback for user actions
- **Error States**: Show clear error messages with actionable guidance
- **Success States**: Confirm successful operations with appropriate feedback

### Loading States Implementation

- **SwiftUI Progress Views**: Use `ProgressView` for indeterminate loading
- **Progress Bars**: Implement `ProgressView(progress:)` for determinate operations
- **Loading Overlays**: Show loading states over content during operations
- **Skeleton Screens**: Use placeholder content during data loading
- **Status Updates**: Provide real-time status updates for long operations

### Progress Indicators

- **Reservation Progress**: Show step-by-step progress for reservation automation
- **File Operations**: Display progress for configuration saves/loads
- **Network Operations**: Show progress for web requests and automation
- **Background Tasks**: Indicate progress for scheduled operations
- **Error Recovery**: Show progress during error recovery operations

### Security & Code Signing

- **App Sandbox**: Enable App Sandbox for enhanced security
- **Code Signing**: Implement proper code signing with Developer ID
- **Notarization**: App is **code signed but not notarized by Apple** (see README and DEVELOPMENT.md)
- **Secure Credential Storage**: Use Keychain Services for sensitive data
- **Input Validation**: Validate and sanitize all user inputs
- **Network Security**: Use HTTPS and certificate pinning where appropriate

### Logging Standards

- **Emoji Usage:** **ALWAYS use emojis in log messages** for better readability and quick visual identification
- **Consistent Format:** All log messages must follow the pattern: `logger.level("emoji message.")`
- **Punctuation:** Always end log messages with periods (.) for completed statements
- **Privacy:** Use `privacy: .private` for sensitive data in logs

### Debugging

- **Logging:** Use `os.log` with appropriate categories and emojis
- **Console:** Check Console app for detailed logs
- **WebKit:** Test automation manually with WebKit debugging
- **Network:** Monitor network requests and responses

## 📚 Documentation Standards

- **Code Comments:** Use JSDoc-style comments for all public APIs
- **README Files:** Maintain comprehensive documentation in each directory
- **Changelog:** Document all changes in `CHANGELOG.md`
- **User Guides:** Provide clear installation and usage instructions
- **API Documentation:** Document all public interfaces and methods

## 🚀 Release Process

### Version Management

- **Semantic Versioning:** Follow MAJOR.MINOR.PATCH format
- **Changelog:** Update `CHANGELOG.md` with all changes
- **Version Numbers:** Update all version references consistently
- **Build Numbers:** Increment build number for each release

### Security Implementation

- **App Sandbox Configuration:**

  - Enable in `Info.plist` with appropriate entitlements
  - Configure network access for web automation
  - Set file system permissions for configuration storage
  - Enable user interaction for window management

- **Code Signing Setup:**

  - Sign all binaries and frameworks
  - Implement proper provisioning profiles
  - Test signed builds thoroughly

- **Secure Credential Storage:**
  - Use Keychain Services for email credentials
  - Implement secure credential retrieval
  - Handle credential updates securely
  - Provide user-friendly credential management

### Quality Assurance

- **Code Review:** Self-review all changes before submission
- **Testing:** Test on multiple macOS versions
- **Performance:** Monitor app size and memory usage
- **Security:** Validate all security settings and permissions

### Distribution

- **DMG Creation:** Use `create-dmg` for installer creation
- **Code Signing:** Sign with Developer ID for distribution
- **GitHub Releases:** Create releases with proper documentation

## 🤝 Collaboration Guidelines

- **Pull Requests:** Use descriptive titles and detailed descriptions
- **Code Review:** Review for functionality, style, and security
- **Testing:** Ensure all changes are properly tested
- **Documentation:** Update documentation for all changes
- **Communication:** Use GitHub Issues for collaboration

## 🛡️ Ethical Automation

- **Rate Limiting:** Implement appropriate delays and rate limits
- **User Consent:** Require explicit permission for automation
- **Community Benefit:** Focus on positive community impact
- **Transparency:** Be clear about automation capabilities and limitations
