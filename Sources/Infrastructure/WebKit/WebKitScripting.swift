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

        // Use the centralized library for script injection
        _ = try await evaluateJavaScript(script)
        logger.info("✅ Script injection completed")
    }

    func clickElement(_ selector: String) async throws {
        logger.info("🖱️ Clicking element: \(selector)")

        let result = try await evaluateJavaScript("window.odyssey.clickElement('\(selector)');")
        guard let clicked = result as? Bool, clicked else {
            throw DomainError.automation(.elementNotFound(selector))
        }

        logger.info("✅ Element clicked successfully")
    }

    func typeText(_ text: String, into selector: String) async throws {
        logger.info("⌨️ Typing text into element: \(selector)")

        let result = try await evaluateJavaScript("window.odyssey.typeTextIntoElement('\(selector)', '\(text)');")
        guard let typed = result as? Bool, typed else {
            throw DomainError.automation(.elementNotFound(selector))
        }

        logger.info("✅ Text typed successfully")
    }

    func getElementText(_ selector: String) async throws -> String? {
        logger.info("📖 Getting element text: \(selector)")

        let result = try await evaluateJavaScript("window.odyssey.getElementText('\(selector)');")
        let text = result as? String
        logger.info("✅ Element text retrieved: \(text ?? "null")")
        return text
    }

    func waitForElementToBeClickable(_ selector: String) async throws -> Bool {
        logger.info("⏳ Waiting for element to be clickable: \(selector)")

        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            do {
                let result = try await evaluateJavaScript("window.odyssey.isElementClickable('\(selector)');")
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
