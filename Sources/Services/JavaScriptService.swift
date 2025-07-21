import Foundation
import os.log

/// Service for managing JavaScript code and operations
/// Extracted from WebKitService to improve code organization
@MainActor
class JavaScriptService: ObservableObject {
    static let shared = JavaScriptService()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "JavaScriptService")

    private init() { }

    // MARK: - Anti-Detection Scripts

    /// Generates anti-detection script with custom parameters
    func generateAntiDetectionScript(
        userAgent: String? = nil,
        language: String? = nil,
        instanceId: String? = nil,
        ) -> String {
        let selectedUserAgent = userAgent ??
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        let lang = language?.components(separatedBy: ",").first ?? "en-US"
        let langs = language?.components(separatedBy: ",") ?? ["en-US", "en"]
        _ = instanceId != nil ? "odyssey_\(instanceId!)_" : "odyssey_"

        return """
        (function() {
            try {
                // Remove webdriver property
                Object.defineProperty(navigator, 'webdriver', {
                    get: () => undefined,
                    configurable: true
                });

                // Fake plugins and languages
                Object.defineProperty(navigator, 'plugins', {
                    get: () => {
                        const plugins = [];
                        const mockPlugins = [
                            { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer', description: 'Portable Document Format' },
                            { name: 'Chrome PDF Viewer', filename: 'mhjfbmdgcfjbbpaeojofohoefgiehjai', description: '' },
                            { name: 'Native Client', filename: 'internal-nacl-plugin', description: '' }
                        ];
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

                Object.defineProperty(navigator, 'languages', {
                    get: () => \(langs),
                    configurable: true
                });

                Object.defineProperty(navigator, 'language', {
                    get: () => '\(lang)',
                    configurable: true
                });

                // Fake Chrome object
                window.chrome = { runtime: {} };

                // Patch permissions
                const originalQuery = window.navigator.permissions.query;
                window.navigator.permissions.query = (parameters) =>
                    parameters.name === 'notifications'
                        ? Promise.resolve({ state: Notification.permission })
                        : originalQuery(parameters);

                // User-Agent override
                Object.defineProperty(navigator, 'userAgent', {
                    get: () => '\(selectedUserAgent)',
                    configurable: true
                });

                // Hardware properties
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

                // Screen properties
                Object.defineProperty(screen, 'width', {
                    get: () => 1440,
                    configurable: true
                });

                Object.defineProperty(screen, 'height', {
                    get: () => 900,
                    configurable: true
                });

                Object.defineProperty(screen, 'availWidth', {
                    get: () => 1440,
                    configurable: true
                });

                Object.defineProperty(screen, 'availHeight', {
                    get: () => 900,
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

                // WebGL fingerprint spoof
                const getParameter = WebGLRenderingContext.prototype.getParameter;
                WebGLRenderingContext.prototype.getParameter = function(parameter) {
                    if (parameter === 37445) return 'Intel Inc.';
                    if (parameter === 37446) return 'Intel(R) Iris(TM) Plus Graphics 640';
                    return getParameter.call(this, parameter);
                };

                // Canvas fingerprint spoof
                const toDataURL = HTMLCanvasElement.prototype.toDataURL;
                HTMLCanvasElement.prototype.toDataURL = function() {
                    return toDataURL.apply(this, arguments) + 'a';
                };

                // Remove automation indicators
                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Array) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array;
                }
                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Promise) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise;
                }
                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol;
                }

                // Add mouse movement tracking
                if (!window.odysseyMouseMovements) {
                    window.odysseyMouseMovements = [];
                }

                // Anti-detection measures applied
            } catch (error) {
                console.error('[ODYSSEY] Error in anti-detection script:', error);
            }
        })();
        """
    }

    // MARK: - Form Filling Scripts

    /// Generates script to fill contact fields with autofill behavior
    func generateContactFormFillingScript(phoneNumber: String, email: String, name: String) -> String {
        return """
        (function() {
            try {
                // Find contact fields
                const phoneField = document.getElementById('phone') ||
                                 document.getElementById('telephone') ||
                                 document.getElementById('phoneNumber') ||
                                 document.querySelector('input[type="tel"]') ||
                                 document.querySelector('input[name*="phone"]') ||
                                 document.querySelector('input[name*="tel"]') ||
                                 document.querySelector('input[placeholder*="phone"]') ||
                                 document.querySelector('input[placeholder*="tel"]') ||
                                 document.querySelector('input[placeholder*="Phone"]') ||
                                 document.querySelector('input[placeholder*="Telephone"]');

                const emailField = document.getElementById('email') ||
                                 document.getElementById('mail') ||
                                 document.querySelector('input[type="email"]') ||
                                 document.querySelector('input[name*="email"]') ||
                                 document.querySelector('input[name*="mail"]') ||
                                 document.querySelector('input[placeholder*="email"]') ||
                                 document.querySelector('input[placeholder*="Email"]') ||
                                 document.querySelector('input[placeholder*="mail"]');

                const nameField = document.getElementById('name') ||
                                document.getElementById('fullName') ||
                                document.getElementById('firstName') ||
                                document.querySelector('input[name*="name"]') ||
                                document.querySelector('input[name*="full"]') ||
                                document.querySelector('input[name*="first"]') ||
                                document.querySelector('input[placeholder*="name"]') ||
                                document.querySelector('input[placeholder*="Name"]') ||
                                document.querySelector('input[placeholder*="Full"]');

                // Fill fields with autofill behavior
                if (phoneField) {
                    phoneField.focus();
                    phoneField.value = '\(phoneNumber)';
                    phoneField.dispatchEvent(new Event('input', { bubbles: true }));
                    phoneField.dispatchEvent(new Event('change', { bubbles: true }));
                }

                if (emailField) {
                    emailField.focus();
                    emailField.value = '\(email)';
                    emailField.dispatchEvent(new Event('input', { bubbles: true }));
                    emailField.dispatchEvent(new Event('change', { bubbles: true }));
                }

                if (nameField) {
                    nameField.focus();
                    nameField.value = '\(name)';
                    nameField.dispatchEvent(new Event('input', { bubbles: true }));
                    nameField.dispatchEvent(new Event('change', { bubbles: true }));
                }

                return {
                    phoneFilled: !!phoneField,
                    emailFilled: !!emailField,
                    nameFilled: !!nameField
                };
            } catch (error) {
                console.error('[ODYSSEY] Error filling contact fields:', error);
                return { phoneFilled: false, emailFilled: false, nameFilled: false };
            }
        })();
        """
    }

    // MARK: - Element Interaction Scripts

    /// Generates script to find and click element with specific text
    func generateFindAndClickScript(targetText: String) -> String {
        return """
        (function() {
            try {
                const targetText = '\(targetText)';
                const elements = Array.from(document.querySelectorAll('button, div, a, span, label'));

                for (const el of elements) {
                    const text = el.textContent?.trim();
                    if (text && text.includes(targetText)) {
                        el.click();
                        return true;
                    }
                }

                return false;
            } catch (error) {
                console.error('[ODYSSEY] Error finding element:', error);
                return false;
            }
        })();
        """
    }

    /// Generates script to check if DOM is ready
    func generateDOMReadyCheckScript() -> String {
        return """
        (function() {
            return document.readyState === 'complete';
        })();
        """
    }

    // MARK: - Utility Scripts

    /// Generates script to detect reCAPTCHA
    static func generateCaptchaDetectionScript() -> String {
        return """
        (function() {
            const captchaSelectors = [
                '.g-recaptcha',
                '#recaptcha',
                '.recaptcha',
                'iframe[src*="recaptcha"]',
                'div[data-sitekey]'
            ];

            for (const selector of captchaSelectors) {
                if (document.querySelector(selector)) {
                    return true;
                }
            }

            return false;
        })();
        """
    }
}
