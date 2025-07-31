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
        logger.info("🔧 WebKitHumanBehavior initialized for instance: \(instanceId).")
    }

    deinit {
        logger.info("🧹 WebKitHumanBehavior deinitialized for instance: \(self.instanceId).")
    }

    // MARK: - Human-Like Delays

    /// Adds a random human-like delay
    public func addHumanDelay() async {
        let delay = Double.random(in: minDelay ... maxDelay)
        logger.debug("⏱️ Adding human delay: \(String(format: "%.2f", delay))s for instance: \(self.instanceId).")
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
        logger.debug("⏱️ Adding typing delay: \(String(format: "%.2f", delay))s for instance: \(self.instanceId).")
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    // MARK: - Element Interaction

    /// Simulates human-like clicking using centralized JavaScript library
    /// - Parameters:
    ///   - webView: The WebView to interact with
    ///   - selector: The CSS selector for the element
    ///   - description: Description of the action for logging
    public func simulateHumanClick(in webView: WKWebView, selector: String, description: String) async {
        logger.info("🖱️ Simulating human click: \(description) for instance: \(self.instanceId).")

        // Add pre-click delay
        await addHumanDelay()

        let script = "window.odyssey.clickElement('\(selector)');"

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("✅ Human click simulated successfully: \(description).")
            } else {
                logger.warning("⚠️ Human click simulation failed: \(description).")
            }
        } catch {
            logger.error("❌ Failed to simulate human click: \(error.localizedDescription).")
        }
    }

    /// Simulates human-like text input using centralized JavaScript library
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
        logger.info("⌨️ Simulating human text input: \(description) for instance: \(self.instanceId).")

        // Add pre-input delay
        await addHumanDelay()

        let script = "window.odyssey.typeTextIntoElement('\(selector)', '\(text)');"

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("✅ Human text input simulated successfully: \(description).")
            } else {
                logger.warning("⚠️ Human text input simulation failed: \(description).")
            }
        } catch {
            logger.error("❌ Failed to simulate human text input: \(error.localizedDescription).")
        }
    }

    /// Simulates human-like scrolling using centralized JavaScript library
    /// - Parameters:
    ///   - webView: The WebView to scroll
    ///   - direction: The scroll direction
    ///   - distance: The scroll distance
    public func simulateHumanScrolling(in webView: WKWebView, direction: ScrollDirection, distance: Int = 300) async {
        logger.info("📜 Simulating human scrolling: \(direction.rawValue) for instance: \(self.instanceId).")

        await addHumanDelay()

        let script = "window.odyssey.scrollHuman('\(direction.rawValue)', \(distance));"

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("✅ Human scrolling simulated successfully.")
            } else {
                logger.warning("⚠️ Human scrolling simulation failed.")
            }
        } catch {
            logger.error("❌ Failed to simulate human scrolling: \(error.localizedDescription).")
        }
    }

    // MARK: - Behavior Patterns

    /// Records a behavior pattern for analysis
    /// - Parameter pattern: The behavior pattern to record
    public func recordBehaviorPattern(_ pattern: BehaviorPattern) {
        behaviorPatterns.append(pattern)
        lastInteractionTime = Date()
        logger.debug("📊 Behavior pattern recorded: \(pattern.description) for instance: \(self.instanceId).")
    }

    /// Gets recent behavior patterns
    /// - Parameter count: Number of recent patterns to return
    /// - Returns: Array of recent behavior patterns
    public func getRecentBehaviorPatterns(count: Int = 10) -> [BehaviorPattern] {
        return Array(behaviorPatterns.suffix(count))
    }

    /// Clears behavior patterns older than 1 hour
    public func clearOldBehaviorPatterns() {
        let cutoffTime = Date().addingTimeInterval(-3_600) // 1 hour ago
        behaviorPatterns = behaviorPatterns.filter { $0.timestamp > cutoffTime }
        logger
            .debug("🧹 Cleared behavior patterns older than 1 hour for instance: \(self.instanceId, privacy: .public).")
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
