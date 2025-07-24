# 📋 Changelog

All notable changes to ODYSSEY will be documented in this file.

## [1.1.0] - 2025-07-23

### 🎉 Added

- **Complete Advanced Settings in God Mode**: All advanced settings are now only visible in God Mode
- **Browser Window Control**: New "Show browser window" setting in God Mode Advanced Settings
- **Conditional UI**: "Automatically close browser window on failure" only appears when browser window is enabled
- **Improved Captcha Bypass**: Browser window visibility now helps bypass captcha detection

### 🛠️ Changed

- **Default Behavior**: Browser window is now hidden by default (invisible automation)
- **God Mode Only**: All advanced settings are now only visible in God Mode for advanced debugging
- **UI Layout**: Advanced Settings section completely moved to God Mode with "(God Mode)" title
- **Setting Name**: Changed from "Do not show browser window" to "Show browser window" for clarity
- **Help Text**: Updated to explain captcha bypass benefits and default behavior
- **Default Values**: Optimized defaults for regular users (sleep prevention enabled, invisible automation)
- **User Documentation**: Cleaned up README.md to remove technical details from user-facing documentation

### 🐛 Fixed

- **Tray Icon Behavior**: Fixed premature tray icon unfilling during verification process
- **Timeout Issues**: Increased completion tracking timeout from 10 seconds to 5 minutes
- **Browser Window Logic**: Fixed multiple places where browser window was shown regardless of settings

---

> **How to read this changelog:**
>
> - 🎉 **Added**: New features
> - 🛠️ **Changed**: Updates or improvements
> - 🗑️ **Removed**: Features that were removed
> - 🐛 **Fixed**: Bug fixes
> - Each release follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
