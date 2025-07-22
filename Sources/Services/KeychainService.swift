import Foundation
import os.log
import Security

/// Secure credential storage service using Keychain Services
/// Provides secure storage and retrieval of sensitive data like email credentials
@MainActor
public final class KeychainService: @unchecked Sendable, KeychainServiceProtocol {
    public static let shared = KeychainService()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "KeychainService")

    private init() { }

    // MARK: - Email Credentials

    /// Store email credentials securely in Keychain
    /// - Parameters:
    ///   - email: Email address
    ///   - password: Email password
    ///   - server: IMAP server address
    ///   - port: IMAP server port
    /// - Returns: Success status
    public func storeEmailCredentials(email: String, password: String, server: String, port: Int) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: email,
            kSecAttrServer as String: server,
            kSecAttrPort as String: port,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing credentials first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            logger.info("🔐 Email credentials stored securely for \(email).")
            return true
        } else {
            logger.error("❌ Failed to store email credentials: \(status).")
            return false
        }
    }

    /// Retrieve email credentials from Keychain
    /// - Parameters:
    ///   - email: Email address
    ///   - server: IMAP server address
    ///   - port: IMAP server port
    /// - Returns: Email password if found
    public func retrieveEmailPassword(email: String, server: String, port: Int) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: email,
            kSecAttrServer as String: server,
            kSecAttrPort as String: port,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if
            status == errSecSuccess,
            let data = result as? Data,
            let password = String(data: data, encoding: .utf8) {
            logger.info("🔐 Email credentials retrieved for \(email).")
            return password
        } else {
            logger.warning("⚠️ No email credentials found for \(email).")
            return nil
        }
    }

    /// Delete email credentials from Keychain
    /// - Parameters:
    ///   - email: Email address
    ///   - server: IMAP server address
    ///   - port: IMAP server port
    /// - Returns: Success status
    public func deleteEmailCredentials(email: String, server: String, port: Int) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: email,
            kSecAttrServer as String: server,
            kSecAttrPort as String: port
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            logger.info("🧹 Email credentials deleted for \(email).")
            return true
        } else {
            logger.error("❌ Failed to delete email credentials: \(status).")
            return false
        }
    }

    /// Check if email credentials exist in Keychain
    /// - Parameters:
    ///   - email: Email address
    ///   - server: IMAP server address
    ///   - port: IMAP server port
    /// - Returns: True if credentials exist
    public func hasEmailCredentials(email: String, server: String, port: Int) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: email,
            kSecAttrServer as String: server,
            kSecAttrPort as String: port,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Generic Key-Value Storage

    /// Store a generic value securely in Keychain
    /// - Parameters:
    ///   - value: Value to store
    ///   - key: Unique key for the value
    ///   - service: Service identifier
    /// - Returns: Success status
    public func storeValue(_ value: String, forKey key: String, service: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecValueData as String: value.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing value first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            logger.info("🔐 Value stored securely for key: \(key).")
            return true
        } else {
            logger.error("❌ Failed to store value for key \(key): \(status).")
            return false
        }
    }

    /// Retrieve a generic value from Keychain
    /// - Parameters:
    ///   - key: Unique key for the value
    ///   - service: Service identifier
    /// - Returns: Stored value if found
    public func retrieveValue(forKey key: String, service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if
            status == errSecSuccess,
            let data = result as? Data,
            let value = String(data: data, encoding: .utf8) {
            logger.info("🔐 Value retrieved for key: \(key).")
            return value
        } else {
            logger.warning("⚠️ No value found for key: \(key).")
            return nil
        }
    }

    /// Delete a generic value from Keychain
    /// - Parameters:
    ///   - key: Unique key for the value
    ///   - service: Service identifier
    /// - Returns: Success status
    public func deleteValue(forKey key: String, service: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            logger.info("🧹 Value deleted for key: \(key).")
            return true
        } else {
            logger.error("❌ Failed to delete value for key \(key): \(status).")
            return false
        }
    }

    // MARK: - Utility Methods

    /// Get human-readable error message for Keychain status
    /// - Parameter status: Keychain status code
    /// - Returns: Error description
    private func keychainErrorDescription(_ status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecDuplicateItem:
            return "Item already exists"
        case errSecItemNotFound:
            return "Item not found"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecParam:
            return "Invalid parameters"
        case errSecNotAvailable:
            return "Keychain not available"
        case errSecDecode:
            return "Decode error"
        case errSecUnimplemented:
            return "Unimplemented"
        default:
            return "Unknown error (\(status))"
        }
    }

    /// Clear all ODYSSEY-related items from Keychain
    /// - Returns: Success status
    public func clearAllOdysseyItems() -> Bool {
        logger.info("🧹 Clearing all ODYSSEY items from Keychain.")

        // Clear generic passwords
        let genericQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.odyssey.app"
        ]

        let genericStatus = SecItemDelete(genericQuery as CFDictionary)

        // Clear internet passwords (email credentials)
        let internetQuery: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: "imap"
        ]

        let internetStatus = SecItemDelete(internetQuery as CFDictionary)

        let success = genericStatus == errSecSuccess || genericStatus == errSecItemNotFound
        let internetSuccess = internetStatus == errSecSuccess || internetStatus == errSecItemNotFound

        if success, internetSuccess {
            logger.info("✅ All ODYSSEY items cleared from Keychain.")
            return true
        } else {
            logger.error("❌ Failed to clear some ODYSSEY items from Keychain.")
            return false
        }
    }
}

// Register the singleton for DI
extension KeychainService {
    static func registerForDI() {
        ServiceRegistry.shared.register(KeychainService.shared, for: KeychainServiceProtocol.self)
    }
}
