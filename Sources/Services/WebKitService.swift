//
// WebKitService.swift
// ODYSSEY
//
// Created by ODYSSEY Team
//
// IMPORTANT: WebKit Native Approach
// ===================================
// This service implements a native Swift WebKit approach for web automation
// that provides:
// - No external dependencies
// - Native macOS integration
// - Better performance and reliability
// - Smaller app footprint
// - No permission issues
//

import AppKit
import Combine
import Foundation
import WebKit
import os.log

// MARK: - Screenshot Format Enum

/// Defines the format for screenshot files
public enum ScreenshotFormat: String, CaseIterable, Sendable {
  case png = "png"
  case jpg = "jpg"

  var fileExtension: String {
    return self.rawValue
  }

  var mimeType: String {
    switch self {
    case .png:
      return "image/png"
    case .jpg:
      return "image/jpeg"
    }
  }
}

// Wrapper to make JavaScript evaluation results sendable
struct JavaScriptResult: @unchecked Sendable {
  let value: Any?

  init(_ value: Any?) {
    self.value = value
  }
}

/// WebKit service for native web automation.
/// Handles web navigation and automation using WKWebView.
///
/// - Supports dependency injection for testability and flexibility.
/// - Use the default initializer for app use, or inject dependencies for testing/mocking.
@MainActor
@preconcurrency
public final class WebKitService: NSObject, ObservableObject, WebAutomationServiceProtocol,
  WebKitServiceProtocol,
  NSWindowDelegate,
  @unchecked Sendable
{
  // Singleton instance for app-wide use
  public static let shared = WebKitService()
  // Register this service for dependency injection
  static let registered: Void = {
    ServiceRegistry.shared.register(WebKitService.shared, for: WebKitServiceProtocol.self)
    ServiceRegistry.shared.register(
      ErrorHandlingService.shared, for: ErrorHandlingServiceProtocol.self)
    ServiceRegistry.shared.register(LoggingService.shared, for: LoggingServiceProtocol.self)
  }()

  // Published properties for UI binding and automation state
  @Published public var isConnected = false
  @Published public var isRunning = false
  @Published public var currentURL: String?
  @Published public var pageTitle: String?
  /// User-facing error message to be displayed in the UI.
  @Published public var userError: String = ""

  // Callback for window closure (used for cleanup and UI updates)
  public var onWindowClosed: ((ReservationRunType) -> Void)?

  // Logger instance
  let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "WebKitService")

  // WebKit components for browser automation
  public var webView: WKWebView?
  private var navigationDelegate: WebKitNavigationDelegate?
  private var scriptMessageHandler: WebKitScriptMessageHandler?
  private var debugWindow: NSWindow?
  private var instanceId = "default"

  // Anti-detection and human behavior services
  private var antiDetectionService: WebKitAntiDetection?
  private var humanBehaviorService: WebKitHumanBehavior?
  private var debugWindowManager: WebKitDebugWindowManager?

  // Configuration for the current automation run
  public var currentConfig: ReservationConfig? {
    didSet {
      if let config = currentConfig {
        Task { @MainActor in
          updateWindowTitle(with: config)
        }
      }
    }
  }

  // User agent and language for anti-detection
  var userAgent: String =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    + "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
  private var language = "en-US,en"

  // Completion handlers for async navigation and script operations
  var navigationCompletions: [String: @Sendable (Bool) -> Void] = [:]
  private var scriptCompletions: [String: @Sendable (Any?) -> Void] = [:]

  // Screenshot functionality
  private var screenshotDirectory: String?

  // Public getter for screenshot directory
  public var currentScreenshotDirectory: String? {
    return screenshotDirectory
  }

  private var elementCompletions: [String: @Sendable (String?) -> Void] = [:]

  @MainActor private static var liveInstanceCount = 0
  @MainActor static func printLiveInstanceCount() {
    Logger(subsystem: AppConstants.loggingSubsystem, category: "WebKitService")
      .info("📊 Live WebKitService instances: \(liveInstanceCount)")
  }

  /// Main initializer supporting dependency injection for all major dependencies.
  /// - Parameters:
  ///   - logger: Logger instance (default: ODYSSEY WebKitService logger)
  ///   - webView: WKWebView instance (default: nil, will be set up internally)
  ///   - navigationDelegate: WebKitNavigationDelegate (default: nil, will be set up internally)
  ///   - scriptMessageHandler: WebKitScriptMessageHandler (default: nil, will be set up internally)
  ///   - debugWindow: NSWindow for debugging (default: nil)
  ///   - instanceId: Unique instance identifier (default: "default")
  public init(
    logger: Logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "WebKitService"),
    webView: WKWebView? = nil,
    navigationDelegate: WebKitNavigationDelegate? = nil,
    scriptMessageHandler: WebKitScriptMessageHandler? = nil,
    debugWindow: NSWindow? = nil,
    instanceId: String = "default"
  ) {
    self.webView = webView
    self.navigationDelegate = navigationDelegate
    self.scriptMessageHandler = scriptMessageHandler
    self.debugWindow = debugWindow
    self.instanceId = instanceId
    super.init()
    logger.info("🔧 WebKitService initialized (DI mode).")
    Task { @MainActor in
      Self.liveInstanceCount += 1
      logger.info("🔄 WebKitService init. Live instances: \(Self.liveInstanceCount).")
    }

    if webView == nil {
      setupWebView()
    }
  }

  // Keep the default singleton for app use
  override private init() {
    super.init()
    logger.info("🔧 WebKitService initialized.")
    Task { @MainActor in
      Self.liveInstanceCount += 1
      logger.info("🔄 WebKitService init. Live instances: \(Self.liveInstanceCount).")
    }
    setupWebView()
    // Do not show browser window at app launch
  }

  /// Create a new WebKit service instance for parallel operations (e.g., for multiple bookings)
  convenience init(forParallelOperation _: Bool) {
    self.init()
  }

  /// Create a new WebKit service instance with unique anti-detection profile
  convenience init(forParallelOperation _: Bool, instanceId: String) {
    self.init(instanceId: instanceId)
  }

  @MainActor private static func handleDeinitCleanup(logger: Logger) {
    liveInstanceCount -= 1
    logger.info("✅ WebKitService cleanup completed. Live instances: \(liveInstanceCount).")
  }

  deinit {
    logger.info("🧹 WebKitService deinitialized.")
    navigationCompletions.removeAll()
    scriptCompletions.removeAll()
    elementCompletions.removeAll()
    webView = nil
    MainActor.assumeIsolated {
      Self.liveInstanceCount -= 1
      logger.info("✅ WebKitService cleanup completed. Live instances: \(Self.liveInstanceCount).")
    }
  }

  private func setupWebView() {
    logger.info("🔧 Setting up new WebView for instance: \(self.instanceId).")

    // Initialize anti-detection and human behavior services
    antiDetectionService = WebKitAntiDetection(instanceId: instanceId)
    humanBehaviorService = WebKitHumanBehavior(instanceId: instanceId)
    debugWindowManager = WebKitDebugWindowManager()

    let configuration = WKWebViewConfiguration()
    configuration.userContentController = WKUserContentController()

    // Add script message handler
    scriptMessageHandler = WebKitScriptMessageHandler()
    scriptMessageHandler?.delegate = self
    if let scriptMessageHandler {
      configuration.userContentController.add(scriptMessageHandler, name: "odysseyHandler")
    }

    // Enhanced anti-detection measures
    configuration
      .applicationNameForUserAgent =
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"

    // Disable automation detection
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

    // Enable JavaScript using the modern approach
    if #available(macOS 11.0, *) {
      configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    } else {
      configuration.preferences.javaScriptEnabled = true
    }

    // Set realistic viewport and screen properties
    configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

    // Create unique website data store for each instance to avoid tab detection
    let websiteDataStore = WKWebsiteDataStore.nonPersistent()
    configuration.websiteDataStore = websiteDataStore

    // Clear all data for this instance
    let currentInstanceId = self.instanceId
    websiteDataStore.removeData(
      ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
      modifiedSince: Date(timeIntervalSince1970: 0),
    ) { [self] in
      logger.info("🧹 Cleared website data for instance: \(currentInstanceId).")
    }

    // Create web view
    webView = WKWebView(frame: .zero, configuration: configuration)
    logger.info("✅ WebView created successfully for instance: \(self.instanceId).")

    // Generate unique user agent for this instance
    let userAgents = [
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
    ]
    let selectedUserAgent = userAgents.randomElement() ?? userAgents[0]
    webView?.customUserAgent = selectedUserAgent

    // Set navigation delegate
    navigationDelegate = WebKitNavigationDelegate()
    navigationDelegate?.delegate = self
    webView?.navigationDelegate = navigationDelegate

    // Set realistic window size with unique positioning for each instance
    let windowSizes = AppConstants.windowSizes
    let selectedSize = windowSizes.randomElement() ?? windowSizes[0]

    // Generate unique window position based on instance ID
    let hash = abs(instanceId.hashValue)
    let xOffset = (hash % AppConstants.windowOffsetRange) + AppConstants.windowOffsetBase
    let yOffset =
      ((hash / AppConstants.windowOffsetRange) % AppConstants.windowOffsetRange)
      + AppConstants.windowOffsetBase
    webView?.frame = CGRect(
      x: xOffset, y: yOffset, width: selectedSize.width, height: selectedSize.height)

    // Inject custom JavaScript for automation and anti-detection
    injectAutomationScripts()
    injectAntiDetectionScripts()
    logger.info("✅ WebView setup completed successfully for instance: \(self.instanceId).")
  }

  @MainActor
  private func setupDebugWindow() {
    guard let webView, let debugWindowManager else {
      logger.warning("⚠️ Cannot setup debug window: WebView or debug window manager not available.")
      return
    }

    debugWindowManager.showDebugWindow(webView: webView, config: currentConfig)
  }

  @MainActor
  private func updateWindowTitle(with config: ReservationConfig) {
    guard let debugWindowManager else { return }
    debugWindowManager.updateWindowTitle(with: config)
  }

  private func injectAutomationScripts() {
    let automationScript = JavaScriptLibrary.getAutomationLibrary()
    let script = WKUserScript(
      source: automationScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    webView?.configuration.userContentController.addUserScript(script)
    logger.info("✅ Automation scripts injected for instance: \(self.instanceId).")
  }

  private func injectAntiDetectionScripts() {
    guard let webView, let antiDetectionService else {
      logger.warning("⚠️ Cannot inject anti-detection scripts: WebView or service not available.")
      return
    }

    Task {
      await antiDetectionService.injectAntiDetectionScripts(into: webView)
      await antiDetectionService.injectHumanBehaviorScripts(into: webView)
    }
  }

  @MainActor
  private func logAllButtonsAndLinks() async {
    guard GodModeStateManager.shared.isGodModeUIEnabled else { return }
    guard let webView else {
      logger.error("❌ [ButtonScan] webView is nil.")
      return
    }

    do {
      let result = try await webView.evaluateJavaScript("window.odyssey.logAllButtonsAndLinks();")
      if let arr = result as? [String] {
        for line in arr {
          logger.info("🔍 [ButtonScan] \(line, privacy: .public).")
        }
      } else {
        logger.error("❌ [ButtonScan] Unexpected JS result: \(String(describing: result)).")
      }
    } catch {
      logger.error(
        "❌ [ButtonScan] JS error: \(error.localizedDescription, privacy: .public) | \(error)")
    }
  }

  // MARK: - Screenshot Methods

  /**
   Sets the screenshot directory for failure screenshots.
   - Parameter directory: The directory to save screenshots.
   */
  public func setScreenshotDirectory(_ directory: String) {
    screenshotDirectory = directory
    logger.info("📸 Screenshot directory set to: \(directory).")
  }

  /**
   Takes a screenshot of the current web page and saves it to the configured directory.
   - Parameters:
   - filename: Optional filename for the screenshot.
   - quality: JPEG quality from 0.0 (lowest) to 1.0 (highest), default 0.7
   - maxWidth: Maximum width in pixels, maintains aspect ratio if specified
   - format: Image format (.png or .jpg), default .jpg for better compression
   - Returns: The path to the saved screenshot, or nil if failed.
   */
  public func takeScreenshot(
    filename: String? = nil, quality: Float = 0.7, maxWidth: CGFloat? = nil,
    format: ScreenshotFormat = .jpg
  ) async -> String? {
    guard let webView = webView else {
      logger.error("📸 Cannot take screenshot: WebView is nil.")
      return nil
    }

    guard let screenshotDirectory = screenshotDirectory else {
      logger.error("📸 Cannot take screenshot: Screenshot directory not configured.")
      return nil
    }

    logger.info("📸 Starting screenshot capture for WebView: \(webView).")

    do {
      // Create screenshot directory if it doesn't exist
      let fileManager = FileManager.default
      if !fileManager.fileExists(atPath: screenshotDirectory) {
        try fileManager.createDirectory(
          atPath: screenshotDirectory, withIntermediateDirectories: true)
        logger.info("📁 Created screenshot directory: \(screenshotDirectory).")
      }

      // Generate filename if not provided
      let finalFilename =
        filename ?? "screenshot_\(Date().timeIntervalSince1970).\(format.fileExtension)"
      let screenshotPath = "\(screenshotDirectory)/\(finalFilename)"

      logger.info("📸 Taking screenshot with WebView: \(webView).")
      logger.info("📸 Screenshot will be saved to: \(screenshotPath).")
      logger.info(
        "📸 Format: \(format.rawValue.uppercased()), Quality: \(quality), Max Width: \(maxWidth?.description ?? "none")"
      )

      // Take screenshot using WKWebView's takeSnapshot method
      let imageData = try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Data, Error>) in
        // Ensure we're on the main actor for WebKit operations
        Task { @MainActor in
          webView.takeSnapshot(with: nil) { image, error in
            if let error = error {
              continuation.resume(throwing: error)
            } else if let image = image {
              // Use compression utilities for better file size
              guard
                let compressedData = FileManager.compressImage(
                  image, quality: quality, maxWidth: maxWidth)
              else {
                continuation.resume(
                  throwing: NSError(
                    domain: "WebKitService", code: -1,
                    userInfo: [
                      NSLocalizedDescriptionKey: "Failed to compress screenshot"
                    ]))
                return
              }
              continuation.resume(returning: compressedData)
            } else {
              continuation.resume(
                throwing: NSError(
                  domain: "WebKitService", code: -1,
                  userInfo: [NSLocalizedDescriptionKey: "Failed to capture screenshot"]))
            }
          }
        }
      }

      // Write compressed image data to file
      try imageData.write(to: URL(fileURLWithPath: screenshotPath))

      // Log file size information
      let fileSize = FileManager.getFileSizeString(screenshotPath)
      logger.info("📸 Screenshot saved successfully: \(screenshotPath).")
      logger.info("📸 File size: \(fileSize).")
      return screenshotPath

    } catch {
      logger.error("📸 Failed to take screenshot: \(error.localizedDescription).")
      logger.error("📸 Error details: \(error).")

      // Log additional context for debugging
      logger.error("📸 Screenshot directory: \(screenshotDirectory).")

      // Check if directory exists and is writable
      let fileManager = FileManager.default
      if fileManager.fileExists(atPath: screenshotDirectory) {
        logger.info("📁 Screenshot directory exists.")

        // Check if directory is writable
        if fileManager.isWritableFile(atPath: screenshotDirectory) {
          logger.info("📁 Screenshot directory is writable.")
        } else {
          logger.error("📁 Screenshot directory is NOT writable.")
        }
      } else {
        logger.error("📁 Screenshot directory does NOT exist.")
      }

      return nil
    }
  }

  // MARK: - WebDriverServiceProtocol Implementation

  public func connect() async throws {
    // Ensure WebView is properly initialized before connecting
    await MainActor.run {
      // Check if window was manually closed and reset state if needed
      if self.debugWindow == nil, self.isConnected {
        logger.info("👤 Window was manually closed, resetting service state.")
        self.isConnected = false
        self.isRunning = false
        self.navigationCompletions.removeAll()
        self.scriptCompletions.removeAll()
        self.elementCompletions.removeAll()
        self.webView = nil
      }

      if self.webView == nil {
        logger.info("🔧 WebView is nil, setting up new WebView.")
        self.setupWebView()
      }
      self.setupDebugWindow()
    }
    isConnected = true
    isRunning = true
    logger.info("🔗 WebKit service connected.")
  }

  public func disconnect(closeWindow: Bool = true) async {
    logger.info("🔌 Starting WebKit service disconnect. closeWindow=\(closeWindow).")
    // Mark as disconnected first to prevent new operations
    isConnected = false
    isRunning = false
    // Clear all pending completions immediately to prevent callbacks after disconnect
    await MainActor.run {
      self.navigationCompletions.removeAll()
      self.scriptCompletions.removeAll()
      self.elementCompletions.removeAll()
    }
    // Use the new async cleanup function
    await cleanupWebView()

    if closeWindow {
      await MainActor.run {
        if let debugWindowManager = self.debugWindowManager {
          logger.info("🪟 Closing debug window via debugWindowManager.")
          debugWindowManager.hideDebugWindow()
        } else {
          logger.info("🪟 No debugWindowManager to close window.")
        }
      }
    }
    // Failsafe: Force close all NSWindows with our title
    await MainActor.run {
      let allWindows = NSApplication.shared.windows
      for window in allWindows where window.title.contains("ODYSSEY Web Automation") {
        logger.info("🪟 Failsafe: Forcibly closing window with title: \(window.title).")
        window.close()
      }
    }
    // Ensure WebView is properly cleaned up for next run
    await MainActor.run {
      self.webView = nil
      logger.info("🧹 WebView reference cleared for next run.")
    }
    logger.info("✅ WebKit service disconnected successfully.")
  }

  /// Reset the WebKit service for reuse
  public func reset() async {
    logger.info("🔄 Resetting WebKit service.")

    // Disconnect first
    await disconnect(closeWindow: false)

    // Wait a bit for cleanup
    try? await Task.sleep(nanoseconds: AppConstants.mediumDelayNanoseconds)

    // Setup new WebView
    await MainActor.run {
      self.setupWebView()
    }

    logger.info("✅ WebKit service reset completed.")
  }

  /// Force reset the WebKit service (for troubleshooting)
  public func forceReset() async {
    logger.info("🔄 Force resetting WebKit service.")

    // Mark as disconnected
    isConnected = false
    isRunning = false

    // Clear all completions
    await MainActor.run {
      self.navigationCompletions.removeAll()
      self.scriptCompletions.removeAll()
      self.elementCompletions.removeAll()
    }

    // Force cleanup
    await cleanupWebView()

    // Close browser window
    await MainActor.run {
      self.debugWindow?.close()
      self.debugWindow = nil
      self.webView = nil
    }

    // Wait for cleanup
    try? await Task.sleep(nanoseconds: AppConstants.humanDelayNanoseconds)  // 1 second

    // Setup fresh WebView
    await MainActor.run {
      self.setupWebView()
    }

    logger.info("✅ WebKit service force reset completed.")
  }

  /// Check if the service is in a valid state for operations
  public func isServiceValid() -> Bool {
    return isConnected && webView != nil && debugWindow != nil
  }

  /// Get current service state
  public func getServiceState() -> String {
    return """
      Service State:
      - isConnected: \(isConnected)
      - isRunning: \(isRunning)
      - webView exists: \(webView != nil)
      - debugWindow exists: \(debugWindow != nil)
      - navigationCompletions: \(navigationCompletions.count)
      - scriptCompletions: \(scriptCompletions.count)
      - elementCompletions: \(elementCompletions.count)
      """
  }

  public func navigateToURL(_ url: String) async throws {
    // Check if service is in valid state
    await MainActor.run {
      if !self.isConnected || self.webView == nil {
        logger.warning("⚠️ Service not in valid state, attempting to reconnect.")
        self.setupDebugWindow()
      }
    }
    guard webView != nil else {
      logger.error("❌ navigateToURL: WebView not initialized.")
      await MainActor
        .run {
          self.userError = "Web browser is not initialized. Please try again or restart the app."
        }
      throw WebDriverError.navigationFailed("WebView not initialized")
    }
    logger.info("🌐 Navigating to URL: \(url, privacy: .private).")
    return try await withCheckedThrowingContinuation { continuation in
      navigationCompletions[UUID().uuidString] = { success in
        Task { @MainActor in
          if success {
            self.logger.info("✅ Navigation to \(url, privacy: .private) succeeded.")

            // Log document.readyState and page source for diagnosis
            Task { @MainActor in
              do {
                let readyState = try await self.executeScriptInternal(
                  "return document && document.readyState;")?.value
                self.logger.info(
                  "📄 document.readyState after navigation: \(String(describing: readyState))")
                let pageSource = try? await self.getPageSource()
                if let pageSource {
                  self.logger.info(
                    "Page source after navigation (first \(AppConstants.pageSourcePreviewLength) chars): \(pageSource.prefix(AppConstants.pageSourcePreviewLength))"
                  )
                }
              } catch {
                self.logger.warning(
                  "⚠️ Skipping readyState/page source log: \(error.localizedDescription)")
              }
            }
            // After navigation completes, log page source and all buttons/links
            Task { @MainActor in
              await self.logAllButtonsAndLinks()
            }
            continuation.resume()
          } else {
            self.logger.error("❌ Navigation to \(url, privacy: .private) failed.")
            await MainActor
              .run {
                self
                  .userError =
                  "Failed to load the reservation page. Please check your internet connection or try again later."
              }
            continuation.resume(
              throwing: WebDriverError.navigationFailed("Failed to navigate to \(url)"))
          }
        }
      }
      guard let url = URL(string: url) else {
        self.logger.error("❌ navigateToURL: Invalid URL: \(url).")
        Task { @MainActor in
          self.userError = "The reservation URL is invalid. Please check your configuration."
        }
        continuation.resume(throwing: WebDriverError.navigationFailed("Invalid URL: \(url)"))
        return
      }
      let request = URLRequest(url: url)
      webView?.load(request)
    }
  }

  @MainActor
  public func findElement(by selector: String) async throws -> WebElementProtocol {
    guard webView != nil else {
      throw WebDriverError.elementNotFound("WebView not initialized")
    }

    let script = "return document.querySelector('\(selector)');"
    let result = try await executeScriptInternal(script)?.value

    if let elementId = result as? String, !elementId.isEmpty, let webView {
      return WebKitElement(id: elementId, webView: webView, service: self)
    } else {
      throw WebDriverError.elementNotFound("Element not found: \(selector)")
    }
  }

  @MainActor
  public func findElements(by selector: String) async throws -> [WebElementProtocol] {
    guard webView != nil else {
      throw WebDriverError.elementNotFound("WebView not initialized")
    }

    let result = try await executeScriptInternal("window.odyssey.findAllElements('\(selector)');")?
      .value
    let elementIds = result as? [String] ?? []
    guard let webView else {
      throw WebDriverError.elementNotFound("WebView not initialized")
    }
    return elementIds.map { WebKitElement(id: $0, webView: webView, service: self) }
  }

  @MainActor
  public func getPageSource() async throws -> String {
    guard webView != nil else {
      throw WebDriverError.elementNotFound("WebView not initialized")
    }

    let result = try await executeScriptInternal("window.odyssey.getPageSource();")?.value
    return result as? String ?? ""
  }

  public func getCurrentURL() async throws -> String {
    guard webView != nil else {
      throw WebDriverError.elementNotFound("WebView not initialized")
    }

    let result = try await executeScriptInternal("window.odyssey.getCurrentURL();")?.value
    return result as? String ?? ""
  }

  public func getTitle() async throws -> String {
    guard webView != nil else {
      throw WebDriverError.elementNotFound("WebView not initialized")
    }

    let result = try await executeScriptInternal("window.odyssey.getPageTitle();")?.value
    return result as? String ?? ""
  }

  @MainActor
  public func waitForElement(by selector: String, timeout: TimeInterval) async throws
    -> WebElementProtocol
  {
    guard webView != nil else {
      throw WebDriverError.elementNotFound("WebView not initialized")
    }

    _ = try await executeScriptInternal(
      "window.odyssey.waitForElement('\(selector)', \(Int(timeout * 1_000)));")
    return try await findElement(by: selector)
  }

  @MainActor
  public func waitForElementToDisappear(by selector: String, timeout: TimeInterval) async throws {
    guard webView != nil else {
      throw WebDriverError.elementNotFound("WebView not initialized")
    }

    _ =
      try await executeScriptInternal(
        "window.odyssey.waitForElementToDisappear('\(selector)', \(Int(timeout * 1_000)));",
      )
  }

  @MainActor
  public func executeScript(_ script: String) async throws -> String {
    guard webView != nil else {
      throw WebDriverError.scriptExecutionFailed("WebView not initialized")
    }

    let result = try await executeScriptInternal(script)?.value
    return String(describing: result)
  }

  // MARK: - Internal Methods

  func executeScriptInternal(_ script: String) async throws -> JavaScriptResult? {
    guard webView != nil, isConnected else {
      await MainActor.run {
        self.userError = "Web browser is not ready. Please try again or restart the app."
      }
      throw WebDriverError.scriptExecutionFailed("WebView not initialized or disconnected")
    }

    return try await withCheckedThrowingContinuation { continuation in
      let requestId = UUID().uuidString
      scriptCompletions[requestId] = { result in
        continuation.resume(returning: JavaScriptResult(result))
      }

      Task { @MainActor in
        do {
          // Double-check that webView is still valid before executing JavaScript
          guard let currentWebView = self.webView, self.isConnected else {
            await MainActor.run {
              self.userError = "Web browser was disconnected during script execution."
            }
            continuation
              .resume(
                throwing:
                  WebDriverError
                  .scriptExecutionFailed("WebView was disconnected during script execution"),
              )
            return
          }

          // Add a small delay to allow any pending operations to complete
          try? await Task.sleep(nanoseconds: AppConstants.shortDelayNanoseconds)  // 0.1 seconds

          // Check again after the delay
          guard self.isConnected else {
            await MainActor
              .run { self.userError = "Web browser was disconnected during JavaScript execution." }
            continuation
              .resume(
                throwing:
                  WebDriverError
                  .scriptExecutionFailed("WebView was disconnected during JavaScript execution"),
              )
            return
          }

          let result = try await currentWebView.evaluateJavaScript(script)
          // JavaScript evaluation results are safe to pass across actor boundaries
          // The result contains primitive types (String, Number, Boolean, Array, Object) that are sendable
          continuation.resume(returning: JavaScriptResult(result))
        } catch {
          await MainActor
            .run {
              self
                .userError =
                "An error occurred while automating the reservation page. Please try again."
            }
          continuation.resume(
            throwing: WebDriverError.scriptExecutionFailed(error.localizedDescription))
        }
      }
    }
  }

  // MARK: - Reservation-specific Methods

  public func findAndClickElement(_ selector: String) async -> Bool {
    return await findAndClickElement(withText: selector)
  }

  public func fillAllContactFieldsWithAutofillAndHumanMovements(
    phoneNumber: String,
    email: String,
    name: String,
  ) async -> Bool {
    logger.info("👤 Filling contact fields with autofill and human movements.")

    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    do {
      let result =
        try await webView
        .evaluateJavaScript(
          "window.odyssey.fillContactFields('\(phoneNumber)', '\(email)', '\(name)');")
      if let dict = result as? [String: Any],
        let success = dict["success"] as? Bool,
        success
      {
        logger.info("✅ All contact fields filled successfully.")
        return true
      } else {
        logger.error("❌ Failed to fill contact fields.")
        return false
      }
    } catch {
      logger.error("❌ Error filling contact fields: \(error.localizedDescription).")
      return false
    }
  }

  public func typeText(_ text: String, into selector: String) async -> Bool {
    logger.info("⌨️ Typing text '\(text)' into selector: \(selector).")
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    do {
      let result = try await webView.evaluateJavaScript(
        "window.odyssey.typeText('\(selector)', '\(text)');")
      if let found = result as? Bool, found {
        logger.info("✅ Text typed successfully: \(text).")
        return true
      } else {
        logger.error("❌ Failed to type text: \(text).")
        return false
      }
    } catch {
      logger.error("❌ Error typing text: \(error.localizedDescription).")
      return false
    }
  }

  public func findAndClickElement(withText text: String) async -> Bool {
    guard webView != nil, let humanBehaviorService else {
      logger.error("❌ WebView or human behavior service not initialized.")
      return false
    }

    logger.info("🔍 Searching for sport button: '\(text, privacy: .private)'.")

    // Add human-like delay before interaction
    await humanBehaviorService.addHumanDelay()

    do {
      let result = try await executeScriptInternal(
        "window.odyssey.findAndClickElementByText('\(text)');")?.value
      logger.info("🔘 [ButtonClick] JS result: \(String(describing: result), privacy: .public).")
      if let str = result as? String {
        if str == "clicked" || str == "dispatched" {
          // Add human-like delay after successful click
          await humanBehaviorService.addHumanDelay()
          return true
        } else if str.starts(with: "error:") {
          logger.error("❌ [ButtonClick] JS error: \(str, privacy: .public).")
          return false
        } else {
          logger
            .error(
              "Sport button not found: '\(text, privacy: .private)' | JS result: \(str, privacy: .public)",
            )
          return false
        }
      } else {
        logger.error("❌ [ButtonClick] Unexpected JS result: \(String(describing: result)).")
        return false
      }
    } catch {
      logger.error(
        "❌ Error clicking sport button: \(error.localizedDescription, privacy: .public) | \(error)")
      return false
    }
  }

  /// Waits for DOM ready or for a key button/element to appear
  /// Now also checks for the presence of a button with the configured sport name
  public func waitForDOMReady() async -> Bool {
    guard webView != nil else {
      logger.error("❌ waitForDOMReady: WebView not initialized.")
      return false
    }
    let configSport = currentConfig?.sportName ?? ""
    let script = "window.odyssey.checkDOMReadyWithButton('\(configSport)');"

    do {
      logger.info("🔧 Executing enhanced DOM ready/button check script...")
      let result = try await executeScriptInternal(script)?.value
      logger.info("📊 DOM/button check result: \(String(describing: result)).")
      if let dict = result as? [String: Any] {
        let readyState = dict["readyState"] as? String ?? ""
        let buttonFound = dict["buttonFound"] as? Bool ?? false
        logger.info("📄 document.readyState=\(readyState), buttonFound=\(buttonFound).")
        if readyState == "complete" || buttonFound {
          logger.info("✅ DOM ready or button found, proceeding.")
          return true
        } else {
          logger.error("❌ DOM not ready and button not found.")
          return false
        }
      } else {
        logger.error("❌ Unexpected result from DOM/button check: \(String(describing: result)).")
        return false
      }
    } catch {
      logger.error("❌ Error waiting for DOM ready/button: \(error.localizedDescription).")
      return false
    }
  }

  public func fillNumberOfPeople(_ numberOfPeople: Int) async -> Bool {
    guard webView != nil else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    do {
      let result = try await executeScriptInternal(
        "window.odyssey.fillNumberOfPeople(\(numberOfPeople));")?.value

      if let success = result as? Bool, success {
        return true
      } else {
        logger.error("❌ Field not found or not filled: \(String(describing: result)).")
        return false
      }
    } catch {
      logger.error("❌ Error filling number of people: \(error.localizedDescription).")
      return false
    }
  }

  public func clickConfirmButton() async -> Bool {
    guard webView != nil else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    logger.info("🔘 [ConfirmClick] Executing centralized confirm button click.")
    do {
      let result = try await executeScriptInternal("window.odyssey.clickConfirmButton();")
      logger.info("🔘 [ConfirmClick] JS result: \(String(describing: result), privacy: .public).")
      if let str = result?.value as? String, str == "clicked" {
        // Wait a moment for the page to settle
        try? await Task.sleep(nanoseconds: AppConstants.humanDelayNanoseconds)  // 1 second

        // Also check for any error messages or loading states
        let checkResult = try await executeScriptInternal("window.odyssey.checkPageState();")
        logger.info(
          "📊 [ConfirmClick] Page check: \(String(describing: checkResult), privacy: .public)")

        return true
      } else {
        logger.error(
          "❌ [ConfirmClick] Button not found or not clicked: \(String(describing: result))")
        return false
      }
    } catch {
      logger.error("❌ Error clicking confirm button: \(error.localizedDescription).")
      return false
    }
  }

  // MARK: - Additional Reservation Methods

  public func waitForGroupSizePage() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    let timeout: TimeInterval = AppConstants.shortTimeout
    let pollInterval: TimeInterval = AppConstants.checkIntervalShort
    let start = Date()
    var pollCount = 0
    while Date().timeIntervalSince(start) < timeout {
      pollCount += 1
      let script = "window.odyssey.checkGroupSizePage();"
      do {
        let result = try await webView.evaluateJavaScript(script)
        if let found = result as? Bool, found {
          logger.info("📊 Group size input found on poll #\(pollCount).")
          return true
        }
      } catch {
        logger.error(
          "❌ [GroupSizePoll][poll \(pollCount)] JS error: \(error.localizedDescription).")
      }
      try? await Task.sleep(
        nanoseconds: UInt64(pollInterval * Double(AppConstants.humanDelayNanoseconds)))
    }
    logger.error("❌ Group size page load timeout after \(Int(timeout))s and \(pollCount) polls.")
    return false
  }

  public func waitForTimeSelectionPage() async -> Bool {
    guard webView != nil else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    logger.info("⏳ [TimeSelection] Starting time selection page detection...")

    let script = "window.odyssey.checkTimeSelectionPage();"

    do {
      let result = try await executeScriptInternal(script)?.value as? Bool ?? false

      logger.info("📊 [TimeSelection] JavaScript result: \(result).")

      if result {
        logger.info("✅ Time selection page loaded successfully.")
      } else {
        logger.error("❌ Time selection page not detected.")
      }
      return result
    } catch {
      logger.error("❌ Error checking time selection page: \(error.localizedDescription).")
      return false
    }
  }

  public func selectTimeSlot(dayName: String, timeString: String) async -> Bool {
    guard webView != nil else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    logger.info(
      "📅 Selecting time slot: \(dayName, privacy: .private) at \(timeString, privacy: .private)")

    // First expand the day section
    let dayExpanded = await expandDaySection(dayName: dayName)
    if !dayExpanded {
      logger.error("❌ Failed to expand day section: \(dayName, privacy: .private).")
      return false
    }

    // Wait a moment for the day section to fully expand
    try? await Task.sleep(nanoseconds: AppConstants.mediumDelayNanoseconds)  // 0.5 seconds

    // Then click the time button
    let timeClicked = await clickTimeButton(timeString: timeString, dayName: dayName)
    if !timeClicked {
      logger.error("❌ Failed to click time button: \(timeString, privacy: .private).")
      return false
    }

    logger.info("✅ Time slot selection completed successfully.")
    return true
  }

  public func expandDaySection(dayName: String) async -> Bool {
    guard let webView else {
      logger.error("❌ [DaySection] WebView not initialized.")
      return false
    }

    logger.info("📅 [DaySection] Expanding day section for: \(dayName, privacy: .private).")

    // First check if the JavaScript library is available
    let checkScript =
      "typeof window.odyssey !== 'undefined' && typeof window.odyssey.expandDaySection === 'function'"
    do {
      let isAvailable = try await webView.evaluateJavaScript(checkScript) as? Bool ?? false
      if !isAvailable {
        logger.error("❌ [DaySection] JavaScript library not available, injecting scripts...")
        // Re-inject scripts if not available
        injectAutomationScripts()
        injectAntiDetectionScripts()
        // Wait a moment for scripts to load
        try await Task.sleep(nanoseconds: AppConstants.mediumDelayNanoseconds)  // 0.5 seconds
      }
    } catch {
      logger.error(
        "❌ [DaySection] Error checking JavaScript availability: \(error.localizedDescription)")
    }

    let script = "window.odyssey.expandDaySection('\(dayName)');"

    do {
      logger.info("📅 [DaySection] Executing JavaScript script...")
      let result = try await webView.evaluateJavaScript(script)
      logger.info("📊 [DaySection] JS result: \(String(describing: result), privacy: .private).")

      if let success = result as? Bool, success {
        logger.info("✅ [DaySection] Day section expanded successfully.")
        return true
      } else {
        logger.error("❌ [DaySection] Failed to expand day section.")
        return false
      }
    } catch {
      logger.error("❌ [DaySection] JS error: \(error.localizedDescription, privacy: .private).")
      return false
    }
  }

  public func clickTimeButton(timeString: String, dayName: String) async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    logger.info(
      "⏰ Clicking time button: \(timeString, privacy: .private) for day: \(dayName, privacy: .private)"
    )

    // First check if the JavaScript library is available
    let checkScript =
      "typeof window.odyssey !== 'undefined' && typeof window.odyssey.clickTimeButton === 'function'"
    do {
      let isAvailable = try await webView.evaluateJavaScript(checkScript) as? Bool ?? false
      if !isAvailable {
        logger.error("❌ [TimeButton] JavaScript library not available, injecting scripts...")
        // Re-inject scripts if not available
        injectAutomationScripts()
        injectAntiDetectionScripts()
        // Wait a moment for scripts to load
        try await Task.sleep(nanoseconds: AppConstants.mediumDelayNanoseconds)  // 0.5 seconds
      }
    } catch {
      logger.error(
        "❌ [TimeButton] Error checking JavaScript availability: \(error.localizedDescription)")
    }

    let script = "window.odyssey.clickTimeButton('\(timeString)', '\(dayName)');"

    do {
      let result = try await webView.evaluateJavaScript(script)
      logger.info("📊 [TimeButton] JS result: \(String(describing: result), privacy: .private).")

      if let success = result as? Bool, success {
        logger.info("✅ [TimeButton] Time button clicked successfully.")
        return true
      } else {
        logger.error("❌ [TimeButton] Failed to click time button.")
        return false
      }
    } catch {
      logger.error("❌ [TimeButton] JS error: \(error.localizedDescription, privacy: .private).")
      return false
    }
  }

  public func verifyJavaScriptLibrary() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized for JavaScript verification.")
      return false
    }

    let checkScript =
      "typeof window.odyssey !== 'undefined' && typeof window.odyssey.expandDaySection === 'function' && typeof window.odyssey.clickTimeButton === 'function'"
    do {
      let isAvailable = try await webView.evaluateJavaScript(checkScript) as? Bool ?? false
      logger.info(
        "🔧 JavaScript library verification: \(isAvailable ? "✅ Available" : "❌ Not available")")
      return isAvailable
    } catch {
      logger.error("❌ Error verifying JavaScript library: \(error.localizedDescription).")
      return false
    }
  }

  public func reinjectScripts() {
    logger.info("🔄 Re-injecting scripts for instance: \(self.instanceId).")
    injectAutomationScripts()
    injectAntiDetectionScripts()
  }

  public func checkAndClickContinueButton() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    // Add human-like delay before checking
    await addRandomDelay()

    let script = "window.odyssey.checkAndClickContinueButton();"
    do {
      let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
      return result
    } catch {
      logger
        .error(
          "❌ [ContinueButton] Error checking for continue button: \(error.localizedDescription, privacy: .public)",
        )
      logger.error("❌ [ContinueButton] Continue button error details: \(error, privacy: .public).")
      return false
    }
  }

  public func waitForContactInfoPage() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    let timeout: TimeInterval = AppConstants.shortTimeout
    let pollInterval: TimeInterval = AppConstants.checkIntervalShort
    let start = Date()
    var pollCount = 0

    while Date().timeIntervalSince(start) < timeout {
      pollCount += 1
      let script = "window.odyssey.checkContactInfoPage();"
      do {
        let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
        if result {
          logger.info("✅ Contact info page loaded successfully on poll #\(pollCount).")

          // Activate enhanced antidetection measures immediately when contact page is detected
          logger.info("🛡️ Activating enhanced antidetection measures for contact form page...")
          await enhanceHumanLikeBehavior()
          return true
        }
      } catch {
        logger.error(
          "❌ [ContactPagePoll][poll \(pollCount)] JS error: \(error.localizedDescription).")
      }
      try? await Task.sleep(
        nanoseconds: UInt64(pollInterval * Double(AppConstants.humanDelayNanoseconds)))
    }

    logger.error("❌ Contact info page load timeout after \(Int(timeout))s and \(pollCount) polls.")
    return false
  }

  public func fillPhoneNumber(_ phoneNumber: String) async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    // Optimized delay before starting to avoid reCAPTCHA (0.5-0.9 seconds)
    try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...900_000_000))

    // Essential human-like behavior simulation
    await addQuickPause()

    let script = "window.odyssey.fillFormField('phone', '\(phoneNumber)');"

    do {
      let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
      if result {
        logger.info("✅ Successfully filled phone number with enhanced human-like behavior.")
        // Optimized delay after filling to avoid reCAPTCHA (0.4-0.7 second)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 400_000_000...700_000_000))
        return true
      } else {
        logger.error("❌ Failed to fill phone number - field not found.")
        return false
      }
    } catch {
      logger.error("❌ Error filling phone number: \(error.localizedDescription).")
      return false
    }
  }

  public func fillEmail(_ email: String) async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    // Optimized delay before starting to avoid reCAPTCHA (0.5-0.9 seconds)
    try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...900_000_000))

    // Essential human-like behavior simulation
    await addQuickPause()

    let script = "window.odyssey.fillFormField('email', '\(email)');"

    do {
      let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
      if result {
        logger.info("✅ Successfully filled email with enhanced human-like behavior.")
        // Optimized delay after filling to avoid reCAPTCHA (0.4-0.7 second)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 400_000_000...700_000_000))
        return true
      } else {
        logger.error("❌ Failed to fill email - field not found.")
        return false
      }
    } catch {
      logger.error("❌ Error filling email: \(error.localizedDescription).")
      return false
    }
  }

  public func fillName(_ name: String) async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    // Check if we're still connected before proceeding
    guard isConnected else {
      logger.error("❌ WebKit service is not connected.")
      return false
    }

    // Optimized delay before starting to avoid reCAPTCHA (0.5-0.9 seconds)
    try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...900_000_000))

    // Essential human-like behavior simulation
    await addQuickPause()

    let script = "window.odyssey.fillFormField('name', '\(name)');"

    do {
      // Double-check that we are still connected before executing JavaScript
      guard isConnected else {
        logger.error("❌ WebKit service is not connected before JavaScript execution.")
        return false
      }

      let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
      if result {
        logger.info("✅ Successfully filled name with enhanced human-like behavior.")
        // Optimized delay after filling to avoid reCAPTCHA (0.4-0.7 second)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 400_000_000...700_000_000))
        return true
      } else {
        logger.error("❌ Failed to fill name - field not found.")
        return false
      }
    } catch {
      logger.error("❌ Error filling name: \(error.localizedDescription).")
      return false
    }
  }

  public func clickContactInfoConfirmButtonWithRetry() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    // Essential anti-detection before clicking
    logger.info("🛡️ Applying essential anti-detection before confirm button click.")
    await addQuickPause()

    // Add human-like delay before clicking (1-1.5 seconds)
    try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...1_500_000_000))

    let script = "window.odyssey.clickContactInfoConfirmButton();"

    do {
      let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
      if result {
        logger.info("✅ Successfully clicked contact info confirm button with human-like behavior.")
        return true
      } else {
        logger.error("❌ Failed to click contact info confirm button.")
        return false
      }
    } catch {
      logger.error("❌ Error clicking contact info confirm button: \(error.localizedDescription).")
      return false
    }
  }

  public func isEmailVerificationRequired() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    // Wait a bit for the page to load after clicking confirm
    try? await Task.sleep(nanoseconds: AppConstants.extraLongDelayNanoseconds)  // Wait 3 seconds

    let script = "window.odyssey.isEmailVerificationRequired();"

    do {
      let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
      if result {
        logger.info("📧 Email verification required.")
      } else {
        logger.info("🛡️ No email verification required.")
      }
      return result
    } catch {
      logger.error("❌ Error checking email verification: \(error.localizedDescription).")
      return false
    }
  }

  public func handleEmailVerification(verificationStart: Date) async -> Bool {
    guard webView != nil else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    logger.info("🛡️ Instance \(self.instanceId): Handling email verification...")

    // Step 1: Wait for verification page to load
    await updateTask("Waiting for verification page...")
    let verificationPageReady = await waitForVerificationPage()
    if !verificationPageReady {
      logger.error("❌ Instance \(self.instanceId): Verification page failed to load.")
      return false
    }

    // Step 2: Try verification codes with retry mechanism
    await updateTask("Trying verification codes with retry...")
    let verificationSuccess = await tryVerificationCodesWithRetry(
      verificationStart: verificationStart)
    if !verificationSuccess {
      logger.error("❌ Instance \(self.instanceId): All verification attempts failed.")
      return false
    }

    logger.info("✅ Instance \(self.instanceId): Email verification completed successfully.")
    return true
  }

  /// Waits for the verification page to load
  private func waitForVerificationPage() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    let timeout: TimeInterval = AppConstants.mediumTimeout  // 60 seconds
    let pollInterval: TimeInterval = AppConstants.pollInterval
    let start = Date()

    logger.info("⏳ Waiting for verification page to load (timeout: \(timeout)s).")

    while Date().timeIntervalSince(start) < timeout {
      let script = "window.odyssey.checkVerificationPage();"

      do {
        let result = try await webView.evaluateJavaScript(script)
        if let dict = result as? [String: Any] {
          let hasInput = dict["hasInput"] as? Bool ?? false
          let hasText = dict["hasText"] as? Bool ?? false
          let hasPattern = dict["hasPattern"] as? Bool ?? false
          let isLoading = dict["isLoading"] as? Bool ?? false
          let bodyTextPreview = dict["bodyTextPreview"] as? String ?? ""

          logger
            .info(
              "Verification page check - Input: \(hasInput), Text: \(hasText), Pattern: \(hasPattern), Loading: \(isLoading)",
            )
          logger.info("📄 Page content preview: \(bodyTextPreview).")

          if hasInput || hasText || hasPattern {
            logger.info("✅ Verification page detected successfully.")
            return true
          }

          if isLoading {
            logger.info("⏳ Page is still loading, waiting...")
          }
        }
      } catch {
        logger.error("❌ Error checking verification page: \(error.localizedDescription).")
      }

      try? await Task.sleep(
        nanoseconds: UInt64(pollInterval * Double(AppConstants.humanDelayNanoseconds)))
    }

    logger.error("❌ Verification page load timeout after \(timeout) seconds.")
    return false
  }

  /// Fetches verification code from email using IMAP
  private func fetchVerificationCodeFromEmail(verificationStart: Date) async -> String {
    logger.info("📧 Fetching verification code from email...")

    // Initial wait before checking for the email
    let initialWait: TimeInterval = AppConstants.initialWait  // 10 seconds
    let maxTotalWait: TimeInterval = AppConstants.maxTotalWait  // 5 minutes
    let retryDelay: TimeInterval = AppConstants.retryDelay  // 2 seconds
    let deadline = Date().addingTimeInterval(maxTotalWait)
    let emailService = EmailService.shared

    // Wait for the initial period
    logger.info("⏳ Waiting \(initialWait)s before starting email verification checks...")
    try? await Task.sleep(
      nanoseconds: UInt64(initialWait * Double(AppConstants.humanDelayNanoseconds)))

    while Date() < deadline {
      // Fetch verification codes using the correct method
      let codes = await emailService.fetchVerificationCodesForToday(since: verificationStart)
      if let code = codes.first {
        logger.info("✅ Found verification email, parsed code: \(code).")
        return code
      }
      logger.info("⏳ Verification code not found yet, retrying in \(retryDelay)s...")
      try? await Task.sleep(
        nanoseconds: UInt64(retryDelay * Double(AppConstants.humanDelayNanoseconds)))
    }
    logger.error("❌ Timed out waiting for verification code after \(maxTotalWait)s.")
    return ""
  }

  /// Parses 4-digit verification code from email body
  private func parseVerificationCode(from emailBody: String) -> String {
    // Extract verification code from email body using regex patterns
    let pattern = #"Your verification code is:\s*(\d{4})\s*\."#

    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
      let range = NSRange(location: 0, length: emailBody.utf16.count)
      if let match = regex.firstMatch(in: emailBody, options: [], range: range) {
        let codeRange = match.range(at: 1)
        if let range = Range(codeRange, in: emailBody) {
          let code = String(emailBody[range])
          logger.info("🔍 Parsed verification code: \(code, privacy: .private).")
          return code
        }
      }
    }

    // Fallback: look for any 4-digit number
    let fallbackPattern = #"\b(\d{4})\b"#
    if let regex = try? NSRegularExpression(pattern: fallbackPattern, options: []) {
      let range = NSRange(location: 0, length: emailBody.utf16.count)
      if let match = regex.firstMatch(in: emailBody, options: [], range: range) {
        let codeRange = match.range(at: 1)
        if let range = Range(codeRange, in: emailBody) {
          let code = String(emailBody[range])
          logger.info("🔍 Parsed verification code (fallback): \(code, privacy: .private).")
          return code
        }
      }
    }

    logger.error("❌ Could not parse verification code from email body.")
    return ""
  }

  /// Fetches all verification codes from email using IMAP
  private func fetchAllVerificationCodesFromEmail(verificationStart: Date) async -> [String] {
    logger.info("📧 Fetching all verification codes from email for instance: \(self.instanceId).")

    // Initial wait before checking for the email
    let initialWait: TimeInterval = AppConstants.initialWait  // 10 seconds
    let maxTotalWait: TimeInterval = AppConstants.maxTotalWait  // 5 minutes
    let retryDelay: TimeInterval = AppConstants.retryDelay  // 2 seconds
    let deadline = Date().addingTimeInterval(maxTotalWait)

    // Use shared email service but with instance-specific logging and timing
    let emailService = EmailService.shared
    logger.info("📧 Using EmailService for WebKit instance: \(self.instanceId).")

    // Wait for the initial period
    logger
      .info(
        "Waiting \(initialWait)s before starting email verification checks for instance: \(self.instanceId)...",
      )
    try? await Task.sleep(
      nanoseconds: UInt64(initialWait * Double(AppConstants.humanDelayNanoseconds)))

    while Date() < deadline {
      // Try both shared code pool and direct email fetching as fallback
      var codes: [String] = []

      // First try shared code pool
      codes = await emailService.fetchAndConsumeVerificationCodes(
        since: verificationStart,
        instanceId: self.instanceId,
      )

      if codes.isEmpty {
        logger.info(
          "📧 Instance \(self.instanceId): Shared code pool empty, trying direct email fetch...")
        codes = await emailService.fetchVerificationCodesForToday(since: verificationStart)

        if !codes.isEmpty {
          logger.info(
            "📧 Instance \(self.instanceId): Direct email fetch found \(codes.count) codes")
        }
      }

      if codes.isEmpty {
        logger.info(
          "📧 Instance \(self.instanceId): Still no codes, trying with broader time window...")
        let broaderStart = verificationStart.addingTimeInterval(
          -AppConstants.emailSearchWindowMinutes * 60)  // 5 minutes earlier
        codes = await emailService.fetchVerificationCodesForToday(since: broaderStart)

        if !codes.isEmpty {
          logger.info("📧 Instance \(self.instanceId): Broader search found \(codes.count) codes.")
        }
      }

      if !codes.isEmpty {
        logger
          .info(
            "Instance \(self.instanceId): Found \(codes.count) verification codes: \(codes.map { String(repeating: "*", count: $0.count) })",
          )
        return codes
      }
      logger
        .info(
          "Instance \(self.instanceId): No verification codes available yet, retrying in \(retryDelay)s..."
        )
      try? await Task.sleep(
        nanoseconds: UInt64(retryDelay * Double(AppConstants.humanDelayNanoseconds)))
    }
    logger.error(
      "❌ Instance \(self.instanceId): Timed out waiting for verification codes after \(maxTotalWait)s"
    )
    return []
  }

  /// Tries verification codes systematically until one works or all fail
  private func tryVerificationCodes(_ codes: [String]) async -> Bool {
    logger
      .info(
        "Instance \(self.instanceId): Starting systematic verification code trial with \(codes.count) codes: \(codes)",
      )

    let emailService = EmailService.shared
    for (index, code) in codes.enumerated() {
      // Validate code: must be 4 digits and not suspicious
      if code.count != 4 || !code.allSatisfy(\.isNumber)
        || AppConstants.suspiciousVerificationCodes.contains(code)
      {
        logger.warning("⚠️ Instance \(self.instanceId): Skipping invalid code: \(code).")

        continue
      }
      if !codes.contains(code) {
        logger
          .warning(
            "Instance \(self.instanceId): Code \(code) not in extracted set for this round, skipping."
          )

        continue
      }
      logger
        .info(
          "Instance \(self.instanceId): Trying verification code \(index + 1)/\(codes.count): \(String(repeating: "*", count: code.count))",
        )
      await updateTask("Trying verification code \(index + 1)/\(codes.count)...")
      let fillSuccess = await fillVerificationCode(code)
      if !fillSuccess {
        logger.warning(
          "⚠️ Instance \(self.instanceId): Failed to fill verification code \(index + 1).")

        continue
      }
      await updateTask("Waiting for form to process verification code...")
      try? await Task.sleep(nanoseconds: AppConstants.longDelayNanoseconds)
      logger.info(
        "Instance \(self.instanceId): Finished waiting for form to process verification code")
      let clickSuccess = await clickVerificationSubmitButton()
      if !clickSuccess {
        logger
          .warning(
            "Instance \(self.instanceId): Failed to click verification submit button for code \(index + 1)",
          )

        continue
      }
      await updateTask("Waiting for verification response...")
      try? await Task.sleep(nanoseconds: AppConstants.veryLongDelayNanoseconds)
      logger.info("⏳ Instance \(self.instanceId): Finished waiting for verification response.")
      logger.info(
        "🔍 Instance \(self.instanceId): Checking verification result for code \(index + 1)...")
      let verificationSuccess = await checkVerificationSuccess()
      if verificationSuccess {
        logger
          .info(
            "✅ Instance \(self.instanceId): ✅ Verification code \(index + 1) was accepted or terminal state reached!",
          )
        await emailService.markCodeAsConsumed(code, byInstanceId: self.instanceId)
        logger
          .info(
            "Instance \(self.instanceId): ✅ Verification successful or terminal state on attempt \(index + 1)",
          )

        return true  // TERMINATE IMMEDIATELY ON SUCCESS OR TERMINAL STATE
      }
      logger.warning(
        "⚠️ Instance \(self.instanceId): ❌ Verification code \(index + 1) was rejected.")
      let stillOnVerificationPage = await checkIfStillOnVerificationPage()
      if stillOnVerificationPage {
        logger.info(
          "Instance \(self.instanceId): Still on verification page - continuing to next code...")
        await clearVerificationInput()
        continue
      } else {
        logger
          .info(
            "Instance \(self.instanceId): Moved away from verification page - checking if it's success or error...",
          )
        // If we moved away from verification page, check if it's actually success
        // Don't assume it's success just because the page moved
        let verificationSuccess = await checkVerificationSuccess()
        if verificationSuccess {
          logger
            .info(
              "Instance \(self.instanceId): ✅ Verification successful after page redirect!",
            )
          await emailService.markCodeAsConsumed(code, byInstanceId: self.instanceId)
          return true
        } else {
          logger
            .info(
              "Instance \(self.instanceId): ❌ Verification failed after page redirect - continuing to next code...",
            )
          continue
        }
      }
    }

    logger
      .error(
        "Instance \(self.instanceId): All \(codes.count) verification codes failed or were rejected. Failing gracefully.",
      )

    return false
  }

  /// Tries verification codes with retry mechanism that fetches new codes if initial ones fail
  private func tryVerificationCodesWithRetry(verificationStart: Date) async -> Bool {
    logger.info("🔄 Instance \(self.instanceId): Starting verification with retry mechanism.")
    let maxRetryAttempts = 3
    var retryCount = 0
    while retryCount < maxRetryAttempts {
      logger.info(
        "Instance \(self.instanceId): Retry attempt \(retryCount + 1)/\(maxRetryAttempts)")
      await updateTask(
        "Fetching verification codes (attempt \(retryCount + 1)/\(maxRetryAttempts))...")
      let verificationCodes = await fetchAllVerificationCodesFromEmail(
        verificationStart: verificationStart)
      logger.info(
        "📧 Instance \(self.instanceId): Codes fetched for this round: \(verificationCodes).")
      if verificationCodes.isEmpty {
        logger.warning(
          "Instance \(self.instanceId): No verification codes found in attempt \(retryCount + 1)")
        retryCount += 1
        if retryCount < maxRetryAttempts {
          logger.info("⏳ Instance \(self.instanceId): Waiting 3 seconds before retry...")
          try? await Task.sleep(nanoseconds: AppConstants.extraLongDelayNanoseconds)
        }
        continue
      }
      logger
        .info(
          "Instance \(self.instanceId): Retrieved \(verificationCodes.count) verification codes for attempt \(retryCount + 1)",
        )
      await updateTask(
        "Trying verification codes (attempt \(retryCount + 1)/\(maxRetryAttempts))...")
      let verificationSuccess = await tryVerificationCodes(verificationCodes)
      if verificationSuccess {
        logger.info(
          "Instance \(self.instanceId): ✅ Verification successful on attempt \(retryCount + 1)")
        return true
      } else {
        logger.warning(
          "Instance \(self.instanceId): ❌ Verification failed on attempt \(retryCount + 1)")
        let stillOnVerificationPage = await checkIfStillOnVerificationPage()
        if !stillOnVerificationPage {
          logger
            .warning(
              "Instance \(self.instanceId): No longer on verification page after failed attempt, aborting all further retries.",
            )
          return false
        }
        retryCount += 1
        if retryCount < maxRetryAttempts {
          logger.info("⏳ Instance \(self.instanceId): Waiting 3 seconds before next retry...")
          try? await Task.sleep(nanoseconds: AppConstants.extraLongDelayNanoseconds)
        }
      }
    }
    // Final fallback: try direct fetch from email ignoring code pool
    logger.error(
      "Instance \(self.instanceId): All retry attempts failed. Trying final direct fetch from email."
    )
    let directCodes = await EmailService.shared.fetchVerificationCodesForToday(
      since: verificationStart)
    logger.info(
      "📧 Instance \(self.instanceId): Codes fetched for final direct fetch: \(directCodes).")
    if !directCodes.isEmpty {
      logger
        .info(
          "Instance \(self.instanceId): Final direct fetch found \(directCodes.count) codes. Trying them."
        )
      let verificationSuccess = await tryVerificationCodes(directCodes)
      if verificationSuccess {
        logger.info("✅ Instance \(self.instanceId): Verification successful on final direct fetch.")
        return true
      }
      // After final direct fetch, check if still on verification page
      let stillOnVerificationPage = await checkIfStillOnVerificationPage()
      if !stillOnVerificationPage {
        logger
          .warning(
            "Instance \(self.instanceId): No longer on verification page after final direct fetch, aborting all further retries.",
          )
        return false
      }
    }
    logger
      .error(
        "Instance \(self.instanceId): All verification attempts failed or all codes consumed. Failing gracefully.",
      )
    return false
  }

  /// Checks if the verification was successful by looking for success indicators
  private func checkVerificationSuccess() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    let script = "window.odyssey.checkVerificationSuccess();"

    do {
      let result = try await webView.evaluateJavaScript(script)
      if let dict = result as? [String: Any] {
        let success = dict["success"] as? Bool ?? false
        let reason = dict["reason"] as? String ?? "unknown"
        _ = dict["pageText"] as? String ?? ""

        logger
          .info(
            "Instance \(self.instanceId): Verification check result: \(success ? "SUCCESS" : "FAILED") - \(reason)",
          )

        if success {
          logger.info("🎉 Instance \(self.instanceId): SUCCESS detected - reason: \(reason).")
        } else {
          logger.info("❌ Instance \(self.instanceId): FAILURE detected - reason: \(reason).")
        }
        return success
      } else {
        logger
          .error(
            "Instance \(self.instanceId): Could not parse verification result: \(String(describing: result))",
          )
      }
    } catch {
      logger
        .error(
          "Instance \(self.instanceId): Error checking verification success: \(error.localizedDescription)",
        )
    }

    logger.error(
      "❌ Instance \(self.instanceId): Defaulting to FAILURE due to error or parsing issue.")
    return false
  }

  /// Checks if we're still on the verification page
  private func checkIfStillOnVerificationPage() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    let script = "window.odyssey.checkIfStillOnVerificationPage();"

    do {
      let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
      logger.info("📄 Instance \(self.instanceId): Still on verification page: \(result).")
      return result
    } catch {
      logger
        .error(
          "Instance \(self.instanceId): Error checking if still on verification page: \(error.localizedDescription)",
        )
      return false
    }
  }

  /// Clears the verification input field for the next attempt
  private func clearVerificationInput() async {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return
    }

    let script = "window.odyssey.clearVerificationInput();"

    do {
      _ = try await webView.evaluateJavaScript(script)
      logger.info("🧹 Instance \(self.instanceId): Cleared verification input field.")
    } catch {
      logger
        .error(
          "Instance \(self.instanceId): Error clearing verification input: \(error.localizedDescription)"
        )
    }
  }

  /// Fills verification code into the input field using browser autofill behavior
  private func fillVerificationCode(_ code: String) async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    let script = "window.odyssey.fillVerificationCode('\(code)');"

    do {
      let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
      if result {
        logger.info(
          "Instance \(self.instanceId): Successfully filled verification code with autofill behavior"
        )
        // Minimal delay after autofill
        try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...300_000_000))
        return true
      } else {
        logger.error(
          "❌ Instance \(self.instanceId): Failed to fill verification code with autofill.")
        return false
      }
    } catch {
      logger
        .error(
          "Instance \(self.instanceId): Error filling verification code with autofill: \(error.localizedDescription)",
        )
      return false
    }
  }

  /// Updates the current task for logging purposes
  private func updateTask(_ task: String) async {
    logger.info("📋 Task: \(task).")
  }

  /// Clicks the submit button for verification
  private func clickVerificationSubmitButton() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }
    let maxAttempts = 10
    for attempt in 1...maxAttempts {
      do {
        let script = "window.odyssey.clickVerificationSubmitButton();"

        let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
        if result {
          logger.info(
            "✅ [ConfirmClick] Success on attempt \(attempt): Button clicked successfully.")
          return true
        } else {
          logger.info("🔄 [ConfirmClick] Attempt \(attempt) did not find/click button.")
        }
      } catch {
        logger
          .error(
            "Error in clickVerificationSubmitButton (attempt \(attempt)): \(error.localizedDescription)"
          )
      }

      try? await Task.sleep(nanoseconds: AppConstants.mediumDelayNanoseconds)
    }
    logger.error(
      "❌ [ConfirmClick] Failed to click Final Confirmation button after \(maxAttempts) attempts")
    return false
  }

  /// Detects if "Retry" text appears on the page (indicating reCAPTCHA failure)
  public func detectRetryText() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    let script = "window.odyssey.detectRetryText();"

    do {
      let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
      if result {
        logger.warning("⚠️ Retry text detected - reCAPTCHA likely failed.")
      }
      return result
    } catch {
      logger.error("❌ Error detecting retry text: \(error.localizedDescription).")
      return false
    }
  }

  /// Handle captcha retry with human behavior simulation
  public func handleCaptchaRetry() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    logger.info("🛡️ Handling captcha retry with human behavior simulation...")

    let script = "window.odyssey.handleCaptchaRetry();"

    do {
      let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
      if result {
        logger.info("✅ Captcha retry initiated with human behavior.")
      } else {
        logger.error("❌ Failed to handle captcha retry.")
      }
      return result
    } catch {
      logger.error("❌ Error handling captcha retry: \(error.localizedDescription).")
      return false
    }
  }

  /// Enhances human-like behavior to avoid reCAPTCHA detection
  public func enhanceHumanLikeBehavior() async {
    guard let webView else { return }

    logger.info("🛡️ Enhancing human-like behavior to avoid reCAPTCHA detection...")

    // First, clean up session to prevent multiple tab detection
    let cleanupScript = "window.odyssey.cleanupSession();"
    do {
      _ = try await webView.evaluateJavaScript(cleanupScript)
      logger.info("🧹 Session cleanup completed.")
    } catch {
      logger.error("❌ Failed to cleanup session: \(error.localizedDescription).")
    }

    // Apply basic anti-detection measures using centralized library
    let script = "window.odyssey.applyBasicAntiDetection();"

    do {
      _ = try await webView.evaluateJavaScript(script)
      logger.info("🛡️ Basic anti-detection measures applied successfully.")
    } catch {
      logger.error("❌ Failed to apply anti-detection measures: \(error.localizedDescription).")
    }

    // Quick human-like behavior simulation (much faster)
    await simulateQuickMouseMovements()
    await simulateQuickScrolling()
    await addQuickPause()
  }

  /// Simulates quick realistic mouse movements
  public func simulateQuickMouseMovements() async {
    guard let webView else { return }

    // Much faster mouse movements (0.1-0.3s total)
    try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...300_000_000))

    let script = "window.odyssey.simulateQuickMouseMovement();"

    do {
      if let ok = try await webView.evaluateJavaScript(script) as? Bool, ok == false {
        logger.warning("⚠️ simulateQuickMouseMovement returned false (ignored).")
      }
    } catch {
      logger.warning(
        "⚠️ Error simulating mouse movement (non-fatal): \(error.localizedDescription).")
    }
  }

  /// Simulates quick realistic scrolling
  public func simulateQuickScrolling() async {
    guard let webView else { return }

    // Much faster scrolling (0.1-0.2s)
    try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...200_000_000))

    let script = "window.odyssey.simulateQuickScrolling();"

    do {
      if let ok = try await webView.evaluateJavaScript(script) as? Bool, ok == false {
        logger.warning("⚠️ simulateQuickScrolling returned false (ignored).")
      }
    } catch {
      logger.warning("⚠️ Error simulating scrolling (non-fatal): \(error.localizedDescription).")
    }
  }

  /// Adds a quick pause (0.1-0.3s)
  public func addQuickPause() async {
    try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...300_000_000))
  }

  /// Adds natural pauses to simulate human thinking/reading
  public func addNaturalPauses() async {
    // Much shorter pauses (0.2-0.5s)
    let pauseDuration = UInt64.random(in: 200_000_000...500_000_000)
    try? await Task.sleep(nanoseconds: pauseDuration)
  }

  /// Simulates realistic mouse movements (alias for enhanced version)
  public func simulateRealisticMouseMovements() async {
    await simulateQuickMouseMovements()
  }

  /// Simulates human scrolling
  public func simulateHumanScrolling() async {
    await simulateQuickScrolling()
  }

  /// Simulates human form interaction
  public func simulateHumanFormInteraction() async {
    await addQuickPause()
  }

  /// Simulates realistic scrolling
  public func simulateRealisticScrolling() async {
    await simulateQuickScrolling()
  }

  /// Simulates enhanced mouse movements
  public func simulateEnhancedMouseMovements() async {
    await simulateQuickMouseMovements()
  }

  /// Simulates random keyboard events
  public func simulateRandomKeyboardEvents() async {
    await addQuickPause()
  }

  /// Simulates scrolling
  public func simulateScrolling() async {
    await simulateQuickScrolling()
  }

  /// Moves mouse randomly
  public func moveMouseRandomly() async {
    await simulateQuickMouseMovements()
  }

  /// Adds random delay
  public func addRandomDelay() async {
    await addQuickPause()
  }

  private func cleanupWebView() async {
    logger.info("🧹 Starting WebView cleanup...")
    scriptCompletions.removeAll()
    elementCompletions.removeAll()
    // Safely cleanup WebView if it exists
    if let webView {
      logger.info("🧹 Cleaning up existing WebView...")
      await MainActor.run {
        webView.configuration.userContentController.removeScriptMessageHandler(
          forName: "odysseyHandler")
        webView.navigationDelegate = nil
        webView.stopLoading()
      }
    } else {
      logger.info("ℹ️ No WebView to cleanup.")
    }
    // Clear webView reference
    await MainActor.run {
      self.webView = nil
    }
    logger.info("✅ WebKitService cleanup completed.")
  }

  // MARK: - NSWindowDelegate

  public func windowWillClose(_ notification: Notification) {
    guard let window = notification.object as? NSWindow, window === debugWindow else {
      return
    }

    logger.info("🪟 Browser window closed by user - resetting WebKit service state.")

    // Reset service state when window is manually closed
    Task {
      await MainActor.run {
        // Mark as disconnected
        self.isConnected = false
        self.isRunning = false

        // Clear all completions
        self.navigationCompletions.removeAll()
        self.scriptCompletions.removeAll()
        self.elementCompletions.removeAll()

        // Clear window reference
        self.debugWindow = nil

        // Clear WebView reference
        self.webView = nil

        logger.info("🪟 WebKit service state reset after manual window closure.")
      }

      // Notify ReservationManager about window closure
      if let onWindowClosed = self.onWindowClosed {
        onWindowClosed(.manual)
      }
    }
  }

  /// Check if the current page indicates a successful reservation completion
  public func checkReservationComplete() async -> Bool {
    guard let webView else {
      logger.error("❌ WebView not initialized.")
      return false
    }

    let script = "window.odyssey.checkReservationComplete();"

    do {
      if let result = try await webView.evaluateJavaScript(script) as? [String: Any] {
        let isComplete = result["isComplete"] as? Bool ?? false
        let pageText = result["pageText"] as? String ?? "No page text"
        let title = result["title"] as? String ?? "No title"

        logger.info("🔍 Reservation completion check results.")
        logger.info("📄 Page title: \(title).")
        logger.info("📝 Page text preview: \(pageText).")
        logger.info("✅ Is complete: \(isComplete).")

        if isComplete {
          logger.info("✅ Reservation completion detected.")
          logger.info("📋 Completion details: \(result).")
          return true
        } else {
          logger.warning("⚠️ Reservation completion not detected.")
          logger.info("📋 Incomplete details: \(result).")
          return false
        }
      } else {
        logger.error("❌ Reservation completion check returned invalid result.")
        return false
      }
    } catch {
      logger.error("❌ Error checking reservation completion: \(error.localizedDescription).")
      return false
    }
  }

  /// Check if the current page shows a session error (multiple tabs error)
}

