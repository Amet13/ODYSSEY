import Foundation
import os.log
import Security

@MainActor
public final class EmailKeychainHelper {
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "EmailKeychain")

    // MARK: - Keychain Credential Helper

    /**
     * Stores email credentials securely in the keychain.
     * - Parameters:
     *   - email: The email address.
     *   - password: The email password or App Password.
     * - Returns: True if successful, false otherwise.
     */
    public func storeEmailCredentials(email: String, password: String) -> Bool {
        logger.info("🔐 Storing email credentials in keychain")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecValueData as String: password.data(using: .utf8) ?? Data(),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        // Delete existing credentials first
        SecItemDelete(query as CFDictionary)

        // Store new credentials
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            logger.info("✅ Email credentials stored successfully")
            return true
        } else {
            logger.error("❌ Failed to store email credentials: \(status)")
            return false
        }
    }

    /**
     * Retrieves email credentials from the keychain.
     * - Parameter email: The email address.
     * - Returns: The password if found, nil otherwise.
     */
    public func retrieveEmailCredentials(email: String) -> String? {
        logger.info("🔍 Retrieving email credentials from keychain")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if
            status == errSecSuccess,
            let data = result as? Data,
            let password = String(data: data, encoding: .utf8)
        {
            logger.info("✅ Email credentials retrieved successfully")
            return password
        } else {
            logger.warning("⚠️ Email credentials not found in keychain")
            return nil
        }
    }

    /**
     * Deletes email credentials from the keychain.
     * - Parameter email: The email address.
     * - Returns: True if successful, false otherwise.
     */
    public func deleteEmailCredentials(email: String) -> Bool {
        logger.info("🗑️ Deleting email credentials from keychain")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            logger.info("✅ Email credentials deleted successfully")
            return true
        } else {
            logger.error("❌ Failed to delete email credentials: \(status)")
            return false
        }
    }

    /**
     * Checks if email credentials exist in the keychain.
     * - Parameter email: The email address.
     * - Returns: True if credentials exist, false otherwise.
     */
    public func hasEmailCredentials(email: String) -> Bool {
        logger.info("🔍 Checking if email credentials exist in keychain")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        let exists = status == errSecSuccess

        logger.info("✅ Email credentials exist: \(exists)")
        return exists
    }

    /**
     * Updates email credentials in the keychain.
     * - Parameters:
     *   - email: The email address.
     *   - password: The new password.
     * - Returns: True if successful, false otherwise.
     */
    public func updateEmailCredentials(email: String, password: String) -> Bool {
        logger.info("🔄 Updating email credentials in keychain")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: password.data(using: .utf8) ?? Data(),
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecSuccess {
            logger.info("✅ Email credentials updated successfully")
            return true
        } else {
            logger.error("❌ Failed to update email credentials: \(status)")
            return false
        }
    }
}
