# ODYSSEY Development Guide

## 🚀 Getting Started

### Prerequisites

- **macOS 15.0** or later
- **Xcode 16.0** or later
- **Swift 6.0** or later
- **XcodeGen** (for project generation)
- **SwiftLint** (for code quality)
- **SwiftFormat** (for code formatting)
- **Google Chrome** (for automation)
- **ChromeDriver** (install with `brew install chromedriver`)
- **System Permissions:**
  - You must add **ChromeDriver** to **System Settings > Privacy & Security > Full Disk Access** (and/or **Automation/Accessibility**) for automation to work on macOS. Without this, ChromeDriver may not be able to control Chrome or may be killed by the system.

### Quick Start

1. **Clone and setup the project:**

   ```bash
   git clone https://github.com/Amet13/ODYSSEY.git
   cd ODYSSEY
   brew install xcodegen swiftlint swiftformat
   xcodegen
   ```

2. **Build and run:**

   ```bash
   ./Scripts/build.sh
   ```

3. **Or use Xcode:**
   - Open `Config/ODYSSEY.xcodeproj`
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

### Code Quality Standards

#### SwiftLint Configuration

ODYSSEY uses a comprehensive SwiftLint configuration (`.swiftlint.yml`) that enforces:

- **Code Style**: Consistent formatting and naming conventions
- **Best Practices**: Modern Swift patterns and anti-patterns
- **Documentation**: Public API documentation requirements
- **Performance**: Efficient code patterns
- **Security**: Safe coding practices

#### SwiftFormat Configuration

SwiftFormat (`.swiftformat`) ensures consistent code formatting:

- **Indentation**: 4 spaces, smart tabs enabled
- **Line Length**: 120 characters max
- **Import Organization**: Alphabetized and grouped
- **Spacing**: Consistent spacing rules

#### Pre-commit Checks

Before committing code:

```bash
# Format code
swiftformat Sources/

# Lint code
swiftlint lint --config .swiftlint.yml

# Build project
xcodebuild build -project Config/ODYSSEY.xcodeproj -scheme ODYSSEY -configuration Debug
```

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

#### Documentation Standards

All public APIs must be documented:

````swift
/// Manages web automation and reservation booking for Ottawa Recreation facilities
///
/// This service handles the complete automation workflow including:
/// - Web navigation and form interaction
/// - Sport selection and slot booking
/// - Error handling and retry logic
/// - Status reporting and logging
///
/// ## Usage
/// ```swift
/// let manager = ReservationManager.shared
/// await manager.runReservation(for: config)
/// ```
///
/// ## Thread Safety
/// This class is thread-safe and can be used from any dispatch queue.
class ReservationManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = ReservationManager()

    /// Runs a reservation for the specified configuration
    /// - Parameter config: The reservation configuration to execute
    /// - Returns: A result indicating success or failure with error details
    func runReservation(for config: ReservationConfig) async -> Result<Void, ReservationError> {
        // Implementation
    }
}
````

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
extension ReservationManager {
    /// Enhanced automation with retry logic
    func runReservationWithRetry(for config: ReservationConfig, maxRetries: Int = 3) async -> Result<Void, ReservationError> {
        for attempt in 1...maxRetries {
            let result = await runReservation(for: config)

            switch result {
            case .success:
                return .success(())
            case .failure(let error):
                if attempt == maxRetries {
                    return .failure(error)
                }

                // Wait before retry
                try? await Task.sleep(nanoseconds: UInt64(2.0 * Double(attempt) * 1_000_000_000))
            }
        }

        return .failure(.networkError("Max retries exceeded"))
    }
}
```

## 🚀 CI/CD Pipeline

### Overview

ODYSSEY uses a comprehensive CI/CD pipeline with multiple stages:

1. **Quality Checks** - Code formatting and linting
2. **Build & Test** - Compilation and basic testing
3. **Security Scan** - Security vulnerability checks
4. **Performance Check** - Build time and size analysis
5. **Release** - Automated release creation

### CI Workflow (`ci.yml`)

**Triggers**: Push to main/develop, Pull requests

**Stages**:

- **Quality Checks**: SwiftFormat, SwiftLint, code formatting validation
- **Build & Test**: Debug and Release builds with timing analysis
- **Security Scan**: Hardcoded secrets, ATS settings, code signing checks
- **Performance Check**: Build time analysis, app size monitoring

### Release Workflow (`release.yml`)

**Triggers**: Push of version tags (v\*)

**Stages**:

- **Validate Release**: Version consistency checks across all files
- **Build Release**: Release build with code signing
- **Security Audit**: Security vulnerability assessment
- **Create Release**: Automated GitHub release with comprehensive notes

### Local Development Workflow

```bash
# 1. Make changes
git checkout -b feature/new-feature

