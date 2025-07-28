//
//  WebKitService.swift
//  ODYSSEY
//
//  Created by ODYSSEY Team
//
//  IMPORTANT: WebKit Native Approach
//  ===================================
//  This service implements a native Swift WebKit approach for web automation
//  that provides:
//  - No external dependencies
//  - Native macOS integration
//  - Better performance and reliability
//  - Smaller app footprint
//  - No permission issues
//

import AppKit
import Combine
import Foundation
import os.log
import SwiftUI
import WebKit

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
public final class WebKitService: NSObject, ObservableObject, WebAutomationServiceProtocol, WebKitServiceProtocol,
                                  NSWindowDelegate,
                                  @unchecked Sendable {
    // Singleton instance for app-wide use
    public static let shared = WebKitService()
    // Register this service for dependency injection
    static let registered: Void = {
        ServiceRegistry.shared.register(WebKitService.shared, for: WebKitServiceProtocol.self)
    }()

    // Published properties for UI binding and automation state
    @Published public var isConnected = false
    @Published public var isRunning: Bool = false
    @Published public var currentURL: String?
    @Published public var pageTitle: String?
    /// User-facing error message to be displayed in the UI.
    @Published var userError: String?

    // Callback for window closure (used for cleanup and UI updates)
    public var onWindowClosed: ((ReservationRunType) -> Void)?

    let logger: Logger

    // WebKit components for browser automation
    public var webView: WKWebView?
    private var navigationDelegate: WebKitNavigationDelegate?
    private var scriptMessageHandler: WebKitScriptMessageHandler?
    private var debugWindow: NSWindow?
    private var instanceId: String = "default"

    // Configuration for the current automation run
    public var currentConfig: ReservationConfig? {
        didSet {
            // Update window title when config changes (for debug window)
            if let config = currentConfig {
                Task { @MainActor in
                    updateWindowTitle(with: config)
                }
            }
        }
    }

    // User agent and language for anti-detection and compatibility
    var userAgent: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    private var language: String = "en-US,en"

    // Completion handlers for async navigation and script operations
    var navigationCompletions: [String: @Sendable (Bool) -> Void] = [:]
    private var scriptCompletions: [String: @Sendable (Any?) -> Void] = [:]
    private var elementCompletions: [String: @Sendable (String?) -> Void] = [:]

    // Track live instances for debugging and anti-detection
    @MainActor private static var liveInstanceCount = 0
    @MainActor static func printLiveInstanceCount() {
        Logger(subsystem: "com.odyssey.app", category: "WebKitService")
            .info("📊 Live WebKitService instances: \(liveInstanceCount)")
    }

    /// Main initializer supporting dependency injection for all major dependencies.
    /// - Parameters:
    ///   - logger: Logger instance (default: ODYSSEY WebKitService logger)
    ///   - webView: WKWebView instance (default: nil, will be set up internally)
    ///   - navigationDelegate: WebKitNavigationDelegate (default: nil, will be set up internally)
    ///   - scriptMessageHandler: WebKitScriptMessageHandler (default: nil, will be set up internally)
    ///   - debugWindow: NSWindow for debug (default: nil)
    ///   - instanceId: Unique instance identifier (default: "default")
    public init(
        logger: Logger = Logger(subsystem: "com.odyssey.app", category: "WebKitService"),
        webView: WKWebView? = nil,
        navigationDelegate: WebKitNavigationDelegate? = nil,
        scriptMessageHandler: WebKitScriptMessageHandler? = nil,
        debugWindow: NSWindow? = nil,
        instanceId: String = "default"
    ) {
        self.logger = logger
        self.webView = webView
        self.navigationDelegate = navigationDelegate
        self.scriptMessageHandler = scriptMessageHandler
        self.debugWindow = debugWindow
        self.instanceId = instanceId
        super.init()
        logger.info("🔧 WebKitService initialized (DI mode).")
        Task { @MainActor in
            Self.liveInstanceCount += 1
            logger.info("🔄 WebKitService init. Live instances: \(Self.liveInstanceCount)")
        }
        // If no webView provided, set up a new one
        if webView == nil {
            setupWebView()
        }
    }

    // Keep the default singleton for app use
    override private init() {
        self.logger = Logger(subsystem: "com.odyssey.app", category: "WebKitService")
        super.init()
        logger.info("🔧 WebKitService initialized.")
        Task { @MainActor in
            Self.liveInstanceCount += 1
            logger.info("🔄 WebKitService init. Live instances: \(Self.liveInstanceCount)")
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
        logger.info("✅ WebKitService cleanup completed. Live instances: \(liveInstanceCount)")
    }

    deinit {
        logger.info("🧹 WebKitService deinitialized.")
        navigationCompletions.removeAll()
        scriptCompletions.removeAll()
        elementCompletions.removeAll()
        webView = nil
        MainActor.assumeIsolated {
            Self.liveInstanceCount -= 1
            logger.info("✅ WebKitService cleanup completed. Live instances: \(Self.liveInstanceCount)")
        }
    }

    private func setupWebView() {
        logger.info("🔧 Setting up new WebView for instance: \(self.instanceId).")
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
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
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
        let xOffset = (hash % 200) + 50
        let yOffset = ((hash / 200) % 200) + 50
        webView?.frame = CGRect(x: xOffset, y: yOffset, width: selectedSize.width, height: selectedSize.height)

        // Inject custom JavaScript for automation and anti-detection
        injectAutomationScripts()
        injectAntiDetectionScripts()
        logger.info("✅ WebView setup completed successfully for instance: \(self.instanceId).")
    }

    @MainActor
    private func setupDebugWindow() {
        // Check user settings to determine if browser window should be shown
        let userSettings = UserSettingsManager.shared.userSettings
        if !userSettings.showBrowserWindow {
            logger.info("🪟 Browser window hidden (user setting: hide window - recommended to avoid captcha detection)")
            return
        }

        // Check if browser window already exists
        if debugWindow != nil {
            logger.info("🪟 Browser window already exists, reusing existing window.")
            debugWindow?.makeKeyAndOrderFront(nil)
            return
        }
        // Set realistic window size (random from common MacBook resolutions)
        let windowSizes = AppConstants.windowSizes
        let selectedSize = windowSizes.randomElement() ?? windowSizes[0]
        // Create a visible window for debugging
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: selectedSize.width, height: selectedSize.height),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false,
            )
        window.title = "ODYSSEY Web Automation"
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.delegate = self // Set window delegate to monitor closure
        if let webView {
            window.contentView = webView
        }
        window.makeKeyAndOrderFront(nil)
        debugWindow = window
        logger
            .info(
                "Browser window for WKWebView created and shown with size: \(selectedSize.width)x\(selectedSize.height)",
                )
    }

    @MainActor
    private func updateWindowTitle(with config: ReservationConfig) {
        guard let window = debugWindow else { return }
        let facilityName = ReservationConfig.extractFacilityName(from: config.facilityURL)
        let schedule = ReservationConfig.formatScheduleInfoInline(config: config)
        let newTitle = "\(facilityName) • \(config.sportName) • \(config.numberOfPeople)pp • \(schedule)"
        window.title = newTitle
        logger.info("📝 Updated browser window title to: \(newTitle).")
    }

    private func injectAutomationScripts() {
        let automationScript = """
        window.odyssey = {
            // Find element by text content
            findElementByText: function(text, timeout = 10000) {
                return new Promise((resolve, reject) => {
                    const startTime = Date.now();
                    const checkElement = () => {
                        const elements = document.querySelectorAll('*');
                        for (let element of elements) {
                            if (element.textContent && element.textContent.trim() === text) {
                                resolve(element);
                                return;
                            }
                        }

                        if (Date.now() - startTime < timeout) {
                            setTimeout(checkElement, 100);
                        } else {
                            reject(new Error('Element not found'));
                        }
                    };
                    checkElement();
                });
            },

            // Find element by XPath
            findElementByXPath: function(xpath) {
                const result = document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
                return result.singleNodeValue;
            },

            // Click element with human-like behavior
            clickElement: function(element) {
                if (!element) return false;

                // Scroll into view
                element.scrollIntoView({ behavior: 'smooth', block: 'center' });

                // Simulate mouse events
                const rect = element.getBoundingClientRect();
                const centerX = rect.left + rect.width / 2;
                const centerY = rect.top + rect.height / 2;

                // Mouse down
                element.dispatchEvent(new MouseEvent('mousedown', {
                    bubbles: true,
                    cancelable: true,
                    view: window,
                    clientX: centerX,
                    clientY: centerY
                }));

                // Mouse up
                element.dispatchEvent(new MouseEvent('mouseup', {
                    bubbles: true,
                    cancelable: true,
                    view: window,
                    clientX: centerX,
                    clientY: centerY
                }));

                // Click
                element.click();

                return true;
            },

            // Fill form field
            fillField: function(selector, value, instant = false) {
                const field = document.querySelector(selector);
                if (!field) return false;

                field.focus();
                field.value = '';

                if (instant) {
                    field.value = value;
                } else {
                    // Simulate typing
                    for (let char of value) {
                        field.value += char;
                        field.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                }

                field.dispatchEvent(new Event('change', { bubbles: true }));
                return true;
            },

            // Fill form field with browser autofill behavior (less likely to trigger captchas)
            fillFieldWithAutofill: function(selector, value) {
                const field = document.querySelector(selector);
                if (!field) return false;

                // Browser autofill behavior: scroll into view
                field.scrollIntoView({ behavior: 'auto', block: 'center' });

                // Focus and clear
                field.focus();
                field.value = '';

                // Autofill-style: set value instantly
                field.value = value;

                // Dispatch autofill events
                field.dispatchEvent(new Event('input', { bubbles: true }));
                field.dispatchEvent(new Event('change', { bubbles: true }));
                field.dispatchEvent(new Event('autocomplete', { bubbles: true }));

                // Blur (browser autofill behavior)
                field.blur();

                return true;
            },

            // Wait for element to appear
            waitForElement: function(selector, timeout = 10000) {
                return new Promise((resolve, reject) => {
                    const startTime = Date.now();
                    const checkElement = () => {
                        const element = document.querySelector(selector);
                        if (element) {
                            resolve(element);
                        } else if (Date.now() - startTime < timeout) {
                            setTimeout(checkElement, 100);
                        } else {
                            reject(new Error('Element not found'));
                        }
                    };
                    checkElement();
                });
            },

            // Get page source
            getPageSource: function() {
                return document.documentElement.outerHTML;
            },

            // Execute custom script
            executeScript: function(script) {
                try {
                    return eval(script);
                } catch (error) {
                    console.error('Script execution error:', error);
                    return null;
                }
            }
        };

        // Make odyssey available globally
        window.webkit.messageHandlers.odysseyHandler.postMessage({
            type: 'scriptInjected',
            data: { success: true }
        });
        """

        let script = WKUserScript(source: automationScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView?.configuration.userContentController.addUserScript(script)
    }

    private func injectAntiDetectionScripts() {
        let antiDetectionScript = """
        // Comprehensive anti-detection measures to avoid reCAPTCHA detection
        (function() {
            // Generate unique fingerprint for this instance
            const instanceId = '\(instanceId)';
            const instanceHash = instanceId.split('').reduce((a, b) => a + b.charCodeAt(0), 0);

            // Random screen sizes for realism (common MacBook resolutions)
            const screenSizes = [
                { width: 1440, height: 900, pixelRatio: 2 },   // MacBook Air 13"
                { width: 1680, height: 1050, pixelRatio: 2 }  // MacBook Pro 15"
            ];

            const selectedScreen = screenSizes[instanceHash % screenSizes.length];

            // Real Chrome user agents (updated regularly)
            const userAgents = [
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15'
            ];

            const selectedUserAgent = userAgents[Math.floor(Math.random() * userAgents.length)];

            // Override navigator properties
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined,
                configurable: true
            });

            Object.defineProperty(navigator, 'platform', {
                get: () => 'MacIntel',
                configurable: true
            });

            Object.defineProperty(navigator, 'languages', {
                get: () => ['en-US', 'en'],
                configurable: true
            });

            Object.defineProperty(navigator, 'language', {
                get: () => 'en-US',
                configurable: true
            });

            Object.defineProperty(navigator, 'hardwareConcurrency', {
                get: () => 8,
                configurable: true
            });

            Object.defineProperty(navigator, 'maxTouchPoints', {
                get: () => 0,
                configurable: true
            });

            Object.defineProperty(navigator, 'vendor', {
                get: () => 'Google Inc.',
                configurable: true
            });

            Object.defineProperty(navigator, 'userAgent', {
                get: () => selectedUserAgent,
                configurable: true
            });

            // Realistic plugins
            const mockPlugins = [
                { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer', description: 'Portable Document Format' },
                { name: 'Chrome PDF Viewer', filename: 'mhjfbmdgcfjbbpaeojofohoefgiehjai', description: '' },
                { name: 'Native Client', filename: 'internal-nacl-plugin', description: '' }
            ];

            Object.defineProperty(navigator, 'plugins', {
                get: () => {
                    const plugins = [];
                    mockPlugins.forEach((plugin, index) => {
                        plugins[index] = {
                            name: plugin.name,
                            filename: plugin.filename,
                            description: plugin.description,
                            length: 1
                        };
                    });
                    plugins.length = mockPlugins.length;
                    return plugins;
                },
                configurable: true
            });

            // Screen properties
            Object.defineProperty(screen, 'width', {
                get: () => selectedScreen.width,
                configurable: true
            });

            Object.defineProperty(screen, 'height', {
                get: () => selectedScreen.height,
                configurable: true
            });

            Object.defineProperty(screen, 'availWidth', {
                get: () => selectedScreen.width,
                configurable: true
            });

            Object.defineProperty(screen, 'availHeight', {
                get: () => selectedScreen.height - 23, // Menu bar height
                configurable: true
            });

            Object.defineProperty(screen, 'colorDepth', {
                get: () => 24,
                configurable: true
            });

            Object.defineProperty(screen, 'pixelDepth', {
                get: () => 24,
                configurable: true
            });

            // Window properties
            Object.defineProperty(window, 'devicePixelRatio', {
                get: () => selectedScreen.pixelRatio,
                configurable: true
            });

            Object.defineProperty(window, 'outerWidth', {
                get: () => selectedScreen.width,
                configurable: true
            });

            Object.defineProperty(window, 'outerHeight', {
                get: () => selectedScreen.height,
                configurable: true
            });

            Object.defineProperty(window, 'innerWidth', {
                get: () => selectedScreen.width,
                configurable: true
            });

            Object.defineProperty(window, 'innerHeight', {
                get: () => selectedScreen.height - 23,
                configurable: true
            });

            // Chrome runtime object
            Object.defineProperty(window, 'chrome', {
                get: () => ({
                    runtime: {
                        onConnect: undefined,
                        onMessage: undefined,
                        connect: function() { return { postMessage: function() {} }; },
                        sendMessage: function() {}
                    },
                    loadTimes: function() {
                        return {
                            commitLoadTime: Date.now() / 1000,
                            connectionInfo: 'h2',
                            finishDocumentLoadTime: Date.now() / 1000,
                            finishLoadTime: Date.now() / 1000,
                            firstPaintAfterLoadTime: Date.now() / 1000,
                            navigationType: 'Other',
                            npnNegotiatedProtocol: 'h2',
                            requestTime: Date.now() / 1000,
                            startLoadTime: Date.now() / 1000,
                            wasAlternateProtocolAvailable: false,
                            wasFetchedViaSpdy: true,
                            wasNpnNegotiated: true
                        };
                    }
                }),
                configurable: true
            });

            // Document properties
            Object.defineProperty(document, 'hidden', {
                get: () => false,
                configurable: true
            });

            Object.defineProperty(document, 'visibilityState', {
                get: () => 'visible',
                configurable: true
            });

            // Timezone and locale
            Object.defineProperty(Intl, 'DateTimeFormat', {
                get: () => function() {
                    return {
                        resolvedOptions: function() {
                            return {
                                timeZone: 'America/Toronto',
                                locale: 'en-US'
                            };
                        }
                    };
                },
                configurable: true
            });

            // WebGL fingerprinting protection
            const getParameter = WebGLRenderingContext.prototype.getParameter;
            WebGLRenderingContext.prototype.getParameter = function(parameter) {
                if (parameter === 37445) {
                    return 'Intel Inc.';
                }
                if (parameter === 37446) {
                    return 'Intel Iris OpenGL Engine';
                }
                return getParameter.call(this, parameter);
            };

            // Canvas fingerprinting protection
            const originalGetContext = HTMLCanvasElement.prototype.getContext;
            HTMLCanvasElement.prototype.getContext = function(type) {
                const context = originalGetContext.call(this, type);
                if (type === '2d') {
                    const originalFillText = context.fillText;
                    context.fillText = function() {
                        return originalFillText.apply(this, arguments);
                    };
                }
                return context;
            };

            // Touch events (even though Mac doesn't have touch)
            Object.defineProperty(window, 'ontouchstart', {
                get: () => null,
                set: () => {},
                configurable: true
            });

            Object.defineProperty(window, 'ontouchmove', {
                get: () => null,
                set: () => {},
                configurable: true
            });

            Object.defineProperty(window, 'ontouchend', {
                get: () => null,
                set: () => {},
                configurable: true
            });

            // Media devices
            if (navigator.mediaDevices) {
                Object.defineProperty(navigator.mediaDevices, 'enumerateDevices', {
                    get: () => function() {
                        return Promise.resolve([
                            { deviceId: 'default', kind: 'audioinput', label: 'Default - MacBook Pro Microphone' },
                            { deviceId: 'default', kind: 'audiooutput', label: 'Default - MacBook Pro Speakers' }
                        ]);
                    },
                    configurable: true
                });
            }

            // Font enumeration protection
            if (document.fonts) {
                Object.defineProperty(document.fonts, 'ready', {
                    get: () => Promise.resolve(),
                    configurable: true
                });
            }

            // Add realistic mouse movement patterns
            let lastMouseX = Math.random() * selectedScreen.width;
            let lastMouseY = Math.random() * selectedScreen.height;

            // Override mouse event properties to be more realistic
            const originalMouseEvent = window.MouseEvent;
            window.MouseEvent = function(type, init) {
                if (!init) init = {};
                if (!init.clientX) init.clientX = lastMouseX + Math.random() * 10 - 5;
                if (!init.clientY) init.clientY = lastMouseY + Math.random() * 10 - 5;
                lastMouseX = init.clientX;
                lastMouseY = init.clientY;
                return new originalMouseEvent(type, init);
            };
            window.MouseEvent.prototype = originalMouseEvent.prototype;

            // Add realistic timing patterns
            const originalSetTimeout = window.setTimeout;
            window.setTimeout = function(fn, delay) {
                // Add small random variations to timing
                const adjustedDelay = delay + Math.random() * 50 - 25;
                return originalSetTimeout(fn, Math.max(0, adjustedDelay));
            };

            // Add realistic scroll behavior
            const originalScrollIntoView = Element.prototype.scrollIntoView;
            Element.prototype.scrollIntoView = function(options) {
                // Add small delay to scroll behavior
                setTimeout(() => {
                    originalScrollIntoView.call(this, options);
                }, Math.random() * 100);
            };

            // Performance timing protection
            if (window.performance && window.performance.timing) {
                const timing = window.performance.timing;
                const now = Date.now();
                Object.defineProperty(timing, 'navigationStart', {
                    get: () => now - Math.random() * 1000,
                    configurable: true
                });
            }

            // Advanced tab detection prevention
            // Override localStorage and sessionStorage to be instance-specific
            const originalLocalStorage = window.localStorage;
            const originalSessionStorage = window.sessionStorage;

            // Create unique storage keys for this instance
            const storagePrefix = 'odyssey_' + instanceHash + '_';

            // Override localStorage
            Object.defineProperty(window, 'localStorage', {
                get: () => ({
                    getItem: function(key) {
                        return originalLocalStorage.getItem(storagePrefix + key);
                    },
                    setItem: function(key, value) {
                        return originalLocalStorage.setItem(storagePrefix + key, value);
                    },
                    removeItem: function(key) {
                        return originalLocalStorage.removeItem(storagePrefix + key);
                    },
                    clear: function() {
                        // Only clear our instance's data
                        const keys = Object.keys(originalLocalStorage);
                        keys.forEach(k => {
                            if (k.startsWith(storagePrefix)) {
                                originalLocalStorage.removeItem(k);
                            }
                        });
                    },
                    key: function(index) {
                        const keys = Object.keys(originalLocalStorage).filter(k => k.startsWith(storagePrefix));
                        return keys[index] ? keys[index].substring(storagePrefix.length) : null;
                    },
                    get length() {
                        return Object.keys(originalLocalStorage).filter(k => k.startsWith(storagePrefix)).length;
                    }
                }),
                configurable: true
            });

            // Override sessionStorage
            Object.defineProperty(window, 'sessionStorage', {
                get: () => ({
                    getItem: function(key) {
                        return originalSessionStorage.getItem(storagePrefix + key);
                    },
                    setItem: function(key, value) {
                        return originalSessionStorage.setItem(storagePrefix + key, value);
                    },
                    removeItem: function(key) {
                        return originalSessionStorage.removeItem(storagePrefix + key);
                    },
                    clear: function() {
                        // Only clear our instance's data
                        const keys = Object.keys(originalSessionStorage);
                        keys.forEach(k => {
                            if (k.startsWith(storagePrefix)) {
                                originalSessionStorage.removeItem(k);
                            }
                        });
                    },
                    key: function(index) {
                        const keys = Object.keys(originalSessionStorage).filter(k => k.startsWith(storagePrefix));
                        return keys[index] ? keys[index].substring(storagePrefix.length) : null;
                    },
                    get length() {
                        return Object.keys(originalSessionStorage).filter(k => k.startsWith(storagePrefix)).length;
                    }
                }),
                configurable: true
            });

            // Override IndexedDB to be instance-specific
            if (window.indexedDB) {
                const originalOpen = window.indexedDB.open;
                window.indexedDB.open = function(name, version) {
                    return originalOpen.call(this, storagePrefix + name, version);
                };
            }

            // Override cookies to be instance-specific
            const originalDocumentCookie = Object.getOwnPropertyDescriptor(Document.prototype, 'cookie');
            Object.defineProperty(document, 'cookie', {
                get: function() {
                    const cookies = originalDocumentCookie.get.call(this);
                    return cookies.split(';').filter(cookie =>
                        cookie.trim().startsWith(storagePrefix)
                    ).map(cookie =>
                        cookie.trim().substring(storagePrefix.length)
                    ).join('; ');
                },
                set: function(value) {
                    return originalDocumentCookie.set.call(this, storagePrefix + value);
                },
                configurable: true
            });

            // Override WebSocket to add unique headers
            const originalWebSocket = window.WebSocket;
            window.WebSocket = function(url, protocols) {
                const ws = new originalWebSocket(url, protocols);
                ws.addEventListener('open', function() {
                    // Add unique headers to WebSocket connection
                    if (ws.readyState === WebSocket.OPEN) {
                        ws.send(JSON.stringify({
                            type: 'odyssey_instance',
                            instanceId: instanceId,
                            timestamp: Date.now()
                        }));
                    }
                });
                return ws;
            };
            window.WebSocket.prototype = originalWebSocket.prototype;

            // Override fetch to add unique headers
            const originalFetch = window.fetch;
            window.fetch = function(input, init) {
                if (!init) init = {};
                if (!init.headers) init.headers = {};

                // Add unique headers to avoid request correlation
                init.headers['X-Odyssey-Instance'] = instanceId;
                init.headers['X-Odyssey-Timestamp'] = Date.now().toString();

                return originalFetch.call(this, input, init);
            };

            // Override XMLHttpRequest to add unique headers
            const originalXHROpen = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
                const xhr = this;
                originalXHROpen.call(this, method, url, async, user, password);

                // Add unique headers after opening
                this.addEventListener('readystatechange', function() {
                    if (xhr.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
                        xhr.setRequestHeader('X-Odyssey-Instance', instanceId);
                        xhr.setRequestHeader('X-Odyssey-Timestamp', Date.now().toString());
                    }
                });
            };

            // Override navigator.connection to be unique
            if (navigator.connection) {
                Object.defineProperty(navigator.connection, 'effectiveType', {
                    get: () => ['4g', '3g', '2g'][instanceHash % 3],
                    configurable: true
                });
            }

            // Add unique device memory
            Object.defineProperty(navigator, 'deviceMemory', {
                get: () => [4, 8, 16][instanceHash % 3],
                configurable: true
            });

            // Add unique battery API
            if (navigator.getBattery) {
                const originalGetBattery = navigator.getBattery;
                navigator.getBattery = function() {
                    return Promise.resolve({
                        charging: Math.random() > 0.5,
                        chargingTime: Math.random() * 3600,
                        dischargingTime: Math.random() * 7200,
                        level: Math.random()
                    });
                };
            }

            console.log('[ODYSSEY] Comprehensive anti-detection measures activated for instance: ' + instanceId);
            console.log('[ODYSSEY] Screen: ' + selectedScreen.width + 'x' + selectedScreen.height + ' @' + selectedScreen.pixelRatio + 'x');
            console.log('[ODYSSEY] User Agent: ' + selectedUserAgent.substring(0, 50) + '...');
            console.log('[ODYSSEY] Storage prefix: ' + storagePrefix);
        })();
        """

        let script = WKUserScript(source: antiDetectionScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView?.configuration.userContentController.addUserScript(script)
    }

    @MainActor
    private func logAllButtonsAndLinks() async {
        guard let webView else {
            logger.error("❌ [ButtonScan] webView is nil.")
            return
        }
        let script = """
        (function() {
            let results = [];
            let btns = Array.from(document.querySelectorAll('button, a, div'));
            for (let el of btns) {
                let txt = el.innerText || el.textContent || '';
                let tag = el.tagName;
                let id = el.id || '';
                let cls = el.className || '';
                let clickable = (el.onclick || el.getAttribute('role') === 'button' || el.tabIndex >= 0);
                results.push(`[${tag}] id='${id}' class='${cls}' clickable=${clickable} text='${txt.trim()}'`);
            }
            return results;
        })();
        """
        do {
            let result = try await webView.evaluateJavaScript(script)
            if let arr = result as? [String] {
                for line in arr {
                    logger.info("🔍 [ButtonScan] \(line, privacy: .public)")
                }
            } else {
                logger.error("❌ [ButtonScan] Unexpected JS result: \(String(describing: result))")
            }
        } catch {
            logger.error("❌ [ButtonScan] JS error: \(error.localizedDescription, privacy: .public) | \(error)")
        }
    }

    // Helper to log page state for debugging

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
        logger.info("🔌 Starting WebKit service disconnect. closeWindow=\(closeWindow)")
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
        // Only close browser window if requested
        if closeWindow {
            await MainActor.run {
                if let window = self.debugWindow {
                    logger.info("🪟 Closing debugWindow in disconnect.")
                    window.close()
                } else {
                    logger.info("🪟 No debugWindow to close in disconnect.")
                }
                self.debugWindow = nil
            }
        }
        // Failsafe: Force close all NSWindows with our title
        await MainActor.run {
            let allWindows = NSApplication.shared.windows
            for window in allWindows where window.title.contains("ODYSSEY Web Automation") {
                logger.info("🪟 Failsafe: Forcibly closing window with title: \(window.title)")
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
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

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
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

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

    /// Get current service state for debugging
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
                .run { self.userError = "Web browser is not initialized. Please try again or restart the app." }
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
                                let readyState = try await self.executeScriptInternal("return document.readyState;")?
                                    .value
                                self.logger
                                    .info("📄 document.readyState after navigation: \(String(describing: readyState))")
                                let pageSource = try await self.getPageSource()
                                self.logger
                                    .info("Page source after navigation (first 500 chars): \(pageSource.prefix(500))")
                            } catch {
                                self.logger
                                    .error("❌ Error logging readyState/page source: \(error.localizedDescription)")
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
                        continuation.resume(throwing: WebDriverError.navigationFailed("Failed to navigate to \(url)"))
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

        let script = """
        const elements = document.querySelectorAll('\(selector)');
        return Array.from(elements).map((el, index) => 'element_' + index);
        """

        let result = try await executeScriptInternal(script)?.value
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

        let result = try await executeScriptInternal("return document.documentElement.outerHTML;")?.value
        return result as? String ?? ""
    }

    public func getCurrentURL() async throws -> String {
        guard webView != nil else {
            throw WebDriverError.elementNotFound("WebView not initialized")
        }

        return await MainActor.run {
            webView?.url?.absoluteString ?? ""
        }
    }

    public func getTitle() async throws -> String {
        guard webView != nil else {
            throw WebDriverError.elementNotFound("WebView not initialized")
        }

        return await MainActor.run {
            webView?.title ?? ""
        }
    }

    @MainActor
    public func waitForElement(by selector: String, timeout: TimeInterval) async throws -> WebElementProtocol {
        guard webView != nil else {
            throw WebDriverError.elementNotFound("WebView not initialized")
        }

        let script = """
        return new Promise((resolve, reject) => {
            const startTime = Date.now();
            const checkElement = () => {
                const element = document.querySelector('\(selector)');
                if (element) {
                    resolve('element_found');
                } else if (Date.now() - startTime < \(timeout * 1_000)) {
                    setTimeout(checkElement, 100);
                } else {
                    reject(new Error('Element not found'));
                }
            };
            checkElement();
        });
        """

        _ = try await executeScriptInternal(script)
        return try await findElement(by: selector)
    }

    @MainActor
    public func waitForElementToDisappear(by selector: String, timeout: TimeInterval) async throws {
        guard webView != nil else {
            throw WebDriverError.elementNotFound("WebView not initialized")
        }

        let script = """
        return new Promise((resolve, reject) => {
            const startTime = Date.now();
            const checkElement = () => {
                const element = document.querySelector('\(selector)');
                if (!element) {
                    resolve();
                } else if (Date.now() - startTime < \(timeout * 1_000)) {
                    setTimeout(checkElement, 100);
                } else {
                    reject(new Error('Element did not disappear'));
                }
            };
            checkElement();
        });
        """

        _ = try await executeScriptInternal(script)
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
            await MainActor.run { self.userError = "Web browser is not ready. Please try again or restart the app." }
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
                        await MainActor.run { self.userError = "Web browser was disconnected during script execution." }
                        continuation
                            .resume(
                                throwing: WebDriverError
                                    .scriptExecutionFailed("WebView was disconnected during script execution"),
                                )
                        return
                    }

                    // Add a small delay to allow any pending operations to complete
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                    // Check again after the delay
                    guard self.isConnected else {
                        await MainActor
                            .run { self.userError = "Web browser was disconnected during JavaScript execution." }
                        continuation
                            .resume(
                                throwing: WebDriverError
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
                    continuation.resume(throwing: WebDriverError.scriptExecutionFailed(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Reservation-specific Methods

    public func findAndClickElement(withText text: String) async -> Bool {
        guard webView != nil else {
            logger.error("❌ WebView not initialized.")
            return false
        }

        logger.info("🔍 Searching for sport button: '\(text, privacy: .private)'.")
        let script = """
        (function() {
            try {
                const divXPath = "//div[contains(text(),'\(text)')]";
                const result = document.evaluate(divXPath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
                const div = result.singleNodeValue;
                if (div) {
                    div.scrollIntoView({behavior: 'smooth', block: 'center'});
                    try {
                        div.click();
                        return 'clicked';
                    } catch (e) {
                        try {
                            let evt = document.createEvent('MouseEvents');
                            evt.initEvent('click', true, true);
                            div.dispatchEvent(evt);
                            return 'dispatched';
                        } catch (e2) {
                            return 'error:dispatch:' + e2.toString();
                        }
                    }
                } else {
                    return 'not found';
                }
            } catch (err) {
                return 'error:' + err.toString();
            }
        })();
        """
        logger.info("🔘 [ButtonClick] Executing JS: \(script, privacy: .public)")
        do {
            let result = try await executeScriptInternal(script)?.value
            logger.info("🔘 [ButtonClick] JS result: \(String(describing: result), privacy: .public)")
            if let str = result as? String {
                if str == "clicked" || str == "dispatched" {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second sleep
                    return true
                } else if str.starts(with: "error:") {
                    logger.error("❌ [ButtonClick] JS error: \(str, privacy: .public)")
                    return false
                } else {
                    logger
                        .error(
                            "Sport button not found: '\(text, privacy: .private)' | JS result: \(str, privacy: .public)",
                            )
                    return false
                }
            } else {
                logger.error("❌ [ButtonClick] Unexpected JS result: \(String(describing: result))")
                return false
            }
        } catch {
            logger.error("❌ Error clicking sport button: \(error.localizedDescription, privacy: .public) | \(error)")
            return false
        }
    }

    /// Waits for DOM ready or for a key button/element to appear
    /// Now also checks for the presence of a button with the configured sport name
    public func waitForDOMReady() async -> Bool {
        guard webView != nil else {
            logger.error("❌ waitForDOMReady: WebView not initialized")
            return false
        }
        let configSport = currentConfig?.sportName ?? ""
        let buttonCheckScript = """
        (() => {
            const ready = document.readyState === 'complete';
            const button = Array.from(document.querySelectorAll('button,div,a')).find(el => el.textContent && el.textContent.includes('\(
                configSport
            )'));
            return { readyState: document.readyState, buttonFound: !!button };
        })();
        """
        do {
            logger.info("🔧 Executing enhanced DOM ready/button check script...")
            let result = try await executeScriptInternal(buttonCheckScript)?.value
            logger.info("📊 DOM/button check result: \(String(describing: result))")
            if let dict = result as? [String: Any] {
                let readyState = dict["readyState"] as? String ?? ""
                let buttonFound = dict["buttonFound"] as? Bool ?? false
                logger.info("📄 document.readyState=\(readyState), buttonFound=\(buttonFound)")
                if readyState == "complete" || buttonFound {
                    logger.info("✅ DOM ready or button found, proceeding")
                    return true
                } else {
                    logger.error("❌ DOM not ready and button not found")
                    return false
                }
            } else {
                logger.error("❌ Unexpected result from DOM/button check: \(String(describing: result))")
                return false
            }
        } catch {
            logger.error("❌ Error waiting for DOM ready/button: \(error.localizedDescription)")
            return false
        }
    }

    @MainActor
    public func waitForDOMReadyAndButton(selector _: String, buttonText: String) async -> Bool {
        guard let webView else {
            logger.error("❌ waitForDOMReady: WebView not initialized")
            return false
        }
        let start = Date()
        let timeout: TimeInterval = 10
        while Date().timeIntervalSince(start) < timeout {
            let script = """
            (function() {
                let btns = Array.from(document.querySelectorAll('button, a, div'));
                for (let el of btns) {
                    let txt = el.innerText || el.textContent || '';
                    if (txt && txt.toLowerCase().includes('\(buttonText.lowercased())')) {
                        return true;
                    }
                }
                return false;
            })();
            """
            do {
                let result = try await webView.evaluateJavaScript(script)
                if let found = result as? Bool, found {
                    return true
                }
            } catch {
                logger
                    .error(
                        "waitForDOMReadyAndButton JS error: \(error.localizedDescription, privacy: .public) | error: \(String(describing: error), privacy: .public)",
                        )
                return false
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }
        logger.error("❌ Button with text \(buttonText) not found after 10s")
        return false
    }

    public func fillNumberOfPeople(_ numberOfPeople: Int) async -> Bool {
        guard webView != nil else {
            logger.error("❌ WebView not initialized")
            return false
        }

        let script = """
        (function() {
            let field = document.getElementById('reservationCount')
                || document.querySelector('input[name=\"ReservationCount\"]')
                || document.querySelector('input[type=\"number\"]');
            if (field) {
                field.value = '';
                field.focus();
                field.value = '\(numberOfPeople)';
                field.dispatchEvent(new Event('input', { bubbles: true }));
                field.dispatchEvent(new Event('change', { bubbles: true }));
                return 'filled';
            } else {
                let inputs = Array.from(document.querySelectorAll('input'));
                let details = inputs.map(el =>
                    `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [placeholder='${el.placeholder}'] [type='${el.type}']`
                );
                return 'not found: ' + details.join(' | ');
            }
        })();
        """

        do {
            let result = try await executeScriptInternal(script)?.value

            if let str = result as? String, str == "filled" {
                return true
            } else {
                logger.error("❌ Field not found or not filled: \(String(describing: result))")
                return false
            }
        } catch {
            logger.error("❌ Error filling number of people: \(error.localizedDescription)")
            return false
        }
    }

    public func clickConfirmButton() async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            let button = document.getElementById('submit-btn')
                || document.querySelector('button[type="submit"]')
                || Array.from(document.querySelectorAll('button, input[type="submit"]'))
                    .find(el => el.innerText && el.innerText.toLowerCase().includes('confirm'));
            if (button) {
                // Log button state before click
                console.log('Button before click:', {
                    disabled: button.disabled,
                    text: button.innerText,
                    type: button.type,
                    class: button.className
                });

                button.click();

                // Log button state after click
                setTimeout(() => {
                    console.log('Button after click:', {
                        disabled: button.disabled,
                        text: button.innerText,
                        type: button.type,
                        class: button.className
                    });
                }, 100);

                return 'clicked';
            } else {
                let btns = Array.from(document.querySelectorAll('button, input[type="submit"]'));
                let details = btns.map(el =>
                    `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [text='${el.innerText || el.value || ''}']`
                );
                return 'not found: ' + details.join(' | ');
            }
        })();
        """

        logger.info("🔘 [ConfirmClick] Executing JS: \(script, privacy: .public)")
        do {
            let result = try await executeScriptInternal(script)
            logger.info("🔘 [ConfirmClick] JS result: \(String(describing: result), privacy: .public)")
            if let str = result?.value as? String, str == "clicked" {
                // Wait a moment for the page to settle
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                // Also check for any error messages or loading states
                let checkScript = """
                (function() {
                    let errors = Array.from(document.querySelectorAll('.error, .alert, .message, [class*="error"], [class*="alert"]')).map(el => el.innerText);
                    let loading = Array.from(document.querySelectorAll('[class*="loading"], [class*="spinner"], .disabled')).map(el => el.innerText);
                    let buttons = Array.from(document.querySelectorAll('button')).map(el => ({
                        text: el.innerText,
                        disabled: el.disabled,
                        class: el.className
                    }));
                    return { errors, loading, buttons };
                })();
                """
                let checkResult = try await executeScriptInternal(checkScript)
                logger.info("📊 [ConfirmClick] Page check: \(String(describing: checkResult), privacy: .public)")

                return true
            } else {
                logger.error("❌ [ConfirmClick] Button not found or not clicked: \(String(describing: result))")
                return false
            }
        } catch {
            logger.error("❌ Error clicking confirm button: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Additional Reservation Methods

    public func waitForGroupSizePage() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let timeout: TimeInterval = 10
        let pollInterval: TimeInterval = 0.5
        let start = Date()
        var pollCount = 0
        while Date().timeIntervalSince(start) < timeout {
            pollCount += 1
            let script = """
            (function() {
                let html = document.documentElement.outerHTML.substring(0, 5000);
                let inputs = Array.from(document.querySelectorAll('input')).map(el =>
                    `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [placeholder='${el.placeholder}'] [type='${el.type}'] [value='${el.value}'] [visible='${!!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)}']`
                );
                let buttons = Array.from(document.querySelectorAll('button')).map(el =>
                    `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [text='${el.innerText || ''}'] [visible='${!!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)}']`
                );
                let divs = Array.from(document.querySelectorAll('div')).map(el =>
                    `[id='${el.id}'] [class='${el.className}'] [text='${el.innerText || ''}'] [visible='${!!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)}']`
                );
                let found = document.getElementById('reservationCount')
                    || document.querySelector('input[name=\"reservationCount\"]')
                    || Array.from(document.querySelectorAll('input'))
                        .find(el => (el.placeholder||'').toLowerCase().includes('people') || el.type === 'number');
                return { html, inputs, buttons, divs, found: !!found };
            })();
            """
            do {
                let result = try await webView.evaluateJavaScript(script)
                if let dict = result as? [String: Any] {
                    let found = dict["found"] as? Bool ?? false
                    let html = dict["html"] as? String ?? ""
                    let inputs = dict["inputs"] as? [String] ?? []
                    let buttons = dict["buttons"] as? [String] ?? []
                    let divs = dict["divs"] as? [String] ?? []
                    logger
                        .info(
                            "[GroupSizePoll][poll \(pollCount)] found=\(found)\nINPUTS: \(inputs.joined(separator: ", "))\nBUTTONS: \(buttons.joined(separator: ", "))\nDIVS: \(divs.prefix(5).joined(separator: ", "))\nHTML: \(html.prefix(5_000))",
                            )
                    if found {
                        logger.info("📊 Group size input found on poll #\(pollCount)")
                        return true
                    }
                }
            } catch {
                logger.error("[GroupSizePoll][poll \(pollCount)] JS error: \(error.localizedDescription)")
            }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        logger.error("❌ Group size page load timeout after \(Int(timeout))s and \(pollCount) polls")
        return false
    }

    public func waitForTimeSelectionPage() async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        logger.info("⏳ [TimeSelection] Starting time selection page detection...")

        // Simple script to check page content
        let script = """
        (function() {
            try {
                const pageText = document.body.textContent || document.body.innerText || '';
                const title = document.title || '';
                const url = window.location.href || '';

                console.log('Page content check:', {
                    pageText: pageText.substring(0, 200),
                    title: title,
                    url: url,
                    hasSelectDateText: pageText.toLowerCase().includes('select a date and time'),
                    hasPlusSymbols: pageText.includes('⊕') || pageText.includes('+') || pageText.includes('○') || pageText.includes('●'),
                    hasDateElements: document.querySelectorAll('[class*="date"], [class*="day"], [id*="date"], [id*="day"]').length
                });

                // Check for multiple indicators that we're on the time selection page
                const hasSelectDateText = pageText.toLowerCase().includes('select a date and time');
                const hasPlusSymbols = pageText.includes('⊕') || pageText.includes('+') || pageText.includes('○') || pageText.includes('●');
                const hasDateElements = document.querySelectorAll('[class*="date"], [class*="day"], [id*="date"], [id*="day"]').length > 0;

                // If any of these indicators are present, we're on the time selection page
                return hasSelectDateText || hasPlusSymbols || hasDateElements;
            } catch (error) {
                console.error('Error in time selection page check:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await executeScriptInternal(script)?.value as? Bool ?? false

            logger.info("📊 [TimeSelection] JavaScript result: \(result)")

            if result {
                logger.info("✅ Time selection page loaded successfully")
            } else {
                logger.error("❌ Time selection page not detected")
            }
            return result
        } catch {
            logger.error("❌ Error checking time selection page: \(error.localizedDescription)")
            return false
        }
    }

    public func selectTimeSlot(dayName: String, timeString: String) async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        logger.info("📅 Selecting time slot: \(dayName, privacy: .private) at \(timeString, privacy: .private)")

        let script = """
        (function() {
            try {
                const allElements = Array.from(document.querySelectorAll('*'));
                const dayName = '\(dayName)'.trim().toLowerCase();
                const dayParts = dayName.split(/\\s+/).filter(Boolean);
                // Log all elements with click handlers
                const clickables = allElements.filter(el => typeof el.onclick === 'function' || el.hasAttribute('onclick'));
                console.log('[ODYSSEY] All elements with click handlers:', clickables.map(el => el.outerHTML));
                // Log all candidate elements' text, visibility, and outerHTML
                allElements.forEach(el => {
                    const text = el.textContent.trim().toLowerCase();
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);
                    console.log(`[ODYSSEY] Candidate: text="${text}", visible=${visible}, outerHTML=${el.outerHTML.substring(0, 200)}`);
                });
                // Find all elements whose text includes any part of the dayName
                const candidates = allElements.filter(el => {
                    const text = el.textContent.trim().toLowerCase();
                    return dayParts.some(part => part && text.includes(part));
                });
                console.log('[ODYSSEY] Day section candidates:', candidates.map(el => el.outerHTML));
                // Find all elements with class 'header-text'
                const headerElements = Array.from(document.getElementsByClassName('header-text'));
                headerElements.forEach((el, idx) => {
                    const text = el.textContent.trim();
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);
                    console.log(`[ODYSSEY] header-text[${idx}]: text="${text}", visible=${visible}`);
                });

                // Find and click the SPECIFIC day that matches our target day
                let clicked = false;
                const targetDayName = '\(dayName)'.trim().toLowerCase();
                console.log('[ODYSSEY] Looking for day section matching:', targetDayName);

                for (let i = 0; i < headerElements.length; i++) {
                    const el = headerElements[i];
                    const headerText = el.textContent.trim().toLowerCase();
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);

                    console.log(`[ODYSSEY] Checking header-text[${i}]: text="${el.textContent.trim()}", matches target: ${headerText.includes(targetDayName)}`);

                    // Check if this header contains our target day name
                    if (headerText.includes(targetDayName) && visible) {
                        el.scrollIntoView({behavior: 'smooth', block: 'center'});
                        el.click();
                        clicked = true;
                        console.log(`[ODYSSEY] Clicked matching day header[${i}]: text="${el.textContent.trim()}"`);
                        break;
                    }
                }

                // If no exact match found, try partial matching
                if (!clicked) {
                    console.log('[ODYSSEY] No exact match found, trying partial matching...');
                    const dayParts = targetDayName.split(/\\s+/).filter(Boolean);

                    for (let i = 0; i < headerElements.length; i++) {
                        const el = headerElements[i];
                        const headerText = el.textContent.trim().toLowerCase();
                        const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);

                        // Check if any part of the target day name matches
                        const hasMatch = dayParts.some(part => part && headerText.includes(part));
                        console.log(`[ODYSSEY] Partial check header-text[${i}]: text="${el.textContent.trim()}", has match: ${hasMatch}`);

                        if (hasMatch && visible) {
                            el.scrollIntoView({behavior: 'smooth', block: 'center'});
                            el.click();
                            clicked = true;
                            console.log(`[ODYSSEY] Clicked partial match header[${i}]: text="${el.textContent.trim()}"`);
                            break;
                        }
                    }
                }
                // After expanding, find and click the time slot by aria-label
                const slotTime = '\(timeString)';
                const slotDay = '\(dayName)';
                const timeSlotSelector = `[aria-label*='${slotTime} ${slotDay}']`;
                console.log('[ODYSSEY] Looking for time slot with selector:', timeSlotSelector);
                const timeSlotElements = Array.from(document.querySelectorAll(timeSlotSelector));
                timeSlotElements.forEach((el, idx) => {
                    const text = el.textContent.trim();
                    const aria = el.getAttribute('aria-label');
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);
                    console.log(`[ODYSSEY] time-slot[${idx}]: text="${text}", aria-label="${aria}", visible=${visible}`);
                });
                let timeSlotClicked = false;
                for (let i = 0; i < timeSlotElements.length; i++) {
                    const el = timeSlotElements[i];
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);
                    if (visible) {
                        el.scrollIntoView({behavior: 'smooth', block: 'center'});
                        el.click();
                        timeSlotClicked = true;
                        console.log(`[ODYSSEY] Clicked time-slot[${i}]: aria-label="${el.getAttribute('aria-label')}"`);
                        break;
                    }
                }
                return {clicked, timeSlotClicked, headerCount: headerElements.length, timeSlotCount: timeSlotElements.length};
            } catch (e) {
                return {clicked: false, error: e.toString()};
            }
        })()
        """
        do {
            let result = try await webView?.evaluateJavaScript(script)
            logger.info("📊 [TimeSlot][DaySection] JS result: \(String(describing: result), privacy: .private)")
            if let dict = result as? [String: Any], let clicked = dict["clicked"] as? Bool, clicked {
                logger.info("📊 [TimeSlot][DaySection] Day section expanded successfully")

                // Check if time slot was also clicked
                if let timeSlotClicked = dict["timeSlotClicked"] as? Bool, timeSlotClicked {
                    logger.info("✅ [TimeSlot] Time slot clicked successfully")

                    // Wait for page to load after time slot click
                    logger.info("⏳ [TimeSlot] Waiting for page to load after time slot click...")
                    try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second

                    // Check if we're already on the contact form page
                    let contactFormReady = await waitForContactInfoPage()
                    if contactFormReady {
                        logger
                            .info(
                                "Contact form page already loaded after time slot selection - skipping continue button check",
                                )
                    } else {
                        // Check for continue button after time slot selection
                        let continueClicked = await checkAndClickContinueButton()
                        if continueClicked {
                            logger.info("✅ Continue button clicked after time slot selection")
                        } else {
                            logger.warning("⚠️ No continue button found after time slot selection")
                        }
                    }
                }

                return true
            } else {
                // Log analysis results
                if let dict = result as? [String: Any], let analysis = dict["analysis"] as? [String: Any] {
                    let symbolMatches = analysis["symbolMatches"] as? [[String: Any]] ?? []
                    let dayMatches = analysis["dayMatches"] as? [[String: Any]] ?? []
                    let elementsWithSymbols = analysis["elementsWithSymbols"] as? Int ?? 0

                    let symbolLog = symbolMatches.map { match in
                        let symbol = match["symbol"] as? String ?? "?"
                        let count = match["count"] as? Int ?? 0
                        return "\(symbol):\(count)"
                    }.joined(separator: ", ")

                    let dayLog = dayMatches.map { match in
                        let day = match["day"] as? String ?? "?"
                        let count = match["count"] as? Int ?? 0
                        return "\(day):\(count)"
                    }.joined(separator: ", ")

                    logger
                        .error(
                            "[TimeSlot][DaySection] Page analysis - Symbols: [\(symbolLog)], Days: [\(dayLog)], Elements with symbols: \(elementsWithSymbols)",
                            )
                }

                // Log candidates as simple strings to avoid privacy redaction
                if let dict = result as? [String: Any], let candidates = dict["candidates"] as? [[String: Any]] {
                    let candidateStrings = candidates.map { candidate in
                        let text = candidate["text"] as? String ?? "unknown"
                        let tag = candidate["tag"] as? String ?? "unknown"
                        let visible = candidate["visible"] as? Bool ?? false
                        return "[\(tag)] \(text) (visible: \(visible))"
                    }
                    logger
                        .error(
                            "[TimeSlot][DaySection] Failed to expand day section. Found \(candidates.count) candidates: \(candidateStrings.joined(separator: ", "))",
                            )
                } else {
                    logger
                        .error(
                            "[TimeSlot][DaySection] Failed to expand day section. No candidates found or result format error.",
                            )
                }
                return false
            }
        } catch {
            logger.error("[TimeSlot][DaySection] JS error: \(error.localizedDescription, privacy: .private)")
            return false
        }
    }

    public func checkAndClickContinueButton() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Add human-like delay before checking
        await addRandomDelay()

        let script = """
        (function() {
            try {
                // Simple approach: just check if there's a confirm button and click it
                const confirmButton = document.getElementById('submit-btn');
                if (confirmButton && confirmButton.textContent.toLowerCase().includes('confirm')) {
                    confirmButton.click();
                    return true;
                }

                // Fallback: look for any button with confirm text
                const allButtons = Array.from(document.querySelectorAll('button'));
                for (const button of allButtons) {
                    const text = (button.textContent || '').toLowerCase();
                    if (text.includes('confirm') && !button.disabled) {
                        button.click();
                        return true;
                    }
                }

                return false;
            } catch (error) {
                console.error('Error in continue button check:', error);
                return false;
            }
        })();
        """
        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            return result
        } catch {
            logger
                .error(
                    "❌ [ContinueButton] Error checking for continue button: \(error.localizedDescription, privacy: .public)",
                    )
            logger.error("❌ [ContinueButton] Continue button error details: \(error, privacy: .public)")
            return false
        }
    }

    public func clickContinueAfterTimeSlot() async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        // Add human-like delay before clicking
        await addRandomDelay()
        await moveMouseRandomly()

        let script = """
        // Log all buttons on the page for debugging
        const allButtons = Array.from(document.querySelectorAll('button, input[type="submit"], input[type="button"], a[role="button"], div[role="button"]'));
        const buttonDetails = allButtons.map((btn, index) => ({
            index: index,
            tagName: btn.tagName || '',
            type: btn.type || '',
            className: btn.className || '',
            id: btn.id || '',
            textContent: (btn.textContent || '').trim(),
            innerText: (btn.innerText || '').trim(),
            ariaLabel: btn.getAttribute('aria-label') || '',
            disabled: !!btn.disabled,
            visible: !!(btn.offsetWidth || btn.offsetHeight || btn.getClientRects().length),
            outerHTML: (btn.outerHTML || '').substring(0, 200) + '...'
        }));
        console.log('[ODYSSEY] All buttons found:', buttonDetails);

        // Log all clickable elements with cursor style
        const clickables = Array.from(document.querySelectorAll('*')).filter(el => {
            const style = window.getComputedStyle(el);
            return style.cursor === 'pointer' || el.onclick || el.hasAttribute('onclick');
        });
        const clickableDetails = clickables.map((el, index) => ({
            index: index,
            tagName: el.tagName || '',
            className: el.className || '',
            id: el.id || '',
            textContent: (el.textContent || '').trim().substring(0, 50),
            cursor: (() => {
                try {
                    return window.getComputedStyle(el).cursor;
                } catch (e) {
                    return '';
                }
            })(),
            hasOnClick: !!el.onclick,
            hasOnclickAttr: el.hasAttribute('onclick'),
            visible: !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)
        }));
        console.log('[ODYSSEY] All clickable elements:', clickableDetails);

        // Try to find continue button with multiple strategies
        let continueButton = null;
        let strategy = '';

        // Strategy 1: Exact text match
        const exactMatches = allButtons.filter(btn => {
            const text = (btn.textContent || '').toLowerCase();
            return text.includes('continue') || text.includes('next') || text.includes('book') || text.includes('confirm') || text.includes('proceed') || text.includes('submit');
        });
        if (exactMatches.length > 0) {
            continueButton = exactMatches[0];
            strategy = 'exact text match';
        }

        // Strategy 2: Partial text match
        if (!continueButton) {
            const partialMatches = allButtons.filter(btn => {
                const text = (btn.textContent || '').toLowerCase();
                return text.includes('cont') || text.includes('next') || text.includes('book') || text.includes('conf') || text.includes('proc') || text.includes('sub');
            });
            if (partialMatches.length > 0) {
                continueButton = partialMatches[0];
                strategy = 'partial text match';
            }
        }

        // Strategy 3: mdc-button__ripple class (from Python/Selenium)
        if (!continueButton) {
            const rippleButtons = document.querySelectorAll('.mdc-button__ripple');
            if (rippleButtons.length > 0) {
                continueButton = rippleButtons[0];
                strategy = 'mdc-button__ripple class';
            }
        }

        // Strategy 4: Submit type buttons
        if (!continueButton) {
            const submitButtons = allButtons.filter(btn => btn.type === 'submit');
            if (submitButtons.length > 0) {
                continueButton = submitButtons[0];
                strategy = 'submit type';
            }
        }

        // Strategy 5: First visible button
        if (!continueButton) {
            const visibleButtons = allButtons.filter(btn => btn.visible && !btn.disabled);
            if (visibleButtons.length > 0) {
                continueButton = visibleButtons[0];
                strategy = 'first visible button';
            }
        }

        if (continueButton) {
            console.log(`[ODYSSEY] Found continue button using strategy: ${strategy}`);
            console.log(`[ODYSSEY] Button details:`, {
                tagName: continueButton.tagName || '',
                className: continueButton.className || '',
                id: continueButton.id || '',
                textContent: (continueButton.textContent || '').trim(),
                visible: continueButton.visible,
                disabled: continueButton.disabled
            });

            // Scroll to button and click
            continueButton.scrollIntoView({behavior: 'smooth', block: 'center'});
            continueButton.click();
            console.log(`[ODYSSEY] Clicked continue button: ${(continueButton.textContent || '').trim()}`);
            return {clicked: true, strategy: strategy, buttonText: (continueButton.textContent || '').trim()};
        } else {
            console.log('[ODYSSEY] No continue button found with any strategy');
            return {clicked: false, strategy: 'none'};
        }
        """

        do {
            let result = try await webView?.evaluateJavaScript(script)
            logger.info("[ContinueButton] JS result: \(String(describing: result), privacy: .private)")
            if let dict = result as? [String: Any], let clicked = dict["clicked"] as? Bool, clicked {
                logger.info("[ContinueButton] Continue button clicked successfully")
                return true
            } else {
                logger.error("[ContinueButton] Failed to click continue button")
                return false
            }
        } catch {
            logger
                .error(
                    "[ContinueButton] Error clicking continue button after time slot selection: \(error, privacy: .private)",
                    )
            return false
        }
    }

    public func waitForContactInfoPage() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Enhanced approach: check for multiple indicators of contact info page
        let script = """
        (function() {
            try {
                // Check for telephone field
                const phoneField = document.getElementById('telephone');
                const hasPhoneField = phoneField !== null;

                // Check for email field
                const emailField = document.getElementById('email');
                const hasEmailField = emailField !== null;

                // Check for name field
                const nameField = document.getElementById('name');
                const hasNameField = nameField !== null;

                // Check for confirm button
                const confirmButton = document.querySelector('button[type="submit"], input[type="submit"], .mdc-button');
                const hasConfirmButton = confirmButton !== null;

                // Check page title or content for contact info indicators
                const bodyText = document.body.textContent || '';
                const hasContactText = bodyText.toLowerCase().includes('phone') ||
                                     bodyText.toLowerCase().includes('email');

                console.log('[ODYSSEY] Contact page detection:', {
                    hasPhoneField: hasPhoneField,
                    hasEmailField: hasEmailField,
                    hasNameField: hasNameField,
                    hasConfirmButton: hasConfirmButton,
                    hasContactText: hasContactText,
                    phoneFieldId: phoneField ? phoneField.id : 'not found',
                    emailFieldId: emailField ? emailField.id : 'not found',
                    nameFieldId: nameField ? nameField.id : 'not found',
                    confirmButtonText: confirmButton ? (confirmButton.textContent || '').trim() : 'not found'
                });

                // Return true if we have at least phone field or multiple contact indicators
                const isContactPage = hasPhoneField || (hasEmailField && hasNameField && hasConfirmButton);

                return isContactPage;
            } catch (error) {
                console.error('Error in contact form check:', error);
                return false;
            }
        })();
        """
        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("✅ Contact info page loaded successfully")

                // Activate enhanced antidetection measures immediately when contact page is detected
                logger.info("🛡️ Activating enhanced antidetection measures for contact form page...")
                await enhanceHumanLikeBehavior()

            } else {
                logger.error("❌ Contact info page load timeout - see logs for page HTML and input fields")
            }
            return result
        } catch {
            logger.error("❌ Error checking contact info page: \(error.localizedDescription, privacy: .public)")
            logger.error("❌ Contact form error details: \(error, privacy: .public)")
            return false
        }
    }

    public func fillPhoneNumber(_ phoneNumber: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Optimized delay before starting to avoid reCAPTCHA (0.5-0.9 seconds)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000 ... 900_000_000))

        // Essential human-like behavior simulation
        await addQuickPause()

        let script = """
        (function() {
            // Try multiple selectors to find the phone field
            let phoneField = document.getElementById('telephone') ||
                           document.querySelector('input[type="tel"]') ||
                           document.querySelector('input[name*="PhoneNumber"]') ||
                           document.querySelector('input[placeholder*="Telephone"]');

            console.log('[ODYSSEY] Phone field found:', phoneField ? {
                type: phoneField.type,
                name: phoneField.name,
                id: phoneField.id,
                placeholder: phoneField.placeholder,
                className: phoneField.className,
                value: phoneField.value,
                parentText: phoneField.parentElement ? phoneField.parentElement.textContent.trim().substring(0, 100) : ''
            } : 'NOT FOUND');

            if (phoneField) {
                // Scroll to field with human-like behavior
                phoneField.scrollIntoView({ behavior: 'smooth', block: 'center' });

                // Focus and clear
                phoneField.focus();
                phoneField.value = '';

                // Simulate human-like typing with realistic events and delays
                const value = '\(phoneNumber)';
                console.log('[ODYSSEY] Typing phone:', value);

                // Use a synchronous approach with setTimeout to simulate typing delays
                const typeCharacter = (index) => {
                    if (index >= value.length) {
                        // Add natural delay before finishing
                        setTimeout(() => {
                            phoneField.dispatchEvent(new Event('change', { bubbles: true }));
                            phoneField.blur();
                            console.log('[ODYSSEY] Phone field filled with:', phoneField.value);
                        }, 100 + Math.random() * 200);
                        return;
                    }

                    // Simulate occasional typos (2% chance) - minimal for stealth
                    let charToType = value[index];
                    let shouldMakeTypo = Math.random() < 0.02 && index < value.length - 1;

                    if (shouldMakeTypo) {
                        // Type wrong character first
                        phoneField.value += 'x';
                        phoneField.dispatchEvent(new KeyboardEvent('keydown', {
                            bubbles: true,
                            key: 'x',
                            code: 'KeyX',
                            keyCode: 'x'.charCodeAt(0)
                        }));
                        phoneField.dispatchEvent(new Event('input', { bubbles: true }));
                        phoneField.dispatchEvent(new KeyboardEvent('keyup', {
                            bubbles: true,
                            key: 'x',
                            code: 'KeyX',
                            keyCode: 'x'.charCodeAt(0)
                        }));

                        // Wait before correcting (shorter)
                        setTimeout(() => {
                            // Backspace
                            phoneField.value = phoneField.value.slice(0, -1);
                            phoneField.dispatchEvent(new KeyboardEvent('keydown', {
                                bubbles: true,
                                key: 'Backspace',
                                code: 'Backspace',
                                keyCode: 8
                            }));
                            phoneField.dispatchEvent(new Event('input', { bubbles: true }));
                            phoneField.dispatchEvent(new KeyboardEvent('keyup', {
                                bubbles: true,
                                key: 'Backspace',
                                code: 'Backspace',
                                keyCode: 8
                            }));

                            // Type correct character after shorter pause
                            setTimeout(() => {
                                phoneField.value += charToType;
                                phoneField.dispatchEvent(new KeyboardEvent('keydown', {
                                    bubbles: true,
                                    key: charToType,
                                    code: 'Key' + charToType.toUpperCase(),
                                    keyCode: charToType.charCodeAt(0)
                                }));
                                phoneField.dispatchEvent(new KeyboardEvent('keypress', {
                                    bubbles: true,
                                    key: charToType,
                                    code: 'Key' + charToType.toUpperCase(),
                                    keyCode: charToType.charCodeAt(0)
                                }));
                                phoneField.dispatchEvent(new Event('input', { bubbles: true }));
                                phoneField.dispatchEvent(new KeyboardEvent('keyup', {
                                    bubbles: true,
                                    key: charToType,
                                    code: 'Key' + charToType.toUpperCase(),
                                    keyCode: charToType.charCodeAt(0)
                                }));

                                // Continue with next character after shorter delay
                                setTimeout(() => typeCharacter(index + 1), 50 + Math.random() * 100);
                            }, 150 + Math.random() * 200);
                        }, 200 + Math.random() * 300);
                    } else {
                        // Normal typing with faster, more realistic delays
                        phoneField.value += charToType;
                        phoneField.dispatchEvent(new KeyboardEvent('keydown', {
                            bubbles: true,
                            key: charToType,
                            code: 'Key' + charToType.toUpperCase(),
                            keyCode: charToType.charCodeAt(0)
                        }));
                        phoneField.dispatchEvent(new KeyboardEvent('keypress', {
                            bubbles: true,
                            key: charToType,
                            code: 'Key' + charToType.toUpperCase(),
                            keyCode: charToType.charCodeAt(0)
                        }));
                        phoneField.dispatchEvent(new Event('input', { bubbles: true }));
                        phoneField.dispatchEvent(new KeyboardEvent('keyup', {
                            bubbles: true,
                            key: charToType,
                            code: 'Key' + charToType.toUpperCase(),
                            keyCode: charToType.charCodeAt(0)
                        }));

                        // Optimized human-like delay to avoid reCAPTCHA (100-200ms base)
                        const baseDelay = 100 + Math.random() * 100;
                        const extraDelay = Math.random() < 0.10 ? 150 + Math.random() * 250 : 0; // 10% chance of longer pause
                        const thinkingPause = Math.random() < 0.025 ? 300 + Math.random() * 400 : 0; // 2.5% chance of thinking pause
                        setTimeout(() => typeCharacter(index + 1), baseDelay + extraDelay + thinkingPause);
                    }
                };

                // Start typing after a shorter delay
                setTimeout(() => typeCharacter(0), 150 + Math.random() * 300);

                return true;
            } else {
                console.error('[ODYSSEY] Phone field not found');
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("✅ Successfully filled phone number with enhanced human-like behavior")
                // Optimized delay after filling to avoid reCAPTCHA (0.4-0.7 second)
                try? await Task.sleep(nanoseconds: UInt64.random(in: 400_000_000 ... 700_000_000))
                return true
            } else {
                logger.error("❌ Failed to fill phone number - field not found")
                return false
            }
        } catch {
            logger.error("❌ Error filling phone number: \(error.localizedDescription)")
            return false
        }
    }

    public func fillEmail(_ email: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Optimized delay before starting to avoid reCAPTCHA (0.5-0.9 seconds)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000 ... 900_000_000))

        // Essential human-like behavior simulation
        await addQuickPause()

        let script = """
        (function() {
            // Try multiple selectors to find the email field
            let emailField = document.getElementById('email') ||
                           document.querySelector('input[type="email"]') ||
                           document.querySelector('input[name*="Email"]') ||
                           document.querySelector('input[placeholder*="Email"]');

            console.log('[ODYSSEY] Email field found:', emailField ? {
                type: emailField.type,
                name: emailField.name,
                id: emailField.id,
                placeholder: emailField.placeholder,
                className: emailField.className,
                value: emailField.value,
                parentText: emailField.parentElement ? emailField.parentElement.textContent.trim().substring(0, 100) : ''
            } : 'NOT FOUND');

            if (emailField) {
                // Scroll to field with human-like behavior
                emailField.scrollIntoView({ behavior: 'smooth', block: 'center' });

                // Focus and clear
                emailField.focus();
                emailField.value = '';

                // Simulate human-like typing with realistic events and delays
                const value = '\(email)';
                console.log('[ODYSSEY] Typing email:', value);

                // Use a synchronous approach with setTimeout to simulate typing delays
                const typeCharacter = (index) => {
                    if (index >= value.length) {
                        // Add natural delay before finishing
                        setTimeout(() => {
                            emailField.dispatchEvent(new Event('change', { bubbles: true }));
                            emailField.blur();
                            console.log('[ODYSSEY] Email field filled with:', emailField.value);
                        }, 200 + Math.random() * 300);
                        return;
                    }

                    // Simulate occasional typos (1% chance) - minimal for stealth
                    let charToType = value[index];
                    let shouldMakeTypo = Math.random() < 0.01 && index < value.length - 1;

                    if (shouldMakeTypo) {
                        // Type wrong character first
                        const wrongChars = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
                        const wrongChar = wrongChars[Math.floor(Math.random() * wrongChars.length)];
                        emailField.value += wrongChar;
                        emailField.dispatchEvent(new KeyboardEvent('keydown', {
                            bubbles: true,
                            key: wrongChar,
                            code: 'Key' + wrongChar.toUpperCase(),
                            keyCode: wrongChar.charCodeAt(0)
                        }));
                        emailField.dispatchEvent(new Event('input', { bubbles: true }));
                        emailField.dispatchEvent(new KeyboardEvent('keyup', {
                            bubbles: true,
                            key: wrongChar,
                            code: 'Key' + wrongChar.toUpperCase(),
                            keyCode: wrongChar.charCodeAt(0)
                        }));

                        // Wait before correcting
                        setTimeout(() => {
                            // Backspace
                            emailField.value = emailField.value.slice(0, -1);
                            emailField.dispatchEvent(new KeyboardEvent('keydown', {
                                bubbles: true,
                                key: 'Backspace',
                                code: 'Backspace',
                                keyCode: 8
                            }));
                            emailField.dispatchEvent(new Event('input', { bubbles: true }));
                            emailField.dispatchEvent(new KeyboardEvent('keyup', {
                                bubbles: true,
                                key: 'Backspace',
                                code: 'Backspace',
                                keyCode: 8
                            }));

                            // Type correct character
                            setTimeout(() => {
                                emailField.value += charToType;
                                emailField.dispatchEvent(new KeyboardEvent('keydown', {
                                    bubbles: true,
                                    key: charToType,
                                    code: 'Key' + charToType.toUpperCase(),
                                    keyCode: charToType.charCodeAt(0)
                                }));
                                emailField.dispatchEvent(new KeyboardEvent('keypress', {
                                    bubbles: true,
                                    key: charToType,
                                    code: 'Key' + charToType.toUpperCase(),
                                    keyCode: charToType.charCodeAt(0)
                                }));
                                emailField.dispatchEvent(new Event('input', { bubbles: true }));
                                emailField.dispatchEvent(new KeyboardEvent('keyup', {
                                    bubbles: true,
                                    key: charToType,
                                    code: 'Key' + charToType.toUpperCase(),
                                    keyCode: charToType.charCodeAt(0)
                                }));

                                // Continue with next character
                                setTimeout(() => typeCharacter(index + 1), 150 + Math.random() * 200);
                            }, 300 + Math.random() * 400);
                        }, 400 + Math.random() * 600);
                    } else {
                        // Normal typing with enhanced delays to avoid reCAPTCHA
                        emailField.value += charToType;
                        emailField.dispatchEvent(new KeyboardEvent('keydown', {
                            bubbles: true,
                            key: charToType,
                            code: 'Key' + charToType.toUpperCase(),
                            keyCode: charToType.charCodeAt(0)
                        }));
                        emailField.dispatchEvent(new KeyboardEvent('keypress', {
                            bubbles: true,
                            key: charToType,
                            code: 'Key' + charToType.toUpperCase(),
                            keyCode: charToType.charCodeAt(0)
                        }));
                        emailField.dispatchEvent(new Event('input', { bubbles: true }));
                        emailField.dispatchEvent(new KeyboardEvent('keyup', {
                            bubbles: true,
                            key: charToType,
                            code: 'Key' + charToType.toUpperCase(),
                            keyCode: charToType.charCodeAt(0)
                        }));

                        // Optimized human-like delay to avoid reCAPTCHA (90-180ms base)
                        const baseDelay = 90 + Math.random() * 90;
                        const extraDelay = Math.random() < 0.10 ? 140 + Math.random() * 200 : 0; // 10% chance of longer pause
                        const thinkingPause = Math.random() < 0.025 ? 250 + Math.random() * 350 : 0; // 2.5% chance of thinking pause
                        setTimeout(() => typeCharacter(index + 1), baseDelay + extraDelay + thinkingPause);
                    }
                };

                // Start typing after a natural delay
                setTimeout(() => typeCharacter(0), 300 + Math.random() * 500);

                return true;
            } else {
                console.error('[ODYSSEY] Email field not found');
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("✅ Successfully filled email with enhanced human-like behavior")
                // Optimized delay after filling to avoid reCAPTCHA (0.4-0.7 second)
                try? await Task.sleep(nanoseconds: UInt64.random(in: 400_000_000 ... 700_000_000))
                return true
            } else {
                logger.error("❌ Failed to fill email - field not found")
                return false
            }
        } catch {
            logger.error("❌ Error filling email: \(error.localizedDescription)")
            return false
        }
    }

    public func fillName(_ name: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Check if we're still connected before proceeding
        guard isConnected else {
            logger.error("WebKit service is not connected")
            return false
        }

        // Optimized delay before starting to avoid reCAPTCHA (0.5-0.9 seconds)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000 ... 900_000_000))

        // Essential human-like behavior simulation
        await addQuickPause()

        let script = """
        (function() {
            try {
                // Try multiple selectors to find the name field
                let nameField = document.querySelector('input[id^=\"field\"]') ||
                              document.querySelector('input[name*=\"field2021\"]');

                console.log('[ODYSSEY] Name field found:', nameField ? {
                    type: nameField.type,
                    name: nameField.name,
                    id: nameField.id,
                    placeholder: nameField.placeholder,
                    className: nameField.className,
                    value: nameField.value,
                    parentText: nameField.parentElement ? nameField.parentElement.textContent.trim().substring(0, 100) : ''
                } : 'NOT FOUND');

                if (nameField) {
                    // Scroll to field with human-like behavior
                    nameField.scrollIntoView({ behavior: 'smooth', block: 'center' });

                    // Focus and clear
                    nameField.focus();
                    nameField.value = '';

                    // Simulate human-like typing with realistic events and delays
                    const value = '\(name)';
                    console.log('[ODYSSEY] Typing name:', value);

                    // Use a synchronous approach with setTimeout to simulate typing delays
                    const typeCharacter = (index) => {
                        if (index >= value.length) {
                            // Add natural delay before finishing
                            setTimeout(() => {
                                nameField.dispatchEvent(new Event('change', { bubbles: true }));
                                nameField.blur();
                                console.log('[ODYSSEY] Name field filled with:', nameField.value);
                            }, 200 + Math.random() * 300);
                            return;
                        }

                        // Simulate occasional typos (1.5% chance) - minimal for stealth
                        let charToType = value[index];
                        let shouldMakeTypo = Math.random() < 0.015 && index < value.length - 1;

                        if (shouldMakeTypo) {
                            // Type wrong character first
                            const wrongChars = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
                            const wrongChar = wrongChars[Math.floor(Math.random() * wrongChars.length)];
                            nameField.value += wrongChar;
                            nameField.dispatchEvent(new KeyboardEvent('keydown', {
                                bubbles: true,
                                key: wrongChar,
                                code: 'Key' + wrongChar.toUpperCase(),
                                keyCode: wrongChar.charCodeAt(0)
                            }));
                            nameField.dispatchEvent(new Event('input', { bubbles: true }));
                            nameField.dispatchEvent(new KeyboardEvent('keyup', {
                                bubbles: true,
                                key: wrongChar,
                                code: 'Key' + wrongChar.toUpperCase(),
                                keyCode: wrongChar.charCodeAt(0)
                            }));

                            // Wait before correcting
                            setTimeout(() => {
                                // Backspace
                                nameField.value = nameField.value.slice(0, -1);
                                nameField.dispatchEvent(new KeyboardEvent('keydown', {
                                    bubbles: true,
                                    key: 'Backspace',
                                    code: 'Backspace',
                                    keyCode: 8
                                }));
                                nameField.dispatchEvent(new Event('input', { bubbles: true }));
                                nameField.dispatchEvent(new KeyboardEvent('keyup', {
                                    bubbles: true,
                                    key: 'Backspace',
                                    code: 'Backspace',
                                    keyCode: 8
                                }));

                                // Type correct character
                                setTimeout(() => {
                                    nameField.value += charToType;
                                    nameField.dispatchEvent(new KeyboardEvent('keydown', {
                                        bubbles: true,
                                        key: charToType,
                                        code: 'Key' + charToType.toUpperCase(),
                                        keyCode: charToType.charCodeAt(0)
                                    }));
                                    nameField.dispatchEvent(new KeyboardEvent('keypress', {
                                        bubbles: true,
                                        key: charToType,
                                        code: 'Key' + charToType.toUpperCase(),
                                        keyCode: charToType.charCodeAt(0)
                                    }));
                                    nameField.dispatchEvent(new Event('input', { bubbles: true }));
                                    nameField.dispatchEvent(new KeyboardEvent('keyup', {
                                        bubbles: true,
                                        key: charToType,
                                        code: 'Key' + charToType.toUpperCase(),
                                        keyCode: charToType.charCodeAt(0)
                                    }));

                                    // Continue with next character
                                    setTimeout(() => typeCharacter(index + 1), 150 + Math.random() * 200);
                                }, 300 + Math.random() * 400);
                            }, 400 + Math.random() * 600);
                        } else {
                            // Normal typing with enhanced delays to avoid reCAPTCHA
                            nameField.value += charToType;
                            nameField.dispatchEvent(new KeyboardEvent('keydown', {
                                bubbles: true,
                                key: charToType,
                                code: 'Key' + charToType.toUpperCase(),
                                keyCode: charToType.charCodeAt(0)
                            }));
                            nameField.dispatchEvent(new KeyboardEvent('keypress', {
                                bubbles: true,
                                key: charToType,
                                code: 'Key' + charToType.toUpperCase(),
                                keyCode: charToType.charCodeAt(0)
                            }));
                            nameField.dispatchEvent(new Event('input', { bubbles: true }));
                            nameField.dispatchEvent(new KeyboardEvent('keyup', {
                                bubbles: true,
                                key: charToType,
                                code: 'Key' + charToType.toUpperCase(),
                                keyCode: charToType.charCodeAt(0)
                            }));

                            // Optimized human-like delay to avoid reCAPTCHA (95-190ms base)
                            const baseDelay = 95 + Math.random() * 95;
                            const extraDelay = Math.random() < 0.10 ? 160 + Math.random() * 220 : 0; // 10% chance of longer pause
                            const thinkingPause = Math.random() < 0.025 ? 280 + Math.random() * 380 : 0; // 2.5% chance of thinking pause
                            setTimeout(() => typeCharacter(index + 1), baseDelay + extraDelay + thinkingPause);
                        }
                    };

                    // Start typing after a natural delay
                    setTimeout(() => typeCharacter(0), 300 + Math.random() * 500);

                    return true;
                } else {
                    console.error('[ODYSSEY] Name field not found');
                    return false;
                }
            } catch (error) {
                console.error('[ODYSSEY] Error in fillName script:', error);
                return false;
            }
        })();
        """

        do {
            // Double-check that we are still connected before executing JavaScript
            guard isConnected else {
                logger.error("WebKit service is not connected before JavaScript execution")
                return false
            }

            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("✅ Successfully filled name with enhanced human-like behavior")
                // Optimized delay after filling to avoid reCAPTCHA (0.4-0.7 second)
                try? await Task.sleep(nanoseconds: UInt64.random(in: 400_000_000 ... 700_000_000))
                return true
            } else {
                logger.error("❌ Failed to fill name - field not found")
                return false
            }
        } catch {
            logger.error("❌ Error filling name: \(error.localizedDescription)")
            return false
        }
    }

    /// Detects if Google reCAPTCHA is present on the page
    public func detectCaptcha() async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        // Check for various reCAPTCHA indicators
        const recaptchaElements = document.querySelectorAll('.g-recaptcha, .recaptcha, iframe[src*="recaptcha"], [class*="recaptcha"], [id*="recaptcha"]');
        const googleRecaptcha = document.querySelectorAll('iframe[src*="google.com/recaptcha"], iframe[src*="gstatic.com/recaptcha"]');
        const captchaText = document.querySelectorAll('*:contains("captcha"), *:contains("robot"), *:contains("verify")');

        console.log('[ODYSSEY] reCAPTCHA detection:', {
            recaptchaElements: recaptchaElements.length,
            googleRecaptcha: googleRecaptcha.length,
            captchaText: captchaText.length
        });

        return recaptchaElements.length > 0 || googleRecaptcha.length > 0;
        """

        do {
            let result = try await executeScriptInternal(script)?.value as? Bool ?? false
            if result {
                logger.warning("⚠️ Google reCAPTCHA detected on page")
            } else {
                logger.info("🛡️ No reCAPTCHA detected")
            }
            return result
        } catch {
            logger.error("❌ Error detecting captcha: \(error.localizedDescription)")
            return false
        }
    }

    /// Handles reCAPTCHA by implementing human-like behavior and waiting
    public func handleCaptcha() async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        logger.info("🛡️ Handling reCAPTCHA with human-like behavior...")

        // Inject anti-detection scripts
        await injectAntiDetectionScript()

        // Simulate human-like behavior before captcha
        await simulateScrolling()
        await moveMouseRandomly()
        await addRandomDelay()
        return false
    }

    public func clickContactInfoConfirmButtonWithRetry() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Essential anti-detection before clicking
        logger.info("🛡️ Applying essential anti-detection before confirm button click")
        await addQuickPause()

        // Add human-like delay before clicking (1-1.5 seconds)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000 ... 1_500_000_000))

        let script = """
        (function() {
            try {
                // Comprehensive button detection strategy
                let button = null;

                // Strategy 1: Material Design ripple button
                button = document.querySelector('.mdc-button__ripple');

                // Strategy 2: Material Design button
                if (!button) {
                    button = document.querySelector('.mdc-button');
                }

                // Strategy 3: Submit button
                if (!button) {
                    button = document.querySelector('button[type="submit"]') || document.querySelector('input[type="submit"]');
                }

                // Strategy 4: Button with confirm text
                if (!button) {
                    const allButtons = Array.from(document.querySelectorAll('button'));
                    button = allButtons.find(btn => {
                        const text = (btn.textContent || '').toLowerCase();
                        return text.includes('confirm') || text.includes('submit') || text.includes('verify');
                    });
                }

                console.log('[ODYSSEY] Confirm button found:', button ? {
                    tagName: button.tagName,
                    className: button.className,
                    textContent: (button.textContent || '').trim(),
                    visible: !!(button.offsetWidth || button.offsetHeight || button.getClientRects().length)
                } : 'NOT FOUND');

                if (button) {
                    // Scroll to button with human-like behavior
                    button.scrollIntoView({ behavior: 'smooth', block: 'center' });

                    // Get button position for consistent coordinates
                    const rect = button.getBoundingClientRect();
                    const centerX = rect.left + rect.width / 2;
                    const centerY = rect.top + rect.height / 2;

                    // Simulate realistic mouse movement and hover
                    button.dispatchEvent(new MouseEvent('mouseenter', {
                        bubbles: true,
                        clientX: centerX,
                        clientY: centerY
                    }));

                    button.dispatchEvent(new MouseEvent('mouseover', {
                        bubbles: true,
                        clientX: centerX,
                        clientY: centerY
                    }));

                    // Click with human-like behavior
                    button.dispatchEvent(new MouseEvent('mousedown', {
                        bubbles: true,
                        button: 0,
                        clientX: centerX,
                        clientY: centerY
                    }));

                    button.dispatchEvent(new MouseEvent('mouseup', {
                        bubbles: true,
                        button: 0,
                        clientX: centerX,
                        clientY: centerY
                    }));

                    button.dispatchEvent(new MouseEvent('click', {
                        bubbles: true,
                        button: 0,
                        clientX: centerX,
                        clientY: centerY
                    }));

                    console.log('[ODYSSEY] Clicked confirm button with ultra-human-like behavior');
                    return true;
                }

                // Fallback: Try native click method
                if (button) {
                    try {
                        button.click();
                        console.log('[ODYSSEY] Used native click method as fallback');
                        return true;
                    } catch (e) {
                        console.log('[ODYSSEY] Native click failed:', e);
                    }
                }

                // Fallback to other common submit button selectors
                const fallbackButton = document.querySelector('button[type="submit"]') ||
                                      document.querySelector('input[type="submit"]') ||
                                      document.querySelector('button:contains("Confirm")');

                if (fallbackButton) {
                    console.log('[ODYSSEY] Using fallback confirm button:', fallbackButton.tagName);
                    fallbackButton.scrollIntoView({ behavior: 'smooth', block: 'center' });

                    // Immediate click with proper event sequence
                    fallbackButton.dispatchEvent(new MouseEvent('mousedown', {
                        bubbles: true,
                        button: 0,
                        clientX: fallbackButton.getBoundingClientRect().left + 10,
                        clientY: fallbackButton.getBoundingClientRect().top + 10
                    }));

                    fallbackButton.dispatchEvent(new MouseEvent('mouseup', {
                        bubbles: true,
                        button: 0,
                        clientX: fallbackButton.getBoundingClientRect().left + 10,
                        clientY: fallbackButton.getBoundingClientRect().top + 10
                    }));

                    fallbackButton.dispatchEvent(new MouseEvent('click', {
                        bubbles: true,
                        button: 0,
                        clientX: fallbackButton.getBoundingClientRect().left + 10,
                        clientY: fallbackButton.getBoundingClientRect().top + 10
                    }));

                    console.log('[ODYSSEY] Clicked fallback confirm button immediately');
                    return true;
                }

                return false;
            } catch (error) {
                console.error('[ODYSSEY] Error in confirm button click:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("✅ Successfully clicked contact info confirm button with human-like behavior")
                return true
            } else {
                logger.error("❌ Failed to click contact info confirm button")
                return false
            }
        } catch {
            logger.error("❌ Error clicking contact info confirm button: \(error.localizedDescription)")
            return false
        }
    }

    public func isEmailVerificationRequired() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Wait a bit for the page to load after clicking confirm
        try? await Task.sleep(nanoseconds: 3_000_000_000) // Wait 3 seconds

        let script = """
        (function() {
            // Check for verification-related elements
            const verificationElements = document.querySelectorAll('[class*="verification"], [id*="verification"], [class*="verify"], [id*="verify"]');

            // Check for verification code input fields
            const codeInputs = document.querySelectorAll('input[type="text"], input[type="number"], input[name*="verification"], input[name*="code"]');

            // Check for verification-related text in the page
            const bodyText = document.body.textContent || '';
            const hasVerificationText = bodyText.toLowerCase().includes('verification') ||
                                      bodyText.toLowerCase().includes('verify') ||
                                      bodyText.toLowerCase().includes('code') ||
                                      bodyText.toLowerCase().includes('enter it below');

            // Check for specific verification patterns
            const hasVerificationPattern = bodyText.toLowerCase().includes('verification code') ||
                                         bodyText.toLowerCase().includes('check your email') ||
                                         bodyText.toLowerCase().includes('receive an email');

            const result = verificationElements.length > 0 || codeInputs.length > 0 || hasVerificationText || hasVerificationPattern;

            console.log('[ODYSSEY] Verification check:', {
                verificationElements: verificationElements.length,
                codeInputs: codeInputs.length,
                hasVerificationText: hasVerificationText,
                hasVerificationPattern: hasVerificationPattern,
                result: result
            });

            return result;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("📧 Email verification required")
            } else {
                logger.info("🛡️ No email verification required")
            }
            return result
        } catch {
            logger.error("❌ Error checking email verification: \(error.localizedDescription)")
            return false
        }
    }

    public func handleEmailVerification(verificationStart: Date) async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        logger.info("🛡️ Instance \(self.instanceId): Handling email verification...")

        // Step 1: Wait for verification page to load
        await updateTask("Waiting for verification page...")
        let verificationPageReady = await waitForVerificationPage()
        if !verificationPageReady {
            logger.error("❌ Instance \(self.instanceId): Verification page failed to load")
            return false
        }

        // Step 2: Try verification codes with retry mechanism
        await updateTask("Trying verification codes with retry...")
        let verificationSuccess = await tryVerificationCodesWithRetry(verificationStart: verificationStart)
        if !verificationSuccess {
            logger.error("❌ Instance \(self.instanceId): All verification attempts failed")
            return false
        }

        logger.info("✅ Instance \(self.instanceId): Email verification completed successfully")
        return true
    }

    /// Waits for the verification page to load
    private func waitForVerificationPage() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let timeout: TimeInterval = 60 // 60 seconds
        let pollInterval: TimeInterval = 1.0
        let start = Date()

        logger.info("Waiting for verification page to load (timeout: \(timeout)s)")

        while Date().timeIntervalSince(start) < timeout {
            let script = """
            (function() {
                // Check for verification code input field
                const verificationInput = document.querySelector('input[type="text"]') ||
                                        document.querySelector('input[type="number"]') ||
                                        document.querySelector('input[name*="verification"]') ||
                                        document.querySelector('input[name*="code"]') ||
                                        document.querySelector('input[placeholder*="verification"]') ||
                                        document.querySelector('input[placeholder*="code"]') ||
                                        document.querySelector('input[id*="verification"]') ||
                                        document.querySelector('input[id*="code"]');

                // Check for verification-related text
                const bodyText = document.body.textContent || '';
                const hasVerificationText = bodyText.toLowerCase().includes('verification') ||
                                        bodyText.toLowerCase().includes('verify') ||
                                        bodyText.toLowerCase().includes('code') ||
                                        bodyText.toLowerCase().includes('enter it below');

                // Check for specific verification patterns
                const hasVerificationPattern = bodyText.toLowerCase().includes('verification code') ||
                                            bodyText.toLowerCase().includes('check your email') ||
                                            bodyText.toLowerCase().includes('receive an email');

                // Check for loading states
                const isLoading = bodyText.toLowerCase().includes('loading') ||
                                bodyText.toLowerCase().includes('please wait') ||
                                document.querySelector('[class*="loading"], [id*="loading"]');

                const result = {
                    hasInput: !!verificationInput,
                    hasText: hasVerificationText,
                    hasPattern: hasVerificationPattern,
                    isLoading: !!isLoading,
                    inputType: verificationInput ? verificationInput.type : null,
                    inputName: verificationInput ? verificationInput.name : null,
                    inputPlaceholder: verificationInput ? verificationInput.placeholder : null,
                    bodyTextPreview: bodyText.substring(0, 200) + '...'
                };

                console.log('[ODYSSEY] Verification page check:', result);
                return result;
            })();
            """

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
                    logger.info("Page content preview: \(bodyTextPreview)")

                    if hasInput || hasText || hasPattern {
                        logger.info("✅ Verification page detected successfully")
                        return true
                    }

                    if isLoading {
                        logger.info("⏳ Page is still loading, waiting...")
                    }
                }
            } catch {
                logger.error("❌ Error checking verification page: \(error.localizedDescription)")
            }

            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        logger.error("❌ Verification page load timeout after \(timeout) seconds")
        return false
    }

    /// Fetches verification code from email using IMAP
    private func fetchVerificationCodeFromEmail(verificationStart: Date) async -> String {
        logger.info("📧 Fetching verification code from email...")

        // Initial wait before checking for the email
        let initialWait: TimeInterval = 10.0 // 10 seconds
        let maxTotalWait: TimeInterval = 300.0 // 5 minutes
        let retryDelay: TimeInterval = 2.0 // 2 seconds
        let deadline = Date().addingTimeInterval(maxTotalWait)
        let emailService = EmailService.shared

        // Wait for the initial period
        logger.info("Waiting \(initialWait)s before starting email verification checks...")
        try? await Task.sleep(nanoseconds: UInt64(initialWait * 1_000_000_000))

        while Date() < deadline {
            // Fetch verification codes using the correct method
            let codes = await emailService.fetchVerificationCodesForToday(since: verificationStart)
            if let code = codes.first {
                logger.info("✅ Found verification email, parsed code: \(code)")
                return code
            }
            logger.info("⏳ Verification code not found yet, retrying in \(retryDelay)s...")
            try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
        }
        logger.error("❌ Timed out waiting for verification code after \(maxTotalWait)s")
        return ""
    }

    /// Parses 4-digit verification code from email body
    private func parseVerificationCode(from emailBody: String) -> String {
        // Look for pattern: "Your verification code is: XXXX."
        let pattern = #"Your verification code is:\s*(\d{4})\s*\."#

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: emailBody.utf16.count)
            if let match = regex.firstMatch(in: emailBody, options: [], range: range) {
                let codeRange = match.range(at: 1)
                if let range = Range(codeRange, in: emailBody) {
                    let code = String(emailBody[range])
                    logger.info("🔍 Parsed verification code: \(code, privacy: .private)")
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
                    logger.info("🔍 Parsed verification code (fallback): \(code, privacy: .private)")
                    return code
                }
            }
        }

        logger.error("❌ Could not parse verification code from email body")
        return ""
    }

    /// Fetches all verification codes from email using IMAP
    private func fetchAllVerificationCodesFromEmail(verificationStart: Date) async -> [String] {
        logger.info("📧 Fetching all verification codes from email for instance: \(self.instanceId)")

        // Initial wait before checking for the email
        let initialWait: TimeInterval = 10.0 // 10 seconds
        let maxTotalWait: TimeInterval = 300.0 // 5 minutes
        let retryDelay: TimeInterval = 2.0 // 2 seconds
        let deadline = Date().addingTimeInterval(maxTotalWait)

        // Use shared email service but with instance-specific logging and timing
        let emailService = EmailService.shared
        logger.info("📧 Using EmailService for WebKit instance: \(self.instanceId)")

        // Wait for the initial period
        logger
            .info(
                "Waiting \(initialWait)s before starting email verification checks for instance: \(self.instanceId)...",
                )
        try? await Task.sleep(nanoseconds: UInt64(initialWait * 1_000_000_000))

        while Date() < deadline {
            // Try both shared code pool and direct email fetching as fallback
            var codes: [String] = []

            // First try shared code pool
            codes = await emailService.fetchAndConsumeVerificationCodes(
                since: verificationStart,
                instanceId: self.instanceId,
                )

            // If shared pool is empty, try direct email fetching as fallback
            if codes.isEmpty {
                logger.info("📧 Instance \(self.instanceId): Shared code pool empty, trying direct email fetch...")
                codes = await emailService.fetchVerificationCodesForToday(since: verificationStart)

                if !codes.isEmpty {
                    logger.info("📧 Instance \(self.instanceId): Direct email fetch found \(codes.count) codes")
                }
            }

            // If still empty, try with a broader time window for the second instance
            if codes.isEmpty {
                logger.info("📧 Instance \(self.instanceId): Still no codes, trying with broader time window...")
                let broaderStart = verificationStart.addingTimeInterval(-300) // 5 minutes earlier
                codes = await emailService.fetchVerificationCodesForToday(since: broaderStart)

                if !codes.isEmpty {
                    logger.info("📧 Instance \(self.instanceId): Broader search found \(codes.count) codes")
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
                .info("Instance \(self.instanceId): No verification codes available yet, retrying in \(retryDelay)s...")
            try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
        }
        logger.error("❌ Instance \(self.instanceId): Timed out waiting for verification codes after \(maxTotalWait)s")
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
            // Validate code: must be 4 digits and not '0000'
            if code.count != 4 || !code.allSatisfy(\.isNumber) || code == "0000" {
                logger.warning("Instance \(self.instanceId): Skipping invalid code: \(code)")

                continue
            }
            if !codes.contains(code) {
                logger
                    .warning("Instance \(self.instanceId): Code \(code) not in extracted set for this round, skipping.")

                continue
            }
            logger
                .info(
                    "Instance \(self.instanceId): Trying verification code \(index + 1)/\(codes.count): \(String(repeating: "*", count: code.count))",
                    )
            await updateTask("Trying verification code \(index + 1)/\(codes.count)...")
            let fillSuccess = await fillVerificationCode(code)
            if !fillSuccess {
                logger.warning("Instance \(self.instanceId): Failed to fill verification code \(index + 1)")

                continue
            }
            await updateTask("Waiting for form to process verification code...")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            logger.info("Instance \(self.instanceId): Finished waiting for form to process verification code")
            let clickSuccess = await clickVerificationSubmitButton()
            if !clickSuccess {
                logger
                    .warning(
                        "Instance \(self.instanceId): Failed to click verification submit button for code \(index + 1)",
                        )

                continue
            }
            await updateTask("Waiting for verification response...")
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            logger.info("Instance \(self.instanceId): Finished waiting for verification response")
            logger.info("🔍 Instance \(self.instanceId): Checking verification result for code \(index + 1)...")
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

                return true // TERMINATE IMMEDIATELY ON SUCCESS OR TERMINAL STATE
            }
            logger.warning("Instance \(self.instanceId): ❌ Verification code \(index + 1) was rejected")
            let stillOnVerificationPage = await checkIfStillOnVerificationPage()
            if stillOnVerificationPage {
                logger.info("Instance \(self.instanceId): Still on verification page - continuing to next code...")
                await clearVerificationInput()

                continue
            } else {
                logger
                    .info(
                        "Instance \(self.instanceId): Moved away from verification page - likely success or different error",
                        )
                let finalCheck = await checkVerificationSuccess()
                if finalCheck {
                    logger.info("Instance \(self.instanceId): ✅ Final check confirms verification success!")
                    await emailService.markCodeAsConsumed(code, byInstanceId: self.instanceId)

                    return true
                }
                logger.warning("Instance \(self.instanceId): Final check failed, continuing to next code...")

                continue
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
        logger.info("Instance \(self.instanceId): Starting verification with retry mechanism")
        let maxRetryAttempts = 3
        var retryCount = 0
        while retryCount < maxRetryAttempts {
            logger.info("Instance \(self.instanceId): Retry attempt \(retryCount + 1)/\(maxRetryAttempts)")
            await updateTask("Fetching verification codes (attempt \(retryCount + 1)/\(maxRetryAttempts))...")
            let verificationCodes = await fetchAllVerificationCodesFromEmail(verificationStart: verificationStart)
            logger.info("Instance \(self.instanceId): Codes fetched for this round: \(verificationCodes)")
            if verificationCodes.isEmpty {
                logger.warning("Instance \(self.instanceId): No verification codes found in attempt \(retryCount + 1)")
                retryCount += 1
                if retryCount < maxRetryAttempts {
                    logger.info("Instance \(self.instanceId): Waiting 3 seconds before retry...")
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                }
                continue
            }
            logger
                .info(
                    "Instance \(self.instanceId): Retrieved \(verificationCodes.count) verification codes for attempt \(retryCount + 1)",
                    )
            await updateTask("Trying verification codes (attempt \(retryCount + 1)/\(maxRetryAttempts))...")
            let verificationSuccess = await tryVerificationCodes(verificationCodes)
            if verificationSuccess {
                logger.info("Instance \(self.instanceId): ✅ Verification successful on attempt \(retryCount + 1)")
                return true
            } else {
                logger.warning("Instance \(self.instanceId): ❌ Verification failed on attempt \(retryCount + 1)")
                retryCount += 1
                if retryCount < maxRetryAttempts {
                    logger.info("Instance \(self.instanceId): Waiting 3 seconds before next retry...")
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                }
            }
        }
        // Final fallback: try direct fetch from email ignoring code pool
        logger.error("Instance \(self.instanceId): All retry attempts failed. Trying final direct fetch from email.")
        let directCodes = await EmailService.shared.fetchVerificationCodesForToday(since: verificationStart)
        logger.info("Instance \(self.instanceId): Codes fetched for final direct fetch: \(directCodes)")
        if !directCodes.isEmpty {
            logger
                .info("Instance \(self.instanceId): Final direct fetch found \(directCodes.count) codes. Trying them.")
            let verificationSuccess = await tryVerificationCodes(directCodes)
            if verificationSuccess {
                logger.info("Instance \(self.instanceId): ✅ Verification successful on final direct fetch.")
                return true
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
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            try {
                const bodyText = document.body.textContent || '';
                const bodyTextLower = bodyText.toLowerCase();


                console.log('[ODYSSEY] Checking verification result. Page content preview:', bodyText.substring(0, 1000));

                // Check for robust confirmation page indicators
                // 1. .confirmed-reservation class
                if (document.querySelector('.confirmed-reservation')) {
                  console.log('[ODYSSEY] Found .confirmed-reservation class - success!');
                  return { success: true, reason: 'confirmed_reservation_class', pageText: bodyText.substring(0, 1000) };
                }
                // 2. <h1>Confirmation</h1>
                const h1s = Array.from(document.querySelectorAll('h1'));
                if (h1s.some(h => h.textContent.trim().toLowerCase() === 'confirmation')) {
                  console.log('[ODYSSEY] Found <h1>Confirmation</h1> - success!');
                  return { success: true, reason: 'h1_confirmation', pageText: bodyText.substring(0, 1000) };
                }
                // 3. <p> containing 'is now confirmed'
                const ps = Array.from(document.querySelectorAll('p'));
                if (ps.some(p => p.textContent.toLowerCase().includes('is now confirmed'))) {
                  console.log('[ODYSSEY] Found <p> with \"is now confirmed\" - success!');
                  return { success: true, reason: 'p_is_now_confirmed', pageText: bodyText.substring(0, 1000) };
                }

                // Check for error indicators FIRST
                const errorIndicators = [
                    'invalid code',
                    'incorrect code',
                    'verification failed',
                    'code not found',
                    'try again',
                    'error',
                    'failed',
                    'invalid',
                    'the confirmation code is incorrect',
                    'incorrect confirmation code',
                    'verification code is incorrect',
                    'please try again',
                    'wrong code',
                    'code is incorrect'
                ];
                for (const indicator of errorIndicators) {
                    if (bodyTextLower.includes(indicator)) {
                        console.log('[ODYSSEY] Found error indicator:', indicator);
                        return { success: false, reason: indicator, pageText: bodyText.substring(0, 1000) };
                    }
                }

                // Check for success indicators
                const successIndicators = [
                  'confirmation',
                  'is now confirmed',
                  'your appointment on',
                  'your appointment is now confirmed',
                  'now confirmed',
                  'reservation confirmed',
                  'booking confirmed',
                  'successfully booked',
                  'thank you for your reservation',
                  'your reservation is confirmed',
                  'your booking is confirmed',
                  'your spot is confirmed',
                  'your registration is confirmed',
                  'your registration was successful',
                  'success!',
                  'completed successfully',
                  // Add more as needed based on confirmation page text
                ];
                for (const indicator of successIndicators) {
                  if (bodyTextLower.includes(indicator)) {
                    console.log('[ODYSSEY] Found success indicator:', indicator);
                    return { success: true, reason: indicator, pageText: bodyText.substring(0, 1000) };
                  }
                }

                // Check if we're still on the verification page (indicates failure)
                const verificationInput = document.querySelector('input[type=\"text\"]') ||
                                        document.querySelector('input[type=\"number\"]') ||
                                        document.querySelector('input[name*=\"code\"]') ||
                                        document.querySelector('input[placeholder*=\"code\"]');

                // If the verification input is present but the confirmation text is also present, treat as success
                if (verificationInput) {
                  for (const indicator of successIndicators) {
                    if (bodyTextLower.includes(indicator)) {
                      console.log('[ODYSSEY] Found success indicator with input present:', indicator);
                      return { success: true, reason: indicator + '_with_input', pageText: bodyText.substring(0, 1000) };
                    }
                  }
                  console.log('[ODYSSEY] Still on verification page - likely failed');
                  return { success: false, reason: 'still_on_verification_page', pageText: bodyText.substring(0, 1000) };
                }

                // If the verification input is gone and no error indicators, treat as success/terminal state
                console.log('[ODYSSEY] No verification input found - treating as success/terminal state');
                return { success: true, reason: 'no_verification_input', pageText: bodyText.substring(0, 1000) };
            } catch (error) {
                console.error('[ODYSSEY] Error checking verification success:', error);
                return { success: false, reason: 'error_checking', pageText: '' };
            }
        })();
        """

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
                    logger.info("Instance \(self.instanceId): 🎉 SUCCESS detected - reason: \(reason)")
                } else {
                    logger.info("Instance \(self.instanceId): ❌ FAILURE detected - reason: \(reason)")
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

        logger.error("Instance \(self.instanceId): Defaulting to FAILURE due to error or parsing issue")
        return false
    }

    /// Checks if we're still on the verification page
    private func checkIfStillOnVerificationPage() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            try {
                // Check for verification code input field
                const verificationInput = document.querySelector('input[type="text"]') ||
                                        document.querySelector('input[type="number"]') ||
                                        document.querySelector('input[name*="code"]') ||
                                        document.querySelector('input[placeholder*="code"]');

                // Check for verification-related text
                const bodyText = document.body.textContent || '';
                const hasVerificationText = bodyText.toLowerCase().includes('verification') ||
                                        bodyText.toLowerCase().includes('verify') ||
                                        bodyText.toLowerCase().includes('code') ||
                                        bodyText.toLowerCase().includes('enter it below');

                const result = !!verificationInput || hasVerificationText;
                console.log('[ODYSSEY] Still on verification page check:', {
                    hasInput: !!verificationInput,
                    hasText: hasVerificationText,
                    result: result
                });
                return result;
            } catch (error) {
                console.error('[ODYSSEY] Error checking if still on verification page:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            logger.info("Instance \(self.instanceId): Still on verification page: \(result)")
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
            logger.error("WebView not initialized")
            return
        }

        let script = """
        (function() {
            try {
                const verificationInput = document.querySelector('input[type="text"]') ||
                                        document.querySelector('input[type="number"]') ||
                                        document.querySelector('input[name*="code"]') ||
                                        document.querySelector('input[placeholder*="code"]');

                if (verificationInput) {
                    verificationInput.value = '';
                    verificationInput.dispatchEvent(new Event('input', { bubbles: true }));
                    verificationInput.dispatchEvent(new Event('change', { bubbles: true }));
                    console.log('[ODYSSEY] Cleared verification input field');
                }
            } catch (error) {
                console.error('[ODYSSEY] Error clearing verification input:', error);
            }
        })();
        """

        do {
            _ = try await webView.evaluateJavaScript(script)
            logger.info("Instance \(self.instanceId): Cleared verification input field")
        } catch {
            logger
                .error("Instance \(self.instanceId): Error clearing verification input: \(error.localizedDescription)")
        }
    }

    /// Fills verification code into the input field using browser autofill behavior
    private func fillVerificationCode(_ code: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            try {
                // Find verification code input field
                const verificationInput = document.querySelector('input[type="text"]') ||
                                        document.querySelector('input[type="number"]') ||
                                        document.querySelector('input[name*="code"]') ||
                                        document.querySelector('input[placeholder*="code"]');

                if (verificationInput) {
                    // Browser autofill behavior: scroll into view
                    verificationInput.scrollIntoView({ behavior: 'auto', block: 'center' });

                    // Focus and clear
                    verificationInput.focus();
                    verificationInput.value = '';

                    // Autofill-style: set value instantly
                    verificationInput.value = '\(code)';

                    // Dispatch autofill events
                    verificationInput.dispatchEvent(new Event('input', { bubbles: true }));
                    verificationInput.dispatchEvent(new Event('change', { bubbles: true }));
                    verificationInput.dispatchEvent(new Event('autocomplete', { bubbles: true }));

                    // Blur (browser autofill behavior)
                    verificationInput.blur();

                    console.log('[ODYSSEY] Verification code autofill completed with:', verificationInput.value);
                    return true;
                } else {
                    console.log('[ODYSSEY] Verification input field not found');
                    return false;
                }
            } catch (error) {
                console.error('[ODYSSEY] Error filling verification code with autofill:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Instance \(self.instanceId): Successfully filled verification code with autofill behavior")
                // Minimal delay after autofill
                try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000 ... 300_000_000))
                return true
            } else {
                logger.error("Instance \(self.instanceId): Failed to fill verification code with autofill")
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
        logger.info("Task: \(task)")
    }

    /// Clicks the submit button for verification
    private func clickVerificationSubmitButton() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }
        let maxAttempts = 10
        for attempt in 1 ... maxAttempts {
            do {
                let script = """
                (function() {
                    // --- ODYSSEY PATCH: Always check for Final Confirmation button after verification submit ---
                    var finalBtn = document.querySelector('#submit-btn');
                    if (finalBtn && (finalBtn.innerText || '').toLowerCase().includes('final confirmation')) {
                        try {
                            finalBtn.click();
                            console.log('[ODYSSEY] Clicked Final Confirmation button (id=submit-btn)');
                            return '[ODYSSEY] Clicked Final Confirmation button (id=submit-btn)';
                        } catch (e) {
                            console.log('[ODYSSEY] Failed to click Final Confirmation button:', e);
                        }
                    }
                    // --- END PATCH ---
                    console.log('[ODYSSEY] Starting button detection...');

                    const allButtons = document.querySelectorAll('button, input[type="submit"], a');
                    console.log('[ODYSSEY] Found', allButtons.length, 'total buttons/inputs');

                    for (let i = 0; i < allButtons.length; i++) {
                        const btn = allButtons[i];
                        const text = (btn.textContent || '').trim();
                        const ariaLabel = btn.getAttribute('aria-label') || '';
                        const title = btn.getAttribute('title') || '';
                        const className = btn.className || '';
                        const id = btn.id || '';
                        const isVisible = btn.offsetParent !== null;
                        const isEnabled = !btn.disabled;

                        console.log('[ODYSSEY] Button', i, ':', {
                            text: text,
                            ariaLabel: ariaLabel,
                            title: title,
                            className: className,
                            id: id,
                            visible: isVisible,
                            enabled: isEnabled,
                            tagName: btn.tagName
                        });
                    }

                    // Try to find the ripple element
                    const ripple = document.querySelector('.mdc-button__ripple');
                    if (ripple) {
                        console.log('[ODYSSEY] Found ripple element');
                        // Try to click the parent button
                        let parent = ripple.closest('button');
                        if (parent) {
                            console.log('[ODYSSEY] Found parent button of ripple element');
                            // Try MouseEvent first
                            try {
                                const rect = parent.getBoundingClientRect();
                                const event = new MouseEvent('click', {
                                    view: window,
                                    bubbles: true,
                                    cancelable: true,
                                    clientX: rect.left + rect.width / 2,
                                    clientY: rect.top + rect.height / 2
                                });
                                parent.dispatchEvent(event);
                                console.log('[ODYSSEY] Clicked parent button via MouseEvent');
                                return '[ODYSSEY] Clicked parent button via MouseEvent';
                            } catch (e) {
                                console.log('[ODYSSEY] MouseEvent failed, trying .click()');
                                try {
                                    parent.click();
                                    console.log('[ODYSSEY] Clicked parent button via .click()');
                                    return '[ODYSSEY] Clicked parent button via .click()';
                                } catch (e2) {
                                    console.log('[ODYSSEY] .click() also failed');
                                }
                            }
                        }

                        // Fallback: try clicking the ripple itself
                        try {
                            const rect = ripple.getBoundingClientRect();
                            const event = new MouseEvent('click', {
                                view: window,
                                bubbles: true,
                                cancelable: true,
                                clientX: rect.left + rect.width / 2,
                                clientY: rect.top + rect.height / 2
                            });
                            ripple.dispatchEvent(event);
                            console.log('[ODYSSEY] Clicked ripple element via MouseEvent');
                            return '[ODYSSEY] Clicked ripple element via MouseEvent';
                        } catch (e) {
                            console.log('[ODYSSEY] Ripple click failed');
                        }
                    } else {
                        console.log('[ODYSSEY] No ripple element found');
                    }

                    // Look for Material Design buttons by class
                    const mdcButtons = document.querySelectorAll('.mdc-button, [class*="mdc-button"]');
                    console.log('[ODYSSEY] Found', mdcButtons.length, 'Material Design buttons');

                    for (const btn of mdcButtons) {
                        if (btn.offsetParent !== null && !btn.disabled) {
                            const text = (btn.textContent || '').trim().toLowerCase();
                            console.log('[ODYSSEY] Checking MDC button:', text);

                            if (text.includes('confirm') || text.includes('submit') || text.includes('verify')) {
                                console.log('[ODYSSEY] Found matching MDC button:', text);
                                try {
                                    const rect = btn.getBoundingClientRect();
                                    const event = new MouseEvent('click', {
                                        view: window,
                                        bubbles: true,
                                        cancelable: true,
                                        clientX: rect.left + rect.width / 2,
                                        clientY: rect.top + rect.height / 2
                                    });
                                    btn.dispatchEvent(event);
                                    console.log('[ODYSSEY] Clicked MDC button via MouseEvent:', text);
                                    return '[ODYSSEY] Clicked MDC button via MouseEvent: ' + text;
                                } catch (e) {
                                    console.log('[ODYSSEY] MouseEvent failed for MDC button:', text);
                                    try {
                                        btn.click();
                                        console.log('[ODYSSEY] Clicked MDC button via .click():', text);
                                        return '[ODYSSEY] Clicked MDC button via .click(): ' + text;
                                    } catch (e2) {
                                        console.log('[ODYSSEY] .click() also failed for MDC button:', text);
                                    }
                                }
                            }
                        }
                    }

                    // Fallback: find all visible buttons and look for submit/verify/confirm/continue text
                    const submitKeywords = ['confirm'];

                    for (const btn of allButtons) {
                        if (btn.offsetParent !== null && !btn.disabled) { // visible and enabled
                            const text = (btn.textContent || '').trim().toLowerCase();
                            const ariaLabel = (btn.getAttribute('aria-label') || '').toLowerCase();
                            const title = (btn.getAttribute('title') || '').toLowerCase();

                            console.log('[ODYSSEY] Checking button:', text, 'aria-label:', ariaLabel, 'title:', title);

                            // Check for partial matches with submit keywords in text, aria-label, or title
                            for (const keyword of submitKeywords) {
                                if (text.includes(keyword) || ariaLabel.includes(keyword) || title.includes(keyword)) {
                                    console.log('[ODYSSEY] Found matching button with keyword:', keyword);
                                    try {
                                        const rect = btn.getBoundingClientRect();
                                        const event = new MouseEvent('click', {
                                            view: window,
                                            bubbles: true,
                                            cancelable: true,
                                            clientX: rect.left + rect.width / 2,
                                            clientY: rect.top + rect.height / 2
                                        });
                                        btn.dispatchEvent(event);
                                        console.log('[ODYSSEY] Clicked button via MouseEvent:', text);
                                        return '[ODYSSEY] Clicked button via MouseEvent: ' + text;
                                    } catch (e) {
                                        console.log('[ODYSSEY] MouseEvent failed for button:', text);
                                        try {
                                            btn.click();
                                            console.log('[ODYSSEY] Clicked button via .click():', text);
                                            return '[ODYSSEY] Clicked button via .click(): ' + text;
                                        } catch (e2) {
                                            console.log('[ODYSSEY] .click() also failed for button:', text);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Last resort: try clicking the last visible button (often the submit button)
                    const visibleButtons = Array.from(allButtons).filter(btn =>
                        btn.offsetParent !== null && !btn.disabled
                    );

                    if (visibleButtons.length > 0) {
                        const lastButton = visibleButtons[visibleButtons.length - 1];
                        const text = (lastButton.textContent || '').trim();
                        console.log('[ODYSSEY] Trying last visible button:', text);

                        try {
                            const rect = lastButton.getBoundingClientRect();
                            const event = new MouseEvent('click', {
                                view: window,
                                bubbles: true,
                                cancelable: true,
                                clientX: rect.left + rect.width / 2,
                                clientY: rect.top + rect.height / 2
                            });
                            lastButton.dispatchEvent(event);
                            console.log('[ODYSSEY] Clicked last visible button via MouseEvent:', text);
                            return '[ODYSSEY] Clicked last visible button via MouseEvent: ' + text;
                        } catch (e) {
                            console.log('[ODYSSEY] MouseEvent failed for last button:', text);
                            try {
                                lastButton.click();
                                console.log('[ODYSSEY] Clicked last visible button via .click():', text);
                                return '[ODYSSEY] Clicked last visible button via .click(): ' + text;
                            } catch (e2) {
                                console.log('[ODYSSEY] .click() also failed for last button:', text);
                            }
                        }
                    }

                    console.log('[ODYSSEY] No suitable button found');
                    return '[ODYSSEY] No suitable button found';
                })();
                """
                let result = try await webView
                    .evaluateJavaScript(script) as? String ??
                    "[ODYSSEY] No result from clickVerificationSubmitButton script"
                if result.contains("Clicked Final Confirmation button") || result.contains("Clicked") {
                    logger.info("✅ [ConfirmClick] Success on attempt \(attempt): \(result)")
                    return true
                } else {
                    logger.info("🔄 [ConfirmClick] Attempt \(attempt) did not find/click button: \(result)")
                }
            } catch {
                logger
                    .error("Error in clickVerificationSubmitButton (attempt \(attempt)): \(error.localizedDescription)")
            }
            // Wait 0.5s before next attempt
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        logger.error("❌ [ConfirmClick] Failed to click Final Confirmation button after \(maxAttempts) attempts")
        return false
    }

    /// Detects if "Retry" text appears on the page (indicating reCAPTCHA failure)
    public func detectRetryText() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            // Check for "Retry" text in various contexts
            const bodyText = document.body.textContent || '';
            const retryIndicators = [
                'Retry',
            ];

            const hasRetryText = retryIndicators.some(indicator =>
                bodyText.toLowerCase().includes(indicator.toLowerCase())
            );

            // Also check for specific retry buttons
            const retryButtons = document.querySelectorAll('button, input[type="submit"], a');
            const hasRetryButton = Array.from(retryButtons).some(btn => {
                const text = (btn.textContent || '').toLowerCase();
                return retryIndicators.some(indicator => text.includes(indicator.toLowerCase()));
            });

            return hasRetryText || hasRetryButton;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.warning("⚠️ Retry text detected - reCAPTCHA likely failed")
            }
            return result
        } catch {
            logger.error("❌ Error detecting retry text: \(error.localizedDescription)")
            return false
        }
    }

    /// Enhanced human-like behavior to avoid reCAPTCHA detection
    public func enhanceHumanLikeBehavior() async {
        guard let webView else { return }

        logger.info("🛡️ Enhancing human-like behavior to avoid reCAPTCHA detection...")

        // Inject simplified anti-detection scripts (less likely to cause errors)
        let antiDetectionScript = """
        (function() {
            try {
                // Simple overrides that are less likely to cause errors
                if (navigator.webdriver !== undefined) {
                    Object.defineProperty(navigator, 'webdriver', {
                        get: () => undefined,
                        configurable: true
                    });
                }

                        // Remove common automation indicators.
        if (window.cdc_adoQpoasnfa76pfcZLmcfl_Array) {
            delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array;
        }
                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Promise) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise;
                }
                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol;
                }

                // Add basic mouse movement tracking
                if (!window.odysseyMouseMovements) {
                    window.odysseyMouseMovements = [];
                }

                console.log('[ODYSSEY] Basic anti-detection measures applied');
            } catch (error) {
                console.error('[ODYSSEY] Error in anti-detection script:', error);
            }
        })();
        """

        do {
            _ = try await webView.evaluateJavaScript(antiDetectionScript)
            logger.info("Basic anti-detection measures applied successfully")
        } catch {
            logger.error("❌ Failed to apply anti-detection measures: \(error.localizedDescription)")
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
        try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000 ... 300_000_000))

        let script = """
        (function() {
            try {
                // Simulate a quick mouse movement
                const event = new MouseEvent('mousemove', {
                    bubbles: true,
                    cancelable: true,
                    clientX: 200 + Math.random() * 100,
                    clientY: 150 + Math.random() * 100
                });
                document.dispatchEvent(event);
            } catch (error) {
                console.error('[ODYSSEY] Error in mouse movement:', error);
            }
        })();
        """

        do {
            _ = try await webView.evaluateJavaScript(script)
        } catch {
            logger.error("❌ Error simulating mouse movement: \(error.localizedDescription)")
        }
    }

    /// Simulates quick realistic scrolling
    public func simulateQuickScrolling() async {
        guard let webView else { return }

        // Much faster scrolling (0.1-0.2s)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000 ... 200_000_000))

        let script = """
        (function() {
            try {
                // Simulate a quick scroll
                window.scrollBy({
                    top: Math.random() * 50 - 25,
                    left: 0,
                    behavior: 'smooth'
                });
            } catch (error) {
                console.error('[ODYSSEY] Error in scrolling:', error);
            }
        })();
        """

        do {
            _ = try await webView.evaluateJavaScript(script)
        } catch {
            logger.error("❌ Error simulating scrolling: \(error.localizedDescription)")
        }
    }

    /// Adds a quick pause (0.1-0.3s)
    public func addQuickPause() async {
        try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000 ... 300_000_000))
    }

    /// Adds natural pauses to simulate human thinking/reading
    public func addNaturalPauses() async {
        // Much shorter pauses (0.2-0.5s)
        let pauseDuration = UInt64.random(in: 200_000_000 ... 500_000_000)
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
        logger.info("Starting WebView cleanup...")
        scriptCompletions.removeAll()
        elementCompletions.removeAll()
        // Safely cleanup WebView if it exists
        if let webView {
            logger.info("Cleaning up existing WebView...")
            await MainActor.run {
                webView.configuration.userContentController.removeScriptMessageHandler(forName: "odysseyHandler")
                webView.navigationDelegate = nil
                webView.stopLoading()
            }
        } else {
            logger.info("No WebView to cleanup")
        }
        // Clear webView reference
        await MainActor.run {
            self.webView = nil
        }
        logger.info("WebKitService cleanup completed")
    }

    // MARK: - NSWindowDelegate

    public func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === debugWindow else {
            return
        }

        logger.info("🪟 Browser window closed by user - resetting WebKit service state")

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

                logger.info("🪟 WebKit service state reset after manual window closure")
            }

            // Notify ReservationManager about window closure
            if let onWindowClosed = self.onWindowClosed {
                onWindowClosed(.manual)
            }
        }
    }

    // MARK: - Browser Autofill Methods (Less Likely to Trigger Captchas)

    /// Fills form fields using browser autofill behavior instead of human typing
    /// This mimics how browsers fill forms when users click autofill suggestions
    public func fillFieldWithAutofill(selector: String, value: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            try {
                const field = document.querySelector('\(selector)');
                if (!field) {
                    console.log('[ODYSSEY] Field not found for selector: \(selector)');
                    return false;
                }

                // Scroll field into view (browser autofill behavior)
                field.scrollIntoView({ behavior: 'auto', block: 'center' });

                // Focus the field (browser autofill behavior)
                field.focus();

                // Clear existing value
                field.value = '';

                // Simulate browser autofill: set value instantly and dispatch events
                // This mimics how browsers fill forms when users click autofill suggestions
                field.value = '\(value)';

                // Dispatch events that browsers trigger during autofill
                field.dispatchEvent(new Event('input', { bubbles: true }));
                field.dispatchEvent(new Event('change', { bubbles: true }));

                // Trigger autocomplete event (common in autofill scenarios)
                field.dispatchEvent(new Event('autocomplete', { bubbles: true }));

                // Blur the field (browser autofill behavior)
                field.blur();

                console.log('[ODYSSEY] Autofill-style field filling completed for: \(selector)');
                return true;

            } catch (error) {
                console.error('[ODYSSEY] Error in autofill field filling:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Successfully filled field with autofill behavior: \(selector)")
                // Minimal delay after autofill (browsers don't wait long after autofill)
                try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000 ... 300_000_000))
                return true
            } else {
                logger.error("Failed to fill field with autofill behavior: \(selector)")
                return false
            }
        } catch {
            logger.error("Error filling field with autofill behavior: \(error.localizedDescription)")
            return false
        }
    }

    /// Fills phone number using browser autofill behavior
    public func fillPhoneNumberWithAutofill(_ phoneNumber: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            try {
                // Try multiple selectors to find the phone field
                let phoneField = document.getElementById('phone') ||
                               document.getElementById('telephone') ||
                               document.getElementById('phoneNumber') ||
                               document.querySelector('input[type="tel"]') ||
                               document.querySelector('input[name*="phone"]') ||
                               document.querySelector('input[name*="tel"]') ||
                               document.querySelector('input[placeholder*="phone"]') ||
                               document.querySelector('input[placeholder*="tel"]') ||
                               document.querySelector('input[placeholder*="Phone"]') ||
                               document.querySelector('input[placeholder*="Telephone"]');

                console.log('[ODYSSEY] Phone field found for autofill:', phoneField ? {
                    type: phoneField.type,
                    name: phoneField.name,
                    id: phoneField.id,
                    placeholder: phoneField.placeholder
                } : 'NOT FOUND');

                if (phoneField) {
                    // Browser autofill behavior: scroll into view
                    phoneField.scrollIntoView({ behavior: 'auto', block: 'center' });

                    // Focus and clear
                    phoneField.focus();
                    phoneField.value = '';

                    // Autofill-style: set value instantly
                    phoneField.value = '\(phoneNumber)';

                    // Dispatch autofill events
                    phoneField.dispatchEvent(new Event('input', { bubbles: true }));
                    phoneField.dispatchEvent(new Event('change', { bubbles: true }));
                    phoneField.dispatchEvent(new Event('autocomplete', { bubbles: true }));

                    // Blur (browser autofill behavior)
                    phoneField.blur();

                    console.log('[ODYSSEY] Phone autofill completed with:', phoneField.value);
                    return true;
                } else {
                    console.error('[ODYSSEY] Phone field not found for autofill');
                    return false;
                }
            } catch (error) {
                console.error('[ODYSSEY] Error in phone autofill:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Successfully filled phone number with autofill behavior")
                // Minimal delay after autofill
                try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000 ... 300_000_000))
                return true
            } else {
                logger.error("Failed to fill phone number with autofill - field not found")
                return false
            }
        } catch {
            logger.error("Error filling phone number with autofill: \(error.localizedDescription)")
            return false
        }
    }

    /// Fills email using browser autofill behavior
    public func fillEmailWithAutofill(_ email: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            try {
                // Try multiple selectors to find the email field
                let emailField = document.getElementById('email') ||
                               document.getElementById('emailAddress') ||
                               document.querySelector('input[type="email"]') ||
                               document.querySelector('input[name*="email"]') ||
                               document.querySelector('input[placeholder*="email"]') ||
                               document.querySelector('input[placeholder*="Email"]');

                console.log('[ODYSSEY] Email field found for autofill:', emailField ? {
                    type: emailField.type,
                    name: emailField.name,
                    id: emailField.id,
                    placeholder: emailField.placeholder
                } : 'NOT FOUND');

                if (emailField) {
                    // Browser autofill behavior: scroll into view
                    emailField.scrollIntoView({ behavior: 'auto', block: 'center' });

                    // Focus and clear
                    emailField.focus();
                    emailField.value = '';

                    // Autofill-style: set value instantly
                    emailField.value = '\(email)';

                    // Dispatch autofill events
                    emailField.dispatchEvent(new Event('input', { bubbles: true }));
                    emailField.dispatchEvent(new Event('change', { bubbles: true }));
                    emailField.dispatchEvent(new Event('autocomplete', { bubbles: true }));

                    // Blur (browser autofill behavior)
                    emailField.blur();

                    console.log('[ODYSSEY] Email autofill completed with:', emailField.value);
                    return true;
                } else {
                    console.error('[ODYSSEY] Email field not found for autofill');
                    return false;
                }
            } catch (error) {
                console.error('[ODYSSEY] Error in email autofill:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Successfully filled email with autofill behavior")
                // Minimal delay after autofill
                try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000 ... 300_000_000))
                return true
            } else {
                logger.error("Failed to fill email with autofill - field not found")
                return false
            }
        } catch {
            logger.error("Error filling email with autofill: \(error.localizedDescription)")
            return false
        }
    }

    /// Fills name using browser autofill behavior
    public func fillNameWithAutofill(_ name: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            try {
                // Try multiple selectors to find the name field
                let nameField = document.querySelector('input[id^="field"]') ||
                              document.getElementById('name') ||
                              document.getElementById('fullName') ||
                              document.getElementById('firstName') ||
                              document.querySelector('input[name*="name"]') ||
                              document.querySelector('input[placeholder*="name"]') ||
                              document.querySelector('input[placeholder*=\"Name\"]') ||
                              document.querySelector('input[placeholder*=\"Full Name\"]');

                console.log('[ODYSSEY] Name field found for autofill:', nameField ? {
                    type: nameField.type,
                    name: nameField.name,
                    id: nameField.id,
                    placeholder: nameField.placeholder
                } : 'NOT FOUND');

                if (nameField) {
                    // Browser autofill behavior: scroll into view
                    nameField.scrollIntoView({ behavior: 'auto', block: 'center' });

                    // Focus and clear
                    nameField.focus();
                    nameField.value = '';

                    // Autofill-style: set value instantly
                    nameField.value = '\(name)';

                    // Dispatch autofill events
                    nameField.dispatchEvent(new Event('input', { bubbles: true }));
                    nameField.dispatchEvent(new Event('change', { bubbles: true }));
                    nameField.dispatchEvent(new Event('autocomplete', { bubbles: true }));

                    // Blur (browser autofill behavior)
                    nameField.blur();

                    console.log('[ODYSSEY] Name autofill completed with:', nameField.value);
                    return true;
                } else {
                    console.error('[ODYSSEY] Name field not found for autofill');
                    return false;
                }
            } catch (error) {
                console.error('[ODYSSEY] Error in name autofill:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Successfully filled name with autofill behavior")
                // Minimal delay after autofill
                try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000 ... 300_000_000))
                return true
            } else {
                logger.error("Failed to fill name with autofill - field not found")
                return false
            }
        } catch {
            logger.error("Error filling name with autofill: \(error.localizedDescription)")
            return false
        }
    }

    /// Fills all contact fields simultaneously with browser autofill behavior
    /// and then simulates human-like movements before clicking confirm
    public func fillAllContactFieldsWithAutofillAndHumanMovements(
        phoneNumber: String,
        email: String,
        name: String,
        ) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        logger.info("Starting simultaneous contact form filling with autofill behavior")

        let script = """
        (function() {
            try {
                // Find all contact fields
                let phoneField = document.getElementById('phone') ||
                               document.getElementById('telephone') ||
                               document.getElementById('phoneNumber') ||
                               document.querySelector('input[type="tel"]') ||
                               document.querySelector('input[name*="phone"]') ||
                               document.querySelector('input[name*="tel"]') ||
                               document.querySelector('input[placeholder*="phone"]') ||
                               document.querySelector('input[placeholder*="tel"]') ||
                               document.querySelector('input[placeholder*="Phone"]') ||
                               document.querySelector('input[placeholder*="Telephone"]');

                let emailField = document.getElementById('email') ||
                               document.getElementById('emailAddress') ||
                               document.querySelector('input[type="email"]') ||
                               document.querySelector('input[name*="email"]') ||
                               document.querySelector('input[placeholder*="email"]') ||
                               document.querySelector('input[placeholder*="Email"]');

                let nameField = document.querySelector('input[id^="field"]') ||
                              document.getElementById('name') ||
                              document.getElementById('fullName') ||
                              document.getElementById('firstName') ||
                              document.querySelector('input[name*="name"]') ||
                              document.querySelector('input[placeholder*="name"]') ||
                              document.querySelector('input[placeholder*="Name"]') ||
                              document.querySelector('input[placeholder*="Full Name"]');

                console.log('[ODYSSEY] Contact fields found:', {
                    phone: phoneField ? { id: phoneField.id, name: phoneField.name, type: phoneField.type } : 'NOT FOUND',
                    email: emailField ? { id: emailField.id, name: emailField.name, type: emailField.type } : 'NOT FOUND',
                    name: nameField ? { id: nameField.id, name: nameField.name, type: nameField.type } : 'NOT FOUND'
                });

                // Fill all fields simultaneously with browser autofill behavior
                const fillFieldWithAutofill = (field, value) => {
                    if (!field) return false;

                    // Browser autofill behavior: scroll into view
                    field.scrollIntoView({ behavior: 'auto', block: 'center' });

                    // Focus and clear
                    field.focus();
                    field.value = '';

                    // Autofill-style: set value instantly
                    field.value = value;

                    // Dispatch autofill events
                    field.dispatchEvent(new Event('input', { bubbles: true }));
                    field.dispatchEvent(new Event('change', { bubbles: true }));
                    field.dispatchEvent(new Event('autocomplete', { bubbles: true }));

                    // Blur (browser autofill behavior)
                    field.blur();

                    return true;
                };

                // Fill all fields simultaneously
                const phoneFilled = fillFieldWithAutofill(phoneField, '\(phoneNumber)');
                const emailFilled = fillFieldWithAutofill(emailField, '\(email)');
                const nameFilled = fillFieldWithAutofill(nameField, '\(name)');

                console.log('[ODYSSEY] Simultaneous autofill results:', {
                    phone: phoneFilled,
                    email: emailFilled,
                    name: nameFilled
                });

                // Simulate human-like movements after filling
                const simulateHumanMovements = () => {
                    // Simulate mouse movements across the form
                    const fields = [phoneField, emailField, nameField].filter(f => f);

                    fields.forEach((field, index) => {
                        setTimeout(() => {
                            if (field) {
                                const rect = field.getBoundingClientRect();
                                const centerX = rect.left + rect.width / 2;
                                const centerY = rect.top + rect.height / 2;

                                // Simulate mouse hover over field
                                field.dispatchEvent(new MouseEvent('mouseenter', {
                                    bubbles: true,
                                    clientX: centerX + Math.random() * 10 - 5,
                                    clientY: centerY + Math.random() * 10 - 5
                                }));

                                field.dispatchEvent(new MouseEvent('mouseover', {
                                    bubbles: true,
                                    clientX: centerX + Math.random() * 10 - 5,
                                    clientY: centerY + Math.random() * 10 - 5
                                }));
                            }
                        }, index * 200 + Math.random() * 300);
                    });

                    // Simulate general mouse movements
                    setTimeout(() => {
                        document.dispatchEvent(new MouseEvent('mousemove', {
                            bubbles: true,
                            clientX: 300 + Math.random() * 200,
                            clientY: 200 + Math.random() * 150
                        }));
                    }, 800 + Math.random() * 400);

                    setTimeout(() => {
                        document.dispatchEvent(new MouseEvent('mousemove', {
                            bubbles: true,
                            clientX: 400 + Math.random() * 200,
                            clientY: 300 + Math.random() * 150
                        }));
                    }, 1200 + Math.random() * 400);

                    // Simulate scrolling to review the form
                    setTimeout(() => {
                        window.scrollBy({
                            top: -50 + Math.random() * 100,
                            left: 0,
                            behavior: 'smooth'
                        });
                    }, 1600 + Math.random() * 300);

                    // Simulate clicking on empty space (reviewing the form)
                    setTimeout(() => {
                        document.body.dispatchEvent(new MouseEvent('click', {
                            bubbles: true,
                            clientX: 100 + Math.random() * 100,
                            clientY: 100 + Math.random() * 100
                        }));
                    }, 2000 + Math.random() * 500);
                };

                // Start human movement simulation
                simulateHumanMovements();

                return phoneFilled && emailFilled && nameFilled;

            } catch (error) {
                console.error('[ODYSSEY] Error in simultaneous contact form filling:', error);
                return false;
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Successfully filled all contact fields simultaneously with autofill behavior")

                // Wait for human movements to complete (3-4 seconds total)
                try? await Task.sleep(nanoseconds: UInt64.random(in: 3_000_000_000 ... 4_000_000_000))

                // Additional human-like behavior before clicking confirm
                await simulateEnhancedHumanMovementsBeforeConfirm()

                return true
            } else {
                logger.error("Failed to fill all contact fields simultaneously")
                return false
            }
        } catch {
            logger.error("Error filling contact fields simultaneously: \(error.localizedDescription)")
            return false
        }
    }

    /// Simulates enhanced human-like movements specifically before clicking confirm button
    public func simulateEnhancedHumanMovementsBeforeConfirm() async {
        guard let webView else { return }

        logger.info("🛡️ Simulating enhanced human-like movements before clicking confirm button")

        // Simulate realistic mouse movements to the confirm button area
        let script = """
        (function() {
            try {
                // Find the confirm button to simulate movements towards it
                const confirmButton = document.querySelector('button[type="submit"], input[type="submit"], .mdc-button, button:contains("Confirm"), button:contains("Submit")');

                if (confirmButton) {
                    const rect = confirmButton.getBoundingClientRect();
                    const targetX = rect.left + rect.width / 2;
                    const targetY = rect.top + rect.height / 2;

                    // Simulate mouse movement path to the button
                    const steps = 8;
                    const startX = 200 + Math.random() * 100;
                    const startY = 150 + Math.random() * 100;

                    for (let i = 0; i <= steps; i++) {
                        setTimeout(() => {
                            const progress = i / steps;
                            const currentX = startX + (targetX - startX) * progress + (Math.random() - 0.5) * 20;
                            const currentY = startY + (targetY - startY) * progress + (Math.random() - 0.5) * 20;

                            document.dispatchEvent(new MouseEvent('mousemove', {
                                bubbles: true,
                                clientX: currentX,
                                clientY: currentY
                            }));
                        }, i * 150 + Math.random() * 100);
                    }

                    // Simulate hover over the button
                    setTimeout(() => {
                        confirmButton.dispatchEvent(new MouseEvent('mouseenter', {
                            bubbles: true,
                            clientX: targetX + Math.random() * 10 - 5,
                            clientY: targetY + Math.random() * 10 - 5
                        }));

                        confirmButton.dispatchEvent(new MouseEvent('mouseover', {
                            bubbles: true,
                            clientX: targetX + Math.random() * 10 - 5,
                            clientY: targetY + Math.random() * 10 - 5
                        }));
                    }, steps * 150 + 200);
                }

                // Simulate some random mouse movements in the form area
                setTimeout(() => {
                    document.dispatchEvent(new MouseEvent('mousemove', {
                        bubbles: true,
                        clientX: 250 + Math.random() * 200,
                        clientY: 180 + Math.random() * 150
                    }));
                }, 500 + Math.random() * 300);

                setTimeout(() => {
                    document.dispatchEvent(new MouseEvent('mousemove', {
                        bubbles: true,
                        clientX: 350 + Math.random() * 200,
                        clientY: 220 + Math.random() * 150
                    }));
                }, 1000 + Math.random() * 300);

                // Simulate a small scroll to review the form
                setTimeout(() => {
                    window.scrollBy({
                        top: -30 + Math.random() * 60,
                        left: 0,
                        behavior: 'smooth'
                    });
                }, 1500 + Math.random() * 400);

                console.log('[ODYSSEY] Enhanced human movements before confirm completed');

            } catch (error) {
                console.error('[ODYSSEY] Error in enhanced human movements:', error);
            }
        })();
        """

        do {
            _ = try await webView.evaluateJavaScript(script)

            // Wait for movements to complete (2-3 seconds)
            try? await Task.sleep(nanoseconds: UInt64.random(in: 2_000_000_000 ... 3_000_000_000))

            logger.info("Enhanced human-like movements before confirm completed")
        } catch {
            logger.error("❌ Error simulating enhanced human movements: \(error.localizedDescription)")
        }
    }

    /**
     Loads the given URL in the WKWebView.
     - Parameter url: The URL to load.
     */
    public func load(url _: URL) {
        // ... existing code ...
    }

    /**
     Executes the provided JavaScript in the WKWebView context.
     - Parameter script: The JavaScript string to execute.
     - Parameter completion: Completion handler with result or error.
     */
    public func executeJavaScript(_: String, completion _: @escaping (Result<Any?, Error>) -> Void) {
        // ... existing code ...
    }

    /**
     Cleans up the WKWebView and releases resources.
     */
    public func cleanup() {
        logger.info("🧹 WebKitService cleanup called.")
        // ... existing code ...
    }
}

// MARK: - Navigation Delegate

public class WebKitNavigationDelegate: NSObject, WKNavigationDelegate {
    weak var delegate: WebKitService?

    public func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation?) { }

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

    public func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation?, withError _: Error) { }

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

    public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "odysseyHandler" {
            if let body = message.body as? [String: Any], let type = body["type"] as? String {
                switch type {
                case "scriptInjected":
                    delegate?.logger.info("Automation scripts injected successfully")
                case "contactFormCheckError":
                    if
                        let data = body["data"] as? [String: Any], let msg = data["message"] as? String,
                        let stack = data["stack"] as? String {
                        delegate?.logger.error("[ContactForm][JS] Error: \(msg)\nStack: \(stack)")
                    }
                case "contactFormTimeout":
                    if
                        let data = body["data"] as? [String: Any], let html = data["html"] as? String,
                        let allInputs = data["allInputs"] {
                        let allInputsStr = String(describing: allInputs)
                        delegate?.logger
                            .error("[ContactForm][JS] Timeout. HTML: \(html.prefix(1_000))\nInputs: \(allInputsStr)")
                    }
                case "contactFormTimeoutError":
                    if
                        let data = body["data"] as? [String: Any], let msg = data["message"] as? String,
                        let stack = data["stack"] as? String {
                        delegate?.logger.error("[ContactForm][JS] Timeout error: \(msg)\nStack: \(stack)")
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
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        if (element) {
            element.click();
            return true;
        }
        return false;
        """

        let result = try await service.executeScriptInternal(script)?.value as? Bool ?? false
        if !result {
            throw WebDriverError.clickFailed("Element not found or click failed")
        }
    }

    func type(_ text: String) async throws {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        if (element) {
            element.value = '\(text)';
            element.dispatchEvent(new Event('input', { bubbles: true }));
            element.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
        }
        return false;
        """

        let result = try await service.executeScriptInternal(script)?.value as? Bool ?? false
        if !result {
            throw WebDriverError.typeFailed("Element not found or type failed")
        }

        value = text
    }

    func clear() async throws {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        if (element) {
            element.value = '';
            element.dispatchEvent(new Event('input', { bubbles: true }));
            element.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
        }
        return false;
        """

        let result = try await service.executeScriptInternal(script)?.value as? Bool ?? false
        if !result {
            throw WebDriverError.typeFailed("Element not found or clear failed")
        }

        value = ""
    }

    func getAttribute(_ name: String) async throws -> String? {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        return element ? element.getAttribute('\(name)') : null;
        """

        return try await service.executeScriptInternal(script)?.value as? String
    }

    func getText() async throws -> String {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        return element ? element.textContent || '' : '';
        """

        return try await service.executeScriptInternal(script)?.value as? String ?? ""
    }

    func isDisplayed() async throws -> Bool {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        return element ? element.offsetParent !== null : false;
        """

        let result = try await service.executeScriptInternal(script)?.value
        return result as? Bool ?? false
    }

    func isEnabled() async throws -> Bool {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        return element ? !element.disabled : false;
        """

        let result = try await service.executeScriptInternal(script)?.value
        return result as? Bool ?? false
    }

    func isSelected() async throws -> Bool {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        return element ? element.selected : false;
        """

        return try await service.executeScriptInternal(script)?.value as? Bool ?? false
    }
}

// Register the singleton for DI
public extension WebKitService {
    static func registerForDI() {
        ServiceRegistry.shared.register(WebKitService.shared, for: WebKitServiceProtocol.self)
    }
}
