import Foundation

// MARK: - Reservation Run Types and Status

/// Defines the different types of reservation runs.
public enum ReservationRunType: String, Codable, CaseIterable, Sendable {
  case manual
  case automatic
  case godmode

  public var displayName: String {
    switch self {
    case .manual: return "Manual"
    case .automatic: return "Automatic"
    case .godmode: return "God Mode"
    }
  }
}

/// Defines the status of a reservation run.
public enum ReservationRunStatus: Error, Codable, LocalizedError, Equatable {
  case idle
  case running
  case success
  case failed(String)
  case stopped

  public var description: String {
    switch self {
    case .idle: return "Idle"
    case .running: return "Running"
    case .success: return "Successful"
    case let .failed(error): return "Failed: \(error)"
    case .stopped: return "Stopped"
    }
  }

  public var errorDescription: String? {
    switch self {
    case let .failed(error): return error
    default: return nil
    }
  }

  // Codable conformance
  enum CodingKeys: String, CodingKey {
    case idle, running, success, failed, stopped
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    if container.contains(.idle) {
      self = .idle
    } else if container.contains(.running) {
      self = .running
    } else if container.contains(.success) {
      self = .success
    } else if container.contains(.failed) {
      let error = try container.decode(String.self, forKey: .failed)
      self = .failed(error)
    } else if container.contains(.stopped) {
      self = .stopped
    } else {
      throw DecodingError.dataCorrupted(
        .init(
          codingPath: decoder.codingPath,
          debugDescription: "Invalid ReservationRunStatus",
        ))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .idle: try container.encode(true, forKey: .idle)
    case .running: try container.encode(true, forKey: .running)
    case .success: try container.encode(true, forKey: .success)
    case let .failed(error): try container.encode(error, forKey: .failed)
    case .stopped: try container.encode(true, forKey: .stopped)
    }
  }

  // Equatable conformance
  public static func == (lhs: ReservationRunStatus, rhs: ReservationRunStatus) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle): return true
    case (.running, .running): return true
    case (.success, .success): return true
    case let (.failed(lhsError), .failed(rhsError)): return lhsError == rhsError
    case (.stopped, .stopped): return true
    default: return false
    }
  }
}

/// Information about the last run of a reservation.
public struct LastRunInfo: Codable, Equatable {
  public let status: ReservationRunStatus
  public let date: Date
  public let runType: ReservationRunType

  public init(status: ReservationRunStatus, date: Date, runType: ReservationRunType) {
    self.status = status
    self.date = date
    self.runType = runType
  }
}

/// Status information for a reservation run.
public struct ReservationRunStatusInfo: Codable {
  public let isRunning: Bool
  public let lastRunStatus: ReservationRunStatus
  public let lastRunInfo: [String: LastRunInfo]

  public init(
    isRunning: Bool, lastRunStatus: ReservationRunStatus, lastRunInfo: [String: LastRunInfo]
  ) {
    self.isRunning = isRunning
    self.lastRunStatus = lastRunStatus
    self.lastRunInfo = lastRunInfo
  }
}
