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
        const nameField = document.getElementById('name');
        const confirmButton = document.querySelector('button[type="submit"], input[type="submit"], .mdc-button');
        const bodyText = document.body.textContent || '';

        return {
            hasPhoneField: !!phoneField,
            hasEmailField: !!emailField,
            hasNameField: !!nameField,
            hasConfirmButton: !!confirmButton,
            bodyText: bodyText.substring(0, 500)
        };
    },

    // Check if confirmation page is loaded
    checkConfirmationPage: function() {
        const pageText = document.body.textContent || document.body.innerText || '';
        const title = document.title || '';

        // Check for confirmation/success indicators
        const hasConfirmationElements = document.querySelectorAll('[class*="confirmation"], [class*="success"], [id*="confirmation"], [id*="success"]').length > 0;
        const hasThankYouText = pageText.toLowerCase().includes('thank you') || pageText.toLowerCase().includes('success') || pageText.toLowerCase().includes('confirmed');
        const hasConfirmationText = pageText.toLowerCase().includes('confirmation') || pageText.toLowerCase().includes('confirmed');

        return {
            hasConfirmationElements: hasConfirmationElements,
            hasThankYouText: hasThankYouText,
            hasConfirmationText: hasConfirmationText,
            pageText: pageText.substring(0, 500),
            title: title
        };
    },

    // Check if error page is loaded
    checkErrorPage: function() {
        const pageText = document.body.textContent || document.body.innerText || '';
        const title = document.title || '';

        // Check for error indicators
        const hasErrorElements = document.querySelectorAll('[class*="error"], [class*="alert"], [id*="error"], [id*="alert"]').length > 0;
        const hasErrorText = pageText.toLowerCase().includes('error') || pageText.toLowerCase().includes('failed') || pageText.toLowerCase().includes('unavailable');
        const hasAlertText = pageText.toLowerCase().includes('alert') || pageText.toLowerCase().includes('warning');

        return {
            hasErrorElements: hasErrorElements,
            hasErrorText: hasErrorText,
            hasAlertText: hasAlertText,
            pageText: pageText.substring(0, 500),
            title: title
        };
    },

    // Check if verification page is loaded
    checkVerificationPage: function() {
        const pageText = document.body.textContent || document.body.innerText || '';
        const title = document.title || '';

        // Check for verification indicators
        const hasVerificationElements = document.querySelectorAll('[class*="verification"], [class*="verify"], [id*="verification"], [id*="verify"]').length > 0;
        const hasVerificationText = pageText.toLowerCase().includes('verification') || pageText.toLowerCase().includes('verify');
        const hasCodeInput = document.querySelectorAll('input[type="text"], input[type="number"]').length > 0;
        const hasSubmitButton = document.querySelectorAll('button[type="submit"], input[type="submit"]').length > 0;

        return {
            hasVerificationElements: hasVerificationElements,
            hasVerificationText: hasVerificationText,
            hasCodeInput: hasCodeInput,
            hasSubmitButton: hasSubmitButton,
            pageText: pageText.substring(0, 500),
            title: title
        };
    },

    // Check if verification was successful
    checkVerificationSuccess: function() {
        const pageText = document.body.textContent || document.body.innerText || '';
        const title = document.title || '';

        // Check for success indicators
        const hasSuccessElements = document.querySelectorAll('[class*="success"], [class*="verified"], [id*="success"], [id*="verified"]').length > 0;
        const hasSuccessText = pageText.toLowerCase().includes('success') || pageText.toLowerCase().includes('verified') || pageText.toLowerCase().includes('confirmed');
        const hasErrorElements = document.querySelectorAll('[class*="error"], [class*="failed"], [id*="error"], [id*="failed"]').length > 0;
        const hasErrorText = pageText.toLowerCase().includes('error') || pageText.toLowerCase().includes('failed') || pageText.toLowerCase().includes('invalid');

        return {
            hasSuccessElements: hasSuccessElements,
            hasSuccessText: hasSuccessText,
            hasErrorElements: hasErrorElements,
            hasErrorText: hasErrorText,
            pageText: pageText.substring(0, 500),
            title: title
        };
    },

    // Check if still on verification page
    checkIfStillOnVerificationPage: function() {
        const pageText = document.body.textContent || document.body.innerText || '';
        const title = document.title || '';

        // Check if we're still on a verification page
        const hasVerificationElements = document.querySelectorAll('[class*="verification"], [class*="verify"], [id*="verification"], [id*="verify"]').length > 0;
        const hasVerificationText = pageText.toLowerCase().includes('verification') || pageText.toLowerCase().includes('verify');
        const hasCodeInput = document.querySelectorAll('input[type="text"], input[type="number"]').length > 0;

        return hasVerificationElements || hasVerificationText || hasCodeInput;
    },

    // Detect reCAPTCHA on the page
    detectCaptcha: function() {
        const pageText = document.body.textContent || document.body.innerText || '';

        // Check for reCAPTCHA indicators
        const hasRecaptchaElements = document.querySelectorAll('[class*="recaptcha"], [id*="recaptcha"], iframe[src*="recaptcha"]').length > 0;
        const hasCaptchaText = pageText.toLowerCase().includes('captcha') || pageText.toLowerCase().includes('recaptcha');
        const hasCheckboxElements = document.querySelectorAll('[class*="checkbox"], [class*="check"], input[type="checkbox"]').length > 0;

        return {
            hasRecaptchaElements: hasRecaptchaElements,
            hasCaptchaText: hasCaptchaText,
            hasCheckboxElements: hasCheckboxElements,
            pageText: pageText.substring(0, 500)
        };
    },

    // Detect retry text on the page
    detectRetryText: function() {
        const pageText = document.body.textContent || document.body.innerText || '';

        // Check for retry indicators
        const hasRetryElements = document.querySelectorAll('[class*="retry"], [id*="retry"], button:contains("Retry")').length > 0;
        const hasRetryText = pageText.toLowerCase().includes('retry') || pageText.toLowerCase().includes('try again');

        return hasRetryElements || hasRetryText;
    }
    """
}
