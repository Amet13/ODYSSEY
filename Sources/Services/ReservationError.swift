import Foundation

/// ReservationError defines all possible errors that can occur during the reservation automation process.
///
/// This enum is used throughout the automation flow to provide detailed, user-friendly error messages and to support structured error handling and logging.
public enum ReservationError: Error, Codable, LocalizedError, UnifiedErrorProtocol {
  /// Network error with a message.
  case network(String)
  /// Facility not found with a message.
  case facilityNotFound(String)
  /// Slot unavailable with a message.
  case slotUnavailable(String)
  /// Automation failed with a message
  case automationFailed(String)
  /// Unknown error with a message
  case unknown(String)
  /// Page failed to load in time
  case pageLoadTimeout
  /// Group size page failed to load in time
  case groupSizePageLoadTimeout
  /// Number of people field not found
  case numberOfPeopleFieldNotFound
  /// Confirm button not found
  case confirmButtonNotFound
  /// Failed to select time slot
  case timeSlotSelectionFailed
  /// Contact info page failed to load in time
  case contactInfoPageLoadTimeout
  /// Contact info field not found
  case contactInfoFieldNotFound
  /// Contact info confirm button not found
  case contactInfoConfirmButtonNotFound
  /// Email verification failed
  case emailVerificationFailed
  /// Sport button not found
  case sportButtonNotFound
  /// WebKit operation timed out
  case webKitTimeout

  /// Human-readable error description for each case
  public var errorDescription: String? {
    return userFriendlyMessage
  }

  /// Unique error code for categorization and debugging
  public var errorCode: String {
    switch self {
    case .network: return "RESERVATION_NETWORK_001"
    case .facilityNotFound: return "RESERVATION_FACILITY_001"
    case .slotUnavailable: return "RESERVATION_SLOT_001"
    case .automationFailed: return "RESERVATION_AUTOMATION_001"
    case .unknown: return "RESERVATION_UNKNOWN_001"
    case .pageLoadTimeout: return "RESERVATION_TIMEOUT_001"
    case .groupSizePageLoadTimeout: return "RESERVATION_TIMEOUT_002"
    case .numberOfPeopleFieldNotFound: return "RESERVATION_ELEMENT_001"
    case .confirmButtonNotFound: return "RESERVATION_ELEMENT_002"
    case .timeSlotSelectionFailed: return "RESERVATION_SELECTION_001"
    case .contactInfoPageLoadTimeout: return "RESERVATION_TIMEOUT_003"
    case .contactInfoFieldNotFound: return "RESERVATION_ELEMENT_003"
    case .contactInfoConfirmButtonNotFound: return "RESERVATION_ELEMENT_004"
    case .emailVerificationFailed: return "RESERVATION_EMAIL_001"
    case .sportButtonNotFound: return "RESERVATION_ELEMENT_005"
    case .webKitTimeout: return "RESERVATION_TIMEOUT_004"
    }
  }

  /// Category for grouping similar errors
  public var errorCategory: ErrorCategory {
    switch self {
    case .network: return .network
    case .facilityNotFound, .slotUnavailable: return .validation
    case .automationFailed, .sportButtonNotFound, .confirmButtonNotFound,
      .numberOfPeopleFieldNotFound,
      .contactInfoFieldNotFound, .contactInfoConfirmButtonNotFound:
      return .automation
    case .pageLoadTimeout, .groupSizePageLoadTimeout, .contactInfoPageLoadTimeout, .webKitTimeout:
      return .system
    case .emailVerificationFailed: return .authentication
    case .timeSlotSelectionFailed: return .automation
    case .unknown: return .unknown
    }
  }

  /// User-friendly error message for UI display
  public var userFriendlyMessage: String {
    switch self {
    case .network(let msg): return "Network error: \(msg)"
    case .facilityNotFound(let msg): return "Facility not found: \(msg)"
    case .slotUnavailable(let msg): return "Slot unavailable: \(msg)"
    case .automationFailed(let msg): return "Automation failed: \(msg)"
    case .unknown(let msg): return "Unknown error: \(msg)"
    case .pageLoadTimeout: return "Page failed to load in time."
    case .groupSizePageLoadTimeout: return "Group size page failed to load in time."
    case .numberOfPeopleFieldNotFound: return "Number of people field not found."
    case .confirmButtonNotFound: return "Confirm button not found."
    case .timeSlotSelectionFailed: return "Failed to select time slot."
    case .contactInfoPageLoadTimeout: return "Contact info page failed to load in time."
    case .contactInfoFieldNotFound: return "Contact info field not found."
    case .contactInfoConfirmButtonNotFound: return "Contact info confirm button not found."
    case .emailVerificationFailed: return "Email verification failed."
    case .sportButtonNotFound: return "Sport button not found."
    case .webKitTimeout: return "WebKit operation timed out."
    }
  }

  /// Technical details for debugging (optional)
  public var technicalDetails: String? {
    switch self {
    case .network(let msg): return "Network connectivity issue: \(msg)"
    case .facilityNotFound(let msg): return "Facility lookup failed: \(msg)"
    case .slotUnavailable(let msg): return "Time slot availability check failed: \(msg)"
    case .automationFailed(let msg): return "Web automation process failed: \(msg)"
    case .unknown(let msg): return "Unexpected error occurred: \(msg)"
    case .pageLoadTimeout: return "Page load exceeded timeout threshold"
    case .groupSizePageLoadTimeout: return "Group size page load exceeded timeout threshold"
    case .numberOfPeopleFieldNotFound: return "Could not locate number of people input field"
    case .confirmButtonNotFound: return "Could not locate confirmation button"
    case .timeSlotSelectionFailed: return "Failed to select time slot from available options"
    case .contactInfoPageLoadTimeout: return "Contact info page load exceeded timeout threshold"
    case .contactInfoFieldNotFound: return "Could not locate contact information input fields"
    case .contactInfoConfirmButtonNotFound:
      return "Could not locate contact info confirmation button"
    case .emailVerificationFailed: return "Email verification process failed"
    case .sportButtonNotFound: return "Could not locate sport selection button"
    case .webKitTimeout: return "WebKit operation exceeded timeout threshold"
    }
  }
}
