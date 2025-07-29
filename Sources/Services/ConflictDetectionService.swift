import Foundation
import os.log

/// Service for detecting conflicts between reservation configurations
/// Handles time slot overlaps and facility conflicts
@MainActor
public final class ConflictDetectionService: ObservableObject {
    public static let shared = ConflictDetectionService()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "ConflictDetectionService")

    private init() {
        logger.info("🔧 ConflictDetectionService initialized")
    }

    deinit {
        logger.info("🧹 ConflictDetectionService deinitialized")
    }

    // MARK: - Conflict Detection

    /// Detects conflicts between reservation configurations
    /// - Parameter configurations: Array of configurations to check
    /// - Returns: Array of detected conflicts
    public func detectConflicts(in configurations: [ReservationConfig]) -> [ReservationConflict] {
        var conflicts: [ReservationConflict] = []

        // Check for time slot conflicts
        conflicts.append(contentsOf: detectTimeSlotConflicts(in: configurations))

        logger.info("🔍 Detected \(conflicts.count) conflicts in \(configurations.count) configurations")
        return conflicts
    }

    /// Detects time slot conflicts between configurations
    /// - Parameter configurations: Array of configurations to check
    /// - Returns: Array of time slot conflicts
    private func detectTimeSlotConflicts(in configurations: [ReservationConfig]) -> [ReservationConflict] {
        var conflicts: [ReservationConflict] = []

        for firstIndex in 0 ..< configurations.count {
            for secondIndex in (firstIndex + 1) ..< configurations.count {
                let config1 = configurations[firstIndex]
                let config2 = configurations[secondIndex]

                // Check if configurations have overlapping time slots
                let overlappingSlots = findOverlappingTimeSlots(between: config1, and: config2)

                if !overlappingSlots.isEmpty {
                    let conflict = ReservationConflict(
                        type: .timeSlotOverlap,
                        severity: .warning,
                        message: "Time slot overlap detected",
                        config1: config1,
                        config2: config2,
                        details: overlappingSlots,
                    )
                    conflicts.append(conflict)
                }
            }
        }

        return conflicts
    }

    /// Finds overlapping time slots between two configurations
    /// - Parameters:
    ///   - config1: First configuration
    ///   - config2: Second configuration
    /// - Returns: Array of overlapping time slots
    private func findOverlappingTimeSlots(
        between config1: ReservationConfig,
        and config2: ReservationConfig,
    ) -> [String] {
        var overlappingSlots: [String] = []

        for (weekday1, timeSlots1) in config1.dayTimeSlots {
            for (weekday2, timeSlots2) in config2.dayTimeSlots where weekday1 == weekday2 {
                for timeSlot1 in timeSlots1 {
                    for timeSlot2 in timeSlots2 where timeSlot1.time == timeSlot2.time {
                        let overlap = "\(weekday1.rawValue) at \(formatTime(timeSlot1.time))"
                        overlappingSlots.append(overlap)
                    }
                }
            }
        }

        return overlappingSlots
    }

    /// Formats a time for display
    /// - Parameter time: The time to format
    /// - Returns: Formatted time string
    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    /// Validates a new configuration against existing configurations
    /// - Parameters:
    ///   - newConfig: The new configuration to validate
    ///   - existingConfigs: Array of existing configurations
    /// - Returns: Array of conflicts with the new configuration
    public func validateNewConfiguration(
        _ newConfig: ReservationConfig,
        against existingConfigs: [ReservationConfig],
    ) -> [ReservationConflict] {
        let allConfigs = existingConfigs + [newConfig]
        return detectConflicts(in: allConfigs).filter { conflict in
            conflict.config1.id == newConfig.id || conflict.config2.id == newConfig.id
        }
    }

    /// Gets a summary of conflicts for display
    /// - Parameter conflicts: Array of conflicts
    /// - Returns: Formatted conflict summary
    public func getConflictSummary(_ conflicts: [ReservationConflict]) -> String {
        guard !conflicts.isEmpty else {
            return "No conflicts detected"
        }

        let criticalCount = conflicts.count(where: { $0.severity == .critical })
        let warningCount = conflicts.count(where: { $0.severity == .warning })
        let infoCount = conflicts.count(where: { $0.severity == .info })

        var summary = "Conflict Summary:\n"
        if criticalCount > 0 {
            summary += "• \(criticalCount) critical conflicts\n"
        }
        if warningCount > 0 {
            summary += "• \(warningCount) warnings\n"
        }
        if infoCount > 0 {
            summary += "• \(infoCount) informational conflicts\n"
        }

        return summary
    }
}

// MARK: - Supporting Types

/// Represents a conflict between reservation configurations
public struct ReservationConflict: Identifiable {
    public let id = UUID()
    public let type: ConflictType
    public let severity: ConflictSeverity
    public let message: String
    public let config1: ReservationConfig
    public let config2: ReservationConfig
    public let details: [String]

    public init(
        type: ConflictType,
        severity: ConflictSeverity,
        message: String,
        config1: ReservationConfig,
        config2: ReservationConfig,
        details: [String]
    ) {
        self.type = type
        self.severity = severity
        self.message = message
        self.config1 = config1
        self.config2 = config2
        self.details = details
    }
}

/// Types of conflicts that can occur
public enum ConflictType: String, CaseIterable {
    case timeSlotOverlap = "Time Slot Overlap"
    case resourceConflict = "Resource Conflict"
}

/// Severity levels for conflicts
public enum ConflictSeverity: String, CaseIterable {
    case critical = "Critical"
    case warning = "Warning"
    case info = "Information"

    public var color: String {
        switch self {
        case .critical:
            return "red"
        case .warning:
            return "orange"
        case .info:
            return "blue"
        }
    }
}
