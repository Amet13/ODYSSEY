import Foundation

struct User: Identifiable, Codable, Sendable {
  let id: UUID
  let email: String
  let settings: UserSettings
  let createdAt: Date
  let updatedAt: Date

  init(email: String, settings: UserSettings) {
    self.id = UUID()
    self.email = email
    self.settings = settings
    self.createdAt = Date()
    self.updatedAt = Date()
  }

  init(id: UUID, email: String, settings: UserSettings, createdAt: Date, updatedAt: Date) {
    self.id = id
    self.email = email
    self.settings = settings
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
