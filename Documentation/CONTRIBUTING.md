# 🤝 Contributing to ODYSSEY

Thank you for your interest in contributing to ODYSSEY! This document provides guidelines and information for contributors.

---

## 📝 How to Check Logs

- Open **Console.app** (Applications > Utilities)
- Search for `ODYSSEY` or `com.odyssey.app`
- Look for emoji log messages for quick status identification
- Sensitive data is masked or marked as private

---

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

## ✨ How to Suggest Features

1. Go to [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
2. Click 'New Issue' and use the feature request template
3. Describe your idea, motivation, and possible solutions

---

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

---

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
    var headerView: some View { /* ... */ }
    var mainContentView: some View { /* ... */ }
    var footerView: some View { /* ... */ }
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

- **Separate concerns** with focused views
- **Use appropriate state management**

#### Example: View Structure

```swift
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

#### Example: State Management

```swift
struct ConfigurationDetailView: View {
    @StateObject private var configManager = ConfigurationManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    // ...
}
```

### Testing Guidelines

- **Unit Tests:**

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

- **UI Tests:**

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
        app.buttons["Add Configuration"].tap()
        let urlField = app.textFields["Facility URL"]
        urlField.tap()
        urlField.typeText("https://test.com")
        // ...
    }
}
```

---

## ✅ First PR Checklist

- [ ] My code follows the style guidelines
- [ ] I have self-reviewed my changes
- [ ] I have tested my changes (unit/UI/manual)
- [ ] I have updated documentation as needed
- [ ] My code passes all linting and formatting checks
- [ ] My PR includes a clear description and screenshots if applicable

---

## 🔄 Pull Request Process

1. **Self-review** your changes
2. **Ensure tests pass** locally
3. **Update documentation** for any new features
4. **Check for linting issues** (run `./Scripts/build.sh`)
5. **Test on different macOS versions** if possible
6. **Open a Pull Request** and fill out the PR template
7. **Address feedback** from reviewers
8. **Wait for maintainer approval and merge**

### PR Template Example

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing

- [ ] Unit tests pass
- [ ] UI tests pass
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

---

## 🧐 Review Process

- All PRs require at least one review from a maintainer
- Automated checks (lint, build, tests) must pass
- Reviewers may request changes or clarifications
- Be responsive and address feedback promptly
- PRs are merged after approval

---

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

---

## 📚 Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit/)
- [WebKit Documentation](https://developer.apple.com/documentation/webkit/)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) - Project generation
- [SwiftLint](https://github.com/realm/SwiftLint) - Code style enforcement
- [create-dmg](https://github.com/create-dmg/create-dmg) - DMG creation

---

## 🎯 Areas for Contribution

- **High Priority:** Bug fixes, performance improvements, error handling, testing
- **Medium Priority:** UI/UX improvements, documentation, accessibility, localization
- **Low Priority:** New features, integration with other systems, advanced scheduling

---

## 📞 Getting Help

- **GitHub Issues** - For bug reports and feature requests

---

## 📄 License

By contributing to ODYSSEY, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to ODYSSEY! 🚀**

---

## 🌟 New Contributor Onboarding

Welcome! If this is your first time contributing to ODYSSEY, here’s how to get started:

1. **Read the README and DEVELOPMENT.md** for project context.
2. **Fork the repository** and clone your fork locally.
3. **Set up your environment** (see DEVELOPMENT.md for details).
4. **Pick a good first issue** from [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).
5. **Create a feature branch**:
   ```bash
   git checkout -b my-first-contribution
   ```
6. **Make your changes** and commit with a clear message.
7. **Run all tests and linting**:
   ```bash
   ./Scripts/build.sh
   ```
8. **Push your branch** and open a Pull Request on GitHub.
9. **Fill out the PR template** and request a review.
10. **Respond to feedback** and iterate as needed.

**Tips:**

- Don’t hesitate to ask questions in your PR or on GitHub Issues! We’re here to help. 🙌
- Start small—documentation, typo fixes, or good first issues are great ways to learn the codebase.
- Be kind and respectful in all communications.

Happy coding and welcome to the ODYSSEY community! 🚀
