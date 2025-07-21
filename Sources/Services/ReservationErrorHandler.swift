import Foundation
import os.log

@MainActor
class ReservationErrorHandler {
    static let shared = ReservationErrorHandler()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ReservationErrorHandler")
    private let statusManager = ReservationStatusManager.shared
    private let webKitService = WebKitService.shared

    func handleReservationError(
        _ error: Error,
        config: ReservationConfig,
        runType: ReservationOrchestrator.RunType,
        ) async {
        logger.error("❌ Reservation error: \(error.localizedDescription).")
        await MainActor.run {
            if runType != .godmode { statusManager.isRunning = false }
            statusManager.lastRunStatus = .failed(error.localizedDescription)
            statusManager.setLastRunInfo(
                for: config.id,
                status: .failed(error.localizedDescription),
                date: Date(),
                runType: runType,
                )
            statusManager.lastRunDate = Date()
            statusManager.currentTask = "Reservation failed: \(error.localizedDescription)"
        }
        logger.error("❌ Reservation failed for \(config.name): \(error.localizedDescription).")
        logger.info("🧹 Cleaning up WebKit session after error.")
        await webKitService.disconnect(closeWindow: false)
    }

    func handleError(_ error: String, configId: UUID?, runType: ReservationOrchestrator.RunType = .manual) async {
        await MainActor.run {
            if runType != .godmode { statusManager.isRunning = false }
            statusManager.lastRunStatus = .failed(error)
            statusManager.currentTask = "Error: \(error)"
            statusManager.lastRunDate = Date()
            if let configId {
                statusManager.setLastRunInfo(for: configId, status: .failed(error), date: Date(), runType: runType)
            }
        }
        logger.error("❌ Reservation error: \(error).")
    }

    func handleWebKitCrash() async {
        logger.error("💥 WebKit crash detected, attempting recovery.")
        await webKitService.reset()
        logger.info("✅ WebKit service reset successful.")
    }
}
