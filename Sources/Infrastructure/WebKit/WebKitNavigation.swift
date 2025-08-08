import Foundation
import WebKit
import os.log

@MainActor
protocol WebKitNavigationProtocol {
  func navigateToURL(_ url: String) async throws
  func waitForPageLoad() async throws
  func goBack() async throws
  func goForward() async throws
  func refresh() async throws
  func waitForElement(_ selector: String) async throws -> Bool
}

@MainActor
class WebKitNavigation: WebKitNavigationProtocol {
  private let webView: WKWebView
  private let timeout: TimeInterval
  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem, category: "WebKitNavigation")

  init(webView: WKWebView, timeout: TimeInterval = AppConstants.pageLoadTimeout) {
    self.webView = webView
    self.timeout = timeout
  }

  func navigateToURL(_ url: String) async throws {
    logger.info("🌐 Navigating to URL: \(url).")

    guard let url = URL(string: url) else {
      throw DomainError.validation(.invalidURL(url))
    }

    let request = URLRequest(url: url)
    webView.load(request)

    try await waitForPageLoad()
    logger.info("✅ Navigation completed.")
  }

  func waitForPageLoad() async throws {
    logger.info("⏳ Waiting for page load...")

    let startTime = Date()
    while Date().timeIntervalSince(startTime) < timeout {
      if webView.isLoading {
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
      } else {
        logger.info("✅ Page load completed.")
        return
      }
    }

    throw DomainError.automation(.pageLoadTimeout("Page load timeout after \(Int(timeout))s"))
  }

  func goBack() async throws {
    logger.info("⬅️ Going back...")

    guard webView.canGoBack else {
      throw DomainError.automation(.elementNotFound("Back button"))
    }

    webView.goBack()
    try await waitForPageLoad()
    logger.info("✅ Navigation back completed.")
  }

  func goForward() async throws {
    logger.info("➡️ Going forward...")

    guard webView.canGoForward else {
      throw DomainError.automation(.elementNotFound("Forward button"))
    }

    webView.goForward()
    try await waitForPageLoad()
    logger.info("✅ Navigation forward completed.")
  }

  func refresh() async throws {
    logger.info("🔄 Refreshing page...")
    webView.reload()
    try await waitForPageLoad()
    logger.info("✅ Page refresh completed")
  }

  func waitForElement(_ selector: String) async throws -> Bool {
    logger.info("🔍 Waiting for element: \(selector)")

    let startTime = Date()
    while Date().timeIntervalSince(startTime) < timeout {
      do {
        let result =
          try await webView
          .evaluateJavaScript("window.odyssey.findElementBySelector('\(selector)');")
        if let found = result as? Bool, found {
          logger.info("✅ Element found: \(selector)")
          return true
        }
      } catch {
        logger.error("❌ JavaScript evaluation failed: \(error.localizedDescription)")
      }

      try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
    }

    logger.error("❌ Element not found: \(selector)")
    return false
  }
}
