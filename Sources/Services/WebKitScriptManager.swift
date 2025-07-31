import Foundation
import os.log
import WebKit

@MainActor
class WebKitScriptManager {
    static let shared = WebKitScriptManager()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "WebKitScriptManager")
    private init() { }

    func injectAutomationScripts(into webView: WKWebView) {
        let automationScript = JavaScriptLibrary.getAutomationLibrary()
        let script = WKUserScript(source: automationScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        logger.info("✅ Automation scripts injected into WKWebView.")
    }

    func injectAntiDetectionScripts(into webView: WKWebView, instanceId: String) {
        let antiDetectionScript = JavaScriptLibrary.getAntiDetectionLibrary()
        let script = WKUserScript(source: antiDetectionScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        logger.info("✅ Anti-detection scripts injected into WKWebView for instance: \(instanceId).")
    }

    func injectAllScripts(into webView: WKWebView, instanceId: String) {
        // Inject automation scripts
        injectAutomationScripts(into: webView)

        // Inject anti-detection scripts
        injectAntiDetectionScripts(into: webView, instanceId: instanceId)

        logger.info("✅ All JavaScript libraries injected for instance: \(instanceId).")
    }
}
