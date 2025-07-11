//
//  WebDriverService.swift
//  ODYSSEY
//
//  Created by ODYSSEY Team
//
//  IMPORTANT: Button Detection Approach
//  ===================================
//  This service implements a specific approach for detecting and clicking sport buttons
//  that was discovered through extensive testing. The key insight is to target the
//  <div class="content"> elements directly, not the parent <a> tags.
//
//  HTML Structure:
//  <a href="..." class="button no-img" target="_self">
//      <div class="content">Bootcamp</div>
//  </a>
//
//  Working Method:
//  1. Find all <div class="content"> elements using XPath: //div[contains(@class, 'content')]
//  2. Check each div's text content for the target sport name
//  3. Click the div directly using human-like behavior (scroll + mouse events + fallback click)
//
//  Why This Works:
//  - The <div> elements are the actual clickable targets in the DOM
//  - Clicking the <div> triggers the parent <a>'s click handler
//  - Human-like mouse events bypass potential anti-bot detection
//
//  This approach was discovered after trying multiple XPath strategies and parent element
//  lookups. The direct div targeting with human-like clicks is the only reliable method.
//

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
    var sessionId: String?
    let baseURL = "http://localhost:9515"
    let urlSession: URLSession
    // Expose the current user-agent and language
    var currentUserAgent: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    var currentLanguage: String = "en-US,en"

    private init() {
        // Pool of real user-agents
        let userAgents = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
        ]
        let userAgent = userAgents.randomElement() ?? userAgents[0]
        currentUserAgent = userAgent
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": userAgent]
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
        guard let sessionId else {
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
            let (_, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let success = httpResponse?.statusCode == 200

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
        guard sessionId != nil else {
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
        guard sessionId != nil else {
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
            let success = httpResponse?.statusCode == 200

            // Parse error response if click failed
            if httpResponse?.statusCode != 200 {
                if let responseData = String(data: data, encoding: .utf8) {
                    do {
                        if let jsonData = responseData.data(using: .utf8) {
                            if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                if let error = json["error"] as? String {
                                    logger.error("WebDriver error: \(error)")
                                }
                                if let message = json["message"] as? String {
                                    logger.error("WebDriver message: \(message)")
                                }
                            }
                        }
                    } catch {
                        logger.error("Failed to parse error response: \(error)")
                    }
                }
            }

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
            let success = httpResponse?.statusCode == 200

            // Parse error response if click failed
            if httpResponse?.statusCode != 200 {
                if let responseData = String(data: data, encoding: .utf8) {
                    do {
                        if let jsonData = responseData.data(using: .utf8) {
                            if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                if let error = json["error"] as? String {
                                    logger.error("WebDriver JavaScript error: \(error)")
                                }
                                if let message = json["message"] as? String {
                                    logger.error("WebDriver JavaScript message: \(message)")
                                }
                            }
                        }
                    } catch {
                        logger.error("Failed to parse JavaScript error response: \(error)")
                    }
                }
            }

            return success
        } catch {
            logger.error("JavaScript click failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Closes the current tab/window and ends the WebDriver session, but does not terminate ChromeDriver
    func stopSession() async {
        logger.info("Stopping WebDriver session (closing tab only)")

        if let sessionId {
            let sessionIdString = String(describing: sessionId)
            // Close the current window/tab
            let closeWindowEndpoint = "\(baseURL)/session/\(sessionIdString)/window"
            if let closeRequest = createRequest(url: closeWindowEndpoint, method: "DELETE") {
                do {
                    let _ = try await urlSession.data(for: closeRequest)
                    logger.info("Closed current browser tab/window")
                } catch {
                    logger.error("Error closing browser tab/window: \(error.localizedDescription)")
                }
            }
            // Delete the session
            let endpoint = "\(baseURL)/session/\(sessionIdString)"
            if let request = createRequest(url: endpoint, method: "DELETE") {
                do {
                    let _ = try await urlSession.data(for: request)
                } catch {
                    logger.error("Error deleting session: \(error.localizedDescription)")
                }
            }
        }

        sessionId = nil
        isConnected = false
        currentSession = nil

        logger.info("WebDriver session stopped (browser remains open)")
    }

    /// Closes only the current tab/window without stopping the entire session
    func closeCurrentTab() async {
        guard let sessionId else {
            logger.info("No active session to close tab")
            return
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/window"

        guard let request = createRequest(url: endpoint, method: "DELETE") else {
            logger.error("Failed to create close tab request")
            return
        }

        do {
            let (_, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let success = httpResponse?.statusCode == 200

            if success {
                logger.info("Current tab closed successfully")
            } else {
                logger.error("Failed to close current tab")
            }
        } catch {
            logger.error("Error closing current tab: \(error.localizedDescription)")
        }
    }

    /// Finds and clicks an element containing the specified text
    ///
    /// This method uses a robust approach with multiple fallbacks:
    /// 1. Try to find and click the <div> element containing the text
    /// 2. If that fails, try to click the parent <a> element
    /// 3. If that fails, try JavaScript click on the parent <a>
    ///
    /// - Parameter text: The text to search for
    /// - Returns: True if the element was found and clicked
    func findAndClickElement(withText text: String) async -> Bool {
        guard sessionId != nil else {
            logger.error("No active session")
            return false
        }

        logger.info("Searching for sport button: '\(text)'")

        // Use the same XPath as Python Selenium: find div containing the text
        let divXPath = "//div[contains(text(),'\(text)')]"

        if let sessionId, let divId = await findElementByXPath(divXPath, sessionId: String(describing: sessionId)) {
            // Scroll the div into view
            let scrollScript = "arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});"
            _ = await executeScriptWithElement(scrollScript, elementId: divId, sessionId: String(describing: sessionId))

            // Wait a moment for scroll to complete
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Try clicking the div element directly first
            if await clickElement(divId) {
                logger.info("Successfully clicked sport button: '\(text)'")
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds sleep
                return true
            } else {
                logger.warning("Div click failed, trying parent <a> element...")

                // Try JavaScript click on the parent element
                let clickParentScript = "arguments[0].parentElement.click(); return true;"
                if await executeScriptWithElement(clickParentScript, elementId: divId, sessionId: String(describing: sessionId)) != nil {
                    logger.info("Successfully clicked sport button: '\(text)' via parent element")
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds sleep
                    return true
                } else {
                    logger.error("Failed to click sport button: '\(text)'")
                }
            }
        } else {
            logger.error("Sport button not found: '\(text)'")
        }
        return false
    }

    /// Waits for the DOM to be fully loaded and ready
    /// - Returns: True if DOM is ready, false if timeout
    func waitForDOMReady() async -> Bool {
        guard let sessionId else {
            logger.error("No active session for DOM ready check")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        let maxAttempts = 30 // 30 seconds max wait
        var attempts = 0

        while attempts < maxAttempts {
            // Check if document.readyState is 'complete'
            let readyStateScript = "return document.readyState;"
            if let readyState = await executeScript(readyStateScript, sessionId: sessionIdString) as? String {
                if readyState == "complete" {
                    // Also check if sport buttons are present
                    let buttonsCheckScript = "return document.querySelectorAll('a.button').length;"
                    if let buttonCount = await executeScript(buttonsCheckScript, sessionId: sessionIdString) as? Int {
                        if buttonCount > 0 {
                            logger.info("Page loaded successfully with \(buttonCount) sport options")
                            return true
                        }
                    }
                }
            }

            attempts += 1
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }

        logger.error("Page load timeout after \(maxAttempts) seconds")
        return false
    }

    // MARK: - Private Methods

    private func startChromeDriver() async -> Bool {
        // Check if ChromeDriver is already running
        if await isChromeDriverRunning() {
            return true
        }

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

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                return false
            }

            if httpResponse.statusCode == 200 {
                return true
            } else {
                logger.error("ChromeDriver responded with status: \(httpResponse.statusCode)")
                return false
            }
        } catch {
            logger.error("Failed to check ChromeDriver status: \(error.localizedDescription)")
            return false
        }
    }

    private func createSession() async -> String? {
        let endpoint = "\(baseURL)/session"
        // Pool of real user-agents
        let userAgents = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
        ]
        let languages = ["en-US,en", "en-GB,en", "fr-FR,fr"]
        let userAgent = userAgents.randomElement() ?? userAgents[0]
        let language = languages.randomElement() ?? languages[0]
        currentUserAgent = userAgent
        currentLanguage = language
        let width = Int.random(in: 1200 ... 1920)
        let height = Int.random(in: 700 ... 1080)
        let args: [String] = [
            "--incognito",
            "--no-sandbox",
            "--disable-dev-shm-usage",
            "--disable-gpu",
            "--window-size=\(width),\(height)",
            "--user-agent=\(userAgent)",
            "--lang=\(language)",
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
            let _ = httpResponse?.statusCode ?? 0

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

            if let sessionId {
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
        guard let sessionId else { return nil }

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
        guard let sessionId else { return false }

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

    func createRequest(url: String, method: String, body: [String: Any]? = nil) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
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
            for (key, value) in dict {
                newDict[key] = stringifyJSON(value)
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
        guard let sessionId else { return nil }
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

    /// Finds all elements matching the given XPath and returns their element IDs
    func findAllElementsByXPath(_ xpath: String, sessionId: String) async -> [String]? {
        let endpoint = "\(baseURL)/session/\(sessionId)/elements"
        let body = ["using": "xpath", "value": xpath]
        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create findAllElementsByXPath request")
            return nil
        }
        do {
            let (data, httpResponse) = try await urlSession.data(for: request)
            let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode ?? 0
            if statusCode != 200 {
                logger.error("findAllElementsByXPath failed with status \(statusCode)")
                return nil
            }
            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let value = responseDict?["value"] as? [[String: Any]] else {
                logger.error("findAllElementsByXPath: value missing or not array")
                return nil
            }
            // Extract element IDs (W3C and legacy)
            let ids = value.compactMap { $0["element-6066-11e4-a52e-4f735466cecf"] as? String ?? $0["ELEMENT"] as? String }
            return ids
        } catch {
            logger.error("findAllElementsByXPath failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Gets the inner text of an element by ID
    func getElementInnerText(_ elementId: String) async -> String? {
        guard let sessionId else { return nil }
        let sessionIdString = String(describing: sessionId)
        let elementIdString = String(describing: elementId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementIdString)/text"
        guard let request = createRequest(url: endpoint, method: "GET") else {
            logger.error("Failed to create getElementInnerText request")
            return nil
        }
        do {
            let (data, _) = try await urlSession.data(for: request)
            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return response?["value"] as? String
        } catch {
            logger.error("getElementInnerText failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Executes JavaScript code and returns the result
    /// - Parameters:
    ///   - script: The JavaScript code to execute
    ///   - sessionId: The session ID
    /// - Returns: The result of the JavaScript execution, or nil if failed
    private func executeScript(_ script: String, sessionId: String) async -> Any? {
        let endpoint = "\(baseURL)/session/\(sessionId)/execute/sync"
        let body: [String: Any] = ["script": script, "args": []]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create executeScript request")
            return nil
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let success = httpResponse?.statusCode == 200

            if !success {
                logger.error("executeScript failed with status \(httpResponse?.statusCode ?? 0)")
                return nil
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return responseDict?["value"]
        } catch {
            logger.error("executeScript failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Executes JavaScript code and returns the result, passing an element ID
    /// - Parameters:
    ///   - script: The JavaScript code to execute
    ///   - elementId: The element ID to pass to the script
    ///   - sessionId: The session ID
    /// - Returns: The result of the JavaScript execution, or nil if failed
    private func executeScriptWithElement(_ script: String, elementId: String, sessionId: String) async -> Any? {
        let endpoint = "\(baseURL)/session/\(sessionId)/execute/sync"
        let body: [String: Any] = ["script": script, "args": [["element-6066-11e4-a52e-4f735466cecf": elementId]]]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create executeScriptWithElement request")
            return nil
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let success = httpResponse?.statusCode == 200

            if !success {
                logger.error("executeScriptWithElement failed with status \(httpResponse?.statusCode ?? 0)")
                return nil
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return responseDict?["value"]
        } catch {
            logger.error("executeScriptWithElement failed: \(error.localizedDescription)")
            return nil
        }
    }

    // Helper: find parent by XPath relative to element
    private func findElementByXPathRelative(_ xpath: String, sessionId: String, elementId: String) async -> String? {
        let endpoint = "\(baseURL)/session/\(sessionId)/element/\(elementId)/element"
        let body = ["using": "xpath", "value": xpath]
        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create findElementByXPath (relative) request")
            return nil
        }
        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            if statusCode != 200 {
                logger.error("findElementByXPath (relative) failed with status \(statusCode)")
                return nil
            }
            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let value = responseDict?["value"] as? [String: Any] {
                if let elementId = value["element-6066-11e4-a52e-4f735466cecf"] as? String {
                    return elementId
                }
                if let elementId = value["ELEMENT"] as? String {
                    return elementId
                }
            }
            return nil
        } catch {
            logger.error("findElementByXPath (relative) failed: \(error.localizedDescription)")
            return nil
        }
    }
}
