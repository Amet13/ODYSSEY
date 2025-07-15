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
class WebDriverService: ObservableObject, WebDriverServiceProtocol {
    static let shared = WebDriverService()

    @Published var isConnected = false
    @Published var currentSession: String?

    // Protocol conformance properties
    @Published var isRunning: Bool = false
    @Published var currentURL: String?
    @Published var pageTitle: String?

    private let logger = Logger(subsystem: "com.odyssey.app", category: "WebDriverService")
    private var chromeDriverProcess: Process?
    var sessionId: String?
    let baseURL = "http://localhost:9515"
    let urlSession: URLSession
    // Expose the current user-agent and language
    var currentUserAgent: String =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    var currentLanguage: String = "en-US,en"

    // Toggle for instant fill mode (set to true for fastest fill, false for human-like typing)
    static var instantFillEnabled: Bool = false

    // Toggle for fast mode (reduces all delays for maximum speed)
    static var fastModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "WebDriverFastMode") }
        set { UserDefaults.standard.set(newValue, forKey: "WebDriverFastMode") }
    }

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
                    _ = try await urlSession.data(for: closeRequest)
                    logger.info("Closed current browser tab/window")
                } catch {
                    logger.error("Error closing browser tab/window: \(error.localizedDescription)")
                }
            }
            // Delete the session
            let endpoint = "\(baseURL)/session/\(sessionIdString)"
            if let request = createRequest(url: endpoint, method: "DELETE") {
                do {
                    _ = try await urlSession.data(for: request)
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

        logger.info("Searching for sport button: '\(text, privacy: .private)'")

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
                logger.info("Successfully clicked sport button: '\(text, privacy: .private)'")
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds sleep
                return true
            } else {
                logger.warning("Div click failed, trying parent <a> element...")

                // Try JavaScript click on the parent element
                let clickParentScript = "arguments[0].parentElement.click(); return true;"
                if
                    await executeScriptWithElement(
                        clickParentScript,
                        elementId: divId,
                        sessionId: String(describing: sessionId),
                    ) != nil
                {
                    logger.info("Successfully clicked sport button: '\(text, privacy: .private)' via parent element")
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds sleep
                    return true
                } else {
                    logger.error("Failed to click sport button: '\(text, privacy: .private)'")
                }
            }
        } else {
            logger.error("Sport button not found: '\(text, privacy: .private)'")
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

    /// Waits for the group size page to load after clicking sport button
    /// - Returns: True if group size page is ready, false if timeout
    func waitForGroupSizePage() async -> Bool {
        guard let sessionId else {
            logger.error("No active session for group size page check")
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
                    // Check if group size form is present
                    let groupSizeCheckScript = "return document.getElementById('reservationCount') !== null;"
                    if
                        let hasGroupSizeForm = await executeScript(
                            groupSizeCheckScript,
                            sessionId: sessionIdString,
                        ) as? Bool
                    {
                        if hasGroupSizeForm {
                            logger.info("Group size page loaded successfully")
                            return true
                        }
                    }
                }
            }

            attempts += 1
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }

        logger.error("Group size page load timeout after \(maxAttempts) seconds")
        return false
    }

    /// Waits for the time selection page to load after clicking confirm button
    /// - Returns: True if time selection page is ready, false if timeout
    func waitForTimeSelectionPage() async -> Bool {
        guard let sessionId else {
            logger.error("No active session for time selection page check")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        let maxAttempts = 30 // 30 seconds max wait
        var attempts = 0

        while attempts < maxAttempts {
            // Check if time selection sections are present
            let sectionsCheckScript = "return document.querySelectorAll('.section.date-list').length;"
            if let sectionCount = await executeScript(sectionsCheckScript, sessionId: sessionIdString) as? Int {
                if sectionCount > 0 {
                    logger.info("Time selection page loaded successfully with \(sectionCount) date sections")
                    return true
                }
            }

            attempts += 1
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }

        logger.error("Time selection page load timeout after \(maxAttempts) seconds")
        return false
    }

    /// Expands a date section that contains the specified day
    /// - Parameter dayName: The day name to search for (e.g., "Tue", "Tuesday")
    /// - Returns: True if section was found and expanded (or already expanded), false otherwise
    func expandDateSection(for dayName: String) async -> Bool {
        guard let sessionId else {
            logger.error("No active session for expanding date section")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        logger.info("Searching for date section containing: '\(dayName, privacy: .private)'")

        // Map short day to full day name
        let fullDayName: String = switch dayName.lowercased() {
        case "mon": "Monday"
        case "tue": "Tuesday"
        case "wed": "Wednesday"
        case "thu": "Thursday"
        case "fri": "Friday"
        case "sat": "Saturday"
        case "sun": "Sunday"
        default: dayName
        }

        // Use placeholders and replace in Swift
        let expandLogicScriptTemplate = """
            try {
                const sections = document.querySelectorAll('.section.date-list .date');
                let allHeaders = [];
                for (let section of sections) {
                    const headerText = section.querySelector('.header-text');
                    if (headerText) {
                        allHeaders.push(headerText.textContent.trim());
                        const headerContent = headerText.textContent.trim();
                        if (headerContent.includes('__DAY_NAME__') || headerContent.includes('__FULL_DAY_NAME__')) {
                            const timesList = section.querySelector('.times-list');
                            const plusIcon = section.querySelector('.expand-gfx.fa-plus-square');
                            const minusIcon = section.querySelector('.expand-gfx.fa-minus-square');
                            const titleElement = section.querySelector('.title');
                            let isExpanded = false;
                            if (timesList && timesList.style.display !== 'none') isExpanded = true;
                            if (minusIcon) isExpanded = true;
                            if (plusIcon) isExpanded = false;
                            // Log which header is being clicked
                            window._odysseyClickedHeader = headerContent;
                            if (isExpanded) {
                                return 'already-expanded';
                            } else if (titleElement) {
                                titleElement.click();
                                return 'clicked-to-expand';
                            } else {
                                return 'no-title-element';
                            }
                        }
                    }
                }
                window._odysseyAllHeaders = allHeaders;
                return 'not-found';
            } catch (e) {
                window._odysseyDebug = {error: e && e.message ? e.message : String(e)};
                return 'js-error';
            }
        """
        let safeDayName = dayName.replacingOccurrences(of: "'", with: "\\'")
        let safeFullDayName = fullDayName.replacingOccurrences(of: "'", with: "\\'")
        let expandLogicScript = expandLogicScriptTemplate
            .replacingOccurrences(of: "__DAY_NAME__", with: safeDayName)
            .replacingOccurrences(of: "__FULL_DAY_NAME__", with: safeFullDayName)
        logger.info("expandDateSection JS: \(expandLogicScript)")

        // Log all found headers before attempting to expand
        let logHeadersScript = "return window._odysseyAllHeaders ? JSON.stringify(window._odysseyAllHeaders) : null;"
        if let headersJson = await executeScript(logHeadersScript, sessionId: sessionIdString) as? String {
            logger.info("Found date section headers: \(headersJson)")
        }

        if let result = await executeScript(expandLogicScript, sessionId: sessionIdString) as? String {
            // Log which header was clicked (if any)
            let clickedHeaderScript = "return window._odysseyClickedHeader ? window._odysseyClickedHeader : null;"
            if let clickedHeader = await executeScript(clickedHeaderScript, sessionId: sessionIdString) as? String {
                logger.info("Clicked date section header: \(clickedHeader)")
            }
            if result == "already-expanded" {
                logger.info("Section for \(dayName, privacy: .private) is already expanded.")
                return true
            } else if result == "clicked-to-expand" {
                logger.info("Clicked to expand section for \(dayName, privacy: .private)")
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second wait after clicking
                return true
            } else {
                let debugScript = "return window._odysseyAllHeaders ? JSON.stringify(window._odysseyAllHeaders) : null;"
                if let debugInfo = await executeScript(debugScript, sessionId: sessionIdString) as? String {
                    logger.warning("Section expand debug info: \(debugInfo)")
                }
                logger.error("Failed to find section for: '\(dayName, privacy: .private)'")
                return false
            }
        }
        logger.error("Failed to find or expand date section for: '\(dayName, privacy: .private)'")
        return false
    }

    /// - Returns: True if time button was found and clicked, false otherwise
    func clickTimeButton(timeString: String) async -> Bool {
        guard let sessionId else {
            logger.error("No active session for clicking time button")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        logger.info("Searching for time button: '\(timeString, privacy: .private)'")

        // Wait a moment after expanding section to ensure buttons are loaded
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second (configurable if needed)

        // Helper to normalize time strings
        func normalize(_ s: String) -> String {
            return s
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\u{202F}", with: " ") // narrow no-break space
                .replacingOccurrences(of: "\u{00A0}", with: " ") // no-break space
                .lowercased()
        }
        let normalizedSearch = normalize(timeString)

        // Log all available time labels in the expanded section
        let logTimesScript = """
            const times = [];
            document.querySelectorAll('.time-container').forEach(btn => {
                const label = btn.querySelector('.available-time');
                if (label) times.push(label.textContent.trim());
            });
            return times;
        """
        var availableLabels: [String] = []
        if let labels = await executeScript(logTimesScript, sessionId: sessionIdString) as? [String] {
            availableLabels = labels
            let normalizedLabels = labels.map { normalize($0) }
            logger.info("Available time labels (normalized): \(normalizedLabels)")
            logger.info("Normalized search string: \(normalizedSearch)")
        }

        // Try strict match (normalized)
        let strictMatchScript = #"""
            const search = arguments[0];
            const timeButtons = document.querySelectorAll('.time-container');
            for (let button of timeButtons) {
                const timeLabel = button.querySelector('.available-time');
                if (timeLabel && timeLabel.textContent.trim().replace(/\s+/g, ' ').replace(/\u202F|\u00A0/g, ' ').toLowerCase() === search) {
                    const timeItem = button.closest('.time');
                    if (timeItem && !timeItem.classList.contains('reserved')) {
                        button.click();
                        return true;
                    }
                }
            }
            return false;
        """#
        if
            let clicked = await executeScript(
                strictMatchScript,
                sessionId: sessionIdString,
            ) as? Bool, clicked
        {
            logger
                .info("Successfully clicked time button (strict normalized match): '\(timeString, privacy: .private)'")
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            return true
        }

        // Fallback: Try contains match (normalized)
        let containsMatchScript = #"""
            const search = arguments[0];
            const timeButtons = document.querySelectorAll('.time-container');
            for (let button of timeButtons) {
                const timeLabel = button.querySelector('.available-time');
                if (timeLabel && timeLabel.textContent.trim().replace(/\s+/g, ' ').replace(/\u202F|\u00A0/g, ' ').toLowerCase().includes(search)) {
                    const timeItem = button.closest('.time');
                    if (timeItem && !timeItem.classList.contains('reserved')) {
                        button.click();
                        return true;
                    }
                }
            }
            return false;
        """#
        if
            let clicked = await executeScript(
                containsMatchScript,
                sessionId: sessionIdString,
            ) as? Bool, clicked
        {
            logger
                .info(
                    "Successfully clicked time button (contains normalized match): '\(timeString, privacy: .private)'",
                )
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            return true
        }

        // Fallback: Try clicking the first available time (if any)
        if !availableLabels.isEmpty {
            logger
                .warning(
                    "No exact/contains match for time. Attempting to click the first available time: \(availableLabels[0])",
                )
            let clickFirstScript = """
                const timeButtons = document.querySelectorAll('.time-container');
                for (let button of timeButtons) {
                    const timeItem = button.closest('.time');
                    if (timeItem && !timeItem.classList.contains('reserved')) {
                        button.click();
                        return true;
                    }
                }
                return false;
            """
            if let clicked = await executeScript(clickFirstScript, sessionId: sessionIdString) as? Bool, clicked {
                logger.info("Clicked the first available time button as fallback.")
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                return true
            }
        }

        logger
            .error(
                "Failed to find or click time button: '\(timeString, privacy: .private)'. Available labels: \(availableLabels)",
            )
        return false
    }

    /// Finds and clicks a time slot based on day and time configuration
    /// - Parameters:
    ///   - dayName: The day name to search for (e.g., "Tue", "Tuesday")
    ///   - timeString: The time to click (e.g., "8:30 AM")
    /// - Returns: True if the time slot was successfully selected, false otherwise
    func selectTimeSlot(dayName: String, timeString: String) async -> Bool {
        logger.info("Selecting time slot: \(dayName, privacy: .private) at \(timeString, privacy: .private)")

        // Step 1: Expand the date section
        let sectionExpanded = await expandDateSection(for: dayName)
        if !sectionExpanded {
            logger.error("Failed to expand date section for: '\(dayName, privacy: .private)'")
            return false
        }

        // Step 2: Wait a bit longer to ensure UI is rendered
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second (configurable)

        // Step 3: Click the time button
        let timeClicked = await clickTimeButton(timeString: timeString)
        if !timeClicked {
            logger.error("Failed to click time button: '\(timeString, privacy: .private)'")
            return false
        }

        logger
            .info("Successfully selected time slot: \(dayName, privacy: .private) at \(timeString, privacy: .private)")
        return true
    }

    /// Fills the number of people field on the group size page
    /// - Parameter numberOfPeople: The number of people to set (1 or 2)
    /// - Returns: True if field was filled successfully
    func fillNumberOfPeople(_ numberOfPeople: Int) async -> Bool {
        guard let sessionId else {
            logger.error("No active session for filling number of people")
            return false
        }

        let sessionIdString = String(describing: sessionId)

        // Find the reservation count input field
        let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
        let body = ["using": "id", "value": "reservationCount"]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create find element request for reservation count")
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                logger.error("Failed to find reservation count field")
                return false
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let value = responseDict?["value"] as? [String: Any] {
                let elementId = value["element-6066-11e4-a52e-4f735466cecf"] as? String ?? value["ELEMENT"] as? String
                if let elementId {
                    // First, check the current value
                    let getValueEndpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementId)/property/value"
                    guard let getValueRequest = createRequest(url: getValueEndpoint, method: "GET") else {
                        logger.error("Failed to create get value request")
                        return false
                    }

                    let (valueData, valueResponse) = try await urlSession.data(for: getValueRequest)
                    let valueHttpResponse = valueResponse as? HTTPURLResponse

                    if valueHttpResponse?.statusCode == 200 {
                        let valueResponseDict = try JSONSerialization.jsonObject(with: valueData) as? [String: Any]
                        let currentValue = valueResponseDict?["value"] as? String ?? "1"
                        logger.info("Current value in field: '\(currentValue)', setting to: '\(numberOfPeople)'")
                    }

                    // Clear the field first (this removes the default "1" value)
                    let clearEndpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementId)/clear"
                    guard let clearRequest = createRequest(url: clearEndpoint, method: "POST") else {
                        logger.error("Failed to create clear request")
                        return false
                    }

                    let (_, clearResponse) = try await urlSession.data(for: clearRequest)
                    let clearHttpResponse = clearResponse as? HTTPURLResponse

                    if clearHttpResponse?.statusCode != 200 {
                        logger.error("Failed to clear reservation count field")
                        return false
                    }

                    logger.info("Successfully cleared the field")

                    // Add a small delay to simulate human behavior
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                    // Fill the field with the number of people
                    let fillEndpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementId)/value"
                    let fillBody: [String: Any] = ["text": String(numberOfPeople), "value": [String(numberOfPeople)]]

                    guard let fillRequest = createRequest(url: fillEndpoint, method: "POST", body: fillBody) else {
                        logger.error("Failed to create fill request")
                        return false
                    }

                    let (_, fillResponse) = try await urlSession.data(for: fillRequest)
                    let fillHttpResponse = fillResponse as? HTTPURLResponse

                    if fillHttpResponse?.statusCode == 200 {
                        logger.info("Successfully filled number of people: \(numberOfPeople)")

                        // Add another small delay after filling
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

                        return true
                    } else {
                        logger.error("Failed to fill number of people field")
                        return false
                    }
                }
            }

            logger.error("Failed to extract element ID for reservation count field")
            return false
        } catch {
            logger.error("Error filling number of people: \(error.localizedDescription)")
            return false
        }
    }

    /// Fills the number of people field using JavaScript (alternative method)
    /// - Parameter numberOfPeople: The number of people to set (1 or 2)
    /// - Returns: True if field was filled successfully
    func fillNumberOfPeopleWithJavaScript(_ numberOfPeople: Int) async -> Bool {
        guard let sessionId else {
            logger.error("No active session for filling number of people with JavaScript")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/execute/sync"

        // JavaScript to clear and fill the field
        let script = """
            const field = document.getElementById('reservationCount');
            if (field) {
                field.value = '';
                field.focus();
                field.value = '\(numberOfPeople)';
                field.dispatchEvent(new Event('input', { bubbles: true }));
                field.dispatchEvent(new Event('change', { bubbles: true }));
                return true;
            }
            return false;
        """

        let body: [String: Any] = [
            "script": script,
            "args": [],
        ]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create JavaScript fill request")
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode == 200 {
                let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let result = responseDict?["value"] as? Bool, result {
                    logger.info("Successfully filled number of people with JavaScript: \(numberOfPeople)")
                    return true
                } else {
                    logger.error("JavaScript fill returned false")
                    return false
                }
            } else {
                logger.error("JavaScript fill failed with status \(httpResponse?.statusCode ?? 0)")
                return false
            }
        } catch {
            logger.error("Error filling number of people with JavaScript: \(error.localizedDescription)")
            return false
        }
    }

    /// Clicks the confirm button on the group size page
    /// - Returns: True if confirm button was clicked successfully
    func clickConfirmButton() async -> Bool {
        guard let sessionId else { return false }
        let sessionIdString = String(describing: sessionId)
        // Only use the most reliable selectors
        let selectors = [
            ["using": "id", "value": "submit-btn"],
            ["using": "css selector", "value": ".mdc-button__ripple"],
        ]
        var elementId: String?
        for selector in selectors {
            let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
            guard let request = createRequest(url: endpoint, method: "POST", body: selector) else { continue }
            do {
                let (data, response) = try await urlSession.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if
                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let value = json["value"] as? [String: Any],
                        let eid = value["element-6066-11e4-a52e-4f735466cecf"] as? String
                    {
                        elementId = eid
                        break
                    }
                }
            } catch { continue }
        }
        if let elementId {
            let clickEndpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementId)/click"
            if let clickRequest = createRequest(url: clickEndpoint, method: "POST") {
                do {
                    let (_, clickResponse) = try await urlSession.data(for: clickRequest)
                    if let httpResponse = clickResponse as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        return true
                    }
                } catch { }
            }
        }
        // Fallback: Use JavaScript to click the ripple element
        let js = """
            var ripple = document.querySelector('.mdc-button__ripple');
            if (ripple) {
                ripple.dispatchEvent(new MouseEvent('click', {bubbles: true, cancelable: true, view: window}));
                return true;
            }
            return false;
        """
        let jsEndpoint = "\(baseURL)/session/\(sessionIdString)/execute/sync"
        let jsBody: [String: Any] = ["script": js, "args": []]
        if let jsRequest = createRequest(url: jsEndpoint, method: "POST", body: jsBody) {
            do {
                let (data, response) = try await urlSession.data(for: jsRequest)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if
                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let value = json["value"] as? Bool, value == true
                    {
                        return true
                    }
                }
            } catch { }
        }
        return false
    }

    private func performJavaScriptFormSubmit(sessionId: String) async -> Bool {
        let endpoint = "\(baseURL)/session/\(sessionId)/execute/sync"
        let script = """
            const form = document.getElementById('mainForm');
            if (form) {
                form.submit();
                return true;
            }
            return false;
        """
        let body: [String: Any] = ["script": script, "args": []]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create JavaScript form submit request")
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode == 200 {
                let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let result = responseDict?["value"] as? Bool, result {
                    return true
                }
            }

            // Log the error response for debugging
            if let responseData = String(data: data, encoding: .utf8) {
                logger.error("JavaScript form submit failed with response: \(responseData)")
            }
            return false
        } catch {
            logger.error("JavaScript form submit failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Checks if the confirm button is clickable and logs its properties
    /// - Returns: True if button is found and appears clickable
    func checkConfirmButtonStatus() async -> Bool {
        guard let sessionId else {
            logger.error("No active session for checking confirm button")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/execute/sync"

        let script = """
            const button = document.getElementById('submit-btn');
            if (button) {
                return {
                    exists: true,
                    visible: button.offsetParent !== null,
                    enabled: !button.disabled,
                    text: button.textContent || button.innerText,
                    className: button.className,
                    type: button.type,
                    id: button.id,
                    style: button.style.cssText
                };
            }
            return { exists: false };
        """

        let body: [String: Any] = ["script": script, "args": []]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create button status check request")
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode == 200 {
                let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let result = responseDict?["value"] as? [String: Any] {
                    if let exists = result["exists"] as? Bool, exists {
                        let visible = result["visible"] as? Bool ?? false
                        let enabled = result["enabled"] as? Bool ?? false
                        let text = result["text"] as? String ?? "unknown"
                        let className = result["className"] as? String ?? "unknown"

                        logger.info("Confirm button found:")
                        logger.info("  - Text: '\(text)'")
                        logger.info("  - Visible: \(visible)")
                        logger.info("  - Enabled: \(enabled)")
                        logger.info("  - Class: \(className)")

                        return visible && enabled
                    } else {
                        logger.error("Confirm button does not exist")
                        return false
                    }
                }
            }

            logger.error("Failed to check button status")
            return false
        } catch {
            logger.error("Error checking button status: \(error.localizedDescription)")
            return false
        }
    }

    /// Checks for and clicks the cookie consent button if present
    /// - Returns: True if cookie button was found and clicked, false if not present
    func handleCookieConsent() async -> Bool {
        guard let sessionId else {
            logger.error("No active session for cookie consent handling")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        logger.info("Checking for cookie consent banner...")

        // Check if cookie consent banner is present
        let checkCookieScript = """
            const cookieBanner = document.getElementById('cookieConsent');
            if (cookieBanner && cookieBanner.style.display !== 'none') {
                return true;
            }
            return false;
        """

        if
            let bannerPresent = await executeScript(checkCookieScript, sessionId: sessionIdString) as? Bool,
            bannerPresent
        {
            logger.info("Cookie consent banner detected, attempting to accept...")

            // Click the "Accept necessary cookies" button
            let acceptCookieScript = """
                const acceptButton = document.querySelector('button[data-cookie-string*="Consent=yes"]');
                if (acceptButton) {
                    acceptButton.click();
                    return true;
                }
                return false;
            """

            if let accepted = await executeScript(acceptCookieScript, sessionId: sessionIdString) as? Bool, accepted {
                logger.info("Successfully accepted cookies")

                // Wait a moment for the banner to disappear
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                return true
            } else {
                logger.warning("Cookie banner present but accept button not found")
                return false
            }
        } else {
            logger.info("No cookie consent banner detected")
            return false
        }
    }

    // MARK: - WebDriverServiceProtocol Implementation

    /// Protocol method: Connect to WebDriver
    func connect() async throws {
        let success = await startSession()
        if !success {
            throw WebDriverError.connectionFailed("Failed to start WebDriver session")
        }
    }

    /// Protocol method: Disconnect from WebDriver
    func disconnect() async {
        await stopSession()
    }

    /// Protocol method: Navigate to URL (throws version)
    func navigateToURL(_ url: String) async throws {
        let success = await self.navigate(to: url)
        if !success {
            throw WebDriverError.navigationFailed("Failed to navigate to \(url)")
        }
        currentURL = url
    }

    /// Protocol method: Find element by selector
    func findElement(by selector: String) async throws -> WebElementProtocol {
        guard let sessionId else {
            throw WebDriverError.elementNotFound("No active session")
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
        let body = ["using": "css selector", "value": selector]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            throw WebDriverError.elementNotFound("Failed to create request")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.elementNotFound("Element not found: \(selector)")
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let value = responseDict?["value"] as? [String: Any] {
                let elementId = value["element-6066-11e4-a52e-4f735466cecf"] as? String ?? value["ELEMENT"] as? String
                if let elementId {
                    return WebDriverElement(
                        id: elementId,
                        sessionId: sessionIdString,
                        baseURL: baseURL,
                        urlSession: urlSession,
                    )
                }
            }

            throw WebDriverError.elementNotFound("Element not found: \(selector)")
        } catch {
            throw WebDriverError.elementNotFound("Failed to find element: \(error.localizedDescription)")
        }
    }

    /// Protocol method: Find elements by selector
    func findElements(by selector: String) async throws -> [WebElementProtocol] {
        guard let sessionId else {
            throw WebDriverError.elementNotFound("No active session")
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/elements"
        let body = ["using": "css selector", "value": selector]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            throw WebDriverError.elementNotFound("Failed to create request")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.elementNotFound("Elements not found: \(selector)")
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let value = responseDict?["value"] as? [[String: Any]] {
                return value.compactMap { elementDict in
                    let elementId = elementDict["element-6066-11e4-a52e-4f735466cecf"] as? String ??
                        elementDict["ELEMENT"] as? String
                    if let elementId {
                        return WebDriverElement(
                            id: elementId,
                            sessionId: sessionIdString,
                            baseURL: baseURL,
                            urlSession: urlSession,
                        )
                    }
                    return nil
                }
            }

            return []
        } catch {
            throw WebDriverError.elementNotFound("Failed to find elements: \(error.localizedDescription)")
        }
    }

    /// Protocol method: Get page source
    func getPageSource() async throws -> String {
        guard let sessionId else {
            throw WebDriverError.scriptExecutionFailed("No active session")
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/source"

        guard let request = createRequest(url: endpoint, method: "GET") else {
            throw WebDriverError.scriptExecutionFailed("Failed to create request")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.scriptExecutionFailed("Failed to get page source")
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return responseDict?["value"] as? String ?? ""
        } catch {
            throw WebDriverError.scriptExecutionFailed("Failed to get page source: \(error.localizedDescription)")
        }
    }

    /// Protocol method: Get current URL
    func getCurrentURL() async throws -> String {
        guard let sessionId else {
            throw WebDriverError.scriptExecutionFailed("No active session")
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/url"

        guard let request = createRequest(url: endpoint, method: "GET") else {
            throw WebDriverError.scriptExecutionFailed("Failed to create request")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.scriptExecutionFailed("Failed to get current URL")
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return responseDict?["value"] as? String ?? ""
        } catch {
            throw WebDriverError.scriptExecutionFailed("Failed to get current URL: \(error.localizedDescription)")
        }
    }

    /// Protocol method: Get page title
    func getTitle() async throws -> String {
        guard let sessionId else {
            throw WebDriverError.scriptExecutionFailed("No active session")
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/title"

        guard let request = createRequest(url: endpoint, method: "GET") else {
            throw WebDriverError.scriptExecutionFailed("Failed to create request")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.scriptExecutionFailed("Failed to get title")
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return responseDict?["value"] as? String ?? ""
        } catch {
            throw WebDriverError.scriptExecutionFailed("Failed to get title: \(error.localizedDescription)")
        }
    }

    /// Protocol method: Take screenshot
    func takeScreenshot() async throws -> Data {
        guard let sessionId else {
            throw WebDriverError.screenshotFailed("No active session")
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/screenshot"

        guard let request = createRequest(url: endpoint, method: "GET") else {
            throw WebDriverError.screenshotFailed("Failed to create request")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.screenshotFailed("Failed to take screenshot")
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if
                let base64String = responseDict?["value"] as? String,
                let screenshotData = Data(base64Encoded: base64String)
            {
                return screenshotData
            }

            throw WebDriverError.screenshotFailed("Invalid screenshot data")
        } catch {
            throw WebDriverError.screenshotFailed("Failed to take screenshot: \(error.localizedDescription)")
        }
    }

    /// Protocol method: Wait for element
    func waitForElement(by selector: String, timeout: TimeInterval) async throws -> WebElementProtocol {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            do {
                return try await findElement(by: selector)
            } catch {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        }

        throw WebDriverError.timeout("Element not found within timeout: \(selector)")
    }

    /// Protocol method: Wait for element to disappear
    func waitForElementToDisappear(by selector: String, timeout: TimeInterval) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            do {
                _ = try await findElement(by: selector)
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            } catch {
                return // Element disappeared
            }
        }

        throw WebDriverError.timeout("Element did not disappear within timeout: \(selector)")
    }

    /// Protocol method: Execute script
    func executeScript(_ script: String) async throws -> String {
        guard let sessionId else {
            throw WebDriverError.scriptExecutionFailed("No active session")
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/execute/sync"
        let body: [String: Any] = ["script": script, "args": []]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            throw WebDriverError.scriptExecutionFailed("Failed to create request")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode != 200 {
                throw WebDriverError.scriptExecutionFailed("Script execution failed")
            }

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let value = responseDict?["value"] {
                return String(describing: value)
            }

            return ""
        } catch {
            throw WebDriverError.scriptExecutionFailed("Script execution failed: \(error.localizedDescription)")
        }
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
        let width = Int.random(in: 1_200 ... 1_920)
        let height = Int.random(in: 700 ... 1_080)
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
            _ = httpResponse?.statusCode ?? 0

            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            // Try different possible session ID locations
            var sessionId: String?

            // Try direct sessionId
            if let id = responseDict?["sessionId"] as? String {
                sessionId = id
            }
            // Try value.sessionId (W3C format)
            else if
                let value = responseDict?["value"] as? [String: Any],
                let id = value["sessionId"] as? String
            {
                sessionId = id
            }
            // Try value.session_id
            else if
                let value = responseDict?["value"] as? [String: Any],
                let id = value["session_id"] as? String
            {
                sessionId = id
            }

            if let sessionId {
                logger.info("Session created successfully: \(sessionId)")
            } else {
                logger
                    .error(
                        "No sessionId found in response. Response keys: \(responseDict?.keys.joined(separator: ", ") ?? "none")",
                    )
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
            let ids = value
                .compactMap { $0["element-6066-11e4-a52e-4f735466cecf"] as? String ?? $0["ELEMENT"] as? String }
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

    /// Captures a screenshot of the current browser tab
    /// - Returns: Screenshot data if successful, nil otherwise
    func captureScreenshot() async -> Data? {
        guard let sessionId else {
            logger.error("No active session for screenshot capture")
            return nil
        }

        let sessionIdString = String(describing: sessionId)
        let endpoint = "\(baseURL)/session/\(sessionIdString)/screenshot"

        guard let request = createRequest(url: endpoint, method: "GET") else {
            logger.error("Failed to create screenshot request")
            return nil
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let base64String = json["value"] as? String,
                    let screenshotData = Data(base64Encoded: base64String)
                {
                    logger.info("Screenshot captured successfully")
                    return screenshotData
                }
            }
        } catch {
            logger.error("Failed to capture screenshot: \(error)")
        }

        return nil
    }

    // Helper for appending debug info to a file (only in debug builds)
    private func appendDebugLog(_ message: String) {
        #if DEBUG
            logger.debug("\(message)")
        #endif
    }

    // Helper to log all input fields for debugging when field detection fails (only in debug builds)
    private func logAllInputFields(sessionId _: String, fieldType: String) async {
        #if DEBUG
            logger.debug("Logging all input fields for \(fieldType) field detection")
        #endif
    }

    // Call this after navigation and after each major step (only in debug builds)
    func logCurrentPageSource(_ context: String) async {
        #if DEBUG
            do {
                let pageSource = try await getPageSource()
                logger.debug("Page source after \(context): \(pageSource)")
            } catch {
                logger.debug("Failed to get page source after \(context): \(error.localizedDescription)")
            }
        #endif
    }

    func waitForContactInfoPage() async -> Bool {
        guard let sessionId else {
            logger.error("No active session for waiting contact info page")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        let startTime = Date()
        let timeout: TimeInterval = 0.5 // 0.5 seconds timeout (ultra-fast)
        let fieldIds = ["telephone", "email", "field2021"]
        var foundByBroaderSelector = false

        while Date().timeIntervalSince(startTime) < timeout {
            // Try specific fields first
            for fieldId in fieldIds {
                let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
                let body = ["using": "id", "value": fieldId]

                guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
                    logger.error("Failed to create request for contact info page check (field: \(fieldId))")
                    continue
                }

                do {
                    let (_, response) = try await urlSession.data(for: request)
                    let httpResponse = response as? HTTPURLResponse

                    if httpResponse?.statusCode == 200 {
                        logger.info("Contact info page loaded successfully (field: \(fieldId))")
                        return true
                    }
                } catch {
                    logger.debug("Exception while checking field \(fieldId): \(error.localizedDescription)")
                }
            }

            // Broader detection: check for any <input> or the form itself
            do {
                // Check for form with id="mainForm"
                let formEndpoint = "\(baseURL)/session/\(sessionIdString)/element"
                let formBody = ["using": "id", "value": "mainForm"]
                if let formRequest = createRequest(url: formEndpoint, method: "POST", body: formBody) {
                    let (_, formResponse) = try await urlSession.data(for: formRequest)
                    let formHttpResponse = formResponse as? HTTPURLResponse
                    if formHttpResponse?.statusCode == 200 {
                        foundByBroaderSelector = true
                    }
                }
                // Check for any <input> field
                let inputEndpoint = "\(baseURL)/session/\(sessionIdString)/elements"
                let inputBody = ["using": "tag name", "value": "input"]
                if let inputRequest = createRequest(url: inputEndpoint, method: "POST", body: inputBody) {
                    let (inputData, inputResponse) = try await urlSession.data(for: inputRequest)
                    let inputHttpResponse = inputResponse as? HTTPURLResponse
                    if inputHttpResponse?.statusCode == 200 {
                        let inputDict = try JSONSerialization.jsonObject(with: inputData) as? [String: Any]
                        if let values = inputDict?["value"] as? [Any], !values.isEmpty {
                            foundByBroaderSelector = true
                        }
                    }
                }
            } catch {
                logger.debug("Exception while checking broader selectors: \(error.localizedDescription)")
            }

            // Wait before retry
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }

        // If broader selector found, return true (as fallback)
        if foundByBroaderSelector {
            logger.info("Contact info page detected via broader selectors")
            return true
        }

        logger.error("Contact info page failed to load within timeout")
        return false
    }

    /// Fills the phone number field on the contact information page
    /// - Parameter phoneNumber: The phone number to enter (without hyphens)
    /// - Returns: True if field was filled successfully
    func fillPhoneNumber(_ phoneNumber: String) async -> Bool {
        guard let sessionId else {
            logger.error("No active session for filling phone number")
            return false
        }
        let sessionIdString = String(describing: sessionId)

        // Comprehensive selectors for phone field
        let phoneSelectors = [
            ["using": "id", "value": "telephone"], // Primary selector
            ["using": "name", "value": "PhoneNumber"], // Fallback
            ["using": "css selector", "value": ".contact-field.reservation-text-field[type='tel']"], // Specific CSS
            ["using": "css selector", "value": "#telephone"], // ID selector
            ["using": "css selector", "value": "input[name='PhoneNumber']"], // Name selector
            ["using": "xpath", "value": "//input[@type='tel']"], // XPath fallback
        ]
        var elementId: String?
        var successfulSelector = "none"
        for (index, selector) in phoneSelectors.enumerated() {
            let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
            guard let request = createRequest(url: endpoint, method: "POST", body: selector) else {
                continue
            }
            do {
                let (data, response) = try await urlSession.data(for: request)
                let httpResponse = response as? HTTPURLResponse
                if httpResponse?.statusCode == 200 {
                    let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let value = responseDict?["value"] as? [String: Any] {
                        let foundElementId = value["element-6066-11e4-a52e-4f735466cecf"] as? String ??
                            value["ELEMENT"] as? String
                        if let foundElementId {
                            elementId = foundElementId
                            successfulSelector = "\(selector["using"] ?? "unknown"): \(selector["value"] ?? "unknown")"
                            logger.info("Phone field found with selector: \(successfulSelector)")
                            break
                        }
                    }
                }
            } catch {
                logger.debug("Phone selector \(index + 1) failed: \(error.localizedDescription)")
            }
        }
        guard let elementId else {
            logger.error("Failed to find phone number field with any selector")
            return false
        }
        // Scroll into view
        let scrollScript = "arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});"
        _ = await executeScriptWithElement(scrollScript, elementId: elementId, sessionId: sessionIdString)
        // Simulate mouse movement
        await simulateMouseMovement(to: elementId)
        if WebDriverService.instantFillEnabled {
            // Set value via JS instantly
            let jsEndpoint = "\(baseURL)/session/\(sessionIdString)/execute/sync"
            let script = """
            var el = document.getElementById('telephone');
            if (el) { el.value = '\(phoneNumber)'; }
            """
            let jsBody: [String: Any] = ["script": script, "args": []]
            if let jsRequest = createRequest(url: jsEndpoint, method: "POST", body: jsBody) {
                do {
                    _ = try await urlSession.data(for: jsRequest)
                    logger.info("Phone field filled instantly via JavaScript")
                    return true
                } catch {
                    logger.error("Failed to set phone field via JavaScript: \(error.localizedDescription)")
                    return false
                }
            }
            return false
        }
        // ... existing code ...
        // Wait 100ms after focusing
        try? await Task.sleep(nanoseconds: 100_000_000)
        // ... existing code ...
        // Add a small delay to simulate human behavior
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        // Use human-like typing (fast)
        await simulateTyping(elementId: elementId, text: phoneNumber)

        logger.info("Successfully filled phone field: \(phoneNumber, privacy: .private)")
        return true
    }

    /// Fills the email field on the contact information page
    /// - Parameter email: The email address to enter
    /// - Returns: True if field was filled successfully
    func fillEmail(_ email: String) async -> Bool {
        guard let sessionId else {
            logger.error("No active session for filling email")
            return false
        }

        let sessionIdString = String(describing: sessionId)

        // Comprehensive selectors for email field
        let emailSelectors = [
            ["using": "id", "value": "email"], // Primary selector
            ["using": "name", "value": "Email"], // Fallback
            ["using": "css selector", "value": ".contact-field.reservation-text-field[type='email']"], // Specific CSS
            ["using": "css selector", "value": "#email"], // ID selector
            ["using": "css selector", "value": "input[name='Email']"], // Name selector
            ["using": "xpath", "value": "//input[@type='email']"], // XPath fallback
        ]

        var elementId: String?
        var successfulSelector = "none"

        for (index, selector) in emailSelectors.enumerated() {
            let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
            guard let request = createRequest(url: endpoint, method: "POST", body: selector) else {
                appendDebugLog("Failed to create request for email selector \(index + 1): \(selector)")
                continue
            }

            do {
                let (data, response) = try await urlSession.data(for: request)
                let httpResponse = response as? HTTPURLResponse

                if httpResponse?.statusCode == 200 {
                    let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let value = responseDict?["value"] as? [String: Any] {
                        let foundElementId = value["element-6066-11e4-a52e-4f735466cecf"] as? String ??
                            value["ELEMENT"] as? String
                        if let foundElementId {
                            elementId = foundElementId
                            successfulSelector = "\(selector["using"] ?? "unknown"): \(selector["value"] ?? "unknown")"
                            appendDebugLog("Email field found with selector \(index + 1): \(successfulSelector)")
                            logger.info("Email field found with selector: \(successfulSelector)")
                            break
                        }
                    }
                } else {
                    appendDebugLog("Email selector \(index + 1) failed with status: \(httpResponse?.statusCode ?? 0)")
                }
            } catch {
                appendDebugLog("Email selector \(index + 1) failed with error: \(error.localizedDescription)")
            }
        }

        guard let elementId else {
            logger.error("Failed to find email field with any selector")
            appendDebugLog("Failed to find email field with any selector")
            // Log all input fields for debugging
            await logAllInputFields(sessionId: sessionIdString, fieldType: "email")
            return false
        }
        // Scroll into view
        let scrollScript = "arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});"
        _ = await executeScriptWithElement(scrollScript, elementId: elementId, sessionId: sessionIdString)
        // Simulate mouse movement
        await simulateMouseMovement(to: elementId)
        // Focus/click the field before clearing/typing
        let focusEndpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementId)/click"
        if let focusRequest = createRequest(url: focusEndpoint, method: "POST") {
            do {
                let (_, focusResponse) = try await urlSession.data(for: focusRequest)
                let focusHttpResponse = focusResponse as? HTTPURLResponse
                appendDebugLog("Clicked/focused email field (status: \(focusHttpResponse?.statusCode ?? 0))")
            } catch {
                appendDebugLog("Failed to click/focus email field: \(error.localizedDescription)")
            }
        }
        // Wait 60ms after focusing
        try? await Task.sleep(nanoseconds: 60_000_000)
        // Use human-like typing (fast)
        let blur = Bool.random() && Bool.random() // ~25% chance
        await simulateTyping(elementId: elementId, text: email, fastHumanLike: true, blurAfter: blur)

        logger.info("Successfully filled email (human-like typing): \(email, privacy: .private)")
        appendDebugLog("Successfully filled email with selector: \(successfulSelector)")
        return true
    }

    /// Fills the name field on the contact information page
    /// - Parameter name: The name to enter
    /// - Returns: True if field was filled successfully
    func fillName(_ name: String) async -> Bool {
        guard let sessionId else {
            logger.error("No active session for filling name")
            appendDebugLog("No active session for filling name")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        appendDebugLog("Attempting to fill name field with value: \(name)")

        // Comprehensive selectors for name field
        let nameSelectors = [
            ["using": "id", "value": "field2021"], // Primary selector
            ["using": "name", "value": "field2021"], // Fallback
            ["using": "css selector", "value": ".reservation-text-field[type='text']"], // Specific CSS
            ["using": "css selector", "value": ".mdc-text-field__input.reservation-text-field"], // Material Design
            ["using": "xpath", "value": "//input[starts-with(@id, 'field')]"], // XPath pattern
            ["using": "xpath", "value": "//input[@type='text' and @aria-required='true']"], // Required text field
        ]

        var elementId: String?
        var successfulSelector = "none"

        for (index, selector) in nameSelectors.enumerated() {
            let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
            guard let request = createRequest(url: endpoint, method: "POST", body: selector) else {
                appendDebugLog("Failed to create request for name selector \(index + 1): \(selector)")
                continue
            }

            do {
                let (data, response) = try await urlSession.data(for: request)
                let httpResponse = response as? HTTPURLResponse

                if httpResponse?.statusCode == 200 {
                    let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let value = responseDict?["value"] as? [String: Any] {
                        let foundElementId = value["element-6066-11e4-a52e-4f735466cecf"] as? String ??
                            value["ELEMENT"] as? String
                        if let foundElementId {
                            elementId = foundElementId
                            successfulSelector = "\(selector["using"] ?? "unknown"): \(selector["value"] ?? "unknown")"
                            appendDebugLog("Name field found with selector \(index + 1): \(successfulSelector)")
                            logger.info("Name field found with selector: \(successfulSelector)")
                            break
                        }
                    }
                } else {
                    appendDebugLog("Name selector \(index + 1) failed with status: \(httpResponse?.statusCode ?? 0)")
                }
            } catch {
                appendDebugLog("Name selector \(index + 1) failed with error: \(error.localizedDescription)")
            }
        }

        guard let elementId else {
            logger.error("Failed to find name field with any selector")
            appendDebugLog("Failed to find name field with any selector")
            // Log all input fields for debugging
            await logAllInputFields(sessionId: sessionIdString, fieldType: "name")
            return false
        }
        // Scroll into view
        let scrollScript = "arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});"
        _ = await executeScriptWithElement(scrollScript, elementId: elementId, sessionId: sessionIdString)
        // Simulate mouse movement
        await simulateMouseMovement(to: elementId)
        // Focus/click the field before clearing/typing
        let focusEndpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementId)/click"
        if let focusRequest = createRequest(url: focusEndpoint, method: "POST") {
            do {
                let (_, focusResponse) = try await urlSession.data(for: focusRequest)
                let focusHttpResponse = focusResponse as? HTTPURLResponse
                appendDebugLog("Clicked/focused name field (status: \(focusHttpResponse?.statusCode ?? 0))")
            } catch {
                appendDebugLog("Failed to click/focus name field: \(error.localizedDescription)")
            }
        }
        // Wait 60ms after focusing
        try? await Task.sleep(nanoseconds: 60_000_000)
        // Use human-like typing (fast)
        let blur = Bool.random() && Bool.random() // ~25% chance
        await simulateTyping(elementId: elementId, text: name, fastHumanLike: true, blurAfter: blur)

        logger.info("Successfully filled name (human-like typing): \(name, privacy: .private)")
        appendDebugLog("Successfully filled name with selector: \(successfulSelector)")
        return true
    }

    /// Clicks the confirm button on the contact information page
    /// - Returns: True if confirm button was clicked successfully
    func clickContactInfoConfirmButton() async -> Bool {
        guard let sessionId else { return false }
        let sessionIdString = String(describing: sessionId)

        // Use the most reliable selectors for the confirm button
        let selectors = [
            ["using": "id", "value": "submit-btn"],
            ["using": "css selector", "value": "button[type='submit']"],
            ["using": "css selector", "value": ".submit-button"],
            ["using": "class name", "value": "mdc-button__ripple"], // Fallback: click the ripple class
        ]

        var elementId: String?
        for selector in selectors {
            let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
            guard let request = createRequest(url: endpoint, method: "POST", body: selector) else { continue }
            do {
                let (data, response) = try await urlSession.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if
                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let value = json["value"] as? [String: Any],
                        let eid = value["element-6066-11e4-a52e-4f735466cecf"] as? String
                    {
                        elementId = eid
                        break
                    }
                }
            } catch { continue }
        }

        if let elementId {
            let clickEndpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementId)/click"
            if let clickRequest = createRequest(url: clickEndpoint, method: "POST") {
                do {
                    let (_, clickResponse) = try await urlSession.data(for: clickRequest)
                    if let httpResponse = clickResponse as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        logger.info("Successfully clicked contact info confirm button")
                        return true
                    }
                } catch { }
            }
        }

        // Fallback: Use JavaScript to click the submit button
        return await performJavaScriptContactInfoSubmit(sessionId: sessionIdString)
    }

    private func performJavaScriptContactInfoSubmit(sessionId: String) async -> Bool {
        let endpoint = "\(baseURL)/session/\(sessionId)/execute/sync"
        let script = """
            const submitBtn = document.getElementById('submit-btn');
            if (submitBtn) {
                submitBtn.click();
                return true;
            }
            return false;
        """
        let body: [String: Any] = ["script": script, "args": []]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create JavaScript contact info submit request")
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode == 200 {
                let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let result = responseDict?["value"] as? Bool, result {
                    logger.info("Successfully clicked contact info confirm button with JavaScript")
                    return true
                }
            }

            // Log the error response for debugging
            if let responseData = String(data: data, encoding: .utf8) {
                logger.error("JavaScript contact info submit failed with response: \(responseData)")
            }
            return false
        } catch {
            logger.error("JavaScript contact info submit failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Waits for the email verification code page to load
    /// - Returns: True if verification page is ready, false if timeout
    func waitForVerificationPage() async -> Bool {
        guard let sessionId else {
            logger.error("No active session for verification page check")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        let maxAttempts = 30 // 30 seconds max wait
        var attempts = 0

        while attempts < maxAttempts {
            // Check if verification code field is present
            let codeFieldCheckScript = "return document.getElementById('code') !== null;"
            if let hasCodeField = await executeScript(codeFieldCheckScript, sessionId: sessionIdString) as? Bool {
                if hasCodeField {
                    logger.info("Verification page loaded successfully")
                    return true
                }
            }

            attempts += 1
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }

        logger.error("Verification page load timeout after \(maxAttempts) seconds")
        return false
    }

    /// Extracts verification code from email and fills the verification field
    /// - Returns: True if verification code was found and filled successfully
    func handleEmailVerification() async -> Bool {
        logger.info("=== STARTING EMAIL VERIFICATION PROCESS ===")

        // Wait for verification page to load with timeout
        logger.info("Step 1: Waiting for verification page to load...")
        let pageLoaded = await waitForVerificationPage()
        if !pageLoaded {
            logger.error("❌ FAILED: Verification page did not load")
            await cleanupAndCloseBrowser()
            return false
        }
        logger.info("✅ SUCCESS: Verification page loaded")

        // Poll for verification email every 5 seconds for up to 1 minute (12 attempts)
        logger.info("Step 2: Polling for verification email every 5 seconds (max 1 minute)...")

        for attempt in 1 ... 12 {
            logger.info("📧 Attempt \(attempt)/12: Checking for verification email...")

            // Set up a timeout for each email check (10 seconds max per attempt)
            let emailCheckTask = Task {
                logger.info("🔍 Starting verification code extraction from email...")
                logger.info("📧 Calling EmailService.fetchVerificationCodesForToday()...")

                let codes = await EmailService.shared.fetchVerificationCodesForToday()
                logger.info("📧 EmailService returned \(codes.count) verification codes")

                if !codes.isEmpty {
                    logger.info("✅ SUCCESS: Found verification codes: \(codes)")

                    // Try to fill the verification code field
                    let codeFilled = await fillVerificationCode(codes.first!)
                    if codeFilled {
                        logger.info("✅ SUCCESS: Verification code filled successfully")

                        // Try to click the confirm button
                        let confirmClicked = await clickVerificationConfirmButton()
                        if confirmClicked {
                            logger.info("✅ SUCCESS: Verification confirm button clicked")
                            return true
                        } else {
                            logger.error("❌ FAILED: Could not click verification confirm button")
                            return false
                        }
                    } else {
                        logger.error("❌ FAILED: Could not fill verification code field")
                        return false
                    }
                } else {
                    logger.info("📧 No verification codes found in attempt \(attempt)/12")
                    return false
                }
            }

            // Wait for email check with 10-second timeout
            let result = await withTimeout(seconds: 10) {
                await emailCheckTask.value
            }

            if result == true {
                logger.info("✅ SUCCESS: Email verification completed successfully")
                return true
            }

            // If this wasn't the last attempt, wait 5 seconds before next attempt
            if attempt < 12 {
                logger.info("⏳ Waiting 5 seconds before next attempt...")
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            }
        }

        // If we get here, no verification code was found after 1 minute
        logger.error("❌ FAILED: No verification code found after 1 minute of polling")
        await cleanupAndCloseBrowser()
        return false
    }

    /// Helper function to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> T? {
        return await withTaskGroup(of: T?.self) { group in
            group.addTask {
                return await operation()
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }

            for await result in group {
                if result != nil {
                    return result
                }
            }
            return nil
        }
    }

    /// Cleanup and close browser when verification fails or times out
    private func cleanupAndCloseBrowser() async {
        logger.info("🧹 Cleaning up and closing browser...")

        // Try to close the browser gracefully
        if sessionId != nil {
            await stopSession()
            logger.info("✅ Browser closed successfully")
        }

        // Reset session
        sessionId = nil
        logger.info("🔄 WebDriver session reset")
    }

    /// Fills the verification code field
    /// - Parameter code: The verification code to enter
    /// - Returns: True if field was filled successfully
    private func fillVerificationCode(_ code: String) async -> Bool {
        guard let sessionId else {
            logger.error("No active session for filling verification code")
            return false
        }

        let sessionIdString = String(describing: sessionId)
        logger.info("Filling verification code field")

        // Wait a moment for the page to fully render
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Try multiple selectors to find the verification code field
        let selectors = [
            ["using": "id", "value": "code"],
            ["using": "css selector", "value": "input[name='code']"],
            ["using": "css selector", "value": "input[type='number'][maxlength='4']"],
            ["using": "css selector", "value": "input.mdc-text-field__input"],
            ["using": "xpath", "value": "//input[@id='code']"],
            ["using": "xpath", "value": "//input[@name='code']"],
            ["using": "xpath", "value": "//input[@type='number' and @maxlength='4']"],
        ]

        var elementId: String?

        for selector in selectors {
            let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
            guard let request = createRequest(url: endpoint, method: "POST", body: selector) else {
                logger.error("Failed to create request for verification code field with selector: \(selector)")
                continue
            }

            do {
                let (data, response) = try await urlSession.data(for: request)
                let httpResponse = response as? HTTPURLResponse

                if httpResponse?.statusCode == 200 {
                    let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let value = responseDict?["value"] as? [String: Any] {
                        let eid = value["element-6066-11e4-a52e-4f735466cecf"] as? String ?? value["ELEMENT"] as? String
                        if let eid {
                            elementId = eid
                            logger.info("✅ Found verification code field using selector: \(selector)")
                            break
                        }
                    }
                } else {
                    // Selector failed, continue to next one
                }
            } catch {
                // Selector failed with error, continue to next one
            }
        }

        guard let elementId else {
            logger.error("Failed to find verification code field with any selector")
            return false
        }

        // Now that we have the element ID, proceed with filling the field
        // Scroll into view
        let scrollScript = "arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});"
        _ = await executeScriptWithElement(scrollScript, elementId: elementId, sessionId: sessionIdString)

        // Simulate mouse movement
        await simulateMouseMovement(to: elementId)

        // Focus/click the field
        let focusEndpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementId)/click"
        if let focusRequest = createRequest(url: focusEndpoint, method: "POST") {
            do {
                let (_, focusResponse) = try await urlSession.data(for: focusRequest)
                let focusHttpResponse = focusResponse as? HTTPURLResponse
                logger
                    .info("Clicked verification code field (status: \(focusHttpResponse?.statusCode ?? 0))")
            } catch {
                logger.error("Failed to click verification code field: \(error.localizedDescription)")
            }
        }

        // Wait 60ms after focusing
        try? await Task.sleep(nanoseconds: 60_000_000)

        // Use human-like typing (fast)
        let blur = Bool.random() && Bool.random() // ~25% chance
        await simulateTyping(elementId: elementId, text: code, fastHumanLike: true, blurAfter: blur)

        logger.info("Successfully filled verification code field")
        return true
    }

    /// Clicks the confirm button on the verification page
    /// - Returns: True if confirm button was clicked successfully
    private func clickVerificationConfirmButton() async -> Bool {
        guard let sessionId else { return false }
        let sessionIdString = String(describing: sessionId)

        // Use the most reliable selectors for the confirm button
        let selectors = [
            ["using": "css selector", "value": "button[onclick*='SubmitContactInfoValidationCode']"],
            ["using": "css selector", "value": "button.mdc-button--unelevated"],
            ["using": "xpath", "value": "//button[contains(text(), 'Confirm')]"],
        ]

        var elementId: String?
        for selector in selectors {
            let endpoint = "\(baseURL)/session/\(sessionIdString)/element"
            guard let request = createRequest(url: endpoint, method: "POST", body: selector) else { continue }
            do {
                let (data, response) = try await urlSession.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if
                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let value = json["value"] as? [String: Any],
                        let eid = value["element-6066-11e4-a52e-4f735466cecf"] as? String
                    {
                        elementId = eid
                        break
                    }
                }
            } catch { continue }
        }

        if let elementId {
            let clickEndpoint = "\(baseURL)/session/\(sessionIdString)/element/\(elementId)/click"
            if let clickRequest = createRequest(url: clickEndpoint, method: "POST") {
                do {
                    let (_, clickResponse) = try await urlSession.data(for: clickRequest)
                    if let httpResponse = clickResponse as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        logger.info("Successfully clicked verification confirm button")
                        return true
                    }
                } catch { }
            }
        }

        // Fallback: Use JavaScript to click the submit button
        return await performJavaScriptVerificationSubmit(sessionId: sessionIdString)
    }

    private func performJavaScriptVerificationSubmit(sessionId: String) async -> Bool {
        let endpoint = "\(baseURL)/session/\(sessionId)/execute/sync"
        let script = """
            submitCommand('SubmitContactInfoValidationCode');
            return true;
        """
        let body: [String: Any] = ["script": script, "args": []]

        guard let request = createRequest(url: endpoint, method: "POST", body: body) else {
            logger.error("Failed to create JavaScript verification submit request")
            return false
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode == 200 {
                let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let result = responseDict?["value"] as? Bool, result {
                    logger.info("Successfully clicked verification confirm button with JavaScript")
                    return true
                }
            }

            // Log the error response for debugging
            if let responseData = String(data: data, encoding: .utf8) {
                logger.error("JavaScript verification submit failed with response: \(responseData)")
            }
            return false
        } catch {
            logger.error("JavaScript verification submit failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Public cleanup method for external use
    func cleanup() async {
        await cleanupAndCloseBrowser()
    }

    /// Checks if email verification is required on the current page
    /// - Returns: True if email verification is required, false otherwise
    func isEmailVerificationRequired() async -> Bool {
        logger.info("🔍 Checking if email verification is required...")

        do {
            // Look for verification code input field
            _ =
                try await findElement(
                    by: "input[type='text'][placeholder*='verification'], input[type='text'][placeholder*='code'], input[name*='verification'], input[name*='code']",
                )

            // If we get here, the element was found
            logger.info("✅ Email verification field found - verification required")
            return true

        } catch {
            // If we can't find the element, check for verification-related text on the page
            do {
                let pageText = try await getPageSource()
                let verificationKeywords = ["verification", "verify", "code", "enter code", "verification code"]

                for keyword in verificationKeywords {
                    if pageText.lowercased().contains(keyword.lowercased()) {
                        logger.info("✅ Email verification keyword found: \(keyword) - verification required")
                        return true
                    }
                }

                logger.info("❌ No email verification required")
                return false

            } catch {
                logger.warning("⚠️ Error checking for email verification: \(error)")
                // If we can't determine, assume verification is not required
                return false
            }
        }
    }

    /// Checks if the reservation was successful
    /// - Returns: True if reservation was successful, false otherwise
    func checkReservationSuccess() async -> Bool {
        logger.info("🔍 Checking if reservation was successful...")

        do {
            // Get the current page source to analyze
            let pageText = try await getPageSource()

            // Look for success indicators
            let successKeywords = [
                "success", "successful", "confirmed", "confirmation",
                "reservation confirmed", "booking confirmed", "thank you",
                "reservation successful", "booking successful",
            ]

            for keyword in successKeywords {
                if pageText.lowercased().contains(keyword.lowercased()) {
                    logger.info("✅ Success keyword found: \(keyword)")
                    return true
                }
            }

            // Look for error indicators
            let errorKeywords = [
                "error", "failed", "failure", "unavailable", "not available",
                "booking failed", "reservation failed", "try again",
            ]

            for keyword in errorKeywords {
                if pageText.lowercased().contains(keyword.lowercased()) {
                    logger.warning("⚠️ Error keyword found: \(keyword)")
                    return false
                }
            }

            // If we can't determine, assume success (optimistic approach)
            logger.info("❓ Could not determine success status, assuming success")
            return true

        } catch {
            logger.warning("⚠️ Error checking reservation success: \(error)")
            // If we can't determine, assume success
            return true
        }
    }
}
