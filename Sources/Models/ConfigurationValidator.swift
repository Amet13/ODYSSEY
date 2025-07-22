import Foundation

/**
 * Provides validation logic for reservation configuration fields.
 *
 * Use this struct to validate user input for reservation configurations, ensuring all required fields are present and valid.
 */
enum ConfigurationValidator {
    /**
     * Validates all fields of a reservation configuration.
     *
     * - Parameters:
     *   - facilityURL: The facility reservation URL.
     *   - name: The configuration name.
     *   - sportName: The sport name.
     *   - numberOfPeople: The number of people for the reservation.
     *   - dayTimeSlots: The selected days and time slots.
     * - Returns: An array of validation error messages. Empty if valid.
     */
    static func validate(
        facilityURL: String,
        name: String,
        sportName: String,
        numberOfPeople: Int,
        dayTimeSlots: [ReservationConfig.Weekday: [Date]],
        ) -> [String] {
        var errors: [String] = []
        if facilityURL.isEmpty || !isValidFacilityURL(facilityURL) {
            errors.append("Facility URL is invalid.")
        }
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Configuration name is required.")
        }
        if sportName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Sport name is required.")
        }
        if numberOfPeople < 1 {
            errors.append("Number of people must be at least 1.")
        }
        if dayTimeSlots.isEmpty {
            errors.append("At least one day/time slot is required.")
        }
        return errors
    }

    /**
     * Validates the facility reservation URL.
     *
     * - Parameter url: The facility URL string.
     * - Returns: True if the URL is valid, false otherwise.
     */
    static func isValidFacilityURL(_ url: String) -> Bool {
        let pattern = #"^https://reservation\.frontdesksuite\.ca/rcfs/[^/]+/?$"#
        return url.range(of: pattern, options: .regularExpression) != nil
    }
}
