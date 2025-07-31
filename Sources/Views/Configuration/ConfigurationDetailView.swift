import os.log
import SwiftUI
import UniformTypeIdentifiers

/// A detailed view for editing or creating a reservation configuration.
struct ConfigurationDetailView: View {
    let config: ReservationConfig?
    let onSave: (ReservationConfig) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var configurationManager = ConfigurationManager.shared
    @ObservedObject var userSettingsManager = UserSettingsManager.shared

    @State private var name = ""
    @State private var facilityURL = ""
    @State private var sportName = ""
    @State private var numberOfPeople: Int = AppConstants.defaultNumberOfPeople
    @State private var isEnabled = true
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
    let configurationValidator = ConfigurationValidator.shared

    // Conflict detection
    @StateObject private var conflictDetectionService = ConflictDetectionService.shared
    @State private var detectedConflicts: [ReservationConflict] = []
    @State private var showingConflictAlert = false

    var body: some View {
        ZStack {
            Color.odysseyBackground.ignoresSafeArea()
            VStack(spacing: AppConstants.spacingNone) {
                // Add header for Add/Edit Configuration page, styled like SettingsHeader.
                HStack(spacing: AppConstants.spacingLarge) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: AppConstants.primaryFont))
                        .foregroundColor(.accentColor)
                    Text(config == nil ? "Add Configuration" : "Edit Configuration")
                        .font(.system(size: AppConstants.primaryFont))
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, AppConstants.contentPadding)
                .padding(.vertical, AppConstants.contentPadding)
                .onAppear {
                    os_log(
                        "🔍 facilityURL.isEmpty: %{public}d",
                        log: .default,
                        type: .debug,
                        facilityURL.isEmpty ? 1 : 0,
                        )
                    os_log(
                        "🔍 isValidFacilityURL result: %{public}d",
                        log: .default,
                        type: .debug,
                        isValidFacilityURL(facilityURL) ? 1 : 0,
                        )
                }
                HeaderFooterDivider()
                if !validationErrors.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.odysseyWarning)
                        Text(validationErrors.first ?? "Validation error.")
                            .foregroundColor(.odysseyWarning)
                            .font(.system(size: AppConstants.secondaryFont))
                        Spacer()
                    }
                    .padding(.horizontal, AppConstants.sectionPadding)
                    .padding(.top, AppConstants.paddingTiny)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: AppConstants.spacingNone) {
                        basicSettingsSection
                        sportPickerSection
                        numberOfPeopleSection
                        configNameSection
                        Divider().padding(.vertical, AppConstants.paddingSmall)
                        schedulingSection
                        if !detectedConflicts.isEmpty {
                            Divider().padding(.vertical, AppConstants.paddingSmall)
                            conflictDetectionSection
                        }
                    }
                    .padding(.horizontal, AppConstants.sectionPadding)
                    .padding(.vertical, AppConstants.sectionPadding)
                }
                HeaderFooterDivider()
                footerButtonsSection
            }
        }
        .frame(width: AppConstants.windowMainWidth, height: AppConstants.windowMainHeight)
        .navigationTitle(
            config == nil ? "Add Reservation Configuration" : "Edit Reservation Configuration",
            )
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
        .alert("Configuration Conflicts Detected", isPresented: $showingConflictAlert) {
            Button("Review Conflicts") { }
            Button("Save Anyway", role: .destructive) {
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
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(conflictDetectionService.getConflictSummary(detectedConflicts))
        }
        .onAppear {
            if !didInitializeSlots {
                dayTimeSlots = config?.dayTimeSlots.mapValues { $0.map(\.time) } ?? [:]
                didInitializeSlots = true
            }
            loadConfiguration()
            updateConflicts()
        }
        .onChange(of: dayTimeSlots) {
            updateConflicts()
        }
        .onChange(of: facilityURL) { _, newValue in
            // Automatically trim the URL if it contains Home/...
            let trimmedURL = trimFacilityURL(newValue)
            if trimmedURL != newValue {
                facilityURL = trimmedURL
            }
            updateConfigurationName()
            updateConflicts()
        }
        .sheet(isPresented: $showDayPicker) {
            DayPickerView(selectedDays: Set(dayTimeSlots.keys), onAdd: { day in
                addTimeSlot(for: day)
            })
        }
    }

    private var basicSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
            Text("Facility URL")
                .font(.system(size: AppConstants.secondaryFont))
                .fontWeight(.semibold)
                .foregroundColor(.odysseyText)
            TextField("Enter facility URL", text: $facilityURL)
            if !facilityURL.isEmpty, !isValidFacilityURL(facilityURL) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.odysseyWarning)
                    HStack(spacing: AppConstants.spacingNone) {
                        Text("Please enter a ")
                            .font(.system(size: AppConstants.fontBody))
                            .foregroundColor(.odysseyWarning)
                        Button("valid") {
                            if let url = URL(string: AppConstants.ottawaFacilitiesURL) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.odysseyPrimary)
                        .font(.system(size: AppConstants.fontBody))
                        Text(" Ottawa Recreation URL.")
                            .font(.system(size: AppConstants.fontBody))
                            .foregroundColor(.odysseyWarning)
                    }
                    Spacer()
                }
            }
            if facilityURL.isEmpty {
                HStack(spacing: AppConstants.spacingTiny) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.odysseyWarning)
                    Text("Please enter your facility URL.")
                        .font(.system(size: AppConstants.fontBody))
                        .foregroundColor(.odysseyWarning)
                    Spacer()
                }
                .padding(.top, AppConstants.paddingTiny)
            }
        }
        .padding(.bottom, AppConstants.contentPadding)
    }

    private var sportPickerSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
            Text("Sport Name")
                .font(.system(size: AppConstants.secondaryFont))
                .fontWeight(.semibold)
                .foregroundColor(.odysseyText)
            HStack {
                Menu {
                    if availableSports.isEmpty {
                        Text("No sports available")
                            .foregroundColor(.odysseySecondaryText)
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
                                        Image(systemName: "checkmark").foregroundColor(.odysseyAccent)
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(sportName.isEmpty ? "Select Sport" : sportName)
                            .foregroundColor(sportName.isEmpty ? .odysseySecondaryText : .odysseyText)
                        Spacer()
                        Image(systemName: "chevron.down").foregroundColor(.odysseySecondaryText)
                            .font(.system(size: AppConstants.fontBody))
                    }
                }
                .accessibilityLabel("Select Sport")
                .disabled(availableSports.isEmpty)

                if !facilityURL.isEmpty, isValidFacilityURL(facilityURL) {
                    Button(action: {
                        fetchAvailableSports()
                    }) {
                        Image(systemName: isFetchingSports ? "arrow.clockwise" : "magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isFetchingSports)
                    .onAppear {
                        os_log(
                            "🔍 isValidFacilityURL: %{public}d",
                            log: .default,
                            type: .debug,
                            isValidFacilityURL(facilityURL) ? 1 : 0,
                            )
                    }
                }
            }
            if isFetchingSports {
                HStack {
                    ProgressView().scaleEffect(AppConstants.scaleEffectSmall)
                    Text("Fetching available sports...").font(.system(size: AppConstants.fontBody))
                        .foregroundColor(.odysseySecondaryText)
                }
            }
            if !availableSports.isEmpty {
                Text("\(availableSports.count) sports found")
                    .font(.system(size: AppConstants.fontBody)).foregroundColor(.odysseySecondaryText)
            }
            if validationErrors.contains(where: { $0.contains("Sport name") }) {
                HStack(spacing: AppConstants.spacingTiny) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.odysseyWarning)
                    Text("Sport name is required.")
                        .font(.system(size: AppConstants.fontBody))
                        .foregroundColor(.odysseyWarning)
                    Spacer()
                }
                .padding(.top, AppConstants.paddingTiny)
            }
        }
        .padding(.bottom, AppConstants.contentPadding)
    }

    private var numberOfPeopleSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
            Text("Number of People")
                .font(.system(size: AppConstants.secondaryFont))
                .fontWeight(.semibold)
                .foregroundColor(.odysseyText)
            HStack(spacing: AppConstants.sectionSpacing) {
                Button(action: {
                    numberOfPeople = AppConstants.defaultNumberOfPeople
                    updateConfigurationName()
                }) {
                    HStack {
                        Image(systemName: numberOfPeople == 1 ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(numberOfPeople == 1 ? .odysseyAccent : .odysseySecondaryText)
                        Text("1 Person").foregroundColor(.odysseyText)
                    }
                }.buttonStyle(.bordered)
                .controlSize(.regular)
                Button(action: {
                    numberOfPeople = 2
                    updateConfigurationName()
                }) {
                    HStack {
                        Image(systemName: numberOfPeople == 2 ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(numberOfPeople == 2 ? .odysseyAccent : .odysseySecondaryText)
                        Text("2 People").foregroundColor(.odysseyText)
                    }
                }.buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding(.bottom, AppConstants.contentPadding)
    }

    private var configNameSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
            Text("Configuration Name")
                .font(.system(size: AppConstants.secondaryFont))
                .fontWeight(.semibold)
                .foregroundColor(.odysseyText)
            TextField("Configuration Name", text: $name)
                .accessibilityLabel("Configuration Name")
                .onChange(of: name) { _, newValue in
                    if newValue.count > 60 {
                        name = String(newValue.prefix(60))
                    }
                }
        }
        .padding(.bottom, AppConstants.contentPadding)
    }

    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
            HStack {
                Text("Time Slot")
                    .font(.system(size: AppConstants.secondaryFont))
                    .fontWeight(.semibold)
                    .foregroundColor(.odysseyText)
                Spacer()
                if dayTimeSlots.isEmpty {
                    Button("Add Day") { showDayPicker = true }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                }
            }
            Text("Select one day and one time slot for your reservation")
                .font(.system(size: AppConstants.fontBody))
                .foregroundColor(.odysseySecondaryText)
            if dayTimeSlots.isEmpty {
                Text("No day selected. Click 'Add Day' to start scheduling.")
                    .font(.system(size: AppConstants.fontBody))
                    .foregroundColor(.odysseySecondaryText)
                    .padding(.vertical, AppConstants.paddingSmall)
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
                                .font(.system(size: AppConstants.secondaryFont))
                                .foregroundColor(.odysseyText)
                            Spacer()
                            Button(action: { removeDay(day) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.odysseyError)
                            }
                            .buttonStyle(.bordered)
                        }
                        TimeSlotPickerView(slots: Binding(
                            get: { dayTimeSlots[day] ?? [defaultTime()] },
                            set: { newValue in dayTimeSlots[day] = newValue },
                            ))
                    }
                    .padding(.vertical, AppConstants.paddingTiny)
                }
            }
        }
        .padding(.bottom, AppConstants.contentPadding)
    }

    private var footerButtonsSection: some View {
        HStack {
            Spacer()
            Button("Cancel") { dismiss() }
                .accessibilityLabel("Cancel")
                .keyboardShortcut(.escape)
                .buttonStyle(.bordered)
            Button(config == nil ? "Add" : "Save") {
                saveConfiguration()
            }
            .accessibilityLabel("Save Configuration")
            .keyboardShortcut("s", modifiers: .command)
            .buttonStyle(.borderedProminent)
            .disabled(!isValidConfiguration)
        }
        .padding(.horizontal, AppConstants.sectionPadding)
        .padding(.vertical, AppConstants.buttonPadding)
    }

    // MARK: - Private Methods

    /**
     Loads the configuration from the provided `config` object.
     - Parameter config: The existing configuration to load.
     */
    private func loadConfiguration() {
        guard let config else {
            // Creating a new configuration.
            isEditingExistingConfig = false
            return
        }

        // Editing an existing configuration.
        isEditingExistingConfig = true
        name = config.name
        facilityURL = config.facilityURL
        sportName = config.sportName
        numberOfPeople = config.numberOfPeople
        isEnabled = config.isEnabled

        // Don't update the name when editing an existing configuration
        // to preserve custom names that users have set.
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

        // Validate configuration before saving
        let validationResult = configurationValidator.validateReservationConfig(newConfig)
        if !validationResult.isValid {
            validationErrors = validationResult.errors
            showingValidationAlert = true
            validationMessage = validationResult.errorMessage
            return
        }

        // Check for conflicts with existing configurations
        let existingConfigs = configurationManager.settings.configurations.filter { $0.id != newConfig.id }
        let conflicts = conflictDetectionService.validateNewConfiguration(newConfig, against: existingConfigs)

        if !conflicts.isEmpty {
            detectedConflicts = conflicts
            showingConflictAlert = true
            return
        }

        onSave(newConfig)
        dismiss()
    }

    /**
     Checks if the current configuration is valid.
     - Returns: Bool indicating if the configuration is valid.
     */
    private var isValidConfiguration: Bool {
        let tempConfig = ReservationConfig(
            id: config?.id ?? UUID(),
            name: name,
            facilityURL: facilityURL,
            sportName: sportName,
            numberOfPeople: numberOfPeople,
            isEnabled: isEnabled,
            dayTimeSlots: dayTimeSlots.mapValues { $0.map { TimeSlot(time: $0) } },
            )

        let validationResult = configurationValidator.validateReservationConfig(tempConfig)
        validationErrors = validationResult.errors
        return validationResult.isValid
    }

    /**
     Trims a facility URL to remove everything from Home/... onwards.
     - Parameter url: The URL string to trim.
     - Returns: The trimmed URL string.
     */
    private func trimFacilityURL(_ url: String) -> String {
        guard !url.isEmpty else { return url }

        // Find the position of "Home/..." in the URL.
        if let homeIndex = url.range(of: "Home")?.lowerBound {
            // Return everything up to (but not including) "Home/...".
            let trimmedURL = String(url[..<homeIndex])
            Logger(subsystem: "com.odyssey.app", category: "ConfigurationDetailView")
                .info("✂️ Trimmed facility URL from '\(url)' to '\(trimmedURL)'.")
            return trimmedURL
        }

        return url
    }

    /**
     Validates if a URL string is a valid facility URL.
     - Parameter url: The URL string to validate.
     - Returns: Bool indicating if the URL is valid.
     */
    private func isValidFacilityURL(_ url: String) -> Bool {
        let pattern = #"^https://reservation\.frontdesksuite\.ca/rcfs/[^/]+/?$"#
        let isValid = url.range(of: pattern, options: .regularExpression) != nil
        os_log(
            "🔍 isValidFacilityURL check - URL: '%{public}@', Pattern: '%{public}@', Result: %{public}d",
            log: .default,
            type: .debug,
            url,
            pattern,
            isValid ? 1 : 0,
            )
        return isValid
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
                let facilityRange = Range(match.range(at: 1), in: url)
            {
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
        // Only update the name if we're creating a new configuration or if the name is empty.
        // This preserves custom names when editing existing configurations.
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
        guard !facilityURL.isEmpty, isValidFacilityURL(facilityURL) else {
            return
        }

        guard let url = URL(string: facilityURL) else {
            isFetchingSports = false
            return
        }

        os_log(
            "🔍 fetchAvailableSports() proceeding with URL: %{public}@",
            log: .default,
            type: .debug,
            url.absoluteString,
            )

        isFetchingSports = true
        availableSports = []

        let facilityService = FacilityService()
        facilityService.fetchSports(from: url) { sports in
            DispatchQueue.main.async {
                os_log(
                    "🔍 fetchAvailableSports() completed with %{public}d sports",
                    log: .default,
                    type: .debug,
                    sports.count,
                    )
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
        // Only allow one timeslot per day - no additional timeslots.
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
        // Convert [TimeSlot] to [Date].
        dayTimeSlots = imported.dayTimeSlots.mapValues { $0.map(\.time) }
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

    private var conflictDetectionSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacingMedium) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Potential Conflicts")
                    .font(.system(size: AppConstants.primaryFont))
                    .fontWeight(.semibold)
                Spacer()
            }

            ForEach(detectedConflicts) { conflict in
                VStack(alignment: .leading, spacing: AppConstants.spacingTiny) {
                    HStack {
                        Image(systemName: severityIcon(for: conflict.severity))
                            .foregroundColor(severityColor(for: conflict.severity))
                        Text(conflict.type.rawValue)
                            .font(.system(size: AppConstants.secondaryFont))
                            .fontWeight(.medium)
                        Spacer()
                        Text(conflict.severity.rawValue)
                            .font(.system(size: AppConstants.tertiaryFont))
                            .foregroundColor(severityColor(for: conflict.severity))
                    }

                    Text(conflict.message)
                        .font(.system(size: AppConstants.secondaryFont))
                        .foregroundColor(.odysseySecondaryText)

                    ForEach(conflict.details, id: \.self) { detail in
                        Text("• \(detail)")
                            .font(.system(size: AppConstants.tertiaryFont))
                            .foregroundColor(.odysseySecondaryText)
                    }
                }
                .padding(AppConstants.paddingSmall)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadiusSmall)
                        .fill(severityColor(for: conflict.severity).opacity(0.1)),
                    )
            }
        }
    }

    private func severityIcon(for severity: ConflictSeverity) -> String {
        switch severity {
        case .critical:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    private func severityColor(for severity: ConflictSeverity) -> Color {
        switch severity {
        case .critical:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        }
    }

    private func updateConflicts() {
        let tempConfig = ReservationConfig(
            id: config?.id ?? UUID(),
            name: name,
            facilityURL: facilityURL,
            sportName: sportName,
            numberOfPeople: numberOfPeople,
            isEnabled: isEnabled,
            dayTimeSlots: dayTimeSlots.mapValues { $0.map { TimeSlot(time: $0) } },
            )

        let existingConfigs = configurationManager.settings.configurations.filter { $0.id != tempConfig.id }
        detectedConflicts = conflictDetectionService.validateNewConfiguration(tempConfig, against: existingConfigs)
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
    @ObservedObject var userSettingsManager = UserSettingsManager.shared

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
                .padding(AppConstants.sectionPadding)

            if availableDays.isEmpty {
                Text("A day is already selected. Remove the current day to select a different one.")
                    .font(.system(size: AppConstants.fontCaption))
                    .foregroundColor(.odysseySecondaryText)
                    .padding(AppConstants.sectionPadding)
            } else {
                List(availableDays, id: \.self) { day in
                    Button(action: {
                        onAdd(day)
                        dismiss()
                    }) {
                        HStack {
                            Text(day.localizedShortName)
                                .foregroundColor(.odysseyText)
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundColor(.odysseyAccent)
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
                .padding(AppConstants.sectionPadding)
            }
        }
        .frame(width: AppConstants.windowDayPickerWidth, height: AppConstants.windowDayPickerHeight)
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
