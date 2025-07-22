import Combine
import Foundation
import os.log

@MainActor
public final class SharedVerificationCodePool: ObservableObject, @unchecked Sendable {
    public static let shared = SharedVerificationCodePool()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "SharedCodePool")

    // Shared pool of available codes
    private var availableCodes: [String] = []

    // Track which codes have been consumed by which instances
    private var consumedCodes: [String: String] = [:] // code -> instanceId

    // Track when codes were last fetched to avoid stale data
    private var lastFetchTime: Date?

    private init() {
        logger.info("🔧 SharedVerificationCodePool initialized.")
    }

    /// Consumes verification codes for a specific instance
    /// - Parameters:
    ///   - instanceId: Unique identifier for the WebKit instance
    ///   - since: The date since which to fetch codes
    /// - Returns: Array of verification codes for this instance
    public func consumeCodes(for instanceId: String, since: Date) async -> [String] {
        logger.info("🔄 SharedCodePool: Consuming codes for instance \(instanceId)")
        logger.info("🔄 SharedCodePool: Using since parameter: \(since)")
        logger
            .info(
                "🔄 SharedCodePool: Current pool status - Available: \(self.availableCodes.count), Consumed: \(self.consumedCodes.count)",
                )

        // Check if we need to refresh the code pool
        if shouldRefreshCodePool(since: since) {
            logger.info("🔄 SharedCodePool: Refreshing code pool for instance \(instanceId)")
            await refreshCodePool(since: since)
        }

        // Get all available codes (do not filter by consumed codes)
        let codesToReturn = availableCodes

        logger
            .info(
                "🔄 SharedCodePool: Returning \(codesToReturn.count) codes for instance \(instanceId): \(codesToReturn.map { String(repeating: "*", count: $0.count) })",
                )
        logger
            .info(
                "🔄 SharedCodePool: Available codes: \(self.availableCodes.map { String(repeating: "*", count: $0.count) })",
                )
        logger
            .info(
                "🔄 SharedCodePool: Consumed codes: \(Array(self.consumedCodes.keys).map { String(repeating: "*", count: $0.count) })",
                )
        return codesToReturn
    }

    /// Refreshes the code pool by fetching new codes from email
    /// - Parameter since: The date since which to fetch codes
    private func refreshCodePool(since: Date) async {
        logger.info("📧 SharedCodePool: Fetching fresh codes from email")
        logger.info("📧 SharedCodePool: Using since parameter: \(since)")

        // Use the existing email service to fetch codes
        let emailService = EmailService.shared
        let freshCodes = await emailService.fetchVerificationCodesForToday(since: since)

        // Update the code pool
        self.availableCodes = freshCodes
        self.lastFetchTime = Date()

        logger
            .info(
                "📧 SharedCodePool: Refreshed with \(freshCodes.count) codes: \(freshCodes.map { String(repeating: "*", count: $0.count) })",
                )
    }

    /// Determines if the code pool should be refreshed
    /// - Parameter since: The date since which codes should be fetched
    /// - Returns: True if the pool should be refreshed
    private func shouldRefreshCodePool(since _: Date) -> Bool {
        if availableCodes.isEmpty {
            logger.info("🔄 SharedCodePool: Refreshing - no codes available")
            return true
        }
        if let lastFetch = lastFetchTime {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            if timeSinceLastFetch > 15 {
                logger.info("🔄 SharedCodePool: Refreshing - \(timeSinceLastFetch) seconds since last fetch")
                return true
            }
        }
        return false
    }

    /// Clears consumed codes to free up memory
    public func clearConsumedCodes() {
        self.consumedCodes.removeAll()
        logger.info("🧹 SharedCodePool: Cleared consumed codes")
    }

    /// Gets current pool status for debugging
    public func getPoolStatus() -> (available: Int, consumed: Int) {
        let available = self.availableCodes.count
        let consumed = self.consumedCodes.count
        return (available: available, consumed: consumed)
    }

    /// Checks if a verification code has already been consumed by another instance
    /// - Parameters:
    ///   - code: The verification code to check
    ///   - currentInstanceId: The ID of the current instance
    /// - Returns: Always false (all windows can try all codes independently)
    public func isCodeConsumedByOtherInstance(_: String, currentInstanceId _: String) -> Bool {
        // With new logic, all windows can try all codes independently
        return false
    }

    /// Marks a verification code as consumed by a specific instance
    /// - Parameters:
    ///   - code: The verification code to mark as consumed
    ///   - instanceId: The ID of the instance that consumed the code
    public func markCodeAsConsumed(_ code: String, byInstanceId instanceId: String) {
        consumedCodes[code] = instanceId
        logger
            .info(
                "✅ SharedCodePool: Marked code \(String(repeating: "*", count: code.count)) as consumed by instance \(instanceId)",
                )
    }
}
