import Foundation
import WebKit
import os.log

/// WebKit anti-detection service
/// Implements advanced techniques to avoid detection by websites
@MainActor
public final class WebKitAntiDetection: ObservableObject {
  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem, category: "WebKitAntiDetection")

  // Anti-detection configuration
  private let instanceId: String
  private var lastInteractionTime: Date = .init()

  // Timing configuration
  private let minDelay: TimeInterval = AppConstants.minHumanDelay
  private let maxDelay: TimeInterval = AppConstants.maxHumanDelay

  public init(instanceId: String = "default") {
    self.instanceId = instanceId
    logger.info("🔧 WebKitAntiDetection initialized for instance: \(instanceId).")
  }

  deinit {
    logger.info("🧹 WebKitAntiDetection deinitialized for instance: \(self.instanceId).")
  }

  // MARK: - Anti-Detection Methods

  /// Injects anti-detection scripts into the WebView
  public func injectAntiDetectionScripts(into webView: WKWebView) async {
    logger.info("🛡️ Injecting anti-detection scripts.")

    let antiDetectionScript = JavaScriptLibrary.getAntiDetectionLibrary()
    let script = WKUserScript(
      source: antiDetectionScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    webView.configuration.userContentController.addUserScript(script)

    logger.info("✅ Anti-detection scripts injected successfully.")
  }

  /// Injects human behavior scripts into the WebView
  public func injectHumanBehaviorScripts(into webView: WKWebView) async {
    logger.info("🤖 Injecting human behavior scripts.")

    // Use the mouse movement library as the human behavior script
    let humanBehaviorScript = JavaScriptLibrary.getMouseMovementLibrary()
    let script = WKUserScript(
      source: humanBehaviorScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    webView.configuration.userContentController.addUserScript(script)

    logger.info("✅ Human behavior scripts injected successfully.")
  }

  /// Simulates realistic mouse movements to avoid detection
  public func simulateMouseMovements(in webView: WKWebView) async {
    logger.info("🖱️ Simulating realistic mouse movements.")

    let mouseMovementScript = JavaScriptLibrary.getMouseMovementLibrary()

    do {
      let result = try await webView.evaluateJavaScript(mouseMovementScript) as? Bool ?? false
      if result {
        logger.info("✅ Mouse movements simulated successfully.")
      } else {
        logger.warning("⚠️ Mouse movement simulation failed.")
      }
    } catch {
      logger.error("❌ Mouse movement simulation error: \(error.localizedDescription).")
    }
  }

  /// Adds a random human-like delay
  public func addHumanDelay() async {
    let delay = Double.random(in: minDelay...maxDelay)

    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
  }
}

// MARK: - Supporting Types

/// Represents a mouse movement pattern
public struct MouseMovement {
  public let x: Double
  public let y: Double
  public let timestamp: Date
  public let duration: TimeInterval

  public init(x: Double, y: Double, timestamp: Date = Date(), duration: TimeInterval = 0.1) {
    self.x = x
    self.y = y
    self.timestamp = timestamp
    self.duration = duration
  }
}
