import Foundation
import os.log
import WebKit

@MainActor
protocol WebKitEngineProtocol {
    func createWebView() -> WKWebView
    func configureWebView(_ webView: WKWebView) throws
    func cleanup()
}

@MainActor
class WebKitEngine: NSObject, WebKitEngineProtocol {
    private var webView: WKWebView?
    private let configuration: WKWebViewConfiguration
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "WebKitEngine")

    init(configuration: WKWebViewConfiguration) {
        self.configuration = configuration
    }

    override convenience init() {
        self.init(configuration: WKWebViewConfiguration())
    }

    func createWebView() -> WKWebView {
        logger.info("🔧 Creating WebView...")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView = webView
        logger.info("✅ WebView created successfully")
        return webView
    }

    func configureWebView(_ webView: WKWebView) throws {
        logger.info("⚙️ Configuring WebView...")

        // Configure WebView settings
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // Set user agent
        webView.customUserAgent = AppConstants.defaultUserAgent

        // Configure preferences
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        logger.info("✅ WebView configured successfully")
    }

    func cleanup() {
        logger.info("🧹 Cleaning up WebKit engine...")
        webView?.stopLoading()
        webView = nil
        logger.info("✅ WebKit engine cleanup completed")
    }
}

extension WebKitEngine: WKNavigationDelegate {
    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation?) {
        logger.info("🌐 Navigation started")
    }

    func webView(_: WKWebView, didFinish _: WKNavigation?) {
        logger.info("✅ Navigation completed")
    }

    func webView(_: WKWebView, didFail _: WKNavigation?, withError error: Error) {
        logger.error("❌ Navigation failed: \(error.localizedDescription)")
    }
}

extension WebKitEngine: WKUIDelegate {
    func webView(
        _: WKWebView,
        createWebViewWith _: WKWebViewConfiguration,
        for _: WKNavigationAction,
        windowFeatures _: WKWindowFeatures,
        ) -> WKWebView? {
        // Handle new window requests
        return nil
    }
}
