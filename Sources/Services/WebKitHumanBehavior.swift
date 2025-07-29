import Foundation
import os.log
import WebKit

/// WebKit human behavior simulation service
/// Handles advanced human-like behavior patterns for automation
@MainActor
public final class WebKitHumanBehavior: ObservableObject {
    private let logger = Logger(subsystem: "com.odyssey.app", category: "WebKitHumanBehavior")

    // Behavior configuration
    private let instanceId: String
    private var behaviorPatterns: [BehaviorPattern] = []
    private var lastInteractionTime: Date = .init()

    // Timing configuration
    private let minDelay: TimeInterval = AppConstants.minHumanDelay
    private let maxDelay: TimeInterval = AppConstants.maxHumanDelay
    private let pageTransitionDelay: TimeInterval = AppConstants.pageTransitionDelay

    public init(instanceId: String = "default") {
        self.instanceId = instanceId
        logger.info("🔧 WebKitHumanBehavior initialized for instance: \(instanceId)")
    }

    deinit {
        logger.info("🧹 WebKitHumanBehavior deinitialized for instance: \(self.instanceId)")
    }

    // MARK: - Human-Like Delays

    /// Adds a random human-like delay
    public func addHumanDelay() async {
        let delay = Double.random(in: minDelay ... maxDelay)
        logger.debug("⏱️ Adding human delay: \(String(format: "%.2f", delay))s for instance: \(self.instanceId)")
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Adds a page transition delay
    public func addPageTransitionDelay() async {
        logger
            .debug(
                "⏱️ Adding page transition delay: \(String(format: "%.2f", self.pageTransitionDelay))s for instance: \(self.instanceId)",
                )
        try? await Task.sleep(nanoseconds: UInt64(pageTransitionDelay * 1_000_000_000))
    }

    /// Adds a typing delay
    public func addTypingDelay() async {
        let delay = AppConstants.typingDelay
        logger.debug("⏱️ Adding typing delay: \(String(format: "%.2f", delay))s for instance: \(self.instanceId)")
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    // MARK: - Element Interaction

    /// Simulates human-like element clicking
    /// - Parameters:
    ///   - webView: The WebView to interact with
    ///   - selector: The CSS selector for the element
    ///   - description: Description of the action for logging
    public func simulateHumanClick(in webView: WKWebView, selector: String, description: String) async {
        logger.info("🖱️ Simulating human click: \(description) for instance: \(self.instanceId)")

        // Add pre-click delay
        await addHumanDelay()

        let clickScript = """
        (function() {
            try {
                const element = document.querySelector('\(selector)');
                if (!element) {
                    console.error('[ODYSSEY] Element not found for click: \(selector)');
                    return false;
                }

                // Scroll element into view
                element.scrollIntoView({ behavior: 'smooth', block: 'center' });

                // Add mouse hover before click
                const hoverEvent = new MouseEvent('mouseenter', {
                    bubbles: true,
                    cancelable: true,
                    view: window
                });
                element.dispatchEvent(hoverEvent);

                // Simulate mouse down and up
                const mouseDownEvent = new MouseEvent('mousedown', {
                    bubbles: true,
                    cancelable: true,
                    button: 0,
                    buttons: 1,
                    view: window
                });
                element.dispatchEvent(mouseDownEvent);

                // Small delay between down and up
                setTimeout(() => {
                    const mouseUpEvent = new MouseEvent('mouseup', {
                        bubbles: true,
                        cancelable: true,
                        button: 0,
                        buttons: 0,
                        view: window
                    });
                    element.dispatchEvent(mouseUpEvent);

                    // Finally trigger the click
                    const clickEvent = new MouseEvent('click', {
                        bubbles: true,
                        cancelable: true,
                        button: 0,
                        buttons: 0,
                        view: window
                    });
                    element.dispatchEvent(clickEvent);
                }, Math.random() * 100 + 50);

                console.log('[ODYSSEY] Human click simulated: \(description)');
                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error simulating human click:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(clickScript) as? Bool ?? false
            if result {
                logger.info("✅ Human click simulated successfully: \(description)")
            } else {
                logger.warning("⚠️ Human click simulation failed: \(description)")
            }
        } catch {
            logger.error("❌ Failed to simulate human click: \(error.localizedDescription)")
        }
    }

    /// Simulates human-like text input
    /// - Parameters:
    ///   - webView: The WebView to interact with
    ///   - selector: The CSS selector for the input element
    ///   - text: The text to input
    ///   - description: Description of the action for logging
    public func simulateHumanTextInput(
        in webView: WKWebView,
        selector: String,
        text: String,
        description: String,
        ) async {
        logger.info("⌨️ Simulating human text input: \(description) for instance: \(self.instanceId)")

        // Add pre-input delay
        await addHumanDelay()

        let inputScript = """
        (function() {
            try {
                const element = document.querySelector('\(selector)');
                if (!element) {
                    console.error('[ODYSSEY] Element not found for text input: \(selector)');
                    return false;
                }

                // Focus the element
                element.focus();

                // Clear existing value
                element.value = '';
                element.dispatchEvent(new Event('input', { bubbles: true }));
                element.dispatchEvent(new Event('change', { bubbles: true }));

                const text = '\(text)';
                let currentText = '';

                // Type each character with human-like timing
                for (let i = 0; i < text.length; i++) {
                    setTimeout(() => {
                        currentText += text[i];
                        element.value = currentText;

                        // Dispatch input events
                        element.dispatchEvent(new Event('input', { bubbles: true }));
                        element.dispatchEvent(new Event('change', { bubbles: true }));

                        // Occasionally make a typo and correct it (5% chance)
                        if (Math.random() < 0.05 && i < text.length - 1) {
                            setTimeout(() => {
                                currentText = currentText.slice(0, -1) + text[i];
                                element.value = currentText;
                                element.dispatchEvent(new Event('input', { bubbles: true }));
                            }, Math.random() * 200 + 100);
                        }
                    }, i * (\(AppConstants.typingDelay) * 1000) + Math.random() * 100);
                }

                console.log('[ODYSSEY] Human text input simulated: \(description)');
                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error simulating human text input:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(inputScript) as? Bool ?? false
            if result {
                logger.info("✅ Human text input simulated successfully: \(description)")
            } else {
                logger.warning("⚠️ Human text input simulation failed: \(description)")
            }
        } catch {
            logger.error("❌ Failed to simulate human text input: \(error.localizedDescription)")
        }
    }

    /// Simulates human-like scrolling
    /// - Parameters:
    ///   - webView: The WebView to scroll
    ///   - direction: The scroll direction
    ///   - distance: The scroll distance
    public func simulateHumanScrolling(in webView: WKWebView, direction: ScrollDirection, distance: Int = 300) async {
        logger.info("📜 Simulating human scrolling: \(direction.rawValue) for instance: \(self.instanceId)")

        await addHumanDelay()

        let scrollScript = """
        (function() {
            try {
                const scrollDistance = \(distance);
                const direction = '\(direction.rawValue)';

                // Smooth scrolling with human-like behavior
                const scrollStep = scrollDistance / 10;
                let currentScroll = 0;

                const scrollInterval = setInterval(() => {
                    if (currentScroll >= scrollDistance) {
                        clearInterval(scrollInterval);
                        return;
                    }

                    const step = Math.min(scrollStep, scrollDistance - currentScroll);
                    if (direction === 'down') {
                        window.scrollBy(0, step);
                    } else {
                        window.scrollBy(0, -step);
                    }

                    currentScroll += step;
                }, Math.random() * 50 + 30);

                console.log('[ODYSSEY] Human scrolling simulated: \(direction.rawValue)');
            } catch (error) {
                console.error('[ODYSSEY] Error simulating human scrolling:', error);
            }
        })();
        """

        do {
            _ = try await webView.evaluateJavaScript(scrollScript)
            logger.info("✅ Human scrolling simulated successfully")
        } catch {
            logger.error("❌ Failed to simulate human scrolling: \(error.localizedDescription)")
        }
    }

    // MARK: - Behavior Patterns

    /// Records a behavior pattern for analysis
    /// - Parameter pattern: The behavior pattern to record
    public func recordBehaviorPattern(_ pattern: BehaviorPattern) {
        behaviorPatterns.append(pattern)
        lastInteractionTime = Date()
        logger.debug("📊 Behavior pattern recorded: \(pattern.description) for instance: \(self.instanceId)")
    }

    /// Gets recent behavior patterns
    /// - Parameter count: Number of recent patterns to return
    /// - Returns: Array of recent behavior patterns
    public func getRecentBehaviorPatterns(count: Int = 10) -> [BehaviorPattern] {
        return Array(behaviorPatterns.suffix(count))
    }

    /// Clears old behavior patterns
    public func clearOldBehaviorPatterns() {
        let cutoffTime = Date().addingTimeInterval(-3_600) // 1 hour ago
        behaviorPatterns = behaviorPatterns.filter { $0.timestamp > cutoffTime }
        logger.debug("🧹 Cleared old behavior patterns for instance: \(self.instanceId)")
    }
}

// MARK: - Supporting Types

/// Represents a scroll direction
public enum ScrollDirection: String, CaseIterable {
    case up
    case down
    case left
    case right
}

/// Represents a behavior pattern for analysis
public struct BehaviorPattern {
    public let type: BehaviorType
    public let description: String
    public let timestamp: Date
    public let duration: TimeInterval?

    public init(type: BehaviorType, description: String, timestamp: Date = Date(), duration: TimeInterval? = nil) {
        self.type = type
        self.description = description
        self.timestamp = timestamp
        self.duration = duration
    }
}

/// Types of human behavior patterns
public enum BehaviorType: String, CaseIterable {
    case click
    case type
    case scroll
    case hover
    case wait
    case navigate
}
