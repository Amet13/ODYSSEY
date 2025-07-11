# ODYSSEY Development Guide

## 🚀 Getting Started

### Prerequisites

- **macOS 12.0** or later
- **Xcode 14.0** or later
- **Swift 5.7** or later
- **XcodeGen** (for project generation)
- **Google Chrome** (for automation)
- **ChromeDriver** (install with `brew install chromedriver`)
- **System Permissions:**
  - You must add **ChromeDriver** to **System Settings > Privacy & Security > Full Disk Access** (and/or **Automation/Accessibility**) for automation to work on macOS. Without this, ChromeDriver may not be able to control Chrome or may be killed by the system.

### Quick Start

1. **Clone and setup the project:**

   ```bash
   git clone https://github.com/Amet13/ODYSSEY.git
   cd ODYSSEY
   brew install xcodegen
   xcodegen
   ```

2. **Build and run:**

   ```bash
   ./build.sh
   ```

3. **Or use Xcode:**
   - Open `ODYSSEY.xcodeproj`
   - Press `Cmd+R` to build and run
   - The app will appear in your menu bar

## 🏗️ Project Architecture

### Core Components

```
Sources/
├── Models/
│   └── ReservationConfig.swift    # Data models and enums
├── App/ODYSSEYApp.swift          # Main app entry point
├── Views/Main/ContentView.swift  # Main UI interface
├── Views/ConfigurationDetailView.swift # Configuration editor
├── Controllers/StatusBarController.swift # Menu bar integration
├── Services/ReservationManager.swift # Web automation logic
├── Services/FacilityService.swift # Web scraping and facility data
├── Services/Configuration.swift  # Settings persistence
└── Resources/Info.plist          # App metadata
```

### Architecture Overview

#### 1. **ConfigurationManager** - Settings and Data Management

- **Purpose**: Manages user preferences and configurations
- **Key Features**:
  - Persists settings using `UserDefaults`
  - Provides CRUD operations for configurations
  - Handles scheduling logic and autorun calculations
  - Manages enabled/disabled states

#### 2. **ReservationManager** - Web Automation Engine

- **Purpose**: Handles web automation and reservation booking
- **Key Features**:
  - Uses `WKWebView` for web interaction
  - Injects JavaScript for form automation
  - Manages reservation attempts and retries
  - Handles different page states and navigation

#### 3. **StatusBarController** - Menu Bar Integration

- **Purpose**: Manages the menu bar item and popover
- **Key Features**:
  - Creates and manages the status bar item
  - Handles popover display and positioning
  - Monitors global events and app state
  - Provides menu bar interface

#### 4. **FacilityService** - Web Scraping

- **Purpose**: Extracts facility and sport information
- **Key Features**:
  - Scrapes available sports from facility pages
  - Handles dynamic content loading
  - Provides sport selection interface

#### 5. **SwiftUI Views** - Modern UI Components

- **ContentView**: Main configuration interface
- **ConfigurationDetailView**: Detailed settings editor
- **LogsView**: Built-in logging interface

## 🔧 Development Guidelines

### Code Style

#### SwiftUI Best Practices

```swift
// ✅ Good: Use private extensions for organization
private extension ContentView {
    var headerView: some View {
        HStack {
            // Header content
        }
    }
}

// ✅ Good: Use computed properties for derived state
private var canRunAll: Bool {
    configManager.isAnyConfigurationEnabled() && !reservationManager.isRunning
}

// ✅ Good: Separate concerns with focused views
struct ConfigurationRowView: View {
    let config: ReservationConfig
    let onEdit: () -> Void

    var body: some View {
        HStack {
            configurationInfoView
            Spacer()
            actionButtonsView
        }
    }

    private var configurationInfoView: some View {
        // Configuration info
    }
}
```

#### Error Handling

```swift
// ✅ Good: Use Result types for async operations
func fetchSports() async -> Result<[Sport], Error> {
    do {
        let sports = try await webView.evaluateJavaScript(script)
        return .success(sports)
    } catch {
        return .failure(error)
    }
}

// ✅ Good: Provide meaningful error messages
enum ReservationError: LocalizedError {
    case networkError(String)
    case noSlotsAvailable
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .noSlotsAvailable:
            return "No available slots found"
        case .invalidConfiguration:
            return "Invalid configuration"
        }
    }
}
```

### Adding New Features

#### 1. New Configuration Options

Edit `ReservationConfig.swift`:

```swift
struct ReservationConfig: Codable, Identifiable {
    // Add new properties here
    var newFeature: String = ""
    var advancedSettings: AdvancedSettings = AdvancedSettings()

    // Update the initializer
    init(name: String, facilityURL: String, sportName: String,
         newFeature: String = "", advancedSettings: AdvancedSettings = AdvancedSettings()) {
        self.newFeature = newFeature
        self.advancedSettings = advancedSettings
        // ... other properties
    }
}

struct AdvancedSettings: Codable {
    var retryCount: Int = 3
    var timeoutInterval: TimeInterval = 30.0
}
```

