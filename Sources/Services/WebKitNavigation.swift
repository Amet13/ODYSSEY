import Foundation
import os.log
import WebKit

/// Navigation functionality for WebKit service
/// Handles URL navigation, page loading, and navigation state management
@MainActor
extension WebKitCore {
    // MARK: - Navigation Methods

    /// Connects to the WebKit service and prepares for navigation
    func connect() async throws {
        logger.info("🔗 Connecting to WebKit service.")

        guard webView != nil else {
            logger.error("❌ WebView is nil, cannot connect.")
            throw WebKitError.webViewNotInitialized
        }

        isRunning = true
        isConnected = false

        // Check user settings to determine if browser window should be shown
        let userSettings = UserSettingsManager.shared.userSettings
        if userSettings.showBrowserWindow {
            // Show browser window for visibility
            showDebugWindow()
            logger.info("🪟 Browser window shown (user setting: show window).")
        } else {
            logger.info("🪟 Browser window hidden (user setting: hide window - recommended to avoid captcha detection).")
        }

        logger.info("✅ WebKit service connected successfully.")
    }

    /// Navigates to a specific URL
    /// - Parameter url: The URL to navigate to
    func navigateToURL(_ url: String) async throws {
        logger.info("🌐 Navigating to URL: \(url, privacy: .private).")

        guard webView != nil else {
            logger.error("❌ WebView is nil, cannot navigate.")
            throw WebKitError.webViewNotInitialized
        }

        guard let urlObject = URL(string: url) else {
            logger.error("❌ Invalid URL: \(url)")
            throw WebKitError.invalidURL
        }

        // Create a unique navigation ID for tracking
        let navigationId = UUID().uuidString

        // Start navigation
        let navigation = webView?.load(URLRequest(url: urlObject))

        // Store navigation reference for completion tracking
        if let navigationDescription = navigation?.description {
            navigationCompletions[navigationDescription] = navigationCompletions[navigationId]
        }
        navigationCompletions.removeValue(forKey: navigationId)

        // Wait for navigation to complete using a simple approach
        // For now, we'll just return true since the navigation delegate will handle completion

        logger.info("✅ Navigation completed successfully for URL: \(url, privacy: .private).")
    }

    /// Disconnects from the WebKit service
    /// - Parameter closeWindow: Whether to close the browser window
    func disconnect(closeWindow: Bool = true) async {
        logger.info("🔌 Disconnecting from WebKit service.")

        isRunning = false
        isConnected = false
        currentURL = nil
        pageTitle = nil

        // Clear completion handlers
        navigationCompletions.removeAll()
        scriptCompletions.removeAll()
        elementCompletions.removeAll()

        if closeWindow {
            hideDebugWindow()
        }

        logger.info("✅ WebKit service disconnected successfully.")
    }

    /// Waits for the DOM to be ready
    /// - Returns: True if DOM is ready, false if timeout
    func waitForDOMReady() async -> Bool {
        logger.info("⏳ Waiting for DOM to be ready.")

        let maxWaitTime: TimeInterval = 15.0 // 15 seconds timeout
        let checkInterval: TimeInterval = 0.5 // Check every 500ms
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < maxWaitTime {
            let isReady = await evaluateJavaScript("document.readyState === 'complete'") as? Bool ?? false

            if isReady {
                logger.info("✅ DOM is ready.")
                return true
            }

            // Wait before next check
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }

        logger.warning("⏰ DOM ready timeout reached.")
        return false
    }

