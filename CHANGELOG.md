# Changelog

All notable changes to ORRMAT will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [1.0.0] - 2024-07-09

### Added

- Initial release of ORRMAT
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

- **GitHub Issues**: [Report Issues](https://github.com/Amet13/orrmat/issues)
- **GitHub Discussions**: [Community Discussion](https://github.com/Amet13/orrmat/discussions)
- **Email**: support@orrmat.app

---

**Made with ❤️ for the Ottawa sports community**
