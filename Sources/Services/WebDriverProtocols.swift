import Combine
import Foundation

// MARK: - Web Automation Protocols (WebKit)

/// Protocol for web automation service functionality (WebKit-based)
public protocol WebAutomationServiceProtocol: ObservableObject {
    var isConnected: Bool { get }
    var isRunning: Bool { get }
    var currentURL: String? { get }
    var pageTitle: String? { get }

    func connect() async throws
    func disconnect() async
    func navigateToURL(_ url: String) async throws
    func getPageSource() async throws -> String
    func getCurrentURL() async throws -> String
    func getTitle() async throws -> String
    func takeScreenshot() async throws -> Data
}

// MARK: - Web Element Protocol

/// Protocol for web elements in WebKit-based automation
public protocol WebElementProtocol {
    var id: String { get }
    var tagName: String { get }
    var type: String? { get }
    var value: String { get set }
    var isDisplayed: Bool { get }
    var isEnabled: Bool { get }
    var isSelected: Bool { get }

    func click() async throws
    func type(_ text: String) async throws
    func clear() async throws
    func getAttribute(_ name: String) async throws -> String?
    func getText() async throws -> String
    func isDisplayed() async throws -> Bool
    func isEnabled() async throws -> Bool
}

// MARK: - Web Driver Error Types

/// Error types for WebKit-based automation
public enum WebDriverError: Error, LocalizedError {
    case navigationFailed(String)
    case elementNotFound(String)
    case clickFailed(String)
    case typeFailed(String)
    case scriptExecutionFailed(String)
    case screenshotFailed(String)
    case timeout(String)
    case connectionFailed(String)
    case invalidSelector(String)
    case staleElement(String)

    public var errorDescription: String? {
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
        case let .screenshotFailed(message):
            return "Screenshot failed: \(message)"
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
}

// MARK: - Configuration Type

/// Configuration type for compatibility
public struct Configuration: Equatable {
    public let id: UUID
    public let name: String
    public let facilityURL: String
    public let sportName: String
    public let isEnabled: Bool

    public init(id: UUID = UUID(), name: String, facilityURL: String, sportName: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.facilityURL = facilityURL
        self.sportName = sportName
        self.isEnabled = isEnabled
    }

    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.facilityURL == rhs.facilityURL &&
            lhs.sportName == rhs.sportName &&
            lhs.isEnabled == rhs.isEnabled
    }
}