// MARK: - Navigation Delegate

public class WebKitNavigationDelegate: NSObject, WKNavigationDelegate {
  weak var delegate: WebKitService?

  public func webView(_ webView: WKWebView, didFinish _: WKNavigation?) {
    delegate?.currentURL = webView.url?.absoluteString
    delegate?.pageTitle = webView.title

    // Notify any waiting navigation completions
    if let delegate {
      for (_, completion) in delegate.navigationCompletions {
        completion(true)
      }
      delegate.navigationCompletions.removeAll()
    }
  }

  public func webView(_: WKWebView, didFail _: WKNavigation?, withError _: Error) {
    // Notify any waiting navigation completions
    if let delegate {
      for (_, completion) in delegate.navigationCompletions {
        completion(false)
      }
      delegate.navigationCompletions.removeAll()
    }
  }

  public func webView(
    _: WKWebView,
    decidePolicyFor _: WKNavigationAction,
    decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void,
  ) {
    decisionHandler(.allow)
  }
}

// MARK: - Script Message Handler

public class WebKitScriptMessageHandler: NSObject, WKScriptMessageHandler {
  weak var delegate: WebKitService?

  public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage)
  {
    if message.name == "odysseyHandler" {
      if let body = message.body as? [String: Any], let type = body["type"] as? String {
        switch type {
        case "scriptInjected":
          delegate?.logger.info("✅ Automation scripts injected successfully.")
        case "contactFormCheckError":
          if let data = body["data"] as? [String: Any], let msg = data["message"] as? String,
            let stack = data["stack"] as? String
          {
            delegate?.logger.error("❌ [ContactForm][JS] Error: \(msg)\nStack: \(stack).")
          }
        case "contactFormTimeout":
          if let data = body["data"] as? [String: Any], let html = data["html"] as? String,
            let allInputs = data["allInputs"]
          {
            let allInputsStr = String(describing: allInputs)
            delegate?.logger
              .error(
                "[ContactForm][JS] Timeout. HTML: \(html.prefix(1_000))\nInputs: \(allInputsStr)")
          }
        case "contactFormTimeoutError":
          if let data = body["data"] as? [String: Any], let msg = data["message"] as? String,
            let stack = data["stack"] as? String
          {
            delegate?.logger.error("❌ [ContactForm][JS] Timeout error: \(msg)\nStack: \(stack).")
          }
        default:
          break
        }
      }
    }
  }
}

