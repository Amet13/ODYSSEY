import Combine
import Foundation
import os.log
import Security

/// Secure credential storage service using Keychain Services
/// Provides secure storage and retrieval of sensitive data like email credentials

/// Keychain error type for detailed error reporting
public enum KeychainError: Error, LocalizedError, UnifiedErrorProtocol {
    case encodingFailed
    case itemAddFailed(OSStatus)
    case itemDeleteFailed(OSStatus)
    case itemNotFound
    case itemRetrieveFailed(OSStatus)
    case unknown(OSStatus)

    public var errorDescription: String? {
        return userFriendlyMessage
    }

    /// Unique error code for categorization and debugging
    public var errorCode: String {
        switch self {
        case .encodingFailed: return "KEYCHAIN_ENCODING_001"
        case .itemAddFailed: return "KEYCHAIN_ADD_001"
        case .itemDeleteFailed: return "KEYCHAIN_DELETE_001"
        case .itemNotFound: return "KEYCHAIN_NOTFOUND_001"
        case .itemRetrieveFailed: return "KEYCHAIN_RETRIEVE_001"
        case .unknown: return "KEYCHAIN_UNKNOWN_001"
        }
    }

    /// Category for grouping similar errors
    public var errorCategory: ErrorCategory {
        switch self {
        case .encodingFailed, .itemAddFailed, .itemDeleteFailed, .itemRetrieveFailed, .itemNotFound,
             .unknown: return .system
        }
    }

    /// User-friendly error message for UI display
    public var userFriendlyMessage: String {
        switch self {
        case .encodingFailed:
            return "Failed to encode value for Keychain."
        case let .itemAddFailed(status):
            return "Failed to add item to Keychain: \(status)"
        case let .itemDeleteFailed(status):
            return "Failed to delete item from Keychain: \(status)"
        case .itemNotFound:
            return "Item not found in Keychain."
        case let .itemRetrieveFailed(status):
            return "Failed to retrieve item from Keychain: \(status)"
        case let .unknown(status):
            return "Unknown Keychain error: \(status)"
        }
    }

    /// Technical details for debugging (optional)
    public var technicalDetails: String? {
        switch self {
        case .encodingFailed: return "Data encoding failed for Keychain storage"
        case let .itemAddFailed(status): return "Keychain SecItemAdd failed with status: \(status)"
        case let .itemDeleteFailed(status): return "Keychain SecItemDelete failed with status: \(status)"
        case .itemNotFound: return "Keychain SecItemCopyMatching returned errSecItemNotFound"
        case let .itemRetrieveFailed(status): return "Keychain SecItemCopyMatching failed with status: \(status)"
        case let .unknown(status): return "Unexpected Keychain operation failed with status: \(status)"
        }
    }
}

@MainActor
public final class KeychainService: @unchecked Sendable, KeychainServiceProtocol {
    public static let shared = KeychainService()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "KeychainService")
    @Published public var lastError: KeychainError?
    public var onError: ((KeychainError) -> Void)?

    private init() { }

    // MARK: - Email Credentials

    /// Store email credentials securely in Keychain
    public func storeEmailCredentials(
        email: String,
        password: String,
        server: String,
        port: Int,
    ) -> Result<Void, KeychainError> {
        guard let passwordData = password.data(using: .utf8) else {
            let err = KeychainError.encodingFailed
            handleError(err)
            return .failure(err)
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: email,
            kSecAttrServer as String: server,
            kSecAttrPort as String: port,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            logger.info("🔐 Email credentials stored securely for \(email).")
            return .success(())
        } else {
            let err = KeychainError.itemAddFailed(status)
            handleError(err)
            return .failure(err)
        }
    }

    /// Retrieve email credentials from Keychain
    public func retrieveEmailPassword(email: String, server: String, port: Int) -> Result<String, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: email,
            kSecAttrServer as String: server,
            kSecAttrPort as String: port,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let password = String(data: data, encoding: .utf8) {
            logger.info("🔐 Email credentials retrieved for \(email).")
            return .success(password)
        } else if status == errSecItemNotFound {
            let err = KeychainError.itemNotFound
            handleError(err)
            return .failure(err)
        } else {
            let err = KeychainError.itemRetrieveFailed(status)
            handleError(err)
            return .failure(err)
        }
    }

    /// Delete email credentials from Keychain
    public func deleteEmailCredentials(email: String, server: String, port: Int) -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: email,
            kSecAttrServer as String: server,
            kSecAttrPort as String: port,
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            logger.info("🧹 Email credentials deleted for \(email).")
            return .success(())
        } else if status == errSecItemNotFound {
            let err = KeychainError.itemNotFound
            handleError(err)
            return .failure(err)
        } else {
            let err = KeychainError.itemDeleteFailed(status)
            handleError(err)
            return .failure(err)
        }
    }

    /// Check if email credentials exist in Keychain
    public func hasEmailCredentials(email: String, server: String, port: Int) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: email,
            kSecAttrServer as String: server,
            kSecAttrPort as String: port,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Generic Key-Value Storage

    public func storeValue(_ value: String, forKey key: String, service: String) -> Result<Void, KeychainError> {
        guard let valueData = value.data(using: .utf8) else {
            let err = KeychainError.encodingFailed
            handleError(err)
            return .failure(err)
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecValueData as String: valueData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            logger.info("🔐 Value stored securely for key: \(key).")
            return .success(())
        } else {
            let err = KeychainError.itemAddFailed(status)
            handleError(err)
            return .failure(err)
        }
    }

    public func retrieveValue(forKey key: String, service: String) -> Result<String, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let value = String(data: data, encoding: .utf8) {
            logger.info("🔐 Value retrieved for key: \(key).")
            return .success(value)
        } else if status == errSecItemNotFound {
            let err = KeychainError.itemNotFound
            handleError(err)
            return .failure(err)
        } else {
            let err = KeychainError.itemRetrieveFailed(status)
            handleError(err)
            return .failure(err)
        }
    }

    public func deleteValue(forKey key: String, service: String) -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            logger.info("🧹 Value deleted for key: \(key).")
            return .success(())
        } else if status == errSecItemNotFound {
            let err = KeychainError.itemNotFound
            handleError(err)
            return .failure(err)
        } else {
            let err = KeychainError.itemDeleteFailed(status)
            handleError(err)
            return .failure(err)
        }
    }

    // MARK: - Utility Methods

    private func handleError(_ error: KeychainError) {
        lastError = error
        logger.error("❌ Keychain error: \(error.localizedDescription).")
        onError?(error)
        logger.error("❌ Keychain error: \(error.localizedDescription).")
    }

    public func clearAllOdysseyItems() -> Result<Void, KeychainError> {
        logger.info("🧹 Clearing all ODYSSEY items from Keychain.")
        let genericQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.odyssey.app",
        ]
        let genericStatus = SecItemDelete(genericQuery as CFDictionary)
        let internetQuery: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: "imap",
        ]
        let internetStatus = SecItemDelete(internetQuery as CFDictionary)
        let success = genericStatus == errSecSuccess || genericStatus == errSecItemNotFound
        let internetSuccess = internetStatus == errSecSuccess || internetStatus == errSecItemNotFound
        if success, internetSuccess {
            logger.info("✅ All ODYSSEY items cleared from Keychain.")
            return .success(())
        } else {
            let err = KeychainError.unknown(genericStatus != errSecSuccess ? genericStatus : internetStatus)
            handleError(err)
            return .failure(err)
        }
    }
}

// Register the singleton for DI
public extension KeychainService {
    static func registerForDI() { }
}
