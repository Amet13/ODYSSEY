import Foundation
import os.log

@MainActor
public final class ReservationErrorHandler: @unchecked Sendable {
    public static let shared = ReservationErrorHandler()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ReservationErrorHandler")
    private let statusManager = ReservationStatusManager.shared
    private let webKitService = WebKitService.shared

    public func handleReservationError(
        _ error: Error,
        config: ReservationConfig,
        runType: ReservationRunType,
        ) async {
        logger.error("❌ Reservation error: \(error.localizedDescription).")

        if let webKitService = try? await getWebKitServiceIfAvailable() {
            if let pageSource = try? await webKitService.getPageSource() {
                logger.error("📄 DOM Snapshot (first 1000 chars): \(pageSource.prefix(1_000))")
            } else {
                logger.error("⚠️ Failed to capture DOM snapshot for error context.")
            }
        }
        await MainActor.run {
            // Only set isRunning = false for single reservations (manual runs)
            // For multiple reservations (godmode/automatic), let trackGodModeCompletion handle it
            if runType == .manual { statusManager.isRunning = false }
            statusManager.lastRunStatus = ReservationRunStatus.failed(error.localizedDescription)
            statusManager.setLastRunInfo(
                for: config.id,
                status: .failed(error.localizedDescription),
                date: Date(),
                runType: runType,
                )
            statusManager.lastRunDate = Date()
            statusManager.currentTask = "Reservation failed: \(error.localizedDescription)"
            // Show user-facing error banner
            logger.error("❌ Reservation failed: \(error.localizedDescription)")
        }
        logger.error("❌ Reservation failed for \(config.name): \(error.localizedDescription).")
        logger.info("🧹 Cleaning up WebKit session after error.")
        let shouldClose = UserSettingsManager.shared.userSettings.autoCloseDebugWindowOnFailure
        await webKitService.disconnect(closeWindow: shouldClose)
    }

    public func handleError(_ error: String, configId: UUID?, runType: ReservationRunType = .manual) async {
        await MainActor.run {
            // Only set isRunning = false for single reservations (manual runs)
            // For multiple reservations (godmode/automatic), let trackGodModeCompletion handle it
            if runType == .manual { statusManager.isRunning = false }
            statusManager.lastRunStatus = ReservationRunStatus.failed(error)
            statusManager.currentTask = "Error: \(error)"
            statusManager.lastRunDate = Date()
            if let configId {
                statusManager.setLastRunInfo(for: configId, status: .failed(error), date: Date(), runType: runType)
            }
        }
        logger.error("❌ Reservation error: \(error).")
    }

    public func handleWebKitCrash() async {
        logger.error("💥 WebKit crash detected, attempting recovery.")
        await webKitService.reset()
        logger.info("✅ WebKit service reset successful.")
    }

    /// Helper to get WebKitService if available and connected
    private func getWebKitServiceIfAvailable() async throws -> WebKitService? {
        let service = WebKitService.shared
        if service.isConnected, service.webView != nil {
            return service
        }
        return nil
    }
}
