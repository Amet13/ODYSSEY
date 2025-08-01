import Foundation

// MARK: - Unified Error Types

/// Unified error types to consolidate duplicate error structures across the codebase
public enum UnifiedError: Error, LocalizedError, UnifiedErrorProtocol {
    // MARK: - Network Errors

    case network(String)
    case connectionFailed(String)
    case timeout(String)

    // MARK: - Authentication Errors

    case authenticationFailed(String)
    case emailVerificationFailed(String)
    case gmailAppPasswordRequired(String)

    // MARK: - Validation Errors

    case facilityNotFound(String)
    case slotUnavailable(String)
    case invalidSelector(String)
    case unsupportedServer(String)

    // MARK: - Automation Errors

    case automationFailed(String)
    case elementNotFound(String)
    case clickFailed(String)
    case typeFailed(String)
    case scriptExecutionFailed(String)
    case staleElement(String)
    case sportButtonNotFound(String)
    case confirmButtonNotFound(String)
    case numberOfPeopleFieldNotFound(String)
    case contactInfoFieldNotFound(String)
    case contactInfoConfirmButtonNotFound(String)
    case timeSlotSelectionFailed(String)

    // MARK: - System Errors

    case pageLoadTimeout(String)
    case groupSizePageLoadTimeout(String)
    case contactInfoPageLoadTimeout(String)
    case webKitTimeout(String)
    case commandFailed(String)
    case invalidResponse(String)

    // MARK: - Unknown Errors

    case unknown(String)

    // MARK: - UnifiedErrorProtocol Implementation

    /// Human-readable error description
    public var errorDescription: String? {
        return userFriendlyMessage
    }

    /// Unique error code for categorization and debugging
    public var errorCode: String {
        switch self {
        // Network Errors
        case .network: return "UNIFIED_NETWORK_001"
        case .connectionFailed: return "UNIFIED_CONNECTION_001"
        case .timeout: return "UNIFIED_TIMEOUT_001"
        // Authentication Errors
        case .authenticationFailed: return "UNIFIED_AUTH_001"
        case .emailVerificationFailed: return "UNIFIED_EMAIL_001"
        case .gmailAppPasswordRequired: return "UNIFIED_GMAIL_001"
        // Validation Errors
        case .facilityNotFound: return "UNIFIED_VALIDATION_001"
        case .slotUnavailable: return "UNIFIED_VALIDATION_002"
        case .invalidSelector: return "UNIFIED_VALIDATION_003"
        case .unsupportedServer: return "UNIFIED_VALIDATION_004"
        // Automation Errors
        case .automationFailed: return "UNIFIED_AUTOMATION_001"
        case .elementNotFound: return "UNIFIED_AUTOMATION_002"
        case .clickFailed: return "UNIFIED_AUTOMATION_003"
        case .typeFailed: return "UNIFIED_AUTOMATION_004"
        case .scriptExecutionFailed: return "UNIFIED_AUTOMATION_005"
        case .staleElement: return "UNIFIED_AUTOMATION_006"
        case .sportButtonNotFound: return "UNIFIED_AUTOMATION_007"
        case .confirmButtonNotFound: return "UNIFIED_AUTOMATION_008"
        case .numberOfPeopleFieldNotFound: return "UNIFIED_AUTOMATION_009"
        case .contactInfoFieldNotFound: return "UNIFIED_AUTOMATION_010"
        case .contactInfoConfirmButtonNotFound: return "UNIFIED_AUTOMATION_011"
        case .timeSlotSelectionFailed: return "UNIFIED_AUTOMATION_012"
        // System Errors
        case .pageLoadTimeout: return "UNIFIED_SYSTEM_001"
        case .groupSizePageLoadTimeout: return "UNIFIED_SYSTEM_002"
        case .contactInfoPageLoadTimeout: return "UNIFIED_SYSTEM_003"
        case .webKitTimeout: return "UNIFIED_SYSTEM_004"
        case .commandFailed: return "UNIFIED_SYSTEM_005"
        case .invalidResponse: return "UNIFIED_SYSTEM_006"
        // Unknown Errors
        case .unknown: return "UNIFIED_UNKNOWN_001"
        }
    }

