// The debug window is essential for development, troubleshooting, and user support.
import AppKit
import os.log
import WebKit

class WebKitDebugWindowManager: NSObject, NSWindowDelegate {
    private var debugWindow: NSWindow?
    private let logger = Logger(subsystem: "com.odyssey.app", category: "WebKitDebugWindowManager")

    @MainActor
    func showDebugWindow(webView: WKWebView?, config: ReservationConfig?) {
        if debugWindow != nil {
            logger.info("🪟 Debug window already exists, reusing existing window.")
            debugWindow?.makeKeyAndOrderFront(nil)
            return
        }
        let windowSizes = [
            (width: 1_440, height: 900),
            (width: 1_680, height: 1_050)
        ]
        let selectedSize = windowSizes.randomElement() ?? windowSizes[0]
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: selectedSize.width, height: selectedSize.height),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false,
            )
        window.title = "ODYSSEY Web Automation"
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.delegate = self
        if let webView {
            window.contentView = webView
        }
        window.makeKeyAndOrderFront(nil)
        debugWindow = window
        logger
            .info(
                "Debug window for WKWebView created and shown with size: \(selectedSize.width)x\(selectedSize.height)",
                )
        if let config {
            updateWindowTitle(with: config)
        }
    }

    @MainActor
    func hideDebugWindow() {
        debugWindow?.orderOut(nil)
    }

    @MainActor
    func updateWindowTitle(with config: ReservationConfig) {
        guard let window = debugWindow else { return }
        let facilityName = ReservationConfig.extractFacilityName(from: config.facilityURL)
        let schedule = ReservationConfig.formatScheduleInfoInline(config: config)
        let newTitle = "\(facilityName) • \(config.sportName) • \(config.numberOfPeople)pp • \(schedule)"
        window.title = newTitle
        logger.info("📝 Updated debug window title to: \(newTitle).")
    }

    @MainActor
    func windowWillClose(_: Notification) {
        logger.info("🪟 Debug window closing - notifying callback.")
        debugWindow = nil
        // Optionally notify a delegate/callback if needed
    }
}
