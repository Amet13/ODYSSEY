import AppKit
import Combine
import Foundation
import os.log
import WebKit

/// Core WebKit service functionality.
/// Handles initialization, setup, and basic navigation operations.
@MainActor
@preconcurrency
class WebKitCore: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isConnected = false
    @Published var isRunning: Bool = false
    @Published var currentURL: String?
    @Published var pageTitle: String?

    // MARK: - Core Properties

    let logger = Logger(subsystem: "com.odyssey.app", category: "WebKitCore")
    var webView: WKWebView?
    private var navigationDelegate: WebKitNavigationDelegate?
    private var scriptMessageHandler: WebKitScriptMessageHandler?
    private var debugWindowManager: WebKitDebugWindowManager?
    private var instanceId: String = "default"

    // Configuration
    var currentConfig: ReservationConfig? {
        didSet {
            if let config = currentConfig {
                Task { @MainActor in
                    debugWindowManager?.updateWindowTitle(with: config)
                }
            }
        }
    }

    // User agent and language settings
    var userAgent: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    private var language: String = "en-US,en"

    // Completion handlers for async operations
    var navigationCompletions: [String: @Sendable (Bool) -> Void] = [:]
    var scriptCompletions: [String: @Sendable (Any?) -> Void] = [:]
    var elementCompletions: [String: @Sendable (String?) -> Void] = [:]

    // Callback for window closure
    var onWindowClosed: ((ReservationRunType) -> Void)?

    // MARK: - Initialization

    override private init() {
        super.init()
        setupWebView()
    }

    /// Create a new WebKit service instance for parallel operations
    convenience init(forParallelOperation _: Bool) {
        self.init()
    }

    /// Create a new WebKit service instance with unique anti-detection profile
    convenience init(forParallelOperation _: Bool, instanceId: String) {
        self.init()
        self.instanceId = instanceId
    }

    deinit {
        logger.info("🧹 WebKitCore deinit - cleaning up resources.")
        navigationCompletions.removeAll()
        scriptCompletions.removeAll()
        elementCompletions.removeAll()
        webView = nil
        logger.info("✅ WebKitCore cleanup completed.")
    }

    // MARK: - Setup Methods

    private func setupWebView() {
        logger.info("🔧 Setting up new WebView for instance: \(self.instanceId).")
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        // Add script message handler
        scriptMessageHandler = WebKitScriptMessageHandler()
        if let scriptMessageHandler {
            configuration.userContentController.add(scriptMessageHandler, name: "odysseyHandler")
        }

        // Enhanced anti-detection measures
        configuration.applicationNameForUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"

        // Disable automation detection
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Enable JavaScript using the modern approach
        if #available(macOS 11.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            configuration.preferences.javaScriptEnabled = true
        }

        // Set realistic viewport and screen properties
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // Create unique website data store for each instance to avoid tab detection
        let websiteDataStore = WKWebsiteDataStore.nonPersistent()
        configuration.websiteDataStore = websiteDataStore

        // Clear all data for this instance
        let currentInstanceId = self.instanceId
        websiteDataStore.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0),
            ) { [self] in
            logger.info("🧹 Cleared website data for instance: \(currentInstanceId).")
        }

        // Create web view
        webView = WKWebView(frame: .zero, configuration: configuration)
        logger.info("✅ WebView created successfully for instance: \(self.instanceId).")

        // Generate unique user agent for this instance
        let userAgents = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        ]
        let selectedUserAgent = userAgents.randomElement() ?? userAgents[0]
        webView?.customUserAgent = selectedUserAgent

        // Set navigation delegate
        navigationDelegate = WebKitNavigationDelegate()
        webView?.navigationDelegate = navigationDelegate

        // Set realistic window size with unique positioning for each instance
        let selectedSize = AppConstants.windowSizes.randomElement() ?? AppConstants.windowSizes[0]

        // Generate unique window position based on instance ID
        let hash = abs(instanceId.hashValue)
        let xOffset = (hash % 200) + 50
        let yOffset = ((hash / 200) % 200) + 50
        webView?.frame = CGRect(x: xOffset, y: yOffset, width: selectedSize.width, height: selectedSize.height)

        if let webView {
            WebKitScriptManager.shared.injectAutomationScripts(into: webView)
            WebKitScriptManager.shared.injectAntiDetectionScripts(into: webView, instanceId: instanceId)
        }

        logger.info("✅ WebView setup completed successfully for instance: \(self.instanceId).")
    }

    // MARK: - Public Methods

    /// Shows the browser window
    func showDebugWindow() {
        // Check user settings to determine if browser window should be shown
        let userSettings = UserSettingsManager.shared.userSettings
        if userSettings.showBrowserWindow {
            debugWindowManager?.showDebugWindow(webView: webView, config: currentConfig)
            logger.info("🪟 Browser window shown (user setting: show window)")
        } else {
            logger.info("🪟 Browser window hidden (user setting: hide window - recommended to avoid captcha detection)")
        }
    }

    /// Hides the browser window
    func hideDebugWindow() {
        debugWindowManager?.hideDebugWindow()
    }

    /// Forces a reset of the WebKit service
    func forceReset() {
        logger.info("🔄 Force resetting WebKit service.")
        isConnected = false
        isRunning = false
        currentURL = nil
        pageTitle = nil
        navigationCompletions.removeAll()
        scriptCompletions.removeAll()
        elementCompletions.removeAll()
        webView = nil
        debugWindowManager = nil
        setupWebView()
        logger.info("✅ WebKit service reset completed.")
    }

    /// Checks if the service is in a valid state
    func isServiceValid() -> Bool {
        return webView != nil && navigationDelegate != nil
    }

    /// Resets the service to a clean state
    func reset() {
        logger.info("🔄 Resetting WebKit service.")
        forceReset()
    }
}

// MARK: - NSWindowDelegate

extension WebKitCore: NSWindowDelegate {
    func windowWillClose(_: Notification) {
        logger.info("🪟 Browser window closing - notifying callback.")
        onWindowClosed?(ReservationRunType.godmode)
    }
}
