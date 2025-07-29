import Foundation
import os.log
import WebKit

/// WebKit anti-detection service for human-like automation
/// Handles all anti-detection measures and human-like behavior simulation
@MainActor
public final class WebKitAntiDetection: ObservableObject {
    private let logger = Logger(subsystem: "com.odyssey.app", category: "WebKitAntiDetection")

    // Anti-detection configuration
    private let instanceId: String
    private var mouseMovements: [MouseMovement] = []
    private var lastActivityTime: Date = .init()

    // Human-like behavior settings
    private let minHumanDelay: TimeInterval = AppConstants.minHumanDelay
    private let maxHumanDelay: TimeInterval = AppConstants.maxHumanDelay
    private let typingDelay: TimeInterval = AppConstants.typingDelay

    public init(instanceId: String = "default") {
        self.instanceId = instanceId
        logger.info("🔧 WebKitAntiDetection initialized for instance: \(instanceId)")
    }

    deinit {
        logger.info("🧹 WebKitAntiDetection deinitialized for instance: \(self.instanceId)")
    }

    // MARK: - Anti-Detection Scripts

    /// Injects basic anti-detection scripts into the WebView
    /// - Parameter webView: The WebView to inject scripts into
    public func injectAntiDetectionScripts(into webView: WKWebView) async {
        logger.info("🛡️ Injecting anti-detection scripts for instance: \(self.instanceId)")

        let antiDetectionScript = """
        (function() {
            try {
                if (navigator.webdriver !== undefined) {
                    Object.defineProperty(navigator, 'webdriver', {
                        get: () => undefined,
                        configurable: true
                    });
                }

                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Array) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array;
                }
                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Promise) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise;
                }
                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol;
                }

                // Override automation detection methods
                if (window.chrome && window.chrome.runtime) {
                    Object.defineProperty(window.chrome, 'runtime', {
                        get: () => undefined,
                        configurable: true
                    });
                }

                // Add human-like properties
                if (!window.odysseyMouseMovements) {
                    window.odysseyMouseMovements = [];
                }

                // Override automation detection
                const originalQuerySelector = document.querySelector;
                document.querySelector = function(selector) {
                    const result = originalQuerySelector.call(this, selector);
                    if (result && result.tagName === 'IFRAME') {
                        // Handle iframe detection
                        try {
                            const iframeDoc = result.contentDocument || result.contentWindow.document;
                            if (iframeDoc) {
                                // Apply anti-detection to iframe
                                if (!iframeDoc.odysseyAntiDetectionApplied) {
                                    iframeDoc.odysseyAntiDetectionApplied = true;
                                }
                            }
                        } catch (e) {
                            // Cross-origin iframe, ignore
                        }
                    }
                    return result;
                };

                console.log('[ODYSSEY] Anti-detection measures applied for instance: \(instanceId)');
            } catch (error) {
                console.error('[ODYSSEY] Error in anti-detection script:', error);
            }
        })();
        """

        do {
            _ = try await webView.evaluateJavaScript(antiDetectionScript)
            logger.info("✅ Anti-detection scripts injected successfully")
        } catch {
            logger.error("❌ Failed to inject anti-detection scripts: \(error.localizedDescription)")
        }
    }

    /// Injects enhanced human-like behavior scripts
    /// - Parameter webView: The WebView to inject scripts into
    public func injectHumanBehaviorScripts(into webView: WKWebView) async {
        logger.info("👤 Injecting human behavior scripts for instance: \(self.instanceId)")

        let humanBehaviorScript = """
        (function() {
            try {
                // Simulate human-like typing behavior
                const originalSetValue = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
                Object.defineProperty(HTMLInputElement.prototype, 'value', {
                    set: function(value) {
                        // Add slight delay to simulate human typing
                        setTimeout(() => {
                            originalSetValue.call(this, value);
                            this.dispatchEvent(new Event('input', { bubbles: true }));
                            this.dispatchEvent(new Event('change', { bubbles: true }));
                        }, Math.random() * 100 + 50);
                    },
                    get: Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').get,
                    configurable: true
                });

                // Add mouse movement tracking
                if (!window.odysseyMouseMovements) {
                    window.odysseyMouseMovements = [];
                }

                // Override click events to add human-like delays
                const originalClick = HTMLElement.prototype.click;
                HTMLElement.prototype.click = function() {
                    // Add random delay before click
                    setTimeout(() => {
                        originalClick.call(this);
                    }, Math.random() * 200 + 100);
                };

                console.log('[ODYSSEY] Human behavior scripts applied for instance: \(instanceId)');
            } catch (error) {
                console.error('[ODYSSEY] Error in human behavior script:', error);
            }
        })();
        """

        do {
            _ = try await webView.evaluateJavaScript(humanBehaviorScript)
            logger.info("✅ Human behavior scripts injected successfully")
        } catch {
            logger.error("❌ Failed to inject human behavior scripts: \(error.localizedDescription)")
        }
    }

