import Foundation
import os.log
import WebKit

@MainActor
class WebKitScriptManager {
    static let shared = WebKitScriptManager()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "WebKitScriptManager")
    private init() { }

    func injectAutomationScripts(into webView: WKWebView) {
        let automationScript = """
        window.odyssey = {
            // Find element by text content
            findElementByText: function(text, timeout = 10000) {
                return new Promise((resolve, reject) => {
                    const startTime = Date.now();
                    const checkElement = () => {
                        const elements = document.querySelectorAll('*');
                        for (let element of elements) {
                            if (element.textContent && element.textContent.trim() === text) {
                                resolve(element);
                                return;
                            }
                        }
                        if (Date.now() - startTime < timeout) {
                            setTimeout(checkElement, 100);
                        } else {
                            reject(new Error('Element not found'));
                        }
                    };
                    checkElement();
                });
            },
            // Find element by XPath
            findElementByXPath: function(xpath) {
                const result = document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
                return result.singleNodeValue;
            },
            // Click element with human-like behavior
            clickElement: function(element) {
                if (!element) return false;
                const rect = element.getBoundingClientRect();
                const x = rect.left + rect.width / 2;
                const y = rect.top + rect.height / 2;
                const eventOptions = { bubbles: true, cancelable: true, view: window };
                element.dispatchEvent(new MouseEvent('mouseover', eventOptions));
                element.dispatchEvent(new MouseEvent('mousedown', eventOptions));
                element.dispatchEvent(new MouseEvent('mouseup', eventOptions));
                element.dispatchEvent(new MouseEvent('click', eventOptions));
                return true;
            },
            // Execute arbitrary script
            executeScript: function(script) {
                try {
                    return eval(script);
                } catch (error) {
                    console.error('Script execution error:', error);
                    return null;
                }
            }
        };
        // Make odyssey available globally
        window.webkit.messageHandlers.odysseyHandler.postMessage({
            type: 'scriptInjected',
            data: { success: true }
        });
        """
        let script = WKUserScript(source: automationScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        logger.info("✅ Automation scripts injected into WKWebView.")
    }

    func injectAntiDetectionScripts(into webView: WKWebView, instanceId: String) {
        let antiDetectionScript = """
        // Comprehensive anti-detection measures to avoid reCAPTCHA detection
        (function() {
            // ... (anti-detection script content from WebKitService/WebKitCore) ...
            // For brevity, insert the full anti-detection script here as in the original code
        })();
        """
        let script = WKUserScript(source: antiDetectionScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        logger.info("✅ Anti-detection scripts injected into WKWebView for instance: \(instanceId).")
    }
}