#### 2. Enhanced Web Automation

Extend `ReservationManager.swift`:

```swift
private func injectAutomationScript() {
    let script = """
    // Add your custom JavaScript here
    function customAutomation() {
        // Your automation logic
        console.log('Custom automation running...');

        // Example: Wait for elements to load
        return new Promise((resolve) => {
            const checkElement = () => {
                const element = document.querySelector('.target-element');
                if (element) {
                    resolve(true);
                } else {
                    setTimeout(checkElement, 100);
                }
            };
            checkElement();
        });
    }
    """

    webView?.evaluateJavaScript(script) { result, error in
        if let error = error {
            NSLog("ODYSSEY: JavaScript error: \(error)")
        }
    }
}
```

#### 3. New UI Components

Create new SwiftUI views:

```swift
struct NewFeatureView: View {
    @State private var isEnabled = false
    @State private var selectedOption = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Feature")
                .font(.headline)

            Toggle("Enable Feature", isOn: $isEnabled)

            if isEnabled {
                Picker("Option", selection: $selectedOption) {
                    Text("Option 1").tag("option1")
                    Text("Option 2").tag("option2")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
```

### Web Automation Customization

The app uses WebKit for web automation. To customize for specific websites:

#### 1. Analyze the Target Website

```bash
# Use browser developer tools to:
# - Identify form elements and buttons
# - Note any dynamic content loading
# - Check for AJAX requests
# - Understand the page flow
```

#### 2. Update JavaScript Injection

```swift
private func injectAutomationScript() {
    let script = """
    // Custom selectors for your target website
    const selectors = {
        sport: 'select[name="sport"], .sport-dropdown',
        date: 'input[name="date"], .date-picker',
        time: 'select[name="time"], .time-slot',
        submit: 'button[type="submit"], .book-button',
        login: 'input[name="username"], input[name="password"]'
    };

    // Custom automation logic
    function bookReservation(config) {
        return new Promise(async (resolve, reject) => {
            try {
                // Wait for page to load
                await waitForElement(selectors.sport);

                // Fill form
                await fillForm(config);

                // Submit
                await submitForm();

                resolve(true);
            } catch (error) {
                reject(error);
            }
        });
    }

    function waitForElement(selector, timeout = 5000) {
        return new Promise((resolve, reject) => {
            const startTime = Date.now();

            const check = () => {
                const element = document.querySelector(selector);
                if (element) {
                    resolve(element);
                } else if (Date.now() - startTime > timeout) {
                    reject(new Error(`Element not found: ${selector}`));
                } else {
                    setTimeout(check, 100);
                }
            };

            check();
        });
    }
    """
}
```

#### 3. Handle Different Page States

```swift
private func handlePageLoaded(_ data: [String: Any]) {
    guard let url = data["url"] as? String else { return }

    // Route to different handlers based on URL
    if url.contains("login") {
        handleLoginPage()
    } else if url.contains("booking") {
        handleBookingPage()
    } else if url.contains("confirmation") {
        handleConfirmationPage()
    } else {
        NSLog("ODYSSEY: Unknown page type: \(url)")
    }
}

private func handleLoginPage() {
    // Handle login page automation
    let loginScript = """
    // Login automation logic
    """
    webView?.evaluateJavaScript(loginScript)
}
```

## 🧪 Testing

### Unit Tests

Create tests in `ODYSSEYTests/`:

```swift
import XCTest
@testable import ODYSSEY

class ConfigurationManagerTests: XCTestCase {
    var manager: ConfigurationManager!

    override func setUp() {
        super.setUp()
        manager = ConfigurationManager.shared
        // Clear test data
        UserDefaults.standard.removeObject(forKey: "ODYSSEY_Settings")
    }

    func testAddConfiguration() {
        let config = ReservationConfig(
            name: "Test Config",
            facilityURL: "https://test.com",
            sportName: "Basketball"
        )

        manager.addConfiguration(config)
        XCTAssertEqual(manager.settings.configurations.count, 1)
        XCTAssertEqual(manager.settings.configurations.first?.name, "Test Config")
    }

    func testToggleConfiguration() {
        let config = ReservationConfig(
            name: "Test Config",
            facilityURL: "https://test.com",
            sportName: "Basketball"
        )

        manager.addConfiguration(config)
        XCTAssertTrue(manager.settings.configurations.first?.isEnabled ?? false)

        manager.toggleConfigurationEnabled(config)
        XCTAssertFalse(manager.settings.configurations.first?.isEnabled ?? true)
    }
}

class ReservationManagerTests: XCTestCase {
    func testCronTimeCalculation() {
        let manager = ReservationManager.shared
        let config = ReservationConfig(
            name: "Test",
            facilityURL: "https://test.com",
            sportName: "Basketball"
        )

        // Test cron time calculation logic
        // Add your test cases here
    }
}
```

### Manual Testing

#### 1. Configuration Testing

