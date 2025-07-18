# Utils Directory

This directory contains utility components, extensions, and protocols that are used throughout the ODYSSEY application.

## 📁 File Structure

### `AppConstants.swift`

Centralized constants for the entire application including:

- Application information (name, version, bundle ID)
- Timeouts and delays
- Email configuration
- WebKit settings
- User agent strings
- Validation patterns
- Error messages
- UserDefaults keys

### `Extensions.swift`

Reusable Swift extensions for common functionality:

- **String Extensions**: Masking for logging, validation, code extraction
- **Date Extensions**: IMAP formatting, time range checking
- **Array Extensions**: Code management utilities
- **View Extensions**: Conditional modifiers, loading overlays
- **Color Extensions**: ODYSSEY color palette
- **Logger Extensions**: Enhanced logging utilities

### `Protocols.swift`

Protocol definitions for better architecture:

- **WebAutomationServiceProtocol**: Web automation interface
- **EmailServiceProtocol**: Email operations interface
- **ConfigurationManagerProtocol**: Configuration management interface
- **UserSettingsManagerProtocol**: User settings interface
- **ReservationManagerProtocol**: Reservation management interface
- **FacilityServiceProtocol**: Facility operations interface
- **StatusBarControllerProtocol**: UI management interface
- **LoggingServiceProtocol**: Logging operations interface
- **ValidationServiceProtocol**: Validation operations interface
- **StorageServiceProtocol**: Data persistence interface
- **NetworkServiceProtocol**: Network operations interface
- **TimerServiceProtocol**: Scheduling interface
- **ErrorHandlingServiceProtocol**: Error management interface
- **PerformanceMonitoringProtocol**: Performance tracking interface

### `ValidationService.swift`

Centralized validation logic for the application:

- **Email Validation**: Format checking, Gmail detection
- **Phone Number Validation**: International format support
- **Gmail App Password Validation**: Format-specific validation
- **Facility URL Validation**: URL pattern matching
- **Verification Code Validation**: 4-digit code validation
- **Configuration Validation**: Complete reservation config validation
- **User Settings Validation**: Comprehensive settings validation

## 🎯 Usage Guidelines

### When to Use Utils

1. **AppConstants**: Use for any hardcoded values or configuration
2. **Extensions**: Use for reusable functionality across multiple files
3. **Protocols**: Use for defining clear interfaces between components
4. **ValidationService**: Use for all validation logic

### Best Practices

- **Don't duplicate**: If functionality exists in Utils, use it instead of recreating
- **Keep it focused**: Each file should have a single, clear purpose
- **Document everything**: All public APIs should be well-documented
- **Test thoroughly**: Utils are used throughout the app, so they must be reliable

### Adding New Utils

1. **Extensions**: Add to `Extensions.swift` if they're general-purpose
2. **Constants**: Add to `AppConstants.swift` if they're configuration values
3. **Protocols**: Add to `Protocols.swift` if they define interfaces
4. **Validation**: Add to `ValidationService.swift` if they're validation logic
5. **New files**: Create new files only for substantial, focused functionality

## 🔗 Dependencies

- **Foundation**: Basic Swift functionality
- **SwiftUI**: UI-related extensions
- **os.log**: Logging extensions
- **Combine**: Reactive programming support

## 📝 Examples

### Using AppConstants

```swift
let timeout = AppConstants.defaultTimeout
let userAgent = AppConstants.userAgents.randomElement()
```

### Using Extensions

```swift
let maskedPassword = password.maskedForLogging
let formattedDate = date.imapSearchFormat
let recentCode = codes.mostRecentCode
```

### Using ValidationService

```swift
let isValid = ValidationService.shared.validateEmail(email)
let validationResult = ValidationService.shared.validateUserSettings(settings)
```

### Using Protocols

```swift
class MyService: EmailServiceProtocol {
    // Implement required methods
}
```
