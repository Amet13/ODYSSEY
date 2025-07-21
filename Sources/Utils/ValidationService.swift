import Foundation
import os.log

/// Centralized validation service for the ODYSSEY application
/// Provides consistent validation across all components
@MainActor
class ValidationService: NSObject, ValidationServiceProtocol {
    static let shared = ValidationService()

    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "ValidationService")

    override private init() {
        super.init()
    }

    // MARK: - Email Validation

    /// Validates email address format
    /// - Parameter email: Email address to validate
    /// - Returns: True if email is valid
    nonisolated func validateEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }

        let emailRegex = AppConstants.patterns["email"] ?? "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValid = emailPredicate.evaluate(with: email)

        logger.debug("Email validation result: \(isValid) for \(email.maskedForLogging)")
        return isValid
    }

    /// Validates if email is a Gmail account
    /// - Parameter email: Email address to check
    /// - Returns: True if it's a Gmail account
    func isGmailAccount(_ email: String) -> Bool {
        let gmailDomains = ["gmail.com", "googlemail.com"]
        let domain = email.components(separatedBy: "@").last?.lowercased()
        return gmailDomains.contains(domain ?? "")
    }

    /// Validates IMAP server address format
    /// - Parameter server: Server address to validate
    /// - Returns: True if server address is valid
    nonisolated func validateServer(_ server: String) -> Bool {
        guard !server.isEmpty else { return false }

        // Basic server validation - should contain a domain and optional port
        let serverRegex = "^[a-zA-Z0-9.-]+(\\.[a-zA-Z0-9.-]+)*(:[0-9]+)?$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", serverRegex)
        let isValid = predicate.evaluate(with: server)

        logger.debug("Server validation result: \(isValid) for \(server)")
        return isValid
    }

    // MARK: - Phone Number Validation

    /// Validates phone number format
    /// - Parameter phone: Phone number to validate
    /// - Returns: True if phone number is valid
    nonisolated func validatePhoneNumber(_ phone: String) -> Bool {
        guard !phone.isEmpty else { return false }

        // Remove all non-digit characters for validation
        let digitsOnly = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        // Check if it's a valid length (7-15 digits)
        guard digitsOnly.count >= 7, digitsOnly.count <= 15 else { return false }

        // Check if it starts with a valid country code or area code
        let phoneRegex = AppConstants.patterns["phoneNumber"] ?? "^\\+?[1-9]\\d{1,14}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let isValid = phonePredicate.evaluate(with: phone)

        logger.debug("Phone validation result: \(isValid) for \(phone.maskedForLogging)")
        return isValid
    }

    /// Formats phone number for display
    /// - Parameter phone: Raw phone number
    /// - Returns: Formatted phone number
    func formatPhoneNumber(_ phone: String) -> String {
        let digitsOnly = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        // Format based on length
        switch digitsOnly.count {
        case 10: // North American format
            let index = digitsOnly.index(digitsOnly.startIndex, offsetBy: 3)
            let areaCode = String(digitsOnly[..<index])
            let prefix = String(digitsOnly[index ..< digitsOnly.index(index, offsetBy: 3)])
            let lineNumber = String(digitsOnly[digitsOnly.index(index, offsetBy: 3)...])
            return "(\(areaCode)) \(prefix)-\(lineNumber)"
        case 11 where digitsOnly.hasPrefix("1"): // North American with country code
            let withoutCountry = String(digitsOnly.dropFirst())
            return formatPhoneNumber(withoutCountry)
        default:
            return phone // Return original if can't format
        }
    }

    // MARK: - Gmail App Password Validation

    /// Validates Gmail App Password format
    /// - Parameter password: App password to validate
    /// - Returns: True if password format is valid
    nonisolated func validateGmailAppPassword(_ password: String) -> Bool {
        guard !password.isEmpty else { return false }

        let pattern = AppConstants.patterns["gmailAppPassword"] ?? "^[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        let isValid = predicate.evaluate(with: password)

        logger.debug("Gmail App Password validation result: \(isValid)")
        return isValid
    }

    // MARK: - Facility URL Validation

    /// Validates facility URL format
    /// - Parameter url: URL to validate
    /// - Returns: True if URL is valid
    nonisolated func validateFacilityURL(_ url: String) -> Bool {
        guard !url.isEmpty else { return false }

        // Check if it's a valid URL
        guard URL(string: url) != nil else { return false }

        // Check if it's a valid facility URL pattern
        let pattern = AppConstants.patterns["facilityURL"] ?? "^https://reservation\\.frontdesksuite\\.ca/rcfs/[^/]+/?$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        let isValid = predicate.evaluate(with: url)

        logger.debug("Facility URL validation result: \(isValid) for \(url)")
        return isValid
    }

    /// Extracts facility name from URL
    /// - Parameter url: Facility URL
    /// - Returns: Facility name or nil if invalid
    func extractFacilityName(from url: String) -> String? {
        guard validateFacilityURL(url) else { return nil }

        let pattern = AppConstants.patterns["facilityName"] ?? "https://reservation\\.frontdesksuite\\.ca/rcfs/([^/]+)"

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(url.startIndex..., in: url)

        guard
            let match = regex.firstMatch(in: url, range: range),
            match.numberOfRanges > 1 else { return nil }

        let facilityRange = match.range(at: 1)
        guard let range = Range(facilityRange, in: url) else { return nil }

        return String(url[range]).capitalized
    }

    // MARK: - Verification Code Validation

    /// Validates verification code format
    /// - Parameter code: Code to validate
    /// - Returns: True if code is valid
    func validateVerificationCode(_ code: String) -> Bool {
        guard !code.isEmpty else { return false }

        let pattern = AppConstants.patterns["verificationCode"] ?? "\\b\\d{4}\\b"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        let isValid = predicate.evaluate(with: code)

        logger.debug("Verification code validation result: \(isValid)")
        return isValid
    }

    // MARK: - Configuration Validation

    /// Validates reservation configuration
    /// - Parameter config: Configuration to validate
    /// - Returns: Validation result with errors
    func validateReservationConfig(_ config: ReservationConfig) -> ValidationResult {
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
        if config.numberOfPeople <= 0 || config.numberOfPeople > 20 {
            errors.append("Number of people must be between 1 and 20")
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

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
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
}

// MARK: - Validation Result

/// Result of validation operations
struct ValidationResult {
    let isValid: Bool
    let errors: [String]

    var errorMessage: String {
        errors.joined(separator: "; ")
    }
}
