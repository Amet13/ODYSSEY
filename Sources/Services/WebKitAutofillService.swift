import Foundation
import os.log
import WebKit

@MainActor
public final class WebKitAutofillService {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "WebKitAutofill")

    // Reference to the main WebKit service for webView access
    private weak var webKitService: WebKitService?

    init(webKitService: WebKitService) {
        self.webKitService = webKitService
    }

    // MARK: - Browser Autofill Methods (Less Likely to Trigger Captchas)

    /**
     * Fills phone number using browser autofill (less likely to trigger captchas).
     * - Parameter phoneNumber: The phone number to fill.
     * - Returns: True if successful, false otherwise.
     */
    public func fillPhoneNumberWithAutofill(_ phoneNumber: String) async -> Bool {
        logger.info("📞 Filling phone number with autofill: \(phoneNumber)")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available")
            return false
        }

        let script = """
        (function() {
            try {
                const phoneField =
                    document.getElementById('phoneNumber') ||
                    document.querySelector('input[name*="phone"], input[name*="PhoneNumber"], input[type="tel"]') ||
                    document.querySelector('[placeholder*="phone"], [placeholder*="Phone"]') ||
                    document.querySelector('.phone-input, .phone-field');

                if (!phoneField) {
                    console.log('[ODYSSEY] Phone field not found');
                    return { success: false, error: 'Phone field not found' };
                }

                console.log('[ODYSSEY] Found phone field:', {
                    id: phoneField.id,
                    name: phoneField.name,
                    className: phoneField.className,
                    type: phoneField.type
                });

                // Focus the field first (triggers autofill)
                phoneField.focus();

                // Clear existing value
                phoneField.value = '';

                // Set the new value
                phoneField.value = '\(phoneNumber)';

                // Trigger input events
                phoneField.dispatchEvent(new Event('input', { bubbles: true }));
                phoneField.dispatchEvent(new Event('change', { bubbles: true }));

                console.log('[ODYSSEY] Phone number filled successfully');
                return { success: true };
            } catch (error) {
                console.error('[ODYSSEY] Error filling phone number:', error);
                return { success: false, error: error.toString() };
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script)
            if
                let resultDict = result as? [String: Any],
                let success = resultDict["success"] as? Bool
            {
                if success {
                    logger.info("✅ Phone number filled with autofill")
                    return true
                } else {
                    let error = resultDict["error"] as? String ?? "Unknown error"
                    logger.warning("⚠️ Phone number autofill failed: \(error)")
                    return false
                }
            } else {
                logger.warning("⚠️ Phone number autofill failed - invalid result")
                return false
            }
        } catch {
            logger.error("❌ Error filling phone number: \(error.localizedDescription)")
            return false
        }
    }

    /**
     * Fills all contact fields with autofill and human-like movements.
     * - Parameters:
     *   - phoneNumber: The phone number to fill.
     *   - email: The email address to fill.
     *   - name: The name to fill.
     * - Returns: True if successful, false otherwise.
     */
    public func fillAllContactFieldsWithAutofillAndHumanMovements(
        phoneNumber: String,
        email: String,
        name: String,
        ) async -> Bool {
        logger.info("👤 Filling all contact fields with autofill")

        guard webKitService?.webView != nil else {
            logger.error("❌ WebView not available")
            return false
        }

        // First try the comprehensive approach
        let comprehensiveResult = await fillAllFieldsComprehensive(phoneNumber: phoneNumber, email: email, name: name)
        if comprehensiveResult {
            return true
        }

        // If that fails, try filling fields individually
        logger.info("🔄 Comprehensive fill failed, trying individual field fills")
        return await fillFieldsIndividually(phoneNumber: phoneNumber, email: email, name: name)
    }

    /**
     * Comprehensive field filling approach with extensive selectors
     */
    private func fillAllFieldsComprehensive(
        phoneNumber: String,
        email: String,
        name: String,
        ) async -> Bool {
        guard let webView = webKitService?.webView else { return false }

        let script = """
        (function() {
            try {
                console.log('[ODYSSEY] Starting comprehensive contact form fill...');

                // More comprehensive field selectors
                const phoneField =
                    document.getElementById('phoneNumber') ||
                    document.querySelector('input[name*="phone"], input[name*="PhoneNumber"], input[type="tel"]') ||
                    document.querySelector('[placeholder*="phone"], [placeholder*="Phone"]') ||
                    document.querySelector('.phone-input, .phone-field') ||
                    document.querySelector('input[id*="phone"]') ||
                    document.querySelector('input[name*="tel"]');

                const emailField =
                    document.getElementById('email') ||
                    document.querySelector('input[name*="email"], input[type="email"]') ||
                    document.querySelector('[placeholder*="email"], [placeholder*="Email"]') ||
                    document.querySelector('.email-input, .email-field') ||
                    document.querySelector('input[id*="email"]');

                const nameField =
                    document.querySelector('input[id^="field"]') ||
                    document.getElementById('name') ||
                    document.querySelector('input[name*="name"], input[name*="Name"]') ||
                    document.querySelector('[placeholder*="name"], [placeholder*="Name"]') ||
                    document.querySelector('.name-input, .name-field') ||
                    document.querySelector('input[id*="name"]') ||
                    document.querySelector('input[name*="first"], input[name*="last"]');

                console.log('[ODYSSEY] Field search results:', {
                    phoneFound: !!phoneField,
                    emailFound: !!emailField,
                    nameFound: !!nameField
                });

                function fillFieldWithAutofill(field, value, fieldType) {
                    if (!field) {
                        console.log('[ODYSSEY] Field not found for type:', fieldType);
                        return false;
                    }

                    try {
                        console.log('[ODYSSEY] Filling field:', fieldType, 'with value:', value);

                        // Focus the field first (triggers autofill)
                        field.focus();

                        // Clear existing value
                        field.value = '';

                        // Set the new value
                        field.value = value;

                        // Trigger input events
                        field.dispatchEvent(new Event('input', { bubbles: true }));
                        field.dispatchEvent(new Event('change', { bubbles: true }));

                        console.log('[ODYSSEY] Successfully filled field:', fieldType);
                        return true;
                    } catch (error) {
                        console.error('[ODYSSEY] Error filling field:', fieldType, error);
                        return false;
                    }
                }

                let results = {
                    phone: false,
                    email: false,
                    name: false
                };

                // Fill phone number
                if (phoneField) {
                    results.phone = fillFieldWithAutofill(phoneField, '\(phoneNumber)', 'phone');
                }

                // Fill email
                if (emailField) {
                    results.email = fillFieldWithAutofill(emailField, '\(email)', 'email');
                }

                // Fill name
                if (nameField) {
                    results.name = fillFieldWithAutofill(nameField, '\(name)', 'name');
                }

                const success = results.phone || results.email || results.name;
                console.log('[ODYSSEY] Contact form fill results:', results);

                return {
                    success: success,
                    results: results,
                    fieldsFound: {
                        phone: !!phoneField,
                        email: !!emailField,
                        name: !!nameField
                    }
                };
            } catch (error) {
                console.error('[ODYSSEY] Error in contact form fill:', error);
                return {
                    success: false,
                    error: error.toString(),
                    results: { phone: false, email: false, name: false }
                };
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script)
            if
                let resultDict = result as? [String: Any],
                let success = resultDict["success"] as? Bool
            {
                if success {
                    logger.info("✅ All contact fields filled with autofill")
                    return true
                } else {
                    let error = resultDict["error"] as? String ?? "Unknown error"
                    logger.warning("⚠️ Contact fields autofill failed: \(error)")
                    return false
                }
            } else {
                logger.warning("⚠️ Contact fields autofill failed - invalid result")
                return false
            }
        } catch {
            logger.error("❌ Error filling contact fields: \(error.localizedDescription)")
            return false
        }
    }

    /**
     * Fallback method that tries to fill fields individually
     */
    private func fillFieldsIndividually(
        phoneNumber: String,
        email: String,
        name: String,
        ) async -> Bool {
        guard let webView = webKitService?.webView else { return false }

        let script = """
        (function() {
            try {
                console.log('[ODYSSEY] Starting individual field fill...');

                // Get all input fields on the page
                const allInputs = document.querySelectorAll('input[type="text"], input[type="email"], input[type="tel"], input:not([type])');
                console.log('[ODYSSEY] Found', allInputs.length, 'input fields');

                let filledCount = 0;
                const results = [];

                for (let i = 0; i < allInputs.length; i++) {
                    const input = allInputs[i];
                    const id = input.id || '';
                    const name = input.name || '';
                    const placeholder = input.placeholder || '';
                    const type = input.type || '';

                    console.log('[ODYSSEY] Checking input', i, ':', { id, name, placeholder, type });

                    let valueToFill = null;
                    let fieldType = '';

                    // Determine what to fill based on field attributes
                    if (id.toLowerCase().includes('phone') || name.toLowerCase().includes('phone') ||
                        placeholder.toLowerCase().includes('phone') || type === 'tel') {
                        valueToFill = '\(phoneNumber)';
                        fieldType = 'phone';
                    } else if (id.toLowerCase().includes('email') || name.toLowerCase().includes('email') ||
                               placeholder.toLowerCase().includes('email') || type === 'email') {
                        valueToFill = '\(email)';
                        fieldType = 'email';
                    } else if (id.toLowerCase().includes('name') || name.toLowerCase().includes('name') ||
                               placeholder.toLowerCase().includes('name') ||
                               id.startsWith('field') || name.startsWith('field')) {
                        valueToFill = '\(name)';
                        fieldType = 'name';
                    }

                    if (valueToFill) {
                        try {
                            console.log('[ODYSSEY] Filling', fieldType, 'field with:', valueToFill);
                            input.focus();
                            input.value = '';
                            input.value = valueToFill;
                            input.dispatchEvent(new Event('input', { bubbles: true }));
                            input.dispatchEvent(new Event('change', { bubbles: true }));
                            filledCount++;
                            results.push({ fieldType, success: true });
                        } catch (error) {
                            console.error('[ODYSSEY] Error filling', fieldType, 'field:', error);
                            results.push({ fieldType, success: false, error: error.toString() });
                        }
                    }
                }

                console.log('[ODYSSEY] Individual fill completed. Filled', filledCount, 'fields');
                return {
                    success: filledCount > 0,
                    filledCount: filledCount,
                    results: results
                };
            } catch (error) {
                console.error('[ODYSSEY] Error in individual field fill:', error);
                return {
                    success: false,
                    error: error.toString(),
                    filledCount: 0
                };
            }
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script)
            if
                let resultDict = result as? [String: Any],
                let success = resultDict["success"] as? Bool
            {
                if let filledCount = resultDict["filledCount"] as? Int {
                    logger.info("📊 Individual fill completed. Filled \(filledCount) fields")
                }

                if success {
                    logger.info("✅ Individual field fill successful")
                    return true
                } else {
                    let error = resultDict["error"] as? String ?? "Unknown error"
                    logger.warning("⚠️ Individual field fill failed: \(error)")
                    return false
                }
            } else {
                logger.warning("⚠️ Individual field fill failed - invalid result")
                return false
            }
        } catch {
            logger.error("❌ Error in individual field fill: \(error.localizedDescription)")
            return false
        }
    }
}
