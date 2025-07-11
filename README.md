<div align="center">
  <img src="logo.svg" alt="ODYSSEY Logo" width="120" height="120">
  <h1>ODYSSEY</h1>
  <p><strong>Ottawa Drop-in Your Sports & Schedule Easily Yourself (macOS Automation)</strong></p>
  
  <p>
    <a href="https://github.com/Amet13/ODYSSEY/actions/workflows/ci.yml">
      <img src="https://github.com/Amet13/ODYSSEY/actions/workflows/ci.yml/badge.svg" alt="CI Status">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/releases/latest">
      <img src="https://img.shields.io/badge/Version-2.0.0-blue" alt="Version 2.0.0">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/issues">
      <img src="https://img.shields.io/badge/Support-GitHub%20Issues-orange" alt="GitHub Issues">
    </a>
  </p>
  
  <p>
    <a href="https://github.com/Amet13/ODYSSEY/releases/latest">
      <img src="https://img.shields.io/badge/Download-v2.0.0-blue?style=for-the-badge&logo=apple" alt="Download v2.0.0">
    </a>
  </p>
</div>

A sophisticated macOS menu bar application that automates sports reservation bookings for Ottawa Recreation facilities. ODYSSEY runs quietly in the background and automatically books your preferred sports slots at the optimal time.

## 📋 Table of Contents

