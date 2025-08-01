import Foundation
import os.log

/// Form handling and field filling JavaScript functions for ODYSSEY
/// Contains all form-related automation functionality
@MainActor
public final class JavaScriptForms {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "JavaScriptForms")

    /// Form handling library
    public static let formsLibrary = """
    // ===== FORM FILLING =====



    // Fill all contact fields using browser autofill and click confirm with delay
    fillContactFields: function(phoneNumber, email, name) {
        // Fill all fields with browser autofill simulation
        const results = {
            phone: this.fillFormField('phone', phoneNumber),
            email: this.fillFormField('email', email),
            name: this.fillFormField('name', name)
        };

        // Add delay before clicking confirm button (1-2 seconds)
        const delay = Math.random() * 1000 + 1000; // 1000-2000ms
        setTimeout(() => {
            this.clickContactInfoConfirmButton();
        }, delay);

        return {
            ...results,
            confirmClicked: true // Return true since we're scheduling the click
        };
    },

    // Fill fields individually with comprehensive detection
    fillFieldsIndividually: function(phoneNumber, email, name) {
        const allInputs = document.querySelectorAll('input[type="text"], input[type="email"], input[type="tel"], input:not([type])');
        let filledCount = 0;

        for (let input of allInputs) {
            const inputType = this.detectInputType(input);
            let value = '';

            switch (inputType) {
                case 'phone':
                    value = phoneNumber;
                    break;
                case 'email':
                    value = email;
                    break;
                case 'name':
                    value = name;
                    break;
                default:
                    continue;
            }

            if (this.simulateBrowserAutofill(input, value)) {
                filledCount++;
            }
        }

        return filledCount;
    },

    // Detect input field type using centralized constants
    detectInputType: function(input) {
        const name = (input.name || '').toLowerCase();
        const placeholder = (input.placeholder || '').toLowerCase();
        const id = (input.id || '').toLowerCase();
        const type = (input.type || '').toLowerCase();

        // Check against centralized phone selectors
        for (let selector of this.constants.phoneSelectors) {
            if (this.matchesSelector(input, selector)) {
                return 'phone';
            }
        }

        // Check against centralized email selectors
        for (let selector of this.constants.emailSelectors) {
            if (this.matchesSelector(input, selector)) {
                return 'email';
            }
        }

        // Check against centralized name selectors
        for (let selector of this.constants.nameSelectors) {
            if (this.matchesSelector(input, selector)) {
                return 'name';
            }
        }

        return 'unknown';
    },

    // Helper function to check if input matches a selector
    matchesSelector: function(input, selector) {
        // Simple selector matching logic
        if (selector.includes('type=')) {
            const expectedType = selector.match(/type="([^"]+)"/)?.[1];
            if (expectedType && input.type === expectedType) {
                return true;
            }
        }

                if (selector.includes('name*=')) {
            const namePattern = selector.match(/name\\*="([^"]+)"/)?.[1];
            if (namePattern && input.name && input.name.toLowerCase().includes(namePattern.toLowerCase())) {
                return true;
            }
        }

        if (selector.includes('id*=')) {
            const idPattern = selector.match(/id\\*="([^"]+)"/)?.[1];
            if (idPattern && input.id && input.id.toLowerCase().includes(idPattern.toLowerCase())) {
                return true;
            }
        }

        return false;
    },
    """
}
