import Foundation
import AppKit
import os.log

/// Service for handling external browser operations
/// Provides functionality to open Chrome in incognito mode for manual reservation verification
class BrowserService {
    static let shared = BrowserService()
    
    private let logger = Logger(subsystem: "com.odyssey.app", category: "BrowserService")
    
    private init() {}
    
    /// Checks if Google Chrome is installed on the system
    ///
    /// - Returns: True if Chrome is installed, false otherwise
    func isChromeInstalled() -> Bool {
        let chromePath = "/Applications/Google Chrome.app"
        return FileManager.default.fileExists(atPath: chromePath)
    }
    
    /// Shows an alert to inform the user that Chrome is required but not installed
    private func showChromeNotInstalledAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Google Chrome Required"
            alert.informativeText = "ODYSSEY requires Google Chrome to open reservation pages in incognito mode. Please install Google Chrome from https://www.google.com/chrome/ and try again."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Download Chrome")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open Chrome download page
                if let url = URL(string: "https://www.google.com/chrome/") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    /// Opens Google Chrome in incognito mode with the specified URL
    ///
    /// This method opens Chrome with incognito enabled to allow users
    /// to manually verify and complete reservations if needed.
    ///
    /// - Parameter url: The URL to open in Chrome
    /// - Returns: True if Chrome was successfully opened, false otherwise
    @discardableResult
    func openChromeIncognito(with url: String) -> Bool {
        guard let url = URL(string: url) else {
            logger.error("Invalid URL: \(url)")
            return false
        }
        
        // Check if Chrome is installed
        guard isChromeInstalled() else {
            logger.error("Google Chrome is not installed")
            showChromeNotInstalledAlert()
            return false
        }
        
        logger.info("Opening Chrome in incognito mode with URL: \(url)")
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = ["-na", "Google Chrome", "--args", "--incognito", url.absoluteString]
        do {
            try process.run()
            logger.info("Successfully opened Chrome in incognito mode")
            return true
        } catch {
            logger.error("Failed to open Chrome: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Opens Chrome in incognito mode with a configuration URL
    ///
    /// - Parameter config: The reservation configuration containing the URL
    /// - Returns: True if Chrome was successfully opened, false otherwise
    @discardableResult
    func openConfigurationInChrome(_ config: ReservationConfig) -> Bool {
        logger.info("Opening configuration '\(config.name)' in Chrome incognito mode")
        return openChromeIncognito(with: config.facilityURL)
    }
    
    /// Opens the default browser with the specified URL
    ///
    /// Fallback method that opens the URL in the user's default browser
    ///
    /// - Parameter url: The URL to open
    /// - Returns: True if the browser was successfully opened, false otherwise
    @discardableResult
    func openURLInDefaultBrowser(_ url: String) -> Bool {
        guard let url = URL(string: url) else {
            logger.error("Invalid URL: \(url)")
            return false
        }
        logger.info("Opening URL in default browser: \(url)")
        let success = NSWorkspace.shared.open(url)
        if success {
            logger.info("Successfully opened URL in default browser")
        } else {
            logger.error("Failed to open URL in default browser")
        }
        return success
    }
    
    // Deprecated: Safari support is unreliable for incognito automation
    @available(*, deprecated, message: "Use openChromeIncognito instead.")
    func openSafariIncognito(with url: String) -> Bool { return false }
    @available(*, deprecated, message: "Use openConfigurationInChrome instead.")
    func openConfigurationInSafari(_ config: ReservationConfig) -> Bool { return false }
} 