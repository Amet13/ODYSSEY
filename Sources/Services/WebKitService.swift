//
//  WebKitService.swift
//  ODYSSEY
//
//  Created by ODYSSEY Team
//
//  IMPORTANT: WebKit Native Approach
//  ===================================
//  This service implements a native Swift WebKit approach for web automation
//  that replaces the Chrome/ChromeDriver dependency. This provides:
//  - No external dependencies (ChromeDriver, Chrome)
//  - Native macOS integration
//  - Better performance and reliability
//  - Smaller app footprint
//  - No permission issues with ChromeDriver
//

import AppKit
import Combine
import Foundation
import os.log
import WebKit

/// WebKit service for native web automation
/// Handles web navigation and automation using WKWebView
class WebKitService: NSObject, ObservableObject, WebAutomationServiceProtocol {
    static let shared = WebKitService()

    @Published var isConnected = false
    @Published var isRunning: Bool = false
    @Published var currentURL: String?
    @Published var pageTitle: String?

    let logger = Logger(subsystem: "com.odyssey.app", category: "WebKitService")
    var webView: WKWebView?
    private var navigationDelegate: WebKitNavigationDelegate?
    private var scriptMessageHandler: WebKitScriptMessageHandler?
    private var debugWindow: NSWindow?

    // Configuration
    var currentConfig: ReservationConfig?
    // Set a Chrome-like user agent
    var userAgent: String =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    private var language: String = "en-US,en"

    // Toggle for instant fill mode
    static var instantFillEnabled: Bool = false

