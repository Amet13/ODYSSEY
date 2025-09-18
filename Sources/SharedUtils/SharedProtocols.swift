import Combine
import Foundation
import WebKit
import os

// MARK: - Shared Types

public struct Email {
  public let id: String
  public let from: String
  public let subject: String
  public let body: String
  public let date: Date

  public init(id: String, from: String, subject: String, body: String, date: Date) {
    self.id = id
    self.from = from
    self.subject = subject
    self.body = body
    self.date = date
  }
}

/// ServiceRegistry is a singleton for dependency injection and service lookup.
@MainActor
public final class ServiceRegistry {
  public static let shared = ServiceRegistry()
  private var services: [String: Any] = [:]
  private init() {}
  /**
   Register a service instance for a protocol or type.
   - Parameters:
   - service: The instance to register.
   - type: The protocol or type to register for.
   */
  public func register<T>(_ service: T, for type: T.Type) {
    services[String(describing: type)] = service
  }

  /**
   Resolve a registered service for a protocol or type.
   - Parameter type: The protocol or type to resolve.
   - Returns: The registered instance.
   */
  public func resolve<T>(_ type: T.Type) -> T {
    guard let service = services[String(describing: type)] as? T else {
      fatalError("No service registered for type: \(type)")
    }
    return service
  }
}

// MARK: - WebKitService Protocol

/// Protocol for the main WebKit automation service used by ODYSSEY.
@MainActor
@preconcurrency
public protocol WebKitServiceProtocol: AnyObject, Sendable {
  /// Indicates if the service is connected to a web automation session
  var isConnected: Bool { get }
  /// Indicates if the service is currently running a web automation task
  var isRunning: Bool { get }
  /// The current URL of the web page being displayed
  var currentURL: String? { get }
  /// The title of the current web page
  var pageTitle: String? { get }
  /**
   Establishes a connection to a web automation session.
   - Throws: An error if connection fails.
   */
  func connect() async throws
  /**
   Disconnects from the current web automation session.
   - Parameter closeWindow: Whether to close the browser window.
   */
  func disconnect(closeWindow: Bool) async
  /**
   Navigates the web browser to the specified URL.
   - Parameter url: The URL to navigate to.
   - Throws: An error if navigation fails.
   */
  func navigateToURL(_ url: String) async throws
  // --- Extended API for ODYSSEY automation ---
  /**
   Force reset the WebKit service (for troubleshooting).
   */
  func forceReset() async
  /**
   Checks if the service is in a valid state for operations.
   - Returns: True if valid, false otherwise.
   */
  func isServiceValid() -> Bool
  /**
   Resets the service to a clean state.
   */
  func reset() async
  /// Callback for when the browser window is closed
  var onWindowClosed: ((ReservationRunType) -> Void)? { get set }
  /// The current reservation configuration being automated
  var currentConfig: ReservationConfig? { get set }
  /**
   Waits for the DOM to be ready or for a key button/element to appear.
   - Returns: True if ready, false if timeout.
   */
  func waitForDOMReady() async -> Bool
  /**
   Finds and clicks an element with the given text.
   - Parameter text: The text to search for.
   - Returns: True if the element was found and clicked.
   */
  func findAndClickElement(withText text: String) async -> Bool
  /**
   Waits for the group size page to appear.
   - Returns: True if the page appeared.
   */
  func waitForGroupSizePage() async -> Bool
  /**
   Fills the number of people field.
   - Parameter number: The number of people.
   - Returns: True if successful.
   */
  func fillNumberOfPeople(_ number: Int) async -> Bool
  /**
   Clicks the confirm button on the current page.
   - Returns: True if successful.
   */
  func clickConfirmButton() async -> Bool
  /**
   Selects a time slot for a given day and time string.
   - Parameters:
   - dayName: The day of the week.
   - timeString: The time string.
   - Returns: True if successful.
   */
  func selectTimeSlot(dayName: String, timeString: String) async -> Bool
  /**
   Waits for the contact info page to appear.
   - Returns: True if the page appeared.
   */
  func waitForContactInfoPage() async -> Bool
  /**
   Fills all contact fields using autofill and human-like movements.
   - Parameters:
   - phoneNumber: The user's phone number.
   - email: The user's email address.
   - name: The user's name.
   - Returns: True if successful.
   */
  func fillAllContactFieldsWithAutofillAndHumanMovements(
    phoneNumber: String, email: String, name: String
  ) async
    -> Bool
  /**
   Adds a quick pause (for human-like timing).
   */
  func addQuickPause() async
  /**
   Clicks the contact info confirm button, with retry logic.
   - Returns: True if successful.
   */
  func clickContactInfoConfirmButtonWithRetry() async -> Bool
  /**
   Detects if a retry text is present on the page.
   - Returns: True if retry is needed.
   */
  func detectRetryText() async -> Bool
  func handleCaptchaRetry() async -> Bool
  /**
   Checks if email verification is required.
   - Returns: True if verification is required.
   */
  func isEmailVerificationRequired() async -> Bool
  /**
   Handles the email verification process.
   - Parameter verificationStart: The start time of verification.
   - Returns: True if successful.
   */
  func handleEmailVerification(verificationStart: Date) async -> Bool

