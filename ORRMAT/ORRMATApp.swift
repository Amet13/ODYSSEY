import SwiftUI
import UserNotifications
import os.log

@main
struct ORRMATApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

/// App delegate to handle macOS-specific functionality
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var timer: Timer?
    private let logger = Logger(subsystem: "com.orrmat.app", category: "AppDelegate")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("ORRMAT application launching")
        
        // Hide dock icon since this is a status bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize status bar controller
        statusBarController = StatusBarController()
        
        // Set up scheduling timer
        setupSchedulingTimer()
        
        // Request notification permissions
        requestNotificationPermissions()
        
        logger.info("ORRMAT application launched successfully")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logger.info("ORRMAT application terminating")
        // Clean up
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Private Methods
    
    private func setupSchedulingTimer() {
        logger.info("Setting up scheduling timer")
        // Check every minute for scheduled reservations
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.checkScheduledReservations()
        }
    }
    
    private func checkScheduledReservations() {
        let configManager = ConfigurationManager.shared
        let reservationManager = ReservationManager.shared
        
        guard configManager.settings.globalEnabled else { 
            logger.debug("Global automation disabled, skipping scheduled check")
            return 
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Convert Calendar weekday to our Weekday enum
        let weekday: ReservationConfig.Weekday
        switch currentWeekday {
        case 1: weekday = .sunday
        case 2: weekday = .monday
        case 3: weekday = .tuesday
        case 4: weekday = .wednesday
        case 5: weekday = .thursday
        case 6: weekday = .friday
        case 7: weekday = .saturday
        default: 
            logger.warning("Invalid weekday: \(currentWeekday)")
            return
        }
        
        let configsForToday = configManager.getConfigurationsForDay(weekday)
        logger.debug("Found \(configsForToday.count) configurations for \(weekday.rawValue)")
        
        for config in configsForToday {
            if shouldRunReservation(config: config, at: now) {
                logger.info("Triggering reservation for: \(config.name)")
                DispatchQueue.main.async {
                    reservationManager.runReservation(for: config)
                }
            }
        }
    }
    
    private func shouldRunReservation(config: ReservationConfig, at date: Date) -> Bool {
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute], from: date)
        
        guard let currentHour = currentTime.hour,
              let currentMinute = currentTime.minute else {
            logger.warning("Could not extract time components from date")
            return false
        }
        
        let currentMinutes = currentHour * 60 + currentMinute
        
        // Check if current time matches any of the enabled time slots exactly
        for (day, timeSlots) in config.dayTimeSlots {
            let calendarWeekday = calendar.component(.weekday, from: date)
            let expectedWeekday: Int
            
            switch day {
            case .sunday: expectedWeekday = 1
            case .monday: expectedWeekday = 2
            case .tuesday: expectedWeekday = 3
            case .wednesday: expectedWeekday = 4
            case .thursday: expectedWeekday = 5
            case .friday: expectedWeekday = 6
            case .saturday: expectedWeekday = 7
            }
            
            if calendarWeekday == expectedWeekday {
                for timeSlot in timeSlots {
                    let slotTime = calendar.dateComponents([.hour, .minute], from: timeSlot.time)
                    
                    guard let slotHour = slotTime.hour,
                          let slotMinute = slotTime.minute else {
                        logger.warning("Could not extract time components from slot")
                        continue
                    }
                    
                    let slotMinutes = slotHour * 60 + slotMinute
                    
                    if currentMinutes == slotMinutes {
                        logger.debug("Time match found for \(config.name) at \(slotHour):\(slotMinute)")
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func requestNotificationPermissions() {
        logger.info("Requesting notification permissions")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                self.logger.error("Notification permission error: \(error.localizedDescription)")
            } else {
                self.logger.info("Notification permissions granted: \(granted)")
            }
        }
    }
} 