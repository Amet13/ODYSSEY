import SwiftUI

// MARK: - Main Content View

struct ContentView: View {
    @StateObject private var configManager = ConfigurationManager.shared
    @StateObject private var reservationManager = ReservationManager.shared
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
            Text("ODYSSEY – Ottawa Drop-in Your Sports & Schedule Easily Yourself")
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(action: { showingAddConfig = true }) {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
            .help("Add new configuration")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    var mainContentView: some View {
        Group {
            if configManager.settings.configurations.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(configManager.settings.configurations) { config in
                        ConfigurationRowView(
                            config: config,
                            nextAutorunInfo: getNextCronRunTime(for: config),
                            formatCountdown: formatCountdown
                        ) {
                            selectedConfig = config
                        } onDelete: {
                            configManager.removeConfiguration(config)
                        } onToggle: {
                            configManager.toggleConfigurationEnabled(config)
                        } onRun: {
                            reservationManager.runReservation(for: config)
                        }
                    }
                    .onDelete { indices in
                        for index in indices {
                            let config = configManager.settings.configurations[index]
                            configManager.removeConfiguration(config)
                        }
                    }
                }
                .listStyle(.inset)
            }
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
            Text("Add your first reservation configuration to get started with automated booking.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Add Configuration") {
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
                Button("Settings") {
                    showingSettings = true
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .help("Configure user settings and integrations")

                Spacer()

                Link("GitHub", destination: URL(string: "https://github.com/Amet13/ODYSSEY")!)
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .help("View ODYSSEY on GitHub")

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .help("Quit ODYSSEY")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 16)
        }
    }

    // Helper to get next autorun for a specific config
    func getNextCronRunTime(for config: ReservationConfig) -> (date: Date, config: ReservationConfig, weekday: ReservationConfig.Weekday, timeSlot: TimeSlot)? {
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
            return (date: date, config: config, weekday: weekday, timeSlot: timeSlot)
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
        let days = Int(timeInterval / 86400)
        let hours = Int((timeInterval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s"), \(hours) hour\(hours == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s"), \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

// MARK: - Configuration Row View

struct ConfigurationRowView: View {
    let config: ReservationConfig
    let nextAutorunInfo: (date: Date, config: ReservationConfig, weekday: ReservationConfig.Weekday, timeSlot: TimeSlot)?
    let formatCountdown: (Date) -> String
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void
    let onRun: () -> Void
    @State private var isHovered = false
    @State private var isToggleHovered = false
    @State private var showingDeleteConfirmation = false
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
                }
                .buttonStyle(.bordered)
                .help("Run automated reservation booking for this configuration")
                Toggle("", isOn: Binding(
                    get: { config.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .help("Enable or disable configuration")
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.bordered)
                .help("Edit configuration")
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .help("Delete configuration")
            }
            Text("\(ReservationConfig.extractFacilityName(from: config.facilityURL)) • \(config.sportName) • \(config.numberOfPeople)pp")
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
            }
        }
        .padding(.vertical, 6)
        .alert("Delete Configuration", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(config.name)'? This action cannot be undone.")
        }
    }

    private func formatScheduleInfo() -> String {
        let sortedDays = config.dayTimeSlots.keys.sorted { day1, day2 in
            ReservationConfig.Weekday.allCases.firstIndex(of: day1)! < ReservationConfig.Weekday.allCases.firstIndex(of: day2)!
        }
        var scheduleInfo: [String] = []
        for day in sortedDays {
            if let timeSlots = config.dayTimeSlots[day], !timeSlots.isEmpty {
                let timeStrings = timeSlots.map { timeSlot in
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    return formatter.string(from: timeSlot.time)
                }.sorted()
                let dayShort = day.shortName
                let timesString = timeStrings.joined(separator: ", ")
                scheduleInfo.append("\(dayShort): \(timesString)")
            }
        }
        return scheduleInfo.joined(separator: " • ")
    }

    private func nextAutorunText(for next: (date: Date, config: ReservationConfig, weekday: ReservationConfig.Weekday, timeSlot: TimeSlot)) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: next.timeSlot.time)
        return "Next autorun: \(formatCountdown(next.date)) (\(next.weekday.shortName) \(timeString))"
    }
}

struct DeleteConfirmationModal: View {
    let configName: String
    let onDelete: () -> Void
    let onCancel: () -> Void
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
            Text("Are you sure you want to delete '\(configName)'? This action cannot be undone.")
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
                .shadow(radius: 20)
        )
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
