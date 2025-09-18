import SwiftUI
import UniformTypeIdentifiers
import os

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
      VStack(spacing: AppConstants.spacingNone) {
        // Add header for Add/Edit Configuration page, styled like SettingsHeader.
        HStack(spacing: AppConstants.spacingLarge) {
          Image(systemName: AppConstants.SFSymbols.app)
            .font(.title3)
            .foregroundColor(.accentColor)
          Text(config == nil ? "Add Configuration" : "Edit Configuration")
            .font(.title3)
            .fontWeight(.semibold)
          Spacer()
        }
        .padding(.horizontal, AppConstants.screenPadding)
        .padding(.vertical, AppConstants.contentPadding)
        .onAppear {
          let logger = Logger(
            subsystem: AppConstants.loggingSubsystem, category: "ConfigurationDetailView")
          logger.debug("🔍 facilityURL.isEmpty: \(facilityURL.isEmpty ? 1 : 0, privacy: .public).")
          logger.debug(
            "🔍 isValidFacilityURL result: \(isValidFacilityURL(facilityURL) ? 1 : 0, privacy: .public)."
          )
        }
        HeaderFooterDivider()
        if !validationErrors.isEmpty {
          HStack {
            Image(systemName: AppConstants.SFSymbols.warningFill).foregroundColor(.odysseyWarning)
            Text(validationErrors.first ?? "Validation error.")
              .foregroundColor(.odysseyWarning)
              .font(.footnote)
            Spacer()
          }
          .padding(.horizontal, AppConstants.contentPadding)
          .padding(.top, AppConstants.paddingTiny)
        }
        ScrollView {
          VStack(alignment: .leading, spacing: AppConstants.spacingNone) {
            basicSettingsSection
              .padding(.vertical, AppConstants.sectionDividerSpacing)
            // No background to avoid double-layer gray; window already provides material
            SectionDivider()
            sportPickerSection
              .padding(.vertical, AppConstants.sectionDividerSpacing)
            // No background to avoid double-layer gray; window already provides material
            SectionDivider()
            numberOfPeopleSection
              .padding(.vertical, AppConstants.sectionDividerSpacing)
            // No background to avoid double-layer gray; window already provides material
            SectionDivider()
            configNameSection
              .padding(.vertical, AppConstants.sectionDividerSpacing)
            // No background to avoid double-layer gray; window already provides material
            SectionDivider()
            schedulingSection
              .padding(.vertical, AppConstants.sectionDividerSpacing)
            // No background to avoid double-layer gray; window already provides material
            if !detectedConflicts.isEmpty {
              SectionDivider()
              conflictDetectionSection
                .padding(.vertical, AppConstants.sectionDividerSpacing)
              // No background to avoid double-layer gray; window already provides material
            }
          }
          .padding(.horizontal, AppConstants.screenPadding)
        }
        HeaderFooterDivider()
        footerButtonsSection
      }
    }
    .odysseyWindowBackground()
    .frame(width: AppConstants.windowMainWidth, height: AppConstants.windowMainHeight)
    .navigationTitle(
      config == nil ? "Add Reservation Configuration" : "Edit Reservation Configuration",
    )
    .alert("Validation Error", isPresented: $showingValidationAlert) {
      Button("OK") {}
    } message: {
      Text(validationMessage)
    }
    .alert("Configuration Conflicts Detected", isPresented: $showingConflictAlert) {
      Button("Review Conflicts") {}
      Button("Save Anyway", role: .destructive) {
        let convertedSlots: [ReservationConfig.Weekday: [TimeSlot]] =
          dayTimeSlots
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
      Button("Cancel", role: .cancel) {}
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
      DayPickerView(
        selectedDays: Set(dayTimeSlots.keys),
        onAdd: { day in
          addTimeSlot(for: day)
        }
      )
      .presentationBackground(.ultraThinMaterial)
      .if(!NSWorkspace.shared.accessibilityDisplayShouldReduceMotion) { v in
        v.transition(.opacity)
      }
    }
  }

  private var basicSettingsSection: some View {
    VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
      Text("Facility URL")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(.odysseyText)
      TextField("Enter facility URL", text: $facilityURL)
        .textFieldStyle(.roundedBorder)
      if !facilityURL.isEmpty, !isValidFacilityURL(facilityURL) {
        HStack {
          Image(systemName: AppConstants.SFSymbols.warningFill)
            .foregroundColor(.odysseyWarning)
          HStack(spacing: AppConstants.spacingNone) {
            Text("Please enter a ")
              .font(.footnote)
              .foregroundColor(.odysseyWarning)
            Button("valid") {
              if let url = URL(string: AppConstants.ottawaFacilitiesURL) {
                NSWorkspace.shared.open(url)
              }
            }
            .buttonStyle(.plain)
            .foregroundColor(.odysseyPrimary)
            .font(.footnote)
            Text(" Ottawa Recreation URL.")
              .font(.footnote)
              .foregroundColor(.odysseyWarning)
          }
          Spacer()
        }
      }
      if facilityURL.isEmpty {
        HStack(spacing: AppConstants.spacingTiny) {
          Image(systemName: AppConstants.SFSymbols.warningFill)
            .foregroundColor(.odysseyWarning)
          Text("Please enter your facility URL.")
            .font(.footnote)
            .foregroundColor(.odysseyWarning)
          Spacer()
        }
        .padding(.top, AppConstants.paddingTiny)
      }
    }

  }

  private var sportPickerSection: some View {
    VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
      Text("Sport Name")
        .font(.subheadline)
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
                    Image(systemName: AppConstants.SFSymbols.checkmark).foregroundColor(
                      .odysseyAccent)
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
            Image(systemName: AppConstants.SFSymbols.chevronDown).foregroundColor(
              .odysseySecondaryText
            )
            .font(.body)
          }
        }
        .accessibilityLabel("Select Sport")
        .disabled(availableSports.isEmpty)

        if !facilityURL.isEmpty, isValidFacilityURL(facilityURL) {
          Button(action: {
            fetchAvailableSports()
          }) {
            Image(
              systemName: isFetchingSports
                ? AppConstants.SFSymbols.refresh : AppConstants.SFSymbols.magnifyingglass)
          }
          .buttonStyle(.bordered)
          .disabled(isFetchingSports)
          .onAppear {
            let logger = Logger(
              subsystem: AppConstants.loggingSubsystem, category: "ConfigurationDetailView")
            logger.debug(
              "🔍 isValidFacilityURL: \(isValidFacilityURL(facilityURL) ? 1 : 0, privacy: .public).")
          }
        }
      }
      if isFetchingSports {
        HStack {
          ProgressView().scaleEffect(AppConstants.scaleEffectSmall)
          Text("Fetching available sports...").font(.footnote)
            .foregroundColor(.odysseySecondaryText)
        }
      }
      if !availableSports.isEmpty {
        Text("\(availableSports.count) sports found")
          .font(.footnote).foregroundColor(.odysseySecondaryText)
      }
      if validationErrors.contains(where: { $0.contains("Sport name") }) {
        HStack(spacing: AppConstants.spacingTiny) {
          Image(systemName: AppConstants.SFSymbols.warningFill)
            .foregroundColor(.odysseyWarning)
          Text("Sport name is required.")
            .font(.footnote)
            .foregroundColor(.odysseyWarning)
          Spacer()
        }
        .padding(.top, AppConstants.paddingTiny)
      }
    }

  }

  private var numberOfPeopleSection: some View {
    VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
      Text("Number of People")
        .font(.subheadline)
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

  }

  private var configNameSection: some View {
    VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
      Text("Configuration Name")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(.odysseyText)
      TextField("Configuration Name", text: $name)
        .textFieldStyle(.roundedBorder)
        .accessibilityLabel("Configuration Name")
        .onChange(of: name) { _, newValue in
          if newValue.count > 60 {
            name = String(newValue.prefix(60))
          }
        }
    }

  }

  private var schedulingSection: some View {
    VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
      HStack {
        Text("Time Slot")
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(.odysseyText)
        Spacer()
        if dayTimeSlots.isEmpty {
          Button("Add Day") { showDayPicker = true }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
      }
      Text("Select one day and one time slot for your reservation.")
        .font(.body)
        .foregroundColor(.odysseySecondaryText)
      if dayTimeSlots.isEmpty {
        Text("No day selected. Click 'Add Day' to start scheduling.")
          .font(.body)
          .foregroundColor(.odysseySecondaryText)
          .padding(.vertical, AppConstants.paddingSmall)
      } else {
        let weekdayOrder: [ReservationConfig.Weekday] = [
          .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
        ]
        ForEach(
          Array(
            dayTimeSlots.keys.sorted { lhs, rhs in
              guard
                let lhsIndex = weekdayOrder.firstIndex(of: lhs),
                let rhsIndex = weekdayOrder.firstIndex(of: rhs)
              else { return false }
              return lhsIndex < rhsIndex
            }), id: \.self
        ) { day in
          VStack(alignment: .leading) {
            HStack {
              Text(day.localizedShortName)
                .font(.subheadline)
                .foregroundColor(.odysseyText)
              Spacer()
              Button(action: { removeDay(day) }) {
                Image(systemName: AppConstants.SFSymbols.xmarkCircleFill)
                  .foregroundColor(.odysseyError)
              }
              .buttonStyle(.bordered)
              .tint(.odysseyError)
            }
            TimeSlotPickerView(
              slots: Binding(
                get: { dayTimeSlots[day] ?? [defaultTime()] },
                set: { newValue in dayTimeSlots[day] = newValue },
              ))
          }
          .padding(.vertical, AppConstants.paddingTiny)
        }
      }
    }

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
    .padding(.horizontal, AppConstants.screenPadding)
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

    // Don't update the name when editing an existing configuration.
    // to preserve custom names that users have set.
  }

  /**
   Saves the current configuration to the `onSave` closure.
   - Returns: Void
   */
  private func saveConfiguration() {
    let convertedSlots: [ReservationConfig.Weekday: [TimeSlot]] =
      dayTimeSlots
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
    let existingConfigs = configurationManager.settings.configurations.filter {
      $0.id != newConfig.id
    }
    let conflicts = conflictDetectionService.validateNewConfiguration(
      newConfig, against: existingConfigs)

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
   Trims a facility URL to remove everything after the facility name.
   - Parameter url: The URL string to trim.
   - Returns: The trimmed URL string.
   */
  private func trimFacilityURL(_ url: String) -> String {
    guard !url.isEmpty else { return url }

    // Pattern to match the base facility URL structure
    // This will capture: https://reservation.frontdesksuite.ca/rcfs/facility-name (with optional trailing slash)
    let pattern = #"^https://reservation\.frontdesksuite\.ca/rcfs/[^/]+/?$"#

    if let regex = try? NSRegularExpression(pattern: pattern) {
      let nsrange = NSRange(url.startIndex..<url.endIndex, in: url)
      if regex.firstMatch(in: url, options: [], range: nsrange) != nil {
        // If the URL already matches the expected pattern, return it as is
        return url
      }
    }

    // If the URL doesn't match the expected pattern, try to extract the base URL
    let basePattern = #"^https://reservation\.frontdesksuite\.ca/rcfs/[^/]+"#
    if let regex = try? NSRegularExpression(pattern: basePattern) {
      let nsrange = NSRange(url.startIndex..<url.endIndex, in: url)
      if let match = regex.firstMatch(in: url, options: [], range: nsrange) {
        let trimmedURL = String(url[Range(match.range, in: url)!])
        Logger(subsystem: AppConstants.loggingSubsystem, category: "ConfigurationDetailView")
          .info("✂️ Trimmed facility URL from '\(url)' to '\(trimmedURL)'.")
        return trimmedURL
      }
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
    Logger(subsystem: AppConstants.loggingSubsystem, category: "ConfigurationDetailView")
      .debug(
        "🔍 isValidFacilityURL check - URL: '\(url, privacy: .public)', Pattern: '\(pattern, privacy: .public)', Result: \(isValid ? 1 : 0, privacy: .public)."
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

  /**
   Updates the configuration name based on the facility URL and sport name.
   - Returns: Void
   */
  private func updateConfigurationName() {

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

    Logger(subsystem: AppConstants.loggingSubsystem, category: "ConfigurationDetailView")
      .debug(
        "🔍 fetchAvailableSports() proceeding with URL: \(url.absoluteString, privacy: .public)")

    isFetchingSports = true
    availableSports = []

    let facilityService = FacilityService()
    facilityService.fetchSports(from: url) { sports in
      DispatchQueue.main.async {
        Logger(subsystem: AppConstants.loggingSubsystem, category: "ConfigurationDetailView")
          .debug("🔍 fetchAvailableSports() completed with \(sports.count, privacy: .public) sports")
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

  }

  /**
   Finds an available time slot for a given day.
   - Parameter day: The day to find an available time for.
   - Returns: The available time slot.
   */
  private func findAvailableTime(for day: ReservationConfig.Weekday) -> Date? {
    guard let existingSlots = dayTimeSlots[day], let firstSlot = existingSlots.first else {
      return nil
    }

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

    for hour in (firstSlotHour + 1)...22 {
      if !existingHours.contains(hour) {
        return Self.normalizeTime(hour: hour, minute: 0)
      }
    }

    for hour in 9...22 {
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
        Image(systemName: AppConstants.SFSymbols.warningFill)
          .foregroundColor(.odysseyWarning)
        Text("Potential Conflicts")
          .font(.title3)
          .fontWeight(.semibold)
        Spacer()
      }

      ForEach(detectedConflicts) { conflict in
        VStack(alignment: .leading, spacing: AppConstants.spacingTiny) {
          HStack {
            Image(systemName: severityIcon(for: conflict.severity))
              .foregroundColor(severityColor(for: conflict.severity))
            Text(conflict.type.rawValue)
              .font(.subheadline)
              .fontWeight(.medium)
            Spacer()
            Text(conflict.severity.rawValue)
              .font(.footnote)
              .foregroundColor(severityColor(for: conflict.severity))
          }

          Text(conflict.message)
            .font(.subheadline)
            .foregroundColor(.odysseySecondaryText)

          ForEach(conflict.details, id: \.self) { detail in
            Text("• \(detail)")
              .font(.footnote)
              .foregroundColor(.odysseySecondaryText)
          }
        }
        .padding(AppConstants.paddingSmall)
        .overlay(
          RoundedRectangle(cornerRadius: AppConstants.cornerRadiusSmall)
            .stroke(
              severityColor(for: conflict.severity).opacity(0.2),
              lineWidth: AppConstants.strokeWidthThin
            )
        )
      }
    }
  }

  private func severityIcon(for severity: ConflictSeverity) -> String {
    switch severity {
    case .critical:
      return AppConstants.SFSymbols.xmarkCircleFill
    case .warning:
      return AppConstants.SFSymbols.warningFill
    case .info:
      return AppConstants.SFSymbols.infoCircleFill
    }
  }

  private func severityColor(for severity: ConflictSeverity) -> Color {
    switch severity {
    case .critical:
      return .odysseyError
    case .warning:
      return .odysseyWarning
    case .info:
      return .odysseyInfo
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

    let existingConfigs = configurationManager.settings.configurations.filter {
      $0.id != tempConfig.id
    }
    detectedConflicts = conflictDetectionService.validateNewConfiguration(
      tempConfig, against: existingConfigs)
  }
}

/// A default time slot for a reservation configuration.
/// - Returns: The default Date object.
private func defaultTime() -> Date {
  Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
}

// MARK: - DayPickerView

/// A view for selecting days for a reservation configuration.
struct DayPickerView: View {
  let selectedDays: Set<ReservationConfig.Weekday>
  let onAdd: (ReservationConfig.Weekday) -> Void
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var userSettingsManager = UserSettingsManager.shared

  var availableDays: [ReservationConfig.Weekday] {

    if selectedDays.isEmpty {
      return ReservationConfig.Weekday.allCases
    } else {
      return []
    }
  }

  var body: some View {
    VStack {
      Text("Add Day")
        .font(.subheadline)
        .padding(AppConstants.contentPadding)

      if availableDays.isEmpty {
        Text("A day is already selected. Remove the current day to select a different one.")
          .font(.footnote)
          .foregroundColor(.odysseySecondaryText)
          .padding(AppConstants.contentPadding)
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
              Image(systemName: AppConstants.SFSymbols.plusCircle)
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
        .padding(AppConstants.contentPadding)
      }
    }
    .frame(width: AppConstants.windowDayPickerWidth, height: AppConstants.windowDayPickerHeight)
  }
}

// MARK: - TimeSlotPickerView

/// A view for picking time slots for a specific day.
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
          .controlSize(.small)
        }
      }
    }
  }
}

/// A document for exporting a reservation configuration to a JSON file.
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
