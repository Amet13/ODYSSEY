import Foundation
import os.log

/// WebDriver service for Chrome automation
/// Handles WebDriver protocol communication with ChromeDriver
class WebDriverService: ObservableObject {
    static let shared = WebDriverService()

    @Published var isConnected = false
    @Published var currentSession: String?

    private let logger = Logger(subsystem: "com.odyssey.app", category: "WebDriverService")
    private var chromeDriverProcess: Process?
    private var sessionId: String?
    private let baseURL = "http://localhost:9515"
    private let urlSession: URLSession

    private init() {
        // Create a custom URLSession configuration to prevent CFNetwork crashes
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "ODYSSEY-WebDriver/1.0"]
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: config)

        // Set up global exception handler
        NSSetUncaughtExceptionHandler { exception in
            let logger = Logger(subsystem: "com.odyssey.app", category: "WebDriverService")
            logger.error("CRASH: \(exception.name.rawValue): \(exception.reason ?? "Unknown reason")")
            logger.error("CRASH: Call stack: \(exception.callStackSymbols)")
        }
    }

    // MARK: - Public Methods

    /// Starts ChromeDriver and creates a new WebDriver session
    /// - Returns: True if session was created successfully
    func startSession() async -> Bool {
        guard await startChromeDriver() else {
            logger.error("Failed to start ChromeDriver")
            return false
        }

        // Create new session
        guard let session = await createSession() else {
            logger.error("Failed to create WebDriver session")
            return false
        }

        sessionId = session
        isConnected = true
        currentSession = session
        logger.info("WebDriver session created: \(session)")
        return true
    }

    /// Navigates to a URL
    /// - Parameter url: The URL to navigate to
    /// - Returns: True if navigation was successful
    func navigate(to url: String) async -> Bool {
        guard let sessionId = sessionId else {
            logger.error("No active session")
            return false
        }

        // Force convert sessionId to string
        let sessionIdString = String(describing: sessionId)

        let endpoint = "\(baseURL)/session/\(sessionIdString)/url"
        let body = ["url": url]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create navigation request")
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            let success = statusCode == 200

            logger.info("Navigation result: \(success)")
            return success
        } catch {
            logger.error("Navigation failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Finds an element by text content
    /// - Parameters:
    ///   - text: The text to search for
    ///   - timeout: Timeout in seconds
    /// - Returns: Element ID if found, nil otherwise
    func findElementByText(_ text: String, timeout: TimeInterval = 10) async -> String? {
        guard let sessionId = sessionId else {
            logger.error("No active session")
            return nil
        }

        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            // Try multiple strategies
            if let elementId = await findElementByTextStrategy(text) {
                logger.info("Found element: \(elementId)")
                return elementId
            }

            // Wait before retry
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        logger.warning("Element with text '\(text)' not found within timeout")
        return nil
    }

    /// Clicks an element by its ID
    /// - Parameter elementId: The element ID to click
    /// - Returns: True if click was successful
    func clickElement(_ elementId: String) async -> Bool {
        guard let sessionId = sessionId else {
            logger.error("No active session")
            return false
        }

        // Force convert both to strings
        let sessionIdString = String(describing: sessionId)
        let elementIdString = String(describing: elementId)

        logger.info("Clicking element: \(elementIdString)")

        // Try regular click first
        let regularClickSuccess = await performRegularClick(sessionId: sessionIdString, elementId: elementIdString)
        if regularClickSuccess {
            return true
        }

        // If regular click fails, try JavaScript click
        logger.info("Regular click failed, trying JavaScript click")
        return await performJavaScriptClick(sessionId: sessionIdString, elementId: elementIdString)
    }

    private func performRegularClick(sessionId: String, elementId: String) async -> Bool {
        let endpoint = "\(baseURL)/session/\(sessionId)/element/\(elementId)/click"
        guard let request = createRequest(url: endpoint, method: "POST") else {
            logger.error("Failed to create click request")
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            let success = statusCode == 200

            // Parse error response if click failed
            if statusCode != 200 {
                if let responseData = String(data: data, encoding: .utf8) {
                    do {
                        if let jsonData = responseData.data(using: .utf8),
                           let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                        {
                            if let error = json["error"] as? String {
                                logger.error("WebDriver error: \(error)")
                            }
                            if let message = json["message"] as? String {
                                logger.error("WebDriver message: \(message)")
                            }
                        }
                    } catch {
                        logger.error("Failed to parse error response: \(error)")
                    }
                }
            }

            logger.info("Regular click result: \(success)")
            return success
        } catch {
            logger.error("Regular click failed: \(error.localizedDescription)")
            return false
        }
    }

    private func performJavaScriptClick(sessionId: String, elementId: String) async -> Bool {
        let endpoint = "\(baseURL)/session/\(sessionId)/execute/sync"
        let script = "arguments[0].click();"
        let args = [["element-6066-11e4-a52e-4f735466cecf": elementId]]
        let body: [String: Any] = ["script": script, "args": args]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create JavaScript click request")
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            let success = statusCode == 200

            // Parse error response if click failed
            if statusCode != 200 {
                if let responseData = String(data: data, encoding: .utf8) {
                    do {
                        if let jsonData = responseData.data(using: .utf8),
                           let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                        {
                            if let error = json["error"] as? String {
                                logger.error("WebDriver JavaScript error: \(error)")
                            }
                            if let message = json["message"] as? String {
                                logger.error("WebDriver JavaScript message: \(message)")
                            }
                        }
                    } catch {
                        logger.error("Failed to parse JavaScript error response: \(error)")
                    }
                }
            }

            logger.info("JavaScript click result: \(success)")
            return success
        } catch {
            logger.error("JavaScript click failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Gets the current page source
    /// - Returns: Page source HTML
    func getPageSource() async -> String? {
        guard let sessionId = sessionId else {
            logger.error("No active session")
            return nil
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/source"
        guard let request = createRequest(url: endpoint, method: "GET") else {
            return nil
        }

        do {
            let (data, _) = try await urlSession.data(for: request)
            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return response?["value"] as? String
        } catch {
            logger.error("Failed to get page source: \(error.localizedDescription)")
            return nil
        }
    }

    /// Closes the current session and stops ChromeDriver
    func stopSession() async {
        logger.info("Stopping WebDriver session")

        do {
            if let sessionId = sessionId {
                let sessionIdString = String(describing: sessionId)
                let endpoint = "\(baseURL)/session/\(sessionIdString)"
                if let request = createRequest(url: endpoint, method: "DELETE") {
                    let (data, response) = try await urlSession.data(for: request)
                    let httpResponse = response as? HTTPURLResponse
                    let statusCode = httpResponse?.statusCode ?? 0
                }
            }
        } catch {
            logger.error("Error deleting session: \(error.localizedDescription)")
        }

        sessionId = nil
        isConnected = false
        currentSession = nil

        // Don't terminate ChromeDriver process - let it keep running
        // chromeDriverProcess?.terminate()
        // chromeDriverProcess = nil

        logger.info("WebDriver session stopped (ChromeDriver kept running)")
    }

    /// Finds and clicks an element containing the specified text (simplified version)
    /// - Parameter text: The text to search for
    /// - Returns: True if the element was found and clicked
    func findAndClickElement(withText text: String) async -> Bool {
        guard let sessionId = sessionId else {
            logger.error("No active session")
            return false
        }

        do {
            // Strategy 1: Find the parent <a> element with a child <div class="content"> containing the text
            let xpath1 = "//a[contains(@class, 'button') and .//div[contains(@class, 'content') and contains(text(), '\(text)')]]"
            if let elementId = await findElementByXPath(xpath1, sessionId: String(describing: sessionId)) {
                // Log the tag name of the found element
                if let tagName = await getElementTagName(elementId) {
                    logger.info("Found element with ID: \(elementId) and tag: <\(tagName)> using XPath 1")
                } else {
                    logger.info("Found element with ID: \(elementId) using XPath 1 (tag unknown)")
                }
                let clickResult = await clickElement(elementId)
                if clickResult {
                    // Wait a bit after successful click to see the result
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                }
                return clickResult
            }

            // Strategy 2: Find any clickable element containing the text
            let xpath2 = "//a[contains(., '\(text)')]"
            if let elementId = await findElementByXPath(xpath2, sessionId: String(describing: sessionId)) {
                logger.info("Found clickable element with ID: \(elementId) using XPath 2")
                let clickResult = await clickElement(elementId)
                if clickResult {
                    // Wait a bit after successful click to see the result
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                }
                return clickResult
            }

            // Strategy 3: Find button element containing the text
            let xpath3 = "//button[contains(., '\(text)')]"
            if let elementId = await findElementByXPath(xpath3, sessionId: String(describing: sessionId)) {
                logger.info("Found button element with ID: \(elementId) using XPath 3")
                let clickResult = await clickElement(elementId)
                if clickResult {
                    // Wait a bit after successful click to see the result
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                }
                return clickResult
            }

            // Strategy 4: Find div.content element and try to click it (fallback)
            let xpath4 = "//div[contains(@class, 'content') and contains(text(), '\(text)')]"
            if let elementId = await findElementByXPath(xpath4, sessionId: String(describing: sessionId)) {
                logger.info("Found div.content element with ID: \(elementId) using XPath 4 (fallback)")
                let clickResult = await clickElement(elementId)
                if clickResult {
                    // Wait a bit after successful click to see the result
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                }
                return clickResult
            }

            // Strategy 5: Find any element containing the text (last resort)
            let xpath5 = "//*[contains(., '\(text)')]"
            if let elementId = await findElementByXPath(xpath5, sessionId: String(describing: sessionId)) {
                logger.info("Found any element with ID: \(elementId) using XPath 5 (last resort)")
                let clickResult = await clickElement(elementId)
                if clickResult {
                    // Wait a bit after successful click to see the result
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                }
                return clickResult
            }

            logger.error("Element not found for text: \(text)")
            return false
        } catch {
            logger.error("Error in findAndClickElement: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Private Methods

    private func startChromeDriver() async -> Bool {
        // Check if ChromeDriver is already running
        if await isChromeDriverRunning() {
            logger.info("ChromeDriver is already running")
            return true
        }

        logger.info("Starting ChromeDriver")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/chromedriver")
        process.arguments = ["--port=9515", "--verbose"]

        do {
            try process.run()
            chromeDriverProcess = process

            // Wait for ChromeDriver to start
            for _ in 0 ..< 10 {
                if await isChromeDriverRunning() {
                    logger.info("ChromeDriver started successfully")
                    return true
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }

            logger.error("ChromeDriver failed to start")
            return false
        } catch {
            logger.error("Failed to start ChromeDriver: \(error.localizedDescription)")
            return false
        }
    }

    private func isChromeDriverRunning() async -> Bool {
        guard let url = URL(string: "\(baseURL)/status") else { return false }

        do {
            let (_, response) = try await urlSession.data(for: URLRequest(url: url))
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    private func createSession() async -> String? {
        let endpoint = "\(baseURL)/session"
        let args: [String] = [
            "--incognito",
            "--no-sandbox",
            "--disable-dev-shm-usage",
            "--disable-gpu",
            "--window-size=1920,1080",
        ]

        // Use W3C WebDriver protocol format
        let capabilities: [String: Any] = [
            "capabilities": [
                "alwaysMatch": [
                    "browserName": "chrome",
                    "goog:chromeOptions": [
                        "args": args,
                    ],
                ],
            ],
        ]

        guard let request = createRequest(url: endpoint, method: "POST", body: capabilities) else {
            logger.error("Failed to create request for session")
            return nil
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            // Try different possible session ID locations
            var sessionId: String?

            // Try direct sessionId
            if let id = responseDict?["sessionId"] as? String {
                sessionId = id
            }
            // Try value.sessionId (W3C format)
            else if let value = responseDict?["value"] as? [String: Any],
                    let id = value["sessionId"] as? String
            {
                sessionId = id
            }
            // Try value.session_id
            else if let value = responseDict?["value"] as? [String: Any],
                    let id = value["session_id"] as? String
            {
                sessionId = id
            }

            if let sessionId = sessionId {
                logger.info("Session created successfully: \(sessionId)")
            } else {
                logger.error("No sessionId found in response. Response keys: \(responseDict?.keys.joined(separator: ", ") ?? "none")")
            }

            return sessionId
        } catch {
            logger.error("Failed to create session: \(error.localizedDescription)")
            return nil
        }
    }

    private func findElementByTextStrategy(_ text: String) async -> String? {
        guard let sessionId = sessionId else { return nil }

        do {
            // Strategy 1: Find by XPath containing text
            let xpath = "//*[contains(text(), '\(text)')]"
            if let elementId = await findElementByXPath(xpath, sessionId: sessionId) {
                return elementId
            }

            // Strategy 2: Find by CSS selector for buttons/links
            let selectors = ["button", "a", "div[role='button']", ".sport-button", ".activity-button"]
            for selector in selectors {
                if let elementId = await findElementByCSS(selector, sessionId: sessionId) {
                    // Check if element contains the text
                    if await elementContainsText(elementId, text: text) {
                        return elementId
                    }
                }
            }

            return nil
        } catch {
            logger.error("Error in findElementByTextStrategy: \(error.localizedDescription)")
            return nil
        }
    }

    private func findElementByXPath(_ xpath: String, sessionId: String) async -> String? {
        // Force convert sessionId to string
        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
        let body = ["using": "xpath", "value": xpath]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create findElementByXPath request")
            return nil
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0

            if statusCode != 200 {
                logger.error("findElementByXPath failed with status \(statusCode)")
                return nil
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let value = responseDict?["value"] as? [String: Any] {
                // W3C WebDriver: element-6066-11e4-a52e-4f735466cecf
                if let elementId = value["element-6066-11e4-a52e-4f735466cecf"] as? String {
                    return elementId
                }
                // Legacy: ELEMENT
                if let elementId = value["ELEMENT"] as? String {
                    return elementId
                }
            }

            return nil
        } catch {
            logger.error("findElementByXPath failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func findElementByCSS(_ selector: String, sessionId: String) async -> String? {
        // Force convert sessionId to string
        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
        let body = ["using": "css selector", "value": selector]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            return nil
        }

        do {
            let (data, _) = try await urlSession.data(for: request)
            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let value = response?["value"] as? [String: Any] {
                // W3C WebDriver: element-6066-11e4-a52e-4f735466cecf
                if let elementId = value["element-6066-11e4-a52e-4f735466cecf"] as? String {
                    return elementId
                }
                // Legacy: ELEMENT
                if let elementId = value["ELEMENT"] as? String {
                    return elementId
                }
            }
            return nil
        } catch {
            return nil
        }
    }

    private func elementContainsText(_ elementId: String, text: String) async -> Bool {
        guard let sessionId = sessionId else { return false }

        // Force convert both to strings
        let sessionIdString = String(describing: sessionId)
        let elementIdString = String(describing: elementId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementIdString)/text"
        guard let request = createRequest(url: endpoint, method: "GET") else {
            return false
        }

        do {
            let (data, _) = try await urlSession.data(for: request)
            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let elementText = response?["value"] as? String ?? ""
            return elementText.lowercased().contains(text.lowercased())
        } catch {
            return false
        }
    }

    private func createRequest(url: String, method: String, body: [String: Any]? = nil) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            do {
                let stringifiedBody = stringifyJSON(body)
                request.httpBody = try JSONSerialization.data(withJSONObject: stringifiedBody)
            } catch {
                logger.error("Failed to serialize request body: \(error.localizedDescription)")
                return nil
            }
        }

        return request
    }

    /// Recursively convert all values in a dictionary to strings (except arrays/dictionaries themselves)
    private func stringifyJSON(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            var newDict: [String: Any] = [:]
            for (k, v) in dict {
                newDict[k] = stringifyJSON(v)
            }
            return newDict
        } else if let arr = value as? [Any] {
            return arr.map { stringifyJSON($0) }
        } else if let arr = value as? [String] {
            // Keep string arrays as-is
            return arr
        } else if let num = value as? NSNumber {
            return num.stringValue
        } else if let str = value as? String {
            return str
        } else if let v = value as? CustomStringConvertible {
            return v.description
        } else {
            // Convert anything else to string
            return String(describing: value)
        }
    }

    private func getElementTagName(_ elementId: String) async -> String? {
        guard let sessionId = sessionId else { return nil }
        let sessionIdString = String(describing: sessionId)
        let elementIdString = String(describing: elementId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementIdString)/name"
        guard let request = createRequest(url: endpoint, method: "GET") else { return nil }
        do {
            let (data, _) = try await urlSession.data(for: request)
            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return response?["value"] as? String
        } catch {
            return nil
        }
    }
}
