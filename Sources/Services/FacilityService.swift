import Foundation
import os.log
import WebKit

@MainActor
public final class FacilityService: NSObject, ObservableObject, WKScriptMessageHandler {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "FacilityService")

    // Published properties for UI updates
    @Published public var availableSports: [String] = []
    @Published public var isLoading: Bool = false
    @Published public var error: String?

    // WebView and completion handler
    private var webView: WKWebView?
    private var completionHandler: (([String]) -> Void)?

    // MARK: - Initialization

    override public init() {
        super.init()
        setupWebView()
    }

    // MARK: - Public Methods

    /// Loads available sports from a facility URL
    /// - Parameters:
    ///   - url: The facility URL to load
    ///   - completion: Completion handler with array of available sports
    public func loadAvailableSports(from url: URL, completion: @escaping ([String]) -> Void) {
        guard let webView else {
            logger.error("❌ WebView not initialized.")
            completion([])
            return
        }

        self.completionHandler = completion
        isLoading = true
        availableSports = []
        error = nil

        logger.info("🌐 Loading facility page: \(url.absoluteString).")

        let request = URLRequest(url: url)
        webView.load(request)
    }

    /// Test method to debug sports detection
    public func testSportsDetection() {
        logger.info("🧪 Testing sports detection functionality...")

        // Test with a simple URL
        guard let testURL = URL(string: "https://www.google.com") else {
            logger.error("❌ Invalid test URL.")
            return
        }

        loadAvailableSports(from: testURL) { sports in
            self.logger.info("🧪 Test completed. Found \(sports.count) sports: \(sports).")
        }
    }

    // MARK: - Private Methods

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "odysseyHandler")

        // Add the centralized JavaScript library
        let automationScript = JavaScriptLibrary.getAutomationLibrary()
        let script = WKUserScript(source: automationScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
        webView?.uiDelegate = self

        logger.info("🔧 WebView setup completed with centralized JavaScript library.")
    }

    private func executeSportsDetectionScript() {
        let sportsDetectionScript = JavaScriptLibrary.getSportsDetectionLibrary()

        logger.info("🔍 Executing sports detection script...")

        webView?.evaluateJavaScript(sportsDetectionScript) { [weak self] result, error in
            if let error {
                self?.logger.error("❌ Sports detection script error: \(error.localizedDescription).")
                self?.isLoading = false
                self?.completionHandler?([])
            } else if let sportsArray = result as? [String] {
                self?.logger.info("✅ Extracted \(sportsArray.count) sports from facility page: \(sportsArray).")
                self?.availableSports = sportsArray
                self?.isLoading = false
                self?.completionHandler?(sportsArray)
            } else {
                self?.logger.warning("⚠️ Invalid sports data received. Result type: \(type(of: result)).")
                self?.logger.warning("⚠️ Result value: \(String(describing: result)).")
                self?.isLoading = false
                self?.completionHandler?([])
            }
        }
    }

    private func executeFallbackSportsDetection() {
        let script = "window.odyssey.detectSportsFallback();"

        webView?.evaluateJavaScript(script) { [weak self] result, error in
            if let error {
                self?.logger.error("❌ Fallback sports detection script error: \(error.localizedDescription).")
                self?.isLoading = false
                self?.completionHandler?([])
            } else if let sportsArray = result as? [String] {
                self?.logger.info("✅ Fallback extracted \(sportsArray.count) sports: \(sportsArray).")
                self?.availableSports = sportsArray
                self?.isLoading = false
                self?.completionHandler?(sportsArray)
            } else {
                self?.logger.warning("⚠️ Fallback: Invalid sports data received.")
                self?.isLoading = false
                self?.completionHandler?([])
            }
        }
    }

    // MARK: - WebKit Message Handling

    /// Handles messages from WebKit
    @objc public func userContentController(
        _: WKUserContentController,
        didReceive message: WKScriptMessage,
        ) {
        logger.info("📨 Received WebKit message: \(message.name).")
    }
}

// MARK: - WKNavigationDelegate

extension FacilityService: WKNavigationDelegate {
    public func webView(_: WKWebView, didFinish _: WKNavigation!) {
        logger.info("✅ Facility page loaded successfully.")

        // Wait a moment for the page to fully render
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.logger.info("🔍 Starting sports detection after page render...")
            self?.executeSportsDetectionScript()
        }
    }

    public func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        logger.error("❌ Failed to load facility page: \(error.localizedDescription).")
        self.error = error.localizedDescription
        self.isLoading = false
        self.completionHandler?([])
    }

    public func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        logger.error("❌ Failed to load facility page (provisional): \(error.localizedDescription).")
        self.error = error.localizedDescription
        self.isLoading = false
        self.completionHandler?([])
    }
}

// MARK: - WKUIDelegate

extension FacilityService: WKUIDelegate {
    public func webView(
        _ webView: WKWebView,
        createWebViewWith _: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures _: WKWindowFeatures,
        ) -> WKWebView? {
        // Handle new window requests by loading in the same WebView
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
