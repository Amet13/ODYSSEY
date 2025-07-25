import Combine
import SwiftUI

// MARK: - Main Content View

struct ContentView: View {
    // Service singletons for automation, email, and secure storage
    private let webKitService: WebKitServiceProtocol = ServiceRegistry.shared.resolve(WebKitServiceProtocol.self)
    private let emailService: EmailServiceProtocol = ServiceRegistry.shared.resolve(EmailServiceProtocol.self)
    private let keychainService: KeychainServiceProtocol = ServiceRegistry.shared.resolve(KeychainServiceProtocol.self)
    // State objects for app-wide managers (configuration, orchestration, status, user settings)
    @StateObject private var configManager = ConfigurationManager.shared
    @StateObject private var orchestrator = ReservationOrchestrator.shared
    @StateObject private var statusManager = ReservationStatusManager.shared
    @StateObject private var userSettingsManager = UserSettingsManager.shared
    // UI state for modal and sheet presentation
    @State private var showingAddConfig = false
    @State private var selectedConfig: ReservationConfig?
    @State private var showingSettings = false
    @State private var showingAbout = false
    @State private var showingGodModeConfig = false
    // Loading and progress state
    @ObservedObject private var loadingStateManager = LoadingStateManager.shared
    @State private var bannerTimer: AnyCancellable?
    // God mode and error/help UI
    @State private var godModeUIEnabled = false
    @State private var showingUserError = false
    @State private var showingHelp = false
    // Countdown refresh for autorun scheduling
    @State private var countdownRefreshTrigger = false
    @State private var countdownTimer: Timer?

    var body: some View {
        MainBody(
            configManager: configManager,
            orchestrator: orchestrator,
            statusManager: statusManager,
            userSettingsManager: userSettingsManager,
            showingAddConfig: $showingAddConfig,
            selectedConfig: $selectedConfig,
            showingSettings: $showingSettings,
            showingAbout: $showingAbout,
            showingGodModeConfig: $showingGodModeConfig,
            loadingStateManager: loadingStateManager,
            bannerTimer: $bannerTimer,
            godModeUIEnabled: $godModeUIEnabled,
            showingUserError: $showingUserError,
            showingHelp: $showingHelp,
            emailService: emailService,
            countdownRefreshTrigger: $countdownRefreshTrigger,
            )
        .onAppear {
            // When the main view appears, start a timer to update the autorun countdown every 30 seconds
            countdownRefreshTrigger.toggle()
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                DispatchQueue.main.async {
                    countdownRefreshTrigger.toggle()
                }
            }
        }
        .onDisappear {
            // Clean up timer when the view disappears
            countdownTimer?.invalidate()
            countdownTimer = nil
        }
    }
}