    /// Category for grouping similar errors
    public var errorCategory: ErrorCategory {
        switch self {
        // Network Errors
        case .network, .connectionFailed, .timeout: return .network

        // Authentication Errors
        case .authenticationFailed, .emailVerificationFailed, .gmailAppPasswordRequired: return .authentication

        // Validation Errors
        case .facilityNotFound, .slotUnavailable, .invalidSelector, .unsupportedServer: return .validation

        // Automation Errors
        case .automationFailed, .elementNotFound, .clickFailed, .typeFailed, .scriptExecutionFailed,
             .staleElement, .sportButtonNotFound, .confirmButtonNotFound, .numberOfPeopleFieldNotFound,
             .contactInfoFieldNotFound, .contactInfoConfirmButtonNotFound, .timeSlotSelectionFailed: return .automation

        // System Errors
        case .pageLoadTimeout, .groupSizePageLoadTimeout, .contactInfoPageLoadTimeout, .webKitTimeout,
             .commandFailed, .invalidResponse: return .system

        // Unknown Errors
        case .unknown: return .unknown
        }
    }

    /// User-friendly error message for UI display
    public var userFriendlyMessage: String {
        switch self {
        // Network Errors
        case let .network(message): return "Network error: \(message)"
        case let .connectionFailed(message): return "Connection failed: \(message)"
        case let .timeout(message): return "Timeout: \(message)"
        // Authentication Errors
        case let .authenticationFailed(message): return "Authentication failed: \(message)"
        case let .emailVerificationFailed(message): return "Email verification failed: \(message)"
        case let .gmailAppPasswordRequired(message): return "Gmail App Password required: \(message)"
        // Validation Errors
        case let .facilityNotFound(message): return "Facility not found: \(message)"
        case let .slotUnavailable(message): return "Slot unavailable: \(message)"
        case let .invalidSelector(message): return "Invalid selector: \(message)"
        case let .unsupportedServer(message): return "Unsupported server: \(message)"
        // Automation Errors
        case let .automationFailed(message): return "Automation failed: \(message)"
        case let .elementNotFound(message): return "Element not found: \(message)"
        case let .clickFailed(message): return "Click failed: \(message)"
        case let .typeFailed(message): return "Type failed: \(message)"
        case let .scriptExecutionFailed(message): return "Script execution failed: \(message)"
        case let .staleElement(message): return "Stale element: \(message)"
        case let .sportButtonNotFound(message): return "Sport button not found: \(message)"
        case let .confirmButtonNotFound(message): return "Confirm button not found: \(message)"
        case let .numberOfPeopleFieldNotFound(message): return "Number of people field not found: \(message)"
        case let .contactInfoFieldNotFound(message): return "Contact info field not found: \(message)"
        case let .contactInfoConfirmButtonNotFound(message): return "Contact info confirm button not found: \(message)"
        case let .timeSlotSelectionFailed(message): return "Failed to select time slot: \(message)"
        // System Errors
        case let .pageLoadTimeout(message): return "Page failed to load in time: \(message)"
        case let .groupSizePageLoadTimeout(message): return "Group size page failed to load in time: \(message)"
        case let .contactInfoPageLoadTimeout(message): return "Contact info page failed to load in time: \(message)"
        case let .webKitTimeout(message): return "WebKit operation timed out: \(message)"
        case let .commandFailed(message): return "Command failed: \(message)"
        case let .invalidResponse(message): return "Invalid response: \(message)"
        // Unknown Errors
        case let .unknown(message): return "Unknown error: \(message)"
        }
    }