    // Toggle for fast mode
    static var fastModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "WebKitFastMode") }
        set { UserDefaults.standard.set(newValue, forKey: "WebKitFastMode") }
    }

    // Completion handlers for async operations
    var navigationCompletions: [String: (Bool) -> Void] = [:]
    private var scriptCompletions: [String: (Any?) -> Void] = [:]
    private var elementCompletions: [String: (String?) -> Void] = [:]

    override private init() {
        super.init()
        setupWebView()
        // Do not show debug window at app launch
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        // Add script message handler
        scriptMessageHandler = WebKitScriptMessageHandler()
        scriptMessageHandler?.delegate = self
        configuration.userContentController.add(scriptMessageHandler!, name: "odysseyHandler")

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

        // Create web view
        webView = WKWebView(frame: .zero, configuration: configuration)

        // Set realistic user agent (random from common browsers)
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

        // Set realistic window size (random from common MacBook resolutions)
        let windowSizes = [
            (width: 1_440, height: 900), // MacBook Air 13"
            (width: 1_680, height: 1_050), // MacBook Pro 15"
            (width: 1_920, height: 1_080), // MacBook Pro 16"
            (width: 2_560, height: 1_600), // MacBook Pro 13" Retina
            (width: 2_880, height: 1_800), // MacBook Pro 15" Retina
        ]
        let selectedSize = windowSizes.randomElement() ?? windowSizes[0]
        webView?.frame = CGRect(x: 0, y: 0, width: selectedSize.width, height: selectedSize.height)

        // Inject custom JavaScript for automation and anti-detection
        injectAutomationScripts()
        injectAntiDetectionScripts()
    }

    @MainActor
    private func setupDebugWindow() {
        // Set realistic window size (random from common MacBook resolutions)
        let windowSizes = [
            (width: 1_440, height: 900), // MacBook Air 13"
            (width: 1_680, height: 1_050), // MacBook Pro 15"
            (width: 1_920, height: 1_080), // MacBook Pro 16"
            (width: 2_560, height: 1_600), // MacBook Pro 13" Retina
            (width: 2_880, height: 1_800), // MacBook Pro 15" Retina
        ]
        let selectedSize = windowSizes.randomElement() ?? windowSizes[0]

        // Create a visible window for debugging
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: selectedSize.width, height: selectedSize.height),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false,
        )
        window.title = "ODYSSEY Web Automation Debug"
        window.isReleasedWhenClosed = false
        window.level = .floating
        if let webView {
            window.contentView = webView
        }
        window.makeKeyAndOrderFront(nil)
        debugWindow = window
        logger
            .info(
                "Debug window for WKWebView created and shown with size: \(selectedSize.width)x\(selectedSize.height)",
            )
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
            // Random screen sizes for realism (common MacBook resolutions)
            const screenSizes = [
                { width: 1440, height: 900, pixelRatio: 2 },   // MacBook Air 13"
                { width: 1680, height: 1050, pixelRatio: 2 },  // MacBook Pro 15"
                { width: 1920, height: 1080, pixelRatio: 2 },  // MacBook Pro 16"
                { width: 2560, height: 1600, pixelRatio: 2 },  // MacBook Pro 13" Retina
                { width: 2880, height: 1800, pixelRatio: 2 }   // MacBook Pro 15" Retina
            ];

            const selectedScreen = screenSizes[Math.floor(Math.random() * screenSizes.length)];

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

            console.log('[ODYSSEY] Comprehensive anti-detection measures activated');
            console.log('[ODYSSEY] Screen: ' + selectedScreen.width + 'x' + selectedScreen.height + ' @' + selectedScreen.pixelRatio + 'x');
            console.log('[ODYSSEY] User Agent: ' + selectedUserAgent.substring(0, 50) + '...');
        })();
        """

        let script = WKUserScript(source: antiDetectionScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView?.configuration.userContentController.addUserScript(script)
    }

    @MainActor
    private func logAllButtonsAndLinks() async {
        guard let webView else {
            logger.error("[ButtonScan] webView is nil")
            print("[ButtonScan] webView is nil")
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
                    logger.info("[ButtonScan] \(line, privacy: .public)")
                    print("[ButtonScan] \(line)")
                }
            } else {
                logger.error("[ButtonScan] Unexpected JS result: \(String(describing: result))")
                print("[ButtonScan] Unexpected JS result: \(String(describing: result))")
            }
        } catch {
            logger.error("[ButtonScan] JS error: \(error.localizedDescription, privacy: .public) | \(error)")
            print("[ButtonScan] JS error: \(error.localizedDescription) | \(error)")
        }
    }

    @MainActor
    private func logPageSource() async {
        guard let webView else {
            logger.error("[PageSource] webView is nil")
            print("[PageSource] webView is nil")
            return
        }
        let script = "document.documentElement.outerHTML;"
        do {
            let result = try await webView.evaluateJavaScript(script)
            if let html = result as? String {
                let snippet = html.prefix(2_000)
                logger.info("[PageSource] \(snippet, privacy: .public)")
                print("[PageSource] \(snippet)")
            } else {
                logger.error("[PageSource] Unexpected JS result: \(String(describing: result))")
                print("[PageSource] Unexpected JS result: \(String(describing: result))")
            }
        } catch {
            logger.error("[PageSource] JS error: \(error.localizedDescription, privacy: .public) | \(error)")
            print("[PageSource] JS error: \(error.localizedDescription) | \(error)")
        }
    }

    // Helper to log page state for debugging
    @MainActor
    private func logPageState(context: String) async {
        guard let webView else { return }
        let script = """
        (function() {
            let html = document.documentElement.outerHTML.substring(0, 5000);
            let inputs = Array.from(document.querySelectorAll('input')).map(el => `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [placeholder='${el.placeholder}'] [type='${el.type}']`);
            let buttons = Array.from(document.querySelectorAll('button')).map(el => `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [text='${el.innerText || ''}']`);
            let links = Array.from(document.querySelectorAll('a')).map(el => `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [href='${el.href}'] [text='${el.innerText || ''}']`);
            let divs = Array.from(document.querySelectorAll('div')).map(el => `[id='${el.id}'] [class='${el.className}'] [text='${el.innerText || ''}']`);
            return { html, inputs, buttons, links, divs };
        })();
        """
        do {
            let result = try await webView.evaluateJavaScript(script)
            if let dict = result as? [String: Any] {
                if let html = dict["html"] as? String {
                    logger.info("[PageState][\(context)] HTML: \(html.prefix(5_000), privacy: .public)")
                    print("[PageState][\(context)] HTML: \(html.prefix(5_000))")
                }
                if let inputs = dict["inputs"] as? [String] {
                    logger.info("[PageState][\(context)] INPUTS: \(inputs.joined(separator: ", "), privacy: .public)")
                    print("[PageState][\(context)] INPUTS: \(inputs.joined(separator: ", "))")
                }
                if let buttons = dict["buttons"] as? [String] {
                    logger.info("[PageState][\(context)] BUTTONS: \(buttons.joined(separator: ", "), privacy: .public)")
                    print("[PageState][\(context)] BUTTONS: \(buttons.joined(separator: ", "))")
                }
                if let links = dict["links"] as? [String] {
                    logger.info("[PageState][\(context)] LINKS: \(links.joined(separator: ", "), privacy: .public)")
                    print("[PageState][\(context)] LINKS: \(links.joined(separator: ", "))")
                }
                if let divs = dict["divs"] as? [String] {
                    logger.info("[PageState][\(context)] DIVS: \(divs.joined(separator: ", "), privacy: .public)")
                    print("[PageState][\(context)] DIVS: \(divs.joined(separator: ", "))")
                }
            }
        } catch {
            logger.error("[PageState][\(context)] Error logging page state: \(error.localizedDescription)")
            print("[PageState][\(context)] Error logging page state: \(error.localizedDescription)")
        }
    }

    // MARK: - WebDriverServiceProtocol Implementation

    func connect() async throws {
        await MainActor.run {
            self.setupDebugWindow()
        }
        isConnected = true
        isRunning = true
        logger.info("WebKit service connected")
    }

    func disconnect() async {
        isConnected = false
        isRunning = false
        await webView?.stopLoading()
        logger.info("WebKit service disconnected")
    }

    func navigateToURL(_ url: String) async throws {
        await MainActor.run {
            self.setupDebugWindow()
        }
        guard webView != nil else {
            logger.error("navigateToURL: WebView not initialized")
            throw WebDriverError.navigationFailed("WebView not initialized")
        }
        logger.info("Navigating to URL: \(url, privacy: .private)")
        return try await withCheckedThrowingContinuation { continuation in
            let requestId = UUID().uuidString
            navigationCompletions[requestId] = { success in
                if success {
                    self.logger.info("Navigation to \(url, privacy: .private) succeeded")
                    Task { await self.logPageState(context: "after navigation") }
                    // Log document.readyState and page source for diagnosis
                    Task {
                        do {
                            let readyState = try await self.executeScriptInternal("return document.readyState;")
                            self.logger.info("document.readyState after navigation: \(String(describing: readyState))")
                            let pageSource = try await self.getPageSource()
                            self.logger
                                .info("Page source after navigation (first 500 chars): \(pageSource.prefix(500))")
                        } catch {
                            self.logger.error("Error logging readyState/page source: \(error.localizedDescription)")
                        }
                    }
                    // After navigation completes, log page source and all buttons/links
                    Task { @MainActor in
                        await self.logPageSource()
                        await self.logAllButtonsAndLinks()
                    }
                    continuation.resume()
                } else {
                    self.logger.error("Navigation to \(url, privacy: .private) failed")
                    Task { await self.logPageState(context: "error") }
                    continuation.resume(throwing: WebDriverError.navigationFailed("Failed to navigate to \(url)"))
                }
            }
            guard let url = URL(string: url) else {
                self.logger.error("navigateToURL: Invalid URL: \(url)")
                Task { await self.logPageState(context: "error") }
                continuation.resume(throwing: WebDriverError.navigationFailed("Invalid URL: \(url)"))
                return
            }
            let request = URLRequest(url: url)
            Task {
                await webView?.load(request)
            }
        }
    }

    func findElement(by selector: String) async throws -> WebElementProtocol {
        guard webView != nil else {
            throw WebDriverError.elementNotFound("WebView not initialized")
        }

        let script = "return document.querySelector('\(selector)');"
        let result = try await executeScriptInternal(script)

        if let elementId = result as? String, !elementId.isEmpty {
            return WebKitElement(id: elementId, webView: webView!, service: self)
        } else {
            throw WebDriverError.elementNotFound("Element not found: \(selector)")
        }
    }

    func findElements(by selector: String) async throws -> [WebElementProtocol] {
        guard webView != nil else {
            throw WebDriverError.elementNotFound("WebView not initialized")
        }

        let script = """
        const elements = document.querySelectorAll('\(selector)');
        return Array.from(elements).map((el, index) => 'element_' + index);
        """

        let result = try await executeScriptInternal(script)
        let elementIds = result as? [String] ?? []
        return elementIds.map { WebKitElement(id: $0, webView: webView!, service: self) }
    }

    func getPageSource() async throws -> String {
        guard webView != nil else {
            throw WebDriverError.elementNotFound("WebView not initialized")
        }

        let result = try await executeScriptInternal("return document.documentElement.outerHTML;")
        return result as? String ?? ""
    }

    func getCurrentURL() async throws -> String {
        guard webView != nil else {
            throw WebDriverError.elementNotFound("WebView not initialized")
        }

        return await webView?.url?.absoluteString ?? ""
    }

    func getTitle() async throws -> String {
        guard webView != nil else {
            throw WebDriverError.elementNotFound("WebView not initialized")
        }

        return await webView?.title ?? ""
    }

    func takeScreenshot() async throws -> Data {
        guard webView != nil else {
            throw WebDriverError.screenshotFailed("WebView not initialized")
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                await webView!.takeSnapshot(with: nil) { image, error in
                    if let image, let data = image.tiffRepresentation {
                        continuation.resume(returning: data)
                    } else {
                        continuation
                            .resume(
                                throwing: WebDriverError
                                    .screenshotFailed(error?.localizedDescription ?? "Unknown error"),
                            )
                    }
                }
            }
        }
    }

    func waitForElement(by selector: String, timeout: TimeInterval) async throws -> WebElementProtocol {
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

    func waitForElementToDisappear(by selector: String, timeout: TimeInterval) async throws {
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

    func executeScript(_ script: String) async throws -> String {
        guard webView != nil else {
            throw WebDriverError.scriptExecutionFailed("WebView not initialized")
        }

        let result = try await executeScriptInternal(script)
        return String(describing: result)
    }

    // MARK: - Internal Methods

    func executeScriptInternal(_ script: String) async throws -> Any? {
        guard webView != nil else {
            throw WebDriverError.scriptExecutionFailed("WebView not initialized")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let requestId = UUID().uuidString
            scriptCompletions[requestId] = { result in
                continuation.resume(returning: result)
            }

            Task {
                do {
                    let result = try await webView!.evaluateJavaScript(script)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: WebDriverError.scriptExecutionFailed(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Reservation-specific Methods

    func findAndClickElement(withText text: String) async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            Task { await self.logPageState(context: "error") }
            return false
        }

        logger.info("Searching for sport button: '\(text, privacy: .private)'")
        Task { await self.logPageState(context: "before button click") }
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
        logger.info("[ButtonClick] Executing JS: \(script, privacy: .public)")
        print("[ButtonClick] Executing JS: \n\(script)")
        do {
            let result = try await executeScriptInternal(script)
            logger.info("[ButtonClick] JS result: \(String(describing: result), privacy: .public)")
            print("[ButtonClick] JS result: \(String(describing: result))")
            Task { await self.logPageState(context: "after button click") }
            if let str = result as? String {
                if str == "clicked" || str == "dispatched" {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds sleep
                    return true
                } else if str.starts(with: "error:") {
                    logger.error("[ButtonClick] JS error: \(str, privacy: .public)")
                    print("[ButtonClick] JS error: \(str)")
                    Task { await self.logPageState(context: "error") }
                    return false
                } else {
                    logger
                        .error(
                            "Sport button not found: '\(text, privacy: .private)' | JS result: \(str, privacy: .public)",
                        )
                    print("Sport button not found: '\(text)' | JS result: \(str)")
                    Task { await self.logPageState(context: "error") }
                    return false
                }
            } else {
                logger.error("[ButtonClick] Unexpected JS result: \(String(describing: result))")
                print("[ButtonClick] Unexpected JS result: \(String(describing: result))")
                Task { await self.logPageState(context: "error") }
                return false
            }
        } catch {
            logger.error("Error clicking sport button: \(error.localizedDescription, privacy: .public) | \(error)")
            print("Error clicking sport button: \(error.localizedDescription) | \(error)")
            Task { await self.logPageState(context: "error") }
            return false
        }
    }

    /// Waits for DOM ready or for a key button/element to appear
    /// Now also checks for the presence of a button with the configured sport name
    func waitForDOMReady() async -> Bool {
        guard webView != nil else {
            logger.error("waitForDOMReady: WebView not initialized")
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
            logger.info("Executing enhanced DOM ready/button check script...")
            let result = try await executeScriptInternal(buttonCheckScript)
            logger.info("DOM/button check result: \(String(describing: result))")
            if let dict = result as? [String: Any] {
                let readyState = dict["readyState"] as? String ?? ""
                let buttonFound = dict["buttonFound"] as? Bool ?? false
                logger.info("document.readyState=\(readyState), buttonFound=\(buttonFound)")
                if readyState == "complete" || buttonFound {
                    logger.info("DOM ready or button found, proceeding")
                    return true
                } else {
                    logger.error("DOM not ready and button not found")
                    return false
                }
            } else {
                logger.error("Unexpected result from DOM/button check: \(String(describing: result))")
                return false
            }
        } catch {
            logger.error("Error waiting for DOM ready/button: \(error.localizedDescription)")
            return false
        }
    }

    @MainActor
    func waitForDOMReadyAndButton(selector _: String, buttonText: String) async -> Bool {
        guard let webView else {
            logger.error("waitForDOMReady: WebView not initialized")
            print("waitForDOMReady: WebView not initialized")
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
                print("waitForDOMReadyAndButton JS error: \(error.localizedDescription) | error: \(error)")
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }
        logger.error("Button with text \(buttonText) not found after 10s")
        print("Button with text \(buttonText) not found after 10s")
        return false
    }

    func fillNumberOfPeople(_ numberOfPeople: Int) async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            print("WebView not initialized")
            Task { await self.logPageState(context: "error") }
            return false
        }
        Task { await self.logPageState(context: "before fill number of people") }

        // Log the page HTML and all input/button elements for debugging
        let logScript = """
        (function() {
            let html = document.documentElement.outerHTML.substring(0, 5000);
            let inputs = Array.from(document.querySelectorAll('input')).map(el => `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [placeholder='${el.placeholder}'] [type='${el.type}']`);
            let buttons = Array.from(document.querySelectorAll('button')).map(el => `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [text='${el.innerText || ''}']`);
            return { html, inputs, buttons };
        })();
        """
        do {
            let logResult = try await executeScriptInternal(logScript)
            if let dict = logResult as? [String: Any] {
                if let html = dict["html"] as? String {
                    logger.info("[PeopleFill] PAGE HTML: \(html.prefix(5_000), privacy: .public)")
                    print("[PeopleFill] PAGE HTML: \(html.prefix(5_000))")
                }
                if let inputs = dict["inputs"] as? [String] {
                    logger.info("[PeopleFill] INPUTS: \(inputs.joined(separator: ", "), privacy: .public)")
                    print("[PeopleFill] INPUTS: \(inputs.joined(separator: ", "))")
                }
                if let buttons = dict["buttons"] as? [String] {
                    logger.info("[PeopleFill] BUTTONS: \(buttons.joined(separator: ", "), privacy: .public)")
                    print("[PeopleFill] BUTTONS: \(buttons.joined(separator: ", "))")
                }
            }
        } catch {
            logger.error("[PeopleFill] Error logging page HTML/inputs/buttons: \(error.localizedDescription)")
            print("[PeopleFill] Error logging page HTML/inputs/buttons: \(error.localizedDescription)")
        }

        let script = """
        (function() {
            let field = document.getElementById('reservationCount')
                || document.querySelector('input[name=\"reservationCount\"]')
                || document.querySelector('input[placeholder*=\"people\" i]')
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
                let details = inputs.map(el => `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [placeholder='${el.placeholder}'] [type='${el.type}']`);
                return 'not found: ' + details.join(' | ');
            }
        })();
        """
        logger.info("[PeopleFill] Executing JS: \(script, privacy: .public)")
        print("[PeopleFill] Executing JS: \n\(script)")
        do {
            let result = try await executeScriptInternal(script)
            logger.info("[PeopleFill] JS result: \(String(describing: result), privacy: .public)")
            print("[PeopleFill] JS result: \(String(describing: result))")
            Task { await self.logPageState(context: "after fill number of people") }
            if let str = result as? String, str == "filled" {
                return true
            } else {
                logger.error("[PeopleFill] Field not found or not filled: \(String(describing: result))")
                print("[PeopleFill] Field not found or not filled: \(String(describing: result))")
                Task { await self.logPageState(context: "error") }
                return false
            }
        } catch {
            logger.error("Error filling number of people: \(error.localizedDescription)")
            print("Error filling number of people: \(error.localizedDescription)")
            Task { await self.logPageState(context: "error") }
            return false
        }
    }

    func clickConfirmButton() async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            print("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            let button = document.getElementById('submit-btn')
                || document.querySelector('button[type="submit"]')
                || document.querySelector('input[type="submit"]')
                || Array.from(document.querySelectorAll('button, input[type="submit"]')).find(el => el.innerText && el.innerText.toLowerCase().includes('confirm'));
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
                let details = btns.map(el => `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [text='${el.innerText || el.value || ''}']`);
                return 'not found: ' + details.join(' | ');
            }
        })();
        """

        logger.info("[ConfirmClick] Executing JS: \(script, privacy: .public)")
        print("[ConfirmClick] Executing JS: \n\(script)")
        do {
            let result = try await executeScriptInternal(script)
            logger.info("[ConfirmClick] JS result: \(String(describing: result), privacy: .public)")
            print("[ConfirmClick] JS result: \(String(describing: result))")
            if let str = result as? String, str == "clicked" {
                // Wait a moment and then log the page state to see what happened
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await logPageState(context: "after confirm click")

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
                logger.info("[ConfirmClick] Page check: \(String(describing: checkResult), privacy: .public)")
                print("[ConfirmClick] Page check: \(String(describing: checkResult))")

                return true
            } else {
                logger.error("[ConfirmClick] Button not found or not clicked: \(String(describing: result))")
                print("[ConfirmClick] Button not found or not clicked: \(String(describing: result))")
                return false
            }
        } catch {
            logger.error("Error clicking confirm button: \(error.localizedDescription)")
            print("Error clicking confirm button: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Additional Reservation Methods (Placeholders)

    func waitForGroupSizePage() async -> Bool {
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
                let inputs = Array.from(document.querySelectorAll('input')).map(el => `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [placeholder='${el.placeholder}'] [type='${el.type}'] [value='${el.value}'] [visible='${!!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)}']`);
                let buttons = Array.from(document.querySelectorAll('button')).map(el => `[id='${el.id}'] [name='${el.name}'] [class='${el.className}'] [text='${el.innerText || ''}'] [visible='${!!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)}']`);
                let divs = Array.from(document.querySelectorAll('div')).map(el => `[id='${el.id}'] [class='${el.className}'] [text='${el.innerText || ''}'] [visible='${!!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)}']`);
                let found = document.getElementById('reservationCount')
                    || document.querySelector('input[name=\"reservationCount\"]')
                    || Array.from(document.querySelectorAll('input')).find(el => (el.placeholder||'').toLowerCase().includes('people') || el.type === 'number');
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
                    print(
                        "[GroupSizePoll][poll \(pollCount)] found=\(found)\nINPUTS: \(inputs.joined(separator: ", "))\nBUTTONS: \(buttons.joined(separator: ", "))\nDIVS: \(divs.prefix(5).joined(separator: ", "))\nHTML: \(html.prefix(5_000))",
                    )
                    if found {
                        logger.info("Group size input found on poll #\(pollCount)")
                        return true
                    }
                }
            } catch {
                logger.error("[GroupSizePoll][poll \(pollCount)] JS error: \(error.localizedDescription)")
                print("[GroupSizePoll][poll \(pollCount)] JS error: \(error.localizedDescription)")
            }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        logger.error("Group size page load timeout after \(Int(timeout))s and \(pollCount) polls")
        return false
    }

    func waitForTimeSelectionPage() async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        logger.info("[TimeSelection] Starting time selection page detection...")
        print("[TimeSelection] Starting time selection page detection...")

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
            let result = try await executeScriptInternal(script) as? Bool ?? false

            logger.info("[TimeSelection] JavaScript result: \(result)")
            print("[TimeSelection] JavaScript result: \(result)")

            if result {
                logger.info("Time selection page loaded successfully")
                print("Time selection page loaded successfully")
            } else {
                logger.error("Time selection page not detected")
                print("Time selection page not detected")
            }
            return result
        } catch {
            logger.error("Error checking time selection page: \(error.localizedDescription)")
            print("Error checking time selection page: \(error.localizedDescription)")
            return false
        }
    }

    func selectTimeSlot(dayName: String, timeString: String) async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        logger.info("Selecting time slot: \(dayName, privacy: .private) at \(timeString, privacy: .private)")
        await logPageState(context: "before time slot selection")

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
                // Click the last visible header-text element
                let clicked = false;
                for (let i = headerElements.length - 1; i >= 0; i--) {
                    const el = headerElements[i];
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);
                    if (visible) {
                        el.scrollIntoView({behavior: 'smooth', block: 'center'});
                        el.click();
                        clicked = true;
                        console.log(`[ODYSSEY] Clicked header-text[${i}]: text="${el.textContent.trim()}"`);
                        break;
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
            logger.info("[TimeSlot][DaySection] JS result: \(String(describing: result), privacy: .private)")
            await logPageState(context: "after day section click attempts")
            if let dict = result as? [String: Any], let clicked = dict["clicked"] as? Bool, clicked {
                logger.info("[TimeSlot][DaySection] Day section expanded successfully")

                // Check if time slot was also clicked
                if let timeSlotClicked = dict["timeSlotClicked"] as? Bool, timeSlotClicked {
                    logger.info("[TimeSlot] Time slot clicked successfully")

                    // Wait for page to load after time slot click
                    logger.info("[TimeSlot] Waiting for page to load after time slot click...")
                    try await Task.sleep(nanoseconds: 3_000_000_000) // Wait 3 seconds

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
                            logger.info("Continue button clicked after time slot selection")
                        } else {
                            logger.info("No continue button found after time slot selection")
                            // Log current page state for debugging
                            await logPageState(context: "after time slot click - no continue button found")
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

    func checkAndClickContinueButton() async -> Bool {
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
            logger.error("Error checking for continue button: \(error.localizedDescription, privacy: .public)")
            logger.error("Continue button error details: \(error, privacy: .public)")
            return false
        }
    }

    func clickContinueAfterTimeSlot() async -> Bool {
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
            await logPageState(context: "after continue button click attempt")
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

    func waitForContactInfoPage() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Ultra-simple approach: just check if the telephone field exists
        let script = """
        (function() {
            try {
                const phoneField = document.getElementById('telephone');
                return phoneField !== null;
            } catch (error) {
                console.error('Error in contact form check:', error);
                return false;
            }
        })();
        """
        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Contact info page loaded successfully")
            } else {
                logger.error("Contact info page load timeout - see logs for page HTML and input fields")
            }
            return result
        } catch {
            logger.error("Error checking contact info page: \(error.localizedDescription, privacy: .public)")
            logger.error("Contact form error details: \(error, privacy: .public)")
            return false
        }
    }

    func fillPhoneNumber(_ phoneNumber: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Add very short random delay before starting (0.2-0.8 seconds)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000 ... 800_000_000))

        // Simulate realistic mouse movement and human-like behavior
        await simulateRealisticMouseMovements()
        await simulateHumanScrolling()
        await simulateHumanFormInteraction()

        let script = """
        (function() {
            // Use exact selector from Python/Selenium implementation
            const phoneField = document.getElementById('telephone');

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

                // Focus and clear (but preserve +1 if it's there)
                phoneField.focus();
                const currentValue = phoneField.value;
                if (currentValue.includes('+1')) {
                    phoneField.value = '+1';
                } else {
                    phoneField.value = '';
                }

                // Simulate human-like typing with realistic events and delays
                const value = '\(phoneNumber)';
                console.log('[ODYSSEY] Typing phone number:', value);

                                // Use a synchronous approach with setTimeout to simulate typing delays
                const typeCharacter = (index) => {
                    if (index >= value.length) {
                        phoneField.dispatchEvent(new Event('change', { bubbles: true }));
                        phoneField.blur();
                        console.log('[ODYSSEY] Phone field filled with:', phoneField.value);
                        return;
                    }

                    // Simulate occasional typos (5% chance)
                    let charToType = value[index];
                    let shouldMakeTypo = Math.random() < 0.05 && index < value.length - 1;

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

                        // Wait a bit, then backspace and type correct character
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

                            // Type correct character
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

                                // Continue with next character
                                setTimeout(() => typeCharacter(index + 1), 50 + Math.random() * 100);
                            }, 100 + Math.random() * 200);
                        }, 200 + Math.random() * 300);
                    } else {
                        // Normal typing
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

                        // Schedule next character with variable delay (30-200ms)
                        const baseDelay = 80 + Math.random() * 100;
                        const extraDelay = Math.random() < 0.1 ? 100 + Math.random() * 200 : 0; // 10% chance of longer pause
                        setTimeout(() => typeCharacter(index + 1), baseDelay + extraDelay);
                    }
                };

                // Start typing
                typeCharacter(0);

                // Return true immediately - the typing will complete asynchronously
                return true;
            }
            return false;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Successfully filled phone number with human-like behavior")
                // Add very short delay after filling (0.2-0.5 second)
                try? await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000 ... 500_000_000))
                return true
            } else {
                logger.error("Failed to fill phone number - field not found")
                return false
            }
        } catch {
            logger.error("Error filling phone number: \(error.localizedDescription)")
            return false
        }
    }

    func fillEmail(_ email: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Add very short random delay before starting (0.2-0.8 seconds)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000 ... 800_000_000))

        // Simulate realistic mouse movement and human-like behavior
        await simulateRealisticMouseMovements()
        await simulateHumanScrolling()
        await simulateHumanFormInteraction()

        let script = """
        (function() {
            // Use exact selector from Python/Selenium implementation
            const emailField = document.getElementById('email');

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
                        emailField.dispatchEvent(new Event('change', { bubbles: true }));
                        emailField.blur();
                        console.log('[ODYSSEY] Email field filled with:', emailField.value);
                        return;
                    }

                    emailField.value += value[index];

                    // Dispatch realistic keyboard events
                    emailField.dispatchEvent(new KeyboardEvent('keydown', { 
                        bubbles: true, 
                        key: value[index], 
                        code: 'Key' + value[index].toUpperCase(),
                        keyCode: value[index].charCodeAt(0)
                    }));
                    emailField.dispatchEvent(new KeyboardEvent('keypress', { 
                        bubbles: true, 
                        key: value[index], 
                        code: 'Key' + value[index].toUpperCase(),
                        keyCode: value[index].charCodeAt(0)
                    }));
                    emailField.dispatchEvent(new Event('input', { bubbles: true }));
                    emailField.dispatchEvent(new KeyboardEvent('keyup', { 
                        bubbles: true, 
                        key: value[index], 
                        code: 'Key' + value[index].toUpperCase(),
                        keyCode: value[index].charCodeAt(0)
                    }));

                    // Schedule next character with random delay (50-150ms)
                    setTimeout(() => typeCharacter(index + 1), 50 + Math.random() * 100);
                };

                // Start typing
                typeCharacter(0);

                // Return true immediately - the typing will complete asynchronously
                return true;
            }
            return false;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Successfully filled email with human-like behavior")
                // Add very short delay after filling (0.2-0.5 second)
                try? await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000 ... 500_000_000))
                return true
            } else {
                logger.error("Failed to fill email - field not found")
                return false
            }
        } catch {
            logger.error("Error filling email: \(error.localizedDescription)")
            return false
        }
    }

    func fillName(_ name: String) async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Add very short random delay before starting (0.2-0.8 seconds)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000 ... 800_000_000))

        // Simulate realistic mouse movement and human-like behavior
        await simulateRealisticMouseMovements()
        await simulateHumanScrolling()
        await simulateHumanFormInteraction()

        let script = """
        (function() {
            // Use exact selector from Python/Selenium implementation
            const nameField = document.querySelector('input[id^=\"field\"]');

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
                        nameField.dispatchEvent(new Event('change', { bubbles: true }));
                        nameField.blur();
                        console.log('[ODYSSEY] Name field filled with:', nameField.value);
                        return;
                    }

                    nameField.value += value[index];

                    // Dispatch realistic keyboard events
                    nameField.dispatchEvent(new KeyboardEvent('keydown', { 
                        bubbles: true, 
                        key: value[index], 
                        code: 'Key' + value[index].toUpperCase(),
                        keyCode: value[index].charCodeAt(0)
                    }));
                    nameField.dispatchEvent(new KeyboardEvent('keypress', { 
                        bubbles: true, 
                        key: value[index], 
                        code: 'Key' + value[index].toUpperCase(),
                        keyCode: value[index].charCodeAt(0)
                    }));
                    nameField.dispatchEvent(new Event('input', { bubbles: true }));
                    nameField.dispatchEvent(new KeyboardEvent('keyup', { 
                        bubbles: true, 
                        key: value[index], 
                        code: 'Key' + value[index].toUpperCase(),
                        keyCode: value[index].charCodeAt(0)
                    }));

                    // Schedule next character with random delay (50-150ms)
                    setTimeout(() => typeCharacter(index + 1), 50 + Math.random() * 100);
                };

                // Start typing
                typeCharacter(0);

                // Return true immediately - the typing will complete asynchronously
                return true;
            }
            return false;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Successfully filled name with human-like behavior")
                // Add very short delay after filling (0.2-0.5 second)
                try? await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000 ... 500_000_000))
                return true
            } else {
                logger.error("Failed to fill name - field not found")
                return false
            }
        } catch {
            logger.error("Error filling name: \(error.localizedDescription)")
            return false
        }
    }

    /// Detects if Google reCAPTCHA is present on the page
    func detectCaptcha() async -> Bool {
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
            let result = try await executeScriptInternal(script) as? Bool ?? false
            if result {
                logger.warning("Google reCAPTCHA detected on page")
            } else {
                logger.info("No reCAPTCHA detected")
            }
            return result
        } catch {
            logger.error("Error detecting captcha: \(error.localizedDescription)")
            return false
        }
    }

    /// Handles reCAPTCHA by implementing human-like behavior and waiting
    func handleCaptcha() async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        logger.info("Handling reCAPTCHA with human-like behavior...")

        // Inject anti-detection scripts
        await injectAntiDetectionScript()

        // Simulate human-like behavior before captcha
        await simulateScrolling()
        await moveMouseRandomly()
        await addRandomDelay()

        let script = """
        // Wait for reCAPTCHA to load and become interactive
        return new Promise((resolve) => {
            const checkCaptcha = () => {
                const recaptcha = document.querySelector('.g-recaptcha, .recaptcha, iframe[src*="recaptcha"]');
                if (recaptcha) {
                    console.log('[ODYSSEY] reCAPTCHA found, waiting for user interaction...');
                    // Scroll to captcha
                    recaptcha.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    resolve(true);
                } else {
                    setTimeout(checkCaptcha, 500);
                }
            };
            checkCaptcha();
        });
        """

        do {
            let result = try await executeScriptInternal(script) as? Bool ?? false
            if result {
                logger.info("reCAPTCHA detected and prepared for interaction")
                // Wait for manual captcha completion
                return await waitForCaptchaCompletion()
            } else {
                logger.error("Failed to detect reCAPTCHA")
                return false
            }
        } catch {
            logger.error("Error handling captcha: \(error.localizedDescription)")
            return false
        }
    }

    /// Waits for captcha completion by monitoring page changes
    func waitForCaptchaCompletion() async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        logger.info("Waiting for manual captcha completion...")

        // Wait up to 2 minutes for captcha completion
        let startTime = Date()
        let timeout: TimeInterval = 120 // 2 minutes

        while Date().timeIntervalSince(startTime) < timeout {
            // Check if captcha is still present
            let captchaStillPresent = await detectCaptcha()

            if !captchaStillPresent {
                logger.info("reCAPTCHA appears to be completed")
                await addRandomDelay()
                return true
            }

            // Check for success indicators
            let successScript = """
            const successIndicators = document.querySelectorAll('[class*="success"], [class*="verified"], [class*="completed"]');
            const errorIndicators = document.querySelectorAll('[class*="error"], [class*="failed"], [class*="invalid"]');

            if (errorIndicators.length > 0) {
                return 'error';
            } else if (successIndicators.length > 0) {
                return 'success';
            }
            return 'waiting';
            """

            do {
                let status = try await executeScriptInternal(successScript) as? String ?? "waiting"
                if status == "success" {
                    logger.info("reCAPTCHA completed successfully")
                    return true
                } else if status == "error" {
                    logger.error("reCAPTCHA verification failed")
                    return false
                }
            } catch {
                logger.error("Error checking captcha status: \(error.localizedDescription)")
            }

            // Wait before checking again
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }

        logger.error("reCAPTCHA completion timeout")
        return false
    }

    func clickContactInfoConfirmButtonWithRetry() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        // Add shorter human-like delay before clicking (1-2 seconds)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000 ... 2_000_000_000))

        // Simulate realistic mouse movements and human-like behaviors
        await simulateRealisticMouseMovements()
        await simulateHumanScrolling()
        await simulateRandomKeyboardEvents()

        let script = """
        (function() {
            // Use exact selector from Python/Selenium implementation
            const button = document.querySelector('.mdc-button__ripple');

            console.log('[ODYSSEY] Confirm button found:', button ? {
                tagName: button.tagName,
                className: button.className,
                textContent: button.textContent.trim(),
                visible: !!(button.offsetWidth || button.offsetHeight || button.getClientRects().length)
            } : 'NOT FOUND');

            if (button) {
                // Scroll to button with human-like behavior
                button.scrollIntoView({ behavior: 'smooth', block: 'center' });

                                // Simulate realistic mouse movement and hover
                button.dispatchEvent(new MouseEvent('mouseenter', { 
                    bubbles: true, 
                    clientX: button.getBoundingClientRect().left + 10,
                    clientY: button.getBoundingClientRect().top + 10
                }));

                button.dispatchEvent(new MouseEvent('mouseover', { 
                    bubbles: true, 
                    clientX: button.getBoundingClientRect().left + 15,
                    clientY: button.getBoundingClientRect().top + 15
                }));

                // Click with human-like behavior
                button.dispatchEvent(new MouseEvent('mousedown', { 
                    bubbles: true, 
                    button: 0,
                    clientX: button.getBoundingClientRect().left + 20,
                    clientY: button.getBoundingClientRect().top + 20
                }));

                button.dispatchEvent(new MouseEvent('mouseup', { 
                    bubbles: true, 
                    button: 0,
                    clientX: button.getBoundingClientRect().left + 20,
                    clientY: button.getBoundingClientRect().top + 20
                }));

                button.dispatchEvent(new MouseEvent('click', { 
                    bubbles: true, 
                    button: 0,
                    clientX: button.getBoundingClientRect().left + 20,
                    clientY: button.getBoundingClientRect().top + 20
                }));

                console.log('[ODYSSEY] Clicked confirm button with ultra-human-like behavior');
                return true;
            }

            // Fallback to other common submit button selectors
            const fallbackButton = document.querySelector('button[type="submit"]') || 
                                  document.querySelector('input[type="submit"]') || 
                                  document.querySelector('button:contains("Submit")') ||
                                  document.querySelector('button:contains("Confirm")');

            if (fallbackButton) {
                console.log('[ODYSSEY] Using fallback confirm button:', fallbackButton.tagName);
                fallbackButton.scrollIntoView({ behavior: 'smooth', block: 'center' });

                // Use setTimeout for delays instead of await
                setTimeout(() => {
                    fallbackButton.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, button: 0 }));
                    setTimeout(() => {
                        fallbackButton.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, button: 0 }));
                        fallbackButton.dispatchEvent(new MouseEvent('click', { bubbles: true, button: 0 }));
                    }, 50 + Math.random() * 100);
                }, 300 + Math.random() * 200);

                return true;
            }

            return false;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Successfully clicked contact info confirm button with human-like behavior")
                return true
            } else {
                logger.error("Failed to click contact info confirm button")
                return false
            }
        } catch {
            logger.error("Error clicking contact info confirm button: \(error.localizedDescription)")
            return false
        }
    }

    func isEmailVerificationRequired() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            const verificationElements = document.querySelectorAll('[class*="verification"], [id*="verification"], [class*="verify"], [id*="verify"]');
            return verificationElements.length > 0;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Email verification required")
            } else {
                logger.info("No email verification required")
            }
            return result
        } catch {
            logger.error("Error checking email verification: \(error.localizedDescription)")
            return false
        }
    }

    func handleEmailVerification(verificationStart _: Date) async -> Bool {
        guard webView != nil else {
            logger.error("WebView not initialized")
            return false
        }

        logger.info("Handling email verification...")

        // Placeholder implementation - will be fully implemented later
        let script = """
        // Placeholder for email verification handling
        console.log('Handling email verification...');
        return true;
        """

        do {
            let result = try await executeScriptInternal(script) as? Bool ?? false
            if result {
                logger.info("Email verification completed successfully")
                return true
            } else {
                logger.error("Email verification failed")
                return false
            }
        } catch {
            logger.error("Error handling email verification: \(error.localizedDescription)")
            return false
        }
    }

    func checkReservationSuccess() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            const successElements = document.querySelectorAll('[class*="success"], [id*="success"], [class*="confirmed"], [id*="confirmed"]');
            const errorElements = document.querySelectorAll('[class*="error"], [id*="error"], [class*="failed"], [id*="failed"]');

            if (errorElements.length > 0) {
                return false;
            }

            if (successElements.length > 0) {
                return true;
            }

            // Check for confirmation text
            const bodyText = document.body.textContent || '';
            if (bodyText.includes('confirmed') || bodyText.includes('success') || bodyText.includes('booked')) {
                return true;
            }

            return false;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script) as? Bool ?? false
            if result {
                logger.info("Reservation success detected")
            } else {
                logger.info("Reservation success not detected")
            }
            return result
        } catch {
            logger.error("Error checking reservation success: \(error.localizedDescription)")
            return false
        }
    }

    /// Detects if "Retry" text appears on the page (indicating reCAPTCHA failure)
    func detectRetryText() async -> Bool {
        guard let webView else {
            logger.error("WebView not initialized")
            return false
        }

        let script = """
        (function() {
            // Check for "Retry" text in various contexts
            const bodyText = document.body.textContent || '';
            const retryIndicators = [
                'retry',
                'try again',
                'verification failed',
                'please try again',
                'captcha failed',
                'robot verification failed'
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
                logger.warning("Retry text detected - reCAPTCHA likely failed")
            }
            return result
        } catch {
            logger.error("Error detecting retry text: \(error.localizedDescription)")
            return false
        }
    }

    /// Enhanced human-like behavior to avoid reCAPTCHA detection
    func enhanceHumanLikeBehavior() async {
        guard let webView else { return }

        logger.info("Enhancing human-like behavior to avoid reCAPTCHA detection...")

        // Inject enhanced anti-detection scripts
        let antiDetectionScript = """
        (function() {
            // Override common bot detection methods
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined,
            });

            // Add realistic mouse movement patterns
            window.odysseyMouseMovements = [];
            const originalAddEventListener = EventTarget.prototype.addEventListener;
            EventTarget.prototype.addEventListener = function(type, listener, options) {
                if (type === 'mousemove') {
                    const wrappedListener = function(event) {
                        window.odysseyMouseMovements.push({
                            x: event.clientX,
                            y: event.clientY,
                            timestamp: Date.now()
                        });
                        // Keep only last 100 movements
                        if (window.odysseyMouseMovements.length > 100) {
                            window.odysseyMouseMovements.shift();
                        }
                        return listener.call(this, event);
                    };
                    return originalAddEventListener.call(this, type, wrappedListener, options);
                }
                return originalAddEventListener.call(this, type, listener, options);
            };

            // Add realistic scroll patterns
            let lastScrollTime = 0;
            const originalScrollTo = window.scrollTo;
            window.scrollTo = function(x, y) {
                const now = Date.now();
                if (now - lastScrollTime > 100) { // Minimum 100ms between scrolls
                    lastScrollTime = now;
                    return originalScrollTo.call(this, x, y);
                }
            };

            // Add realistic focus/blur patterns
            const originalFocus = HTMLElement.prototype.focus;
            HTMLElement.prototype.focus = function() {
                // Add small random delay before focus
                setTimeout(() => {
                    originalFocus.call(this);
                }, Math.random() * 50);
            };

            console.log('[ODYSSEY] Enhanced anti-detection measures activated');
        })();
        """

        do {
            try await webView.evaluateJavaScript(antiDetectionScript)
            logger.info("Enhanced anti-detection measures activated")
        } catch {
            logger.error("Error injecting anti-detection script: \(error.localizedDescription)")
        }

        // Simulate more realistic human behavior
        await simulateRealisticScrolling()
        await simulateRealisticMouseMovements()
        await addNaturalPauses()
    }

    /// Simulates realistic scrolling patterns
    private func simulateRealisticScrolling() async {
        guard let webView else { return }

        let scrollScript = """
        (function() {
            // Simulate natural scrolling with variable speeds
            const scrollSteps = [
                { y: 100, delay: 150 },
                { y: 200, delay: 200 },
                { y: 150, delay: 180 },
                { y: 300, delay: 250 },
                { y: 100, delay: 120 }
            ];

            let currentStep = 0;
            const scrollInterval = setInterval(() => {
                if (currentStep < scrollSteps.length) {
                    const step = scrollSteps[currentStep];
                    window.scrollBy(0, step.y);
                    currentStep++;
                } else {
                    clearInterval(scrollInterval);
                }
            }, 100);
        })();
        """

        do {
            try await webView.evaluateJavaScript(scrollScript)
        } catch {
            logger.error("Error simulating realistic scrolling: \(error.localizedDescription)")
        }
    }

    /// Simulates realistic mouse movements
    private func simulateRealisticMouseMovements() async {
        guard let webView else { return }

        let mouseScript = """
        (function() {
            // Simulate natural mouse movements with acceleration/deceleration
            const simulateMouseMove = (startX, startY, endX, endY, duration) => {
                const steps = 20;
                const stepDelay = duration / steps;
                let currentStep = 0;

                const interval = setInterval(() => {
                    if (currentStep >= steps) {
                        clearInterval(interval);
                        return;
                    }

                    const progress = currentStep / steps;
                    // Use easing function for natural movement
                    const easeProgress = 1 - Math.pow(1 - progress, 3);

                    const x = startX + (endX - startX) * easeProgress;
                    const y = startY + (endY - startY) * easeProgress;

                    // Dispatch mouse move event
                    document.dispatchEvent(new MouseEvent('mousemove', {
                        bubbles: true,
                        clientX: x,
                        clientY: y
                    }));

                    currentStep++;
                }, stepDelay);
            };

            // Simulate a few mouse movements
            setTimeout(() => simulateMouseMove(100, 100, 300, 200, 500), 200);
            setTimeout(() => simulateMouseMove(300, 200, 500, 150, 400), 800);
            setTimeout(() => simulateMouseMove(500, 150, 200, 300, 600), 1300);
        })();
        """

        do {
            try await webView.evaluateJavaScript(mouseScript)
        } catch {
            logger.error("Error simulating realistic mouse movements: \(error.localizedDescription)")
        }
    }

    /// Adds natural pauses and delays
    private func addNaturalPauses() async {
        // Add random pauses to simulate human thinking/reading
        let pauseDuration = UInt64.random(in: 500_000_000 ... 2_000_000_000) // 0.5-2 seconds
        try? await Task.sleep(nanoseconds: pauseDuration)
    }

    /// Simulates random mouse clicks on empty areas (like humans do)
    private func simulateRandomMouseClicks() async {
        guard let webView else { return }

        // Simulate random mouse clicks on empty areas (like humans do)
        let randomClicks = Int.random(in: 0 ... 2) // 0-2 random clicks

        for _ in 0 ..< randomClicks {
            try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000 ... 500_000_000))

            // Simulate clicking on empty space
            let script = """
                (function() {
                    // Find a random empty area to click
                    const body = document.body;
                    const rect = body.getBoundingClientRect();
                    const x = Math.random() * (rect.width - 100) + 50;
                    const y = Math.random() * (rect.height - 100) + 50;

                    // Create and dispatch mouse events
                    const clickEvent = new MouseEvent('click', {
                        bubbles: true,
                        cancelable: true,
                        view: window,
                        clientX: x,
                        clientY: y,
                        button: 0
                    });

                                document.elementFromPoint(x, y)?.dispatchEvent(clickEvent);
                console.log('[ODYSSEY] Random click at:', x, y);
            })();
            """

            _ = try? await webView.evaluateJavaScript(script)
        }
    }

    /// Simulates human-like scrolling patterns
    private func simulateHumanScrolling() async {
        guard let webView else { return }

        // Simulate human-like scrolling patterns
        let scrollPatterns = [
            (direction: "down", distance: 100),
            (direction: "up", distance: 50),
            (direction: "down", distance: 200),
            (direction: "up", distance: 75),
        ]

        for pattern in scrollPatterns {
            try? await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000 ... 800_000_000))

            let script = """
                (function() {
                    const scrollDistance = \(pattern.distance);
                    window.scrollBy({
                        top: scrollDistance,
                        behavior: 'smooth'
                    });
                                console.log('[ODYSSEY] Human-like scroll:', '\(pattern.direction)', scrollDistance);
            })();
            """

            _ = try? await webView.evaluateJavaScript(script)
        }
    }

    /// Simulates random keyboard events (like humans accidentally pressing keys)
    private func simulateRandomKeyboardEvents() async {
        guard let webView else { return }

        // Simulate random keyboard events (like humans accidentally pressing keys)
        let randomEvents = Int.random(in: 0 ... 1) // 0-1 random events

        for _ in 0 ..< randomEvents {
            try? await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000 ... 1_000_000_000))

            let script = """
                (function() {
                    // Random keys that humans might accidentally press
                    const randomKeys = ['Tab', 'Escape', 'ArrowUp', 'ArrowDown'];
                    const randomKey = randomKeys[Math.floor(Math.random() * randomKeys.length)];

                    const keyEvent = new KeyboardEvent('keydown', {
                        bubbles: true,
                        key: randomKey,
                        code: randomKey,
                        keyCode: randomKey.charCodeAt ? randomKey.charCodeAt(0) : 0
                    });

                    document.activeElement?.dispatchEvent(keyEvent);
                                console.log('[ODYSSEY] Random keyboard event:', randomKey);
            })();
            """

            _ = try? await webView.evaluateJavaScript(script)
        }
    }

    /// Simulates human-like form interaction patterns
    private func simulateHumanFormInteraction() async {
        guard let webView else { return }

        // Simulate human-like form interaction patterns
        let script = """
            (function() {
                // Simulate random form field focus/blur events
                const formFields = document.querySelectorAll('input, textarea, select');
                if (formFields.length > 0) {
                    const randomField = formFields[Math.floor(Math.random() * formFields.length)];

                    // Random focus/blur
                    if (Math.random() < 0.3) {
                        randomField.focus();
                        setTimeout(() => {
                            randomField.blur();
                        }, Math.random() * 1000 + 500);
                    }

                    // Random hover events
                    if (Math.random() < 0.2) {
                        randomField.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
                        setTimeout(() => {
                            randomField.dispatchEvent(new MouseEvent('mouseleave', { bubbles: true }));
                        }, Math.random() * 2000 + 1000);
                    }
                }

                        console.log('[ODYSSEY] Human-like form interaction simulated');
        })();
        """

        _ = try? await webView.evaluateJavaScript(script)
    }
}

// MARK: - Navigation Delegate

class WebKitNavigationDelegate: NSObject, WKNavigationDelegate {
    weak var delegate: WebKitService?

    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        delegate?.logger.info("[Navigation] Started loading: \(webView.url?.absoluteString ?? "unknown")")
        print("[Navigation] Started loading: \(webView.url?.absoluteString ?? "unknown")")
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        delegate?.currentURL = webView.url?.absoluteString
        delegate?.pageTitle = webView.title
        delegate?.logger.info("[Navigation] Completed: \(webView.url?.absoluteString ?? "unknown")")
        print("[Navigation] Completed: \(webView.url?.absoluteString ?? "unknown")")

        // Notify any waiting navigation completions
        if let delegate {
            for (_, completion) in delegate.navigationCompletions {
                completion(true)
            }
            delegate.navigationCompletions.removeAll()
        }
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        delegate?.logger.error("[Navigation] Failed: \(error.localizedDescription)")
        print("[Navigation] Failed: \(error.localizedDescription)")

        // Notify any waiting navigation completions
        if let delegate {
            for (_, completion) in delegate.navigationCompletions {
                completion(false)
            }
            delegate.navigationCompletions.removeAll()
        }
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        delegate?.logger.error("[Navigation] Provisional navigation failed: \(error.localizedDescription)")
        print("[Navigation] Provisional navigation failed: \(error.localizedDescription)")
    }

    func webView(
        _: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void,
    ) {
        delegate?.logger
            .info("[Navigation] Policy decision for: \(navigationAction.request.url?.absoluteString ?? "unknown")")
        print("[Navigation] Policy decision for: \(navigationAction.request.url?.absoluteString ?? "unknown")")
        decisionHandler(.allow)
    }
}

// MARK: - Script Message Handler

class WebKitScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WebKitService?

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "odysseyHandler" {
            if let body = message.body as? [String: Any], let type = body["type"] as? String {
                switch type {
                case "scriptInjected":
                    delegate?.logger.info("Automation scripts injected successfully")
                case "contactFormCheckError":
                    if
                        let data = body["data"] as? [String: Any], let msg = data["message"] as? String,
                        let stack = data["stack"] as? String
                    {
                        delegate?.logger.error("[ContactForm][JS] Error: \(msg)\nStack: \(stack)")
                    }
                case "contactFormTimeout":
                    if
                        let data = body["data"] as? [String: Any], let html = data["html"] as? String,
                        let allInputs = data["allInputs"]
                    {
                        let allInputsStr = String(describing: allInputs)
                        delegate?.logger
                            .error("[ContactForm][JS] Timeout. HTML: \(html.prefix(1_000))\nInputs: \(allInputsStr)")
                    }
                case "contactFormTimeoutError":
                    if
                        let data = body["data"] as? [String: Any], let msg = data["message"] as? String,
                        let stack = data["stack"] as? String
                    {
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

class WebKitElement: WebElementProtocol {
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

        let result = try await service.executeScriptInternal(script) as? Bool ?? false
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

        let result = try await service.executeScriptInternal(script) as? Bool ?? false
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

        let result = try await service.executeScriptInternal(script) as? Bool ?? false
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

        return try await service.executeScriptInternal(script) as? String
    }

    func getText() async throws -> String {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        return element ? element.textContent || '' : '';
        """

        return try await service.executeScriptInternal(script) as? String ?? ""
    }

    func isDisplayed() async throws -> Bool {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        return element ? element.offsetParent !== null : false;
        """

        let result = try await service.executeScriptInternal(script)
        return result as? Bool ?? false
    }

    func isEnabled() async throws -> Bool {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        return element ? !element.disabled : false;
        """

        let result = try await service.executeScriptInternal(script)
        return result as? Bool ?? false
    }

    func isSelected() async throws -> Bool {
        let script = """
        const element = document.querySelector('[data-odyssey-id="\(id)"]');
        return element ? element.selected : false;
        """

        return try await service.executeScriptInternal(script) as? Bool ?? false
    }
}
