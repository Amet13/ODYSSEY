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

            // Check for multiple success indicators
            const lowerText = pageText.toLowerCase();
            const hasConfirmedText = lowerText.includes('confirmation');
            const hasSuccessText = lowerText.includes('is now confirmed');

            const isComplete = hasConfirmedText || hasSuccessText;

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

            // Log page context for debugging
            const pageText = document.body.textContent || document.body.innerText || '';

            // Try multiple selectors for submit button with more comprehensive detection
            const selectors = [
                'button[type="submit"]',
                'input[type="submit"]',
                'button[type="button"]',
                'input[type="button"]',
                'input[value*="Confirm"]',
            ];

            for (let selector of selectors) {
                const button = document.querySelector(selector);
                if (button) {
                    button.focus();
                    button.click();
                    return true;
                }
            }

            // Fallback: try to find any clickable element that might be the submit button
            const allButtons = document.querySelectorAll('button, input[type="submit"], input[type="button"], input[type="image"], a[role="button"]');

            for (let button of allButtons) {
                const buttonText = (button.textContent || button.innerText || '').toLowerCase();
                const buttonValue = (button.value || '').toLowerCase();
                const buttonClass = (button.className || '').toLowerCase();
                const buttonId = (button.id || '').toLowerCase();

                if (buttonText.includes('Confirm') || buttonId.includes('confirm') {
                    button.focus();
                    button.click();
                    return true;
                }
            }

            return false;
        } catch (error) {
            console.error('[ODYSSEY] Error clicking verification submit button:', error);
            return false;
        }
    }
    """
}
