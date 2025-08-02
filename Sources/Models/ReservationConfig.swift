import Foundation

/// Configuration for a single reservation automation
/// Represents all settings needed to automate a reservation at an Ottawa recreation facility.
public struct ReservationConfig: Identifiable, Equatable, Codable, Sendable {
  public var id: UUID

  // Basic settings
  public var name: String
  public var facilityURL: String
  public var sportName: String
  public var numberOfPeople: Int = 1

  // Scheduling
  public var isEnabled = true

  // Time preferences
  public var dayTimeSlots: [Weekday: [TimeSlot]] = [:]

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
  public init(
    id: UUID = UUID(),
    name: String,
    facilityURL: String,
    sportName: String,
    numberOfPeople: Int = AppConstants.defaultNumberOfPeople,
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

  public static func == (lhs: ReservationConfig, rhs: ReservationConfig) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.facilityURL == rhs.facilityURL
      && lhs.sportName == rhs.sportName
      && lhs.numberOfPeople == rhs.numberOfPeople && lhs.isEnabled == rhs.isEnabled
      && lhs.dayTimeSlots == rhs.dayTimeSlots
  }

  // MARK: - Weekday Enum

  /// Represents days of the week for scheduling
  public enum Weekday: String, CaseIterable, Codable, Sendable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"

    /// Three-letter abbreviation (e.g., "Mon", "Tue")
    public var shortName: String {
      String(rawValue.prefix(3))
    }

    /// Localized three-letter abbreviation
    public var localizedShortName: String {
      let localizedName = rawValue
      return String(localizedName.prefix(3))
    }

    /// Calendar weekday number (1 = Sunday, 2 = Monday, etc.)
    public var calendarWeekday: Int {
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
  public static func extractFacilityName(from url: String) -> String {
    let pattern = #"https://reservation\.frontdesksuite\.ca/rcfs/([^/]+)"#
    if let regex = try? NSRegularExpression(pattern: pattern) {
      let nsrange = NSRange(url.startIndex..<url.endIndex, in: url)
      if let match = regex.firstMatch(in: url, options: [], range: nsrange),
        let facilityRange = Range(match.range(at: 1), in: url)
      {
        let facilityName = String(url[facilityRange])
        return facilityName.capitalized
      }
    }
    return ""
  }

  /// Formats the schedule info inline for display (e.g., "Mon 8:30 AM, 9:30 AM • Wed 7:00 PM")
  public static func formatScheduleInfoInline(config: ReservationConfig) -> String {
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
public struct TimeSlot: Codable, Equatable, Sendable {
  public var id: UUID
  public var time: Date

  /// Creates a new time slot
  /// - Parameter time: The time for this slot
  public init(time: Date) {
    id = UUID()
    self.time = time
  }

  /// Formats the time to match the website's time format (e.g., "8:30 AM")
  /// - Returns: Formatted time string
  public func formattedTime() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: time)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: TimeSlot, rhs: TimeSlot) -> Bool {
    lhs.id == rhs.id
  }
}

/// Global application settings
public struct AppSettings: Codable, Sendable {
  public var configurations: [ReservationConfig] = []
  public var globalEnabled = true
  public var autoStart = false
  public var logLevel: LogLevel = .info

  /// Logging levels for the application
  public enum LogLevel: String, CaseIterable, Codable, Sendable {
    case debug = "Debug"
    case info = "Info"
    case warning = "Warning"
    case error = "Error"
  }
}
