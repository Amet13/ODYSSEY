<div align="center">
  <img src="logo.svg" alt="ODYSSEY Logo" width="120" height="120">
  <h1>ODYSSEY</h1>
  <p><strong>Ottawa Drop-in Your Sports & Schedule Easily Yourself</strong></p>
  <p>
    <a href="https://github.com/Amet13/ODYSSEY/actions/workflows/ci.yml">
      <img src="https://github.com/Amet13/ODYSSEY/actions/workflows/ci.yml/badge.svg" alt="CI Status">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/releases">
      <img src="https://img.shields.io/github/v/release/Amet13/ODYSSEY?label=version" alt="Latest Release">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
    </a>
    <a href="https://github.com/Amet13/ODYSSEY/issues">
      <img src="https://img.shields.io/badge/Support-GitHub%20Issues-orange" alt="GitHub Issues">
    </a>
  </p>
</div>

---

# 🚀 Quick Start

1. **Download** the latest `.dmg` from the [Releases page](https://github.com/Amet13/ODYSSEY/releases).
2. **Install**: Open the `.dmg`, drag ODYSSEY to `Applications`.
3. **Launch**: Find ODYSSEY in your menu bar (top right).
4. **Configure**: Click the icon, add your reservation details, and set up email for verification.
5. **Automate!** Sit back and let ODYSSEY book your sports for you! 🎉

---

# ✨ Features

| Feature                     | Description                                                     |
| --------------------------- | --------------------------------------------------------------- |
| 🖥️ Native macOS Integration | Runs quietly in the menu bar, not the Dock                      |
| 🛡️ WebKit Automation        | Uses native Swift WebKit (WKWebView) for robust automation      |
| 🎨 Modern SwiftUI Interface | Beautiful, responsive UI for easy configuration                 |
| ⏰ Automated Scheduling     | Schedules runs based on your configured time slots              |
| ⚙️ Multiple Configurations  | Supports different sports and facilities                        |
| 🔒 Secure Storage           | Keychain integration for credentials                            |
| 📧 Email Verification       | Automated IMAP/Gmail verification for reservation confirmations |
| 🕵️‍♂️ Anti-Detection           | Human-like automation to avoid bot detection                    |
| 🪟 Debug Window             | Live browser window for transparency and troubleshooting        |
| 📊 Emoji Logging            | All logs use emoji for quick status identification              |

---

# 🏗️ Architecture

```mermaid
flowchart TD
    App["ODYSSEYApp (SwiftUI @main)"] -->|launches| AppDelegate
    AppDelegate -->|creates| StatusBarController
    AppDelegate -->|schedules| ReservationOrchestrator
    StatusBarController -->|shows| ContentView
    ContentView -->|binds| ConfigurationManager
    ContentView -->|binds| UserSettingsManager
    ContentView -->|binds| ReservationOrchestrator
    ContentView -->|binds| ReservationStatusManager
    ContentView -->|binds| LoadingStateManager
    ReservationOrchestrator -->|uses| WebKitService
    ReservationOrchestrator -->|uses| FacilityService
    ReservationOrchestrator -->|uses| EmailService
    ReservationOrchestrator -->|uses| KeychainService
    WebKitService -->|injects| JavaScriptService
    EmailService -->|uses| KeychainService
    EmailService -->|uses| IMAPService
    FacilityService -->|scrapes| WebKitService
    UserSettingsManager -->|stores| KeychainService
    ConfigurationManager -->|stores| UserDefaults
    UserSettingsManager -->|stores| UserDefaults
    LoadingStateManager -->|notifies| ContentView
    ValidationService -->|validates| all
    AppConstants -->|provides| all
```

If the diagram above does not render, see [architecture.png](Documentation/Images/architecture.png).

---

# 📦 Installation

1. **Download the latest release**:
   - Go to the [Releases page](https://github.com/Amet13/ODYSSEY/releases).
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
   - You're ready to automate your bookings! 🎾

---

# 🎯 Usage

## 1️⃣ Add a Reservation Configuration

- Click the ODYSSEY menu bar icon
- Click **Add Configuration**
- Fill in the facility URL, sport name, and time slots
- Configure your contact information

## 2️⃣ Set Up Contact Data

- Enter your phone and name
- Enter your IMAP/Gmail settings
- Test your email connection

## 3️⃣ Run Reservations

- **Manual Run**: Click **Run Now** for immediate execution
- **Automatic**: Runs at 6PM, 2 days before your event

## 4️⃣ Browser Windows

> ⚠️ **Important:**
> To avoid Google reCAPTCHA and other anti-bot detection, browser windows must remain visible during automation. Hiding or minimizing these windows may increase the risk of being flagged as a bot and cause reservations to fail. The automation simulates real user activity in a visible window for maximum reliability.

---

# 📊 Logs & Debugging

- View detailed logs in **Console.app**:
  - Filter by subsystem: `com.odyssey.app`
  - Look for emoji indicators for quick status identification
- All sensitive data is masked or marked as private in logs

---

# 🛠️ Troubleshooting & FAQ

## Common Issues

### ❌ Automation fails with reCAPTCHA or bot detection

- Ensure browser windows remain visible during automation (do not minimize or hide)
- Try running the app at a different time or with a different network
- Make sure your configuration matches the facility's current website structure

### 📧 Email verification not working

- Double-check your IMAP/Gmail credentials and App Password (for Gmail)
- Test your email connection in Settings
- Check for typos in your email address or server
- For Gmail, ensure 2FA is enabled and you are using an App Password

### 🔒 Keychain or credential errors

- If you see a Keychain error banner, try re-entering your credentials in Settings
- Make sure you have granted Keychain access to ODYSSEY
- Restart the app after updating credentials

### 🕵️‍♂️ App does not appear in menu bar

- Ensure you are running macOS 15.0 or later
- Check that the app is not running in the Dock (it should only appear in the menu bar)

### 📝 Logs not showing in Console.app

- Search for `ODYSSEY` or `com.odyssey.app` in Console
- Make sure logging is enabled in your system settings

## Where to Get Help

- [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
- See the [full documentation](Documentation/DEVELOPMENT.md) for advanced troubleshooting

---

# 🤝 Contributing

See [CONTRIBUTING.md](Documentation/CONTRIBUTING.md) for detailed contribution guidelines.

---

# 🛡️ Security & Compliance

- 🔒 Credentials are securely stored in the macOS Keychain—never in plain text or UserDefaults
- 🌐 All network requests use HTTPS; App Transport Security (ATS) is strictly enforced
- 📝 The app is code signed for distribution, but is **not notarized by Apple** (no Apple Developer account). To enable notarization, see [DEVELOPMENT.md](Documentation/DEVELOPMENT.md) and `Scripts/create-release.sh`
- 🚫 No user data is ever sent externally without your explicit consent. All automation runs locally
- See [DEVELOPMENT.md](Documentation/DEVELOPMENT.md) for full security and compliance details

---

# 💬 Support

- [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)

---

# 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

# 🏓 About ODYSSEY (In-App Help)

ODYSSEY is a native macOS menu bar application that automates sports reservation bookings for Ottawa Recreation facilities.

**Key Features:**

- 🏸 Automated reservation booking
- ⏰ Smart scheduling system
- 🛡️ Native WebKit automation
- 📧 Email verification support
- ⚙️ Multiple configuration support

For more information, visit the [project homepage](https://github.com/Amet13/ODYSSEY).