// MARK: - WebKit Element Implementation

@MainActor
@preconcurrency
class WebKitElement: @preconcurrency WebElementProtocol {
  let id: String
  let tagName: String
  let type: String?
  var value: String
  var isDisplayed: Bool
  var isEnabled: Bool
  var isSelected: Bool

  private let webView: WKWebView
  private let service: WebKitService

  init(id: String, webView: WKWebView, service: WebKitService) {
    self.id = id
    self.webView = webView
    self.service = service

    // Default values
    self.tagName = "div"
    self.type = nil
    self.value = ""
    self.isDisplayed = true
    self.isEnabled = true
    self.isSelected = false
  }

  func click() async throws {
    let script = "window.odyssey.clickElementById('\(id)');"

    let result = try await service.executeScriptInternal(script)?.value as? Bool ?? false
    if !result {
      throw WebDriverError.clickFailed("Element not found or click failed")
    }
  }

  func type(_ text: String) async throws {
    let script = "window.odyssey.typeIntoElementById('\(id)', '\(text)');"

    let result = try await service.executeScriptInternal(script)?.value as? Bool ?? false
    if !result {
      throw WebDriverError.typeFailed("Element not found or type failed")
    }

    value = text
  }

  func clear() async throws {
    let script = "window.odyssey.clearElementById('\(id)');"

    let result = try await service.executeScriptInternal(script)?.value as? Bool ?? false
    if !result {
      throw WebDriverError.typeFailed("Element not found or clear failed")
    }

    value = ""
  }

  func getAttribute(_ name: String) async throws -> String? {
    let script = "window.odyssey.getElementAttributeById('\(id)', '\(name)');"

    return try await service.executeScriptInternal(script)?.value as? String
  }

  func getText() async throws -> String {
    let script = "window.odyssey.getElementTextById('\(id)');"

    return try await service.executeScriptInternal(script)?.value as? String ?? ""
  }

  func isDisplayed() async throws -> Bool {
    let script = "window.odyssey.isElementDisplayedById('\(id)');"

    let result = try await service.executeScriptInternal(script)?.value
    return result as? Bool ?? false
  }

  func isEnabled() async throws -> Bool {
    let script = "window.odyssey.isElementEnabledById('\(id)');"

    let result = try await service.executeScriptInternal(script)?.value
    return result as? Bool ?? false
  }

  func isSelected() async throws -> Bool {
    let script = "window.odyssey.isElementSelectedById('\(id)');"

    return try await service.executeScriptInternal(script)?.value as? Bool ?? false
  }
}

// Register the singleton for DI
extension WebKitService {
  public static func registerForDI() {
    ServiceRegistry.shared.register(WebKitService.shared, for: WebKitServiceProtocol.self)
  }
}
