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

A sophisticated macOS menu bar application that automates sports reservation bookings for Ottawa Recreation facilities. ODYSSEY runs quietly in the background and automatically books your preferred sports slots at the optimal time.

## 📋 Table of Contents

- [ODYSSEY - Ottawa Drop-in Your Sports \& Schedule Easily Yourself](#odyssey---ottawa-drop-in-your-sports--schedule-easily-yourself)
  - [Features](#features)
  - [Button Detection Approach](#button-detection-approach)
    - [HTML Structure](#html-structure)
    - [Working Method](#working-method)
    - [Why This Works](#why-this-works)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Development](#development)

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
- 🕵️‍♂️ **Incognito Run (Requires Chrome)** - The "Run" button opens your configuration in a new Google Chrome incognito window for manual verification. **Google Chrome must be installed.**
- 🔒 **Enhanced Security** - Comprehensive security scanning and validation
- 📦 **Automated Releases** - Complete CI/CD pipeline with automated DMG creation

## 📋 Requirements

- **macOS 12.0** or later
- **Xcode 14.0** or later (for development)
- **Swift 5.7** or later
- **Google Chrome** (for automation)
- **ChromeDriver** (required for web automation)

### 🔧 Required Setup

#### 1. Install ChromeDriver

```bash
# Install ChromeDriver via Homebrew
brew install chromedriver
```

#### 2. Configure Security Settings

**Important:** ODYSSEY requires specific permissions to automate Chrome browser actions.

1. **Open System Settings** → **Privacy & Security**
2. **Add ChromeDriver to Full Disk Access:**
   - Click **Full Disk Access** → **+** button
   - Navigate to `/opt/homebrew/bin/chromedriver`
   - Select and add ChromeDriver
3. **Add ODYSSEY to Automation:**
   - Click **Automation** → **+** button
   - Find and select **ODYSSEY** from Applications
   - Enable **System Events** and **Google Chrome**
4. **Optional - Add to Accessibility:**
   - Click **Accessibility** → **+** button
   - Add both **ODYSSEY** and **ChromeDriver**

**Why these permissions?**

- **Full Disk Access:** Allows ChromeDriver to launch Chrome browser
- **Automation:** Enables ODYSSEY to control Chrome for web automation
- **Accessibility:** Provides additional automation capabilities

**Note:** Without these permissions, automation will fail and ChromeDriver may be terminated by macOS security.

## 🚀 Quick Start

<div align="center">
  <a href="#installation">
    <img src="https://img.shields.io/badge/Build%20from%20Source-Development-blue?style=for-the-badge&logo=swift" alt="Build from Source">
  </a>
</div>

> **Note:** Google Chrome must be installed for the "Run" button (incognito mode) to work.

1. **Clone the repository** (see Installation section below)
2. **Run the build script**: `./Scripts/build.sh`
3. **Configure** your first reservation
4. **Enjoy** automated booking! 🎯

> **Development Status**: ODYSSEY is currently in active development. No official releases are available yet. Please build from source to use the application.

## 🛠️ Installation & Setup

### For Users

> **Development Status**: ODYSSEY is currently in active development. No official releases are available yet. Please build from source to use the application.

#### Build from Source (Currently Required)

1. **Clone the repository** (see Developer Setup below)
2. **Run the build script**: `./Scripts/build.sh`
3. **The app will be built and launched automatically**

### For Developers

#### 1. Prerequisites

```bash
# Install development tools
brew install xcodegen swiftlint swiftformat

# Install ChromeDriver for automation
brew install chromedriver
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
# Quick build and run with quality checks
./Scripts/build.sh

# Or open in Xcode
open Config/ODYSSEY.xcodeproj
```

## 🏗️ Project Structure

```
odyssey/
├── Config/
│   ├── ODYSSEY.xcodeproj/        # Xcode project (auto-generated)
│   └── project.yml               # XcodeGen project specification
├── Sources/
│   ├── App/
│   │   ├── ODYSSEYApp.swift      # Main app entry point
│   │   ├── Constants.swift       # Application constants
│   │   └── Info.plist           # App metadata
│   ├── Controllers/
│   │   └── StatusBarController.swift # Menu bar integration
│   ├── Models/
│   │   ├── ReservationConfig.swift # Data models
│   │   └── UserSettings.swift    # User preferences
│   ├── Services/
│   │   ├── Configuration.swift   # Settings and preferences
│   │   ├── EmailService.swift    # IMAP integration
│   │   ├── FacilityService.swift # Web scraping and facility data
│   │   ├── ReservationManager.swift # Web automation orchestration
│   │   ├── TelegramService.swift # Telegram bot integration
│   │   ├── UserSettingsManager.swift # User settings management
│   │   ├── WebDriverService.swift # Chrome automation engine
│   │   └── WebDriverStealth.swift # Anti-detection measures
│   ├── Views/
│   │   ├── Configuration/        # Configuration-related views
│   │   ├── Main/                # Main application views
│   │   └── Settings/            # Settings views
│   └── Resources/               # App resources and assets
├── Scripts/
│   ├── build.sh                 # Enhanced build script
│   └── create-release.sh        # Release management script
├── Documentation/               # Project documentation
├── .github/workflows/           # CI/CD workflows
├── .swiftlint.yml              # SwiftLint configuration
├── .swiftformat                # SwiftFormat configuration
├── README.md                   # This file
└── LICENSE                     # MIT License
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
- **📱 Telegram Integration** - Receive notifications and test messages via Telegram bot

### 📱 Telegram Integration

ODYSSEY supports Telegram integration for notifications and test messages. This feature allows you to receive updates about your automation status and test the integration.

#### Setting Up Telegram Integration

##### 1. Create a Telegram Bot

1. **Open Telegram** and search for `@BotFather`
2. **Start a chat** with BotFather by clicking "Start"
3. **Send the command** `/newbot`
4. **Choose a name** for your bot (e.g., "ODYSSEY Notifications")
5. **Choose a username** for your bot (must end with "bot", e.g., "odyssey_notifications_bot")
6. **Copy the bot token** - BotFather will send you a message like:
   ```
   Use this token to access the HTTP API:
   1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
   ```
   **⚠️ Keep this token secure - don't share it publicly!**

##### 2. Get Your Chat ID

**Method 1: Using @userinfobot (Recommended)**

1. **Search for** `@userinfobot` in Telegram
2. **Start a chat** with the bot
3. **Send any message** to the bot
4. **Copy your Chat ID** from the response (it will be a number like `123456789`)

**Method 2: Using @RawDataBot**

1. **Search for** `@RawDataBot` in Telegram
2. **Start a chat** with the bot
3. **Send any message** to the bot
4. **Look for** `"id": 123456789` in the response
5. **Copy the number** after `"id":`

**Method 3: For Group Chats**

1. **Add your bot** to the group where you want notifications
2. **Send a message** in the group
3. **Use @RawDataBot** to get the group's Chat ID (will be negative, like `-123456789`)

##### 3. Configure in ODYSSEY

1. **Open ODYSSEY** and click the menu bar icon
2. **Click "Settings"** to open the settings panel
3. **Scroll to "Telegram Integration"** section
4. **Toggle "Enable Telegram Integration"** to ON
5. **Enter your Bot Token** (the long string from BotFather)
6. **Enter your Chat ID** (the number from step 2)
7. **Click "Test Telegram Integration"** to verify the setup
8. **You should receive** a test message in Telegram

#### Telegram Integration Features

- **✅ Test Integration** - Send test messages to verify your setup
- **🔔 Notifications** - Receive updates about automation status (coming soon)
- **📱 Mobile Access** - Check status from anywhere via Telegram
- **🔒 Secure** - Uses Telegram's official Bot API
- **⚡ Real-time** - Instant message delivery

#### Troubleshooting Telegram Integration

**"Test failed: Unauthorized"**

- Check that your bot token is correct
- Ensure you copied the entire token from BotFather

**"Test failed: Chat not found"**

- Verify your Chat ID is correct
- Make sure you've started a chat with your bot
- For group chats, ensure the bot is added to the group

**"Test failed: Forbidden"**

- The bot doesn't have permission to send messages
- Start a chat with your bot first by sending `/start`

**"Network error"**

- Check your internet connection
- Ensure ODYSSEY has network permissions

#### Security Notes

- **Keep your bot token private** - don't share it in public forums or repositories
- **The bot can only send messages** - it cannot read your messages or access your account
- **You can revoke the token** anytime by messaging `/revoke` to @BotFather
- **Chat ID is not sensitive** - it's just a number that identifies your chat

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
- **Ensure ChromeDriver is installed:** `brew install chromedriver`
- **Check ChromeDriver permissions:** Add to Full Disk Access in System Settings

**ChromeDriver issues:**

- **"ChromeDriver is not running" error:**
  - Install ChromeDriver: `brew install chromedriver`
  - Add ChromeDriver to **System Settings > Privacy & Security > Full Disk Access**
  - Restart ODYSSEY after adding permissions
- **"Failed to start ChromeDriver" error:**
  - Check if ChromeDriver is installed: `which chromedriver`
  - Verify the path: `/opt/homebrew/bin/chromedriver`
  - Ensure proper permissions in System Settings
- **Chrome opens but automation doesn't work:**
  - Add ODYSSEY to **System Settings > Privacy & Security > Automation**
  - Enable **Google Chrome** and **System Events** for ODYSSEY

**Scheduling issues:**

- Ensure configurations are enabled
- Check that time slots are configured
- Verify the countdown timer in the status

### Debug Mode

Enable detailed logging by checking the Console app for messages from subsystem "com.odyssey.app"

**ChromeDriver Debug:**

```bash
# Check if ChromeDriver is running
curl http://localhost:9515/status

# Test ChromeDriver manually
chromedriver --port=9515 --verbose
```

## 🧪 Development

### 🚀 Enhanced CI/CD Pipeline

ODYSSEY uses a comprehensive GitHub Actions pipeline for continuous integration and deployment:

<div align="center">
  <table>
    <tr>
      <td align="center"><strong>🔨 Quality Checks</strong><br/>SwiftFormat & SwiftLint</td>
      <td align="center"><strong>🏗️ Build & Test</strong><br/>Debug & Release builds</td>
      <td align="center"><strong>🔒 Security Scan</strong><br/>Vulnerability checks</td>
    </tr>
    <tr>
      <td align="center"><strong>📊 Performance</strong><br/>Build time & size analysis</td>
      <td align="center"><strong>📦 Release</strong><br/>Automated DMG creation</td>
      <td align="center"><strong>📝 Documentation</strong><br/>Auto-generated notes</td>
    </tr>
  </table>
</div>

#### CI Workflow Features

- **Quality Checks** - Code formatting and linting with SwiftFormat and SwiftLint
- **Build & Test** - Debug and Release builds with timing analysis
- **Caching** - Swift package caching for faster builds
- **Artifact Upload** - Build artifacts for debugging and distribution

#### Release Workflow Features (Ready for Future Releases)

- **Version Validation** - Ensures version consistency across all files
- **Automated Build** - Release build with code signing
- **DMG Creation** - Professional installer with custom branding
- **Release Notes** - Auto-generated from git history and changelog
- **GitHub Release** - Complete release with download links

### Code Quality Standards

#### SwiftLint Configuration

ODYSSEY enforces strict code quality standards with a comprehensive SwiftLint configuration:

- **Code Style** - Consistent formatting and naming conventions
- **Best Practices** - Modern Swift patterns and anti-patterns
- **Documentation** - Public API documentation requirements
- **Performance** - Efficient code patterns
- **Security** - Safe coding practices

#### SwiftFormat Configuration

Automatic code formatting ensures consistency:

- **Indentation** - 4 spaces, smart tabs enabled
- **Line Length** - 120 characters max
- **Import Organization** - Alphabetized and grouped
- **Spacing** - Consistent spacing rules

### Development Workflow

```bash
# 1. Make changes
git checkout -b feature/new-feature

# 2. Format and lint code
swiftformat Sources/
swiftlint lint --config .swiftlint.yml

# 3. Build and test
xcodebuild build -project Config/ODYSSEY.xcodeproj -scheme ODYSSEY -configuration Debug

# 4. Commit with conventional commit message
git add .
git commit -m "feat: add new automation feature"

# 5. Push and create PR
git push origin feature/new-feature
```

### Creating Releases (Future)

When ready for official releases, use the automated release script for consistent releases:

```bash
# Preview release changes
./Scripts/create-release.sh --dry-run 1.0.0

# Create actual release
./Scripts/create-release.sh 1.0.0
```

The release script automatically:

- Updates version numbers in all files
- Generates changelog entries
- Creates git tags
- Triggers CI/CD pipeline for automated release

> **Note**: Currently in development. Release workflow is ready but no official releases have been created yet.

### Version Management

Follow [Semantic Versioning](https://semver.org/) (MAJOR.MINOR.PATCH):

- **MAJOR** - Breaking changes
- **MINOR** - New features, backward compatible
- **PATCH** - Bug fixes, backward compatible

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
