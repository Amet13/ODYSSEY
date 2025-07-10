import SwiftUI

// MARK: - Main Content View

struct ContentView: View {
    @StateObject private var configManager = ConfigurationManager.shared
    @StateObject private var reservationManager = ReservationManager.shared
    @State private var showingAddConfig = false
    @State private var selectedConfig: ReservationConfig?
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            mainContentView
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
    }
}

// MARK: - Header View

private extension ContentView {
    var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sportscourt.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("ODYSSEY – Ottawa Drop-in Your Sports & Schedule Easily Yourself")
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Button(action: { showingAddConfig = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(IconHoverButtonStyle())
            }
            
            statusIndicatorView
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    var statusIndicatorView: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if reservationManager.isRunning {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
}

// MARK: - Main Content View

private extension ContentView {
    var mainContentView: some View {
        Group {
            if configManager.settings.configurations.isEmpty {
                emptyStateView
            } else {
                configurationListView
            }
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Reservations Configured")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Add your first reservation configuration to get started with automated booking.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            StyledButton("Add Configuration") {
                showingAddConfig = true
            }
            
            Spacer()
        }
        .padding()
    }
    
    var configurationListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(configManager.settings.configurations) { config in
                    ConfigurationRowView(config: config) {
                        selectedConfig = config
                    } onDelete: {
                        configManager.removeConfiguration(config)
                    } onToggle: {
                        configManager.toggleConfigurationEnabled(config)
                    } onRun: {
                        reservationManager.runReservation(for: config)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Footer View

private extension ContentView {
    var footerView: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                Button("Run All") {
                    reservationManager.runAllEnabledReservations()
                }
                .buttonStyle(RunAllButtonStyle(isDisabled: !canRunAll))
                .disabled(!canRunAll)
                
                Spacer()
                
                StyledButton("Stop", role: .destructive, isDisabled: !reservationManager.isRunning) {
                    reservationManager.stopAllReservations()
                }
                
                StyledButton("Quit", role: .destructive) {
                    NSApp.terminate(nil)
                }
            }
            .padding(.horizontal)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .padding(.bottom, 12)
    }
    
    private var canRunAll: Bool {
        configManager.isAnyConfigurationEnabled() && !reservationManager.isRunning
    }
}

// MARK: - Computed Properties

private extension ContentView {
    var statusColor: Color {
        switch reservationManager.lastRunStatus {
        case .idle: return .gray
        case .running: return .blue
        case .success: return .green
        case .failed: return .red
        }
    }
    
    var statusText: String {
        if reservationManager.isRunning {
            return "Running: \(reservationManager.currentTask)"
        }
        
        let enabledConfigs = configManager.getEnabledConfigurations()
        let totalConfigs = configManager.settings.configurations.count
        
        if enabledConfigs.isEmpty {
            return "No enabled configs (\(totalConfigs) total)"
        }
        
        let configsWithSlots = enabledConfigs.filter { !$0.dayTimeSlots.isEmpty }
        if configsWithSlots.isEmpty {
            return "No time slots configured (\(enabledConfigs.count) enabled)"
        }
        
        if let nextRun = getNextCronRunTime() {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let timeString = timeFormatter.string(from: nextRun.timeSlot.time)
            return "Next autorun: \(formatCountdown(to: nextRun.date)) for \(nextRun.config.sportName) (\(nextRun.weekday.shortName) \(timeString))"
        } else {
            return "No future autorun times (\(configsWithSlots.count) configs with slots)"
        }
    }
}

// MARK: - Helper Functions

private extension ContentView {
    func getNextCronRunTime() -> (date: Date, config: ReservationConfig, weekday: ReservationConfig.Weekday, timeSlot: TimeSlot)? {
        let enabledConfigs = configManager.getEnabledConfigurations()
        guard !enabledConfigs.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        var nextCronTime: Date?
        var nextConfig: ReservationConfig?
        var nextWeekday: ReservationConfig.Weekday?
        var nextTimeSlot: TimeSlot?
        
        // Debug logging
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
                    NSLog("ODYSSEY: Current time: \(formatter.string(from: now))")
        
        // Find the next cron run time (2 days before any scheduled event at 6:00 PM)
        for config in enabledConfigs {
            for (weekday, timeSlots) in config.dayTimeSlots {
                for timeSlot in timeSlots {
                    // Check multiple weeks ahead to find the next valid cron time
                    for weekOffset in 0...4 {
                        let baseDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: now) ?? now
                        let reservationDay = getNextWeekday(weekday, from: baseDate)
                        
                        // Calculate cron time (2 days before at 6:00 PM)
                        let cronTime = calendar.date(byAdding: .day, value: -2, to: reservationDay) ?? reservationDay
                        let finalCronTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: cronTime) ?? cronTime
                        
                                    NSLog("ODYSSEY: Config: \(config.name), Day: \(weekday.rawValue), Week: +\(weekOffset)")
            NSLog("ODYSSEY:   Reservation day: \(formatter.string(from: reservationDay))")
            NSLog("ODYSSEY:   Cron time: \(formatter.string(from: finalCronTime))")
            NSLog("ODYSSEY:   Is future: \(finalCronTime > now)")
                        
                        // Only consider if this cron time is in the future
                        if finalCronTime > now {
                            // Keep the earliest cron time
                            if nextCronTime == nil || finalCronTime < nextCronTime! {
                                nextCronTime = finalCronTime
                                nextConfig = config
                                nextWeekday = weekday
                                nextTimeSlot = timeSlot
                                NSLog("ODYSSEY:   -> New earliest cron time: \(formatter.string(from: finalCronTime))")
                            }
                            // Found a valid cron time for this config/day, move to next
                            break
                        }
                    }
                }
            }
        }
        
        if let result = nextCronTime, let config = nextConfig, let weekday = nextWeekday, let timeSlot = nextTimeSlot {
            NSLog("ODYSSEY: Final result: \(formatter.string(from: result))")
            return (date: result, config: config, weekday: weekday, timeSlot: timeSlot)
        } else {
            NSLog("ODYSSEY: No future cron times found")
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
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void
    let onRun: () -> Void
    
    @State private var isHovered = false
    @State private var isToggleHovered = false
    
    var body: some View {
        HStack {
            configurationInfoView
            Spacer()
            actionButtonsView
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: isHovered ? .black.opacity(0.1) : .clear, radius: isHovered ? 4 : 0, x: 0, y: isHovered ? 2 : 0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var configurationInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(config.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(config.sportName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !config.dayTimeSlots.isEmpty {
                Text(formatScheduleInfo())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            Button(action: onRun) {
                Image(systemName: "play.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            }
            .buttonStyle(IconHoverButtonStyle())
            .disabled(ReservationManager.shared.isRunning)
            
            Toggle("", isOn: Binding(
                get: { config.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .toggleStyle(BlueSwitchToggleStyle())
            .scaleEffect(isToggleHovered ? 1.12 : 1.08)
            .onHover { hovering in
                isToggleHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.title3)
            }
            .buttonStyle(IconHoverButtonStyle())
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(.red)
            }
            .buttonStyle(IconHoverButtonStyle())
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
}

// MARK: - Button Styles

struct StyledButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    let role: SwiftUI.ButtonRole?
    
    init(_ title: String, role: SwiftUI.ButtonRole? = nil, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(title, action: action)
            .buttonStyle(AdaptiveButtonStyle(isDisabled: isDisabled, role: role))
            .disabled(isDisabled)
    }
}

struct AdaptiveButtonStyle: ButtonStyle {
    let isDisabled: Bool
    let role: SwiftUI.ButtonRole?
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(buttonBackgroundColor())
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(buttonBorderColor(), lineWidth: 1)
                    )
            )
            .foregroundColor(buttonTextColor())
            .shadow(color: isHovered && !configuration.isPressed && !isDisabled ? .black.opacity(0.15) : .clear, radius: isHovered ? 3 : 0, x: 0, y: isHovered ? 1 : 0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .onHover { hovering in
                if !isDisabled {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
            }
    }
    
    private func buttonBackgroundColor() -> Color {
        if isDisabled {
            return Color.gray.opacity(0.1)
        } else if role == .destructive {
            return Color.red.opacity(0.1)
        } else if role == .cancel {
            return Color.gray.opacity(0.1)
        } else {
            return Color.blue.opacity(0.1)
        }
    }
    
    private func buttonBorderColor() -> Color {
        if isDisabled {
            return Color.gray.opacity(0.2)
        } else if role == .destructive {
            return Color.red.opacity(0.3)
        } else if role == .cancel {
            return Color.gray.opacity(0.3)
        } else {
            return Color.blue.opacity(0.3)
        }
    }
    
    private func buttonTextColor() -> Color {
        if isDisabled {
            return Color.gray.opacity(0.6)
        } else if role == .destructive {
            return .red
        } else if role == .cancel {
            return .gray
        } else {
            return .blue
        }
    }
}

struct IconHoverButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.08)
            .shadow(color: configuration.isPressed ? .clear : .black.opacity(0.18), radius: configuration.isPressed ? 0 : 5, x: 0, y: 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct RunAllButtonStyle: ButtonStyle {
    let isDisabled: Bool
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isDisabled ? Color.gray.opacity(0.1) : Color.green.opacity(0.13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isDisabled ? Color.gray.opacity(0.2) : Color.green.opacity(0.35), lineWidth: 1)
                    )
            )
            .foregroundColor(isDisabled ? Color.gray.opacity(0.6) : Color.green)
            .shadow(color: isHovered && !configuration.isPressed && !isDisabled ? .black.opacity(0.15) : .clear, radius: isHovered ? 3 : 0, x: 0, y: isHovered ? 1 : 0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .onHover { hovering in
                if !isDisabled {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
            }
    }
}

// MARK: - Toggle Style

struct BlueSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 24)
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .offset(x: configuration.isOn ? 8 : -8)
                    .shadow(radius: 1)
            }
            .animation(.easeInOut(duration: 0.18), value: configuration.isOn)
            .onTapGesture { configuration.isOn.toggle() }
        }
        .frame(width: 56)
        .contentShape(Rectangle())
    }
}



// MARK: - Preview

#Preview {
    ContentView()
} 