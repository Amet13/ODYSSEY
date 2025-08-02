import Foundation

struct Reservation: Identifiable, Codable, Sendable {
  let id: UUID
  let configuration: ReservationConfig
  let status: ReservationStatus
  let createdAt: Date
  let updatedAt: Date
  let result: ReservationResult?

  init(configuration: ReservationConfig, status: ReservationStatus = .pending) {
    self.id = UUID()
    self.configuration = configuration
    self.status = status
    self.createdAt = Date()
    self.updatedAt = Date()
    self.result = nil
  }

  init(
    id: UUID,
    configuration: ReservationConfig,
    status: ReservationStatus,
    createdAt: Date,
    updatedAt: Date,
    result: ReservationResult?
  ) {
    self.id = id
    self.configuration = configuration
    self.status = status
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.result = result
  }
}

enum ReservationStatus: String, Codable, CaseIterable {
  case pending
  case inProgress = "in_progress"
  case completed
  case failed
  case cancelled

  var displayName: String {
    switch self {
    case .pending: return "Pending"
    case .inProgress: return "In Progress"
    case .completed: return "Completed"
    case .failed: return "Failed"
    case .cancelled: return "Cancelled"
    }
  }

  var isFinal: Bool {
    switch self {
    case .completed, .failed, .cancelled:
      return true
    case .pending, .inProgress:
      return false
    }
  }
}

struct ReservationResult: Codable, Sendable {
  let success: Bool
  let message: String
  let details: [String: String]
  let timestamp: Date

  init(success: Bool, message: String, details: [String: String] = [:]) {
    self.success = success
    self.message = message
    self.details = details
    self.timestamp = Date()
  }
}
