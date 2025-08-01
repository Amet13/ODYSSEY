import Combine
import Foundation

// MARK: - Web Automation Protocols (WebKit).

/// Protocol for web automation service abstraction.
@MainActor
public protocol WebAutomationServiceProtocol: ObservableObject, Sendable {
    /// Indicates if the service is connected to a web automation session.
    var isConnected: Bool { get }
    /// Indicates if the service is currently running a web automation task.
    var isRunning: Bool { get }
    /// The current URL of the web page being displayed.
    var currentURL: String? { get }
    /// The title of the current web page.
    var pageTitle: String? { get }

    /// Establishes a connection to a web automation session.
    func connect() async throws
    /// Disconnects from the current web automation session.
    func disconnect(closeWindow: Bool) async
    /// Navigates the web browser to the specified URL.
    func navigateToURL(_ url: String) async throws
    /// Retrieves the source code of the current web page.
    func getPageSource() async throws -> String
    /// Retrieves the current URL of the web page.
    func getCurrentURL() async throws -> String
    /// Retrieves the title of the current web page.
    func getTitle() async throws -> String

    // --- Extended API for ODYSSEY automation ---.
    func forceReset() async
    func isServiceValid() -> Bool
    func reset() async
    var onWindowClosed: ((ReservationRunType) -> Void)? { get set }
    var currentConfig: ReservationConfig? { get set }
    func waitForDOMReady() async -> Bool
    func findAndClickElement(withText text: String) async -> Bool
    func waitForGroupSizePage() async -> Bool
    func fillNumberOfPeople(_ number: Int) async -> Bool
    func clickConfirmButton() async -> Bool
    func selectTimeSlot(dayName: String, timeString: String) async -> Bool
    func waitForContactInfoPage() async -> Bool
    func fillAllContactFieldsWithAutofillAndHumanMovements(phoneNumber: String, email: String, name: String) async
    -> Bool
    func addQuickPause() async
    func clickContactInfoConfirmButtonWithRetry() async -> Bool
    func detectRetryText() async -> Bool
    func isEmailVerificationRequired() async -> Bool
    func handleEmailVerification(verificationStart: Date) async -> Bool
    func checkReservationComplete() async -> Bool
}

// MARK: - Web Element Protocol.

/// Protocol for web element abstraction.
@preconcurrency
public protocol WebElementProtocol {
    /// Unique identifier for the web element.
    var id: String { get }
    /// The HTML tag name of the element.
    var tagName: String { get }
    /// The type of the element (e.g., "input", "button").
    var type: String? { get }
    /// The value of the element.
    var value: String { get set }
    /// Indicates if the element is currently displayed on the page.
    var isDisplayed: Bool { get }
    /// Indicates if the element is enabled and can be interacted with.
    var isEnabled: Bool { get }
    /// Indicates if the element is selected.
    var isSelected: Bool { get }

    /// Clicks the web element.
    func click() async throws
    /// Types text into the web element.
    func type(_ text: String) async throws
    /// Clears the text from the web element.
    func clear() async throws
    /// Retrieves the value of a specific attribute of the element.
    func getAttribute(_ name: String) async throws -> String?
    /// Retrieves the text content of the web element.
    func getText() async throws -> String
    /// Checks if the element is currently displayed on the page.
    func isDisplayed() async throws -> Bool
    /// Checks if the element is enabled and can be interacted with.
    func isEnabled() async throws -> Bool
}

// MARK: - Web Driver Error Types.

/// Errors thrown by the web driver.
public enum WebDriverError: Error, LocalizedError, UnifiedErrorProtocol {
    /// Navigation to a URL failed.
    case navigationFailed(String)
    /// The requested web element was not found.
    case elementNotFound(String)
    /// Clicking on the web element failed.
    case clickFailed(String)
    /// Typing text into the web element failed.
    case typeFailed(String)
    /// Script execution failed.
    case scriptExecutionFailed(String)
    /// Operation timed out.
    case timeout(String)
    /// Failed to establish a connection to the web automation session.
    case connectionFailed(String)
    /// The provided selector is invalid.
    case invalidSelector(String)
    /// The web element is no longer valid (stale).
    case staleElement(String)

