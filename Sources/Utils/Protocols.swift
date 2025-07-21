import Combine
import Foundation
import os.log
import WebKit

// MARK: - Web Automation Protocol

// Note: WebAutomationServiceProtocol is already defined in WebDriverProtocols.swift

// MARK: - Email Service Protocol

/// Protocol defining the interface for email services
protocol EmailServiceProtocol: AnyObject {
    func testConnection(email: String, password: String, server: String) async -> EmailService.TestResult
    func extractVerificationCode() async -> String?
    func fetchVerificationCodesForToday(since: Date) async -> [String]
    func sendSuccessNotification(for config: ReservationConfig) async
}

// MARK: - Configuration Management Protocol

/// Protocol defining the interface for configuration management
protocol ConfigurationManagerProtocol: AnyObject {
    var configurations: [ReservationConfig] { get }

    func addConfiguration(_ config: ReservationConfig)
    func updateConfiguration(_ config: ReservationConfig)
    func deleteConfiguration(with id: UUID)
    func saveConfigurations()
    func loadConfigurations()
}

// MARK: - User Settings Management Protocol

/// Protocol defining the interface for user settings management
protocol UserSettingsManagerProtocol: AnyObject {
    var userSettings: UserSettings { get }

    func updateSettings(_ settings: UserSettings)
    func saveSettings()
    func loadSettings()
    func validateSettings() -> Bool
}

// MARK: - Reservation Management Protocol

/// Protocol defining the interface for reservation management
protocol ReservationOrchestratorProtocol: AnyObject {
    var lastRunStatus: ReservationOrchestrator.RunStatus { get }
    func runReservation(for config: ReservationConfig, type: ReservationOrchestrator.RunType) async
    func stopReservation() async
    func emergencyCleanup(runType: ReservationOrchestrator.RunType) async
}

// MARK: - Facility Service Protocol

/// Protocol defining the interface for facility services
protocol FacilityServiceProtocol: AnyObject {
    var isLoading: Bool { get }
    var availableSports: [String] { get }
    var error: String? { get }

    func fetchAvailableSports(from url: String, completion: @escaping ([String]) -> Void)
}

// MARK: - Status Bar Controller Protocol

/// Protocol defining the interface for status bar controllers
protocol StatusBarControllerProtocol: AnyObject {
    func showPopover()
    func hidePopover()
    func updateStatus(_ status: String)
    func showError(_ error: String)
}

// MARK: - Logging Protocol

/// Protocol defining the interface for logging services
protocol LoggingServiceProtocol {
    func info(_ message: String)
    func error(_ message: String)
    func warning(_ message: String)
    func debug(_ message: String)
}

// MARK: - Validation Protocol

/// Protocol defining the interface for validation services
protocol ValidationServiceProtocol {
    func validateEmail(_ email: String) -> Bool
    func validatePhoneNumber(_ phone: String) -> Bool
    func validateGmailAppPassword(_ password: String) -> Bool
    func validateFacilityURL(_ url: String) -> Bool
}

// MARK: - Storage Protocol

/// Protocol defining the interface for data storage services
protocol StorageServiceProtocol {
    func save(_ object: some Encodable, forKey key: String) throws
    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T?
    func delete(forKey key: String)
    func clearAll()
}

// MARK: - Network Service Protocol

/// Protocol defining the interface for network services
protocol NetworkServiceProtocol {
    func makeRequest(to url: URL, method: String, headers: [String: String]?) async throws -> Data
    func testConnection(to host: String, port: UInt16) async -> Bool
}

// MARK: - Timer Service Protocol

/// Protocol defining the interface for timer services
protocol TimerServiceProtocol {
    func scheduleTimer(interval: TimeInterval, repeats: Bool, block: @escaping () -> Void) -> Timer
    func invalidateTimer(_ timer: Timer)
    func scheduleRepeatingTask(interval: TimeInterval, task: @escaping () async -> Void)
}

// MARK: - Error Handling Protocol

/// Protocol defining the interface for error handling services
protocol ErrorHandlingServiceProtocol {
    func handleError(_ error: Error, context: String)
    func logError(_ error: Error, withMessage message: String)
    func showUserFriendlyError(_ error: Error)
}

// MARK: - Performance Monitoring Protocol

/// Protocol defining the interface for performance monitoring
protocol PerformanceMonitoringProtocol {
    func startTimer(for operation: String)
    func endTimer(for operation: String) -> TimeInterval
    func logPerformance(operation: String, duration: TimeInterval)
    func getAverageTime(for operation: String) -> TimeInterval?
}