    /// Technical details for debugging (optional)
    public var technicalDetails: String? {
        switch self {
        // Network Errors
        case let .network(message): return "Network operation failed: \(message)"
        case let .connectionFailed(message): return "Connection establishment failed: \(message)"
        case let .timeout(message): return "Operation exceeded timeout: \(message)"
        // Authentication Errors
        case let .authenticationFailed(message): return "Authentication process failed: \(message)"
        case let .emailVerificationFailed(message): return "Email verification process failed: \(message)"
        case let .gmailAppPasswordRequired(message): return "Gmail App Password validation failed: \(message)"
        // Validation Errors
        case let .facilityNotFound(message): return "Facility lookup failed: \(message)"
        case let .slotUnavailable(message): return "Slot availability check failed: \(message)"
        case let .invalidSelector(message): return "CSS selector validation failed: \(message)"
        case let .unsupportedServer(message): return "Server configuration issue: \(message)"
        // Automation Errors
        case let .automationFailed(message): return "Web automation process failed: \(message)"
        case let .elementNotFound(message): return "DOM element not found: \(message)"
        case let .clickFailed(message): return "Element click operation failed: \(message)"
        case let .typeFailed(message): return "Text input operation failed: \(message)"
        case let .scriptExecutionFailed(message): return "JavaScript execution failed: \(message)"
        case let .staleElement(message): return "Element became stale: \(message)"
        case let .sportButtonNotFound(message): return "Sport button lookup failed: \(message)"
        case let .confirmButtonNotFound(message): return "Confirm button lookup failed: \(message)"
        case let .numberOfPeopleFieldNotFound(message): return "Number of people field lookup failed: \(message)"
        case let .contactInfoFieldNotFound(message): return "Contact info field lookup failed: \(message)"
        case let .contactInfoConfirmButtonNotFound(message): return "Contact info confirm button lookup failed: \(message)"
        case let .timeSlotSelectionFailed(message): return "Time slot selection process failed: \(message)"
        // System Errors
        case let .pageLoadTimeout(message): return "Page load operation timed out: \(message)"
        case let .groupSizePageLoadTimeout(message): return "Group size page load operation timed out: \(message)"
        case let .contactInfoPageLoadTimeout(message): return "Contact info page load operation timed out: \(message)"
        case let .webKitTimeout(message): return "WebKit operation exceeded timeout: \(message)"
        case let .commandFailed(message): return "Command execution failed: \(message)"
        case let .invalidResponse(message): return "Server returned invalid response: \(message)"
        // Unknown Errors
        case let .unknown(message): return "Unexpected error occurred: \(message)"
        }
    }
}

// MARK: - Error Conversion Extensions

public extension ReservationError {
    /// Convert ReservationError to UnifiedError
    func toUnifiedError() -> UnifiedError {
        switch self {
        case let .network(message): return .network(message)
        case let .facilityNotFound(message): return .facilityNotFound(message)
        case let .slotUnavailable(message): return .slotUnavailable(message)
        case let .automationFailed(message): return .automationFailed(message)
        case let .unknown(message): return .unknown(message)
        default: return convertReservationErrorToUnifiedError(self)
        }
    }

    /// Helper function to convert specific ReservationError cases
    private func convertReservationErrorToUnifiedError(_ error: ReservationError) -> UnifiedError {
        switch error {
        case .pageLoadTimeout: return .pageLoadTimeout("Page failed to load in time")
        case .groupSizePageLoadTimeout: return .groupSizePageLoadTimeout("Group size page failed to load in time")
        case .numberOfPeopleFieldNotFound: return .numberOfPeopleFieldNotFound("Number of people field not found")
        case .confirmButtonNotFound: return .confirmButtonNotFound("Confirm button not found")
        case .timeSlotSelectionFailed: return .timeSlotSelectionFailed("Failed to select time slot")
        case .contactInfoPageLoadTimeout: return .contactInfoPageLoadTimeout("Contact info page failed to load in time")
        case .contactInfoFieldNotFound: return .contactInfoFieldNotFound("Contact info field not found")
        case .contactInfoConfirmButtonNotFound: return .contactInfoConfirmButtonNotFound(
                "Contact info confirm button not found",
            )
        case .emailVerificationFailed: return .emailVerificationFailed("Email verification failed")
        case .sportButtonNotFound: return .sportButtonNotFound("Sport button not found")
        case .webKitTimeout: return .webKitTimeout("WebKit operation timed out")
        default: return .unknown("Unknown ReservationError")
        }
    }
}

public extension WebDriverError {
    /// Convert WebDriverError to UnifiedError
    func toUnifiedError() -> UnifiedError {
        switch self {
        case let .navigationFailed(message): return .network(message)
        case let .elementNotFound(message): return .elementNotFound(message)
        case let .clickFailed(message): return .clickFailed(message)
        case let .typeFailed(message): return .typeFailed(message)
        case let .scriptExecutionFailed(message): return .scriptExecutionFailed(message)
        case let .timeout(message): return .timeout(message)
        case let .connectionFailed(message): return .connectionFailed(message)
        case let .invalidSelector(message): return .invalidSelector(message)
        case let .staleElement(message): return .staleElement(message)
        }
    }
}