# 2. Format and lint code
swiftformat Sources/
swiftlint lint --config .swiftlint.yml

# 3. Build and test
xcodebuild build -project Config/ODYSSEY.xcodeproj -scheme ODYSSEY -configuration Debug

# 4. Commit with conventional commit message
git add .
git commit -m "feat: add new automation feature"

# 5. Push and create PR
git push origin feature/new-feature
```

### Version Management

#### Semantic Versioning

Follow [Semantic Versioning](https://semver.org/) (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

#### Version Update Process

1. **Update version in all files**:

   - `Config/project.yml` - `MARKETING_VERSION`
   - `Sources/App/Info.plist` - `CFBundleShortVersionString`
   - `Documentation/CHANGELOG.md` - Add new version entry

2. **Create release tag**:

   ```bash
   git tag v3.2.0
   git push origin v3.2.0
   ```

3. **Automated release**:
   - CI/CD pipeline automatically creates GitHub release
   - Generates comprehensive release notes
   - Creates signed DMG installer

## 🧪 Testing

### Unit Testing

Create unit tests for business logic:

```swift
import XCTest
@testable import ODYSSEY

class ConfigurationManagerTests: XCTestCase {
    var configManager: ConfigurationManager!

    override func setUp() {
        super.setUp()
        configManager = ConfigurationManager.shared
    }

    func testAddConfiguration() {
        // Given
        let config = ReservationConfig(name: "Test", facilityURL: "https://test.com", sportName: "Tennis")

        // When
        configManager.addConfiguration(config)

        // Then
        XCTAssertEqual(configManager.settings.configurations.count, 1)
        XCTAssertEqual(configManager.settings.configurations.first?.name, "Test")
    }
}
```

### UI Testing

Create UI tests for user interactions:

```swift
import XCTest

class ODYSSEYUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }

    func testAddConfiguration() {
        // Test adding a new configuration
        app.buttons["Add Configuration"].tap()

        // Fill in form fields
        let urlField = app.textFields["Facility URL"]
        urlField.tap()
        urlField.typeText("https://test.com")

        // Continue with other form fields...
    }
}
```

## 🔒 Security Guidelines

### Code Security

- **No Hardcoded Secrets**: Never commit API keys, passwords, or tokens
- **Input Validation**: Validate and sanitize all user inputs
- **Secure Communication**: Use HTTPS for all network requests
- **App Transport Security**: Configure ATS properly for required domains

### App Security

- **Code Signing**: Sign releases with Developer ID certificate
- **Notarization**: Notarize app for macOS security
- **Sandboxing**: Consider app sandboxing for enhanced security
- **Permissions**: Request only necessary permissions

## 📊 Performance Guidelines

### Memory Management

- **Weak References**: Use `[weak self]` in closures to prevent retain cycles
- **Resource Cleanup**: Properly dispose of resources in `deinit`
- **Image Optimization**: Optimize app icons and images
- **Background Processing**: Use background queues for heavy operations

### Build Performance

- **Incremental Builds**: Leverage Xcode's incremental build system
- **Parallel Compilation**: Use parallel build settings
- **Caching**: Use Swift Package Manager caching
- **Clean Builds**: Periodically clean build folder

## 📚 Resources

### Documentation

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit/)
- [WebKit Documentation](https://developer.apple.com/documentation/webkit/)

### Tools

- [XcodeGen](https://github.com/yonaskolb/XcodeGen) - Project generation
- [SwiftLint](https://github.com/realm/SwiftLint) - Code style enforcement
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - Code formatting
- [create-dmg](https://github.com/create-dmg/create-dmg) - DMG creation

### Best Practices

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui/best_practices)
- [macOS App Programming Guide](https://developer.apple.com/documentation/appkit/macos_app_programming_guide)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

**Happy coding! 🚀**
