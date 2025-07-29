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
            const phoneField =
                document.getElementById('phoneNumber') ||
                document.querySelector('input[name*="phone"], input[name*="PhoneNumber"], input[type="tel"]') ||
                document.querySelector('[placeholder*="phone"], [placeholder*="Phone"]') ||
                document.querySelector('.phone-input, .phone-field');

            if (!phoneField) {
                console.log('[ODYSSEY] Phone field not found');
                return false;
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
            return true;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script)
            if let success = result as? Bool, success {
                logger.info("✅ Phone number filled with autofill")
                return true
            } else {
                logger.warning("⚠️ Phone number autofill failed")
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

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available")
            return false
        }

        let script = """
        (function() {
            const phoneField =
                document.getElementById('phoneNumber') ||
                document.querySelector('input[name*="phone"], input[name*="PhoneNumber"], input[type="tel"]') ||
                document.querySelector('[placeholder*="phone"], [placeholder*="Phone"]') ||
                document.querySelector('.phone-input, .phone-field');

            const emailField =
                document.getElementById('email') ||
                document.querySelector('input[name*="email"], input[type="email"]') ||
                document.querySelector('[placeholder*="email"], [placeholder*="Email"]') ||
                document.querySelector('.email-input, .email-field');

            const nameField =
                document.getElementById('name') ||
                document.querySelector('input[name*="name"], input[name*="Name"]') ||
                document.querySelector('[placeholder*="name"], [placeholder*="Name"]') ||
                document.querySelector('.name-input, .name-field');

            function fillFieldWithAutofill(field, value) {
                if (!field) return false;

                // Focus the field first (triggers autofill)
                field.focus();

                // Clear existing value
                field.value = '';

                // Set the new value
                field.value = value;

                // Trigger input events
                field.dispatchEvent(new Event('input', { bubbles: true }));
                field.dispatchEvent(new Event('change', { bubbles: true }));

                return true;
            }

            let success = true;

            // Fill phone number
            if (phoneField) {
                const phoneFilled = fillFieldWithAutofill(phoneField, '\(phoneNumber)');
                if (!phoneFilled) success = false;
            }

            // Fill email
            if (emailField) {
                const emailFilled = fillFieldWithAutofill(emailField, '\(email)');
                if (!emailFilled) success = false;
            }

            // Fill name
            if (nameField) {
                const nameFilled = fillFieldWithAutofill(nameField, '\(name)');
                if (!nameFilled) success = false;
            }

            return success;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script)
            if let success = result as? Bool, success {
                logger.info("✅ All contact fields filled with autofill")
                return true
            } else {
                logger.warning("⚠️ Contact fields autofill failed")
                return false
            }
        } catch {
            logger.error("❌ Error filling contact fields: \(error.localizedDescription)")
            return false
        }
    }
}
