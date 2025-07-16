<div align="center">
  <img src="logo.svg" alt="ODYSSEY Logo" width="120" height="120">
  <h1>ODYSSEY</h1>
  <p><strong>Ottawa Drop-in Your Sports & Schedule Easily Yourself (macOS Automation)</strong></p>
  
  <p>
    <a href="https://github.com/Amet13/ODYSSEY/actions/workflows/ci.yml">
      <img src="https://github.com/Amet13/ODYSSEY/actions/workflows/ci.yml/badge.svg" alt="CI Status">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/issues">
      <img src="https://img.shields.io/badge/Support-GitHub%20Issues-orange" alt="GitHub Issues">
    </a>
  </p>
  
  <p>
    <a href="#installation">
      <img src="https://img.shields.io/badge/Build%20from%20Source-Development-blue?style=for-the-badge&logo=swift" alt="Build from Source">
    </a>
  </p>
</div>

# ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself

ODYSSEY is a native macOS menu bar application that automates sports reservation bookings for Ottawa Recreation facilities.

## 🚀 Features

- Runs quietly in the menu bar (not dock)
- Automates web-based reservation booking for Ottawa Recreation facilities
- Uses **Swift + WebKit** for robust, native web automation
- Modern SwiftUI interface for configuration management
- Schedules automatic runs based on configured time slots
- Supports multiple configurations for different sports and facilities
- Comprehensive logging and error handling

## 🏗️ Architecture & Technology Stack

- **SwiftUI** - Modern, declarative UI framework for macOS
- **AppKit** - Native macOS menu bar integration
- **WebKit (WKWebView)** - Native web automation engine
- **Combine** - Reactive programming for async operations and state management
- **UserDefaults** - Persistent configuration storage
- **Timer** - Automated scheduling system
- **os.log** - Structured logging for debugging and monitoring

## 🔧 Setup

```bash
# Clone repository
git clone https://github.com/Amet13/ODYSSEY.git
cd ODYSSEY

# Install dependencies
brew install xcodegen
brew install swiftlint

# Generate Xcode project
xcodegen

# Build and run
./Scripts/build.sh
```

## 🛡️ Permissions

- **Full Disk Access:** ODYSSEY may require Full Disk Access for automation to work on macOS. Grant access in **System Settings > Privacy & Security > Full Disk Access**.
- **Automation/Accessibility:** For advanced automation features, you may need to enable Automation or Accessibility permissions for ODYSSEY.

## 📝 Documentation

- See `Documentation/DEVELOPMENT.md` for development workflow and architecture details.
- See `Documentation/CHANGELOG.md` for release notes.

## 🧑‍💻 Contributing

Pull requests are welcome! Please see `Documentation/CONTRIBUTING.md` for guidelines.

## 📄 License

MIT
