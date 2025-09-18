import Combine
import Foundation
import os

@MainActor
public final class ReservationStatusManager: ObservableObject, @unchecked Sendable {
  public static let shared = ReservationStatusManager()

  @Published public var isRunning = false

  @Published var lastRunDate: Date?
  @Published public var lastRunStatus: ReservationRunStatus = .idle
  @Published var currentTask = ""
  @Published private(set) var lastRunInfo: [UUID: LastRunInfo] = [:] {
    didSet { saveLastRunInfo() }
  }

  private let lastRunInfoKey = "ReservationManager.lastRunInfo"
  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem, category: "ReservationStatusManager")

  private init() {
    loadLastRunInfo()
  }

  private func saveLastRunInfo() {
    let codableDict = lastRunInfo.mapValues {
      LastRunInfoCodable(
        from: LastRunInfo(
          status: $0.status,
          date: $0.date,
          runType: $0.runType,
          screenshotPath: $0.screenshotPath,
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
    return LastRunInfo(
      status: tuple.status, date: tuple.date, runType: tuple.runType,
      screenshotPath: tuple.screenshotPath)
  }

  public func setLastRunInfo(
    for configId: UUID,
    status: ReservationRunStatus,
    date: Date?,
    runType: ReservationRunType,
    screenshotPath: String? = nil,
  ) {
    if let existing = lastRunInfo[configId] {
      // Prevent overwriting .success with .failed for the same runType and date (within 5 minutes window).
      if existing.status == .success, case .failed = status {
        let timeWindow: TimeInterval = AppConstants.timeWindowMinutes  // 5 minutes.
        if let existingDate = existing.date, let newDate = date,
          abs(existingDate.timeIntervalSince(newDate)) < timeWindow, existing.runType == runType
        {
          logger
            .warning(
              "⚠️ Attempted to overwrite .success with .failed for configId: \(configId). Ignoring late failure.",
            )
          return
        }
      }
    }
    lastRunInfo[configId] = LastRunInfo(
      status: status, date: date, runType: runType, screenshotPath: screenshotPath)
  }

  public struct LastRunInfo: Equatable, Codable, Sendable {
    public let status: ReservationRunStatus
    public let date: Date?
    public let runType: ReservationRunType
    public let screenshotPath: String?
  }

  struct LastRunInfoCodable: Codable {
    let status: ReservationRunStatus
    let date: Date?
    let runType: ReservationRunType
    let screenshotPath: String?
    init(from info: LastRunInfo) {
      self.status = info.status
      self.date = info.date
      self.runType = info.runType
      self.screenshotPath = info.screenshotPath
    }

    func toLastRunInfo() -> LastRunInfo {
      .init(status: status, date: date, runType: runType, screenshotPath: screenshotPath)
    }
  }
}
