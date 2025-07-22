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

## 🖼️ Screenshots

<!-- Add your screenshot(s) here -->

![ODYSSEY Screenshot](docs/screenshot.png)

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

> **Important:**
> To avoid Google reCAPTCHA and other anti-bot detection, browser windows must remain visible during automation. Hiding or minimizing these windows may increase the risk of being flagged as a bot and cause reservations to fail. The automation simulates real user activity in a visible window for maximum reliability.

### Logs

View detailed logs in Console.app:

- Filter by subsystem: `com.odyssey.app`
- Look for emoji indicators for quick status identification

## 📝 How to Check Logs

- Open **Console.app** (in Applications > Utilities)
- Search for `ODYSSEY` or `com.odyssey.app`
- Look for log messages with emojis for quick status identification
- Sensitive data is masked or marked as private in logs

## 🐞 How to Report Bugs

1. Go to [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
2. Click 'New Issue' and use the bug report template
3. Include:
   - Steps to reproduce
   - Expected vs actual behavior
   - macOS version, ODYSSEY version, Xcode version
   - Relevant logs (from Console.app)
   - Screenshots if possible

---

## 🤝 Contributing

See [CONTRIBUTING.md](Documentation/CONTRIBUTING.md) for detailed contribution guidelines.

## 🛡️ Security & Compliance

- Credentials are securely stored in the macOS Keychain—never in plain text or UserDefaults.
- All network requests use HTTPS; App Transport Security (ATS) is strictly enforced.
- The app is code signed for distribution, but is **not notarized by Apple** (no Apple Developer account). To enable notarization, see DEVELOPMENT.md and Scripts/create-release.sh.
- No user data is ever sent externally without your explicit consent. All automation runs locally.
- See [DEVELOPMENT.md](Documentation/DEVELOPMENT.md) for full security and compliance details.

## 💬 Support

- [GitHub Issues](https://github.com/Amet13/ODYSSEY/issues)
- [GitHub Discussions](https://github.com/Amet13/ODYSSEY/discussions)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## How to Add a New Sport, Facility, or Configuration

ODYSSEY is designed for easy expansion. To add support for a new sport, facility, or reservation configuration:

### 1. Update Sport Keywords (if needed)

- Edit `Sources/Utils/AppConstants.swift` and add your new sport to the `sportsKeywords` array.
- This ensures the UI and icon mapping recognize the new sport.

### 2. Add or Update Facility URLs

- In the app UI, add a new configuration and enter the facility URL for the new location.
- If the facility uses a new URL pattern, update the validation logic in `ValidationService.swift` as needed.

### 3. Test Facility Scraping

- The app uses `FacilityService` and JavaScript scraping to detect available sports at each facility.
- If the new facility has a unique page structure, update the detection script in `JavaScriptService.swift` (see `generateAntiDetectionScript` and related methods).

### 4. Add/Update Icons (Optional)

- To add a custom icon for your new sport, update `SportIconMapper.swift`.

### 5. Validate Your Addition

- Use the app UI to create a new configuration for your sport/facility.
- Run a test reservation and ensure:
  - The sport is detected and selectable.
  - The reservation flow completes without errors.
  - The correct icon and name appear in the UI.

### 6. Write/Update Tests (Recommended)

- If you add new scraping or validation logic, add or update tests in the relevant service (e.g., `FacilityService`, `ValidationService`).

### 7. Document Your Change

- Update this README and any relevant documentation to describe the new sport/facility/configuration.

**Best Practices:**

- Keep all new keywords, URLs, and logic centralized in the appropriate constants/services.
- Test thoroughly with real facility pages.
- Use the modular JavaScriptService for any new scraping or anti-detection logic.
- Submit a pull request with a clear description of your addition.
