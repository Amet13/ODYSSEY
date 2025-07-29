import AppKit
import Foundation
import os.log
import WebKit

/// Service for fetching available sports from facility websites
public final class FacilityService: NSObject, @unchecked Sendable, FacilityServiceProtocol {
    // MARK: - Properties

    public static let shared = FacilityService()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "FacilityService")
    private var webView: WKWebView?
    public var isLoading = false
    public var error: String?
    public var availableSports: [String] = []
    private var completionHandler: (([String]) -> Void)?

    // MARK: - Initialization

    override init() {
        logger.info("🔧 FacilityService initialized (DI mode).")
        super.init()
    }

    deinit {
        logger.info("🧹 FacilityService deinitialized.")
    }

    func cleanup() {
        logger.info("🧹 FacilityService cleanup called.")
    }

    // MARK: - Public Methods

    /**
     Fetches available sports from a facility URL
     - Parameters:
     ///   - url: The facility URL to scrape
     ///   - completion: Callback with detected sports array
     */
    public func fetchAvailableSports(from url: String, completion: @escaping ([String]) -> Void) {
        guard let facilityURL = URL(string: url) else {
            logger.error("❌ Invalid facility URL: \(url).")
            completion([])
            return
        }

        isLoading = true
        error = nil
        availableSports = []

        setupWebView()

        let request = URLRequest(url: facilityURL)
        webView?.load(request)

        // Set up timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            if self?.isLoading == true {
                self?.logger.warning("⏰ Timeout loading facility page.")
                self?.isLoading = false
                self?.error = "Timeout loading facility page"
                completion([])
            }
        }

        // Store completion handler
        completionHandler = completion
    }

    // MARK: - Private Methods

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        // Add script message handler
        let scriptMessageHandler = WebKitScriptMessageHandler()
        configuration.userContentController.add(scriptMessageHandler, name: "facilityHandler")

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
        webView?.uiDelegate = self
    }

    private func executeSportsDetectionScript() {
        let sportsDetectionScript = """
        (function() {
            const sports = [];
            const debug = [];

            // Look for sport buttons/links with more comprehensive selectors
            const selectors = [
                '[class*="content"]'
            ];

            const sportElements = document.querySelectorAll(selectors.join(', '));
            debug.push(`Found ${sportElements.length} potential elements`);

            sportElements.forEach((element, index) => {
                const text = element.textContent?.trim();
                if (text && text.length > 0 && text.length < 50) {
                    // Filter out common non-sport text
                    const lowerText = text.toLowerCase();
                    const excludedWords = [
                        'login', 'sign', 'help', 'contact', 'about', 'home',
                        'menu', 'search', 'close', 'cancel', 'submit', 'next',
                        'previous', 'back', 'logout', 'register', 'account',
                        'settings', 'profile', 'dashboard', 'admin', 'user'
                    ];

                    const shouldExclude = excludedWords.some(word => lowerText.includes(word));

                    if (!shouldExclude) {
                        sports.push(text);
                        debug.push(`Added sport: "${text}" (element ${index})`);
                    } else {
                        debug.push(`Excluded: "${text}" (contains excluded word)`);
                    }
                }
            });

            const uniqueSports = [...new Set(sports)];
            debug.push(`Final unique sports: ${uniqueSports.length}`);

            console.log('[ODYSSEY] Sports detection debug:', debug);
            return uniqueSports;
        })();
        """

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
                self?.logger.warning("⚠️ Invalid sports data received.")
                self?.isLoading = false
                self?.completionHandler?([])
            }
        }
    }

    private func executeFallbackSportsDetection() {
        let fallbackScript = """
        (function() {
            const sports = [];
            const debug = [];

            // Try a more aggressive approach - look for any clickable elements with text
            const allElements = document.querySelectorAll('*');
            debug.push(`Total elements on page: ${allElements.length}`);

            allElements.forEach((element, index) => {
                // Only check elements that are likely to be clickable
                const isClickable = element.tagName === 'BUTTON' ||
                                   element.tagName === 'A' ||
                                   element.onclick ||
                                   element.style.cursor === 'pointer' ||
                                   element.classList.contains('btn') ||
                                   element.classList.contains('button') ||
                                   element.getAttribute('role') === 'button';

                if (isClickable) {
                    const text = element.textContent?.trim();
                    if (text && text.length > 0 && text.length < 50) {
                        const lowerText = text.toLowerCase();

                        // More permissive filtering - only exclude obvious non-sports
                        const excludedWords = [
                            'login', 'logout', 'sign', 'register', 'account',
                            'settings', 'profile', 'dashboard', 'admin', 'user',
                            'help', 'contact', 'about', 'home', 'menu', 'search',
                            'close', 'cancel', 'submit', 'next', 'previous', 'back'
                        ];

                        const shouldExclude = excludedWords.some(word => lowerText.includes(word));

                        if (!shouldExclude) {
                            sports.push(text);
                            debug.push(`Fallback added: "${text}" (${element.tagName})`);
                        }
                    }
                }
            });

            const uniqueSports = [...new Set(sports)];
            debug.push(`Fallback unique sports: ${uniqueSports.length}`);

            console.log('[ODYSSEY] Fallback sports detection debug:', debug);
            return uniqueSports;
        })();
        """

        webView?.evaluateJavaScript(fallbackScript) { [weak self] result, error in
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
    /// - Parameter message: Message from WebKit
    func handleWebKitMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else {
            logger.warning("⚠️ Invalid message received from facility WebKit.")
            return
        }

        switch type {
        case "sportsData":
            if let sports = message["data"] as? [String] {
                logger.info("✅ Received sports data: \(sports).")
            } else {
                logger.warning("⚠️ Unknown facility message type: \(type).")
            }
        case "error":
            if let error = message["error"] as? String {
                logger.error("❌ Facility WebKit error: \(error).")
            }
        default:
            logger.warning("⚠️ Invalid sports data received.")
        }
    }
}

// MARK: - WKNavigationDelegate

extension FacilityService: WKNavigationDelegate {
    public func webView(_: WKWebView, didFinish _: WKNavigation?) {
        logger.info("✅ Facility page loaded successfully.")

        // Execute sports detection script after page is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.executeSportsDetectionScript()
        }

        // Fallback: if no sports found after 5 seconds, try again with different approach
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if let self, self.availableSports.isEmpty {
                self.logger.warning("⚠️ No sports found after 5 seconds, trying fallback detection.")
                self.executeFallbackSportsDetection()
            }
        }
    }

    public func webView(_: WKWebView, didFail _: WKNavigation?, withError error: Error) {
        logger.error("❌ Failed to load facility page: \(error.localizedDescription).")
        isLoading = false
        self.error = error.localizedDescription
        completionHandler?([])
    }
}

// MARK: - WKUIDelegate

extension FacilityService: WKUIDelegate {
    // Handle any UI-related WebKit events if needed
}
