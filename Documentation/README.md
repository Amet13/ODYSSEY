# 🚀 ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself

**ODYSSEY** is a sophisticated dual-interface application that automates sports reservation bookings for Ottawa Recreation facilities.

## 🎯 Overview

ODYSSEY provides both GUI and CLI versions:

- **🖥️ GUI Version**: Native macOS menu bar app with SwiftUI interface
- **💻 CLI Version**: Command-line interface for remote automation

Both versions share the same backend services and automation engine.

## 🚀 Quick Start

### For Users

1. **Download**: Get the latest release from [GitHub Releases](https://github.com/Amet13/ODYSSEY/releases)
2. **Install**:
   - GUI: Download `ODYSSEY.app` and drag to Applications
   - CLI: Download `odyssey-cli` and make executable: `chmod +x odyssey-cli`
3. **Configure**: Set up your email and reservation preferences
4. **Run**: Start automating your sports reservations!

### For Developers

```bash
# Clone and setup
git clone https://github.com/Amet13/ODYSSEY.git
cd ODYSSEY
./Scripts/setup-dev.sh

# Build and run
./Scripts/build.sh
```

## 📋 System Requirements

- **macOS 15.0 or later**
- **Xcode 16.0 or later** (for development)
- **Swift 6.1 or later** (for development)

## 🔧 Features

### 🖥️ GUI Application

- Native macOS menu bar integration
- Smart scheduling system
- Easy configuration interface
- Native WebKit automation (no ChromeDriver required)
- Multiple configurations
- Real-time status
- Built-in logs with emoji indicators
- Secure credential storage (Keychain)
- Automated email verification (IMAP/Gmail)
- Anti-detection (human-like automation)
- Step-by-step reservation progress
- Comprehensive error handling and cleanup

### 💻 CLI Tool

- Command-line interface for remote automation
- Parallel execution of multiple reservations
- Headless mode (no browser window)
- CI/CD pipeline integration
- Real-time progress tracking
- Same WebKit automation as GUI
- Secure token-based configuration
- Comprehensive logging and error handling
- Pre-built binary (no extraction needed)

## 📚 Documentation

- **[Installation Guide](INSTALLATION.md)** - Detailed installation instructions
- **[User Guide](USER_GUIDE.md)** - Complete user manual
- **[CLI Guide](CLI.md)** - Command-line interface documentation
- **[Development Guide](DEVELOPMENT.md)** - Developer setup and contribution guidelines
- **[Scripts Guide](SCRIPTS.md)** - Automation scripts documentation

## 🛡️ Security & Privacy

- **Local Processing**: All automation runs locally on your machine
- **User Consent**: Explicit permission required for all external integrations
- **Data Privacy**: No user data transmitted without consent
- **Secure Connections**: HTTPS and App Transport Security
- **Input Validation**: All user inputs validated and sanitized

## 🐛 Support

- [Report Issues](https://github.com/Amet13/odyssey/issues)
- [View Releases](https://github.com/Amet13/odyssey/releases)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for the Ottawa sports community**
