# 🤝 Contributing to ODYSSEY

Thank you for your interest in contributing to ODYSSEY! This document provides guidelines and information for contributors.

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

## ✅ First PR Checklist

- [ ] My code follows the style guidelines
- [ ] I have self-reviewed my changes
- [ ] I have tested my changes (UI)
- [ ] I have updated documentation as needed
- [ ] My code passes all linting and formatting checks
- [ ] My PR includes a clear description and screenshots if applicable

## 🔄 Pull Request Process

1. **Self-review** your changes
2. **Ensure app builds** locally
3. **Update documentation** for any new features
4. **Check for linting issues** (run `./Scripts/build.sh`)
5. **Test on different macOS versions** if possible
6. **Open a Pull Request** and fill out the PR template
7. **Address feedback** from reviewers
8. **Wait for maintainer approval and merge**

## 🧐 Review Process

- All PRs require at least one review from a maintainer
- Automated checks (lint, build) must pass
- Reviewers may request changes or clarifications
- Be responsive and address feedback promptly
- PRs are merged after approval

## 📚 Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit/)
- [WebKit Documentation](https://developer.apple.com/documentation/webkit/)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) - Project generation
- [SwiftLint](https://github.com/realm/SwiftLint) - Code style enforcement
- [create-dmg](https://github.com/create-dmg/create-dmg) - DMG creation

## 🎯 Areas for Contribution

- **High Priority:** Bug fixes, performance improvements, error handling, testing
- **Medium Priority:** UI/UX improvements, documentation, accessibility, localization
- **Low Priority:** New features, integration with other systems, advanced scheduling

## 📞 Getting Help

- **GitHub Issues** - For bug reports and feature requests

## 📄 License

By contributing to ODYSSEY, you agree that your contributions will be licensed under the MIT License.

**Thank you for contributing to ODYSSEY! 🚀**
