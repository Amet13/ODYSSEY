<div align="center">
  <img src="logo.svg" alt="ODYSSEY Logo" width="120" height="120">
  <h1>ODYSSEY</h1>
  <p><strong>Ottawa Drop-in Your Sports & Schedule Easily Yourself</strong></p>
  
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
</div>

A sophisticated macOS menu bar application that automates sports reservation bookings for Ottawa Recreation facilities.

## 🚀 Features

- **Native macOS Integration**: Runs quietly in the menu bar
- **WebKit Automation**: Uses native Swift WebKit (WKWebView) for robust, native web automation
- **Modern SwiftUI Interface**: Beautiful, responsive UI for configuration management
- **Automated Scheduling**: Schedules automatic runs based on configured time slots
- **Multiple Configurations**: Support for different sports and facilities
- **Secure Storage**: Keychain integration for secure credential storage
- **Email Verification**: Automated email verification for reservation confirmations (IMAP and Gmail)
- **Anti-Detection**: Advanced human-like behavior simulation to avoid bot detection

## 📦 Installation

1. **Download the latest release**:

   - Go to the [Releases page](https://github.com/Amet13/ODYSSEY/releases) on GitHub.
   - Download the latest `.dmg` installer for your macOS version.

2. **Install the app**:

   - Open the downloaded `.dmg` file.
   - Drag the ODYSSEY app to your `Applications` folder.
   - Eject the ODYSSEY disk image.

3. **Launch ODYSSEY**:

   - Open your `Applications` folder and double-click ODYSSEY.
   - The app will appear in your menu bar (top right of your screen).

4. **Initial Setup**:
   - Click the ODYSSEY menu bar icon.
   - Add your reservation configurations and contact information.
   - Set up your email (IMAP or Gmail) for verification codes.
   - Test your email connection in Settings.
   - You're ready to automate your bookings!

---

### For Developers

See [DEVELOPMENT.md](Documentation/DEVELOPMENT.md) for build and development setup instructions.

## 🎯 Usage

### Basic Configuration

1. **Add a Reservation Configuration**:

   - Click the ODYSSEY menu bar icon
   - Click "Add Configuration"
   - Fill in the facility URL, sport name, and time slots
   - Configure contact information

2. **Set Up Contact Data**:

   - Enter your phone, name
   - Enter your IMAP/Gmail settings
   - Test Email connection

3. **Run Reservations**:

   - **Manual Run**: Click "Run Now" for immediate execution
   - **Automatic**: Will be executed exactly at 6PM, 2 days prior to the event

4. **Browser Windows**:

- During the reservations you will see browser windows that run automation, they are visible to avoid captcha detection and ensure that reservation works

### Logs

View detailed logs in Console.app:

- Filter by subsystem: `com.odyssey.app`
- Look for emoji indicators for quick status identification

## 🤝 Contributing

See [CONTRIBUTING.md](Documentation/CONTRIBUTING.md) for detailed contribution guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
