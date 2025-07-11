import Combine
import Foundation
import os.log
import WebKit

/// Service for fetching available sports/activities from facility pages
/// Handles web scraping and sports detection from Ottawa recreation facilities
class FacilityService: NSObject, ObservableObject {
    static let shared = FacilityService()
    
    @Published var isLoading = false
    @Published var availableSports: [String] = []
    @Published var error: String?
    
    private var webView: WKWebView?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "FacilityService")
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Fetches available sports from a facility URL
    /// - Parameters:
    ///   - url: The facility URL to scrape
    ///   - completion: Callback with detected sports array
    func fetchAvailableSports(from url: String, completion: @escaping ([String]) -> Void) {
        guard let facilityURL = URL(string: url) else {
            logger.error("Invalid facility URL: \(url)")
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
                self?.logger.warning("Timeout loading facility page")
                self?.isLoading = false
                self?.error = "Timeout loading facility page"
                completion([])
            }
        }
        
        // Store completion handler
        self.completionHandler = completion
    }
    
    // MARK: - Private Properties
    
    private var completionHandler: (([String]) -> Void)?
    
    // MARK: - Private Methods
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "facilityHandler")
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
        webView?.uiDelegate = self
    }
    
    private func injectSportsDetectionScript() {
        let script = """
        // ODYSSEY Sports Detection Script
        function extractAvailableSports() {
            const sports = [];
            const excludedTerms = [
                'login', 'sign', 'register', 'search', 'filter', 'date', 'time',
                'submit', 'cancel', 'back', 'next', 'previous', 'close', 'menu',
                'home', 'about', 'contact', 'help', 'settings', 'profile', 'account',
                'logout', 'sign out', 'signout', 'sign up', 'signup', 'create account',
                'new account', 'forgot password', 'reset password', 'change password',
                'update profile', 'edit profile', 'my account', 'my profile',
                'my settings', 'my preferences', 'my bookings', 'my reservations',
                'my history', 'my schedule', 'my calendar', 'my activities',
                'my sports', 'my classes', 'my programs', 'my sessions',
                'my times', 'my slots', 'my time slots'
            ];
            
            // Look specifically for div elements with class="content"
            const contentElements = document.querySelectorAll('div.content');
            
            for (const element of contentElements) {
                const text = element.textContent?.trim();
                if (text && text.length > 0 && text.length < 100) {
                    // Filter out common non-sport text
                    const lowerText = text.toLowerCase();
                    const isExcluded = excludedTerms.some(term => lowerText.includes(term));
                    
                    if (!isExcluded) {
                        sports.push(text);
                    }
                }
            }
            
            // Remove duplicates and sort
            const uniqueSports = [...new Set(sports)].sort();
            
            // Notify Swift about the results
            window.webkit.messageHandlers.facilityHandler.postMessage({
                type: 'sportsDetected',
                sports: uniqueSports,
                count: uniqueSports.length
            });
            
            return uniqueSports;
        }
        
        // Run the detection
        extractAvailableSports();
        """
        
        webView?.evaluateJavaScript(script) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Sports detection script error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = "Failed to analyze page: \(error.localizedDescription)"
                    self.completionHandler?([])
                }
            } else {
                // Script executed successfully
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension FacilityService: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.injectSportsDetectionScript()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
        logger.error("Failed to load facility page: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isLoading = false
            self.error = "Failed to load page: \(error.localizedDescription)"
            self.completionHandler?([])
        }
    }
}

// MARK: - WKUIDelegate

extension FacilityService: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension FacilityService: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "facilityHandler",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else { 
            logger.warning("Invalid message received from facility WebKit")
            return 
        }
        
        switch type {
        case "sportsDetected":
            handleSportsDetected(body)
        default:
            logger.warning("Unknown facility message type: \(type)")
        }
    }
    
    private func handleSportsDetected(_ data: [String: Any]) {
        guard let sports = data["sports"] as? [String] else { 
            logger.warning("Invalid sports data received")
            return 
        }
        
        DispatchQueue.main.async {
            self.isLoading = false
            self.availableSports = sports
            self.completionHandler?(sports)
        }
    }
} 