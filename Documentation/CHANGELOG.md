# Changelog

All notable changes to ODYSSEY will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.0] - 2025-01-27

### Added

- **Enhanced Notification System**: Comprehensive macOS system notifications for reservation success and failure
- **Permission Management**: Automatic notification permission requests with proper error handling
- **Async Notification Handling**: Improved notification delivery using async/await for better performance
- **Notification Documentation**: Complete setup and troubleshooting guide for notifications

### Changed

- **Notification Implementation**: Replaced callback-based notifications with modern async/await approach
- **Permission Checking**: Added `checkNotificationAuthorization()` method to verify permissions before sending
- **Error Handling**: Graceful fallback when notification permissions are denied
- **Documentation**: Updated README and DEVELOPMENT.md with comprehensive notification instructions

### Fixed

- **Notification Reliability**: Fixed issues where notifications weren't being sent due to permission problems
- **Error Messages**: Improved notification error logging and debugging information
- **Permission Requests**: Better handling of notification permission requests and user responses

### Technical Improvements

- **Code Quality**: Improved notification system with proper async/await patterns
- **User Experience**: Clear notification content with emojis and concise error messages
- **Debugging**: Enhanced logging for notification permission status and send attempts
- **Documentation**: Comprehensive guides for enabling and troubleshooting notifications

---

## [3.1.0] - 2025-01-27

### Added

- **Persistent Status Tracking**: Last run status, date, and run type are now persisted across app restarts
- **Unified Status Format**: Standardized "Last run: success|fail|never (manual|auto) <date>" format for all configurations
- **Enhanced Telegram Messages**: Bold success messages and cleaner formatting without redundant timestamps

### Changed

- **Status Display**: Consistent grey color for never-run configurations and unified status format
- **Error Message Localization**: All automation error messages are now properly localized

### Fixed

- **Status Persistence**: Last run information is now saved to UserDefaults and restored on app launch
- **Status Format**: All configurations show status even if never run, with consistent formatting
- **Build Warnings**: Fixed unused variable warnings and Codable conformance issues

---

## [3.0.0] - 2025-07-11

### Added

- **Robust ChromeDriver Automation**: Reliable sport button clicking with Python Selenium approach and fallback logic
- **Anti-Detection**: Random user agents, language, mouse movement, and delays to avoid bot detection
- **Detailed Notifications**: Telegram/email notifications now include facility, people, and schedule info
- **Color-Coded Status**: Last run status and date are color-coded (green/red/orange) for instant feedback
- **Manual/Auto Run Tracking**: Status and logs now show if a run was manual or scheduled (auto)

### Changed

- **Production-Ready Cleanup**: All debug and trash code removed for a clean, fast, and stable release
- **UI Polish**: Status and notification formatting improved for clarity and professionalism
- **Documentation**: Updated README and changelog for 3.0.0

### Fixed

- **Button Clicking Reliability**: Fallback logic ensures sport button is always clicked, even if DOM changes
- **Notification Content**: Telegram and email notifications now always include all relevant booking details
- **Status Display**: Status and date are always color-coded and show run type inline

---

## [2.2.0] - 2025-01-27

### Added

- **Enhanced Documentation**: Comprehensive project review and cleanup
- **Version Management**: Standardized version numbers across all files
- **Code Quality**: Improved error handling and logging consistency
- **UI Polish**: Better visual feedback and consistent styling

### Changed

- **Version Update**: Bumped to version 2.2.0 with build number 8
- **Documentation**: Updated README with new features and improvements
- **Constants**: Streamlined sports keywords for better performance
- **Project Configuration**: Updated XcodeGen project settings

### Fixed

- **Version Inconsistencies**: All version references now consistent across project
- **Documentation References**: Removed references to deleted BrowserService
- **Build Warnings**: Addressed SwiftFormat warnings and improved build process
- **Code Cleanup**: Removed unused constants and improved code organization

### Technical Improvements

- **Build Process**: Enhanced build script with better error handling
- **Code Organization**: Improved file structure and naming conventions
- **Performance**: Optimized constants and reduced memory usage
- **Maintainability**: Better separation of concerns and documentation

## [2.1.0] - 2025-07-11

### Changed

- Major code cleanup: removed all non-critical logger.info and logger.log calls for a clean production build
- Improved settings UI: consistent dividers, margins, and section separation
- IMAP and Telegram integration test results now have consistent styling and feedback
- Fixed duplicate IMAP connection messages and improved error handling
- Telegram test message restored to informative format
- General UI polish and bug fixes throughout the app

### Fixed

- Duplicate IMAP connection result messages
- Inconsistent section margins and divider alignment in settings
- Telegram test message content and formatting
- Various minor UI and logic bugs

## [2.0.0] - 2024-12-19

### Added

- **Timeslot Management Improvements**: Enhanced timeslot configuration with intelligent limits and validation
- **2-Slot Limit**: Maximum 2 timeslots per day to prevent overbooking
- **Duplicate Prevention**: Automatic detection and prevention of duplicate times on the same day
- **Smart Time Selection**: Intelligent default time selection for second timeslot (avoids conflicts)
- **Sorted Preview**: Timeslots in preview are now sorted by day and time for better readability
- **Enhanced UI Feedback**: Clear messaging about limits and helpful tooltips

