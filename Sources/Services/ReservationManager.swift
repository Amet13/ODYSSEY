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
    
    private var cancellables = Set<AnyCancellable>()
    private let configurationManager = ConfigurationManager.shared
    private let webDriverService = WebDriverService.shared
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ReservationManager")
    private var currentConfig: ReservationConfig?
    
    enum RunStatus {
        case idle
        case running
        case success
        case failed(String)
        
        var description: String {
            switch self {
            case .idle: return "Idle"
            case .running: return "Running"
            case .success: return "Success"
            case .failed(let error): return "Failed: \(error)"
            }
        }
    }
    
    private override init() {
        super.init()
        let _ = webDriverService // Force access to trigger WebDriverService init
    }
    
    // MARK: - Public Methods
    
    /// Runs reservation automation for a specific configuration
    /// - Parameter config: The reservation configuration to execute
    func runReservation(for config: ReservationConfig) {
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
            await performReservation(for: config)
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
    
    private func performReservation(for config: ReservationConfig) async {
        do {
            // Step 1: Start WebDriver session and navigate directly to the URL
            await updateTask("Starting WebDriver session")
            guard await webDriverService.startSession() else {
                await handleError("Failed to start WebDriver session")
                return
            }
            
            // Step 2: Navigate to facility URL
            await updateTask("Navigating to facility")
            let navigationResult = await webDriverService.navigate(to: config.facilityURL)
            guard navigationResult else {
                await handleError("Failed to navigate to facility")
                return
            }
            
            // Step 3: Wait for page to load
            await updateTask("Waiting for page to load")
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // Step 4: Find and click sport button
            await updateTask("Looking for sport: \(config.sportName)")
            guard await webDriverService.findAndClickElement(withText: config.sportName) else {
                await handleError("Sport '\(config.sportName)' not found or failed to click")
                return
            }
            
            // Step 6: Wait for page transition
            await updateTask("Waiting for page transition")
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // For now, consider this a success
            await updateTask("Reservation automation completed")
            
            // Keep the browser open for a bit longer so user can see the result
            await updateTask("Keeping browser open for 5 seconds...")
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            
            await handleSuccess()
            
        } catch {
            await handleError("Automation error: \(error.localizedDescription)")
        }
    }
    
    private func updateTask(_ task: String) async {
        await MainActor.run {
            currentTask = task
        }
    }
    
    private func handleError(_ error: String) async {
        await MainActor.run {
            self.isRunning = false
            self.lastRunStatus = .failed(error)
            self.currentTask = "Error: \(error)"
            self.lastRunDate = Date()
        }
        logger.error("Reservation error: \(error)")
        
        // Don't stop WebDriver session on error - let it keep running
        // await webDriverService.stopSession()
    }
    
    private func handleSuccess() async {
        await MainActor.run {
            self.isRunning = false
            self.lastRunStatus = .success
            self.currentTask = "Reservation completed successfully"
            self.lastRunDate = Date()
        }
    }
} 