    // MARK: - Human-Like Behavior Simulation

    /// Simulates human-like mouse movements
    /// - Parameter webView: The WebView to simulate movements in
    public func simulateMouseMovements(in webView: WKWebView) async {
        logger.info("🖱️ Simulating human-like mouse movements for instance: \(self.instanceId)")

        let mouseMovementScript = """
        (function() {
            try {
                const movements = [];
                const viewportWidth = window.innerWidth;
                const viewportHeight = window.innerHeight;

                // Generate random mouse movements
                for (let i = 0; i < 5; i++) {
                    const x = Math.random() * viewportWidth;
                    const y = Math.random() * viewportHeight;
                    movements.push({ x, y });
                }

                // Simulate mouse movements with delays
                movements.forEach((movement, index) => {
                    setTimeout(() => {
                        const event = new MouseEvent('mousemove', {
                            bubbles: true,
                            cancelable: true,
                            clientX: movement.x,
                            clientY: movement.y
                        });
                        document.dispatchEvent(event);
                    }, index * 100);
                });

                console.log('[ODYSSEY] Mouse movements simulated for instance: \(instanceId)');
            } catch (error) {
                console.error('[ODYSSEY] Error simulating mouse movements:', error);
            }
        })();
        """

        do {
            _ = try await webView.evaluateJavaScript(mouseMovementScript)
            logger.info("✅ Mouse movements simulated successfully")
        } catch {
            logger.error("❌ Failed to simulate mouse movements: \(error.localizedDescription)")
        }
    }

    /// Simulates human-like typing behavior
    /// - Parameters:
    ///   - webView: The WebView to simulate typing in
    ///   - text: The text to type
    ///   - elementSelector: The selector for the input element
    public func simulateHumanTyping(in webView: WKWebView, text: String, elementSelector: String) async {
        logger.info("⌨️ Simulating human typing for instance: \(self.instanceId)")

        let typingScript = """
        (function() {
            try {
                const element = document.querySelector('\(elementSelector)');
                if (!element) {
                    console.error('[ODYSSEY] Element not found for typing: \(elementSelector)');
                    return;
                }

                element.focus();
                element.value = '';

                const text = '\(text)';
                let currentText = '';

                // Type each character with random delays
                for (let i = 0; i < text.length; i++) {
                    setTimeout(() => {
                        currentText += text[i];
                        element.value = currentText;

                        // Dispatch events
                        element.dispatchEvent(new Event('input', { bubbles: true }));
                        element.dispatchEvent(new Event('change', { bubbles: true }));

                        // Occasionally make a typo and correct it
                        if (Math.random() < 0.05 && i < text.length - 1) {
                            setTimeout(() => {
                                currentText = currentText.slice(0, -1) + text[i];
                                element.value = currentText;
                                element.dispatchEvent(new Event('input', { bubbles: true }));
                            }, Math.random() * 200 + 100);
                        }
                    }, i * (\(typingDelay) * 1000) + Math.random() * 100);
                }

                console.log('[ODYSSEY] Human typing simulated for instance: \(instanceId)');
            } catch (error) {
                console.error('[ODYSSEY] Error simulating human typing:', error);
            }
        })();
        """

        do {
            _ = try await webView.evaluateJavaScript(typingScript)
            logger.info("✅ Human typing simulated successfully")
        } catch {
            logger.error("❌ Failed to simulate human typing: \(error.localizedDescription)")
        }
    }

    // MARK: - Activity Tracking

    /// Records user activity for anti-detection
    public func recordActivity() {
        lastActivityTime = Date()
        logger.debug("📊 Activity recorded for instance: \(self.instanceId)")
    }

    /// Gets the time since last activity
    public var timeSinceLastActivity: TimeInterval {
        return Date().timeIntervalSince(lastActivityTime)
    }

    /// Checks if the instance has been inactive for too long
    public var isInactive: Bool {
        return timeSinceLastActivity > 300 // 5 minutes
    }
}

// MARK: - Supporting Types

/// Represents a mouse movement for anti-detection
public struct MouseMovement {
    public let x: CGFloat
    public let y: CGFloat
    public let timestamp: Date

    public init(x: CGFloat, y: CGFloat, timestamp: Date = Date()) {
        self.x = x
        self.y = y
        self.timestamp = timestamp
    }
}
