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
        logger.info("📞 Filling phone number with autofill: \(phoneNumber).")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available.")
            return false
        }

        let script = "window.odyssey.fillPhoneNumber('\(phoneNumber)');"

        do {
            let result = try await webView.evaluateJavaScript(script)
            if let success = result as? Bool, success {
                logger.info("✅ Phone number filled with autofill.")
                return true
            } else {
                logger.warning("⚠️ Phone number autofill failed.")
                return false
            }
        } catch {
            logger.error("❌ Error filling phone number: \(error.localizedDescription).")
            return false
        }
    }

    /**
     * Fills all contact fields with autofill and human-like movements using centralized library.
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
        logger.info("👤 Filling all contact fields with autofill.")

        guard webKitService?.webView != nil else {
            logger.error("❌ WebView not available.")
            return false
        }

        // Use centralized library for comprehensive contact form filling
        let comprehensiveResult = await fillAllFieldsComprehensive(phoneNumber: phoneNumber, email: email, name: name)
        if comprehensiveResult {
            return true
        }

        // If that fails, try filling fields individually
        logger.info("🔄 Comprehensive fill failed, trying individual field fills.")
        return await fillFieldsIndividually(phoneNumber: phoneNumber, email: email, name: name)
    }

    /**
     * Comprehensive field filling approach using centralized library
     */
    private func fillAllFieldsComprehensive(
        phoneNumber: String,
        email: String,
        name: String,
        ) async -> Bool {
        guard let webView = webKitService?.webView else { return false }

        let script = "window.odyssey.fillContactFields('\(phoneNumber)', '\(email)', '\(name)');"

        do {
            let result = try await webView.evaluateJavaScript(script)
            if
                let resultDict = result as? [String: Any],
                let success = resultDict["success"] as? Bool
            {
                if success {
                    logger.info("✅ All contact fields filled with autofill.")
                    return true
                } else {
                    let error = resultDict["error"] as? String ?? "Unknown error"
                    logger.warning("⚠️ Contact fields autofill failed: \(error).")
                    return false
                }
            } else {
                logger.warning("⚠️ Contact fields autofill failed - invalid result.")
                return false
            }
        } catch {
            logger.error("❌ Error filling contact fields: \(error.localizedDescription).")
            return false
        }
    }

    /**
     * Fallback method that tries to fill fields individually using centralized library
     */
    private func fillFieldsIndividually(
        phoneNumber: String,
        email: String,
        name: String,
        ) async -> Bool {
        guard let webView = webKitService?.webView else { return false }

        let script = "window.odyssey.fillFieldsIndividually('\(phoneNumber)', '\(email)', '\(name)');"

        do {
            let result = try await webView.evaluateJavaScript(script)
            if
                let resultDict = result as? [String: Any],
                let success = resultDict["success"] as? Bool
            {
                if let filledCount = resultDict["filledCount"] as? Int {
                    logger.info("📊 Individual fill completed. Filled \(filledCount) fields.")
                }

                if success {
                    logger.info("✅ Individual field fill successful.")
                    return true
                } else {
                    let error = resultDict["error"] as? String ?? "Unknown error"
                    logger.warning("⚠️ Individual field fill failed: \(error).")
                    return false
                }
            } else {
                logger.warning("⚠️ Individual field fill failed - invalid result.")
                return false
            }
        } catch {
            logger.error("❌ Error in individual field fill: \(error.localizedDescription).")
            return false
        }
    }
}
