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
  - [Telegram Bot Setup](#telegram-bot-setup)
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
- 📱 **Telegram Notifications** - Get instant notifications when reservations are successfully booked
- 📝 **Contact Form Automation** - Automatically fills contact information (phone, email, name) during booking
- 🤖 **Human-Like Behavior** - Advanced anti-bot detection with realistic timing and mouse movements
- ⚡ **Performance Modes** - Choose between normal and fast modes for optimal speed vs. stealth

## 📋 Requirements

- **macOS 15.0** or later
- **Xcode 16.0** or later (for development)
- **Swift 6.0** or later
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

## 🤖 Telegram Bot Setup

ODYSSEY supports Telegram notifications to keep you informed about successful reservations. Follow these steps to set up your Telegram bot:

### Step 1: Create a Telegram Bot

1. **Open Telegram** and search for `@BotFather`
2. **Start a chat** with BotFather by clicking "Start"
3. **Send the command**: `/newbot`
4. **Choose a name** for your bot (e.g., "ODYSSEY Sports Bot")
5. **Choose a username** ending in "bot" (e.g., "odyssey_sports_bot")
6. **Save the bot token** - BotFather will give you a token like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`

### Step 2: Get Your Chat ID

#### Method 1: Using @userinfobot (Recommended)

1. **Search for** `@userinfobot` in Telegram
2. **Start a chat** with the bot
3. **Send any message** to the bot
4. **Copy your Chat ID** from the response (it will be a number like `123456789`)

#### Method 2: Using Your Bot

1. **Start a chat** with your newly created bot
2. **Send any message** to your bot
3. **Visit this URL** in your browser (replace with your bot token):
   ```
   https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   ```
4. **Find your Chat ID** in the JSON response under `"chat":{"id":123456789}`

### Step 3: Configure in ODYSSEY

1. **Open ODYSSEY** and go to **Settings**
2. **Enable Telegram notifications** by checking the box
3. **Enter your Bot Token** (from Step 1)
4. **Enter your Chat ID** (from Step 2)
5. **Test the connection** using the "Test Telegram" button

### Step 4: Test Your Setup

1. **Click "Test Telegram"** in the Settings
2. **Check your Telegram** for a test message
3. **Verify the message** appears with the current timestamp

### Troubleshooting

#### Common Issues:

- **"Bot token invalid"**: Double-check your bot token from BotFather
- **"Chat ID not found"**: Make sure you've sent a message to your bot first
- **"Test failed"**: Check your internet connection and try again
- **"Bot blocked"**: Make sure you haven't blocked your bot in Telegram

#### Security Notes:

- **Keep your bot token private** - don't share it publicly
- **Your bot can only send messages** - it cannot read your messages
- **You can delete the bot anytime** by messaging BotFather `/deletebot`

### Sample Notification

When ODYSSEY successfully books a reservation, you'll receive a message like:

```
🎉 Reservation Success!

✅ Successfully booked: Basketball

🏢 Facility: Bob MacQuarrie Recreation Complex

👥 People: 2

📅 Schedule: Mon: 7:00 PM • Wed: 8:00 PM

🥅 ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself
```

## 🤖 Contact Form Automation

ODYSSEY automatically handles the contact information form during the booking process, eliminating the need for manual data entry.

### ✨ Features

- **Automatic Field Detection** - Intelligently finds phone, email, and name fields using multiple selectors
- **Human-Like Typing** - Simulates realistic typing patterns with variable delays
- **Anti-Bot Protection** - Includes mouse movements, scrolling, and natural timing to avoid detection
- **Dual Fill Modes**:
  - **Normal Mode**: Human-like typing with realistic delays (recommended)
  - **Fast Mode**: Optimized for speed while maintaining stealth
- **Fallback Mechanisms** - Multiple detection strategies ensure reliable field filling

### 🔧 Configuration

Contact information is automatically pulled from your user settings:

1. **Phone Number**: Automatically removes hyphens and formats for the form
2. **Email Address**: Uses your configured IMAP email
3. **Full Name**: Uses your configured name

### 🛡️ Anti-Detection Features

- **Random Delays**: Variable timing between actions (0.5-1.5 seconds)
- **Mouse Movement**: Realistic cursor movements between fields
- **Scrolling**: Natural page scrolling behavior
- **Typing Patterns**: Human-like character-by-character input
- **Field Transitions**: Natural pauses between form fields

### ⚡ Performance Modes

Enable fast mode for quicker automation (use with caution):

```swift
// In code (for developers)
WebDriverService.fastModeEnabled = true
```

**Normal Mode**: 5-8 seconds total (recommended for reliability)
**Fast Mode**: 4-6 seconds total (faster but may trigger detection)

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

## 🧪 Development

### 🚀 Enhanced CI/CD Pipeline

ODYSSEY uses a comprehensive GitHub Actions pipeline for continuous integration and deployment:

<div align="center">
  <table>
    <tr>
      <td align="center"><strong>🔨 Quality Checks</strong><br/>SwiftFormat & SwiftLint</td>
      <td align="center"><strong>🏗️ Build</strong><br/>Debug & Release builds</td>
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
- **Build** - Debug and Release builds with timing analysis
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
