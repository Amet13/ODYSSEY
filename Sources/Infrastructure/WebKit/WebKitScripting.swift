import Foundation
import os.log
import WebKit

@MainActor
protocol WebKitScriptingProtocol {
    func evaluateJavaScript(_ script: String) async throws -> Any?
    func injectScript(_ script: String) async throws
    func clickElement(_ selector: String) async throws
    func typeText(_ text: String, into selector: String) async throws
    func getElementText(_ selector: String) async throws -> String?
    func waitForElementToBeClickable(_ selector: String) async throws -> Bool
}

@MainActor
class WebKitScripting: WebKitScriptingProtocol {
    private let webView: WKWebView
    private let timeout: TimeInterval
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "WebKitScripting")

    init(webView: WKWebView, timeout: TimeInterval = AppConstants.elementWaitTimeout) {
        self.webView = webView
        self.timeout = timeout
    }

    func evaluateJavaScript(_ script: String) async throws -> Any? {
        logger.info("📜 Evaluating JavaScript...")

        return try await webView.evaluateJavaScript(script)
    }

    func injectScript(_ script: String) async throws {
        logger.info("💉 Injecting script...")

        let wrappedScript = """
        (function() {
            \(script)
        })();
        """

        _ = try await evaluateJavaScript(wrappedScript)
        logger.info("✅ Script injection completed")
    }

    func clickElement(_ selector: String) async throws {
        logger.info("🖱️ Clicking element: \(selector)")

        let script = """
        (function() {
            const element = document.querySelector('\(selector)');
            if (element) {
                element.click();
                return true;
            }
            return false;
        })();
        """

        let result = try await evaluateJavaScript(script)
        guard let clicked = result as? Bool, clicked else {
            throw DomainError.automation(.elementNotFound(selector))
        }

        logger.info("✅ Element clicked successfully")
    }

    func typeText(_ text: String, into selector: String) async throws {
        logger.info("⌨️ Typing text into element: \(selector)")

        let script = """
        (function() {
            const element = document.querySelector('\(selector)');
            if (element) {
                element.focus();
                element.value = '';
                element.value = '\(text)';
                element.dispatchEvent(new Event('input', { bubbles: true }));
                element.dispatchEvent(new Event('change', { bubbles: true }));
                return true;
            }
            return false;
        })();
        """

        let result = try await evaluateJavaScript(script)
        guard let typed = result as? Bool, typed else {
            throw DomainError.automation(.elementNotFound(selector))
        }

        logger.info("✅ Text typed successfully")
    }

    func getElementText(_ selector: String) async throws -> String? {
        logger.info("📖 Getting element text: \(selector)")

        let script = """
        (function() {
            const element = document.querySelector('\(selector)');
            if (element) {
                return element.textContent || element.innerText || element.value || '';
            }
            return null;
        })();
        """

        let result = try await evaluateJavaScript(script)
        let text = result as? String
        logger.info("✅ Element text retrieved: \(text ?? "null")")
        return text
    }

    func waitForElementToBeClickable(_ selector: String) async throws -> Bool {
        logger.info("⏳ Waiting for element to be clickable: \(selector)")

        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            let script = """
            (function() {
                const element = document.querySelector('\(selector)');
                if (element) {
                    const rect = element.getBoundingClientRect();
                    const isVisible = rect.width > 0 && rect.height > 0;
                    const isEnabled = !element.disabled;
                    const isClickable = element.offsetParent !== null;
                    return isVisible && isEnabled && isClickable;
                }
                return false;
            })();
            """

            do {
                let result = try await evaluateJavaScript(script)
                if let clickable = result as? Bool, clickable {
                    logger.info("✅ Element is clickable: \(selector)")
                    return true
                }
            } catch {
                logger.error("❌ JavaScript evaluation failed: \(error.localizedDescription)")
            }

            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        logger.error("❌ Element not clickable: \(selector)")
        return false
    }
}
