import AppKit
import Combine
import SwiftUI
import os

/// Manages the status bar (tray) menu for the macOS app
@MainActor
class StatusBarController: NSObject {
  private var statusBar: NSStatusBar
  private var statusItem: NSStatusItem
  private var popover: NSPopover
  private var eventMonitor: EventMonitor?

  private let configurationManager = ConfigurationManager.shared
  private let orchestrator = ReservationOrchestrator.shared
  private let statusManager = ReservationStatusManager.shared

  private var cancellables = Set<AnyCancellable>()
  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem, category: "StatusBarController")

  private let statusIconPointSize: CGFloat = AppConstants.statusBarIconPointSize

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
      let config = NSImage.SymbolConfiguration(pointSize: statusIconPointSize, weight: .regular)
      let image = NSImage(
        systemSymbolName: AppConstants.SFSymbols.appOutline, accessibilityDescription: "ODYSSEY")?
        .withSymbolConfiguration(config)
      image?.isTemplate = true
      button.image = image
      button.imagePosition = .imageOnly
      button.action = #selector(togglePopover)
      button.target = self

    } else {
      logger.error("❌ Status bar button is nil.")
    }
  }

  private func setupPopover() {
    popover.contentSize = NSSize(
      width: AppConstants.windowMainWidth,
      height: AppConstants.windowMainHeight
    )
    popover.behavior = .transient
    popover.contentViewController = NSHostingController(rootView: ContentView())
  }

  private func setupEventMonitor() {
    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      guard let self else { return }
      guard self.popover.isShown else { return }
      // Only close when clicking outside popover window
      if let popoverWindow = self.popover.contentViewController?.view.window,
        let eventWindowNumber = event?.windowNumber,
        eventWindowNumber == popoverWindow.windowNumber
      {
        return
      }
      self.hidePopover(event)
    }
    eventMonitor?.start()
  }

  private func setupObservers() {
    // Observe reservation manager status
    statusManager.$isRunning
      .sink { [weak self] isRunning in
        self?.logger.info("🔄 StatusBarController: isRunning changed to \(isRunning).")
        self?.updateStatusBarIcon(isRunning: isRunning)
      }
      .store(in: &cancellables)

    statusManager.$lastRunStatus
      .sink { [weak self] status in
        self?.logger.info("🔄 StatusBarController: lastRunStatus changed to \(status.description).")
        self?.updateStatusBarTooltip(status: status)
      }
      .store(in: &cancellables)
  }

  // MARK: - Public Methods

  @objc func togglePopover() {
    // Activate the application first
    NSApp.activate(ignoringOtherApps: true)

    if popover.isShown {
      hidePopover(nil)
    } else {
      showPopover()
    }
  }

  func showPopover() {
    if let button = statusItem.button {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
      // Ensure the popover window stays key and front to prevent focus loss
      if let popoverWindow = popover.contentViewController?.view.window {
        popoverWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }
  }

  func hidePopover(_ sender: Any?) {
    popover.performClose(sender)
  }

  func toggleGodModeUI() {
    logger.info("⌨️ StatusBarController: Toggling God Mode UI via global keyboard shortcut.")

    // Use the shared God Mode state manager
    GodModeStateManager.shared.toggleGodModeUI()
  }

  func addConfiguration() {
    logger.info("⌨️ StatusBarController: Adding configuration via global keyboard shortcut.")

    // Show the popover if it's not already shown
    if !popover.isShown {
      showPopover()
    }

    // Trigger add configuration through the ContentView

    NotificationCenter.default.post(name: AppConstants.addConfigurationNotification, object: nil)
  }

  func openSettings() {
    logger.info("⌨️ StatusBarController: Opening settings via global keyboard shortcut.")

    // Show the popover if it's not already shown
    if !popover.isShown {
      showPopover()
    }

    // Trigger settings opening through the ContentView
    NotificationCenter.default.post(name: AppConstants.openSettingsNotification, object: nil)
  }

  // MARK: - Private Methods

  private func updateStatusBarIcon(isRunning: Bool) {
    logger.info("🔄 StatusBarController: Updating icon - isRunning: \(isRunning).")
    if let button = statusItem.button {
      let symbolName = isRunning ? AppConstants.SFSymbols.app : AppConstants.SFSymbols.appOutline
      let config = NSImage.SymbolConfiguration(pointSize: statusIconPointSize, weight: .regular)
      let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "ODYSSEY")?
        .withSymbolConfiguration(config)
      image?.isTemplate = true
      button.image = image
      logger.info("🔄 StatusBarController: Icon updated to \(symbolName).")
    } else {
      logger.error("❌ StatusBarController: Button is nil, cannot update icon.")
    }
  }

  private func updateStatusBarTooltip(status: ReservationRunStatus) {
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
