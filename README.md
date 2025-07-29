<div align="center">
  <img src="Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" alt="ODYSSEY Logo">
  <h1>ODYSSEY</h1>
  <p><strong>Ottawa Drop-in Your Sports & Schedule Easily Yourself</strong></p>
  <p><em>macOS Menu Bar App + Command Line Interface for Sports Reservation Automation</em></p>
  <p>
    <a href="https://github.com/Amet13/ODYSSEY/actions/workflows/pipeline.yml">
<img src="https://github.com/Amet13/ODYSSEY/actions/workflows/pipeline.yml/badge.svg" alt="Pipeline Status">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/releases">
      <img src="https://img.shields.io/github/v/release/Amet13/ODYSSEY?label=version" alt="Latest Release">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
    </a>
  </p>
</div>

## 🚀 Quick Start

### 🖥️ GUI Version (macOS Menu Bar App)

**Requirements**: See [REQUIREMENTS.md](Documentation/REQUIREMENTS.md)

1. **Download** the latest `.dmg` from the [Releases page](https://github.com/Amet13/ODYSSEY/releases).
2. **Install**: Open the `.dmg`, drag ODYSSEY to `Applications`.
3. **Launch**: Find ODYSSEY in your menu bar (top right).
4. **Configure**: Click the icon, add your reservation details, and set up email for verification.
5. **Automate!** Sit back and let ODYSSEY book your sports for you! 🎉

### 💻 CLI Version (Command Line Interface)

**Requirements**: See [REQUIREMENTS.md](Documentation/REQUIREMENTS.md)

1. **Download** the CLI binary from the [Releases page](https://github.com/Amet13/ODYSSEY/releases).
2. **Export** your configuration from the GUI app.
3. **Set** the `ODYSSEY_EXPORT_TOKEN` environment variable.
4. **Run** reservations with `./odyssey-cli run`! 🚀

## ✨ Features

| Feature                     | Description                                                     |
| --------------------------- | --------------------------------------------------------------- |
| 🖥️ GUI Version              | Native macOS menu bar app with SwiftUI interface                |
| 💻 CLI Version              | Command-line interface for remote automation                    |
| 🛡️ WebKit Automation        | Uses native Swift WebKit (WKWebView) for robust automation      |
| 🎨 Modern SwiftUI Interface | Beautiful, responsive UI for easy configuration                 |
| ⏰ Automated Scheduling     | Schedules runs based on your configured time slots              |
| ⚙️ Multiple Configurations  | Supports different sports and facilities                        |
| 🔒 Secure Storage           | Keychain integration for credentials                            |
| 📧 Email Verification       | Automated IMAP/Gmail verification for reservation confirmations |
| 🕵️‍♂️ Anti-Detection           | Human-like automation with browser window monitoring            |
| 🎨 Dark Mode Polish         | Fully adaptive UI for both light and dark appearances           |
| 🔍 Conflict Detection       | Automatic detection of scheduling and facility conflicts        |

## 📦 Installation

For detailed installation instructions, see [INSTALLATION.md](Documentation/INSTALLATION.md).

### Quick Installation

1. **Download** the latest release from [GitHub Releases](https://github.com/Amet13/ODYSSEY/releases)
2. **Install** by dragging to Applications folder
3. **Launch** and configure your settings
4. **Automate** your Ottawa Recreation reservations!

## 🎯 Quick Usage Guide

### 🖥️ GUI Version

1. **Add configurations** via the menu bar app
2. **Configure email** for verification
3. **Enable auto-run** and let ODYSSEY handle the rest!

### 💻 CLI Version

1. **Export configuration** from the GUI app
2. **Set environment variable**: `export ODYSSEY_EXPORT_TOKEN="<token>"`
3. **Run**: `./odyssey-cli run`

**📖 For detailed usage instructions, see [USER_GUIDE.md](Documentation/USER_GUIDE.md)**

## 📊 Logs & Debugging

- View detailed logs in **Console.app**:
  - Filter by subsystem: `com.odyssey.app`
  - Look for emoji indicators for quick status identification
- All sensitive data is masked or marked as private in logs

## 🛠️ Quick Troubleshooting

### Common Issues

- **❌ Automation fails**: Try different times, check facility website structure
- **📧 Email issues**: Verify IMAP credentials and App Password (for Gmail)
- **🔒 Keychain errors**: Re-enter credentials in Settings
- **🕵️‍♂️ App not visible**: Ensure macOS 15+, check menu bar (not Dock)

### Where to Get Help

- **[GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)** - Report bugs
- **[USER_GUIDE.md](Documentation/USER_GUIDE.md)** - Detailed troubleshooting
- **[DEVELOPMENT.md](Documentation/DEVELOPMENT.md)** - Advanced debugging

## 🤝 Contributing

See [CONTRIBUTING.md](Documentation/CONTRIBUTING.md) for detailed contribution guidelines, and good first issues.

## 🛡️ Security & Compliance

- 🔒 Credentials are securely stored in the macOS Keychain—never in plain text or UserDefaults
- 🌐 All network requests use HTTPS; App Transport Security (ATS) is strictly enforced
- 📝 The app is code signed for distribution but is **not notarized by Apple** (no Apple Developer account). To enable notarization, see [DEVELOPMENT.md](Documentation/DEVELOPMENT.md) and `Scripts/create-release.sh` for detailed instructions
- 🚫 No user data is ever sent externally without your explicit consent. All automation runs locally
- See [DEVELOPMENT.md](Documentation/DEVELOPMENT.md) for full security and compliance details

## 📚 Documentation

- **[USER_GUIDE.md](Documentation/USER_GUIDE.md)** - Comprehensive user guide
- **[CLI.md](Documentation/CLI.md)** - Command-line interface documentation
- **[DEVELOPMENT.md](Documentation/DEVELOPMENT.md)** - Development workflow and guidelines
- **[CONTRIBUTING.md](Documentation/CONTRIBUTING.md)** - Contribution guidelines
- **[ACCESSIBILITY.md](Documentation/ACCESSIBILITY.md)** - Accessibility features and guidelines
- **[SCRIPTS.md](Documentation/SCRIPTS.md)** - Complete scripts documentation and usage guide

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
