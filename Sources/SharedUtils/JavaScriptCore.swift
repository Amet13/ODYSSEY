import Foundation
import os.log

/// Core JavaScript automation functions for ODYSSEY
/// Contains essential element finding and interaction functions
@MainActor
public final class JavaScriptCore {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "JavaScriptCore")

    /// Core automation library with essential functions
    public static let coreLibrary = """
    window.odyssey = {
        // ===== CENTRALIZED CONSTANTS =====

        // Form field selectors - centralized for easy modification
        constants: {
            // Phone number field selectors
            phoneSelectors: [
                'input[type="tel"]',
                'input[name*="PhoneNumber"]',
                'input[id*="telephone"]',
            ],

            // Email field selectors
            emailSelectors: [
                'input[type="email"]',
                'input[name*="Email"]',
                'input[id*="email"]'
            ],

            // Name field selectors
            nameSelectors: [
                'input[name*="field2021"]',
                'input[id*="field2021"]'
            ],

            // Submit button selectors
            submitSelectors: [
                'button[type="submit"]',
                'input[type="submit"]',
                '.mdc-button',
                'button[id="submit-btn"]',
                'button[onclick*="submit"]'
            ]
        },
        // ===== ELEMENT FINDING =====

        // Find element by text content with timeout
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
                        reject(new Error('Element not found: ' + text));
                    }
                };
                checkElement();
            });
        },

        // Find element by selector with timeout
        findElementBySelector: function(selector, timeout = 10000) {
            return new Promise((resolve, reject) => {
                const startTime = Date.now();
                const checkElement = () => {
                    const element = document.querySelector(selector);
                    if (element) {
                        resolve(element);
                    } else if (Date.now() - startTime < timeout) {
                        setTimeout(checkElement, 100);
                    } else {
                        reject(new Error('Element not found: ' + selector));
                    }
                };
                checkElement();
            });
        },

        // ===== UNIFIED FORM FILLING =====

        // Unified form field filling with human-like typing
        fillFormField: function(fieldType, value) {
            const selectors = this.constants[fieldType + 'Selectors'];
            if (!selectors) {
                console.error('[ODYSSEY] Unknown field type:', fieldType);
                return false;
            }

            for (let selector of selectors) {
                const field = document.querySelector(selector);
                if (field) {
                    return this.simulateHumanTyping(field, value);
                }
            }
            return false;
        },

        // Simulate human-like typing with typos and corrections
        simulateHumanTyping: async function(element, text) {
            if (!element) return false;

            try {
                // Focus element
                element.focus();
                element.value = '';

                // Type each character with random delays
                let currentText = '';
                for (let i = 0; i < text.length; i++) {
                    const char = text[i];
                    currentText += char;
                    element.value = currentText;

                    // Trigger input event
                    element.dispatchEvent(new Event('input', { bubbles: true }));

                    // Random delay between characters (50-150ms)
                    const delay = Math.random() * 100 + 50;
                    await new Promise(resolve => setTimeout(resolve, delay));

                    // Occasionally make a typo and correct it (5% chance)
                    if (Math.random() < 0.05 && i < text.length - 1) {
                        const typoChar = String.fromCharCode(97 + Math.floor(Math.random() * 26));
                        currentText = currentText.slice(0, -1) + typoChar + char;
                        element.value = currentText;
                        element.dispatchEvent(new Event('input', { bubbles: true }));

                        await new Promise(resolve => setTimeout(resolve, 200));

                        // Correct the typo
                        currentText = currentText.slice(0, -2) + char;
                        element.value = currentText;
                        element.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                }

                // Trigger final events
                element.dispatchEvent(new Event('change', { bubbles: true }));
                element.dispatchEvent(new Event('blur', { bubbles: true }));

                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error in human typing simulation:', error);
                return false;
            }
        },

        // ===== ELEMENT INTERACTION =====

        // Click element (unified function)
        clickElement: function(selector) {
            const element = typeof selector === 'string' ? document.querySelector(selector) : selector;
            if (!element) {
                console.error('[ODYSSEY] Element not found for click');
                return false;
            }

            try {
                // Scroll element into view
                element.scrollIntoView({ behavior: 'smooth', block: 'center' });

                // Get element position
                const rect = element.getBoundingClientRect();
                const centerX = rect.left + rect.width / 2;
                const centerY = rect.top + rect.height / 2;

                // Simulate mouse hover
                element.dispatchEvent(new MouseEvent('mouseenter', {
                    bubbles: true,
                    cancelable: true,
                    view: window
                }));

                // Simulate mouse down
                element.dispatchEvent(new MouseEvent('mousedown', {
                    bubbles: true,
                    cancelable: true,
                    button: 0,
                    buttons: 1,
                    view: window,
                    clientX: centerX,
                    clientY: centerY
                }));

                // Small delay between down and up
                setTimeout(() => {
                    // Simulate mouse up
                    element.dispatchEvent(new MouseEvent('mouseup', {
                        bubbles: true,
                        cancelable: true,
                        button: 0,
                        buttons: 0,
                        view: window,
                        clientX: centerX,
                        clientY: centerY
                    }));

                    // Simulate click
                    element.dispatchEvent(new MouseEvent('click', {
                        bubbles: true,
                        cancelable: true,
                        button: 0,
                        buttons: 0,
                        view: window,
                        clientX: centerX,
                        clientY: centerY
                    }));
                }, 50);

                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error clicking element:', error);
                return false;
            }
        },

        // Type text into element
        typeTextIntoElement: function(selector, text) {
            const element = typeof selector === 'string' ? document.querySelector(selector) : selector;
            if (!element) {
                console.error('[ODYSSEY] Element not found for typing');
                return false;
            }

            try {
                // Focus element
                element.focus();

                // Clear existing value
                element.value = '';

                // Set new value
                element.value = text;

                // Trigger input event
                element.dispatchEvent(new Event('input', { bubbles: true }));
                element.dispatchEvent(new Event('change', { bubbles: true }));

                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error typing into element:', error);
                return false;
            }
        },

        // Get element text content
        getElementText: function(selector) {
            const element = typeof selector === 'string' ? document.querySelector(selector) : selector;
            return element ? element.textContent || element.innerText || '' : '';
        },

        // Check if element is clickable
        isElementClickable: function(selector) {
            const element = typeof selector === 'string' ? document.querySelector(selector) : selector;
            if (!element) return false;

            const style = window.getComputedStyle(element);
            return style.display !== 'none' &&
                   style.visibility !== 'hidden' &&
                   style.opacity !== '0' &&
                   element.offsetWidth > 0 &&
                   element.offsetHeight > 0;
        },

        // ===== UTILITY FUNCTIONS =====

        // Wait for element to disappear
        waitForElementToDisappear: function(selector, timeout = 10000) {
            return new Promise((resolve, reject) => {
                const startTime = Date.now();
                const checkElement = () => {
                    const element = document.querySelector(selector);
                    if (!element) {
                        resolve(true);
                    } else if (Date.now() - startTime < timeout) {
                        setTimeout(checkElement, 100);
                    } else {
                        reject(new Error('Element still present: ' + selector));
                    }
                };
                checkElement();
            });
        },

        // Wait for element with timeout
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
                        reject(new Error('Element not found: ' + selector));
                    }
                };
                checkElement();
            });
        },

        // Get page source
        getPageSource: function() {
            return document.documentElement.outerHTML;
        },

        // Get current URL
        getCurrentURL: function() {
            return window.location.href;
        },

        // Get page title
        getPageTitle: function() {
            return document.title || '';
        },

        // Check if DOM is ready
        isDOMReady: function() {
            return document.readyState === 'complete' &&
                   document.body !== null &&
                   document.body.innerHTML.length > 0;
        },

        // Check if element exists
        elementExists: function(selector) {
            return document.querySelector(selector) !== null;
        },

        // Find all elements by selector
        findAllElements: function(selector) {
            const elements = document.querySelectorAll(selector);
            return Array.from(elements).map((el, index) => 'element_' + index);
        },

        // Find and click element by text
        findAndClickElementByText: function(text) {
            try {
                const divXPath = "//div[contains(text(),'" + text + "')]";
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
        },

        // Type text (alias for typeTextIntoElement)
        typeText: function(selector, text) {
            return this.typeTextIntoElement(selector, text);
        },

        // Log all buttons and links
        logAllButtonsAndLinks: function() {
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
        },

        // Check if button exists with text
        checkButtonExists: function(buttonText) {
            const buttons = Array.from(document.querySelectorAll('button, a, div'));
            for (let button of buttons) {
                const text = button.textContent || button.innerText || '';
                if (text.toLowerCase().includes(buttonText.toLowerCase())) {
                    return true;
                }
            }
            return false;
        },

                                // Fill number of people field
        fillNumberOfPeople: function(numberOfPeople) {
            try {
                const field = document.querySelector('input[id="reservationCount"][name="ReservationCount"]') ||
                             document.querySelector('#reservationCount') ||
                             document.querySelector('input[name="ReservationCount"]');

                if (field) {
                    field.value = numberOfPeople.toString();
                    field.dispatchEvent(new Event('input', { bubbles: true }));
                    field.dispatchEvent(new Event('change', { bubbles: true }));
                    return true;
                }
                return false;
            } catch (error) {
                return false;
            }
        },

        // Check DOM ready with button detection
        checkDOMReadyWithButton: function(sportName) {
            const ready = document.readyState === 'complete';
            const button = Array.from(document.querySelectorAll('button,div,a')).find(el =>
                el.textContent && el.textContent.includes(sportName)
            );
            return {
                readyState: document.readyState,
                buttonFound: !!button
            };
        },

        // Scroll with human-like behavior
        scrollHuman: function(direction = 'down', distance = 300) {
            try {
                const scrollDistance = distance;
                const scrollStep = scrollDistance / 10;
                let currentScroll = 0;

                const scrollInterval = setInterval(() => {
                    if (currentScroll >= scrollDistance) {
                        clearInterval(scrollInterval);
                        return;
                    }

                    const step = Math.min(scrollStep, scrollDistance - currentScroll);
                    if (direction === 'down') {
                        window.scrollBy(0, step);
                    } else {
                        window.scrollBy(0, -step);
                    }

                    currentScroll += step;
                }, Math.random() * 50 + 30);

                return true;
            } catch (error) {
                return false;
            }
        }
    };
    """
}