  /**
   Checks if the current page indicates a successful reservation completion.
   - Returns: True if reservation is complete.
   */
  func checkReservationComplete() async -> Bool

  /**
   Finds and clicks an element using a CSS selector.
   - Parameter selector: The CSS selector to find the element.
   - Returns: True if the element was found and clicked.
   */
  func findAndClickElement(_ selector: String) async -> Bool

  /**
   Types text into an element using a CSS selector.
   - Parameters:
   - text: The text to type.
   - selector: The CSS selector to find the element.
   - Returns: True if successful.
   */
  func typeText(_ text: String, into selector: String) async -> Bool

  /**
   Expands a day section for the given day name.
   - Parameter dayName: The day name to expand (e.g., "Saturday").
   - Returns: True if successful.
   */
  func expandDaySection(dayName: String) async -> Bool

  /**
   Clicks a time button for the given time string and day name.
   - Parameters:
   - timeString: The time string to click (e.g., "8:15 AM").
   - dayName: The day name for context.
   - Returns: True if successful.
   */
  func clickTimeButton(timeString: String, dayName: String) async -> Bool

  // Screenshot functionality
  /**
   Sets the screenshot directory for failure screenshots.
   - Parameter directory: The directory to save screenshots.
   */
  func setScreenshotDirectory(_ directory: String)

  /**
   Takes a screenshot of the current web page and saves it to the configured directory.
   - Parameters:
   - filename: Optional filename for the screenshot.
   - quality: JPEG quality from 0.0 (lowest) to 1.0 (highest), default 0.7
   - maxWidth: Maximum width in pixels, maintains aspect ratio if specified
   - format: Image format (.png or .jpg), default .jpg for better compression
   - Returns: The path to the saved screenshot, or nil if failed.
   */
  func takeScreenshot(
    filename: String?, quality: Float, maxWidth: CGFloat?, format: ScreenshotFormat
  ) async -> String?
}

// MARK: - EmailService Protocol

@MainActor
public protocol EmailServiceProtocol: AnyObject {
  var isTesting: Bool { get }
  var lastTestResult: EmailService.TestResult? { get }
  var userFacingError: String? { get }

  /**
   Searches for verification emails in the user's inbox.
   - Returns: Array of emails that might contain verification codes.
   - Throws: An error if the search fails.
   */
  func searchForVerificationEmails() async throws -> [Email]
  // ... add other methods as needed ...
}

// MARK: - KeychainService Protocol

@MainActor
public protocol KeychainServiceProtocol: AnyObject {
  // ... add other methods as needed ...
}

// MARK: - Configuration Management Protocol

/// Protocol defining the interface for configuration management.
///
/// Example:
/// ```swift
/// class MyConfigManager: ConfigurationManagerProtocol {
///   var configurations: [ReservationConfig] = []
///   func addConfiguration(_ config: ReservationConfig) { ... }
///   func updateConfiguration(_ config: ReservationConfig) { ... }
///   func deleteConfiguration(with id: UUID) { ... }
///   func saveConfigurations() { ... }
///   func loadConfigurations() { ... }
/// }
/// ```
protocol ConfigurationManagerProtocol: AnyObject {
  /// The list of reservation configurations.
  var configurations: [ReservationConfig] { get }
  /// Adds a new configuration.
  func addConfiguration(_ config: ReservationConfig)
  /// Updates an existing configuration.
  func updateConfiguration(_ config: ReservationConfig)
  /// Deletes a configuration by its UUID.
  func deleteConfiguration(with id: UUID)
  /// Persists all configurations.
  func saveConfigurations()
  /// Loads configurations from storage.
  func loadConfigurations()
}

// MARK: - User Settings Management Protocol

