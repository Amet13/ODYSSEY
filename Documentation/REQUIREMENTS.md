# ODYSSEY Requirements

This document contains the centralized requirements for ODYSSEY that are referenced by all other documentation files.

## 🖥️ System Requirements

### 👥 For Users

- **macOS 15.0 or later**

### 👨‍💻 For Developers

- **macOS 15.0 or later**
- **Xcode 16.0 or later**
- **Swift 6.1 or later**
- **Homebrew** (for installing development dependencies)

## 📦 Development Dependencies

### 🛠️ Required Tools

- **XcodeGen** - For project generation
- **SwiftLint** - For code quality
- **SwiftFormat** - For code formatting
- **create-dmg** - For installer creation

### 🔧 Optional Tools

- **shellcheck** - For bash script linting
- **yamllint** - For YAML file linting
- **markdownlint** - For Markdown file linting
- **actionlint** - For GitHub Actions linting

## ⚙️ Installation Commands

### 👥 For Users

```bash
# Download from GitHub Releases
# No additional installation required - drag to Applications folder
```

### 👨‍💻 For Developers

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install development dependencies
brew install xcodegen swiftlint swiftformat create-dmg shellcheck yamllint markdownlint actionlint

# Setup development environment
./Scripts/setup-dev.sh
```

## 🔧 Troubleshooting

### ⚠️ Common Issues

- **"App is damaged" error**: Right-click and select "Open" instead of double-clicking
- **"macOS version too old"**: Update to macOS 15.0+
- **"Xcode version mismatch"**: Use Xcode 16+ (check with `xcodebuild -version`)
- **"Homebrew installation fails"**: Check internet connection and try again

### 🔧 Development Issues

- **Build failures**: Run `./Scripts/build.sh` to check for issues
- **Linting errors**: Run `./Scripts/lint-all.sh` to identify and fix issues
- **Dependency issues**: Run `brew update && brew upgrade` to update tools
