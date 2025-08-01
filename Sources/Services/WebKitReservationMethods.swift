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
     * Fills phone number field for reservation forms using centralized library.
     * - Parameter phoneNumber: The phone number to fill.
     * - Returns: True if successful, false otherwise.
     */
    public func fillPhoneNumber(_ phoneNumber: String) async -> Bool {
        logger.info("📞 Filling phone number: \(phoneNumber).")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available.")
            return false
        }

        let script = "window.odyssey.fillFormField('phone', '\(phoneNumber)');"

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
     * Fills email field for reservation forms using centralized library.
     * - Parameter email: The email address to fill.
     * - Returns: True if successful, false otherwise.
     */
    public func fillEmail(_ email: String) async -> Bool {
        logger.info("📧 Filling email: \(email).")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available.")
            return false
        }

        let script = "window.odyssey.fillFormField('email', '\(email)');"

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
     * Fills name field for reservation forms using centralized library.
     * - Parameter name: The name to fill.
     * - Returns: True if successful, false otherwise.
     */
    public func fillName(_ name: String) async -> Bool {
        logger.info("👤 Filling name: \(name).")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available")
            return false
        }

        let script = "window.odyssey.fillFormField('name', '\(name)');"

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
     * Checks if email verification is required on the current page using centralized library.
     * - Returns: True if verification is required, false otherwise.
     */
    public func isEmailVerificationRequired() async -> Bool {
        logger.info("🔍 Checking if email verification is required.")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available")
            return false
        }

        let script = "window.odyssey.isEmailVerificationRequired();"

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
     * Waits for DOM to be ready for automation using centralized library.
     * - Returns: True if DOM is ready, false otherwise.
     */
    public func waitForDOMReady() async -> Bool {
        logger.info("⏳ Waiting for DOM to be ready.")

        guard let webView = webKitService?.webView else {
            logger.error("❌ WebView not available")
            return false
        }

        let script = "window.odyssey.isDOMReady();"

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
