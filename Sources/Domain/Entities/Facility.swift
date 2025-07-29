import Foundation

struct Facility: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let address: String
    let sports: [Sport]
    let url: String
    let isActive: Bool

    init(id: String, name: String, address: String, sports: [Sport], url: String, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.address = address
        self.sports = sports
        self.url = url
        self.isActive = isActive
    }
}

struct Sport: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let icon: String
    let isAvailable: Bool

    init(id: String, name: String, icon: String, isAvailable: Bool = true) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isAvailable = isAvailable
    }
}
