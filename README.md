<div align="center">
  <img src="logo.svg" alt="ODYSSEY Logo" width="120" height="120">
  <h1>ODYSSEY</h1>
  <p><strong>Automated Sports Reservation Booking for Ottawa Recreation</strong></p>
  
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

# ODYSSEY

**Ottawa Drop-in Your Sports & Schedule Easily Yourself**

**Automate your Ottawa Recreation sports reservations with ease.**

ODYSSEY (Ottawa Drop-in Your Sports & Schedule Easily Yourself) is a native macOS menu bar application that automatically books your sports reservations at Ottawa Recreation facilities. No more refreshing pages or competing for time slots - ODYSSEY handles it all for you.

## ✨ What ODYSSEY Does

- **🎯 Automatic Booking**: Books your preferred time slots automatically
- **📅 Smart Scheduling**: Runs 2 days before your reservation to secure spots
- **🏀 Multi-Sport Support**: Basketball, volleyball, badminton, tennis, and more
- **🏢 Multi-Facility**: Works with all Ottawa Recreation facilities
- **🔔 Email Verification**: Handles verification codes automatically
- **📊 Real-time Status**: See booking status and next run times
- **🛡️ Privacy First**: Everything runs locally on your Mac

## 🚀 Quick Start

### 1. Build and Install

```bash
# Clone and build
git clone https://github.com/Amet13/ODYSSEY.git
cd ODYSSEY
./Scripts/build.sh
```

### 2. Configure Your Settings

1. **Open ODYSSEY** from your menu bar
2. **Click Settings** to configure your contact information
3. **Enter your details**:
   - Name
   - Phone number (10 digits)
   - Email address
   - Email password (Gmail users need an App Password)

### 3. Add Your First Reservation

1. **Click the + button** to add a new configuration
2. **Enter facility URL** (e.g., `https://reservation.frontdesksuite.ca/rcfs/your-facility`)
3. **Select your sport** from the dropdown
4. **Choose your preferred day and time**
5. **Save the configuration**

### 4. Let ODYSSEY Work

- ODYSSEY will automatically run 2 days before your reservation
- Check the status in the menu bar app
- Receive confirmation when booking is successful

## 🎯 Supported Sports & Facilities

**Sports**: Basketball, Volleyball, Badminton, Tennis, Soccer, Hockey, Swimming, Fitness, and more

**Facilities**: All Ottawa Recreation facilities using the FrontDesk Suite reservation system

## ⚙️ Configuration Options

### Multiple Reservations

- Create separate configurations for different sports
- Set different time preferences for each
- Enable/disable configurations as needed

### Scheduling

- ODYSSEY runs automatically at 6:00 PM, 2 days before your reservation
- Manual runs available for immediate booking
- Real-time countdown to next automatic run

### Email Integration

- Automatic verification code handling
- Supports Gmail and other IMAP providers
- Secure password storage

## 🔧 Troubleshooting

### Common Issues

**Booking not working?**

- Check your facility URL is correct
- Verify your contact information is complete
- Ensure the sport name matches exactly
- Check the app logs for detailed error messages

**Email verification failing?**

- Gmail users: Use an App Password, not your regular password
- Enable IMAP in your email settings
- Verify email server settings

**App not appearing in menu bar?**

- Check Activity Monitor for running instances
- Restart the app if needed
- Ensure no other instances are running

### Getting Help

- **App Logs**: Check Console.app → search for "ODYSSEY"
- **GitHub Issues**: Report bugs and request features
- **Debug Mode**: Built-in troubleshooting tools

## 🛡️ Privacy & Security

- **Local Processing**: All automation runs on your Mac
- **No Data Sharing**: Your information stays private
- **Standard Permissions**: No special access required
- **Secure Storage**: Encrypted local configuration

## 📱 System Requirements

- **macOS**: 15.0 or later
- **Storage**: 10MB free space
- **Network**: Internet connection for booking
- **Permissions**: Standard app permissions only

## 🤝 Contributing

Help improve ODYSSEY! See [Contributing Guidelines](Documentation/CONTRIBUTING.md) for details.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 📚 Documentation

- [User Guide](Documentation/USER_GUIDE.md) - Complete user instructions
- [Development Guide](Documentation/DEVELOPMENT.md) - For developers
- [Changelog](Documentation/CHANGELOG.md) - Release notes
- [Contributing](Documentation/CONTRIBUTING.md) - How to contribute

---

**Made with ❤️ for the Ottawa sports community**
