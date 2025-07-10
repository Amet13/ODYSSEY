# ODYSSEY Sources

This directory contains all the source code for the ODYSSEY macOS application.

> **ODYSSEY: Ottawa Drop-in Your Sports & Schedule Easily Yourself (macOS Automation)**

## Directory Structure

```
Sources/
├── App/                    # Application entry point
│   ├── ODYSSEYApp.swift    # Main app delegate
│   └── Info.plist         # App configuration
├── Views/                  # SwiftUI views
│   ├── Main/              # Main application views
│   │   └── ContentView.swift
│   ├── Configuration/     # Configuration-related views
│   │   └── ConfigurationDetailView.swift
│   └── Components/        # Reusable UI components
├── Models/                 # Data models
│   └── ReservationConfig.swift
├── Services/              # Business logic and services
│   ├── Configuration.swift
│   ├── ReservationManager.swift
│   └── FacilityService.swift
├── Controllers/           # AppKit controllers
│   └── StatusBarController.swift
└── Resources/             # App resources
    ├── Assets.xcassets/   # Images and icons
    └── AppIcon.icns       # App icon
```

## Architecture Overview

### App Layer

- **ODYSSEYApp.swift** - Main application entry point and app delegate
- **Info.plist** - Application configuration and permissions

### Views Layer

- **Main** - Primary application interface
- **Configuration** - Settings and configuration management
- **Components** - Reusable UI components and styles

### Models Layer

- **ReservationConfig.swift** - Core data model for reservation configurations

### Services Layer

- **Configuration.swift** - Settings management and persistence
- **ReservationManager.swift** - Web automation and reservation booking
- **FacilityService.swift** - Facility data fetching and sports detection

### Controllers Layer

- **StatusBarController.swift** - Menu bar integration and UI management

### Resources Layer

- **Assets.xcassets** - Image assets and app icons
- **AppIcon.icns** - Application icon file

## Development Guidelines

### Adding New Files

1. Place files in the appropriate directory based on their purpose
2. Follow the existing naming conventions
3. Update this README if adding new directories

### Code Organization

- Keep related functionality together
- Use clear, descriptive file names
- Follow Swift and SwiftUI best practices
- Maintain separation of concerns

### Dependencies

- Models should have no dependencies on other layers
- Services can depend on Models
- Views can depend on Models and Services
- Controllers can depend on all layers
