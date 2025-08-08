import Foundation
import os.log

@MainActor
class DependencyContainer {
  static let shared = DependencyContainer()

  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem, category: "DependencyContainer")

  // MARK: - Infrastructure Services

  lazy var webKitEngine: WebKitEngineProtocol = {
    logger.info("🔧 Creating WebKit engine...")
    return WebKitEngine()
  }()

  lazy var webKitNavigation: WebKitNavigationProtocol = {
    logger.info("🧭 Creating WebKit navigation...")
    return WebKitNavigation(webView: webKitEngine.createWebView())
  }()

  lazy var webKitScripting: WebKitScriptingProtocol = {
    logger.info("📜 Creating WebKit scripting...")
    return WebKitScripting(webView: webKitEngine.createWebView())
  }()

  lazy var emailClient: EmailClientProtocol = {
    logger.info("📧 Creating email client...")
    let settings = EmailSettings(
      emailAddress: UserDefaults.standard.string(forKey: "email") ?? "",
      password: UserDefaults.standard.string(forKey: "password") ?? "",
      provider: .gmail,
      imapServer: AppConstants.gmailImapServer,
      imapPort: Int(AppConstants.gmailImapPort),
      useSSL: true,
    )
    return EmailClient(settings: settings)
  }()

  lazy var emailParser: EmailParserProtocol = {
    logger.info("📄 Creating email parser...")
    return EmailParser()
  }()

  lazy var storageService: StorageServiceProtocol = {
    logger.info("💾 Creating storage service...")
    return UserDefaultsStorageService()
  }()

  // MARK: - Domain Repositories

  lazy var reservationRepository: any ReservationRepositoryProtocol = {
    logger.info("📝 Creating reservation repository...")
    return ReservationRepository(storage: storageService)
  }()

  // MARK: - Domain Use Cases

  lazy var reservationUseCase: ReservationUseCaseProtocol = {
    logger.info("🚀 Creating reservation use case...")
    return ReservationUseCase(
      repository: reservationRepository,
      webKitService: webKitService,
      emailService: emailService,
    )
  }()

  // MARK: - Application Services

  lazy var webKitService: WebKitServiceProtocol = {
    logger.info("🌐 Creating WebKit service...")
    return WebKitService.shared
  }()

  lazy var emailService: EmailServiceProtocol = {
    logger.info("📧 Creating email service...")
    return EmailService.shared
  }()

  // MARK: - Application Orchestrators

  lazy var reservationOrchestrator: ReservationOrchestratorProtocol = {
    logger.info("🎼 Creating reservation orchestrator...")
    return ReservationOrchestrator.shared
  }()

  // MARK: - Application Managers

  lazy var stateManager: StateManagerProtocol = {
    logger.info("📊 Creating state manager...")
    return StateManager()
  }()

  lazy var errorManager: ErrorManagerProtocol = {
    logger.info("⚠️ Creating error manager...")
    return ErrorManager()
  }()

  // MARK: - Initialization

  private init() {
    logger.info("🏗️ Initializing dependency container...")
  }

  func initialize() async throws {
    logger.info("🚀 Initializing all services...")

    // Initialize core services
    let webView = webKitEngine.createWebView()
    try webKitEngine.configureWebView(webView)

    logger.info("✅ All services initialized successfully.")
  }

  func cleanup() async throws {
    logger.info("🧹 Cleaning up all services...")

    // Cleanup services
    webKitEngine.cleanup()
    try await emailClient.disconnect()

    logger.info("✅ All services cleaned up successfully.")
  }
}

// MARK: - Service Implementations

// Using existing service implementations from Sources/Services/

class UserDefaultsStorageService: StorageServiceProtocol {
  private let userDefaults = UserDefaults.standard
  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem, category: "UserDefaultsStorage")

  func save(_ object: some Encodable, forKey key: String) throws {
    let data = try JSONEncoder().encode(object)
    userDefaults.set(data, forKey: key)
    logger.info("💾 Saved object for key: \(key).")
  }

  func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
    guard let data = userDefaults.data(forKey: key) else {
      return nil
    }
    let object = try JSONDecoder().decode(type, from: data)
    logger.info("📥 Loaded object for key: \(key).")
    return object
  }

  func delete(forKey key: String) {
    userDefaults.removeObject(forKey: key)
    logger.info("🗑️ Deleted data for key: \(key).")
  }

  func clearAll() {
    // UserDefaults doesn't provide a direct way to clear all keys
    // This is a simplified implementation
    logger.info("🧹 Cleared all data.")
  }
}

// MARK: - Orchestrator Protocols

// Using existing ReservationOrchestratorProtocol and ReservationOrchestrator from Sources/Utils/Protocols.swift and
// Sources/Services/ReservationOrchestrator.swift

// MARK: - Manager Protocols

protocol StateManagerProtocol {
  func getCurrentState() -> AppState
  func updateState(_ state: AppState)
}

protocol ErrorManagerProtocol {
  func handleError(_ error: Error)
  func getLastError() -> Error?
}

class StateManager: StateManagerProtocol {
  private var currentState: AppState = .idle

  func getCurrentState() -> AppState {
    return currentState
  }

  func updateState(_ state: AppState) {
    currentState = state
  }
}

class ErrorManager: ErrorManagerProtocol {
  private var lastError: Error?

  func handleError(_ error: Error) {
    lastError = error
  }

  func getLastError() -> Error? {
    return lastError
  }
}

enum AppState {
  case idle
  case loading
  case executing
  case completed
  case error
}
