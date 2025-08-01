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
        const verificationElements = document.querySelectorAll('[class*="verification"], [class*="verify"], [id*="verification"], [id*="verify"], [placeholder*="verification"], [placeholder*="verify"]');
        const hasVerificationText = document.body.textContent.toLowerCase().includes('verification') || document.body.textContent.toLowerCase().includes('verify');
        const hasVerificationForm = document.querySelectorAll('form').length > 0 && (document.body.textContent.toLowerCase().includes('email') || document.body.textContent.toLowerCase().includes('code'));

        return verificationElements.length > 0 || hasVerificationText || hasVerificationForm;
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
        const hasRetryText = pageText.toLowerCase().includes('retry') ||
                            document.querySelector('span[data-valmsg-for="ReCaptcha"]') !== null ||
                            document.querySelector('.text-danger.field-validation-error') !== null ||
                            document.querySelector('span.text-danger.field-validation-error[data-valmsg-for="ReCaptcha"]') !== null;

        return hasRetryText;
    },

    // Check if reservation is complete/successful
    checkReservationComplete: function() {
        try {
            const pageText = document.body.textContent || document.body.innerText || '';
            const title = document.title || '';

            // Check for success indicators
            const hasSuccessText =  pageText.toLowerCase().includes('confirmed');

            return {
                isComplete: hasSuccessText,
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
            // Try multiple selectors for submit button with more comprehensive detection
            const selectors = [
                'button[type="submit"]',
                'input[type="submit"]',
                'button:contains("Confirm")'

            ];

            for (let selector of selectors) {
                const button = document.querySelector(selector);
                if (button) {
                    console.log('[ODYSSEY] Found verification submit button with selector:', selector);
                    console.log('[ODYSSEY] Button text:', button.textContent || button.innerText || '');
                    console.log('[ODYSSEY] Button type:', button.type || 'button');
                    console.log('[ODYSSEY] Button class:', button.className || '');
                    console.log('[ODYSSEY] Button id:', button.id || '');

                    button.focus();
                    button.click();
                    console.log('[ODYSSEY] Verification submit button clicked');
                    return true;
                }
            }

            // Fallback: try to find any clickable element that might be the submit button
            const allButtons = document.querySelectorAll('button, input[type="submit"], input[type="button"]');
            for (let button of allButtons) {
                const buttonText = (button.textContent || button.innerText || '').toLowerCase();
                if (buttonText.includes('confirm')) {
                    console.log('[ODYSSEY] Found verification submit button by text:', buttonText);
                    button.focus();
                    button.click();
                    console.log('[ODYSSEY] Verification submit button clicked (text-based)');
                    return true;
                }
            }

            console.error('[ODYSSEY] No verification submit button found');
            return false;
        } catch (error) {
            console.error('[ODYSSEY] Error clicking verification submit button:', error);
            return false;
        }
    }
    """
}
