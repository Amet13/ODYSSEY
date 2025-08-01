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

        // Simulate mouse movement to element
        simulateMouseMovement: function(selector) {
            const element = document.querySelector(selector);
            if (!element) return false;

            const rect = element.getBoundingClientRect();
            const centerX = rect.left + rect.width / 2;
            const centerY = rect.top + rect.height / 2;

            // Simulate mouse movement
            element.dispatchEvent(new MouseEvent('mousemove', {
                bubbles: true,
                cancelable: true,
                view: window,
                clientX: centerX,
                clientY: centerY
            }));

            return true;
        },

        // Simulate human typing
        simulateTyping: async function(selector, text, fastHumanLike = false, blurAfter = false) {
            const element = document.querySelector(selector);
            if (!element) return false;

            try {
                element.focus();
                element.value = '';

                if (fastHumanLike) {
                    // Fast typing with minimal delays
                    for (let i = 0; i < text.length; i++) {
                        element.value += text[i];
                        element.dispatchEvent(new Event('input', { bubbles: true }));
                        // Small random delay
                        await new Promise(resolve => setTimeout(resolve, Math.random() * 50 + 10));
                    }
                } else {
                    // Normal typing
                    element.value = text;
                    element.dispatchEvent(new Event('input', { bubbles: true }));
                }

                element.dispatchEvent(new Event('change', { bubbles: true }));

                if (blurAfter) {
                    element.blur();
                }

                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error in typing simulation:', error);
                return false;
            }
        },

        // Inject anti-detection script
        injectAntiDetection: function(userAgent, language) {
            // Remove webdriver property
            delete navigator.webdriver;

            // Override user agent
            Object.defineProperty(navigator, 'userAgent', {
                get: () => userAgent || 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            });

            // Override language
            Object.defineProperty(navigator, 'language', {
                get: () => language || 'en-US'
            });

            // Remove automation indicators
            delete window.chrome;
            delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array;
            delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise;
            delete window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol;

            console.log('[ODYSSEY] Anti-detection measures applied');
            return true;
        },

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

                        // Click confirm button
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

        // Select time slot
        selectTimeSlot: function(dayName, timeString) {
            try {
                // Find the day element
                const dayElements = Array.from(document.querySelectorAll('[class*="day"], [class*="date"], [id*="day"], [id*="date"]'));
                let targetDay = null;

                for (let day of dayElements) {
                    if (day.textContent && day.textContent.toLowerCase().includes(dayName.toLowerCase())) {
                        targetDay = day;
                        break;
                    }
                }

                if (!targetDay) {
                    console.error('[ODYSSEY] Day not found:', dayName);
                    return false;
                }

                // Click the day
                targetDay.click();

                // Wait for time slots to load
                setTimeout(() => {
                    // Find time slot
                    const timeSlotSelector = '[class*="time"], [class*="hour"], [id*="time"], [id*="hour"]';
                    const timeSlotElements = Array.from(document.querySelectorAll(timeSlotSelector));

                    for (let timeSlot of timeSlotElements) {
                        if (timeSlot.textContent && timeSlot.textContent.includes(timeString)) {
                            timeSlot.click();
                            return true;
                        }
                    }

                    console.error('[ODYSSEY] Time slot not found:', timeString);
                    return false;
                }, 1000);

                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error selecting time slot:', error);
                return false;
            }
        },

        // Check and click continue button
        checkAndClickContinueButton: function() {
            const continueButtons = Array.from(document.querySelectorAll('button, a, div')).filter(el => {
                const text = el.textContent || el.innerText || '';
                return text.toLowerCase().includes('continue') || text.toLowerCase().includes('next');
            });

            if (continueButtons.length > 0) {
                continueButtons[0].click();
                return true;
            }
            return false;
        },

        // Find and click continue button
        findAndClickContinueButton: function() {
            return this.checkAndClickContinueButton();
        },

        // Click contact info confirm button
        clickContactInfoConfirmButton: function() {
            const submitButtons = document.querySelectorAll('button[type="submit"], input[type="submit"]');
            if (submitButtons.length > 0) {
                submitButtons[0].click();
                return true;
            }
            return false;
        },

                            // Expand day section
        expandDaySection: function(dayName) {
            try {
                console.log('[ODYSSEY] Starting expandDaySection function for:', dayName);

                // Find all elements with class 'header-text'
                const headerElements = Array.from(document.getElementsByClassName('header-text'));
                console.log('[ODYSSEY] Found', headerElements.length, 'header-text elements');

                headerElements.forEach((el, idx) => {
                    const text = el.textContent.trim();
                    const visible = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);
                    console.log(`[ODYSSEY] header-text[${idx}]: text="${text}", visible=${visible}`);
                });

                // Find and click the SPECIFIC day that matches our target day
                let clicked = false;
                const targetDayName = dayName.trim().toLowerCase();
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

                return clicked;
            } catch (error) {
                console.error('[ODYSSEY] Error expanding day section:', error);
                return false;
            }
        },

                // Click time button
        clickTimeButton: function(timeString, dayName) {
            try {
                console.log('[ODYSSEY] Starting clickTimeButton function for:', timeString, 'day:', dayName);

                // After expanding, find and click the time slot by aria-label
                const slotTime = timeString;
                const slotDay = dayName;
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

                return timeSlotClicked;
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

        // Simulate mouse movement to element
        simulateMouseMovement: function(selector) {
            const element = document.querySelector(selector);
            if (!element) return false;

            const rect = element.getBoundingClientRect();
            const centerX = rect.left + rect.width / 2;
            const centerY = rect.top + rect.height / 2;

            // Simulate mouse movement
            element.dispatchEvent(new MouseEvent('mousemove', {
                bubbles: true,
                cancelable: true,
                view: window,
                clientX: centerX,
                clientY: centerY
            }));

            return true;
        },

        // Simulate human typing
        simulateTyping: async function(selector, text, fastHumanLike = false, blurAfter = false) {
            const element = document.querySelector(selector);
            if (!element) return false;

            try {
                element.focus();
                element.value = '';

                if (fastHumanLike) {
                    // Fast typing with minimal delays
                    for (let i = 0; i < text.length; i++) {
                        element.value += text[i];
                        element.dispatchEvent(new Event('input', { bubbles: true }));
                        // Small random delay
                        await new Promise(resolve => setTimeout(resolve, Math.random() * 50 + 10));
                    }
                } else {
                    // Normal typing
                    element.value = text;
                    element.dispatchEvent(new Event('input', { bubbles: true }));
                }

                element.dispatchEvent(new Event('change', { bubbles: true }));

                if (blurAfter) {
                    element.blur();
                }

                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error in typing simulation:', error);
                return false;
            }
        },

        // Inject anti-detection script
        injectAntiDetection: function(userAgent, language) {
            // Remove webdriver property
            delete navigator.webdriver;

            // Override user agent
            Object.defineProperty(navigator, 'userAgent', {
                get: () => userAgent || 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            });

            // Override language
            Object.defineProperty(navigator, 'language', {
                get: () => language || 'en-US'
            });

            // Remove automation indicators
            delete window.chrome;
            delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array;
            delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise;
            delete window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol;

            console.log('[ODYSSEY] Anti-detection measures applied');
            return true;
        },

        // Simulate quick mouse movement
        simulateQuickMouseMovement: function() {
            const elements = document.querySelectorAll('button, a, div');
            if (elements.length > 0) {
                const randomElement = elements[Math.floor(Math.random() * elements.length)];
                const rect = randomElement.getBoundingClientRect();

                randomElement.dispatchEvent(new MouseEvent('mousemove', {
                    bubbles: true,
                    cancelable: true,
                    view: window,
                    clientX: rect.left + Math.random() * rect.width,
                    clientY: rect.top + Math.random() * rect.height
                }));
            }
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
        }
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

    /// WebDriver-style element functions
    private static func getWebDriverLibrary() -> String {
        return """
        // ===== WEBDRIVER ELEMENT FUNCTIONS =====

        // Click element by data-odyssey-id
        clickElementById: function(id) {
            const element = document.querySelector('[data-odyssey-id="' + id + '"]');
            if (element) {
                element.click();
                return true;
            }
            return false;
        },

        // Type into element by data-odyssey-id
        typeIntoElementById: function(id, text) {
            const element = document.querySelector('[data-odyssey-id="' + id + '"]');
            if (element) {
                element.value = text;
                element.dispatchEvent(new Event('input', { bubbles: true }));
                return true;
            }
            return false;
        },

        // Clear element by data-odyssey-id
        clearElementById: function(id) {
            const element = document.querySelector('[data-odyssey-id="' + id + '"]');
            if (element) {
                element.value = '';
                element.dispatchEvent(new Event('input', { bubbles: true }));
                return true;
            }
            return false;
        },

        // Get element attribute by data-odyssey-id
        getElementAttributeById: function(id, name) {
            const element = document.querySelector('[data-odyssey-id="' + id + '"]');
            return element ? element.getAttribute(name) : null;
        },

        // Get element text by data-odyssey-id
        getElementTextById: function(id) {
            const element = document.querySelector('[data-odyssey-id="' + id + '"]');
            return element ? element.textContent || element.innerText || '' : '';
        },

        // Check if element is displayed by data-odyssey-id
        isElementDisplayedById: function(id) {
            const element = document.querySelector('[data-odyssey-id="' + id + '"]');
            if (!element) return false;

            const style = window.getComputedStyle(element);
            return style.display !== 'none' && style.visibility !== 'hidden';
        },

        // Check if element is enabled by data-odyssey-id
        isElementEnabledById: function(id) {
            const element = document.querySelector('[data-odyssey-id="' + id + '"]');
            return element && !element.disabled;
        },

        // Check if element is selected by data-odyssey-id
        isElementSelectedById: function(id) {
            const element = document.querySelector('[data-odyssey-id="' + id + '"]');
            return element && element.checked;
        }
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

                // Look for elements with the specific 'button no-img' class
                const buttonNoImgElements = document.querySelectorAll('.button.no-img');

                buttonNoImgElements.forEach((element) => {
                    const text = element.textContent || element.innerText || '';
                    const trimmedText = text.trim();

                    if (trimmedText.length > 0) {
                        // Check for duplicates by sport name (case-insensitive)
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
                console.error('[ODYSSEY] Error in detectSports:', error);
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
