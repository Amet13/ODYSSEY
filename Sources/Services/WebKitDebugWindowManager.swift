// The browser window is essential for development, troubleshooting, and user support.
import AppKit
import Foundation
import os.log
import WebKit

/// Centralized debug window management for WebKit automation
/// Handles all debug window functionality including creation, display, and cleanup
@MainActor
public final class WebKitDebugWindowManager: NSObject, NSWindowDelegate {
    private var debugWindow: NSWindow?
    private let logger = Logger(subsystem: "com.odyssey.app", category: "WebKitDebugWindowManager")

    // Window configuration
    private let windowWidth: CGFloat = .init(AppConstants.webKitWindowWidth)
    private let windowHeight: CGFloat = .init(AppConstants.webKitWindowHeight)
    private let windowX: CGFloat = AppConstants.webKitDebugWindowX
    private let windowY: CGFloat = AppConstants.webKitDebugWindowY

    // Window state tracking
    private var isWindowVisible = false
    private var currentConfig: ReservationConfig?

    override init() {
        super.init()
        logger.info("🔧 WebKitDebugWindowManager initialized.")
    }

    deinit {
        logger.info("🧹 WebKitDebugWindowManager deinitialized.")
        debugWindow = nil
    }

    // MARK: - Public Interface

    /// Shows the debug window with the specified WebView and configuration
    /// - Parameters:
    ///   - webView: The WebView to display
    ///   - config: The current reservation configuration
    public func showDebugWindow(webView: WKWebView?, config: ReservationConfig?) {
        guard let webView else {
            logger.warning("⚠️ Cannot show debug window: WebView is nil.")
            return
        }

        currentConfig = config

        // Check user settings to determine if window should be shown
        let userSettings = UserSettingsManager.shared.userSettings
        if !userSettings.showBrowserWindow {
            logger.info("🪟 Debug window hidden (user setting: hide window - recommended to avoid captcha detection).")
            return
        }

        if debugWindow == nil {
            createDebugWindow()
        }

        guard let window = debugWindow else {
            logger.error("❌ Failed to create debug window.")
            return
        }

        // Update window content
        updateWindowContent(webView: webView)

        // Show window if not already visible
        if !isWindowVisible {
            window.makeKeyAndOrderFront(nil)
            isWindowVisible = true
            logger.info("🪟 Debug window shown.")
        }

        updateWindowTitle(with: config)
    }

    /// Hides the debug window
    public func hideDebugWindow() {
        guard let window = debugWindow else {
            logger.info("🪟 No debugWindow to close in disconnect.")
            return
        }

        window.close()
        debugWindow = nil
        isWindowVisible = false
        currentConfig = nil
        logger.info("🪟 Debug window closed.")
    }

    /// Updates the window title with configuration information
    /// - Parameter config: The current reservation configuration
    public func updateWindowTitle(with config: ReservationConfig?) {
        guard let window = debugWindow else { return }

        let baseTitle = "\(AppConstants.appName)"
        if let config {
            let facilityName = ReservationConfig.extractFacilityName(from: config.facilityURL)
            let scheduleInfo = ReservationConfig.formatScheduleInfoInline(config: config)
            window.title = "\(baseTitle) - \(config.sportName) at \(facilityName) (\(scheduleInfo))"
        } else {
            window.title = baseTitle
        }
    }

    /// Forces the debug window to close and cleanup resources
    public func forceClose() {
        guard let window = debugWindow else { return }

        window.close()
        debugWindow = nil
        isWindowVisible = false
        currentConfig = nil
        logger.info("🪟 Debug window force closed.")
    }

    /// Checks if the debug window is currently visible
    public var isVisible: Bool {
        return isWindowVisible && debugWindow != nil
    }

    /// Gets the current debug window
    public var window: NSWindow? {
        return debugWindow
    }

    // MARK: - Private Methods

    private func createDebugWindow() {
        logger.info("🔧 Creating debug window...")

        // Create window with proper configuration
        let window = NSWindow(
            contentRect: NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false,
            )

        // Configure window properties
        window.title = "ODYSSEY"
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.managed, .fullScreenNone]

        // Set window appearance
        window.backgroundColor = NSColor.windowBackgroundColor
        window.isOpaque = false
        window.hasShadow = true

        debugWindow = window
        logger.info("✅ Debug window created successfully.")
    }

    private func updateWindowContent(webView: WKWebView) {
        guard let window = debugWindow else { return }

        // Set the WebView as the window's content view
        webView.frame = window.contentView?.bounds ?? webView.frame
        window.contentView = webView

        logger.info("✅ Debug window content updated.")
    }

    private func cleanup() {
        forceClose()
    }

    // MARK: - NSWindowDelegate

    public func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == debugWindow else { return }

        isWindowVisible = false
        logger.info("🪟 Debug window closing.")
    }

    public func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == debugWindow else { return }

        // Update WebView frame when window is resized
        if let webView = window.contentView as? WKWebView {
            webView.frame = window.contentView?.bounds ?? webView.frame
        }
    }

    public func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == debugWindow else { return }
    }
}

// MARK: - Debug Window Configuration

public extension WebKitDebugWindowManager {
    /// Configuration for debug window behavior
    struct DebugWindowConfig {
        public let showWindow: Bool
        public let windowSize: CGSize
        public let windowPosition: CGPoint
        public let windowLevel: NSWindow.Level

        public init(
            showWindow: Bool = false,
            windowSize: CGSize = CGSize(width: AppConstants.webKitWindowWidth, height: AppConstants.webKitWindowHeight),
            windowPosition: CGPoint = CGPoint(x: AppConstants.webKitDebugWindowX, y: AppConstants.webKitDebugWindowY),
            windowLevel: NSWindow.Level = .floating
        ) {
            self.showWindow = showWindow
            self.windowSize = windowSize
            self.windowPosition = windowPosition
            self.windowLevel = windowLevel
        }
    }
}
