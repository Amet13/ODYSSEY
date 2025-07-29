import Foundation

protocol ServiceProtocol {
    func initialize() async throws
    func cleanup() async throws
    func isReady() -> Bool
}

protocol ObservableServiceProtocol: ServiceProtocol, ObservableObject {
    var isInitialized: Bool { get }
    var error: Error? { get }
}
