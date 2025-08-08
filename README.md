<div align="center">
  <img src="Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" alt="ODYSSEY Logo" width="200" style="border-radius: 20px;">
  <h1>ODYSSEY</h1>
  <p><strong>Ottawa Drop-in Your Sports & Schedule Easily Yourself</strong></p>
  <p><em>macOS Menu Bar App + Command Line Interface for Sports Reservation Automation</em></p>
  <p>
    <a href="https://github.com/Amet13/ODYSSEY/actions/workflows/build-release.yml">
<img src="https://github.com/Amet13/ODYSSEY/actions/workflows/build-release.yml/badge.svg" alt="CI/CD Status">
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

- **Download** the `ODYSSEY.dmg` file from the [latest release](https://github.com/Amet13/ODYSSEY/releases/latest/).
- **Install:** Open the installer and drag `ODYSSEY.app` to **Applications**.
- **Add to the quarantine:** Run in your terminal:

  ```bash
  sudo xattr -rd com.apple.quarantine /Applications/ODYSSEY.app
  ```

- **Launch:** Open the app. You'll see a new icon in your menu bar.
- **Configure:** Click the icon to add your settings and create your first configuration(s).
- **Automate!** Enable autorun, or run it manually, and let ODYSSEY book your sports for you! 🎉

## ✨ Key Features

- 🖥️ **GUI & CLI versions** – Menu bar app + command-line automation.
- 🛡️ **Native WebKit automation** – Robust, human-like browser automation.
- ⏰ **Smart scheduling** – Automated runs based on your time slots.
- 🔒 **Secure & private** – Local processing, Keychain storage, no external data.
- 📧 **Email integration** – Automated verification and confirmations.
- 🎨 **Modern interface** – Beautiful SwiftUI with dark mode support.

## 📚 Documentation

- **[USER_GUIDE.md](Documentation/USER_GUIDE.md)** – Complete app setup and usage guide.
- **[CLI.md](Documentation/CLI.md)** – Command-line interface for CI/CD and remote automation.
- **[DEVELOPMENT.md](Documentation/DEVELOPMENT.md)** – Development workflow and contribution guidelines.

## ⚖️ Ethical Considerations & Legal Notice

### 🎓 Educational Purpose

This application demonstrates modern macOS development techniques including SwiftUI & AppKit integration, WebKit automation, menu bar applications, and secure credential management.

### 🛡️ Responsible Usage

**IMPORTANT:** This tool is designed for educational purposes and legitimate personal use only.

**✅ Permitted:**

- Personal educational and development purposes.
- Respecting rate limits with built-in delays.

**❌ Prohibited:**

- Commercial services or reselling.
- Sharing accounts or credentials.
- Any malicious or harmful purposes.

### 🔒 Privacy & Security

- All automation runs locally on your machine (except CI).
- No user data transmitted to external servers (except CI).
- Credentials stored securely in macOS Keychain.
- No tracking or analytics collected.

**Legal Disclaimer:** This software is provided "as is" without warranty. Users are responsible for using the application in accordance with applicable laws and website terms of service.

By using this application, you acknowledge that you understand and agree to these terms of use.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
