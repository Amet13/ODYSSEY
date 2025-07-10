# ORRMAT - Ottawa Recreation Reservation macOS Automation Tool

A sophisticated macOS menu bar application that automates sports reservation bookings for Ottawa Recreation facilities. ORRMAT runs quietly in the background and automatically books your preferred sports slots at the optimal time.

## 🚀 Features

- 🖥️ **Native macOS Menu Bar Integration** - Sits quietly in the menu bar without cluttering your dock
- ⏰ **Smart Scheduling** - Automatically runs 2 days before your desired reservation time at 6:00 PM
- ⚙️ **Easy Configuration** - Intuitive SwiftUI interface for setting up reservations
- 🤖 **Web Automation** - Automatically navigates and books slots using WebKit
- 📱 **Modern UI** - Clean, native macOS interface with hover effects and smooth animations
- 🔄 **Multiple Configurations** - Set up different sports, facilities, and time slots
- 📊 **Real-time Status** - See countdown to next autorun and current status
- 📝 **Built-in Logs** - View automation logs directly in the app
- 🎯 **Flexible Scheduling** - Choose specific days and multiple time slots per day
- 🔍 **Advanced Logging** - Comprehensive logging with os.log for debugging
- 🛡️ **Code Quality** - SwiftLint integration and best practices enforcement

## 📋 Requirements

- **macOS 12.0** or later
- **Xcode 14.0** or later (for development)
- **Swift 5.7** or later

## 🛠️ Installation & Setup

### For Users

1. **Download the latest release** from the releases page
2. **Drag ORRMAT.app to Applications**
3. **Launch the app** - it will appear in your menu bar
4. **Configure your reservations** by clicking the menu bar icon

### For Developers

#### 1. Prerequisites

```bash
# Install XcodeGen (if not already installed)
brew install xcodegen

# Install SwiftLint for code quality (optional but recommended)
brew install swiftlint
```

#### 2. Clone and Setup

```bash
git clone https://github.com/yourusername/orrmat.git
cd orrmat
```

#### 3. Generate Xcode Project

```bash
xcodegen
```

#### 4. Build and Run

```bash
# Quick build and run
./build.sh

# Or open in Xcode
open ORRMAT.xcodeproj
```

## 🏗️ Project Structure

```
orrmat/
├── ORRMAT.xcodeproj/              # Xcode project (auto-generated)
├── ORRMAT/
│   ├── ORRMATApp.swift            # Main app entry point
│   ├── ContentView.swift          # Main configuration interface
│   ├── ConfigurationDetailView.swift # Configuration editor
│   ├── StatusBarController.swift  # Menu bar integration
│   ├── ReservationManager.swift   # Web automation engine
│   ├── FacilityService.swift      # Web scraping and facility data
│   ├── Configuration.swift        # Settings and preferences
│   ├── Models/
│   │   └── ReservationConfig.swift # Data models
│   └── Info.plist                 # App metadata
├── project.yml                    # XcodeGen project specification
├── .swiftlint.yml                 # SwiftLint configuration
├── build.sh                       # Build and run script
├── README.md                      # This file
├── DEVELOPMENT.md                 # Developer guide
├── CONTRIBUTING.md                # Contribution guidelines
├── CHANGELOG.md                   # Version history
└── LICENSE                        # MIT License
```

## ⚙️ Configuration

### Basic Setup

1. **Launch ORRMAT** - Click the menu bar icon
2. **Add Configuration** - Click the "+" button
3. **Enter Facility URL** - Paste your Ottawa Recreation facility URL
4. **Select Sport** - Choose from available sports at the facility
5. **Set Number of People** - Choose 1-4 people
6. **Configure Schedule** - Select days and time slots
7. **Enable Configuration** - Toggle the switch to activate

### Advanced Features

- **Multiple Configurations** - Set up different sports and facilities
- **Custom Scheduling** - Choose specific weekdays and multiple time slots
- **Auto-generated Names** - Configuration names are automatically generated
- **Real-time Status** - See countdown to next autorun
- **Manual Execution** - Run configurations immediately with the "Run" button
- **Built-in Logging** - View detailed logs within the app

## 🔧 How It Works

### Automation Process

1. **Scheduling** - ORRMAT calculates the optimal booking time (2 days before at 6:00 PM)
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

**Scheduling issues:**

- Ensure configurations are enabled
- Check that time slots are configured
- Verify the countdown timer in the status

### Debug Mode

Enable detailed logging by checking the Console app for messages from subsystem "com.orrmat.app"

## 🧪 Development

### Code Quality

The project uses SwiftLint to enforce code quality standards:

```bash
# Run SwiftLint manually
swiftlint lint

# Auto-fix some issues
swiftlint --fix
```

### Logging

The app uses `os.log` for comprehensive logging:

- **Info level** - General application flow
- **Debug level** - Detailed debugging information
- **Warning level** - Potential issues
- **Error level** - Errors and failures

### Testing

```bash
# Build and test
xcodebuild test -project ORRMAT.xcodeproj -scheme ORRMAT

# Run specific tests
xcodebuild test -project ORRMAT.xcodeproj -scheme ORRMAT -only-testing:ORRMATTests/ConfigurationManagerTests
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed development guidelines.

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Development Guidelines

- Follow SwiftLint rules
- Use proper logging with `os.log`
- Write comprehensive tests
- Update documentation
- Follow SwiftUI best practices

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for the Ottawa sports community
- Inspired by the need for automated recreation booking
- Uses modern macOS development practices

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/orrmat/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/orrmat/discussions)
- **Email**: support@orrmat.app

---

**Made with ❤️ for the Ottawa sports community**
