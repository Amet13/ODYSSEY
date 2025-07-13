import Combine
import Foundation
import os.log

/// Manages the automation of reservation bookings for Ottawa recreation facilities
///
/// This class handles the complete web automation process including:
/// - Web navigation to facility websites
/// - Form automation and data entry
/// - Slot selection and booking
/// - Error handling and logging
/// - Status tracking and user feedback
///
/// The manager uses WebDriver for Chrome automation and provides real-time status updates
/// through ObservableObject protocol for SwiftUI integration.
class ReservationManager: NSObject, ObservableObject {
    static let shared = ReservationManager()

    @Published var isRunning = false
    @Published var lastRunDate: Date?
    @Published var lastRunStatus: RunStatus = .idle
    @Published var currentTask: String = ""

    // Per-configuration last run status, date, and run type
    struct LastRunInfo: Codable {
        let status: RunStatusCodable
        let date: Date?
        let runType: RunType
    }

    enum RunStatusCodable: String, Codable {
        case idle, running, success, failed
        var toRunStatus: RunStatus {
            switch self {
            case .idle: .idle
            case .running: .running
            case .success: .success
            case .failed: .failed("") // error string not persisted
            }
        }

        static func from(_ status: RunStatus) -> RunStatusCodable {
            switch status {
            case .idle: .idle
            case .running: .running
            case .success: .success
            case .failed: .failed
            }
        }
    }

    @Published private(set) var lastRunInfo: [UUID: (status: RunStatus, date: Date?, runType: RunType)] = [:] {
        didSet { saveLastRunInfo() }
    }

    private let lastRunInfoKey = "ReservationManager.lastRunInfo"

    private var cancellables = Set<AnyCancellable>()
    private let configurationManager = ConfigurationManager.shared
    private let webDriverService = WebDriverService.shared
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ReservationManager")
    private var currentConfig: ReservationConfig?

    enum RunStatus: Equatable {
        case idle
        case running
        case success
        case failed(String)

        var description: String {
            switch self {
            case .idle: "Idle"
            case .running: "Running"
            case .success: "Success"
            case let .failed(error): "Failed: \(error)"
            }
        }

