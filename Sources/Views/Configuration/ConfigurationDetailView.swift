import SwiftUI
import UniformTypeIdentifiers

/// A detailed view for editing or creating a reservation configuration.
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
    @State private var validationErrors: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            if !validationErrors.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text(validationErrors.first ?? "Validation error.")
                        .foregroundColor(.orange)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    basicSettingsSection
                    sportPickerSection
                    numberOfPeopleSection
                    configNameSection
                    Divider().padding(.vertical, 8)
                    schedulingSection
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
            }
            Divider()
            footerButtonsSection
        }
        .frame(width: 440, height: 580)
        .navigationTitle(
            config == nil ? "Add Reservation Configuration" : "Edit Reservation Configuration",
            )
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") { }
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
            Text("Facility URL")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            TextField("Enter facility URL", text: $facilityURL)
                .onChange(of: facilityURL) { _, _ in
                    updateConfigurationName()
                    validateAll()
                }
            if !facilityURL.isEmpty, !isValidFacilityURL(facilityURL) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    HStack(spacing: 0) {
                        Text("Please enter a ")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Button("valid") {
                            if let url = URL(string: AppConstants.ottawaFacilitiesURL) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                        .font(.caption)
                        Text(" Ottawa Recreation URL")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                }
            }
            if validationErrors.contains(where: { $0.contains("Facility URL") }) {
                Text("Facility URL is invalid.")
                    .foregroundColor(.red)
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
                        Text("No sports available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availableSports, id: \.self) { sport in
                            Button(action: {
                                sportName = sport
                                updateConfigurationName()
                            }) {
                                HStack {
                                    SportIconView(symbolName: SportIconMapper.iconForSport(sport))
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
                    Text("Fetching available sports...").font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if !availableSports.isEmpty {
                Text("\(availableSports.count) sports found")
                    .font(.caption).foregroundColor(.secondary)
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
                .controlSize(.regular)
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
                .controlSize(.regular)
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
                .onChange(of: name) { _, newValue in
                    if newValue.count > 60 {
                        name = String(newValue.prefix(60))
                    }
                }
        }
        .padding(.bottom, 20)
    }

    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Time Slot")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                if dayTimeSlots.isEmpty {
                    Button("Add Day") { showDayPicker = true }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            Text("Select one day and one time slot for your reservation")
                .font(.caption)
                .foregroundColor(.secondary)
            if dayTimeSlots.isEmpty {
                Text("No day selected. Click 'Add Day' to start scheduling.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                let weekdayOrder: [ReservationConfig.Weekday] = [
                    .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
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

    private var footerButtonsSection: some View {
        HStack {
            Spacer()
            Button("Cancel") { dismiss() }
                .buttonStyle(.bordered)
            Button(config == nil ? "Add" : "Save") {
                validateAll()
                if validationErrors.isEmpty {
                    saveConfiguration()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!validationErrors.isEmpty)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
    }

    // MARK: - Private Methods

    /**
     Loads the configuration from the provided `config` object.
     - Parameter config: The existing configuration to load.
     */
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

    /**
     Saves the current configuration to the `onSave` closure.
     - Returns: Void
     */
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

    /**
     Checks if the current configuration is valid.
     - Returns: Bool indicating if the configuration is valid.
     */
    private var isValidConfiguration: Bool {
        !name.isEmpty &&
            isValidFacilityURL(facilityURL) &&
            !sportName.isEmpty &&
            !dayTimeSlots.isEmpty
    }

    /**
     Validates the facility URL.
     - Parameter url: The URL string to validate.
     - Returns: Bool indicating if the URL is valid.
     */
    private func isValidFacilityURL(_ url: String) -> Bool {
        let pattern = #"^https://reservation\.frontdesksuite\.ca/rcfs/[^/]+/?$"#
        return url.range(of: pattern, options: .regularExpression) != nil
    }

    /**
     Extracts the facility name from a URL string.
     - Parameter url: The URL string.
     - Returns: The extracted facility name.
     */
    private func extractFacilityName(from url: String) -> String {
        let pattern = #"https://reservation\.frontdesksuite\.ca/rcfs/([^/]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsrange = NSRange(url.startIndex ..< url.endIndex, in: url)
            if
                let match = regex.firstMatch(in: url, options: [], range: nsrange),
                let facilityRange = Range(match.range(at: 1), in: url) {
                let facilityName = String(url[facilityRange])
                return facilityName.capitalized
            }
        }
        return ""
    }

    /**
     Updates the configuration name based on the facility URL and sport name.
     - Returns: Void
     */
    private func updateConfigurationName() {
        // Only update the name if we're creating a new configuration or if the name is empty
        // This preserves custom names when editing existing configurations
        if !isEditingExistingConfig || name.isEmpty {
            let facilityName = extractFacilityName(from: facilityURL)
            name = "\(facilityName) - \(sportName)"
        }
    }

    /**
     Fetches available sports from the facility URL.
     - Returns: Void
     */
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

    /**
     Adds a default time slot for a given day.
     - Parameter day: The day to add the time slot for.
     - Returns: Void
     */
    private func addTimeSlot(for day: ReservationConfig.Weekday) {
        if dayTimeSlots[day] == nil {
            let defaultTime = Self.normalizeTime(hour: 18, minute: 0)
            dayTimeSlots[day] = [defaultTime]
        }
        // Only allow one timeslot per day - no additional timeslots
    }

    /**
     Finds an available time slot for a given day.
     - Parameter day: The day to find an available time for.
     - Returns: The available time slot.
     */
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

    /**
     Removes a day from the configuration.
     - Parameter day: The day to remove.
     - Returns: Void
     */
    private func removeDay(_ day: ReservationConfig.Weekday) {
        dayTimeSlots.removeValue(forKey: day)
    }

    /**
     Normalizes a given hour and minute into a Date object.
     - Parameter hour: The hour to set.
     - Parameter minute: The minute to set.
     - Returns: The normalized Date object.
     */
    static func normalizeTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
    }

    /**
     Validates all fields in the configuration and updates the validationErrors array.
     - Returns: Void
     */
    private func validateAll() {
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
        // Add more field checks as needed
        validationErrors = errors
    }

    /**
     Loads the configuration from an imported JSON file.
     - Parameter imported: The imported configuration object.
     - Returns: Void
     */
    private func loadFromImportedConfig(_ imported: ReservationConfig) {
        name = imported.name
        facilityURL = imported.facilityURL
        sportName = imported.sportName
        numberOfPeople = imported.numberOfPeople
        isEnabled = imported.isEnabled
        // Convert [TimeSlot] to [Date]
        dayTimeSlots = imported.dayTimeSlots.mapValues { $0.map(\.time) }
        validateAll()
    }

    /**
     Returns the current configuration object for export.
     - Returns: The ReservationConfig object.
     */
    private func currentConfigForExport() -> ReservationConfig {
        ReservationConfig(
            id: config?.id ?? UUID(),
            name: name,
            facilityURL: facilityURL,
            sportName: sportName,
            numberOfPeople: numberOfPeople,
            isEnabled: isEnabled,
            dayTimeSlots: dayTimeSlots.mapValues { $0.map { TimeSlot(time: $0) } },
            )
    }
}

/**
 A default time slot for a reservation configuration.
 - Returns: The default Date object.
 */
private func defaultTime() -> Date {
    Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
}

// MARK: - DayPickerView

/**
 A view for selecting days for a reservation configuration.
 */
struct DayPickerView: View {
    let selectedDays: Set<ReservationConfig.Weekday>
    let onAdd: (ReservationConfig.Weekday) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettingsManager = UserSettingsManager.shared

    var availableDays: [ReservationConfig.Weekday] {
        // Only show days if no day is currently selected (restrict to one day)
        if selectedDays.isEmpty {
            return ReservationConfig.Weekday.allCases
        } else {
            return []
        }
    }

    var body: some View {
        VStack {
            Text("Add Day")
                .font(.headline)
                .padding()

            if availableDays.isEmpty {
                Text("A day is already selected. Remove the current day to select a different one.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
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
            }

            HStack {
                Spacer()
                Button("Cancel") {
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

/**
 A view for picking time slots for a specific day.
 */
struct TimeSlotPickerView: View {
    @Binding var slots: [Date]
    let maxSlots = 1

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(slots.indices, id: \.self) { idx in
                HStack {
                    DatePicker(
                        "Time Slot",
                        selection: Binding(
                            get: { slots[idx] },
                            set: { newValue in
                                slots[idx] = newValue
                            },
                            ),
                        displayedComponents: .hourAndMinute,
                        )
                    .labelsHidden()
                }
            }
        }
    }
}

/**
 A document for exporting a reservation configuration to a JSON file.
 */
struct ExportConfigDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var configuration: ReservationConfig
    init(configuration: ReservationConfig) {
        self.configuration = configuration
    }

    init(configuration: FileDocumentReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        self.configuration = try JSONDecoder().decode(ReservationConfig.self, from: data)
    }

    func fileWrapper(configuration _: FileDocumentWriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(self.configuration)
        return .init(regularFileWithContents: data)
    }
}
