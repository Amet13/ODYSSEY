import Foundation

@MainActor
protocol RepositoryProtocol {
    associatedtype Entity

    func save(_ entity: Entity) async throws
    func fetch(_ id: String) async throws -> Entity?
    func fetchAll() async throws -> [Entity]
    func delete(_ id: String) async throws
    func deleteAll() async throws
}

@MainActor
protocol AsyncRepositoryProtocol {
    associatedtype Entity

    func save(_ entity: Entity) async throws
    func fetch(_ id: String) async throws -> Entity?
    func fetchAll() async throws -> [Entity]
    func delete(_ id: String) async throws
    func deleteAll() async throws
}