        static func == (lhs: RunStatus, rhs: RunStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle):
                return true
            case (.running, .running):
                return true
            case (.success, .success):
                return true
            case let (.failed(lhsError), .failed(rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }

    enum RunType: Codable {
        case manual
        case automatic

        var description: String {
            switch self {
            case .manual: "(manual)"
            case .automatic: "(auto)"
            }
        }
    }

    enum ReservationError: Error, LocalizedError {
        case webDriverNotInitialized
        case navigationFailed
        case sportButtonNotFound
        case pageLoadTimeout

        var errorDescription: String? {
            switch self {
            case .webDriverNotInitialized:
                UserSettingsManager.shared.userSettings.localized("WebDriver not initialized")
            case .navigationFailed:
                UserSettingsManager.shared.userSettings.localized("Failed to navigate to reservation page")
            case .sportButtonNotFound:
                UserSettingsManager.shared.userSettings.localized("Sport button not found on page")
            case .pageLoadTimeout:
                UserSettingsManager.shared.userSettings.localized("Page failed to load completely within timeout")
            }
        }
    }

    override private init() {
        super.init()
        _ = webDriverService // Force access to trigger WebDriverService init
        loadLastRunInfo()
    }

    private func saveLastRunInfo() {
        let codableDict = lastRunInfo.mapValues { status, date, runType in
            LastRunInfo(status: RunStatusCodable.from(status), date: date, runType: runType)
        }
        if let data = try? JSONEncoder().encode(codableDict) {
            UserDefaults.standard.set(data, forKey: lastRunInfoKey)
        }
    }

    private func loadLastRunInfo() {
        guard let data = UserDefaults.standard.data(forKey: lastRunInfoKey)
        else { return }
        if let codableDict = try? JSONDecoder().decode([UUID: LastRunInfo].self, from: data) {
            lastRunInfo = codableDict.mapValues { info in
                (info.status.toRunStatus, info.date, info.runType)
            }
        }
    }

    // MARK: - Public Methods

    /// Runs reservation automation for a specific configuration
    /// - Parameters:
    ///   - config: The reservation configuration to execute
    ///   - runType: Whether this is a manual or automatic run
    func runReservation(for config: ReservationConfig, runType: RunType = .manual) {
        guard !isRunning else {
            logger.warning("Reservation already running, skipping")
            return
        }

        isRunning = true
        lastRunStatus = .running
        currentTask = "Starting reservation for \(config.name)"
        currentConfig = config

        // Start automation in background task
        Task {
            await performReservation(for: config, runType: runType)
        }
    }

    /// Stops all running reservation processes
    func stopAllReservations() {
        isRunning = false
        lastRunStatus = .idle
        currentTask = ""

        // Stop WebDriver session
        Task {
            await webDriverService.stopSession()
        }
    }

    // MARK: - Private Methods

    private func performReservation(for config: ReservationConfig, runType: RunType) async {
        do {
            // Step 1: Start WebDriver session and navigate directly to the URL
            await updateTask("Starting WebDriver session")
            guard await webDriverService.startSession() else {
                await handleError(
                    UserSettingsManager.shared.userSettings.localized("Failed to start WebDriver session"),
                    configId: config.id,
                    runType: runType,
                )
                return
            }

            // Step 2: Navigate to facility URL
            await updateTask("Navigating to facility")
            let navigationResult = await webDriverService.navigate(to: config.facilityURL)
            guard navigationResult else {
                await handleError(
                    UserSettingsManager.shared.userSettings.localized("Failed to navigate to facility"),
                    configId: config.id,
                    runType: runType,
                )
                return
            }

            // Step 2.5: Inject anti-detection script immediately after navigation
            await webDriverService.injectAntiDetectionScript(
                userAgent: webDriverService.currentUserAgent,
                language: webDriverService.currentLanguage,
            )

            // Step 2.6: Simulate random scrolling and mouse movement
            if Bool.random() { await webDriverService.simulateScrolling() }
            if Bool.random() { await webDriverService.moveMouseRandomly() }

            // Step 3: Wait for page to load
            await updateTask("Waiting for page to load")

            // Wait for DOM to be fully ready with sport buttons
            let domReady = await webDriverService.waitForDOMReady()
            if !domReady {
                logger.error("DOM failed to load properly within timeout")
                throw ReservationError.pageLoadTimeout
            }

            logger.info("Page loaded successfully")

            // Step 4: Find and click sport button
            await updateTask("Looking for sport: \(config.sportName)")
            logger.info("Searching for sport button with text: '\(config.sportName)'")
            // Simulate human-like mouse movement and delay before interaction
            await webDriverService.simulateMouseMovement(to: config.sportName)
            await webDriverService.addRandomDelay()
            if Bool.random() { await webDriverService.simulateScrolling() }
            if Bool.random() { await webDriverService.moveMouseRandomly() }

            let buttonClicked = await webDriverService.findAndClickElement(withText: config.sportName)
            if buttonClicked {
                logger.info("Successfully clicked sport button: \(config.sportName)")

                // Step 5: Success - wait a moment and close browser tab
                await updateTask("Success! Closing browser tab...")
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                // Close only the current browser tab, not the entire session
                await webDriverService.stopSession()

                // Update status to success
                await MainActor.run {
                    self.isRunning = false
                    self.lastRunStatus = .success
                    self.lastRunInfo[config.id] = (.success, Date(), runType)
                    self.lastRunDate = Date()
                    self.currentTask = UserSettingsManager.shared.userSettings
                        .localized("Reservation completed successfully")
                }
                logger.info("Reservation completed successfully for \(config.sportName)")

                // Send notifications if configured
                if UserSettingsManager.shared.userSettings.hasEmailConfigured {
                    await EmailService.shared.sendSuccessNotification(for: config)
                }

                if UserSettingsManager.shared.userSettings.hasTelegramConfigured {
                    await TelegramService.shared.sendSuccessNotification(for: config)
                }

                return
            } else {
                logger.error("Failed to click sport button: \(config.sportName)")
                await MainActor.run {
                    self.lastRunInfo[config.id] = (
                        .failed(UserSettingsManager.shared.userSettings.localized("Sport button not found on page")),
                        Date(),
                        runType,
                    )
                }
                throw ReservationError.sportButtonNotFound
            }

        } catch {
            await handleError(
                UserSettingsManager.shared.userSettings
                    .localized("Automation error:") + " \(error.localizedDescription)",
                configId: config.id,
                runType: runType,
            )
        }
    }

    private func updateTask(_ task: String) async {
        await MainActor.run {
            currentTask = task
        }
    }

    private func handleError(_ error: String, configId: UUID?, runType: RunType = .manual) async {
        await MainActor.run {
            self.isRunning = false
            self.lastRunStatus = .failed(error)
            self.currentTask = "Error: \(error)"
            self.lastRunDate = Date()
            if let configId {
                self.lastRunInfo[configId] = (.failed(error), Date(), runType)
            }
        }
        logger.error("Reservation error: \(error)")
    }

    // Helper to get last run info for a config
    func getLastRunInfo(for configId: UUID) -> (status: RunStatus, date: Date?, runType: RunType)? {
        lastRunInfo[configId]
    }
}
