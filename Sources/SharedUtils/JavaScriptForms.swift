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

    // Fill form field with autofill behavior (less likely to trigger captchas)
    fillFieldWithAutofill: function(selector, value, fieldType = '') {
        const field = document.querySelector(selector);
        if (!field) {
            console.error('[ODYSSEY] Field not found:', selector);
            return false;
        }

        try {
            // Focus the field
            field.focus();

            // Clear existing value
            field.value = '';

            // Set new value
            field.value = value;

            // Trigger events in the correct order
            field.dispatchEvent(new Event('input', { bubbles: true }));
            field.dispatchEvent(new Event('change', { bubbles: true }));
            field.dispatchEvent(new Event('blur', { bubbles: true }));


            return true;
        } catch (error) {
            console.error('[ODYSSEY] Error filling field:', error);
            return false;
        }
    },

    // Fill all contact fields
    fillContactFields: function(phoneNumber, email, name) {
        return {
            phone: this.fillPhoneNumber(phoneNumber),
            email: this.fillEmail(email),
            name: this.fillName(name)
        };
    },

    // Fill phone number field
    fillPhoneNumber: function(phoneNumber) {
        const selectors = [
            'input[type="tel"]',
            'input[name*="PhoneNumber"]',
            'input[id*="telephone"]'
        ];

        for (let selector of selectors) {
            if (this.fillFieldWithAutofill(selector, phoneNumber, 'phone')) {
                return true;
            }
        }
        return false;
    },

    // Fill email field
    fillEmail: function(email) {
        const selectors = [
            'input[type="email"]',
            'input[name*="Email"]',
            'input[id*="email"]'
        ];

        for (let selector of selectors) {
            if (this.fillFieldWithAutofill(selector, email, 'email')) {
                return true;
            }
        }
        return false;
    },

    // Fill name field
    fillName: function(name) {
        const selectors = [
            'input[name*="field2021"]',
            'input[id*="field2021"]'
        ];

        for (let selector of selectors) {
            if (this.fillFieldWithAutofill(selector, name, 'name')) {
                return true;
            }
        }
        return false;
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

            if (this.fillFieldWithAutofill(input, value, inputType)) {
                filledCount++;
            }
        }

        return filledCount;
    },

    // Detect input field type
    detectInputType: function(input) {
        const name = (input.name || '').toLowerCase();
        const placeholder = (input.placeholder || '').toLowerCase();
        const id = (input.id || '').toLowerCase();
        const type = (input.type || '').toLowerCase();

        if (type === 'tel' || name.includes('PhoneNumber') || id.includes('telephone')) {
            return 'phone';
        }

        if (type === 'email' || name.includes('Email') || id.includes('email')) {
            return 'email';
        }

        if (name.includes('field2021') || id.includes('field2021')) {
            return 'name';
        }

        return 'unknown';
    },
    """
}
