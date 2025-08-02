import Foundation
import os.log

/// Page detection and state checking JavaScript functions for ODYSSEY
/// Contains all page state detection functionality
@MainActor
public final class JavaScriptPages {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "JavaScriptPages")

    /// Page detection library
    public static let pagesLibrary = """
    // ===== PAGE DETECTION =====

    // Check if email verification is required
    isEmailVerificationRequired: function() {
        const hasVerificationText = document.body.textContent.toLowerCase().includes('verification code');

        return hasVerificationText;
    },

    // Check verification page state
    checkVerificationPage: function() {
        try {
            const pageText = document.body.textContent || document.body.innerText || '';
            const title = document.title || '';

            // Check for verification input fields
            const hasInput = document.querySelectorAll('input[type="number"], input[id*="code"]').length > 0;

            // Check for verification text
            const hasText = pageText.toLowerCase().includes('verification code');
            return {
                hasInput: hasInput,
                hasText: hasText,
                bodyTextPreview: pageText.substring(0, 200),
                title: title
            };
        } catch (error) {
            console.error('[ODYSSEY] Error in checkVerificationPage:', error);
            return {
                hasInput: false,
                bodyTextPreview: 'Error occurred'
            };
        }
    },

    // Check if group size page is loaded
    checkGroupSizePage: function() {
        const hasNumberInputs = document.querySelectorAll('input[type="number"]').length > 0;
        const hasReservationCount = document.querySelectorAll('[name*="reservation"], [name*="count"], [id*="reservation"], [id*="count"]').length > 0;
        const hasReservationCountInput = document.getElementById('reservationCount') || document.querySelector('input[name="ReservationCount"]');
        const hasGroupSizeText = (document.body.textContent || document.body.innerText || '').toLowerCase().includes('group size') ||
                                (document.body.textContent || document.body.innerText || '').toLowerCase().includes('number of people');

        return hasNumberInputs || hasReservationCount || hasReservationCountInput || hasGroupSizeText;
    },

    // Check if time selection page is loaded
    checkTimeSelectionPage: function() {
        const pageText = document.body.textContent || document.body.innerText || '';
        const title = document.title || '';

        // Check for time/date selection indicators
        const hasDateElements = document.querySelectorAll('[class*="date"], [class*="day"], [id*="date"], [id*="day"]').length > 0;
        const hasTimeElements = document.querySelectorAll('[class*="time"], [class*="hour"], [id*="time"], [id*="hour"]').length > 0;
        const hasCalendarElements = document.querySelectorAll('[class*="calendar"], [id*="calendar"]').length > 0;

        return {
            hasDateElements: hasDateElements,
            hasTimeElements: hasTimeElements,
            hasCalendarElements: hasCalendarElements,
            pageText: pageText.substring(0, 500),
            title: title
        };
    },

    // Check if contact info page is loaded
    checkContactInfoPage: function() {
        const phoneField = document.getElementById('telephone');
        const emailField = document.getElementById('email');
        const nameField = document.getElementById('field2021');
        const confirmButton = document.querySelector('button[type="submit"], input[type="submit"], .mdc-button');

        return !!(phoneField || emailField || nameField || confirmButton);
    },

    // Detect retry text on the page
    detectRetryText: function() {
        const pageText = document.body.textContent || document.body.innerText || '';

        // Check for retry indicators - specifically look for the captcha retry message
        const hasRetryText = pageText.toLowerCase().includes('retry');

        return hasRetryText;
    },





    // Check if reservation is complete/successful
    checkReservationComplete: function() {
        try {
            const pageText = document.body.textContent || document.body.innerText || '';
            const title = document.title || '';

            console.log('[ODYSSEY] Checking reservation completion...');
            console.log('[ODYSSEY] Page title:', title);
            console.log('[ODYSSEY] Page text preview:', pageText.substring(0, 500));
            console.log('[ODYSSEY] Full page text length:', pageText.length);

            // Check for multiple success indicators
            const lowerText = pageText.toLowerCase();
            const hasConfirmedText = lowerText.includes('confirmation');
            const hasSuccessText = lowerText.includes('is now confirmed');

            const isComplete = hasConfirmedText || hasSuccessText;

            console.log('[ODYSSEY] Reservation completion check results:', {
                hasConfirmedText,
                hasSuccessText,
                isComplete
            });

            // Log all elements with confirmation-related classes or IDs
            const confirmationElements = document.querySelectorAll('[class*="confirmation"], [id*="confirmation"]');
            console.log('[ODYSSEY] Found', confirmationElements.length, 'confirmation-related elements:');
            confirmationElements.forEach((el, index) => {
                console.log('[ODYSSEY] Element', index + 1, ':', {
                    tagName: el.tagName,
                    className: el.className,
                    id: el.id,
                    text: (el.textContent || el.innerText || '').substring(0, 100)
                });
            });

            return {
                isComplete: isComplete,
                pageText: pageText.substring(0, 200),
                title: title
            };
        } catch (error) {
            console.error('[ODYSSEY] Error in checkReservationComplete:', error);
            return {
                isComplete: false,
                error: error.message
            };
        }
    },

    // Fill verification code into the form
    fillVerificationCode: function(code) {
        try {
            // Try multiple selectors for verification code input
            const selectors = [
                'input[type="number"]',
                'input[type="text"]',
                'input[name*="code"]',
                'input[id*="code"]'
            ];

            for (let selector of selectors) {
                const input = document.querySelector(selector);
                if (input) {
                    // Use the centralized browser autofill simulation
                    const result = this.simulateBrowserAutofill(input, code);
                    if (result) {
                        console.log('[ODYSSEY] Verification code filled successfully with selector:', selector);
                        return true;
                    }
                }
            }

            console.error('[ODYSSEY] No verification code input found');
            return false;
        } catch (error) {
            console.error('[ODYSSEY] Error filling verification code:', error);
            return false;
        }
    },

    // Click verification submit button
    clickVerificationSubmitButton: function() {
        try {
            console.log('[ODYSSEY] Starting verification submit button search...');

            const pageText = document.body.textContent || document.body.innerText || '';
            console.log('[ODYSSEY] Page text preview:', pageText.substring(0, 300));
            console.log('[ODYSSEY] Page title:', document.title || '');

            // Try multiple selectors for submit button with more comprehensive detection
            const selectors = [
                'button[type="submit"]',
                'input[type="submit"]',
                'button[type="button"]',
                'input[type="button"]',
                'input[value*="Confirm"]',
                'input[value*="Submit"]',
                'input[value*="Verify"]',
                'input[value*="Send"]',
                // Additional selectors for common button patterns
                '.btn-primary',
                '.btn-success',
                '.btn-submit',
                '[class*="submit"]',
                '[class*="confirm"]',
                '[class*="verify"]',
                '[id*="submit"]',
                '[id*="confirm"]',
                '[id*="verify"]'
            ];

            for (let selector of selectors) {
                const button = document.querySelector(selector);
                if (button) {
                    console.log('[ODYSSEY] Found verification submit button with selector:', selector);
                    console.log('[ODYSSEY] Button text:', button.textContent || button.innerText || '');
                    console.log('[ODYSSEY] Button type:', button.type || 'button');
                    console.log('[ODYSSEY] Button class:', button.className || '');
                    console.log('[ODYSSEY] Button id:', button.id || '');
                    console.log('[ODYSSEY] Button value:', button.value || '');

                    button.focus();
                    button.click();
                    console.log('[ODYSSEY] Verification submit button clicked');
                    return true;
                }
            }

            // Fallback: try to find any clickable element that might be the submit button
            const allButtons = document.querySelectorAll('button, input[type="submit"], input[type="button"], input[type="image"], a[role="button"]');
            console.log('[ODYSSEY] Found', allButtons.length, 'total buttons on page');

            for (let button of allButtons) {
                const buttonText = (button.textContent || button.innerText || '').toLowerCase();
                const buttonValue = (button.value || '').toLowerCase();
                const buttonClass = (button.className || '').toLowerCase();
                const buttonId = (button.id || '').toLowerCase();

                console.log('[ODYSSEY] Checking button:', {
                    text: buttonText,
                    value: buttonValue,
                    class: buttonClass,
                    id: buttonId,
                    type: button.type || 'button'
                });

                if (buttonText.includes('confirm') || buttonText.includes('submit') ||
                    buttonText.includes('verify') || buttonText.includes('send') ||
                    buttonText.includes('continue') || buttonText.includes('next') ||
                    buttonValue.includes('confirm') || buttonValue.includes('submit') ||
                    buttonValue.includes('verify') || buttonValue.includes('send') ||
                    buttonValue.includes('continue') || buttonValue.includes('next') ||
                    buttonClass.includes('submit') || buttonClass.includes('confirm') ||
                    buttonClass.includes('verify') || buttonClass.includes('primary') ||
                    buttonId.includes('submit') || buttonId.includes('confirm') ||
                    buttonId.includes('verify')) {
                    console.log('[ODYSSEY] Found verification submit button by text/class/id:', buttonText);
                    button.focus();
                    button.click();
                    console.log('[ODYSSEY] Verification submit button clicked (text-based)');
                    return true;
                }
            }

            console.error('[ODYSSEY] No verification submit button found');
            console.log('[ODYSSEY] Available buttons on page:');
            const allElements = document.querySelectorAll('button, input[type="submit"], input[type="button"], input[type="image"], a[role="button"]');
            allElements.forEach((el, index) => {
                console.log('[ODYSSEY] Button', index + 1, ':', {
                    text: el.textContent || el.innerText || '',
                    value: el.value || '',
                    type: el.type || 'button',
                    class: el.className || '',
                    id: el.id || '',
                    disabled: el.disabled || false,
                    visible: el.offsetWidth > 0 && el.offsetHeight > 0
                });
            });

            // Also log all form elements
            const forms = document.querySelectorAll('form');
            console.log('[ODYSSEY] Found', forms.length, 'forms on page');
            forms.forEach((form, index) => {
                console.log('[ODYSSEY] Form', index + 1, ':', {
                    action: form.action || '',
                    method: form.method || '',
                    id: form.id || '',
                    class: form.className || ''
                });
            });

            return false;
        } catch (error) {
            console.error('[ODYSSEY] Error clicking verification submit button:', error);
            return false;
        }
    }
    """
}
