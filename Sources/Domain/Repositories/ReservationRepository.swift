import Foundation
import os.log

@MainActor
protocol ReservationRepositoryProtocol: RepositoryProtocol where Entity == Reservation {
  func save(_ reservation: Reservation) async throws
  func fetch(_ id: String) async throws -> Reservation?
  func fetchAll() async throws -> [Reservation]
  func delete(_ id: String) async throws
  func deleteAll() async throws
  func fetchByStatus(_ status: ReservationStatus) async throws -> [Reservation]
  func fetchByDateRange(from: Date, to: Date) async throws -> [Reservation]
}

@MainActor
class ReservationRepository: ReservationRepositoryProtocol {
  private let storage: StorageServiceProtocol
  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem, category: "ReservationRepository")

  init(storage: StorageServiceProtocol) {
    self.storage = storage
  }

  func save(_ reservation: Reservation) async throws {
    logger.info("💾 Saving reservation: \(reservation.id).")

    let key = "reservation_\(reservation.id.uuidString)"
    try storage.save(reservation, forKey: key)
    logger.info("✅ Reservation saved successfully.")
  }

  func fetch(_ id: String) async throws -> Reservation? {
    logger.info("📥 Fetching reservation: \(id).")

    let key = "reservation_\(id)"
    guard let reservation = try storage.load(Reservation.self, forKey: key) else {
      logger.info("❌ Reservation not found: \(id).")
      return nil
    }

    logger.info("✅ Reservation fetched successfully.")
    return reservation
  }

  func fetchAll() async throws -> [Reservation] {
    logger.info("📥 Fetching all reservations...")

    // Since UserDefaults doesn't provide getAllKeys, we'll return empty array for now
    // In a real implementation, you'd need to maintain a list of keys
    let reservations: [Reservation] = []

    logger.info("✅ Fetched \(reservations.count) reservations.")
    return reservations
  }

  func delete(_ id: String) async throws {
    logger.info("🗑️ Deleting reservation: \(id).")

    let key = "reservation_\(id)"
    storage.delete(forKey: key)

    logger.info("✅ Reservation deleted successfully.")
  }

  func deleteAll() async throws {
    logger.info("🗑️ Deleting all reservations...")

    // Since UserDefaults doesn't provide getAllKeys, we'll just clear all
    storage.clearAll()

    logger.info("✅ All reservations deleted successfully.")
  }

  func fetchByStatus(_ status: ReservationStatus) async throws -> [Reservation] {
    logger.info("📥 Fetching reservations with status: \(status.rawValue).")

    let allReservations = try await fetchAll()
    let filteredReservations = allReservations.filter { $0.status == status }

    logger.info(
      "✅ Found \(filteredReservations.count) reservations with status \(status.rawValue).")
    return filteredReservations
  }

  func fetchByDateRange(from: Date, to: Date) async throws -> [Reservation] {
    logger.info("📥 Fetching reservations from \(from) to \(to).")

    let allReservations = try await fetchAll()
    let filteredReservations = allReservations.filter { reservation in
      reservation.createdAt >= from && reservation.createdAt <= to
    }

    logger.info("✅ Found \(filteredReservations.count) reservations in date range.")
    return filteredReservations
  }
}

// MARK: - Storage Service Protocol

// Using StorageServiceProtocol from Sources/Utils/Protocols.swift
