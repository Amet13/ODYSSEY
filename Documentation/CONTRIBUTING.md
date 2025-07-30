# 🤝 Contributing to ODYSSEY

Thank you for your interest in contributing to ODYSSEY! This document provides guidelines and information for contributors.

## 🎯 Project Overview

ODYSSEY is a **dual-interface application** for automating sports reservation bookings for Ottawa Recreation facilities:

- **🖥️ GUI Version**: Native macOS menu bar app with SwiftUI interface
- **💻 CLI Version**: Command-line interface for remote automation
- **🔧 Shared Core**: Both versions use the same WebKit automation engine

## 🚀 Quick Start for Contributors

### Prerequisites

- **macOS 15+** (for development)
- **Xcode 16+** with Command Line Tools
- **Homebrew** (for development dependencies)
- **Git** (for version control)

### Development Setup

1. **Clone the repository**:

   ```bash
   git clone https://github.com/Amet13/ODYSSEY.git
   cd ODYSSEY
   ```

2. **Run the development setup script**:

   ```bash
   ./Scripts/setup-dev.sh
   ```

3. **Build the project**:
   ```bash
   ./Scripts/build.sh
   ```

## 🏗️ Development Guidelines

### Code Style & Standards

- **Swift Style**: Follow official Swift style guide and SwiftLint rules
- **Documentation**: Use JSDoc-style comments for all public methods and classes
- **Error Handling**: Use structured logging with `os.log` and proper error propagation
- **Memory Management**: Use `[weak self]` capture lists and proper cleanup
- **Naming**: Use clear, descriptive names following Swift conventions

### Architecture Principles

- **Protocol-Oriented Design**: Clear interfaces defined in `Sources/Utils/Protocols.swift`
- **Separation of Concerns**: Each service has a single responsibility
- **Dependency Injection**: Use singletons for shared services
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

## 🧪 Testing & Quality Assurance

### Automated Quality Checks

The project includes comprehensive automated quality checks:

- ✅ SwiftLint code quality checks
- ✅ SwiftFormat code formatting validation
- ✅ ShellCheck bash script linting
- ✅ YAML and Markdown linting
- ✅ GitHub Actions workflow validation
- ✅ Project structure validation

### Running Quality Checks

```bash
# Run all quality checks
./Scripts/lint-all.sh

# Build and test
./Scripts/build.sh

# Monitor logs
./Scripts/logs.sh
```

### Testing Guidelines

- **Unit Tests**: Write tests for all new functionality
- **Integration Tests**: Test service interactions
- **UI Tests**: Test SwiftUI components and user flows
- **Automation Tests**: Test WebKit automation scenarios
- **Performance Tests**: Monitor memory usage and responsiveness

## 📝 Pull Request Process

### Before Submitting

1. **Ensure Quality**: All code must pass SwiftLint with zero errors
2. **Test Thoroughly**: Test on multiple macOS versions if possible
3. **Update Documentation**: Update relevant documentation for changes
4. **Follow Guidelines**: Adhere to code style and architecture principles

### Pull Request Template

```markdown
## 🎯 Description

Brief description of changes and motivation.

## 🔧 Changes Made

- [ ] Feature addition
- [ ] Bug fix
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement

## 🧪 Testing

- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Performance impact assessed

## 📚 Documentation

- [ ] README updated (if needed)
- [ ] Code comments added
- [ ] User guide updated (if needed)

## ✅ Checklist

- [ ] Code follows project style guidelines
- [ ] SwiftLint passes with zero errors
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] No breaking changes (or clearly documented)
```

## 🐛 Bug Reports

### Bug Report Template

```markdown
## 🐛 Bug Description

Clear and concise description of the bug.

## 🔄 Steps to Reproduce

1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## ✅ Expected Behavior

What you expected to happen.

## ❌ Actual Behavior

What actually happened.

## 📱 Environment

- macOS Version: [e.g., 15.0]
- ODYSSEY Version: [e.g., 1.0.0]
- Xcode Version: [e.g., 16.0]

## 📋 Additional Context

Any other context, logs, or screenshots.
```

## 💡 Feature Requests

### Feature Request Template

```markdown
## 💡 Feature Description

Clear and concise description of the feature request.

## 🎯 Problem Statement

What problem does this feature solve?

## 💭 Proposed Solution

Describe your proposed solution.

## 🔄 Alternative Solutions

Any alternative solutions you've considered.

## 📱 Use Cases

How would users benefit from this feature?

## 🎨 UI/UX Considerations

Any UI/UX considerations for the feature.
```

## 🏷️ Issue Labels

We use the following labels to categorize issues:

- **🐛 bug**: Something isn't working
- **💡 enhancement**: New feature or request
- **📚 documentation**: Improvements or additions to documentation
- **🏗️ architecture**: Code structure and design improvements
- **🧪 testing**: Adding or improving tests
- **🔧 maintenance**: Code maintenance and refactoring
- **🚀 performance**: Performance improvements
- **🛡️ security**: Security-related issues
- **🎨 ui/ux**: User interface and experience improvements

## 🤝 Community Guidelines

### Code of Conduct

- **Be Respectful**: Treat all contributors with respect
- **Be Constructive**: Provide constructive feedback
- **Be Inclusive**: Welcome contributors from all backgrounds
- **Be Patient**: Understand that contributors have different skill levels
- **Be Helpful**: Help others learn and grow

### Communication

- **GitHub Issues**: Use for bug reports and feature requests
- **Pull Requests**: Use for code contributions
- **Discussions**: Use for general questions and ideas
- **Documentation**: Keep documentation up to date

## 📚 Resources

### Development Resources

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Comprehensive development guide
- **[INSTALLATION.md](INSTALLATION.md)** - Installation instructions
- **[USER_GUIDE.md](USER_GUIDE.md)** - User documentation
- **[CLI.md](CLI.md)** - CLI documentation

### External Resources

- [Swift Style Guide](https://swift.org/documentation/api-design-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [WebKit Documentation](https://developer.apple.com/documentation/webkit/)
- [macOS Development](https://developer.apple.com/macos/)

## 🎉 Recognition

Contributors will be recognized in:

- **README.md** - Contributor list
- **CHANGELOG.md** - Contribution acknowledgments
- **GitHub Contributors** - GitHub's built-in contributor tracking

## 📄 License

By contributing to ODYSSEY, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to ODYSSEY! 🚀
