import Foundation
import os.log
import WebKit

/// Automation functionality for WebKit service
/// Handles element interaction, form filling, and automation scripts
@MainActor
extension WebKitCore {
    // MARK: - Element Interaction

    /// Finds and clicks an element with specific text
    /// - Parameter text: The text to search for
    /// - Returns: True if element was found and clicked, false otherwise
    func findAndClickElement(withText text: String) async -> Bool {
        logger.info("🔍 Finding and clicking element with text: '\(text, privacy: .private)'")

        let script = """
        (function() {
            const elements = document.querySelectorAll('*');
            for (let element of elements) {
                if (element.textContent && element.textContent.trim() === '\(text)') {
                    // Scroll into view
                    element.scrollIntoView({ behavior: 'smooth', block: 'center' });

                    // Simulate mouse events
                    const rect = element.getBoundingClientRect();
                    const centerX = rect.left + rect.width / 2;
                    const centerY = rect.top + rect.height / 2;

                    // Mouse down
                    element.dispatchEvent(new MouseEvent('mousedown', {
                        bubbles: true,
                        cancelable: true,
                        view: window,
                        clientX: centerX,
                        clientY: centerY
                    }));

                    // Mouse up
                    element.dispatchEvent(new MouseEvent('mouseup', {
                        bubbles: true,
                        cancelable: true,
                        view: window,
                        clientX: centerX,
                        clientY: centerY
                    }));

                    // Click
                    element.click();
                    return true;
                }
            }
            return false;
        })();
        """

        let result = await evaluateJavaScript(script) as? Bool ?? false

        if result {
            logger.info("✅ Successfully clicked element with text: '\(text, privacy: .private)'")
        } else {
            logger.error("❌ Failed to find element with text: '\(text, privacy: .private)'")
        }

        return result
    }

    /// Fills a form field with a value
    /// - Parameters:
    ///   - selector: CSS selector for the field
    ///   - value: Value to fill
    ///   - instant: Whether to fill instantly or simulate typing
    /// - Returns: True if field was filled, false otherwise
    func fillField(_ selector: String, value: String, instant: Bool = false) async -> Bool {
        logger.info("📝 Filling field '\(selector)' with value: '\(value, privacy: .private)'")

        let script = """
        (function() {
            const field = document.querySelector('\(selector)');
            if (!field) return false;

            field.focus();
            field.value = '';

            if (\(instant)) {
                field.value = '\(value)';
            } else {
                // Simulate typing
                for (let char of '\(value)') {
                    field.value += char;
                    field.dispatchEvent(new Event('input', { bubbles: true }));
                }
            }

            field.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
        })();
        """

        let result = await evaluateJavaScript(script) as? Bool ?? false

        if result {
            logger.info("✅ Successfully filled field '\(selector)'")
        } else {
            logger.error("❌ Failed to fill field '\(selector)'")
        }

        return result
    }

    /// Fills a form field with browser autofill behavior
    /// - Parameters:
    ///   - selector: CSS selector for the field
    ///   - value: Value to fill
    /// - Returns: True if field was filled, false otherwise
    func fillFieldWithAutofill(_ selector: String, value: String) async -> Bool {
        logger.info("📝 Filling field '\(selector)' with autofill behavior")

        let script = """
        (function() {
            const field = document.querySelector('\(selector)');
            if (!field) return false;

            // Browser autofill behavior: scroll into view
            field.scrollIntoView({ behavior: 'auto', block: 'center' });

            // Focus and clear
            field.focus();
            field.value = '';

            // Autofill-style: set value instantly
            field.value = '\(value)';

            // Dispatch autofill events
            field.dispatchEvent(new Event('input', { bubbles: true }));
            field.dispatchEvent(new Event('change', { bubbles: true }));
            field.dispatchEvent(new Event('autocomplete', { bubbles: true }));

            // Blur (browser autofill behavior)
            field.blur();

            return true;
        })();
        """

        let result = await evaluateJavaScript(script) as? Bool ?? false

        if result {
            logger.info("✅ Successfully filled field '\(selector)' with autofill behavior")
        } else {
            logger.error("❌ Failed to fill field '\(selector)' with autofill behavior")
        }

        return result
    }

    // MARK: - Reservation-specific Automation

    /// Waits for the group size page to load
    /// - Returns: True if page loaded, false if timeout
    func waitForGroupSizePage() async -> Bool {
        logger.info("⏳ Waiting for group size page to load.")

        // Wait for common group size page indicators
        let indicators = [
            "Number of People",
            "Group Size",
            "Participants",
            "How many people"
        ]

        for indicator in indicators {
            if await waitForText(indicator, timeout: 5.0) {
                logger.info("✅ Group size page loaded successfully.")
                return true
            }
        }

        logger.warning("⚠️ Group size page indicators not found.")
        return false
    }

    /// Fills the number of people field
    /// - Parameter count: Number of people
    /// - Returns: True if field was filled, false otherwise
    func fillNumberOfPeople(_ count: Int) async -> Bool {
        logger.info("👥 Filling number of people field with: \(count)")

        // Try multiple selectors for the number of people field
        let selectors = [
            "input[type='number']",
            "input[name*='ReservationCount']"
        ]

        for selector in selectors {
            if await fillField(selector, value: String(count), instant: true) {
                logger.info("✅ Successfully filled number of people field with: \(count)")
                return true
            }
        }

        logger.error("❌ Failed to fill number of people field with: \(count)")
        return false
    }

