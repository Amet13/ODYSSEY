import Foundation

/// Configuration for a single reservation automation
/// Represents all settings needed to automate a reservation at an Ottawa recreation facility
struct ReservationConfig: Codable, Identifiable, Equatable {
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

    // MARK: - Equatable

    static func == (lhs: ReservationConfig, rhs: ReservationConfig) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.facilityURL == rhs.facilityURL &&
            lhs.sportName == rhs.sportName &&
            lhs.numberOfPeople == rhs.numberOfPeople &&
            lhs.isEnabled == rhs.isEnabled &&
            lhs.dayTimeSlots == rhs.dayTimeSlots
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

        /// Localized three-letter abbreviation
        var localizedShortName: String {
            let localizedName = rawValue
            return String(localizedName.prefix(3))
        }

        /// Calendar weekday number (1 = Sunday, 2 = Monday, etc.)
        var calendarWeekday: Int {
            switch self {
            case .sunday: 1
            case .monday: 2
            case .tuesday: 3
            case .wednesday: 4
            case .thursday: 5
            case .friday: 6
            case .saturday: 7
            }
        }
    }

    // MARK: - Utility Methods

    /// Extracts facility name from a reservation URL
    /// - Parameter url: The facility URL
    /// - Returns: Capitalized facility name or empty string if not found
    static func extractFacilityName(from url: String) -> String {
        let pattern = #"https://reservation\.frontdesksuite\.ca/rcfs/([^/]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsrange = NSRange(url.startIndex ..< url.endIndex, in: url)
            if
                let match = regex.firstMatch(in: url, options: [], range: nsrange),
                let facilityRange = Range(match.range(at: 1), in: url)
            {
                let facilityName = String(url[facilityRange])
                return facilityName.capitalized
            }
        }
        return ""
    }

    /// Formats the schedule info inline for display (e.g., "Mon 8:30 AM, 9:30 AM • Wed 7:00 PM")
    static func formatScheduleInfoInline(config: ReservationConfig) -> String {
        let sortedDays = config.dayTimeSlots.keys.sorted { day1, day2 in
            guard
                let index1 = Weekday.allCases.firstIndex(of: day1),
                let index2 = Weekday.allCases.firstIndex(of: day2)
            else {
                return false
            }
            return index1 < index2
        }
        var scheduleInfo: [String] = []
        for day in sortedDays {
            if let timeSlots = config.dayTimeSlots[day], !timeSlots.isEmpty {
                let timeStrings = timeSlots.map { timeSlot in
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    formatter.locale = Locale(identifier: "en_US")
                    return formatter.string(from: timeSlot.time)
                }.sorted()
                let dayShort = day.localizedShortName
                let timesString = timeStrings.joined(separator: ", ")
                scheduleInfo.append("\(dayShort) \(timesString)")
            }
        }
        return scheduleInfo.joined(separator: " • ")
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

    /// Formats the time to match the website's time format (e.g., "8:30 AM")
    /// - Returns: Formatted time string
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: time)
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
