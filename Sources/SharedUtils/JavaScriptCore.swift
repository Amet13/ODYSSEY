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


        // ===== UNIFIED FORM FILLING =====

        // Unified form field filling with browser autofill simulation
        fillFormField: function(fieldType, value) {
            const selectors = this.constants[fieldType + 'Selectors'];
            if (!selectors) {
                console.error('[ODYSSEY] Unknown field type:', fieldType);
                return false;
            }

            for (let selector of selectors) {
                const field = document.querySelector(selector);
                if (field) {
                    return this.simulateBrowserAutofill(field, value);
                }
            }
            return false;
        },

        // Simulate browser autofill behavior (fast and realistic)
        simulateBrowserAutofill: function(element, text) {
            if (!element) return false;

            try {
                // Focus element
                element.focus();

                // Clear existing value
                element.value = '';

                // Set value instantly (like browser autofill)
                element.value = text;

                // Trigger events in sequence (like browser autofill)
                element.dispatchEvent(new Event('input', { bubbles: true }));
                element.dispatchEvent(new Event('change', { bubbles: true }));
                element.dispatchEvent(new Event('blur', { bubbles: true }));

                return true;
            } catch (error) {
                console.error('[ODYSSEY] Error in browser autofill simulation:', error);
                return false;
            }
        },



        // ===== ELEMENT INTERACTION =====

        // Click element (unified function - handles both selectors and IDs)
        clickElement: function(selector) {
            let element;

            // Handle both selector and data-odyssey-id
            if (selector.startsWith('#')) {
                // Direct ID selector
                element = document.getElementById(selector.substring(1));
            } else if (selector.includes('[data-odyssey-id=')) {
                // data-odyssey-id selector
                const id = selector.match(/data-odyssey-id="([^"]+)"/)?.[1];
                element = document.querySelector('[data-odyssey-id="' + id + '"]');
            } else {
                // Regular selector
                element = typeof selector === 'string' ? document.querySelector(selector) : selector;
            }

            if (!element) {
                console.error('[ODYSSEY] Element not found for click:', selector);
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

                // Type text into element (unified function - handles both selectors and IDs with browser autofill)
        typeTextIntoElement: function(selector, text) {
            let element;

            // Handle both selector and data-odyssey-id
            if (selector.startsWith('#')) {
                // Direct ID selector
                element = document.getElementById(selector.substring(1));
            } else if (selector.includes('[data-odyssey-id=')) {
                // data-odyssey-id selector
                const id = selector.match(/data-odyssey-id="([^"]+)"/)?.[1];
                element = document.querySelector('[data-odyssey-id="' + id + '"]');
            } else {
                // Regular selector
                element = typeof selector === 'string' ? document.querySelector(selector) : selector;
            }

            if (!element) {
                console.error('[ODYSSEY] Element not found for typing:', selector);
                return false;
            }

            // Use browser autofill simulation
            return this.simulateBrowserAutofill(element, text);
        },



        // ===== UTILITY FUNCTIONS =====





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


    };
    """
}
