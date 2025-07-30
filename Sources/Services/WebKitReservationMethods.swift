import Foundation
import os.log
import WebKit

@MainActor
public final class WebKitReservationMethods {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "WebKitReservation")

    // Reference to the main WebKit service for webView access
    private weak var webKitService: WebKitService?

    init(webKitService: WebKitService) {
        self.webKitService = webKitService
    }

    // MARK: - Reservation-specific Methods

    /**
     * Fills phone number field for reservation forms.
     * - Parameter phoneNumber: The phone number to fill.
     * - Returns: True if successful, false otherwise.
     */
    public func fillPhoneNumber(_ phoneNumber: String) async -> Bool {
        logger.info("📞 Filling phone number: \(phoneNumber).")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available.")
            return false
        }

        let script = """
        (function() {
            const phoneField =
                document.querySelector('input[name*="PhoneNumber"]') ||
                document.querySelector('input[name*="phone"], input[type="tel"]') ||
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
                logger.info("✅ Phone number filled.")
                return true
            } else {
                logger.warning("⚠️ Phone number fill failed.")
                return false
            }
        } catch {
            logger.error("❌ Error filling phone number: \(error.localizedDescription).")
            return false
        }
    }

    /**
     * Fills email field for reservation forms.
     * - Parameter email: The email address to fill.
     * - Returns: True if successful, false otherwise.
     */
    public func fillEmail(_ email: String) async -> Bool {
        logger.info("📧 Filling email: \(email).")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available.")
            return false
        }

        let script = """
        (function() {
            const emailField =
                document.querySelector('input[name*="email"], input[type="email"]') ||
                document.querySelector('[placeholder*="email"], [placeholder*="Email"]') ||
                document.querySelector('.email-input, .email-field');

            if (!emailField) {
                console.log('[ODYSSEY] Email field not found');
                return false;
            }

            console.log('[ODYSSEY] Found email field:', {
                id: emailField.id,
                name: emailField.name,
                className: emailField.className,
                type: emailField.type
            });

            // Clear existing value
            emailField.value = '';

            // Set the new value
            emailField.value = '\(email)';

            // Trigger input events
            emailField.dispatchEvent(new Event('input', { bubbles: true }));
            emailField.dispatchEvent(new Event('change', { bubbles: true }));

            console.log('[ODYSSEY] Email filled successfully');
            return true;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script)
            if let success = result as? Bool, success {
                logger.info("✅ Email filled.")
                return true
            } else {
                logger.warning("⚠️ Email fill failed.")
                return false
            }
        } catch {
            logger.error("❌ Error filling email: \(error.localizedDescription).")
            return false
        }
    }

    /**
     * Fills name field for reservation forms.
     * - Parameter name: The name to fill.
     * - Returns: True if successful, false otherwise.
     */
    public func fillName(_ name: String) async -> Bool {
        logger.info("👤 Filling name: \(name).")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available")
            return false
        }

        let script = """
        (function() {
            const nameField =
                document.querySelector('input[name*="name"], input[name*="Name"]') ||
                document.querySelector('[placeholder*="name"], [placeholder*="Name"]') ||
                document.querySelector('.name-input, .name-field');

            if (!nameField) {
                console.log('[ODYSSEY] Name field not found');
                return false;
            }

            console.log('[ODYSSEY] Found name field:', {
                id: nameField.id,
                name: nameField.name,
                className: nameField.className,
                type: nameField.type
            });

            // Clear existing value
            nameField.value = '';

            // Set the new value
            nameField.value = '\(name)';

            // Trigger input events
            nameField.dispatchEvent(new Event('input', { bubbles: true }));
            nameField.dispatchEvent(new Event('change', { bubbles: true }));

            console.log('[ODYSSEY] Name filled successfully');
            return true;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script)
            if let success = result as? Bool, success {
                logger.info("✅ Name filled.")
                return true
            } else {
                logger.warning("⚠️ Name fill failed.")
                return false
            }
        } catch {
            logger.error("❌ Error filling name: \(error.localizedDescription).")
            return false
        }
    }

    /**
     * Checks if email verification is required on the current page.
     * - Returns: True if verification is required, false otherwise.
     */
    public func isEmailVerificationRequired() async -> Bool {
        logger.info("🔍 Checking if email verification is required.")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available")
            return false
        }

        let script = """
        (function() {
            const verificationElements = document.querySelectorAll('[class*="verification"], [id*="verification"], [class*="verify"], [id*="verify"]');
            const verificationInputs = document.querySelectorAll('input[name*="verification"], input[name*="verify"], input[placeholder*="code"], input[placeholder*="Code"]');
            const verificationText = document.body.innerText.toLowerCase();

            const hasVerificationElements = verificationElements.length > 0;
            const hasVerificationInputs = verificationInputs.length > 0;
            const hasVerificationText = verificationText.includes('verification') ||
                                       verificationText.includes('verify') ||
                                       verificationText.includes('code') ||
                                       verificationText.includes('otp');

            const isRequired = hasVerificationElements || hasVerificationInputs || hasVerificationText;

            console.log('[ODYSSEY] Email verification check:', {
                hasVerificationElements,
                hasVerificationInputs,
                hasVerificationText,
                isRequired
            });

            return isRequired;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script)
            if let required = result as? Bool {
                logger.info("✅ Email verification check completed: \(required).")
                return required
            } else {
                logger.warning("⚠️ Email verification check failed.")
                return false
            }
        } catch {
            logger.error("❌ Error checking email verification: \(error.localizedDescription).")
            return false
        }
    }

    /**
     * Waits for DOM to be ready for automation.
     * - Returns: True if DOM is ready, false otherwise.
     */
    public func waitForDOMReady() async -> Bool {
        logger.info("⏳ Waiting for DOM to be ready.")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available")
            return false
        }

        let script = """
        (function() {
            return document.readyState === 'complete' &&
                   document.body !== null &&
                   document.body.innerHTML.length > 0;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script)
            if let ready = result as? Bool, ready {
                logger.info("✅ DOM is ready.")
                return true
            } else {
                logger.warning("⚠️ DOM not ready.")
                return false
            }
        } catch {
            logger.error("❌ Error checking DOM readiness: \(error.localizedDescription).")
            return false
        }
    }
}
