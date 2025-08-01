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
    }
    """
}
