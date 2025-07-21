import AppKit
import Combine
import os.log
import SwiftUI

/// Manages the status bar (tray) menu for the macOS app
@MainActor
class StatusBarController: NSObject {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: EventMonitor?

    @MainActor private let configurationManager = ConfigurationManager.shared
    @MainActor private let reservationManager = ReservationManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "StatusBarController")

    override init() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()

        super.init()

        setupStatusBar()
        setupPopover()
        setupEventMonitor()
        setupObservers()
    }

    // MARK: - Setup Methods

    private func setupStatusBar() {
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            let image = NSImage(systemSymbolName: "sportscourt", accessibilityDescription: "ODYSSEY")?
                .withSymbolConfiguration(config)
            image?.isTemplate = true
            button.image = image
            button.action = #selector(togglePopover)
            button.target = self
        } else {
            logger.error("Status bar button is nil")
        }
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 400, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
    }

    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.hidePopover(event)
            }
        }
        eventMonitor?.start()
    }

    private func setupObservers() {
        // Observe reservation manager status
        reservationManager.$isRunning
            .sink { [weak self] isRunning in
                self?.logger.info("🔄 StatusBarController: isRunning changed to \(isRunning)")
                self?.updateStatusBarIcon(isRunning: isRunning)
            }
            .store(in: &cancellables)

        reservationManager.$lastRunStatus
            .sink { [weak self] status in
                self?.logger.info("🔄 StatusBarController: lastRunStatus changed to \(status.description)")
                self?.updateStatusBarTooltip(status: status)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    @objc func togglePopover() {
        if popover.isShown {
            hidePopover(nil)
        } else {
            showPopover()
        }
    }

    func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    func hidePopover(_ sender: Any?) {
        popover.performClose(sender)
    }

    // MARK: - Private Methods

    private func updateStatusBarIcon(isRunning: Bool) {
        logger.info("🔄 StatusBarController: Updating icon - isRunning: \(isRunning)")
        if let button = statusItem.button {
            let symbolName = isRunning ? "sportscourt.fill" : "sportscourt"
            let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "ODYSSEY")?
                .withSymbolConfiguration(config)
            image?.isTemplate = true
            button.image = image
            logger.info("🔄 StatusBarController: Icon updated to \(symbolName)")
        } else {
            logger.error("❌ StatusBarController: Button is nil, cannot update icon")
        }
    }

    private func updateStatusBarTooltip(status: ReservationManager.RunStatus) {
        if let button = statusItem.button {
            button.toolTip = "ODYSSEY - \(status.description)"
        }
    }
}

// MARK: - Event Monitor

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
