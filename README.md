<div align="center">
  <img src="Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" alt="ODYSSEY Logo" width="200" style="border-radius: 20px;">
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

1. **Download** the latest `.dmg` from the [Releases page](https://github.com/Amet13/ODYSSEY/releases).
2. **Install**: Open the `.dmg`, drag ODYSSEY to `Applications`.
3. **Launch**: Find ODYSSEY in your menu bar (top right).
4. **Configure**: Click the icon, add your settings and configurations.
5. **Automate!** Enable autorun and sit back and let ODYSSEY book your sports for you! 🎉

### 💻 CLI Version (Command Line Interface)

1. **Download** the latest CLI binary from the [Releases page](https://github.com/Amet13/ODYSSEY/releases).
2. **Export** your configuration from the GUI app.
3. **Set** the `ODYSSEY_EXPORT_TOKEN` environment variable.
4. **Run** reservations with `./odyssey-cli run`! 🚀

## ✨ Features

| Feature                     | Description                                                      |
| --------------------------- | ---------------------------------------------------------------- |
| 🖥️ GUI Version              | Native macOS menu bar app with SwiftUI interface                 |
| 💻 CLI Version              | Command-line interface for remote automation                     |
| 🛡️ WebKit Automation        | Uses native Swift WebKit (WKWebView) for robust automation       |
| 🎨 Modern SwiftUI Interface | Beautiful, responsive UI for easy configuration                  |
| ⏰ Automated Scheduling     | Schedules runs based on your configured time slots               |
| ⚙️ Multiple Configurations  | Supports different sports and facilities                         |
| 🔒 Secure Storage           | Keychain integration for credentials                             |
| 📧 Email Verification       | Automated IMAP/Gmail verification for reservation confirmations  |
| 🕵️‍♂️ Anti-Detection           | Human-like automation with browser window monitoring             |
| 🎨 Dark Mode Polish         | Fully adaptive UI for both light and dark appearances            |
| 🔍 Conflict Detection       | Automatic detection of time slot overlaps and facility conflicts |

## 📚 Documentation

- **[REQUIREMENTS.md](Documentation/REQUIREMENTS.md)** - ODYSSEY Requirements
- **[INSTALLATION.md](Documentation/INSTALLATION.md)** - Installation guide
- **[USER_GUIDE.md](Documentation/USER_GUIDE.md)** - Comprehensive user guide
- **[CLI.md](Documentation/CLI.md)** - Command-line interface documentation
- **[DEVELOPMENT.md](Documentation/DEVELOPMENT.md)** - Development workflow and guidelines
- **[CONTRIBUTING.md](Documentation/CONTRIBUTING.md)** - Contribution guidelines
- **[SCRIPTS.md](Documentation/SCRIPTS.md)** - Complete scripts documentation and usage guide

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