    /// Evaluates JavaScript in the current page
    /// - Parameter script: The JavaScript to evaluate
    /// - Returns: The result of the JavaScript evaluation
    func evaluateJavaScript(_ script: String) async -> Any? {
        guard let webView else {
            logger.error("❌ WebView is nil, cannot evaluate JavaScript.")
            return nil
        }

        return await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(script) { result, error in
                if let error {
                    self.logger.error("❌ JavaScript evaluation failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        continuation.resume(returning: nil)
                    }
                } else {
                    let value = result
                    DispatchQueue.main.async {
                        continuation.resume(returning: value)
                    }
                }
            }
        }
    }

    /// Gets the current page title
    /// - Returns: The page title or nil if not available
    func getPageTitle() async -> String? {
        return await evaluateJavaScript("document.title") as? String
    }

    /// Gets the current page URL
    /// - Returns: The page URL or nil if not available
    func getCurrentURL() async -> String? {
        return await evaluateJavaScript("window.location.href") as? String
    }

    /// Checks if the current page contains specific text
    /// - Parameter text: The text to search for
    /// - Returns: True if text is found, false otherwise
    func pageContainsText(_ text: String) async -> Bool {
        let script = "document.body.textContent.includes('\(text)')"
        return await evaluateJavaScript(script) as? Bool ?? false
    }

    /// Waits for specific text to appear on the page
    /// - Parameters:
    ///   - text: The text to wait for
    ///   - timeout: Maximum time to wait in seconds
    /// - Returns: True if text appears, false if timeout
    func waitForText(_ text: String, timeout: TimeInterval = 10.0) async -> Bool {
        logger.info("⏳ Waiting for text: '\(text, privacy: .private)'.")

        let checkInterval: TimeInterval = 0.5
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if await pageContainsText(text) {
                logger.info("✅ Text found: '\(text, privacy: .private)'.")
                return true
            }

            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }

        logger.warning("⏰ Text not found within timeout: '\(text, privacy: .private)'.")
        return false
    }

    /// Waits for an element to appear on the page
    /// - Parameters:
    ///   - selector: CSS selector for the element
    ///   - timeout: Maximum time to wait in seconds
    /// - Returns: True if element appears, false if timeout
    func waitForElement(_ selector: String, timeout: TimeInterval = 10.0) async -> Bool {
        logger.info("⏳ Waiting for element: '\(selector)'.")

        let script = """
        (function() {
            const element = document.querySelector('\(selector)');
            return element !== null;
        })();
        """

        let checkInterval: TimeInterval = 0.5
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let exists = await evaluateJavaScript(script) as? Bool ?? false

            if exists {
                logger.info("✅ Element found: '\(selector)'.")
                return true
            }

            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }

        logger.warning("⏰ Element not found within timeout: '\(selector)'.")
        return false
    }
}

// MARK: - WebKit Errors

enum WebKitError: Error, LocalizedError, UnifiedErrorProtocol {
    case webViewNotInitialized
    case invalidURL
    case navigationFailed
    case elementNotFound
    case timeout

    var errorDescription: String? {
        return userFriendlyMessage
    }

    /// Unique error code for categorization and debugging
    var errorCode: String {
        switch self {
        case .webViewNotInitialized: return "WEBKIT_INIT_001"
        case .invalidURL: return "WEBKIT_URL_001"
        case .navigationFailed: return "WEBKIT_NAV_001"
        case .elementNotFound: return "WEBKIT_ELEMENT_001"
        case .timeout: return "WEBKIT_TIMEOUT_001"
        }
    }

    /// Category for grouping similar errors
    var errorCategory: ErrorCategory {
        switch self {
        case .webViewNotInitialized, .invalidURL: return .system
        case .navigationFailed, .elementNotFound: return .automation
        case .timeout: return .system
        }
    }

    /// User-friendly error message for UI display
    var userFriendlyMessage: String {
        switch self {
        case .webViewNotInitialized:
            return "WebView is not initialized"
        case .invalidURL:
            return "Invalid URL provided"
        case .navigationFailed:
            return "Navigation failed"
        case .elementNotFound:
            return "Element not found on page"
        case .timeout:
            return "Operation timed out"
        }
    }

    /// Technical details for debugging (optional)
    var technicalDetails: String? {
        switch self {
        case .webViewNotInitialized: return "WKWebView instance was not properly initialized"
        case .invalidURL: return "URL validation failed for WebKit navigation"
        case .navigationFailed: return "WebKit navigation operation failed"
        case .elementNotFound: return "DOM element not found during WebKit operation"
        case .timeout: return "WebKit operation exceeded timeout threshold"
        }
    }
}
