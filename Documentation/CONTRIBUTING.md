# Contributing to ODYSSEY

Thank you for your interest in contributing to ODYSSEY! This document provides guidelines and information for contributors.

---

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

---

## 🤝 How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Check existing issues** - Search for similar issues that may already exist
2. **Use the issue template** - Provide all requested information
3. **Be specific** - Include steps to reproduce, expected vs actual behavior
4. **Include system info** - macOS version, Xcode version, etc.

### Feature Requests

When suggesting new features:

1. **Describe the problem** - What issue does this solve?
2. **Propose a solution** - How should it work?
3. **Consider alternatives** - Are there other ways to solve this?
4. **Check existing features** - Is this already possible?

### Code Contributions

#### Getting Started

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes** following the coding guidelines
4. **Test thoroughly** - Ensure your changes work as expected
5. **Commit with clear messages** - Use conventional commit format
6. **Push to your branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

#### Development Setup

```bash
# Clone your fork
git clone https://github.com/Amet13/ODYSSEY.git
cd ODYSSEY

# Add upstream remote
git remote add upstream https://github.com/Amet13/ODYSSEY.git

# Install dependencies
brew install xcodegen

# Generate Xcode project
xcodegen

# Build and run
./build.sh
```

## 📋 Coding Guidelines

### Swift Style Guide

#### General Principles

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
    let url: String
    let sport: String
    var enabled: Bool
}
```

#### Code Organization

```swift
// ✅ Good: Use extensions for organization
struct ContentView: View {
    var body: some View {
        VStack {
            headerView
            mainContentView
            footerView
        }
    }
}

private extension ContentView {
    var headerView: some View {
        // Header implementation
    }

    var mainContentView: some View {
        // Main content implementation
    }

    var footerView: some View {
        // Footer implementation
    }
}
```

#### Error Handling

```swift
// ✅ Good: Use Result types and meaningful errors
enum ReservationError: LocalizedError {
    case networkError(String)
    case noSlotsAvailable
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .noSlotsAvailable:
            return "No available slots found"
        case .invalidConfiguration:
            return "Invalid configuration"
        }
    }
}

func bookReservation() async -> Result<Void, ReservationError> {
    // Implementation
}
```

### SwiftUI Guidelines

#### View Structure

```swift
// ✅ Good: Separate concerns with focused views
struct ConfigurationRowView: View {
    let config: ReservationConfig
    let onEdit: () -> Void

    var body: some View {
        HStack {
            configurationInfoView
            Spacer()
            actionButtonsView
        }
    }

    private var configurationInfoView: some View {
        VStack(alignment: .leading) {
            Text(config.name)
                .font(.headline)
            Text(config.sportName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
```

#### State Management

```swift
// ✅ Good: Use appropriate state management
struct ConfigurationDetailView: View {
    @StateObject private var configManager = ConfigurationManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // Implementation
}
```

### Testing Guidelines

#### Unit Tests

```swift
import XCTest
@testable import ODYSSEY

class ConfigurationManagerTests: XCTestCase {
    var manager: ConfigurationManager!

    override func setUp() {
        super.setUp()
        manager = ConfigurationManager.shared
        // Clear test data
        UserDefaults.standard.removeObject(forKey: "ODYSSEY_Settings")
    }

    func testAddConfiguration() {
        // Given
        let config = ReservationConfig(
            name: "Test Config",
            facilityURL: "https://test.com",
            sportName: "Basketball"
        )

        // When
        manager.addConfiguration(config)

        // Then
        XCTAssertEqual(manager.settings.configurations.count, 1)
        XCTAssertEqual(manager.settings.configurations.first?.name, "Test Config")
    }
}
```

#### UI Tests

```swift
import XCTest

class ODYSSEYUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }

    func testAddConfiguration() {
        // Test adding a new configuration
        app.buttons["Add Configuration"].tap()

        // Fill in form fields
        let urlField = app.textFields["Facility URL"]
        urlField.tap()
        urlField.typeText("https://test.com")

        // Continue with other form fields as needed
    }
}
```

## 🔄 Pull Request Process

### Before Submitting

1. **Self-review** your changes
2. **Ensure tests pass** locally
3. **Update documentation** for any new features
4. **Check for linting issues** (if SwiftLint is configured)
5. **Test on different macOS versions** if possible

### Pull Request Template

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing

- [ ] Unit tests pass
- [ ] UI tests pass (if applicable)
- [ ] Manual testing completed
- [ ] Tested on macOS [version]

## Checklist

- [ ] Code follows the style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings introduced
- [ ] No breaking changes (or breaking changes documented)

## Screenshots (if applicable)

Add screenshots for UI changes
```

### Review Process

1. **Automated checks** must pass
2. **Code review** by maintainers
3. **Address feedback** and iterate if needed
4. **Maintainer approval** required for merge

## 🐛 Bug Reports

### Issue Template

```markdown
## Bug Description

Clear and concise description of the bug

## Steps to Reproduce

1. Go to the settings page
2. Click on the configuration button
3. Scroll down to the form section
4. See error

## Expected Behavior

What you expected to happen

## Actual Behavior

What actually happened

## Environment

- macOS Version: [e.g., 12.0]
- ODYSSEY Version: [e.g., 1.0.0]
- Xcode Version: [e.g., 14.0]

## Additional Context

Add any other context, logs, or screenshots
```

## 📚 Resources

### Documentation

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit/)
- [WebKit Documentation](https://developer.apple.com/documentation/webkit/)

### Tools

- [XcodeGen](https://github.com/yonaskolb/XcodeGen) - Project generation
- [SwiftLint](https://github.com/realm/SwiftLint) - Code style enforcement
- [create-dmg](https://github.com/create-dmg/create-dmg) - DMG creation

## 🎯 Areas for Contribution

### High Priority

- **Bug fixes** - Any issues reported by users
- **Performance improvements** - Faster automation, better memory usage
- **Error handling** - More robust error recovery
- **Testing** - Additional unit and UI tests

### Medium Priority

- **UI/UX improvements** - Better user experience
- **Documentation** - Code comments, user guides
- **Accessibility** - VoiceOver support, keyboard navigation
- **Localization** - Support for additional languages

### Low Priority

- **New features** - Additional automation capabilities
- **Integration** - Support for other recreation systems
- **Advanced scheduling** - More complex scheduling options

## 📞 Getting Help

- **GitHub Issues** - For bug reports and feature requests

## 📄 License

By contributing to ODYSSEY, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to ODYSSEY! 🚀**