    /// Human-readable error description.
    public var errorDescription: String? {
        return userFriendlyMessage
    }

    /// Unique error code for categorization and debugging
    public var errorCode: String {
        switch self {
        case .navigationFailed: return AppConstants.errorCodes["navigationFailed"] ?? "WEBDRIVER_NAVIGATION_001"
        case .elementNotFound: return AppConstants.errorCodes["elementNotFound"] ?? "WEBDRIVER_ELEMENT_001"
        case .clickFailed: return AppConstants.errorCodes["clickFailed"] ?? "WEBDRIVER_CLICK_001"
        case .typeFailed: return AppConstants.errorCodes["typeFailed"] ?? "WEBDRIVER_TYPE_001"
        case .scriptExecutionFailed: return AppConstants.errorCodes["scriptExecutionFailed"] ?? "WEBDRIVER_SCRIPT_001"
        case .timeout: return AppConstants.errorCodes["timeout"] ?? "WEBDRIVER_TIMEOUT_001"
        case .connectionFailed: return AppConstants.errorCodes["connectionFailed"] ?? "WEBDRIVER_CONNECTION_001"
        case .invalidSelector: return AppConstants.errorCodes["invalidSelector"] ?? "WEBDRIVER_SELECTOR_001"
        case .staleElement: return AppConstants.errorCodes["staleElement"] ?? "WEBDRIVER_STALE_001"
        }
    }

    /// Category for grouping similar errors
    public var errorCategory: ErrorCategory {
        switch self {
        case .navigationFailed, .connectionFailed: return .network
        case .elementNotFound, .invalidSelector, .staleElement: return .automation
        case .clickFailed, .typeFailed, .scriptExecutionFailed: return .automation
        case .timeout: return .system
        }
    }

    /// User-friendly error message for UI display
    public var userFriendlyMessage: String {
        switch self {
        case let .navigationFailed(message):
            return "Navigation failed: \(message)"
        case let .elementNotFound(message):
            return "Element not found: \(message)"
        case let .clickFailed(message):
            return "Click failed: \(message)"
        case let .typeFailed(message):
            return "Type failed: \(message)"
        case let .scriptExecutionFailed(message):
            return "Script execution failed: \(message)"
        case let .timeout(message):
            return "Timeout: \(message)"
        case let .connectionFailed(message):
            return "Connection failed: \(message)"
        case let .invalidSelector(message):
            return "Invalid selector: \(message)"
        case let .staleElement(message):
            return "Stale element: \(message)"
        }
    }

    /// Technical details for debugging (optional)
    public var technicalDetails: String? {
        switch self {
        case let .navigationFailed(message): return "WebKit navigation failed: \(message)"
        case let .elementNotFound(message): return "DOM element not found: \(message)"
        case let .clickFailed(message): return "Element click operation failed: \(message)"
        case let .typeFailed(message): return "Text input operation failed: \(message)"
        case let .scriptExecutionFailed(message): return "JavaScript execution failed: \(message)"
        case let .timeout(message): return "Operation exceeded timeout: \(message)"
        case let .connectionFailed(message): return "WebKit connection failed: \(message)"
        case let .invalidSelector(message): return "CSS selector validation failed: \(message)"
        case let .staleElement(message): return "Element became stale: \(message)"
        }
    }
}

// MARK: - Configuration Type.

/// Configuration for a web driver session.
public struct Configuration: Equatable {
    /// Unique identifier for the configuration.
    public let id: UUID
    /// Name of the configuration.
    public let name: String
    /// Facility URL.
    public let facilityURL: String
    /// Sport name.
    public let sportName: String
    /// Whether the configuration is enabled.
    public let isEnabled: Bool
    /// Initialize a new configuration.
    public init(id: UUID = UUID(), name: String, facilityURL: String, sportName: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.facilityURL = facilityURL
        self.sportName = sportName
        self.isEnabled = isEnabled
    }

    /// Equatable conformance.
    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.facilityURL == rhs.facilityURL &&
            lhs.sportName == rhs.sportName &&
            lhs.isEnabled == rhs.isEnabled
    }
}