private struct MainBody: View {
    // All major state and bindings for the main UI
    @ObservedObject var configManager: ConfigurationManager
    @ObservedObject var orchestrator: ReservationOrchestrator
    @ObservedObject var statusManager: ReservationStatusManager
    @ObservedObject var userSettingsManager: UserSettingsManager
    @Binding var showingAddConfig: Bool
    @Binding var selectedConfig: ReservationConfig?
    @Binding var showingSettings: Bool
    @Binding var showingAbout: Bool
    @Binding var showingGodModeConfig: Bool
    @ObservedObject var loadingStateManager: LoadingStateManager
    @Binding var bannerTimer: AnyCancellable?
    @Binding var godModeUIEnabled: Bool
    @Binding var showingUserError: Bool
    @Binding var showingHelp: Bool
    let emailService: EmailServiceProtocol
    @Binding var countdownRefreshTrigger: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HeaderView(
                    godModeUIEnabled: $godModeUIEnabled,
                    showingAddConfig: $showingAddConfig,
                    simulateAutorunForToday: simulateAutorunForToday,
                    )
                Divider()
                MainContentView(
                    configManager: configManager,
                    statusManager: statusManager,
                    selectedConfig: $selectedConfig,
                    orchestrator: orchestrator,
                    getNextCronRunTime: getNextCronRunTime,
                    formatCountdown: formatCountdown,
                    showingAddConfig: $showingAddConfig,
                    countdownRefreshTrigger: countdownRefreshTrigger,
                    )
                Divider()
                FooterView(
                    showingSettings: $showingSettings,
                    showingAbout: $showingAbout,
                    )
            }
            .frame(width: AppConstants.windowMainWidth, height: AppConstants.windowMainHeight)
            .background(Color(NSColor.windowBackgroundColor))
            // Sheet modals for configuration, settings, about, and god mode
            .sheet(isPresented: $showingAddConfig) {
                ConfigurationDetailView(config: nil, onSave: { config in
                    configManager.addConfiguration(config)
                })
            }
            .sheet(item: $selectedConfig) { config in
                ConfigurationDetailView(config: config, onSave: { updatedConfig in
                    configManager.updateConfiguration(updatedConfig)
                })
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(godModeEnabled: godModeUIEnabled)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showingGodModeConfig) {
                ConfigurationDetailView(config: nil, onSave: { _ in
                    // You can define what saving in god mode does here
                })
            }
            // Keyboard shortcut for toggling god mode UI
            .onKeyPress("g", phases: .down) { press in
                if press.modifiers.contains(.command) {
                    godModeUIEnabled.toggle()
                    // Don't remove focus - this was causing the key press issue
                    return .handled
                }
                return .ignored
            }
        }
    }

    // Helper to get the next autorun time for a config, considering custom or default time
    func getNextCronRunTime(for config: ReservationConfig) -> NextAutorunInfo? {
        guard config.isEnabled else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let userSettingsManager = UserSettingsManager.shared
        // Determine which time to use based on user settings
        let useCustomTime = userSettingsManager.userSettings.useCustomAutorunTime
        let autorunTime: Date
        let autorunHour: Int
        let autorunMinute: Int
        let autorunSecond: Int
        if useCustomTime {
            autorunTime = userSettingsManager.userSettings.customAutorunTime
            autorunHour = calendar.component(.hour, from: autorunTime)
            autorunMinute = calendar.component(.minute, from: autorunTime)
            autorunSecond = calendar.component(.second, from: autorunTime)
        } else {
            autorunTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
            autorunHour = 18
            autorunMinute = 0
            autorunSecond = 0
        }
        // Find the next scheduled autorun for this config
        var nextCronTime: Date?
        var nextWeekday: ReservationConfig.Weekday?
        var nextTimeSlot: TimeSlot?
        for (weekday, timeSlots) in config.dayTimeSlots {
            for timeSlot in timeSlots {
                for weekOffset in 0 ... 4 {
                    let baseDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: now) ?? now
                    let reservationDay = getNextWeekday(weekday, from: baseDate)
                    let cronTime = calendar.date(byAdding: .day, value: -2, to: reservationDay) ?? reservationDay
                    let finalCronTime = calendar.date(
                        bySettingHour: autorunHour,
                        minute: autorunMinute,
                        second: autorunSecond,
                        of: cronTime,
                        ) ?? cronTime
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

    // Helper to get the next date for a given weekday from a base date
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

    // Formats a countdown string for the next autorun
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
            if hours > 0 {
                let hoursText = hours == 1 ? "hour" : "hours"
                return "\(days) \(daysText), \(hours) \(hoursText)"
            } else if minutes > 0 {
                let minutesText = minutes == 1 ? "minute" : "minutes"
                return "\(days) \(daysText), \(minutes) \(minutesText)"
            } else {
                return "\(days) \(daysText)"
            }
        } else if hours > 0 {
            let hoursText = hours == 1 ? "hour" : "hours"
            let minutesText = minutes == 1 ? "minute" : "minutes"
            return "\(hours) \(hoursText), \(minutes) \(minutesText)"
        } else if minutes > 0 {
            let minutesText = minutes == 1 ? "minute" : "minutes"
            return "\(minutes) \(minutesText)"
        } else {
            return "less than a minute"
        }
    }

    // Simulate autorun for all enabled configs for today (god mode)
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
        // Get all enabled configs for today
        let configsForToday = configManager.getConfigurationsForDay(weekday)
        let enabledConfigs = configsForToday.filter(\.isEnabled)
        if enabledConfigs.isEmpty {
            // If no enabled configs for today, run all enabled configs
            let allEnabledConfigs = configManager.settings.configurations.filter(\.isEnabled)
            orchestrator.runMultipleReservations(for: allEnabledConfigs, runType: .godmode)
        } else {
            // Run only the configs scheduled for today
            orchestrator.runMultipleReservations(for: enabledConfigs, runType: .godmode)
        }
    }
}

