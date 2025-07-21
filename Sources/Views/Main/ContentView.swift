import SwiftUI

// MARK: - Main Content View

struct ContentView: View {
    @StateObject private var configManager = ConfigurationManager.shared
    @StateObject private var reservationManager = ReservationManager.shared
    @StateObject private var userSettingsManager = UserSettingsManager.shared
    @State private var showingAddConfig = false
    @State private var selectedConfig: ReservationConfig?
    @State private var showingSettings = false
    @State private var showingAbout = false
    @State private var showingGodMode = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            mainContentView
            Divider()
            footerView
        }
        .frame(width: 440, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingAddConfig) {
            ConfigurationDetailView(config: nil) { config in
                configManager.addConfiguration(config)
            }
        }
        .sheet(item: $selectedConfig) { config in
            ConfigurationDetailView(config: config) { updatedConfig in
                configManager.updateConfiguration(updatedConfig)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.clear)
        }
        .onKeyPress("g", phases: .down) { press in
            if press.modifiers.contains(.command) {
                showingGodMode.toggle()
                return .handled
            }
            return .ignored
        }
    }
}

// MARK: - Header View

private extension ContentView {
    var headerView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "sportscourt.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("ODYSSEY")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingAddConfig = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .help("Add new configuration")
            }

            if showingGodMode {
                HStack(spacing: 12) {
                    Spacer()
                    Button(action: simulateAutorunForToday) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                            Text("GOD MODE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
                    .controlSize(.small)
                    .help("Simulate autorun for 6pm today (⌘+G)")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    var mainContentView: some View {
        if configManager.settings.configurations.isEmpty {
            AnyView(emptyStateView)
        } else {
            AnyView(
                List {
                    ForEach(
                        Array(configManager.settings.configurations.enumerated()),
                        id: \.element.id,
                        ) { index, config in
                        ConfigurationRowView(
                            config: config,
                            nextAutorunInfo: getNextCronRunTime(for: config),
                            formatCountdown: formatCountdown,
                            onEdit: { selectedConfig = config },
                            onDelete: { configManager.removeConfiguration(config) },
                            onToggle: { configManager.toggleConfiguration(at: index) },
                            onRun: { reservationManager.runReservation(for: config, runType: .manual) },
                            )
                    }
                    .onDelete(perform: { indices in
                        for index in indices {
                            let config = configManager.settings.configurations[index]
                            configManager.removeConfiguration(config)
                        }
                    })
                }
                .listStyle(.inset),
                )
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Reservations Configured")
                .font(.title3)
                .fontWeight(.medium)
            Text(
                "Add your first reservation configuration to get started with automated booking.",
                )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            Button("Add Configuration") {
                showingAddConfig = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            Spacer()
        }
        .padding()
    }

    var footerView: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { showingSettings = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                        Text("Settings")
                            .font(.system(size: 13))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.regular)
                .help("Configure user settings and integrations")

                Spacer()

                Button(action: { showingAbout = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                        Text("About")
                            .font(.system(size: 13))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .help("About ODYSSEY")

                Spacer()

                Button(action: { NSApp.terminate(nil) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                            .font(.system(size: 14))
                        Text("Quit")
                            .font(.system(size: 13))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.regular)
                .help("Quit ODYSSEY")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 16)
        }
    }

    // Helper to get next autorun for a specific config
    func getNextCronRunTime(for config: ReservationConfig) -> NextAutorunInfo? {
        guard config.isEnabled else { return nil }
        let calendar = Calendar.current
        let now = Date()
        var nextCronTime: Date?
        var nextWeekday: ReservationConfig.Weekday?
        var nextTimeSlot: TimeSlot?
        for (weekday, timeSlots) in config.dayTimeSlots {
            for timeSlot in timeSlots {
                for weekOffset in 0 ... 4 {
                    let baseDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: now) ?? now
                    let reservationDay = getNextWeekday(weekday, from: baseDate)
                    let cronTime = calendar.date(byAdding: .day, value: -2, to: reservationDay) ?? reservationDay
                    let finalCronTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: cronTime) ?? cronTime
                    if finalCronTime > now {
                        if let currentNextCronTime = nextCronTime {
                            if finalCronTime < currentNextCronTime {
                                nextCronTime = finalCronTime
                                nextWeekday = weekday
                                nextTimeSlot = timeSlot
                            }
                        } else {
                            nextCronTime = finalCronTime
                            nextWeekday = weekday
                            nextTimeSlot = timeSlot
                        }
                        break
                    }
                }
            }
        }
        if let date = nextCronTime, let weekday = nextWeekday, let timeSlot = nextTimeSlot {
            return NextAutorunInfo(date: date, config: config, weekday: weekday, timeSlot: timeSlot)
        } else {
            return nil
        }
    }

    func getNextWeekday(_ weekday: ReservationConfig.Weekday, from date: Date) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        let targetWeekday = weekday.calendarWeekday
        var daysToAdd = targetWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
    }

    func formatCountdown(to targetDate: Date) -> String {
        let now = Date()
        let timeInterval = targetDate.timeIntervalSince(now)
        if timeInterval <= 0 {
            return "now"
        }
        let days = Int(timeInterval / 86_400)
        let hours = Int((timeInterval.truncatingRemainder(dividingBy: 86_400)) / 3_600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3_600)) / 60)
        if days > 0 {
            let daysText = days == 1 ? "day" : "days"
            let hoursText = hours == 1 ? "hour" : "hours"
            return "\(days) \(daysText), \(hours) \(hoursText)"
        } else if hours > 0 {
            let hoursText = hours == 1 ? "hour" : "hours"
            let minutesText = minutes == 1 ? "minute" : "minutes"
            return "\(hours) \(hoursText), \(minutes) \(minutesText)"
        } else {
            let minutesText = minutes == 1 ? "minute" : "minutes"
            return "\(minutes) \(minutesText)"
        }
    }

    func simulateAutorunForToday() {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)

        // Convert Calendar weekday to our Weekday enum
        let weekday: ReservationConfig.Weekday
        switch currentWeekday {
        case 1: weekday = .sunday
        case 2: weekday = .monday
        case 3: weekday = .tuesday
        case 4: weekday = .wednesday
        case 5: weekday = .thursday
        case 6: weekday = .friday
        case 7: weekday = .saturday
        default:
            return
        }

        let configsForToday = configManager.getConfigurationsForDay(weekday)
        let enabledConfigs = configsForToday.filter(\.isEnabled)

        if enabledConfigs.isEmpty {
            // If no enabled configs for today, run all enabled configs
            let allEnabledConfigs = configManager.settings.configurations.filter(\.isEnabled)
            reservationManager.runMultipleReservations(for: allEnabledConfigs, runType: .godmode)
        } else {
            // Run only the configs scheduled for today
            reservationManager.runMultipleReservations(for: enabledConfigs, runType: .godmode)
        }
    }
}

