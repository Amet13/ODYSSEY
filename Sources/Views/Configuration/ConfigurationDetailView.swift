import SwiftUI

/// Detailed view for adding and editing reservation configurations
///
/// This view provides a comprehensive interface for creating and modifying reservation configurations.
/// It includes validation for timeslot limits (maximum 2 per day) and duplicate prevention.
///
/// Key Features:
/// - Facility URL validation and auto-detection
/// - Sport selection with real-time facility data
/// - Smart timeslot management with duplicate prevention
/// - Auto-generated configuration names
/// - Real-time preview of configuration
struct ConfigurationDetailView: View {
    let config: ReservationConfig?
    let onSave: (ReservationConfig) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var facilityURL: String = ""
    @State private var sportName: String = ""
    @State private var numberOfPeople: Int = 1
    @State private var isEnabled: Bool = true
    @State private var dayTimeSlots: [ReservationConfig.Weekday: [TimeSlot]] = [:]
    @State private var showDayPicker = false
    @State private var showingSportsPicker = false
    @State private var availableSports: [String] = []
    @State private var isFetchingSports = false

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    basicSettingsSection
                    sportPickerSection
                    numberOfPeopleSection
                    configNameSection
                    Divider().padding(.vertical, 8)
                    schedulingSection
                    Divider().padding(.vertical, 8)
                    previewSection
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
            }
            Divider()
            footerButtonsSection
        }
        .frame(width: 440, height: 560)
        .navigationTitle(config == nil ? "Add Reservation Configuration" : "Edit Reservation Configuration")
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
        .onAppear { loadConfiguration() }
        .sheet(isPresented: $showDayPicker) {
            DayPickerView(selectedDays: Set(dayTimeSlots.keys), onAdd: { day in
                if dayTimeSlots[day] == nil {
                    dayTimeSlots[day] = [TimeSlot(time: Calendar.current.date(from: DateComponents(
                        hour: 18,
                        minute: 0,
                    )) ?? Date())]
                }
            })
        }
    }

    private var basicSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Facility URL")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            TextField("Enter facility URL", text: $facilityURL)
                .onChange(of: facilityURL) { _ in updateConfigurationName() }
            if !facilityURL.isEmpty, !isValidFacilityURL(facilityURL) {
                Text("Invalid facility URL. Please enter a valid Ottawa Recreation URL.")
                    .font(.caption)
                    .foregroundColor(.red)
                Link(
                    "View Ottawa Facilities",
                    destination: URL(string: "https://ottawa.ca/en/recreation-and-parks/recreation-facilities")!,
                )
                .font(.caption)
            }
        }
        .padding(.bottom, 20)
    }

    private var sportPickerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sport Name")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            HStack {
                Menu {
                    if availableSports.isEmpty {
                        Text("No sports available").foregroundColor(.secondary)
                    } else {
                        ForEach(availableSports, id: \.self) { sport in
                            Button(action: {
                                sportName = sport
                                updateConfigurationName()
                            }) {
                                HStack {
                                    Text(sport)
                                    if sportName == sport {
                                        Spacer()
                                        Image(systemName: "checkmark").foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(sportName.isEmpty ? "Select Sport" : sportName)
                            .foregroundColor(sportName.isEmpty ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down").foregroundColor(.secondary).font(.caption)
                    }
                }
                .disabled(availableSports.isEmpty)
                if !facilityURL.isEmpty, isValidFacilityURL(facilityURL) {
                    Button(action: { fetchAvailableSports() }) {
                        Image(systemName: isFetchingSports ? "arrow.clockwise" : "magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isFetchingSports)
                }
            }
            if isFetchingSports {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Fetching available sports...").font(.caption).foregroundColor(.secondary)
                }
            }
            if !availableSports.isEmpty {
                Text("\(availableSports.count) sports found").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 20)
    }

    private var numberOfPeopleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Number of People")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            HStack(spacing: 20) {
                Button(action: {
                    numberOfPeople = 1
                    updateConfigurationName()
                }) {
                    HStack {
                        Image(systemName: numberOfPeople == 1 ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(numberOfPeople == 1 ? .accentColor : .secondary)
                        Text("1 Person").foregroundColor(.primary)
                    }
                }.buttonStyle(.bordered)
                Button(action: {
                    numberOfPeople = 2
                    updateConfigurationName()
                }) {
                    HStack {
                        Image(systemName: numberOfPeople == 2 ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(numberOfPeople == 2 ? .accentColor : .secondary)
                        Text("2 People").foregroundColor(.primary)
                    }
                }.buttonStyle(.bordered)
            }
        }
        .padding(.bottom, 20)
    }

    private var configNameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration Name")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            TextField("Configuration Name", text: $name)
        }
        .padding(.bottom, 20)
    }

    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Time Slots")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Button("Add Day") { showDayPicker = true }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Text("Maximum 2 time slots per day (no duplicates)")
                .font(.caption)
                .foregroundColor(.secondary)
            if dayTimeSlots.isEmpty {
                Text("No days selected. Click 'Add Day' to start scheduling.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                let weekdayOrder: [ReservationConfig.Weekday] = [
                    .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
                ]
                ForEach(Array(dayTimeSlots.keys.sorted { lhs, rhs in
                    weekdayOrder.firstIndex(of: lhs)! < weekdayOrder.firstIndex(of: rhs)!
                }), id: \.self) { day in
                    DayTimeSlotEditor(
                        day: day,
                        slots: Binding(
                            get: { dayTimeSlots[day] ?? [TimeSlot(time: Calendar.current.date(from: DateComponents(
                                hour: 18,
                                minute: 0,
                            )) ?? Date())]
                            },
                            set: { dayTimeSlots[day] = $0 },
                        ),
                        onAdd: { addTimeSlot(for: day) },
                        onRemove: { idx in removeTimeSlot(for: day, at: idx) },
                        onRemoveDay: { removeDay(day) },
                    )
                }
            }
        }
        .padding(.bottom, 20)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 4)
            Text("Name: \(name.isEmpty ? "Not set" : name)")
            Text("Sport: \(sportName.isEmpty ? "Not set" : sportName)")
            Text("People: \(numberOfPeople)")
            if !dayTimeSlots.isEmpty {
                let weekdayOrder: [ReservationConfig.Weekday] = [
                    .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
                ]
                let sortedDays = dayTimeSlots.keys.sorted { lhs, rhs in
                    weekdayOrder.firstIndex(of: lhs)! < weekdayOrder.firstIndex(of: rhs)!
                }
                ForEach(sortedDays, id: \.self) { day in
                    let slots = dayTimeSlots[day] ?? []
                    let sortedTimes = slots.sorted { $0.time < $1.time }
                        .map { $0.time.formatted(date: .omitted, time: .shortened) }
                        .joined(separator: ", ")
                    if !sortedTimes.isEmpty {
                        Text("\(day.shortName): \(sortedTimes)")
                    }
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var footerButtonsSection: some View {
        HStack {
            Spacer()
            Button("Cancel") { dismiss() }
                .buttonStyle(.bordered)
            Button("Save") {
                if isValidConfiguration {
                    saveConfiguration()
                } else {
                    validationMessage = "Please fill in all required fields with valid data."
                    showingValidationAlert = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValidConfiguration)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
    }

    // MARK: - Private Methods

    private func loadConfiguration() {
        guard let config else { return }

        name = config.name
        facilityURL = config.facilityURL
        sportName = config.sportName
        numberOfPeople = config.numberOfPeople
        isEnabled = config.isEnabled
        dayTimeSlots = config.dayTimeSlots.isEmpty ? [:] : config.dayTimeSlots

        // Update the configuration name after loading
        updateConfigurationName()
    }

    private func saveConfiguration() {
        let newConfig = ReservationConfig(
            id: config?.id ?? UUID(),
            name: name,
            facilityURL: facilityURL,
            sportName: sportName,
            numberOfPeople: numberOfPeople,
            isEnabled: isEnabled,
            dayTimeSlots: dayTimeSlots,
        )

        onSave(newConfig)
        dismiss()
    }

    private var isValidConfiguration: Bool {
        !name.isEmpty &&
            isValidFacilityURL(facilityURL) &&
            !sportName.isEmpty &&
            !dayTimeSlots.isEmpty
    }

    private func isValidFacilityURL(_ url: String) -> Bool {
        let pattern = #"^https://reservation\.frontdesksuite\.ca/rcfs/[^/]+/?$"#
        return url.range(of: pattern, options: .regularExpression) != nil
    }

    private func extractFacilityName(from url: String) -> String {
        let pattern = #"https://reservation\.frontdesksuite\.ca/rcfs/([^/]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsrange = NSRange(url.startIndex ..< url.endIndex, in: url)
            if let match = regex.firstMatch(in: url, options: [], range: nsrange) {
                let facilityRange = Range(match.range(at: 1), in: url)!
                let facilityName = String(url[facilityRange])
                return facilityName.capitalized
            }
        }
        return ""
    }

    private func updateConfigurationName() {
        // Auto-generate configuration name
        let facilityName = extractFacilityName(from: facilityURL)
        let peopleText = "\(numberOfPeople)pp"
        name = "\(facilityName) - \(sportName) (\(peopleText))"
    }

    private func fetchAvailableSports() {
        guard !facilityURL.isEmpty, isValidFacilityURL(facilityURL) else { return }

        isFetchingSports = true
        availableSports = []

        FacilityService.shared.fetchAvailableSports(from: facilityURL) { sports in
            DispatchQueue.main.async {
                isFetchingSports = false
                availableSports = sports
            }
        }
    }

    /// Adds a new timeslot for the specified day
    ///
    /// This function implements smart timeslot management:
    /// - First timeslot defaults to 6:00 PM
    /// - Second timeslot uses intelligent time selection to avoid conflicts
    /// - Maximum of 2 timeslots per day enforced
    /// - Duplicate prevention ensures no overlapping times
    ///
    /// - Parameter day: The weekday to add the timeslot to
    private func addTimeSlot(for day: ReservationConfig.Weekday) {
        if dayTimeSlots[day] == nil {
            // First timeslot - use 6:00 PM as default
            let newTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
            dayTimeSlots[day] = [TimeSlot(time: newTime)]
        } else if (dayTimeSlots[day]?.count ?? 0) < 2 {
            // Second timeslot - find an available time
            if let availableTime = findAvailableTime(for: day) {
                dayTimeSlots[day]?.append(TimeSlot(time: availableTime))
            }
        }
    }

    /// Finds an available time for a second timeslot that doesn't conflict with existing times
    ///
    /// This function implements intelligent time selection by trying preferred times in order:
    /// 1. 6:00 PM (if not already taken)
    /// 2. 7:00 PM (if not already taken)
    /// 3. 5:00 PM (if not already taken)
    /// 4. 8:00 PM (if not already taken)
    /// 5. 4:00 PM (if not already taken)
    /// 6. Any available hour between 9 AM and 10 PM
    ///
    /// - Parameter day: The weekday to find an available time for
    /// - Returns: A Date representing the available time, or nil if no time is available
    private func findAvailableTime(for day: ReservationConfig.Weekday) -> Date? {
        guard let existingSlots = dayTimeSlots[day] else { return nil }

        let calendar = Calendar.current
        let defaultTimes = [
            DateComponents(hour: 18, minute: 0), // 6:00 PM
            DateComponents(hour: 19, minute: 0), // 7:00 PM
            DateComponents(hour: 17, minute: 0), // 5:00 PM
            DateComponents(hour: 20, minute: 0), // 8:00 PM
            DateComponents(hour: 16, minute: 0), // 4:00 PM
        ]

        for timeComponents in defaultTimes {
            if let newTime = calendar.date(from: timeComponents) {
                if !isTimeDuplicate(newTime, for: day) {
                    return newTime
                }
            }
        }

        // If all default times are taken, find the next available hour
        let existingHours = existingSlots.compactMap { slot in
            calendar.dateComponents([.hour], from: slot.time).hour
        }

        for hour in 9 ... 22 { // 9 AM to 10 PM
            if !existingHours.contains(hour) {
                if let newTime = calendar.date(from: DateComponents(hour: hour, minute: 0)) {
                    return newTime
                }
            }
        }

        return nil
    }

    /// Checks if a given time would create a duplicate with existing timeslots for the specified day
    ///
    /// This function compares times by hour and minute only, ignoring seconds and date components
    /// to ensure accurate duplicate detection for scheduling purposes.
    ///
    /// - Parameters:
    ///   - time: The time to check for duplicates
    ///   - day: The weekday to check against
    /// - Returns: True if the time would be a duplicate, false otherwise
    private func isTimeDuplicate(_ time: Date, for day: ReservationConfig.Weekday) -> Bool {
        guard let existingSlots = dayTimeSlots[day] else { return false }

        let calendar = Calendar.current
        let newTimeComponents = calendar.dateComponents([.hour, .minute], from: time)

        return existingSlots.contains { existingSlot in
            let existingTimeComponents = calendar.dateComponents([.hour, .minute], from: existingSlot.time)
            return newTimeComponents.hour == existingTimeComponents.hour &&
                newTimeComponents.minute == existingTimeComponents.minute
        }
    }

    private func removeTimeSlot(for day: ReservationConfig.Weekday, at index: Int) {
        if (dayTimeSlots[day]?.count ?? 0) > 1 {
            dayTimeSlots[day]?.remove(at: index)
        }
    }

    private func removeDay(_ day: ReservationConfig.Weekday) {
        dayTimeSlots.removeValue(forKey: day)
    }
}

// MARK: - DayPickerView

struct DayPickerView: View {
    let selectedDays: Set<ReservationConfig.Weekday>
    let onAdd: (ReservationConfig.Weekday) -> Void
    @Environment(\.dismiss) private var dismiss

    var availableDays: [ReservationConfig.Weekday] {
        ReservationConfig.Weekday.allCases.filter { !selectedDays.contains($0) }
    }

    var body: some View {
        VStack {
            Text("Add Day")
                .font(.headline)
                .padding()

            List(availableDays, id: \.self) { day in
                Button(action: {
                    onAdd(day)
                    dismiss()
                }) {
                    HStack {
                        Text(day.shortName)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .frame(width: 300, height: 400)
    }
}

// MARK: - DayTimeSlotEditor

struct DayTimeSlotEditor: View {
    let day: ReservationConfig.Weekday
    @Binding var slots: [TimeSlot]
    let onAdd: () -> Void
    let onRemove: (Int) -> Void
    let onRemoveDay: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(day.shortName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(slots.count >= 2 ? .gray : .green)
                }
                .buttonStyle(.bordered)
                .disabled(slots.count >= 2)
                .help(slots.count >= 2 ? "Maximum 2 time slots per day" : "Add time slot (no duplicates)")
                Button(action: onRemoveDay) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
            }
            ForEach(
                Array(slots.enumerated().sorted { $0.element.time < $1.element.time }),
                id: \.element.id,
            ) { index, _ in
                HStack {
                    DatePicker("", selection: Binding(
                        get: { slots[index].time },
                        set: { newValue in slots[index].time = newValue },
                    ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Button(action: { onRemove(index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .disabled(slots.count <= 1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConfigurationDetailView(config: nil) { _ in }
}