### Changed

- **Configuration Interface**: Improved timeslot editor with better validation and user feedback
- **Preview Display**: Timeslots are now properly sorted chronologically within each day
- **User Experience**: More intuitive timeslot management with clear visual indicators
- **Code Quality**: Improved code organization and error handling in timeslot management

### Technical Improvements

- **Validation Logic**: Robust duplicate detection using hour/minute comparison
- **Smart Defaults**: Intelligent time selection algorithm for second timeslot
- **UI Consistency**: Consistent button states and tooltips throughout the interface
- **Performance**: Optimized timeslot operations and preview rendering

## [1.4.0] - 2024-07-10

### Changed

- Major icon/logo fix: custom app icon now appears in Finder, DMG, and app switcher
- Tray icon reverted to clean SF Symbol for clarity
- Version bump and polish for 1.4.0 release

## [1.3.2] - 2024-07-10

### Changed

- Updated app version to 1.3.2 for new release
- Final polish and cleanup for patch release

## [Unreleased]

### Added

- Enhanced build script with colored output and command-line options
- Comprehensive project documentation and development guidelines
- Improved project configuration with XcodeGen
- Better error handling and logging throughout the application
- Enhanced UI with hover effects and smooth animations
- Built-in logs viewer with clear and filter functionality
- Real-time status display with countdown to next autorun
- Support for multiple configurations with individual run controls
- Auto-generated configuration names based on facility, sport, and people count

### Changed

- Refactored ContentView.swift with better code organization and performance
- Updated project structure with proper separation of concerns
- Improved Info.plist with comprehensive metadata and security settings
- Enhanced .gitignore with comprehensive patterns for macOS development
- Updated README.md with detailed installation and usage instructions
- Improved DEVELOPMENT.md with comprehensive development guidelines

### Fixed

- Cron time calculation to look multiple weeks ahead for future autorun times
- Status text to show detailed information about next autorun
- Configuration name generation to be more concise and readable
- UI layout issues and button styling consistency
- Toggle switch hover effects and visual feedback
- Migrated from Chrome/ChromeDriver automation to native Swift + WebKit automation. All reservation automation is now handled by WebKitService. ChromeDriver is no longer required.

## [1.2.0] - 2024-07-09

### Changed

- Removed build date injection feature for cleaner release artifacts
- Final polish and cleanup for minor release

## [1.1.0] - 2024-07-09

### Changed

- Full UI/UX pass for native macOS look and feel
- Improved margins and spacing for all screens
- Removed all custom button and card styles
- Code cleanup and review for release

## [1.0.0] - 2024-07-09

### Added

- Initial release of ODYSSEY
- Native macOS menu bar application
- Web automation for Ottawa Recreation facilities
- SwiftUI-based configuration interface
- Support for multiple sports and facilities
- Flexible scheduling with custom days and time slots
- Automatic reservation booking 2 days before desired time
- Real-time status monitoring
- Built-in logging system
- Configuration management with CRUD operations
- Web scraping for facility and sport information
- Modern UI with native macOS design patterns

### Technical Features

- SwiftUI for modern, declarative UI
- AppKit for native menu bar integration
- WebKit for web automation and scraping
- UserDefaults for persistent configuration storage
- Timer-based automated scheduling system
- Comprehensive error handling and logging
- Modular architecture with clear separation of concerns

---

## Version History

### Version 1.0.0

- **Release Date**: July 9, 2024
- **Status**: Initial Release
- **Key Features**: Core automation functionality, SwiftUI interface, menu bar integration

---

## Migration Guide

### From Pre-1.0.0 Versions

This is the initial release, so no migration is required.

---

## Deprecation Notices

No deprecated features in the current version.

---

## Known Issues

### Version 1.0.0

- None currently documented

---

## Future Roadmap

### Version 1.1.0 (Planned)

- Enhanced error recovery and retry mechanisms
- Additional facility support
- Improved scheduling options
- Performance optimizations

### Version 1.2.0 (Planned)

- Advanced automation features
- Integration with calendar applications
- Notification system improvements
- Accessibility enhancements

### Version 2.0.0 (Long-term)

- Support for multiple recreation systems
- Advanced scheduling algorithms
- Machine learning for slot prediction
- Cross-platform support

---

## Support

For support and questions:

- **GitHub Issues**: [Report Issues](https://github.com/Amet13/ODYSSEY/issues)
- **GitHub Discussions**: [Community Discussion](https://github.com/Amet13/ODYSSEY/discussions)
- **Email**: support@odyssey.app

---

**Made with ❤️ for the Ottawa sports community**

## [1.3.0] - 2024-07-10

### Changed

- Updated app branding: custom logo now appears in confirmation dialogs and throughout the app
- Updated all version references to 1.3.0
- Polish and prep for new release

## [0.1.0] -

### Added

- Initial public release
- Requirements: macOS 15, Xcode 16, Swift 6
- Full audit for English localization
- Consistent logging format across all services
- UI text and punctuation consistency
- Button and element sizing polish for modern macOS look
- Major codebase cleanup and documentation update
