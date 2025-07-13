import SwiftUI

// MARK: - Main Content View

struct ContentView: View {
    @StateObject private var configManager = ConfigurationManager.shared
    @StateObject private var reservationManager = ReservationManager.shared
    @StateObject private var userSettingsManager = UserSettingsManager.shared
    @State private var showingAddConfig = false
    @State private var selectedConfig: ReservationConfig?
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            mainContentView
            Divider()
            footerView
        }
        .frame(width: 400, height: 600)
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
    }
}

// MARK: - Header View

private extension ContentView {
    var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "sportscourt.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(userSettingsManager.userSettings.localized(
                "ODYSSEY – Ottawa Drop-in Your Sports & Schedule Easily Yourself",
            ))
            .font(.title3)
            .fontWeight(.semibold)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(action: { showingAddConfig = true }) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
            }
            .buttonStyle(.borderedProminent)
            .help(userSettingsManager.userSettings.localized("Add new configuration"))
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
                    .onDelete { indices in
                        for index in indices {
                            let config = configManager.settings.configurations[index]
                            configManager.removeConfiguration(config)
                        }
                    }
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
            Text(userSettingsManager.userSettings.localized("No Reservations Configured"))
                .font(.title3)
                .fontWeight(.medium)
            Text(
                userSettingsManager.userSettings
                    .localized("Add your first reservation configuration to get started with automated booking."),
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            Button(userSettingsManager.userSettings.localized("Add Configuration")) {
                showingAddConfig = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }

    var footerView: some View {
        VStack(spacing: 8) {
            HStack {
                Button(userSettingsManager.userSettings.localized("Settings")) {
                    showingSettings = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .help(userSettingsManager.userSettings.localized("Configure user settings and integrations"))

                Spacer()

                Link(
                    userSettingsManager.userSettings.localized("GitHub"),
                    destination: URL(string: "https://github.com/Amet13/ODYSSEY")!,
                )
                .font(.footnote)
                .foregroundColor(.blue)
                .help(userSettingsManager.userSettings.localized("View ODYSSEY on GitHub"))

                Spacer()

                Button(userSettingsManager.userSettings.localized("Quit")) {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .help(userSettingsManager.userSettings.localized("Quit ODYSSEY"))
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
                        if nextCronTime == nil || finalCronTime < nextCronTime! {
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
            return userSettingsManager.userSettings.localized("now")
        }
        let days = Int(timeInterval / 86_400)
        let hours = Int((timeInterval.truncatingRemainder(dividingBy: 86_400)) / 3_600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3_600)) / 60)
        if days > 0 {
            let daysText = userSettingsManager.userSettings.localized(days == 1 ? "day" : "days")
            let hoursText = userSettingsManager.userSettings.localized(hours == 1 ? "hour" : "hours")
            return "\(days) \(daysText), \(hours) \(hoursText)"
        } else if hours > 0 {
            let hoursText = userSettingsManager.userSettings.localized(hours == 1 ? "hour" : "hours")
            let minutesText = userSettingsManager.userSettings.localized(minutes == 1 ? "minute" : "minutes")
            return "\(hours) \(hoursText), \(minutes) \(minutesText)"
        } else {
            let minutesText = userSettingsManager.userSettings.localized(minutes == 1 ? "minute" : "minutes")
            return "\(minutes) \(minutesText)"
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
                .help(userSettingsManager.userSettings.localized("Run now"))
                Toggle("", isOn: Binding(
                    get: { config.isEnabled },
                    set: { _ in onToggle() },
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .help(userSettingsManager.userSettings.localized("Enable or disable configuration"))
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.bordered)
                .help(userSettingsManager.userSettings.localized("Edit configuration"))
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .help(userSettingsManager.userSettings.localized("Delete configuration"))
            }
            let facilityName = ReservationConfig.extractFacilityName(from: config.facilityURL)
            Text("\(facilityName) • \(config.sportName) • \(config.numberOfPeople)pp")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 2) {
                if !config.dayTimeSlots.isEmpty {
                    Text(formatScheduleInfo())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let next = nextAutorunInfo {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Text(nextAutorunText(for: next))
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                lastRunStatusView(for: config)
            }
        }
        .padding(.vertical, 6)
        .alert(
            userSettingsManager.userSettings.localized("Delete Configuration"),
            isPresented: $showingDeleteConfirmation,
        ) {
            Button(userSettingsManager.userSettings.localized("Cancel"), role: .cancel) { }
            Button(userSettingsManager.userSettings.localized("Delete"), role: .destructive) {
                onDelete()
            }
        } message: {
            let deleteMessage = userSettingsManager.userSettings.localized("Are you sure you want to delete '")
            let undoMessage = userSettingsManager.userSettings.localized("'? This action cannot be undone.")
            Text(deleteMessage + config.name + undoMessage)
        }
    }

    private func formatScheduleInfo() -> String {
        let sortedDays = config.dayTimeSlots.keys.sorted { day1, day2 in
            ReservationConfig.Weekday.allCases.firstIndex(of: day1)! < ReservationConfig.Weekday.allCases
                .firstIndex(of: day2)!
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

    private func nextAutorunText(for next: NextAutorunInfo) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.locale = userSettingsManager.userSettings.locale
        let autorunTimeString = timeFormatter.string(from: next.date)
        let autorunText = userSettingsManager.userSettings.localized("Next autorun:")
        let countdownText = formatCountdown(next.date)
        let scheduleText = "(" + next.weekday.localizedShortName + " " + autorunTimeString + ")"
        return "\(autorunText) \(countdownText) \(scheduleText)"
    }

    private func lastRunStatusView(for config: ReservationConfig) -> some View {
        if let lastRun = ReservationManager.shared.getLastRunInfo(for: config.id) {
            let statusInfo = switch lastRun.status {
            case .success:
                LastRunStatusInfo(statusKey: "success", statusColor: .green, iconName: "checkmark.circle.fill")
            case .failed:
                LastRunStatusInfo(statusKey: "fail", statusColor: .red, iconName: "xmark.octagon.fill")
            case .running:
                LastRunStatusInfo(statusKey: "Running...", statusColor: .orange, iconName: "hourglass")
            case .idle:
                LastRunStatusInfo(statusKey: "never", statusColor: .gray, iconName: "questionmark.circle")
            }
            let runTypeKey = switch lastRun.runType {
            case .manual: "(manual)"
            case .automatic: "(auto)"
            }
            return AnyView(
                HStack(spacing: 6) {
                    Image(systemName: statusInfo.iconName)
                        .foregroundColor(statusInfo.statusColor)
                        .font(.caption)
                    let lastRunText = userSettingsManager.userSettings.localized("Last run:")
                    let statusText = userSettingsManager.userSettings.localized(statusInfo.statusKey)
                    let runTypeText = userSettingsManager.userSettings.localized(runTypeKey)
                    Text("\(lastRunText) \(statusText) \(runTypeText)")
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
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Text(
                        userSettingsManager.userSettings.localized("Last run:") + " " + userSettingsManager
                            .userSettings.localized("never"),
                    )
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
            Text(userSettingsManager.userSettings.localized("Delete Configuration"))
                .font(.title3)
                .fontWeight(.semibold)
            let deleteMessage = userSettingsManager.userSettings.localized("Are you sure you want to delete '")
            let undoMessage = userSettingsManager.userSettings.localized("'? This action cannot be undone.")
            Text(deleteMessage + configName + undoMessage)
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            HStack(spacing: 20) {
                Button(userSettingsManager.userSettings.localized("Cancel")) {
                    onCancel()
                }
                .buttonStyle(.bordered)
                Button(userSettingsManager.userSettings.localized("Delete")) {
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

// MARK: - Preview

#Preview {
    ContentView()
}