/// Protocol defining the interface for user settings management.
///
/// Example:
/// ```swift
/// class MyUserSettingsManager: UserSettingsManagerProtocol {
///   var userSettings: UserSettings = ...
///   func updateSettings(_ settings: UserSettings) { ... }
///   func saveSettings() { ... }
///   func loadSettings() { ... }
///   func validateSettings() -> Bool { ... }
/// }
/// ```
protocol UserSettingsManagerProtocol: AnyObject {
  /// The current user settings.
  var userSettings: UserSettings { get }
  /// Updates the user settings.
  func updateSettings(_ settings: UserSettings)
  /// Persists the user settings.
  func saveSettings()
  /// Loads user settings from storage.
  func loadSettings()
  /// Validates the current user settings.
  /// @returns True if valid, false otherwise.
  func validateSettings() -> Bool
}

// MARK: - Reservation Management Protocol

/// Protocol defining the interface for reservation management.
///
/// Example:
/// ```swift
/// class MyOrchestrator: ReservationOrchestratorProtocol {
///   var lastRunStatus: ReservationOrchestrator.RunStatus = .idle
///   func runReservation(for config: ReservationConfig, type: ReservationOrchestrator.RunType) async { ... }
///   func stopReservation() async { ... }
///   func emergencyCleanup(runType: ReservationOrchestrator.RunType) async { ... }
/// }
/// ```
protocol ReservationOrchestratorProtocol: AnyObject {
  /// The last run status of the orchestrator.
  var lastRunStatus: ReservationRunStatus { get }
  /// Runs a reservation for the given configuration and type.
  func runReservation(for config: ReservationConfig, type: ReservationRunType) async
  /// Stops the current reservation.
  func stopReservation() async
  /// Performs emergency cleanup for a given run type.
  func emergencyCleanup(runType: ReservationRunType) async
}

// MARK: - Facility Service Protocol

/// Protocol defining the interface for facility services.
///
/// Example:
/// ```swift
/// class MyFacilityService: FacilityServiceProtocol {
///   var isLoading: Bool = false
///   var availableSports: [String] = []
///   var error: String? = nil
///   func fetchAvailableSports(from url: String, completion: @escaping ([String]) -> Void) { ... }
/// }
/// ```
@MainActor
public protocol FacilityServiceProtocol: AnyObject {
  /// Indicates if the service is currently loading data.
  var isLoading: Bool { get }
  /// The list of available sports.
  var availableSports: [String] { get }
  /// The last error message, if any.
  var error: String? { get }
  /// Fetches available sports from the given facility URL.
  /// @param url The facility URL.
  /// @param completion Callback with the detected sports array.
  func fetchAvailableSports(from url: String, completion: @escaping ([String]) -> Void)
}

// MARK: - Status Bar Controller Protocol

/// Protocol defining the interface for status bar controllers.
///
/// Example:
/// ```swift
/// class MyStatusBarController: StatusBarControllerProtocol {
///   func showPopover() { ... }
///   func hidePopover() { ... }
///   func updateStatus(_ status: String) { ... }
///   func showError(_ error: String) { ... }
/// }
/// ```
protocol StatusBarControllerProtocol: AnyObject {
  /// Shows the popover UI.
  func showPopover()
  /// Hides the popover UI.
  func hidePopover()
  /// Updates the status text in the UI.
  func updateStatus(_ status: String)
  /// Shows an error message in the UI.
  func showError(_ error: String)
}

// MARK: - Logging Protocol

/**
 * Protocol defining the interface for logging services.
 *
 * Example:
 * ```swift
 * class MyLogger: LoggingServiceProtocol {
 *   func info(_ message: String) { ... }
 *   func error(_ message: String) { ... }
 *   func warning(_ message: String) { ... }
 *   func debug(_ message: String) { ... }
 * }
 * ```
 */

// MARK: - Validation Protocol

/// Protocol defining the interface for validation services.
///
/// Example:
/// ```swift
/// class MyValidationService: ValidationServiceProtocol {
///   func validateEmail(_ email: String) -> Bool { ... }
///   func validatePhoneNumber(_ phone: String) -> Bool { ... }
///   func validateGmailAppPassword(_ password: String) -> Bool { ... }
///   func validateFacilityURL(_ url: String) -> Bool { ... }
/// }
/// ```
protocol ValidationServiceProtocol {
  /// Validates an email address.
  func validateEmail(_ email: String) -> Bool
  /// Validates a phone number.
  func validatePhoneNumber(_ phone: String) -> Bool
  /// Validates a Gmail app password.
  func validateGmailAppPassword(_ password: String) -> Bool
  /// Validates a facility URL.
  func validateFacilityURL(_ url: String) -> Bool
}

// MARK: - Storage Protocol