- [🚀 Features](#-features)
- [📋 Requirements](#-requirements)
- [🛠️ Installation & Setup](#️-installation--setup)
- [🏗️ Project Structure](#️-project-structure)
- [⚙️ Configuration](#️-configuration)
- [🔧 How It Works](#-how-it-works)
- [🐛 Troubleshooting](#-troubleshooting)
- [🧪 Development](#-development)
- [📄 License](#-license)
- [🤝 Contributing](#-contributing)

## 🚀 Features

- 🖥️ **Native macOS Menu Bar Integration** - Sits quietly in the menu bar without cluttering your dock
- ⏰ **Smart Scheduling** - Automatically runs 2 days before your desired reservation time at 6:00 PM
- ⚙️ **Easy Configuration** - Intuitive SwiftUI interface for setting up reservations
- 🤖 **Web Automation** - Automatically navigates and books slots using WebKit
- 📱 **Modern UI** - Clean, native macOS interface with hover effects and smooth animations
- 🔄 **Multiple Configurations** - Set up different sports, facilities, and time slots
- 📊 **Real-time Status** - See countdown to next autorun and current status
- 📝 **Built-in Logs** - View automation logs directly in the app
- 🎯 **Flexible Scheduling** - Choose specific days and up to 2 time slots per day
- 🚫 **Duplicate Prevention** - Automatic detection and prevention of duplicate times
- 🧠 **Smart Time Selection** - Intelligent default time selection for second timeslot
- 📊 **Sorted Preview** - Timeslots displayed in chronological order for clarity
- 🔍 **Advanced Logging** - Comprehensive logging with os.log for debugging
- 🛡️ **Code Quality** - SwiftLint integration and best practices enforcement

## 📋 Requirements

- **macOS 12.0** or later
- **Xcode 14.0** or later (for development)
- **Swift 5.7** or later

## 🚀 Quick Start

<div align="center">
  <a href="https://github.com/Amet13/ODYSSEY/releases/latest">
    <img src="https://img.shields.io/badge/Download-v2.0.0-blue?style=for-the-badge&logo=apple" alt="Download v2.0.0">
  </a>
</div>

1. **Download** the latest release from [Releases](https://github.com/Amet13/ODYSSEY/releases)
2. **Install** by dragging to Applications folder
3. **Launch** ODYSSEY (right-click → Open if needed)
4. **Configure** your first reservation
5. **Enjoy** automated booking! 🎯

## 🛠️ Installation & Setup

### For Users

#### Option 1: Download Latest Release (Recommended)

1. **Go to [Releases](https://github.com/Amet13/ODYSSEY/releases)**
2. **Download the latest DMG file** (e.g., `ODYSSEY-v2.0.0.dmg`)
3. **Double-click the DMG** to mount the disk image
4. **Drag ODYSSEY to Applications** folder
5. **Launch ODYSSEY** from Applications (right-click → Open if needed)
6. **The app will appear in your menu bar**

#### Option 2: Build from Source

1. **Clone the repository** (see Developer Setup below)
2. **Run the build script**: `./build.sh`
3. **The app will be built and launched automatically**

### For Developers

#### 1. Prerequisites

```bash
# Install XcodeGen (if not already installed)
brew install xcodegen

# Install SwiftLint for code quality (optional but recommended)
brew install swiftlint
```

#### 2. Clone and Setup

```bash
git clone https://github.com/Amet13/ODYSSEY.git
cd ODYSSEY
```

#### 3. Generate Xcode Project

```bash
xcodegen
```

#### 4. Build and Run

```bash
# Quick build and run
./build.sh

# Or open in Xcode
open ODYSSEY.xcodeproj
```

## 🏗️ Project Structure

```
odyssey/
├── ODYSSEY.xcodeproj/              # Xcode project (auto-generated)
├── Sources/
│   ├── App/ODYSSEYApp.swift        # Main app entry point
│   ├── ContentView.swift          # Main configuration interface
│   ├── ConfigurationDetailView.swift # Configuration editor
│   ├── StatusBarController.swift  # Menu bar integration
│   ├── ReservationManager.swift   # Web automation engine
│   ├── FacilityService.swift      # Web scraping and facility data
│   ├── Configuration.swift        # Settings and preferences
│   ├── Models/
│   │   └── ReservationConfig.swift # Data models
│   └── Info.plist                 # App metadata
├── project.yml                    # XcodeGen project specification
├── .swiftlint.yml                 # SwiftLint configuration
├── build.sh                       # Build and run script
├── README.md                      # This file
├── DEVELOPMENT.md                 # Developer guide
├── CONTRIBUTING.md                # Contribution guidelines
├── CHANGELOG.md                   # Version history
└── LICENSE                        # MIT License
```

## ⚙️ Configuration

### Basic Setup

1. **Launch ODYSSEY** - Click the menu bar icon
2. **Add Configuration** - Click the "+" button
3. **Enter Facility URL** - Paste your Ottawa Recreation facility URL
4. **Select Sport** - Choose from available sports at the facility
5. **Set Number of People** - Choose 1-4 people
6. **Configure Schedule** - Select days and time slots
7. **Enable Configuration** - Toggle the switch to activate

### Advanced Features

- **Multiple Configurations** - Set up different sports and facilities
- **Smart Scheduling** - Choose specific weekdays and up to 2 time slots per day
- **Duplicate Prevention** - Automatic detection and prevention of duplicate times
- **Auto-generated Names** - Configuration names are automatically generated
- **Real-time Status** - See countdown to next autorun
- **Manual Execution** - Run configurations immediately with the "Run" button
- **Built-in Logging** - View detailed logs within the app

### 🆕 What's New in v2.0.0

<div align="center">
  <table>
    <tr>
      <td align="center"><strong>🎯 2-Slot Limit</strong><br/>Maximum 2 timeslots per day</td>
      <td align="center"><strong>🚫 Duplicate Prevention</strong><br/>No overlapping times</td>
      <td align="center"><strong>🧠 Smart Selection</strong><br/>Intelligent defaults</td>
    </tr>
    <tr>
      <td align="center"><strong>📊 Sorted Preview</strong><br/>Chronological display</td>
      <td align="center"><strong>🎨 Enhanced UI</strong><br/>Better feedback</td>
      <td align="center"><strong>📚 Improved Docs</strong><br/>Better guidance</td>
    </tr>
  </table>
</div>

## 🔧 How It Works

### Automation Process

1. **Scheduling** - ODYSSEY calculates the optimal booking time (2 days before at 6:00 PM)
2. **Web Navigation** - Uses WebKit to navigate to the facility website
3. **Form Automation** - Automatically fills forms with your preferences
4. **Slot Selection** - Finds and selects available time slots
5. **Booking** - Completes the reservation process
6. **Logging** - Records all actions for review

### Technical Architecture

- **SwiftUI** - Modern, declarative UI framework
- **AppKit** - Native macOS menu bar integration
- **WebKit** - Web automation and scraping capabilities
- **UserDefaults** - Persistent configuration storage
- **Timer** - Automated scheduling system
- **os.log** - Comprehensive logging system

## 🐛 Troubleshooting

### Common Issues

**App doesn't appear in menu bar:**

- Check that `LSUIElement` is set to `true` in Info.plist
- Restart the app

**Automation fails:**

- Verify the facility URL is correct
- Check that the sport is available
- Review logs in the app for error details

**Scheduling issues:**

- Ensure configurations are enabled
- Check that time slots are configured
- Verify the countdown timer in the status

### Debug Mode

Enable detailed logging by checking the Console app for messages from subsystem "com.odyssey.app"

## 🧪 Development

### 🚀 CI/CD Pipeline

ODYSSEY uses GitHub Actions for continuous integration and deployment:

<div align="center">
  <table>
    <tr>
      <td align="center"><strong>🔨 CI Workflow</strong><br/>Builds on every push/PR</td>
      <td align="center"><strong>📦 Release Workflow</strong><br/>Auto-creates DMG installers</td>
      <td align="center"><strong>🧪 Quality Checks</strong><br/>SwiftLint & testing</td>
    </tr>
  </table>
</div>

- **CI Workflow** - Runs on every push and pull request
  - ✅ Builds the app in Debug configuration
  - ✅ Runs SwiftLint for code quality
  - ✅ Uploads build artifacts
  - ✅ Checks app size and performance
- **Release Workflow** - Runs when a new version tag is pushed
  - 🚀 Builds the app in Release configuration
  - 📦 Creates a DMG installer automatically
  - 🏷️ Publishes a GitHub release with download links
  - 🔐 Code signs the application
- **Quality Assurance** - Comprehensive testing and validation
  - 🧪 Automated testing on macOS latest
  - 📊 Build size monitoring
  - 🔍 Code quality enforcement

### Creating Releases

To create a new release:

```bash
# Create release v2.0.0
./scripts/create-release.sh 2.0.0

# Preview what would be done
./scripts/create-release.sh --dry-run 2.1.0
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](Documentation/CONTRIBUTING.md) for details.

### 📞 Support & Community

- 🐛 [Report Issues](https://github.com/Amet13/ODYSSEY/issues)
- 💬 [Community Discussion](https://github.com/Amet13/ODYSSEY/discussions)
- 📖 [Documentation](Documentation/)
- 🔧 [Development Guide](Documentation/DEVELOPMENT.md)

---

<div align="center">
  <p><strong>Made with ❤️ for the Ottawa sports community</strong></p>
  <p>
    <a href="https://github.com/Amet13/ODYSSEY">
      <img src="https://img.shields.io/badge/GitHub-Repository-blue?logo=github" alt="GitHub Repository">
    </a>
  </p>
</div>
