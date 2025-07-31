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
            'input[name*="phone"]',
            'input[name*="Phone"]',
            'input[placeholder*="phone"]',
            'input[placeholder*="Phone"]',
            'input[id*="phone"]',
            'input[id*="Phone"]'
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
            'input[name*="email"]',
            'input[name*="Email"]',
            'input[placeholder*="email"]',
            'input[placeholder*="Email"]',
            'input[id*="email"]',
            'input[id*="Email"]'
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
            'input[name*="name"]',
            'input[name*="Name"]',
            'input[placeholder*="name"]',
            'input[placeholder*="Name"]',
            'input[id*="name"]',
            'input[id*="Name"]'
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

        if (type === 'tel' || name.includes('phone') || placeholder.includes('phone') || id.includes('phone')) {
            return 'phone';
        }

        if (type === 'email' || name.includes('email') || placeholder.includes('email') || id.includes('email')) {
            return 'email';
        }

        if (name.includes('name') || placeholder.includes('name') || id.includes('name')) {
            return 'name';
        }

        return 'unknown';
    },

    // Fill phone number with human-like typing simulation
    fillPhoneNumberWithHumanTyping: function(phoneNumber) {
        const selectors = [
            'input[type="tel"]',
            'input[name*="phone"]',
            'input[name*="Phone"]',
            'input[placeholder*="phone"]',
            'input[placeholder*="Phone"]',
            'input[id*="phone"]',
            'input[id*="Phone"]'
        ];

        for (let selector of selectors) {
            const field = document.querySelector(selector);
            if (field) {
                return this.simulateHumanTyping(field, phoneNumber);
            }
        }
        return false;
    },

    // Fill email with human-like typing simulation
    fillEmailWithHumanTyping: function(email) {
        const selectors = [
            'input[type="email"]',
            'input[name*="email"]',
            'input[name*="Email"]',
            'input[placeholder*="email"]',
            'input[placeholder*="Email"]',
            'input[id*="email"]',
            'input[id*="Email"]'
        ];

        for (let selector of selectors) {
            const field = document.querySelector(selector);
            if (field) {
                return this.simulateHumanTyping(field, email);
            }
        }
        return false;
    },

    // Fill name with human-like typing simulation
    fillNameWithHumanTyping: function(name) {
        const selectors = [
            'input[name*="name"]',
            'input[name*="Name"]',
            'input[placeholder*="name"]',
            'input[placeholder*="Name"]',
            'input[id*="name"]',
            'input[id*="Name"]'
        ];

        for (let selector of selectors) {
            const field = document.querySelector(selector);
            if (field) {
                return this.simulateHumanTyping(field, name);
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

            // Final change event
            element.dispatchEvent(new Event('change', { bubbles: true }));
            element.dispatchEvent(new Event('blur', { bubbles: true }));

            return true;
        } catch (error) {
            console.error('[ODYSSEY] Error in human typing simulation:', error);
            return false;
        }
    }
    """
}
