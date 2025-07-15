import SwiftUI

struct ConfigurationDetailView: View {
    let config: ReservationConfig?
    let onSave: (ReservationConfig) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettingsManager = UserSettingsManager.shared

    @State private var name: String = ""
    @State private var facilityURL: String = ""
    @State private var sportName: String = ""
    @State private var numberOfPeople: Int = 1
    @State private var isEnabled: Bool = true
    @State private var dayTimeSlots: [ReservationConfig.Weekday: [Date]] = [:]
    @State private var didInitializeSlots = false
    @State private var showDayPicker = false
    @State private var showingSportsPicker = false
    @State private var availableSports: [String] = []
    @State private var isFetchingSports = false

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var isEditingExistingConfig = false

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
        .navigationTitle(
            config == nil ? userSettingsManager.userSettings
                .localized("Add Reservation Configuration") : userSettingsManager.userSettings
                .localized("Edit Reservation Configuration"),
        )
        .alert(userSettingsManager.userSettings.localized("Validation Error"), isPresented: $showingValidationAlert) {
            Button(userSettingsManager.userSettings.localized("OK")) { }
        } message: {
            Text(validationMessage)
        }
        .onAppear {
            if !didInitializeSlots {
                dayTimeSlots = config?.dayTimeSlots.mapValues { $0.map(\.time) } ?? [:]
                didInitializeSlots = true
            }
            loadConfiguration()
        }
        .sheet(isPresented: $showDayPicker) {
            DayPickerView(selectedDays: Set(dayTimeSlots.keys), onAdd: { day in
                addTimeSlot(for: day)
            })
        }
    }

    private var basicSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(userSettingsManager.userSettings.localized("Facility URL"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            TextField(userSettingsManager.userSettings.localized("Enter facility URL"), text: $facilityURL)
                .onChange(of: facilityURL) { _ in updateConfigurationName() }
            if !facilityURL.isEmpty, !isValidFacilityURL(facilityURL) {
                Text(userSettingsManager.userSettings.localized("Please enter a valid Ottawa Recreation URL."))
                    .font(.caption)
                    .foregroundColor(.red)
                Link(
                    userSettingsManager.userSettings.localized("View Ottawa Facilities"),
                    destination: URL(string: "https://ottawa.ca/en/recreation-and-parks/recreation-facilities") ??
                        URL(string: "https://ottawa.ca")!,
                )
                .font(.caption)
            }
        }
        .padding(.bottom, 20)
    }

    private var sportPickerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(userSettingsManager.userSettings.localized("Sport Name"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            HStack {
                Menu {
                    if availableSports.isEmpty {
                        Text(userSettingsManager.userSettings.localized("No sports available"))
                            .foregroundColor(.secondary)
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
                        Text(sportName.isEmpty ? userSettingsManager.userSettings.localized("Select Sport") : sportName)
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
                    Text(userSettingsManager.userSettings.localized("Fetching available sports...")).font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if !availableSports.isEmpty {
                Text("\(availableSports.count) \(userSettingsManager.userSettings.localized("sports found"))")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 20)
    }

    private var numberOfPeopleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(userSettingsManager.userSettings.localized("Number of People"))
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
                        Text(userSettingsManager.userSettings.localized("1 Person")).foregroundColor(.primary)
                    }
                }.buttonStyle(.bordered)
                    .controlSize(.regular)
                Button(action: {
                    numberOfPeople = 2
                    updateConfigurationName()
                }) {
                    HStack {
                        Image(systemName: numberOfPeople == 2 ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(numberOfPeople == 2 ? .accentColor : .secondary)
                        Text(userSettingsManager.userSettings.localized("2 People")).foregroundColor(.primary)
                    }
                }.buttonStyle(.bordered)
                    .controlSize(.regular)
            }
        }
        .padding(.bottom, 20)
    }

    private var configNameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(userSettingsManager.userSettings.localized("Configuration Name"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            TextField(userSettingsManager.userSettings.localized("Configuration Name"), text: $name)
        }
        .padding(.bottom, 20)
    }

    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(userSettingsManager.userSettings.localized("Time Slots"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Button(userSettingsManager.userSettings.localized("Add Day")) { showDayPicker = true }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Text(userSettingsManager.userSettings.localized("Maximum 2 time slots per day (no duplicates)"))
                .font(.caption)
                .foregroundColor(.secondary)
            if dayTimeSlots.isEmpty {
                Text(
                    userSettingsManager.userSettings
                        .localized("No days selected. Click 'Add Day' to start scheduling."),
                )
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
            } else {
                let weekdayOrder: [ReservationConfig.Weekday] = [
                    .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
                ]
                ForEach(Array(dayTimeSlots.keys.sorted { lhs, rhs in
                    guard
                        let lhsIndex = weekdayOrder.firstIndex(of: lhs),
                        let rhsIndex = weekdayOrder.firstIndex(of: rhs) else { return false }
                    return lhsIndex < rhsIndex
                }), id: \.self) { day in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(day.localizedShortName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Button(action: { removeDay(day) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.bordered)
                        }
                        TimeSlotPickerView(slots: Binding(
                            get: { dayTimeSlots[day] ?? [defaultTime()] },
                            set: { newValue in dayTimeSlots[day] = newValue },
                        ))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.bottom, 20)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(userSettingsManager.userSettings.localized("Preview"))
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 4)
            Text(
                "\(userSettingsManager.userSettings.localized("Name:")) \(name.isEmpty ? userSettingsManager.userSettings.localized("Not set") : name)",
            )
            Text(
                "\(userSettingsManager.userSettings.localized("Sport:")) \(sportName.isEmpty ? userSettingsManager.userSettings.localized("Not set") : sportName)",
            )
            Text("\(userSettingsManager.userSettings.localized("People:")) \(numberOfPeople)")
            if !dayTimeSlots.isEmpty {
                let weekdayOrder: [ReservationConfig.Weekday] = [
                    .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
                ]
                let sortedDays = dayTimeSlots.keys.sorted { lhs, rhs in
                    guard
                        let lhsIndex = weekdayOrder.firstIndex(of: lhs),
                        let rhsIndex = weekdayOrder.firstIndex(of: rhs) else { return false }
                    return lhsIndex < rhsIndex
                }
                ForEach(sortedDays, id: \.self) { day in
                    let slots = dayTimeSlots[day] ?? []
                    let sortedTimes = slots.sorted { $0 < $1 }
                        .map { $0.formatted(date: .omitted, time: .shortened) }
                        .joined(separator: ", ")
                    if !sortedTimes.isEmpty {
                        Text("\(day.localizedShortName): \(sortedTimes)")
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
            Button(userSettingsManager.userSettings.localized("Cancel")) { dismiss() }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            Button(userSettingsManager.userSettings.localized("Save")) {
                if isValidConfiguration {
                    saveConfiguration()
                } else {
                    validationMessage = userSettingsManager.userSettings
                        .localized("Please fill in all required fields with valid data.")
                    showingValidationAlert = true
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(!isValidConfiguration)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
    }

    // MARK: - Private Methods

    private func loadConfiguration() {
        guard let config else {
            // Creating a new configuration
            isEditingExistingConfig = false
            return
        }

        // Editing an existing configuration
        isEditingExistingConfig = true
        name = config.name
        facilityURL = config.facilityURL
        sportName = config.sportName
        numberOfPeople = config.numberOfPeople
        isEnabled = config.isEnabled

        // Don't update the name when editing an existing configuration
        // to preserve custom names that users have set
    }

    private func saveConfiguration() {
        let convertedSlots: [ReservationConfig.Weekday: [TimeSlot]] = dayTimeSlots
            .mapValues { $0.map { TimeSlot(time: $0) } }
        let newConfig = ReservationConfig(
            id: config?.id ?? UUID(),
            name: name,
            facilityURL: facilityURL,
            sportName: sportName,
            numberOfPeople: numberOfPeople,
            isEnabled: isEnabled,
            dayTimeSlots: convertedSlots,
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

    private func updateConfigurationName() {
        // Only update the name if we're creating a new configuration or if the name is empty
        // This preserves custom names when editing existing configurations
        if !isEditingExistingConfig || name.isEmpty {
            let facilityName = extractFacilityName(from: facilityURL)
            let peopleText = "\(numberOfPeople)pp"
            name = "\(facilityName) - \(sportName) (\(peopleText))"
        }
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

    private func addTimeSlot(for day: ReservationConfig.Weekday) {
        if dayTimeSlots[day] == nil {
            let defaultTime = Self.normalizeTime(hour: 18, minute: 0)
            dayTimeSlots[day] = [defaultTime]
        } else if (dayTimeSlots[day]?.count ?? 0) < 2 {
            if let availableTime = findAvailableTime(for: day) {
                dayTimeSlots[day]?.append(availableTime)
            }
        }
    }

    private func findAvailableTime(for day: ReservationConfig.Weekday) -> Date? {
        guard let existingSlots = dayTimeSlots[day], let firstSlot = existingSlots.first else { return nil }

        let calendar = Calendar.current
        let existingHours = existingSlots.compactMap { slot in
            calendar.dateComponents([.hour], from: slot).hour
        }
        let firstSlotHour = calendar.dateComponents([.hour], from: firstSlot).hour ?? 18

        if firstSlotHour < 22 {
            let plusOneHour = firstSlotHour + 1
            if !existingHours.contains(plusOneHour) {
                return Self.normalizeTime(hour: plusOneHour, minute: 0)
            }
        }

        for hour in (firstSlotHour + 1) ... 22 {
            if !existingHours.contains(hour) {
                return Self.normalizeTime(hour: hour, minute: 0)
            }
        }

        for hour in 9 ... 22 {
            if !existingHours.contains(hour) {
                return Self.normalizeTime(hour: hour, minute: 0)
            }
        }
        return nil
    }

    private func removeDay(_ day: ReservationConfig.Weekday) {
        dayTimeSlots.removeValue(forKey: day)
    }

    static func normalizeTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
    }
}

private func defaultTime() -> Date {
    Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
}

// MARK: - DayPickerView

struct DayPickerView: View {
    let selectedDays: Set<ReservationConfig.Weekday>
    let onAdd: (ReservationConfig.Weekday) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettingsManager = UserSettingsManager.shared

    var availableDays: [ReservationConfig.Weekday] {
        ReservationConfig.Weekday.allCases.filter { !selectedDays.contains($0) }
    }

    var body: some View {
        VStack {
            Text(userSettingsManager.userSettings.localized("Add Day"))
                .font(.headline)
                .padding()

            List(availableDays, id: \.self) { day in
                Button(action: {
                    onAdd(day)
                    dismiss()
                }) {
                    HStack {
                        Text(day.localizedShortName)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }

            HStack {
                Spacer()
                Button(userSettingsManager.userSettings.localized("Cancel")) {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .padding()
            }
        }
        .frame(width: 440, height: 400)
    }
}

// MARK: - TimeSlotPickerView

struct TimeSlotPickerView: View {
    @Binding var slots: [Date]
    let maxSlots = 2

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(slots.indices, id: \.self) { idx in
                HStack {
                    DatePicker(
                        "Time Slot \(idx + 1)",
                        selection: Binding(
                            get: { slots[idx] },
                            set: { newValue in
                                if
                                    !slots.enumerated().contains(where: { $0.offset != idx && isSameTime(
                                        $0.element,
                                        newValue,
                                    ) })
                                {
                                    slots[idx] = newValue
                                }
                            },
                        ),
                        displayedComponents: .hourAndMinute,
                    )
                    .labelsHidden()
                    Button(action: {
                        slots.remove(at: idx)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .disabled(slots.count <= 1)
                }
            }
            if slots.count < maxSlots {
                Button(action: {
                    let calendar = Calendar.current
                    let base = slots.first ?? Date()
                    let newHour = slots.count == 1
                        ? ((calendar.component(.hour, from: base) + 1) % 24)
                        : 18
                    let newSlot = calendar.date(
                        bySettingHour: newHour,
                        minute: 0,
                        second: 0,
                        of: Date(),
                    ) ?? Date()
                    if !slots.contains(where: { isSameTime($0, newSlot) }) {
                        slots.append(newSlot)
                    }
                }) {
                    Label(
                        UserSettingsManager.shared.userSettings.localized("Add Time"),
                        systemImage: "plus.circle.fill",
                    )
                }
            }
        }
    }

    private func isSameTime(_ firstTime: Date, _ secondTime: Date) -> Bool {
        let cal = Calendar.current
        let firstComp = cal.dateComponents([.hour, .minute], from: firstTime)
        let secondComp = cal.dateComponents([.hour, .minute], from: secondTime)
        return firstComp.hour == secondComp.hour && firstComp.minute == secondComp.minute
    }
}

#Preview {
    let now = Date()
    let calendar = Calendar.current
    let roundedMinute = (calendar.component(.minute, from: now) / 30) * 30
    let roundedNow = calendar.date(from: DateComponents(
        hour: calendar.component(.hour, from: now),
        minute: roundedMinute,
    )) ?? now
    let slot1 = TimeSlot(time: roundedNow)
    let slot2 = TimeSlot(time: calendar.date(byAdding: .hour, value: 1, to: roundedNow) ?? roundedNow)
    let previewConfig = ReservationConfig(
        name: "Preview Config",
        facilityURL: "https://reservation.frontdesksuite.ca/rcfs/preview",
        sportName: "Soccer",
        numberOfPeople: 2,
        isEnabled: true,
        dayTimeSlots: [
            .monday: [slot1, slot2],
            .wednesday: [slot1],
        ],
    )
    return ConfigurationDetailView(config: previewConfig) { _ in }
}