/// Protocol defining the interface for data storage services.
///
/// Example:
/// ```swift
/// class MyStorageService: StorageServiceProtocol {
///   func save(_ object: some Encodable, forKey key: String) throws { ... }
///   func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? { ... }
///   func delete(forKey key: String) { ... }
///   func clearAll() { ... }
/// }
/// ```
protocol StorageServiceProtocol {
  /// Saves an encodable object for a given key.
  func save(_ object: some Encodable, forKey key: String) throws
  /// Loads a decodable object for a given key.
  func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T?
  /// Deletes the object for a given key.
  func delete(forKey key: String)
  /// Clears all stored data.
  func clearAll()
}

// MARK: - Network Service Protocol

/// Protocol defining the interface for network services.
///
/// Example:
/// ```swift
/// class MyNetworkService: NetworkServiceProtocol {
///   func makeRequest(to url: URL, method: String, headers: [String: String]?) async throws -> Data { ... }
///   func testConnection(to host: String, port: UInt16) async -> Bool { ... }
/// }
/// ```
protocol NetworkServiceProtocol {
  /// Makes a network request to the given URL.
  func makeRequest(to url: URL, method: String, headers: [String: String]?) async throws -> Data
  /// Tests the connection to a host and port.
  func testConnection(to host: String, port: UInt16) async -> Bool
}

// MARK: - Timer Service Protocol

/// Protocol defining the interface for timer services.
///
/// Example:
/// ```swift
/// class MyTimerService: TimerServiceProtocol {
///   func scheduleTimer(interval: TimeInterval, repeats: Bool, block: @escaping () -> Void) -> Timer { ... }
///   func invalidateTimer(_ timer: Timer) { ... }
///   func scheduleRepeatingTask(interval: TimeInterval, task: @escaping () async -> Void) { ... }
/// }
/// ```
protocol TimerServiceProtocol {
  /// Schedules a timer with the given interval and block.
  func scheduleTimer(interval: TimeInterval, repeats: Bool, block: @escaping () -> Void) -> Timer
  /// Invalidates the given timer.
  func invalidateTimer(_ timer: Timer)
  /// Schedules a repeating async task.
  func scheduleRepeatingTask(interval: TimeInterval, task: @escaping () async -> Void)
}

// MARK: - Error Handling Protocol

/**
 * Protocol defining the interface for error handling services.
 *
 * Example:
 * ```swift
 * class MyErrorHandler: ErrorHandlingServiceProtocol {
 *   func handleError(_ error: Error, context: String, userFacing: Bool) { ... }
 *   func logError(_ message: String, error: Error?, context: String) { ... }
 *   func logWarning(_ message: String, context: String) { ... }
 *   func logInfo(_ message: String, context: String) { ... }
 *   func logSuccess(_ message: String, context: String) { ... }
 * }
 * ```
 */

// MARK: - Unified Error Protocol

/// Protocol defining a unified error interface for consistent error handling across the application.
/// All custom error types should conform to this protocol for better error management and logging.
///
/// Example:
/// ```swift
/// enum MyCustomError: Error, UnifiedErrorProtocol {
///   case networkFailure(String)
///   case validationError(String)
///
///   var errorCode: String {
///     switch self {
///     case .networkFailure: return "NETWORK_001"
///     case .validationError: return "VALIDATION_001"
///     }
///   }
///
///   var errorCategory: ErrorCategory {
///     switch self {
///     case .networkFailure: return .network
///     case .validationError: return .validation
///     }
///   }
///
///   var userFriendlyMessage: String {
///     switch self {
///     case let .networkFailure(message): return "Network issue: \(message)"
///     case let .validationError(message): return "Validation error: \(message)"
///     }
///   }
/// }
/// ```
public protocol UnifiedErrorProtocol: Error, LocalizedError {
  /// Unique error code for categorization and debugging
  var errorCode: String { get }

  /// Category for grouping similar errors
  var errorCategory: ErrorCategory { get }

  /// User-friendly error message for UI display
  var userFriendlyMessage: String { get }

  /// Technical details for debugging (optional)
  var technicalDetails: String? { get }
}

/// Categories for grouping errors by type
public enum ErrorCategory: String, CaseIterable {
  case network = "Network"
  case validation = "Validation"
  case authentication = "Authentication"
  case automation = "Automation"
  case configuration = "Configuration"
  case system = "System"
  case unknown = "Unknown"

  var emoji: String {
    switch self {
    case .network: return "🌐"
    case .validation: return "✅"
    case .authentication: return "🔐"
    case .automation: return "🤖"
    case .configuration: return "⚙️"
    case .system: return "💻"
    case .unknown: return "❓"
    }
  }
}