// MARK: - Helper Structs

struct NextAutorunInfo {
    let date: Date
    let config: ReservationConfig
    let weekday: ReservationConfig.Weekday
    let timeSlot: TimeSlot
}

struct LastRunStatusInfo {
    let statusKey: String
    let statusColor: Color
    let iconName: String
}

// MARK: - Configuration Row View

struct ConfigurationRowView: View {
    let config: ReservationConfig
    let nextAutorunInfo: NextAutorunInfo?
    let formatCountdown: (Date) -> String
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void
    let onRun: () -> Void
    @State private var isHovered = false
    @State private var isToggleHovered = false
    @State private var showingDeleteConfirmation = false
    @StateObject private var userSettingsManager = UserSettingsManager.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text(config.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Button(action: onRun) {
                    Image(systemName: "play.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
                .help("Run now")
                Toggle("", isOn: Binding(
                    get: { config.isEnabled },
                    set: { _ in onToggle() },
                    ))
                .toggleStyle(.switch)
                .labelsHidden()
                .help("Enable or disable autorun")
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.bordered)
                .help("Edit configuration")
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .help("Delete configuration")
            }
            let facilityName = ReservationConfig.extractFacilityName(from: config.facilityURL)
            HStack(spacing: 4) {
                SportIconView(
                    symbolName: SportIconMapper.iconForSport(config.sportName),
                    color: .accentColor,
                    size: 12,
                    )
                Text(
                    "\(facilityName) • \(config.sportName) • \(config.numberOfPeople)pp • \(formatScheduleInfoInline())",
                    )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let next = nextAutorunInfo {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Text("Next autorun:")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Text(formatCountdown(next.date))
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Text("(\(next.weekday.localizedShortName) \(formatTime(next.date)))")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                lastRunStatusView(for: config)
            }
        }
        .padding(.vertical, 6)
        .alert(
            "Delete Configuration",
            isPresented: $showingDeleteConfirmation,
            ) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            let deleteMessage = "Are you sure you want to delete '"
            let undoMessage = "'? This action cannot be undone."
            Text(deleteMessage + config.name + undoMessage)
        }
    }

    private func formatScheduleInfo() -> String {
        let sortedDays = config.dayTimeSlots.keys.sorted { day1, day2 in
            guard
                let index1 = ReservationConfig.Weekday.allCases.firstIndex(of: day1),
                let index2 = ReservationConfig.Weekday.allCases.firstIndex(of: day2)
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
                    formatter.locale = userSettingsManager.userSettings.locale
                    return formatter.string(from: timeSlot.time)
                }.sorted()
                let dayShort = day.localizedShortName
                let timesString = timeStrings.joined(separator: ", ")
                scheduleInfo.append("\(dayShort): \(timesString)")
            }
        }
        return scheduleInfo.joined(separator: " • ")
    }

    private func formatScheduleInfoInline() -> String {
        let sortedDays = config.dayTimeSlots.keys.sorted { day1, day2 in
            guard
                let index1 = ReservationConfig.Weekday.allCases.firstIndex(of: day1),
                let index2 = ReservationConfig.Weekday.allCases.firstIndex(of: day2)
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
                    formatter.locale = userSettingsManager.userSettings.locale
                    return formatter.string(from: timeSlot.time)
                }.sorted()
                let dayShort = day.localizedShortName
                let timesString = timeStrings.joined(separator: ", ")
                scheduleInfo.append("\(dayShort) \(timesString)")
            }
        }
        return scheduleInfo.joined(separator: " • ")
    }

    private func formatTime(_ date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.locale = userSettingsManager.userSettings.locale
        return timeFormatter.string(from: date)
    }

    private func nextAutorunText(for next: NextAutorunInfo) -> String {
        let autorunText = "Next autorun:"
        let countdownText = formatCountdown(next.date)
        let scheduleText = "(\(next.weekday.localizedShortName) \(formatTime(next.date)))"
        return "\(autorunText) \(countdownText) \(scheduleText)"
    }

    private func lastRunStatusView(for config: ReservationConfig) -> some View {
        if let lastRun = ReservationManager.shared.getLastRunInfo(for: config.id) {
            let statusInfo = switch lastRun.status {
            case .success:
                LastRunStatusInfo(statusKey: "successful", statusColor: .green, iconName: "checkmark.circle.fill")
            case .failed:
                LastRunStatusInfo(
                    statusKey: "failed",
                    statusColor: .red,
                    iconName: "xmark.octagon.fill",
                    )
            case .running:
                LastRunStatusInfo(
                    statusKey: "Running...",
                    statusColor: .orange,
                    iconName: "hourglass",
                    )
            case .idle:
                LastRunStatusInfo(
                    statusKey: "never",
                    statusColor: .gray,
                    iconName: "questionmark.circle",
                    )
            }
            let runTypeKey = switch lastRun.runType {
            case .manual: " (manual)"
            case .automatic: " (auto)"
            case .godmode: " (god mode)"
            }
            return AnyView(
                HStack(spacing: 2) {
                    Image(systemName: statusInfo.iconName)
                        .foregroundColor(statusInfo.statusColor)
                        .font(.caption)
                    Text("Last run:")
                        .font(.caption)
                        .foregroundColor(statusInfo.statusColor)
                    Text(statusInfo.statusKey + runTypeKey)
                        .font(.caption)
                        .foregroundColor(statusInfo.statusColor)
                    if let date = lastRun.date {
                        Text(date, style: .date)
                            .font(.caption2)
                            .foregroundColor(statusInfo.statusColor)
                        Text(date, style: .time)
                            .font(.caption2)
                            .foregroundColor(statusInfo.statusColor)
                    }
                },
                )
        } else {
            // Configuration has never been run - show in grey
            return AnyView(
                HStack(spacing: 2) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Text("Last run:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("never")
                        .font(.caption)
                        .foregroundColor(.gray)
                },
                )
        }
    }
}

struct DeleteConfirmationModal: View {
    let configName: String
    let onDelete: () -> Void
    let onCancel: () -> Void
    @StateObject private var userSettingsManager = UserSettingsManager.shared
    var body: some View {
        VStack(spacing: 20) {
            Image("logo")
                .resizable()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 24)
            Text("Delete Configuration")
                .font(.title3)
                .fontWeight(.semibold)
            let deleteMessage = "Are you sure you want to delete '"
            let undoMessage = "'? This action cannot be undone."
            Text(deleteMessage + configName + undoMessage)
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            HStack(spacing: 20) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(.bottom, 24)
        }
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 20),
            )
        .padding()
    }
}
