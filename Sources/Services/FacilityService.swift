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

    /// Fetches available sports from the facility page
    public func fetchSports(from url: URL, completion: @escaping ([String]) -> Void) {
        logger.info("🏀 Starting sports fetch process...")

        guard let webView else {
            logger.error("❌ WebView not initialized for sports fetch")
            completion([])
            return
        }

        isLoading = true
        completionHandler = completion

        logger.info("🔍 Loading facility page for sports detection...")
        logger.info("🌐 Loading URL: \(url)")

        let request = URLRequest(url: url)
        webView.load(request)
    }

    /// Fetches available sports from the default Ottawa facility page (for backward compatibility)
    public func fetchSports(completion: @escaping ([String]) -> Void) {
        let defaultURL = URL(string: "https://ottawa.ca/en/recreation-and-parks/recreation-programs-and-activities")!
        fetchSports(from: defaultURL, completion: completion)
    }

    /// Test method for debugging sports detection
    public func testSportsDetection() {
        logger.info("🧪 Testing sports detection functionality...")

        fetchSports { sports in
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
        logger.info("🔍 Starting sports detection script execution...")

        guard let webView else {
            logger.error("❌ WebView is nil in executeSportsDetectionScript")
            return
        }

        // Simple sports detection script with error handling
        let sportsScript = """
        (function() {
            try {
                // Initialize window.odyssey if it doesn't exist
                if (typeof window.odyssey === 'undefined') {
                    window.odyssey = {};
                }

                // Define the detectSports function directly
                window.odyssey.detectSports = function() {
                    try {
                        const sports = [];

                        // Look for elements with the specific 'button no-img' class
                        const buttonNoImgElements = document.querySelectorAll('.button.no-img');

                        buttonNoImgElements.forEach((element) => {
                            const text = element.textContent || element.innerText || '';
                            const trimmedText = text.trim();

                            if (trimmedText.length > 0) {
                                // Check for duplicates by sport name (case-insensitive)
                                const isDuplicate = sports.some(existing =>
                                    existing.toLowerCase() === trimmedText.toLowerCase()
                                );

                                if (!isDuplicate) {
                                    sports.push(trimmedText);
                                }
                            }
                        });

                        console.log('[ODYSSEY] Found sports:', sports);
                        return sports;

                    } catch (error) {
                        console.error('[ODYSSEY] Error in detectSports:', error);
                        return [];
                    }
                };

                // Execute the detection
                return window.odyssey.detectSports();

            } catch (error) {
                console.error('[ODYSSEY] Error in sports detection script:', error);
                return [];
            }
        })();
        """

        logger.info("🔍 Executing sports detection script...")

        webView.evaluateJavaScript(sportsScript) { [weak self] result, error in
            if let error {
                self?.logger.error("❌ Sports detection error: \(error.localizedDescription).")
                self?.isLoading = false
                self?.completionHandler?([])
            } else if let sportsArray = result as? [String] {
                self?.logger.info("✅ Extracted \(sportsArray.count) sports: \(sportsArray).")
                self?.availableSports = sportsArray
                self?.isLoading = false
                self?.completionHandler?(sportsArray)
            } else {
                self?.logger.warning("⚠️ Invalid sports data received.")
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
    public func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        logger.info("🚀 WebView navigation started")
    }

    public func webView(_: WKWebView, didReceiveServerRedirectForProvisionalNavigation _: WKNavigation!) {
        logger.info("🔄 WebView received server redirect")
    }

    public func webView(_: WKWebView, didCommit _: WKNavigation!) {
        logger.info("📄 WebView did commit navigation")
    }

    public func webView(_: WKWebView, didFinish _: WKNavigation!) {
        logger.info("✅ Facility page loaded successfully.")
        logger.info("🌐 Current URL: \(self.webView?.url?.absoluteString ?? "unknown")")
        logger.info("📄 Page title: \(self.webView?.title ?? "unknown")")

        // Wait a moment for the page to fully render
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.logger.info("🔍 Starting sports detection after page render...")
            self?.executeSportsDetectionScript()
        }
    }

    public func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        logger.error("❌ WebView navigation failed: \(error.localizedDescription)")
        isLoading = false
        completionHandler?([])
    }

    public func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        logger.error("❌ WebView provisional navigation failed: \(error.localizedDescription)")
        isLoading = false
        completionHandler?([])
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
