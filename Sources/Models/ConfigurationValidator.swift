import Foundation
import os.log

/// Centralized configuration validation service
/// Handles all validation logic for reservation configurations and user settings
@MainActor
public final class ConfigurationValidator: ObservableObject {
    public static let shared = ConfigurationValidator()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ConfigurationValidator")

    private init() { }

    // MARK: - ReservationConfig Validation

    /// Validates a reservation configuration
    /// - Parameter config: The configuration to validate
    /// - Returns: Validation result with errors if any
    public func validateReservationConfig(_ config: ReservationConfig) -> ValidationResult {
        var errors: [String] = []

        // Name validation
        if config.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Configuration name is required")
        } else if config.name.count > AppConstants.maxConfigurationNameLength {
            errors.append("Configuration name must be \(AppConstants.maxConfigurationNameLength) characters or less")
        }

        // Facility URL validation
        if !isValidFacilityURL(config.facilityURL) {
            errors.append("Invalid facility URL. Must be a valid Ottawa recreation facility URL")
        }

        // Sport name validation
        if config.sportName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Sport name is required")
        } else if config.sportName.count > AppConstants.maxSportNameLength {
            errors.append("Sport name must be \(AppConstants.maxSportNameLength) characters or less")
        }

        // Number of people validation
        if
            config.numberOfPeople < AppConstants.minNumberOfPeople || config.numberOfPeople > AppConstants
                .maxNumberOfPeople {
            errors
                .append(
                    "Number of people must be between \(AppConstants.minNumberOfPeople) and \(AppConstants.maxNumberOfPeople)",
                    )
        }

        // Time slots validation
        if config.dayTimeSlots.isEmpty {
            errors.append("At least one time slot must be selected")
        } else {
            for (day, timeSlots) in config.dayTimeSlots {
                if timeSlots.isEmpty {
                    errors.append("No time slots selected for \(day.rawValue)")
                }
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    /// Validates facility URL format
    /// - Parameter url: The URL to validate
    /// - Returns: True if valid Ottawa recreation facility URL
    public func isValidFacilityURL(_ url: String) -> Bool {
        guard let url = URL(string: url) else { return false }

        // Check if it's a valid Ottawa recreation facility URL
        let validDomains = ["reservation.frontdesksuite.ca"]
        let validPathPrefix = "/rcfs/"

        guard let host = url.host else { return false }
        guard validDomains.contains(host) else { return false }
        guard url.path.hasPrefix(validPathPrefix) else { return false }

        return true
    }

    // MARK: - UserSettings Validation

    /// Validates user settings
    /// - Parameter settings: The settings to validate
    /// - Returns: Validation result with errors if any
    public func validateUserSettings(_ settings: UserSettings) -> ValidationResult {
        var errors: [String] = []

        // Name validation
        if settings.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Name is required")
        }

        // Phone number validation
        if !settings.phoneNumber.isEmpty {
            if !isValidPhoneNumber(settings.phoneNumber) {
                errors.append("Invalid phone number format")
            }
        }

        // Email validation
        if !settings.imapEmail.isEmpty {
            if !isValidEmail(settings.imapEmail) {
                errors.append("Invalid email address format")
            }
        }

        // IMAP server validation
        if !settings.imapServer.isEmpty {
            if !isValidIMAPServer(settings.imapServer) {
                errors.append("Invalid IMAP server address")
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    /// Validates phone number format
    /// - Parameter phoneNumber: The phone number to validate
    /// - Returns: True if valid phone number format
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let pattern = AppConstants.patterns["phoneNumber"] ?? "^\\+?[1-9]\\d{1,14}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(phoneNumber.startIndex ..< phoneNumber.endIndex, in: phoneNumber)
        return regex?.firstMatch(in: phoneNumber, range: range) != nil
    }

    /// Validates email format
    /// - Parameter email: The email to validate
    /// - Returns: True if valid email format
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = AppConstants.patterns["email"] ?? "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(email.startIndex ..< email.endIndex, in: email)
        return regex?.firstMatch(in: email, range: range) != nil
    }

    /// Validates IMAP server format
    /// - Parameter server: The server to validate
    /// - Returns: True if valid IMAP server format
    private func isValidIMAPServer(_ server: String) -> Bool {
        // Basic validation for IMAP server format
        let validDomains = ["gmail.com", "outlook.com", "yahoo.com", "icloud.com"]
        let serverLower = server.lowercased()

        // Check if it's a known domain
        if validDomains.contains(serverLower) {
            return true
        }

        // Check if it's a valid domain format
        let domainPattern =
            "^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        let regex = try? NSRegularExpression(pattern: domainPattern)
        let range = NSRange(server.startIndex ..< server.endIndex, in: server)
        return regex?.firstMatch(in: server, range: range) != nil
    }

    // MARK: - Gmail App Password Validation

    /// Validates Gmail App Password format
    /// - Parameter password: The password to validate
    /// - Returns: True if valid Gmail App Password format
    public func isValidGmailAppPassword(_ password: String) -> Bool {
        let pattern = AppConstants.patterns["gmailAppPassword"] ?? "^[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(password.startIndex ..< password.endIndex, in: password)
        return regex?.firstMatch(in: password, range: range) != nil
    }

    // MARK: - Verification Code Validation

    /// Validates verification code format
    /// - Parameter code: The code to validate
    /// - Returns: True if valid verification code format
    public func isValidVerificationCode(_ code: String) -> Bool {
        let pattern = AppConstants.patterns["verificationCode"] ?? "\\b\\d{4}\\b"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(code.startIndex ..< code.endIndex, in: code)
        return regex?.firstMatch(in: code, range: range) != nil
    }

    // MARK: - Legacy Static Methods (for backward compatibility)

    /**
     * Validates all fields of a reservation configuration.
     *
     * - Parameters:
     *   - facilityURL: The facility reservation URL.
     *   - name: The configuration name.
     *   - sportName: The sport name.
     *   - numberOfPeople: The number of people for the reservation.
     *   - dayTimeSlots: The selected days and time slots.
     * - Returns: An array of validation error messages. Empty if valid.
     */
    static func validate(
        facilityURL: String,
        name: String,
        sportName: String,
        numberOfPeople: Int,
        dayTimeSlots: [ReservationConfig.Weekday: [Date]],
        ) -> [String] {
        let validator = shared
        let tempConfig = ReservationConfig(
            name: name,
            facilityURL: facilityURL,
            sportName: sportName,
            numberOfPeople: numberOfPeople,
            dayTimeSlots: dayTimeSlots.mapValues { $0.map { TimeSlot(time: $0) } },
            )
        let result = validator.validateReservationConfig(tempConfig)
        return result.errors
    }

    /**
     * Validates the facility reservation URL.
     *
     * - Parameter url: The facility URL string.
     * - Returns: True if the URL is valid, false otherwise.
     */
    static func isValidFacilityURL(_ url: String) -> Bool {
        return shared.isValidFacilityURL(url)
    }
}
