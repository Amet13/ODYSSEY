import Foundation
import os

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
        const nameField = document.querySelector('input[name*="field"], input[id*="field"]');
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



            // Check for confirmation-related elements
            const confirmationElements = document.querySelectorAll('[class*="confirmation"], [id*="confirmation"]');

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

            // Try multiple selectors for submit button with more comprehensive detection
            const selectors = [
                'button[onclick*="SubmitContactInfoValidationCode"]',
                'button.mdc-button',
                'button[class*="mdc-button"]',
                'button[type="submit"]',
                'input[type="submit"]',
                'input[value*="Confirm"]',
                '[id*="confirm"]'
            ];

            for (let selector of selectors) {
                const button = document.querySelector(selector);
                if (button) {
                    button.focus();
                    button.click();
                    return true;
                }
            }

            console.error('[ODYSSEY] No verification submit button found');

            return false;
        } catch (error) {
            console.error('[ODYSSEY] Error clicking verification submit button:', error);
            return false;
        }
    },

    // Check if verification was successful
    checkVerificationSuccess: function() {
        try {
            const pageText = document.body.textContent || document.body.innerText || '';
            const title = document.title || '';
            const url = window.location.href;

            // Check for success indicators - be VERY conservative
            const lowerText = pageText.toLowerCase();
            const hasSuccessText = (lowerText.includes('confirmation') && lowerText.includes('is now confirmed')) ||
                                 (lowerText.includes('present upon arrival') && lowerText.includes('please bring')) ||
                                 (lowerText.includes('printed copy') && lowerText.includes('thank you')) ||
                                 (lowerText.includes('successfully confirmed') && lowerText.includes('thank you'));

            // Check if we're still on verification page
            const stillOnVerificationPage = lowerText.includes('enter it below') ||
                                          lowerText.includes('verification code') ||
                                          lowerText.includes('check your email') ||
                                          lowerText.includes('junk or spam') ||
                                          document.querySelectorAll('input[type="number"], input[id*="code"], input[name*="code"]').length > 0;

            // Check for error indicators
            const hasErrorText = lowerText.includes('please enter a valid number') ||
                               lowerText.includes('confirmation code is incorrect') ||
                               lowerText.includes('please enter no more than 4 characters');

            let success = false;
            let reason = 'unknown';

            if (hasSuccessText) {
                success = true;
                reason = 'success_text_found';
            } else if (hasErrorText) {
                success = false;
                reason = 'error_text_found';
            } else if (!stillOnVerificationPage) {
                // If we moved away from verification page, be VERY conservative about success

                const hasSpecificSuccess = lowerText.includes('please bring') ||
                                        lowerText.includes('unable to attend') ||
                                        (title.toLowerCase().includes('confirmation') &&
                                         (lowerText.includes('thank you') || lowerText.includes('confirmed')));

                if (hasSpecificSuccess) {
                    success = true;
                    reason = 'specific_success_indicators_found';
                } else {
                    success = false;
                    reason = 'moved_away_from_verification_page_no_success_indicators';
                }
            } else {
                success = false;
                reason = 'still_on_verification_page';
            }

            // Verification check completed

            return {
                success: success,
                reason: reason,
                pageText: pageText.substring(0, 200),
                title: title,
                url: url
            };
        } catch (error) {
            console.error('[ODYSSEY] Error in checkVerificationSuccess:', error);
            return {
                success: false,
                reason: 'error_occurred',
                pageText: 'Error occurred',
                title: '',
                url: ''
            };
        }
    },

    // Check if we're still on the verification page
    checkIfStillOnVerificationPage: function() {
        try {
            const pageText = document.body.textContent || document.body.innerText || '';
            const lowerText = pageText.toLowerCase();

            // Check for verification page indicators
            const hasVerificationText = lowerText.includes('enter it below') ||
                                      lowerText.includes('check your email') ||
                                      lowerText.includes('junk or spam') ||
                                      lowerText.includes('verification code') ||
                                      lowerText.includes('enter the code');

            // Check for verification input fields
            const hasVerificationInput = document.querySelectorAll('input[type="number"], input[id*="code"], input[name*="code"]').length > 0;

            // Check for verification form or submit button
            const hasVerificationForm = document.querySelectorAll('form').length > 0;
            const hasSubmitButton = document.querySelectorAll('button[type="submit"], input[type="submit"]').length > 0;

            // Check for error messages that indicate we're still on verification page
            const hasErrorOnVerificationPage = lowerText.includes('invalid') ||
                                            lowerText.includes('incorrect') ||
                                            lowerText.includes('wrong') ||
                                            lowerText.includes('please enter a valid number') ||
                                            lowerText.includes('valid number') ||
                                            (lowerText.includes('error') && hasVerificationInput);

            return hasVerificationText || hasVerificationInput || hasVerificationForm || hasSubmitButton || hasErrorOnVerificationPage;
        } catch (error) {
            console.error('[ODYSSEY] Error in checkIfStillOnVerificationPage:', error);
            return false;
        }
    },

    // Clear the verification input field for the next attempt
    clearVerificationInput: function() {
        try {
            // Try multiple selectors for verification code input
            const selectors = [
                'input[type="number"]',
                'input[type="text"]',
                'input[name*="code"]',
                'input[id*="code"]',
                'input[placeholder*="code"]',
                'input[placeholder*="verification"]'
            ];

            for (let selector of selectors) {
                const input = document.querySelector(selector);
                if (input) {
                    // Clear the input field
                    input.value = '';
                    input.dispatchEvent(new Event('input', { bubbles: true }));
                    input.dispatchEvent(new Event('change', { bubbles: true }));
                    // Verification input field cleared
                    return true;
                }
            }

            console.error('[ODYSSEY] No verification input field found to clear');
            return false;
        } catch (error) {
            console.error('[ODYSSEY] Error clearing verification input:', error);
            return false;
        }
    }
    """
}
