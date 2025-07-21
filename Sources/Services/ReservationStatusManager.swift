import Combine
import Foundation
import os.log

@MainActor
class ReservationStatusManager: ObservableObject {
    static let shared = ReservationStatusManager()

    @Published var isRunning = false {
        didSet {
            if isRunning == false {
                logger
                    .info(
                        "⏹️ isRunning set to false. Tray icon should revert to idle. Call stack: \(Thread.callStackSymbols.joined(separator: "\n"))",
                        )
            }
        }
    }

    @Published var lastRunDate: Date?
    @Published var lastRunStatus: ReservationOrchestrator.RunStatus = .idle
    @Published var currentTask: String = ""
    @Published private(set) var lastRunInfo: [UUID: LastRunInfo] = [:] {
        didSet { saveLastRunInfo() }
    }

    private let lastRunInfoKey = "ReservationManager.lastRunInfo"
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ReservationStatusManager")

    private init() {
        loadLastRunInfo()
    }

    private func saveLastRunInfo() {
        let codableDict = lastRunInfo.mapValues { LastRunInfoCodable(from: LastRunInfo(
            status: $0.status,
            date: $0.date,
            runType: $0.runType,
            ))
        }
        if let data = try? JSONEncoder().encode(codableDict) {
            UserDefaults.standard.set(data, forKey: lastRunInfoKey)
        }
    }

    private func loadLastRunInfo() {
        guard let data = UserDefaults.standard.data(forKey: lastRunInfoKey) else { return }
        if let codableDict = try? JSONDecoder().decode([UUID: LastRunInfoCodable].self, from: data) {
            lastRunInfo = codableDict.mapValues { $0.toLastRunInfo() }
        }
    }

    func getLastRunInfo(for configId: UUID) -> LastRunInfo? {
        guard let tuple = lastRunInfo[configId] else { return nil }
        return LastRunInfo(status: tuple.status, date: tuple.date, runType: tuple.runType)
    }

    func setLastRunInfo(
        for configId: UUID,
        status: ReservationOrchestrator.RunStatus,
        date: Date?,
        runType: ReservationOrchestrator.RunType,
        ) {
        lastRunInfo[configId] = LastRunInfo(status: status, date: date, runType: runType)
    }

    struct LastRunInfo: Equatable {
        let status: ReservationOrchestrator.RunStatus
        let date: Date?
        let runType: ReservationOrchestrator.RunType
    }

    struct LastRunInfoCodable: Codable {
        let status: ReservationOrchestrator.RunStatusCodable
        let date: Date?
        let runType: ReservationOrchestrator.RunType
        init(from info: LastRunInfo) {
            self.status = ReservationOrchestrator.RunStatusCodable.from(info.status)
            self.date = info.date
            self.runType = info.runType
        }

        func toLastRunInfo() -> LastRunInfo {
            .init(status: status.toRunStatus, date: date, runType: runType)
        }
    }
}
