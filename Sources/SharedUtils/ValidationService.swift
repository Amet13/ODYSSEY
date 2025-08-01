import Foundation
import os.log

/**
 ValidationService is responsible for centralized validation logic for user input, configuration, and data integrity throughout the app.
 This is the single source of truth for all validation logic in the application.
 */
@MainActor
final class ValidationService {
    @MainActor static let shared = ValidationService()

    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "ValidationService")

    init() { }

    // MARK: - Utility Functions

    /**
     Check if a string is not empty
     - Parameter value: The string to validate
     - Returns: True if the string is not empty
     */
    func isNotEmpty(_ value: String) -> Bool {
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /**
     Check if a string is empty
     - Parameter value: The string to validate
     - Returns: True if the string is empty
     */
    func isEmpty(_ value: String) -> Bool {
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /**
     Check if a collection is not empty
     - Parameter collection: The collection to validate
     - Returns: True if the collection is not empty
     */
    func isNotEmpty(_ collection: some Collection) -> Bool {
        return !collection.isEmpty
    }

    /**
     Check if a collection is empty
     - Parameter collection: The collection to validate
     - Returns: True if the collection is empty
     */
    func isEmpty(_ collection: some Collection) -> Bool {
        return collection.isEmpty
    }

    /**
     Check if a number is within a valid range
     - Parameters:
     - value: The number to validate
     - min: Minimum allowed value
     - max: Maximum allowed value
     - Returns: True if the number is within the valid range
     */
    func isInRange(_ value: Int, min: Int, max: Int) -> Bool {
        return value >= min && value <= max
    }

    /**
     Check if a number is positive
     - Parameter value: The number to validate
     - Returns: True if the number is positive
     */
    func isPositive(_ value: Int) -> Bool {
        return value > 0
    }

    /**
     Check if a number is non-negative
     - Parameter value: The number to validate
     - Returns: True if the number is non-negative
     */
    func isNonNegative(_ value: Int) -> Bool {
        return value >= 0
    }

    // MARK: - Email Validation

    /**
     Validates email address format
     - Parameter email: Email address to validate
     - Returns: True if email is valid
     */
    func validateEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        let emailRegex = AppConstants.patterns["email"] ?? "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValid = emailPredicate.evaluate(with: email)
        return isValid
    }

    /**
     Validates if email is a Gmail account
     - Parameter email: Email address to check
     - Returns: True if it's a Gmail account
     */
    func isGmailAccount(_ email: String) -> Bool {
        let gmailDomains = ["gmail.com", "googlemail.com"]
        let domain = email.components(separatedBy: "@").last?.lowercased()
        return gmailDomains.contains(domain ?? "")
    }

    /**
     Validates Gmail App Password format
     - Parameter password: App password to validate
     - Returns: True if password format is valid
     */
    func validateGmailAppPassword(_ password: String) -> Bool {
        guard !password.isEmpty else { return false }
        let pattern = AppConstants.patterns["gmailAppPassword"] ?? "^[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        let isValid = predicate.evaluate(with: password)
        return isValid
    }

    // MARK: - Facility URL Validation

    /**
     Validates facility URL format
     - Parameter url: URL to validate
     - Returns: True if URL is valid
     */
    func validateFacilityURL(_ url: String) -> Bool {
        guard !url.isEmpty else { return false }
        guard URL(string: url) != nil else { return false }
        let pattern = AppConstants.patterns["facilityURL"] ?? "^https://reservation\\.frontdesksuite\\.ca/rcfs/[^/]+/?$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        let isValid = predicate.evaluate(with: url)
        return isValid
    }

    // MARK: - Phone Number Validation

    /**
     Validates phone number format
     - Parameter phone: Phone number to validate
     - Returns: True if phone number is valid
     */
    func validatePhoneNumber(_ phone: String) -> Bool {
        guard !phone.isEmpty else { return false }
        let digitsOnly = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard digitsOnly.count >= 7, digitsOnly.count <= 15 else { return false }
        let phoneRegex = AppConstants.patterns["phoneNumber"] ?? "^\\+?[1-9]\\d{1,14}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let isValid = phonePredicate.evaluate(with: phone)
        return isValid
    }

    /**
     Validates IMAP server address format
     - Parameter server: Server address to validate
     - Returns: True if server address is valid
     */
    func validateServer(_ server: String) -> Bool {
        guard !server.isEmpty else { return false }
        // Basic server validation - should contain a domain and optional port
        let serverRegex = "^[a-zA-Z0-9.-]+(\\.[a-zA-Z0-9.-]+)*(?::[0-9]+)?$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", serverRegex)
        return predicate.evaluate(with: server)
    }

    // MARK: - Reservation Config Validation

    /**
     Validates a reservation configuration and returns an array of error messages if invalid.
     - Parameter config: The ReservationConfig to validate.
     - Returns: An array of error messages, or an empty array if valid.
     */
    func validateReservationConfig(_ config: ReservationConfig) -> [String] {
        var errors: [String] = []

        // Validate facility URL
        if !validateFacilityURL(config.facilityURL) {
            errors.append("Invalid facility URL")
        }

        // Validate sport name
        if config.sportName.isEmpty {
            errors.append("Sport name is required")
        }

        // Validate number of people
        if
            config.numberOfPeople < AppConstants.minNumberOfPeople || config.numberOfPeople > AppConstants
                .maxNumberOfPeople
        {
            errors
                .append(
                    "Number of people must be between \(AppConstants.minNumberOfPeople) and \(AppConstants.maxNumberOfPeople)",
                    )
        }

        // Validate time slots
        if config.dayTimeSlots.isEmpty {
            errors.append("At least one time slot is required")
        }

        // Validate each time slot
        for (day, slots) in config.dayTimeSlots {
            if slots.isEmpty {
                errors.append("No time slots for \(day.rawValue)")
            }

            for slot in slots {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: slot.time)
                let minute = calendar.component(.minute, from: slot.time)

                if hour < 0 || hour > 23 {
                    errors.append("Invalid hour for \(day.rawValue): \(hour)")
                }
                if minute < 0 || minute > 59 {
                    errors.append("Invalid minute for \(day.rawValue): \(minute)")
                }
            }
        }

        return errors
    }

    // MARK: - User Settings Validation

    /// Validates user settings
    /// - Parameter settings: Settings to validate
    /// - Returns: Validation result with errors
    func validateUserSettings(_ settings: UserSettings) -> ValidationResult {
        var errors: [String] = []

        // Validate name
        if settings.name.isEmpty {
            errors.append("Name is required")
        }

        // Validate phone number if provided
        if !settings.phoneNumber.isEmpty, !validatePhoneNumber(settings.phoneNumber) {
            errors.append("Invalid phone number format")
        }

        // Validate email if provided
        if !settings.imapEmail.isEmpty {
            if !validateEmail(settings.imapEmail) {
                errors.append("Invalid email format")
            }

            // Validate Gmail App Password if it's a Gmail account
            if isGmailAccount(settings.imapEmail), !settings.imapPassword.isEmpty {
                if !validateGmailAppPassword(settings.imapPassword) {
                    errors.append("Invalid Gmail App Password format")
                }
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    // MARK: - WebKit Validation

    /// Validates WebKit configuration
    /// - Parameter config: WebKit configuration to validate
    /// - Returns: Validation result with errors
    func validateWebKitConfig(_ config: ReservationConfig) -> ValidationResult {
        var errors: [String] = []

        // Validate facility URL
        if !validateFacilityURL(config.facilityURL) {
            errors.append("Invalid facility URL for WebKit automation")
        }

        // Validate sport name
        if config.sportName.isEmpty {
            errors.append("Sport name is required for WebKit automation")
        }

        // Validate time slots
        if config.dayTimeSlots.isEmpty {
            errors.append("At least one time slot is required for WebKit automation")
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    // MARK: - Email Configuration Validation

    /// Validates email configuration for automation
    /// - Parameter settings: Email settings to validate
    /// - Returns: Validation result with errors
    func validateEmailConfig(_ settings: UserSettings) -> ValidationResult {
        var errors: [String] = []

        // Validate email is provided
        if settings.imapEmail.isEmpty {
            errors.append("Email address is required for verification")
        } else if !validateEmail(settings.imapEmail) {
            errors.append("Invalid email format")
        }

        // Validate server if provided
        if !settings.imapServer.isEmpty, !validateServer(settings.imapServer) {
            errors.append("Invalid IMAP server address")
        }

        // Validate password if provided
        if settings.imapPassword.isEmpty {
            errors.append("Email password is required for verification")
        }

        // Validate Gmail App Password for Gmail accounts
        if isGmailAccount(settings.imapEmail), !settings.imapPassword.isEmpty {
            if !validateGmailAppPassword(settings.imapPassword) {
                errors.append("Invalid Gmail App Password format")
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    // MARK: - Automation Validation

    /// Validates automation configuration
    /// - Parameter config: Configuration to validate
    /// - Returns: Validation result with errors
    func validateAutomationConfig(_ config: ReservationConfig) -> ValidationResult {
        var errors: [String] = []

        // Validate basic config
        let basicValidation = validateReservationConfig(config)
        if !basicValidation.isEmpty {
            errors.append(contentsOf: basicValidation)
        }

        // Validate WebKit specific requirements
        let webKitValidation = validateWebKitConfig(config)
        if !webKitValidation.isValid {
            errors.append(contentsOf: webKitValidation.errors)
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    // MARK: - Network Validation

    /// Validates network connectivity requirements
    /// - Returns: Validation result with errors
    func validateNetworkRequirements() -> ValidationResult {
        var errors: [String] = []

        // Check if we can reach the internet (basic check)
        guard URL(string: "https://www.apple.com") != nil else {
            errors.append("Invalid test URL")
            return ValidationResult(isValid: false, errors: errors)
        }

        // Note: In a real implementation, you might want to actually test connectivity
        // For now, we'll assume network is available if we can create the URL

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    // MARK: - Comprehensive Validation

    /// Performs comprehensive validation of all components
    /// - Parameters:
    ///   - config: Reservation configuration
    ///   - settings: User settings
    /// - Returns: Comprehensive validation result
    func validateAll(_ config: ReservationConfig, settings: UserSettings) -> ValidationResult {
        var allErrors: [String] = []

        // Validate reservation config
        let configValidation = validateReservationConfig(config)
        if !configValidation.isEmpty {
            allErrors.append(contentsOf: configValidation)
        }

        // Validate user settings
        let settingsValidation = validateUserSettings(settings)
        if !settingsValidation.isValid {
            allErrors.append(contentsOf: settingsValidation.errors)
        }

        // Validate email configuration
        let emailValidation = validateEmailConfig(settings)
        if !emailValidation.isValid {
            allErrors.append(contentsOf: emailValidation.errors)
        }

        // Validate automation configuration
        let automationValidation = validateAutomationConfig(config)
        if !automationValidation.isValid {
            allErrors.append(contentsOf: automationValidation.errors)
        }

        return ValidationResult(isValid: allErrors.isEmpty, errors: allErrors)
    }
}

// MARK: - Validation Result

/**
 Result of validation operations
 */
public struct ValidationResult {
    let isValid: Bool
    let errors: [String]

    var errorMessage: String {
        errors.joined(separator: "; ")
    }
}
