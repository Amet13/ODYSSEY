import Foundation
import os.log

/// Centralized JavaScript library for ODYSSEY automation
/// Consolidates all JavaScript functionality to eliminate duplication and improve maintainability
/// Now uses modular approach with separate libraries for different concerns
@MainActor
public final class JavaScriptLibrary {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "JavaScriptLibrary")

    // MARK: - Modular Libraries

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

        // Extend with human behavior simulation
        Object.assign(window.odyssey, {
        \(getHumanBehaviorLibrary())
        });

        // Extend with verification handling
        Object.assign(window.odyssey, {
        \(getVerificationLibrary())
        });

        // Extend with WebDriver element functions
        Object.assign(window.odyssey, {
        \(getWebDriverLibrary())
        });

        // Extend with sports detection
        Object.assign(window.odyssey, {
        \(getSportsDetectionLibraryContent())
        });
        """
    }

    // MARK: - Advanced Automation Library

    /// Advanced automation functions for complex interactions
    private static func getAdvancedAutomationLibrary() -> String {
        return """
        // ===== ADVANCED AUTOMATION =====

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

        // Apply basic anti-detection measures
        applyBasicAntiDetection: function() {
            try {
                // Simple overrides that are less likely to cause errors
                if (navigator.webdriver !== undefined) {
                    Object.defineProperty(navigator, 'webdriver', {
                        get: () => undefined,
                        configurable: true
                    });
                }

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
                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error in anti-detection script:', error);
                return false;
            }
        },





        // Click contact info confirm button (unified approach)
        clickContactInfoConfirmButton: function() {
            try {
                // Try multiple selectors for the confirm button
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

                // Simulate human behavior before retry
                // 1. Random mouse movement
                const randomX = Math.random() * window.innerWidth;
                const randomY = Math.random() * window.innerHeight;
                document.dispatchEvent(new MouseEvent('mousemove', {
                    bubbles: true,
                    cancelable: true,
                    view: window,
                    clientX: randomX,
                    clientY: randomY
                }));
                console.log('[ODYSSEY] Mouse movement simulated');

                // 2. Small scroll
                window.scrollBy(0, Math.random() * 50 - 25);
                console.log('[ODYSSEY] Scroll simulated');

                // 3. Small delay (synchronous)
                const start = Date.now();
                while (Date.now() - start < 1000) {
                    // Busy wait for 1 second
                }
                console.log('[ODYSSEY] Delay completed');

                // 4. Click the confirm button again
                console.log('[ODYSSEY] Attempting to click confirm button...');
                const clickResult = this.clickContactInfoConfirmButton();
                console.log('[ODYSSEY] Click result:', clickResult);
                return clickResult;
            } catch (error) {
                console.error('[ODYSSEY] Error in handleCaptchaRetry:', error);
                return false;
            }
        },

        // Click confirm button (for group size form)
        clickConfirmButton: function() {
            try {
                const button = document.querySelector('button[id="submit-btn"]') ||
                              document.querySelector('#submit-btn') ||
                              document.querySelector('button[type="submit"]');

                if (button) {
                    // Focus and click the button
                    button.focus();
                    button.click();
                    return 'clicked';
                } else {
                    return 'not found';
                }
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

                // Find and click the specific day that matches our target day
                for (let i = 0; i < headerElements.length; i++) {
                    const el = headerElements[i];
                    const headerText = el.textContent.trim().toLowerCase();
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);

                    // Check if this header contains our target day name
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

                    // Check if any part of the target day name matches
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

    // MARK: - Human Behavior Library

    /// Human behavior simulation functions
    private static func getHumanBehaviorLibrary() -> String {
        return """
        // ===== HUMAN BEHAVIOR SIMULATION =====


        """
    }

    // MARK: - Verification Library

    /// Verification handling functions
    private static func getVerificationLibrary() -> String {
        return """
        // ===== VERIFICATION HANDLING =====

        // Clear verification input field
        clearVerificationInput: function() {
            const inputs = document.querySelectorAll('input[type="text"], input[type="number"]');
            for (let input of inputs) {
                input.value = '';
                input.dispatchEvent(new Event('input', { bubbles: true }));
            }
            return true;
        },

        // Fill verification code with autofill behavior
        fillVerificationCode: function(code) {
            const inputs = document.querySelectorAll('input[type="text"], input[type="number"]');
            for (let input of inputs) {
                input.value = code;
                input.dispatchEvent(new Event('input', { bubbles: true }));
                input.dispatchEvent(new Event('change', { bubbles: true }));
                return true;
            }
            return false;
        },

        // Click verification submit button with comprehensive strategy
        clickVerificationSubmitButton: function() {
            // Strategy 1: Look for submit buttons
            const submitButtons = document.querySelectorAll('button[type="submit"], input[type="submit"]');
            if (submitButtons.length > 0) {
                submitButtons[0].click();
                return true;
            }

            // Strategy 2: Look for buttons with submit text
            const allButtons = Array.from(document.querySelectorAll('button, input[type="submit"], input[type="button"], a[role="button"], div[role="button"]'));
            for (let button of allButtons) {
                const text = button.textContent || button.innerText || '';
                if (text.toLowerCase().includes('submit') || text.toLowerCase().includes('verify') || text.toLowerCase().includes('confirm')) {
                    button.click();
                    return true;
                }
            }

            // Strategy 3: Look for any clickable button
            const anyButtons = document.querySelectorAll('button');
            if (anyButtons.length > 0) {
                anyButtons[0].click();
                return true;
            }

            return false;
        }
        """
    }

    // MARK: - WebDriver Library

    /// WebDriver-style element functions (aliases for unified functions)
    private static func getWebDriverLibrary() -> String {
        return """
        // ===== WEBDRIVER ELEMENT FUNCTIONS =====


        """
    }

    // MARK: - Sports Detection Library

    /// Sports detection functions
    private static func getSportsDetectionLibraryContent() -> String {
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

    // MARK: - Legacy Support

    /// Get the legacy automation library (for backward compatibility)
    public static let automationLibrary = getCompleteLibrary()

    /// Get the anti-detection library (for backward compatibility)
    public static let antiDetectionLibrary = getHumanBehaviorLibrary()

    /// Get the sports detection library (for backward compatibility)
    public static let sportsDetectionLibrary = getSportsDetectionLibraryContent()

    // MARK: - Public Methods for Backward Compatibility

    /// Get the automation library (for backward compatibility)
    public static func getAutomationLibrary() -> String {
        return getCompleteLibrary()
    }

    /// Get the anti-detection library (for backward compatibility)
    public static func getAntiDetectionLibrary() -> String {
        return getHumanBehaviorLibrary()
    }

    /// Get the sports detection library (for backward compatibility)
    public static func getSportsDetectionLibrary() -> String {
        return getSportsDetectionLibraryContent()
    }

    /// Get the mouse movement library (for backward compatibility)
    public static func getMouseMovementLibrary() -> String {
        return getHumanBehaviorLibrary()
    }

    /// Get all libraries combined (for backward compatibility)
    public static func getAllLibraries() -> String {
        return getCompleteLibrary()
    }
}
