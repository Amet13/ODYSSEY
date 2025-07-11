import Foundation

/// Configuration for a single reservation automation
/// Represents all settings needed to automate a reservation at an Ottawa recreation facility
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

    /// Creates a new reservation configuration
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - name: Display name for the configuration
    ///   - facilityURL: URL of the Ottawa recreation facility
    ///   - sportName: Name of the sport/activity
    ///   - numberOfPeople: Number of people for the reservation
    ///   - isEnabled: Whether this configuration is active
    ///   - dayTimeSlots: Scheduled time slots for each day
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

    // MARK: - Weekday Enum

    /// Represents days of the week for scheduling
    enum Weekday: String, CaseIterable, Codable {
        case sunday = "Sunday"
        case monday = "Monday"
        case tuesday = "Tuesday"
        case wednesday = "Wednesday"
        case thursday = "Thursday"
        case friday = "Friday"
        case saturday = "Saturday"

        /// Three-letter abbreviation (e.g., "Mon", "Tue")
        var shortName: String {
            String(rawValue.prefix(3))
        }

        /// Calendar weekday number (1 = Sunday, 2 = Monday, etc.)
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

    // MARK: - Utility Methods

    /// Extracts facility name from a reservation URL
    /// - Parameter url: The facility URL
    /// - Returns: Capitalized facility name or empty string if not found
    static func extractFacilityName(from url: String) -> String {
        let pattern = #"https://reservation\.frontdesksuite\.ca/rcfs/([^/]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url))
        {
            let facilityRange = Range(match.range(at: 1), in: url)!
            let facilityName = String(url[facilityRange])
            return facilityName.capitalized
        }
        return ""
    }
}

/// Represents a time slot for reservations
struct TimeSlot: Codable, Identifiable, Hashable {
    var id: UUID
    var time: Date

    /// Creates a new time slot
    /// - Parameter time: The time for this slot
    init(time: Date) {
        id = UUID()
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

    /// Logging levels for the application
    enum LogLevel: String, CaseIterable, Codable {
        case debug = "Debug"
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
    }
}
