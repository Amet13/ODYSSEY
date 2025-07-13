import Combine
import Foundation

// MARK: - WebDriver Protocols

/// Protocol for WebDriver service functionality
public protocol WebDriverServiceProtocol: ObservableObject {
    var isConnected: Bool { get }
    var isRunning: Bool { get }
    var currentURL: String? { get }
    var pageTitle: String? { get }

    func connect() async throws
    func disconnect() async
    func navigateToURL(_ url: String) async throws
    func findElement(by selector: String) async throws -> WebElementProtocol
    func findElements(by selector: String) async throws -> [WebElementProtocol]
    func getPageSource() async throws -> String
    func getCurrentURL() async throws -> String
    func getTitle() async throws -> String
    func takeScreenshot() async throws -> Data
    func waitForElement(by selector: String, timeout: TimeInterval) async throws -> WebElementProtocol
    func waitForElementToDisappear(by selector: String, timeout: TimeInterval) async throws
    func executeScript(_ script: String) async throws -> String
}

/// Protocol for web element functionality
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
    func isSelected() async throws -> Bool
}

// MARK: - WebDriver Errors

/// WebDriver errors for the main app
public enum WebDriverError: Error, LocalizedError {
    case connectionFailed(String)
    case navigationFailed(String)
    case elementNotFound(String)
    case clickFailed(String)
    case typeFailed(String)
    case screenshotFailed(String)
    case timeout(String)
    case scriptExecutionFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .connectionFailed(message):
            return "Connection failed: \(message)"
        case let .navigationFailed(message):
            return "Navigation failed: \(message)"
        case let .elementNotFound(message):
            return "Element not found: \(message)"
        case let .clickFailed(message):
            return "Click failed: \(message)"
        case let .typeFailed(message):
            return "Type failed: \(message)"
        case let .screenshotFailed(message):
            return "Screenshot failed: \(message)"
        case let .timeout(message):
            return "Timeout: \(message)"
        case let .scriptExecutionFailed(message):
            return "Script execution failed: \(message)"
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

// MARK: - WebDriver Element Implementation

/// WebDriver element implementation for the main app
/// Provides concrete implementation of WebElementProtocol for interacting with web elements
public class WebDriverElement: WebElementProtocol {
    public let id: String
    public let tagName: String
    public let type: String?
    public var value: String
    public var isDisplayed: Bool
    public var isEnabled: Bool
    public var isSelected: Bool

    private let sessionId: String
    private let baseURL: String
    private let urlSession: URLSession

    public init(id: String, sessionId: String, baseURL: String, urlSession: URLSession) {
        self.id = id
        self.sessionId = sessionId
        self.baseURL = baseURL
        self.urlSession = urlSession

        // Default values - will be updated by actual element properties
        self.tagName = "div"
        self.type = nil
        self.value = ""
        self.isDisplayed = true
        self.isEnabled = true
        self.isSelected = false
    }

    public func click() async throws {
        let endpoint = "\(baseURL)/session/\(sessionId)/element/\(id)/click"
        guard let request = createRequest(url: endpoint, method: "POST") else {
            throw WebDriverError.clickFailed("Failed to create click request")
        }

        do {
            let (_, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.clickFailed("Click failed with status \(httpResponse?.statusCode ?? 0)")
            }
        } catch {
            throw WebDriverError.clickFailed("Click failed: \(error.localizedDescription)")
        }
    }

    public func type(_ text: String) async throws {
        let endpoint = "\(baseURL)/session/\(sessionId)/element/\(id)/value"
        let body: [String: Any] = ["text": text, "value": [text]]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            throw WebDriverError.typeFailed("Failed to create type request")
        }

        do {
            let (_, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.typeFailed("Type failed with status \(httpResponse?.statusCode ?? 0)")
            }

            value = text
        } catch {
            throw WebDriverError.typeFailed("Type failed: \(error.localizedDescription)")
        }
    }

    public func clear() async throws {
        let endpoint = "\(baseURL)/session/\(sessionId)/element/\(id)/clear"

        guard let request = createRequest(url: endpoint, method: "POST") else {
            throw WebDriverError.typeFailed("Failed to create clear request")
        }

        do {
            let (_, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.typeFailed("Clear failed with status \(httpResponse?.statusCode ?? 0)")
            }

            value = ""
        } catch {
            throw WebDriverError.typeFailed("Clear failed: \(error.localizedDescription)")
        }
    }

    public func getAttribute(_ name: String) async throws -> String? {
        let endpoint = "\(baseURL)/session/\(sessionId)/element/\(id)/attribute/\(name)"

        guard let request = createRequest(url: endpoint, method: "GET") else {
            return nil
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                return nil
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return responseDict?["value"] as? String
        } catch {
            return nil
        }
    }

    public func getText() async throws -> String {
        let endpoint = "\(baseURL)/session/\(sessionId)/element/\(id)/text"

        guard let request = createRequest(url: endpoint, method: "GET") else {
            throw WebDriverError.elementNotFound("Failed to create text request")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.elementNotFound("Get text failed with status \(httpResponse?.statusCode ?? 0)")
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return responseDict?["value"] as? String ?? ""
        } catch {
            throw WebDriverError.elementNotFound("Get text failed: \(error.localizedDescription)")
        }
    }

    public func isDisplayed() async throws -> Bool {
        let endpoint = "\(baseURL)/session/\(sessionId)/element/\(id)/displayed"

        guard let request = createRequest(url: endpoint, method: "GET") else {
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                return false
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return responseDict?["value"] as? Bool ?? false
        } catch {
            return false
        }
    }

    public func isEnabled() async throws -> Bool {
        let endpoint = "\(baseURL)/session/\(sessionId)/element/\(id)/enabled"

        guard let request = createRequest(url: endpoint, method: "GET") else {
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                return false
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return responseDict?["value"] as? Bool ?? false
        } catch {
            return false
        }
    }

    public func isSelected() async throws -> Bool {
        let endpoint = "\(baseURL)/session/\(sessionId)/element/\(id)/selected"

        guard let request = createRequest(url: endpoint, method: "GET") else {
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                return false
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return responseDict?["value"] as? Bool ?? false
        } catch {
            return false
        }
    }

    private func createRequest(url: String, method: String, body: [String: Any]? = nil) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                return nil
            }
        }

        return request
    }
}
