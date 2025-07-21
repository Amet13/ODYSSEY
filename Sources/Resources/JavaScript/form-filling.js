// ODYSSEY Form Filling Script
// Handles contact form filling with human-like behavior

function fillContactFieldsWithAutofill(phoneNumber, email, name) {
  return `
        (function() {
            try {
                // Find contact fields
                const phoneField = document.getElementById('phone') ||
                                 document.getElementById('telephone') ||
                                 document.getElementById('phoneNumber') ||
                                 document.querySelector('input[type="tel"]') ||
                                 document.querySelector('input[name*="phone"]') ||
                                 document.querySelector('input[name*="tel"]') ||
                                 document.querySelector('input[placeholder*="phone"]') ||
                                 document.querySelector('input[placeholder*="tel"]') ||
                                 document.querySelector('input[placeholder*="Phone"]') ||
                                 document.querySelector('input[placeholder*="Telephone"]');

                const emailField = document.getElementById('email') ||
                                 document.getElementById('mail') ||
                                 document.querySelector('input[type="email"]') ||
                                 document.querySelector('input[name*="email"]') ||
                                 document.querySelector('input[name*="mail"]') ||
                                 document.querySelector('input[placeholder*="email"]') ||
                                 document.querySelector('input[placeholder*="Email"]') ||
                                 document.querySelector('input[placeholder*="mail"]');

                const nameField = document.getElementById('name') ||
                                document.getElementById('fullName') ||
                                document.getElementById('firstName') ||
                                document.querySelector('input[name*="name"]') ||
                                document.querySelector('input[name*="full"]') ||
                                document.querySelector('input[name*="first"]') ||
                                document.querySelector('input[placeholder*="name"]') ||
                                document.querySelector('input[placeholder*="Name"]') ||
                                document.querySelector('input[placeholder*="Full"]');

                // Fill fields with autofill behavior
                if (phoneField) {
                    phoneField.focus();
                    phoneField.value = '${phoneNumber}';
                    phoneField.dispatchEvent(new Event('input', { bubbles: true }));
                    phoneField.dispatchEvent(new Event('change', { bubbles: true }));
                    // Phone field filled
                }

                if (emailField) {
                    emailField.focus();
                    emailField.value = '${email}';
                    emailField.dispatchEvent(new Event('input', { bubbles: true }));
                    emailField.dispatchEvent(new Event('change', { bubbles: true }));
                    // Email field filled
                }

                if (nameField) {
                    nameField.focus();
                    nameField.value = '${name}';
                    nameField.dispatchEvent(new Event('input', { bubbles: true }));
                    nameField.dispatchEvent(new Event('change', { bubbles: true }));
                    // Name field filled
                }

                return {
                    phoneFilled: !!phoneField,
                    emailFilled: !!emailField,
                    nameFilled: !!nameField
                };
            } catch (error) {
                console.error('[ODYSSEY] Error filling contact fields:', error);
                return { phoneFilled: false, emailFilled: false, nameFilled: false };
            }
        })();
    `;
}

function findAndClickElementWithText(targetText) {
  return `
        (function() {
            try {
                const targetText = '${targetText}';
                const elements = Array.from(document.querySelectorAll('button, div, a, span, label'));
                
                for (const el of elements) {
                    const text = el.textContent?.trim();
                    if (text && text.includes(targetText)) {
                        // Click the element
                        el.click();
                        return true;
                    }
                }
                
                // No element found
                return false;
            } catch (error) {
                console.error('[ODYSSEY] Error finding element:', error);
                return false;
            }
        })();
    `;
}

function waitForDOMReady() {
  return `
        (function() {
            return document.readyState === 'complete';
        })();
    `;
}

// Export for use in Swift
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    fillContactFieldsWithAutofill,
    findAndClickElementWithText,
    waitForDOMReady,
  };
}
