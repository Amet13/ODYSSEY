# 📋 Changelog

All notable changes to ODYSSEY (macOS Menu Bar App + Command Line Interface) will be documented in this file.

> **How to read this changelog:**
>
> - 🎉 **Added**: New features
> - 🛠️ **Changed**: Updates or improvements
> - 🗑️ **Removed**: Features that were removed
> - 🐛 **Fixed**: Bug fixes
> - Each release follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.1.0] - 2025-01-27

### 🎉 Added

- **NEW**: Command-line interface (CLI) for remote automation
- **NEW**: Pre-built CLI binaries available in releases
- **NEW**: CLI release pipeline with automated builds
- **NEW**: CLI archive creation with README and documentation
- **NEW**: GitHub Actions workflow using pre-built CLI binaries
- **NEW**: CLI code signing and verification
- **NEW**: Comprehensive CLI documentation and examples
- **NEW**: CLI export token system for secure configuration sharing
- **NEW**: Parallel reservation execution in CLI mode
- **NEW**: Headless mode for CLI automation (no browser window)
- **NEW**: CLI-specific error handling and logging
- **NEW**: CLI release script for standalone CLI builds
- **NEW**: Updated GitHub Actions workflow with proper CLI integration
- **NEW**: Step-by-step instructions for forking repo and adding secrets

### 🛠️ Changed

- Updated release pipeline to build and package CLI binaries
- Enhanced documentation to reflect CLI tool capabilities
- Improved GitHub Actions workflow to use pre-built CLI
- Updated CLI documentation with installation and usage examples
- Streamlined CLI export process for easier CI/CD integration
- Enhanced CLI error messages and user guidance
- Renamed and updated GitHub Actions workflow file for better organization
- Added comprehensive instructions for GitHub Actions setup
- **Updated minimum version requirements**: macOS 15 and Xcode 16 (major versions only, Swift 6.1)

### 🗑️ Removed

- **Outdated files**: Removed `Scripts/debug.sh` (contained hardcoded test token)
- **Legacy workflow**: Removed `.github/workflows/odyssey-legacy.yml` (superseded by modern workflow)
- **Redundant script**: Removed `Scripts/create-cli-release.sh` (functionality covered by main release workflow)

### 🐛 Fixed

- CLI build process now uses release configuration
- CLI code signing for better macOS compatibility
- CLI archive structure with proper documentation
- CLI version display and help system

---

## [1.0.0] - 2025-08-01

### 🎉 Added

- First public release of ODYSSEY: Ottawa Drop-in Your Sports & Schedule Easily Yourself
- Native macOS menu bar app for automated sports reservation bookings
- Modern SwiftUI interface and configuration management
- WebKit-based automation (no Chrome/Chromedriver required)
- Email/IMAP integration for verification
- Secure credential storage with Keychain
- Comprehensive logging with emoji-based categories
- Protocol-oriented architecture and dependency injection
- Extensive validation and error handling
- Multi-configuration and scheduling support
- Human-like anti-detection for web automation
- Browser window for live automation monitoring
- User-friendly onboarding and configuration flows
- In-app and Console log guidance for troubleshooting
- Full documentation for users and developers

### 🛠️ Changed

- Final UI/UX polish for onboarding, settings, and configuration views
- Improved documentation structure for both users and developers
- All logs now use emojis and proper punctuation
- Save button in Add Configuration is disabled until all fields are valid
- Facility URL validation and user guidance improved

### 🗑️ Removed

- All test targets and test files for a clean release
- All debug-only logs and useless comments
- All banners and overlays for reservation state (UI is now minimal)

### 🐛 Fixed

- Consistent versioning across Info.plist, manifests, and About page
- "Last run status" now updates correctly for manual and auto runs
- Settings and About views margins and button alignment
- Keychain credential handling for email testing
- Multiple Xcode project/test target build errors

---
