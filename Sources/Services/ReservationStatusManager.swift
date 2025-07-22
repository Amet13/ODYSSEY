import Combine
import Foundation
import os.log

@MainActor
public final class ReservationStatusManager: ObservableObject, @unchecked Sendable {
    public static let shared = ReservationStatusManager()

    @Published public var isRunning = false {
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
    @Published public var lastRunStatus: ReservationRunStatus = .idle
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

    public func getLastRunInfo(for configId: UUID) -> LastRunInfo? {
        guard let tuple = lastRunInfo[configId] else { return nil }
        return LastRunInfo(status: tuple.status, date: tuple.date, runType: tuple.runType)
    }

    public func setLastRunInfo(
        for configId: UUID,
        status: ReservationRunStatus,
        date: Date?,
        runType: ReservationRunType,
        ) {
        lastRunInfo[configId] = LastRunInfo(status: status, date: date, runType: runType)
    }

    public struct LastRunInfo: Equatable, Codable {
        public let status: ReservationRunStatus
        public let date: Date?
        public let runType: ReservationRunType
    }

    struct LastRunInfoCodable: Codable {
        let status: ReservationRunStatus
        let date: Date?
        let runType: ReservationRunType
        init(from info: LastRunInfo) {
            self.status = info.status
            self.date = info.date
            self.runType = info.runType
        }

        func toLastRunInfo() -> LastRunInfo {
            .init(status: status, date: date, runType: runType)
        }
    }
}
