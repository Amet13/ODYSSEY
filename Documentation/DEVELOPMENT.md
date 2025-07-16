# ODYSSEY Development Guide

## Architecture Overview

ODYSSEY is a native macOS menu bar application for automating sports reservation bookings for Ottawa Recreation facilities. The app is built with SwiftUI, AppKit, Combine, and uses **WebKit (WKWebView)** for all web automation tasks.

### Key Components

- **SwiftUI**: Modern, declarative UI for macOS
- **AppKit**: Menu bar integration
- **WebKitService**: Native web automation engine (replaces all Chrome/ChromeDriver logic)
- **Combine**: Async operations and state management
- **UserDefaults**: Persistent configuration
- **os.log**: Structured logging

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Amet13/ODYSSEY.git
   cd ODYSSEY
   ```
2. **Install dependencies**
   ```bash
   brew install xcodegen
   brew install swiftlint
   ```
3. **Generate Xcode project**
   ```bash
   xcodegen
   ```
4. **Build and run**
   ```bash
   ./Scripts/build.sh
   ```

## Permissions

- **Full Disk Access**: ODYSSEY may require Full Disk Access for automation to work on macOS. Grant access in **System Settings > Privacy & Security > Full Disk Access**.
- **Automation/Accessibility**: For advanced automation features, you may need to enable Automation or Accessibility permissions for ODYSSEY.

## Web Automation

- All reservation automation is now handled by `WebKitService` using `WKWebView` and JavaScript injection.
- No external browsers or drivers are required.
- All automation runs natively and securely on the user's Mac.

## Testing

- Use the built-in UI and logs to test automation flows.
- All business logic and automation can be tested via unit and integration tests.

## Contributing

- Please follow the code style and commit guidelines in the main README.
- Pull requests are welcome!
