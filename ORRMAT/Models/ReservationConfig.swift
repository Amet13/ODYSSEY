import Foundation

/// Configuration for a single reservation automation
struct ReservationConfig: Codable, Identifiable {
    var id: UUID
    
    // Basic settings
    var name: String
    var facilityURL: String
    var sportName: String
    var numberOfPeople: Int = 1
    
    // Scheduling
    var isEnabled: Bool = true
    
    // Time preferences
    var dayTimeSlots: [Weekday: [TimeSlot]] = [:]
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        name: String,
        facilityURL: String,
        sportName: String,
        numberOfPeople: Int = 1,
        isEnabled: Bool = true,
        dayTimeSlots: [Weekday: [TimeSlot]] = [:]
    ) {
        self.id = id
        self.name = name
        self.facilityURL = facilityURL
        self.sportName = sportName
        self.numberOfPeople = numberOfPeople
        self.isEnabled = isEnabled
        self.dayTimeSlots = dayTimeSlots
    }
    
    enum Weekday: String, CaseIterable, Codable {
        case sunday = "Sunday"
        case monday = "Monday"
        case tuesday = "Tuesday"
        case wednesday = "Wednesday"
        case thursday = "Thursday"
        case friday = "Friday"
        case saturday = "Saturday"
        
        var shortName: String {
            String(rawValue.prefix(3))
        }
        
        var calendarWeekday: Int {
            switch self {
            case .sunday: return 1
            case .monday: return 2
            case .tuesday: return 3
            case .wednesday: return 4
            case .thursday: return 5
            case .friday: return 6
            case .saturday: return 7
            }
        }
    }
}

/// Represents a time slot for reservations
struct TimeSlot: Codable, Identifiable, Hashable {
    var id: UUID
    var time: Date
    
    init(time: Date) {
        self.id = UUID()
        self.time = time
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TimeSlot, rhs: TimeSlot) -> Bool {
        lhs.id == rhs.id
    }
}

/// Global application settings
struct AppSettings: Codable {
    var configurations: [ReservationConfig] = []
    var globalEnabled: Bool = true
    var notificationsEnabled: Bool = true
    var autoStart: Bool = false
    var logLevel: LogLevel = .info
    
    enum LogLevel: String, CaseIterable, Codable {
        case debug = "Debug"
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
    }
} 