    /// Clicks the confirm button
    /// - Returns: True if button was clicked, false otherwise
    func clickConfirmButton() async -> Bool {
        logger.info("✅ Clicking confirm button.")

        // Try multiple text variations for confirm button
        let confirmTexts = [
            "Confirm"
        ]

        for text in confirmTexts {
            if await findAndClickElement(withText: text) {
                logger.info("✅ Successfully clicked confirm button.")
                return true
            }
        }

        logger.error("❌ Failed to click confirm button.")
        return false
    }

    /// Waits for the time selection page to load
    /// - Returns: True if page loaded, false if timeout
    func waitForTimeSelectionPage() async -> Bool {
        logger.info("⏳ Waiting for time selection page to load.")

        // Wait for common time selection page indicators
        let indicators = [
            "Select a date and time"
        ]

        for indicator in indicators {
            if await waitForText(indicator, timeout: 5.0) {
                logger.info("✅ Time selection page loaded successfully.")
                return true
            }
        }

        logger.warning("⚠️ Time selection page indicators not found.")
        return false
    }

    /// Selects a time slot
    /// - Parameters:
    ///   - dayName: Day name (e.g., "Mon", "Tue")
    ///   - timeString: Time string (e.g., "8:30 AM")
    /// - Returns: True if time slot was selected, false otherwise
    func selectTimeSlot(dayName: String, timeString: String) async -> Bool {
        logger.info("📅 Selecting time slot: \(dayName) at \(timeString, privacy: .private)")

        // Try to find and click the time slot
        let timeSlotText = "\(dayName) \(timeString)"
        let result = await findAndClickElement(withText: timeSlotText)

        if result {
            logger.info("✅ Successfully selected time slot: \(dayName) at \(timeString, privacy: .private)")
        } else {
            logger.error("❌ Failed to select time slot: \(dayName) at \(timeString, privacy: .private)")
        }

        return result
    }

    /// Waits for the contact information page to load
    /// - Returns: True if page loaded, false if timeout
    func waitForContactInfoPage() async -> Bool {
        logger.info("⏳ Waiting for contact information page to load.")

        // Wait for common contact info page indicators
        let indicators = [
            "following information",
            "Name",
            "Email",
            "Phone"
        ]

        for indicator in indicators {
            if await waitForText(indicator, timeout: 5.0) {
                logger.info("✅ Contact information page loaded successfully.")
                return true
            }
        }

        logger.warning("⚠️ Contact information page indicators not found.")
        return false
    }

    /// Fills all contact fields with autofill behavior
    /// - Parameters:
    ///   - phoneNumber: Phone number
    ///   - email: Email address
    ///   - name: Full name
    /// - Returns: True if all fields were filled, false otherwise
    func fillAllContactFieldsWithAutofill(phoneNumber: String, email: String, name: String) async -> Bool {
        logger.info("📝 Filling all contact fields with autofill behavior.")

        // Common field selectors
        let fieldMappings = [
            "input[name*='field2021']": name,
            "input[name*='email']": email,
            "input[name*='PhoneNumber']": phoneNumber,
            "input[name*='tel']": phoneNumber,
            "input[type='email']": email,
            "input[type='tel']": phoneNumber
        ]

        var successCount = 0

        for (selector, value) in fieldMappings {
            if await fillFieldWithAutofill(selector, value: value) {
                successCount += 1
            }
        }

        let success = successCount > 0

        if success {
            logger.info("✅ Successfully filled \(successCount) contact fields.")
        } else {
            logger.error("❌ Failed to fill any contact fields.")
        }

        return success
    }

    /// Clicks the contact information confirm button
    /// - Returns: True if button was clicked, false otherwise
    func clickContactInfoConfirmButton() async -> Bool {
        logger.info("✅ Clicking contact information confirm button.")

        // Try multiple text variations for confirm button
        let confirmTexts = [
            "Confirm"
        ]

        for text in confirmTexts {
            if await findAndClickElement(withText: text) {
                logger.info("✅ Successfully clicked contact information confirm button.")
                return true
            }
        }

        logger.error("❌ Failed to click contact information confirm button.")
        return false
    }

    /// Detects if retry text appears after clicking confirm
    /// - Returns: True if retry text is detected, false otherwise
    func detectRetryText() async -> Bool {
        logger.info("🔍 Checking for retry text.")

        // Common retry text indicators
        let retryTexts = [
            "Retry"
        ]

        for text in retryTexts {
            if await pageContainsText(text) {
                logger.warning("⚠️ Retry text detected: '\(text)'")
                return true
            }
        }

        logger.info("✅ No retry text detected.")
        return false
    }

    /// Checks if email verification is required
    /// - Returns: True if email verification is required, false otherwise
    func isEmailVerificationRequired() async -> Bool {
        logger.info("📧 Checking if email verification is required.")

        // Common email verification indicators
        let verificationTexts = [
            "verification code",
            "receive the code"
        ]

        for text in verificationTexts {
            if await pageContainsText(text) {
                logger.info("✅ Email verification is required.")
                return true
            }
        }

        logger.info("✅ Email verification is not required.")
        return false
    }

    // MARK: - Utility Methods

    /// Adds a quick pause for human-like behavior
    func addQuickPause() async {
        let pauseDuration = Double.random(in: 0.5 ... 1.0)
        try? await Task.sleep(nanoseconds: UInt64(pauseDuration * 1_000_000_000))
    }

    /// Simulates enhanced human movements before clicking confirm
    func simulateEnhancedHumanMovementsBeforeConfirm() async {
        logger.info("🤖 Simulating enhanced human movements before confirm.")

        // Add random pause
        await addQuickPause()

        // Add another random pause
        await addQuickPause()

        logger.info("✅ Enhanced human movements simulation completed.")
    }
}