- Add test configurations with various settings
- Verify persistence across app restarts
- Test scheduling logic with different time zones
- Verify autorun calculations

#### 2. Web Automation Testing

- Use test URLs first (create mock pages)
- Monitor network requests in Console
- Check for successful form submissions
- Test error handling and retry logic

#### 3. UI Testing

- Test all interactive elements
- Verify hover effects and animations
- Test responsive design on different screen sizes
- Verify accessibility features

## 📦 Deployment

### Code Signing

#### 1. Developer ID

```bash
# Build for distribution
xcodebuild archive \
    -project ODYSSEY.xcodeproj \
    -scheme ODYSSEY \
    -archivePath ODYSSEY.xcarchive

# Export for distribution
xcodebuild -exportArchive \
    -archivePath ODYSSEY.xcarchive \
    -exportPath ODYSSEY-Export \
    -exportOptionsPlist exportOptions.plist
```

#### 2. Notarization

```bash
# Notarize the app
xcrun notarytool submit ODYSSEY-Export/ODYSSEY.app \
    --wait \
    --keychain-profile "AC_PASSWORD"
```

### Distribution Options

#### Direct Distribution

- Share the `.app` bundle directly
- Users can drag to Applications folder
- Requires manual security approval

#### DMG Creation

```bash
# Install create-dmg
brew install create-dmg

# Create DMG
create-dmg \
    --volname "ODYSSEY" \
    --window-pos 200 120 \
    --window-size 600 300 \
    --icon-size 100 \
    --icon "ODYSSEY.app" 175 120 \
    --hide-extension "ODYSSEY.app" \
    --app-drop-link 425 120 \
    "ODYSSEY.dmg" \
    "ODYSSEY-Export/"
```

#### App Store

- Follow Apple's guidelines for Mac App Store submission
- Requires App Store Connect setup
- Review process required

## 🐛 Troubleshooting

### Common Issues

#### 1. App doesn't appear in menu bar

**Symptoms**: App launches but no menu bar icon
**Solutions**:

- Check `LSUIElement` in Info.plist is set to `true`
- Verify `NSApp.setActivationPolicy(.accessory)` in AppDelegate
- Check for permission issues in System Preferences

#### 2. Web automation fails

**Symptoms**: Automation runs but doesn't complete booking
**Solutions**:

- Check website structure changes
- Verify JavaScript injection is working
- Monitor console logs for errors
- Test with manual browser automation

#### 3. Scheduling doesn't work

**Symptoms**: Configurations don't run automatically
**Solutions**:

- Verify timer setup in AppDelegate
- Check weekday conversion logic
- Test with manual triggers
- Verify time zone handling

### Debug Mode

Enable detailed logging:

```swift
// In ConfigurationManager
settings.logLevel = .debug

// In ReservationManager
NSLog("ODYSSEY: Debug message here")

// Check Console app for logs
// Filter by "ODYSSEY" to see only app logs
```

### Performance Monitoring

```swift
// Add performance monitoring
import os.log

private let performanceLog = OSLog(subsystem: "com.odyssey.app", category: "performance")

func measurePerformance<T>(_ operation: String, block: () throws -> T) rethrows -> T {
    let start = CFAbsoluteTimeGetCurrent()
    let result = try block()
    let end = CFAbsoluteTimeGetCurrent()

    os_log("Operation '%{public}@' took %{public}f seconds",
           log: performanceLog, type: .info, operation, end - start)

    return result
}
```

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes** following the coding guidelines
4. **Add tests** for new functionality
5. **Update documentation** as needed
6. **Commit your changes** with descriptive messages
7. **Push to the branch** (`git push origin feature/amazing-feature`)
8. **Open a Pull Request**

### Commit Message Guidelines

```
feat: add new configuration option for retry attempts
fix: resolve scheduling issue with timezone handling
docs: update README with new feature documentation
test: add unit tests for ConfigurationManager
refactor: improve web automation error handling
```

### Code Review Process

1. **Self-review** your changes before submitting
2. **Ensure tests pass** locally
3. **Update documentation** for any new features
4. **Request review** from maintainers
5. **Address feedback** and iterate if needed

## 📚 Resources

### Documentation

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit/)
- [WebKit Documentation](https://developer.apple.com/documentation/webkit/)

### Tools

- [XcodeGen](https://github.com/yonaskolb/XcodeGen) - Project generation
- [create-dmg](https://github.com/create-dmg/create-dmg) - DMG creation
- [SwiftLint](https://github.com/realm/SwiftLint) - Code style enforcement

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

**Happy coding! 🚀**

## Code Formatting

ODYSSEY uses [swiftformat](https://github.com/nicklockwood/SwiftFormat) for automatic Swift code formatting.

- All code is auto-formatted before every build (see `Scripts/build.sh`).
- To format manually, run:

```sh
swiftformat .
```

- If you don't have swiftformat, install it with:

```sh
brew install swiftformat
```

- Formatting is enforced for all contributions. Please ensure your code is formatted before submitting a PR.
