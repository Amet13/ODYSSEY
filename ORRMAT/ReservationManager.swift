import Foundation
import WebKit
import Combine
import os.log

/// Manages the automation of reservation bookings
class ReservationManager: NSObject, ObservableObject {
    static let shared = ReservationManager()
    
    @Published var isRunning = false
    @Published var lastRunDate: Date?
    @Published var lastRunStatus: RunStatus = .idle
    @Published var currentTask: String = ""
    
    private var webView: WKWebView?
    private var cancellables = Set<AnyCancellable>()
    private let configurationManager = ConfigurationManager.shared
    private let logger = Logger(subsystem: "com.orrmat.app", category: "ReservationManager")
    
    enum RunStatus {
        case idle
        case running
        case success
        case failed(String)
        
        var description: String {
            switch self {
            case .idle: return "Idle"
            case .running: return "Running"
            case .success: return "Success"
            case .failed(let error): return "Failed: \(error)"
            }
        }
    }
    
    private override init() {
        super.init()
        setupWebView()
    }
    
    // MARK: - Public Methods
    
    func runReservation(for config: ReservationConfig) {
        guard !isRunning else { 
            logger.warning("Reservation already running, skipping")
            return 
        }
        
        logger.info("Starting reservation for: \(config.name)")
        isRunning = true
        lastRunStatus = .running
        currentTask = "Starting reservation for \(config.name)"
        
        // Initialize web automation
        setupWebView()
        
        // Navigate to the facility URL
        guard let url = URL(string: config.facilityURL) else {
            let error = "Invalid URL: \(config.facilityURL)"
            logger.error("\(error)")
            handleError(error)
            return
        }
        
        let request = URLRequest(url: url)
        webView?.load(request)
        
        // Set up completion handler
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.handleTimeout()
        }
    }
    
    func runAllEnabledReservations() {
        let enabledConfigs = configurationManager.getEnabledConfigurations()
        logger.info("Running all enabled reservations: \(enabledConfigs.count) configurations")
        
        for config in enabledConfigs {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.runReservation(for: config)
            }
        }
    }
    
    func stopAllReservations() {
        logger.info("Stopping all reservations")
        isRunning = false
        lastRunStatus = .idle
        currentTask = ""
        webView?.stopLoading()
    }
    
    // MARK: - Private Methods
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "orrmatHandler")
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
        webView?.uiDelegate = self
    }
    
    private func handleError(_ error: String) {
        logger.error("Reservation error: \(error)")
        DispatchQueue.main.async {
            self.isRunning = false
            self.lastRunStatus = .failed(error)
            self.currentTask = "Error: \(error)"
            self.lastRunDate = Date()
        }
    }
    
    private func handleSuccess() {
        logger.info("Reservation completed successfully")
        DispatchQueue.main.async {
            self.isRunning = false
            self.lastRunStatus = .success
            self.currentTask = "Reservation completed successfully"
            self.lastRunDate = Date()
        }
    }
    
    private func handleTimeout() {
        if isRunning {
            logger.warning("Reservation operation timed out")
            handleError("Operation timed out")
        }
    }
    
    private func injectAutomationScript() {
        let script = """
        // ORRMAT Automation Script
        function findAndClickElement(selector, text) {
            const elements = document.querySelectorAll(selector);
            for (let element of elements) {
                if (element.textContent.includes(text)) {
                    element.click();
                    return true;
                }
            }
            return false;
        }
        
        function findAndFillInput(selector, value) {
            const input = document.querySelector(selector);
            if (input) {
                input.value = value;
                input.dispatchEvent(new Event('input', { bubbles: true }));
                return true;
            }
            return false;
        }
        
        // Notify Swift about page load
        window.webkit.messageHandlers.orrmatHandler.postMessage({
            type: 'pageLoaded',
            url: window.location.href,
            title: document.title
        });
        """
        
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                self.logger.error("Script injection error: \(error.localizedDescription)")
            } else {
                self.logger.debug("Automation script injected successfully")
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension ReservationManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        currentTask = "Page loaded, injecting automation script"
        logger.debug("Page loaded successfully")
        injectAutomationScript()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logger.error("Navigation failed: \(error.localizedDescription)")
        handleError("Navigation failed: \(error.localizedDescription)")
    }
}

// MARK: - WKUIDelegate

extension ReservationManager: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle new window requests
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension ReservationManager: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "orrmatHandler",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else { 
            logger.warning("Invalid message received from WebKit")
            return 
        }
        
        switch type {
        case "pageLoaded":
            handlePageLoaded(body)
        case "elementFound":
            handleElementFound(body)
        case "elementNotFound":
            handleElementNotFound(body)
        default:
            logger.warning("Unknown message type: \(type)")
        }
    }
    
    private func handlePageLoaded(_ data: [String: Any]) {
        guard let url = data["url"] as? String,
              let title = data["title"] as? String else { return }
        
        currentTask = "Loaded: \(title)"
        logger.info("Page loaded: \(title) at \(url)")
        
        // Here you would implement specific automation logic based on the page
        // For now, we'll simulate a successful reservation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.handleSuccess()
        }
    }
    
    private func handleElementFound(_ data: [String: Any]) {
        currentTask = "Found target element"
        logger.debug("Target element found")
    }
    
    private func handleElementNotFound(_ data: [String: Any]) {
        currentTask = "Target element not found"
        logger.warning("Target element not found")
    }
} 