private struct HeaderView: View {
    @Binding var godModeUIEnabled: Bool
    @Binding var showingAddConfig: Bool
    let simulateAutorunForToday: () -> Void
    @StateObject private var userSettingsManager = UserSettingsManager.shared

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "sportscourt.fill")
                    .font(.title2)
                    .foregroundColor(.odysseyAccent)
                Text("ODYSSEY")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if godModeUIEnabled {
                    Button(action: simulateAutorunForToday) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.odysseyWarning)
                            Text("GOD MODE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.odysseyWarning)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.odysseyAccent)
                    .controlSize(.small)
                    .help("⚡ Simulate autorun for \(formatCustomTime()) today")
                    .accessibilityLabel("Simulate GOD MODE")
                }
                Button(action: { showingAddConfig = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .help(NSLocalizedString("add_config_tooltip", comment: "Add a new reservation configuration"))
                .accessibilityLabel(NSLocalizedString("add_configuration", comment: "Add Configuration"))
                .accessibilityHint(NSLocalizedString(
                    "add_config_tooltip",
                    comment: "Add a new reservation configuration",
                    ))
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .padding(.horizontal, AppConstants.paddingHorizontal)
        .padding(.top, AppConstants.paddingVertical)
        .padding(.bottom, AppConstants.paddingVertical)
    }

    private func formatCustomTime() -> String {
        let calendar = Calendar.current
        let useCustomTime = userSettingsManager.userSettings.useCustomAutorunTime
        let hour: Int
        let minute: Int

        if useCustomTime {
            // Use the custom time set by the user
            let customTime = userSettingsManager.userSettings.customAutorunTime
            hour = calendar.component(.hour, from: customTime)
            minute = calendar.component(.minute, from: customTime)
        } else {
            // Use default 6:00 PM time
            hour = 18
            minute = 0
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US")

        let timeDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return formatter.string(from: timeDate)
    }
}

private struct MainContentView: View {
    @ObservedObject var configManager: ConfigurationManager
    @ObservedObject var statusManager: ReservationStatusManager
    @Binding var selectedConfig: ReservationConfig?
    @ObservedObject var orchestrator: ReservationOrchestrator
    let getNextCronRunTime: (ReservationConfig) -> NextAutorunInfo?
    let formatCountdown: (Date) -> String
    @Binding var showingAddConfig: Bool
    let countdownRefreshTrigger: Bool
    var body: some View {
        if configManager.settings.configurations.isEmpty {
            EmptyStateView(showingAddConfig: $showingAddConfig)
        } else {
            ConfigurationListView(
                configManager: configManager,
                statusManager: statusManager,
                selectedConfig: $selectedConfig,
                orchestrator: orchestrator,
                getNextCronRunTime: getNextCronRunTime,
                formatCountdown: formatCountdown,
                countdownRefreshTrigger: countdownRefreshTrigger,
                )
        }
    }
}

private struct EmptyStateView: View {
    @Binding var showingAddConfig: Bool

    var body: some View {
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
                .padding(.horizontal, AppConstants.paddingHorizontal)
            Button("Add Configuration") {
                showingAddConfig = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .accessibilityLabel("Add Configuration")
            .keyboardShortcut("n", modifiers: .command)
            Spacer()
        }
        .padding(AppConstants.paddingHorizontal)
    }
}

private struct ConfigurationListView: View {
    @ObservedObject var configManager: ConfigurationManager
    @ObservedObject var statusManager: ReservationStatusManager
    @Binding var selectedConfig: ReservationConfig?
    @ObservedObject var orchestrator: ReservationOrchestrator
    let getNextCronRunTime: (ReservationConfig) -> NextAutorunInfo?
    let formatCountdown: (Date) -> String
    let countdownRefreshTrigger: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(
                    Array(configManager.settings.configurations.enumerated()),
                    id: \.element.id,
                    ) { index, config in
                    ConfigurationRowView(
                        config: config,
                        nextAutorunInfo: getNextCronRunTime(config),
                        formatCountdown: formatCountdown,
                        lastRunInfo: statusManager.getLastRunInfo(for: config.id),
                        onEdit: { selectedConfig = config },
                        onDelete: { configManager.removeConfiguration(config) },
                        onToggle: { configManager.toggleConfiguration(at: index) },
                        onRun: { orchestrator.runReservation(for: config, runType: .manual) },
                        )
                    .accessibilityElement()
                    .accessibilityLabel("Reservation configuration for \(config.name)")
                    .id("\(config.id)-\(countdownRefreshTrigger)") // Force refresh when countdown trigger changes
                    if index < configManager.settings.configurations.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal, AppConstants.paddingHorizontal)
    }
}

private struct FooterView: View {
    @Binding var showingSettings: Bool
    @Binding var showingAbout: Bool

