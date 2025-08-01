import Foundation
import os.log

/// Centralized JavaScript library for ODYSSEY automation
/// Consolidates all JavaScript functionality to eliminate duplication and improve maintainability
@MainActor
public final class JavaScriptLibrary {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "JavaScriptLibrary")

    // MARK: - Complete Library

    /// Get the complete automation library with all modules
    public static func getCompleteLibrary() -> String {
        return """
        \(JavaScriptCore.coreLibrary)

        // Extend with form handling
        Object.assign(window.odyssey, {
        \(JavaScriptForms.formsLibrary)
        });

        // Extend with page detection
        Object.assign(window.odyssey, {
        \(JavaScriptPages.pagesLibrary)
        });

        // Extend with advanced automation
        Object.assign(window.odyssey, {
        \(getAdvancedAutomationLibrary())
        });

        // Extend with sports detection
        Object.assign(window.odyssey, {
        \(getSportsDetectionLibrary())
        });
        """
    }

    // MARK: - Advanced Automation Library

    /// Advanced automation functions for complex interactions
    private static func getAdvancedAutomationLibrary() -> String {
        return getBasicAutomationFunctions() + getAntiDetectionFunctions() + getSessionFunctions() +
            getInteractionFunctions()
    }

    /// Basic automation functions
    private static func getBasicAutomationFunctions() -> String {
        return """
        // ===== BASIC AUTOMATION =====

        // Simulate quick mouse movement
        simulateQuickMouseMovement: function() {
            const randomX = Math.random() * window.innerWidth;
            const randomY = Math.random() * window.innerHeight;

            document.dispatchEvent(new MouseEvent('mousemove', {
                bubbles: true,
                cancelable: true,
                view: window,
                clientX: randomX,
                clientY: randomY
            }));

            return true;
        },

        // Simulate quick scrolling
        simulateQuickScrolling: function() {
            const scrollAmount = Math.random() * 100 + 50;
            window.scrollBy(0, scrollAmount);
            return true;
        },
        """
    }

    /// Anti-detection functions
    private static func getAntiDetectionFunctions() -> String {
        return """
        // ===== ANTI-DETECTION =====

        // Apply comprehensive anti-detection measures
        applyBasicAntiDetection: function() {
            try {
                this.applySessionManagement();
                this.overrideNavigatorProperties();
                this.removeChromeAutomationFlags();
                this.overrideScreenProperties();
                this.overrideWindowProperties();
                this.setWindowName();

                console.log('[ODYSSEY] Enhanced anti-detection measures applied');
                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error in anti-detection script:', error);
                return false;
            }
        },

        // Session management
        applySessionManagement: function() {
            if (window.sessionStorage) {
                if (!window.sessionStorage.getItem('odyssey_session_id')) {
                    window.sessionStorage.setItem('odyssey_session_id', Date.now().toString());
                }
            }
        },

        // Override navigator properties
        overrideNavigatorProperties: function() {
            if (navigator.webdriver !== undefined) {
                Object.defineProperty(navigator, 'webdriver', {
                    get: () => undefined,
                    configurable: true
                });
            }

            if (navigator.hardwareConcurrency) {
                Object.defineProperty(navigator, 'hardwareConcurrency', {
                    get: () => 8,
                    configurable: true
                });
            }
        },

        // Remove Chrome automation flags
        removeChromeAutomationFlags: function() {
            if (window.cdc_adoQpoasnfa76pfcZLmcfl_Array) {
                delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array;
            }
            if (window.cdc_adoQpoasnfa76pfcZLmcfl_Promise) {
                delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise;
            }
            if (window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol) {
                delete window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol;
            }
        },

        // Override screen properties
        overrideScreenProperties: function() {
            if (screen.width) {
                Object.defineProperty(screen, 'width', {
                    get: () => 1440,
                    configurable: true
                });
            }
            if (screen.height) {
                Object.defineProperty(screen, 'height', {
                    get: () => 900,
                    configurable: true
                });
            }

            if (navigator.userAgent) {
                Object.defineProperty(navigator, 'userAgent', {
                    get: () => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    configurable: true
                });
            }
        },

        // Override window properties
        overrideWindowProperties: function() {
            if (window.outerWidth) {
                Object.defineProperty(window, 'outerWidth', {
                    get: () => 1440,
                    configurable: true
                });
            }
            if (window.outerHeight) {
                Object.defineProperty(window, 'outerHeight', {
                    get: () => 900,
                    configurable: true
                });
            }
        },

        // Set window name
        setWindowName: function() {
            if (window.name) {
                window.name = 'odyssey_main_window';
            }
        },
        """
    }

    /// Session management functions
    private static func getSessionFunctions() -> String {
        return """
        // ===== SESSION MANAGEMENT =====

        // Clean up session and prevent multiple tab detection
        cleanupSession: function() {
            try {
                this.clearSessionData();
                this.clearLocalStorageConflicts();
                this.setWindowName();

                console.log('[ODYSSEY] Enhanced session cleanup completed');
                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error in session cleanup:', error);
                return false;
            }
        },

        // Clear session data
        clearSessionData: function() {
            if (window.sessionStorage) {
                const sessionId = window.sessionStorage.getItem('odyssey_session_id');
                if (sessionId) {
                    console.log('[ODYSSEY] Maintaining session ID:', sessionId);
                } else {
                    const newSessionId = Date.now().toString();
                    window.sessionStorage.setItem('odyssey_session_id', newSessionId);
                    console.log('[ODYSSEY] Created new session ID:', newSessionId);
                }
            }
        },

        // Clear localStorage conflicts
        clearLocalStorageConflicts: function() {
            if (window.localStorage) {
                const keysToRemove = [];
                for (let i = 0; i < window.localStorage.length; i++) {
                    const key = window.localStorage.key(i);
                    if (key && (key.includes('session') || key.includes('tab') || key.includes('browser') || key.includes('multiple'))) {
                        keysToRemove.push(key);
                    }
                }

                keysToRemove.forEach(key => {
                    window.localStorage.removeItem(key);
                    console.log('[ODYSSEY] Removed conflicting session data:', key);
                });
            }
        },
        """
    }

    /// Interaction functions
    private static func getInteractionFunctions() -> String {
        return """
        // ===== INTERACTION FUNCTIONS =====

        // Click contact info confirm button (unified approach)
        clickContactInfoConfirmButton: function() {
            try {
                const selectors = [
                    'button[id="submit-btn"]',
                    '#submit-btn',
                    'button[type="submit"]',
                    'input[type="submit"]'
                ];

                for (let selector of selectors) {
                    const element = document.querySelector(selector);
                    if (element) {
                        element.focus();
                        element.click();
                        return true;
                    }
                }
                return false;
            } catch (error) {
                return false;
            }
        },

        // Handle captcha retry with human behavior simulation
        handleCaptchaRetry: function() {
            try {
                console.log('[ODYSSEY] Starting captcha retry with human behavior simulation...');

                this.simulateQuickMouseMovement();
                console.log('[ODYSSEY] Mouse movement simulated');

                this.simulateQuickScrolling();
                console.log('[ODYSSEY] Scroll simulated');

                // Small delay (synchronous)
                const start = Date.now();
                while (Date.now() - start < 1000) {
                    // Busy wait for 1 second
                }
                console.log('[ODYSSEY] Delay completed');

                const clickResult = this.clickContactInfoConfirmButton();
                console.log('[ODYSSEY] Click result:', clickResult);
                return clickResult;
            } catch (error) {
                console.error('[ODYSSEY] Error in handleCaptchaRetry:', error);
                return false;
            }
        },

        // Click confirm button (for group size form) - uses unified approach
        clickConfirmButton: function() {
            try {
                const result = this.clickContactInfoConfirmButton();
                return result ? 'clicked' : 'not found';
            } catch (error) {
                return 'error: ' + error.message;
            }
        },

        // Check page state
        checkPageState: function() {
            let errors = Array.from(document.querySelectorAll('.error, .alert, .message, [class*="error"], [class*="alert"]')).map(el => el.innerText);
            let loading = Array.from(document.querySelectorAll('[class*="loading"], [class*="spinner"], .disabled')).map(el => el.innerText);
            let buttons = Array.from(document.querySelectorAll('button')).map(el => ({
                text: el.textContent || el.innerText || '',
                className: el.className,
                id: el.id
            }));

            return {
                errors: errors,
                loading: loading,
                buttons: buttons,
                url: window.location.href,
                title: document.title
            };
        },

        // Expand day section
        expandDaySection: function(dayName) {
            try {
                const headerElements = Array.from(document.getElementsByClassName('header-text'));
                const targetDayName = dayName.trim().toLowerCase();

                for (let i = 0; i < headerElements.length; i++) {
                    const el = headerElements[i];
                    const headerText = el.textContent.trim().toLowerCase();
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);

                    if (headerText.includes(targetDayName) && visible) {
                        el.scrollIntoView({behavior: 'smooth', block: 'center'});
                        el.click();
                        return true;
                    }
                }

                // Fallback: try partial matching
                const dayParts = targetDayName.split(/\\s+/).filter(Boolean);
                for (let i = 0; i < headerElements.length; i++) {
                    const el = headerElements[i];
                    const headerText = el.textContent.trim().toLowerCase();
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);

                    const hasMatch = dayParts.some(part => part && headerText.includes(part));
                    if (hasMatch && visible) {
                        el.scrollIntoView({behavior: 'smooth', block: 'center'});
                        el.click();
                        return true;
                    }
                }

                return false;
            } catch (error) {
                console.error('[ODYSSEY] Error expanding day section:', error);
                return false;
            }
        },

        // Click time button
        clickTimeButton: function(timeString, dayName) {
            try {
                const timeSlotSelector = `[aria-label*='${timeString} ${dayName}']`;
                const timeSlotElements = Array.from(document.querySelectorAll(timeSlotSelector));

                for (let i = 0; i < timeSlotElements.length; i++) {
                    const el = timeSlotElements[i];
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);
                    if (visible) {
                        el.scrollIntoView({behavior: 'smooth', block: 'center'});
                        el.click();
                        return true;
                    }
                }

                return false;
            } catch (error) {
                console.error('[ODYSSEY] Error clicking time button:', error);
                return false;
            }
        }
        """
    }

    // MARK: - Sports Detection Library

    /// Sports detection functions
    private static func getSportsDetectionLibrary() -> String {
        return """
        // ===== SPORTS DETECTION =====

        // Detect sports from button elements on the page
        detectSports: function() {
            try {
                const sports = [];
                const buttonNoImgElements = document.querySelectorAll('.button.no-img');

                buttonNoImgElements.forEach((element) => {
                    const text = element.textContent || element.innerText || '';
                    const trimmedText = text.trim();

                    if (trimmedText.length > 0) {
                        const isDuplicate = sports.some(existing =>
                            existing.toLowerCase() === trimmedText.toLowerCase()
                        );

                        if (!isDuplicate) {
                            sports.push(trimmedText);
                        }
                    }
                });

                return sports;
            } catch (error) {
                return [];
            }
        }
        """
    }

    // MARK: - Public Methods

    /// Get the automation library
    public static func getAutomationLibrary() -> String {
        return getCompleteLibrary()
    }

    /// Get the anti-detection library
    public static func getAntiDetectionLibrary() -> String {
        return getAdvancedAutomationLibrary()
    }

    /// Get the mouse movement library
    public static func getMouseMovementLibrary() -> String {
        return getAdvancedAutomationLibrary()
    }

    /// Get the sports detection library
    public static func getSportsDetectionLibraryContent() -> String {
        return getSportsDetectionLibrary()
    }

    /// Get all libraries combined
    public static func getAllLibraries() -> String {
        return getCompleteLibrary()
    }
}
