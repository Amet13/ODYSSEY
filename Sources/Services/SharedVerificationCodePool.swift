import Combine
import Foundation
import os.log

@MainActor
public final class SharedVerificationCodePool: ObservableObject, @unchecked Sendable {
    public static let shared = SharedVerificationCodePool()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "SharedCodePool")
    private let emailService = EmailService.shared

    // Shared pool of available codes per instance.
    private var codePool: [String: [String]] = [:] // instanceId -> [codes]

    // Track which codes have been consumed by which instances.
    private var consumedCodes: [String: [String]] = [:] // instanceId -> [codes]

    // Track when codes were last fetched to avoid stale data.
    private var lastFetchTime: [String: Date] = [:] // instanceId -> Date

    private init() {
        logger.info("🔧 SharedVerificationCodePool initialized.")
    }

    deinit {
        // Cleanup if needed.
    }

    /// Consumes verification codes for a specific instance.
    /// - Parameters:
    ///   - instanceId: Unique identifier for the instance.
    ///   - since: Date to search from.
    /// - Returns: Array of verification codes.
    func consumeCodes(for instanceId: String, since: Date) async -> [String] {
        logger.info("🔄 SharedCodePool: Consuming codes for instance \(instanceId).")
        logger.info("🔄 SharedCodePool: Using since parameter: \(since).")

        // Check if we need to refresh the code pool.
        if shouldRefreshCodePool(for: instanceId, since: since) {
            logger.info("🔄 SharedCodePool: Refreshing code pool for instance \(instanceId).")
            await refreshCodePool(for: instanceId, since: since)
        }

        // Return available codes and mark them as consumed.
        let availableCodes = codePool[instanceId] ?? []
        if !availableCodes.isEmpty {
            consumedCodes[instanceId] = (consumedCodes[instanceId] ?? []) + availableCodes
            codePool[instanceId] = []
        }

        return availableCodes
    }

    /// Refreshes the code pool by fetching fresh codes from email.
    /// - Parameters:
    ///   - instanceId: Unique identifier for the instance.
    ///   - since: Date to search from.
    private func refreshCodePool(for instanceId: String, since: Date) async {
        logger.info("📧 SharedCodePool: Fetching fresh codes from email.")
        logger.info("📧 SharedCodePool: Using since parameter: \(since).")

        // Fetch fresh codes from email service.
        let freshCodes = await emailService.fetchVerificationCodesForToday(since: since)

        // Store the fresh codes.
        codePool[instanceId] = freshCodes
        lastFetchTime[instanceId] = Date()

        logger.info("✅ SharedCodePool: Refreshed with \(freshCodes.count) codes for instance \(instanceId).")
    }

    /// Determines if the code pool should be refreshed.
    /// - Parameters:
    ///   - instanceId: Unique identifier for the instance.
    ///   - since: Date to search from.
    /// - Returns: True if refresh is needed.
    private func shouldRefreshCodePool(for instanceId: String, since _: Date) -> Bool {
        if (codePool[instanceId] ?? []).isEmpty {
            logger.info("🔄 SharedCodePool: Refreshing - no codes available.")
            return true
        }

        if let lastFetch = lastFetchTime[instanceId] {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            if timeSinceLastFetch > AppConstants.codePoolRefreshIntervalSeconds {
                logger.info("🔄 SharedCodePool: Refreshing - \(timeSinceLastFetch) seconds since last fetch.")
                return true
            }
        }

        return false
    }

    /// Clears consumed codes for cleanup.
    func clearConsumedCodes() {
        consumedCodes.removeAll()
        logger.info("🧹 SharedCodePool: Cleared consumed codes.")
    }

    /// Gets current pool status for debugging.
    public func getPoolStatus() -> (available: Int, consumed: Int) {
        let available = codePool.values.flatMap(\.self).count
        let consumed = consumedCodes.values.flatMap(\.self).count
        return (available: available, consumed: consumed)
    }

    /// Checks if a verification code has already been consumed by another instance.
    /// - Parameters:
    ///   - code: The verification code to check.
    ///   - currentInstanceId: The ID of the current instance.
    /// - Returns: Always false (all windows can try all codes independently).
    public func isCodeConsumedByOtherInstance(_: String, currentInstanceId _: String) -> Bool {
        // With new logic, all windows can try all codes independently.
        return false
    }

    /// Marks a verification code as consumed by a specific instance.
    /// - Parameters:
    ///   - code: The verification code to mark as consumed.
    ///   - instanceId: The ID of the instance that consumed the code.
    public func markCodeAsConsumed(_ code: String, byInstanceId instanceId: String) {
        if consumedCodes[instanceId] == nil {
            consumedCodes[instanceId] = []
        }
        consumedCodes[instanceId]?.append(code)
        logger
            .info(
                "✅ SharedCodePool: Marked code \(String(repeating: "*", count: code.count)) as consumed by instance \(instanceId)",
            )
    }
}