    var body: some View {
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
                .help(NSLocalizedString("settings_tooltip", comment: "Configure user settings and integrations"))
                .accessibilityLabel(NSLocalizedString("settings", comment: "Settings"))
                .keyboardShortcut(",", modifiers: .command)

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
                .help(NSLocalizedString("about_tooltip", comment: "About ODYSSEY"))
                .accessibilityLabel(NSLocalizedString("about", comment: "About"))

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
                .help(NSLocalizedString("quit_tooltip", comment: "Quit ODYSSEY"))
                .accessibilityLabel(NSLocalizedString("quit", comment: "Quit"))
            }
            .padding(.horizontal, AppConstants.paddingHorizontal)
            .padding(.bottom, AppConstants.paddingVertical)
            .padding(.top, AppConstants.paddingVertical)
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
    let lastRunInfo: ReservationStatusManager.LastRunInfo?
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
                        .foregroundColor(.odysseyAccent)
                }
                .buttonStyle(.bordered)
                .help(NSLocalizedString("run_now_tooltip", comment: "Run this reservation now"))
                .accessibilityLabel(NSLocalizedString("run_now", comment: "Run Now"))
                .accessibilityHint(NSLocalizedString("run_now_tooltip", comment: "Run this reservation now"))
                Toggle("", isOn: Binding(
                    get: { config.isEnabled },
                    set: { _ in onToggle() },
                    ))
                .toggleStyle(.switch)
                .labelsHidden()
                .help(NSLocalizedString(
                    "enable_autorun_tooltip",
                    comment: "Enable or disable autorun for this configuration",
                    ))
                .accessibilityLabel(NSLocalizedString(
                    "enable_autorun_tooltip",
                    comment: "Enable or disable autorun for this configuration",
                    ))
                .accessibilityHint(NSLocalizedString(
                    "enable_autorun_tooltip",
                    comment: "Enable or disable autorun for this configuration",
                    ))
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.odysseyAccent)
                .help(NSLocalizedString("edit_tooltip", comment: "Edit this configuration"))
                .accessibilityLabel(NSLocalizedString("edit_configuration", comment: "Edit Configuration"))
                .accessibilityHint(NSLocalizedString("edit_tooltip", comment: "Edit this configuration"))
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.odysseyError)
                }
                .buttonStyle(.bordered)
                .help(NSLocalizedString("delete_tooltip", comment: "Delete this configuration"))
                .accessibilityLabel(NSLocalizedString("delete_configuration", comment: "Delete Configuration"))
                .accessibilityHint(NSLocalizedString("delete_tooltip", comment: "Delete this configuration"))
            }
            .accessibilityElement()
            .accessibilityLabel("Reservation configuration for \(config.name)")
            let facilityName = ReservationConfig.extractFacilityName(from: config.facilityURL)
            HStack(spacing: 4) {
                SportIconView(
                    symbolName: SportIconMapper.iconForSport(config.sportName),
                    color: .odysseyAccent,
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
                            .foregroundColor(.odysseyAccent)
                        Text("Next autorun in:")
                            .font(.caption)
                            .foregroundColor(.odysseyAccent)
                        Text(formatCountdown(next.date))
                            .font(.caption)
                            .foregroundColor(.odysseyAccent)
                    }
                }
                lastRunStatusView(for: lastRunInfo)
            }
        }
        .padding(.vertical, AppConstants.paddingVerticalSmall)
        // Removed border and overlay, keep background only if needed in future
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.1)),
            )
        .padding(.vertical, 4)
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

    private func lastRunStatusView(for lastRunInfo: ReservationStatusManager.LastRunInfo?) -> some View {
        if let lastRun = lastRunInfo {
            let statusInfo = switch lastRun.status {
            case .success:
                LastRunStatusInfo(
                    statusKey: "successful",
                    statusColor: .odysseySuccess,
                    iconName: "checkmark.circle.fill",
                    )
            case .failed:
                LastRunStatusInfo(
                    statusKey: "failed",
                    statusColor: .odysseyError,
                    iconName: "xmark.octagon.fill",
                    )
            case .running:
                LastRunStatusInfo(
                    statusKey: "Running...",
                    statusColor: .odysseyWarning,
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
            Image(systemName: "sportscourt.fill")
                .font(.system(size: AppConstants.iconLarge))
                .foregroundColor(.odysseyAccent)
                .padding(.top, AppConstants.paddingVerticalForm)
            Text("Delete Configuration")
                .font(.title3)
                .fontWeight(.semibold)
            let deleteMessage = "Are you sure you want to delete '"
            let undoMessage = "'? This action cannot be undone."
            Text(deleteMessage + configName + undoMessage)
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal, AppConstants.paddingHorizontalForm)
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
            .padding(.bottom, AppConstants.paddingVerticalForm)
        }
        .frame(width: AppConstants.windowDeleteModalWidth)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 20),
            )
        .padding(AppConstants.paddingHorizontalForm)
    }
}

// MARK: - Onboarding/Help View

// (OnboardingHelpView struct and its implementation removed)
