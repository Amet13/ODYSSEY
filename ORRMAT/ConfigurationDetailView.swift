import SwiftUI

// MARK: - Custom Hover Styles

struct HoverTextFieldStyle: TextFieldStyle {
    @State private var isHovered = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isHovered ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: isHovered ? 2 : 1)
                    )
            )
            .shadow(color: isHovered ? .black.opacity(0.1) : .clear, radius: isHovered ? 2 : 0, x: 0, y: isHovered ? 1 : 0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

struct HoverMenuStyle: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isHovered ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: isHovered ? 2 : 1)
                    )
            )
            .shadow(color: isHovered ? .black.opacity(0.1) : .clear, radius: isHovered ? 2 : 0, x: 0, y: isHovered ? 1 : 0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

struct HoverRadioButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isHovered ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .shadow(color: isHovered ? .black.opacity(0.05) : .clear, radius: isHovered ? 2 : 0, x: 0, y: isHovered ? 1 : 0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

struct HoverIconButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background(
                Circle()
                    .fill(isHovered ? Color.blue.opacity(0.1) : Color.clear)
            )
            .shadow(color: isHovered ? .black.opacity(0.1) : .clear, radius: isHovered ? 3 : 0, x: 0, y: isHovered ? 1 : 0)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

struct HoverDatePickerStyle: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isHovered ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: isHovered ? 1.5 : 1)
                    )
            )
            .shadow(color: isHovered ? .black.opacity(0.05) : .clear, radius: isHovered ? 1 : 0, x: 0, y: isHovered ? 1 : 0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

/// Detailed view for adding and editing reservation configurations
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Basic Settings Section
                Group {
                    Text("Basic Settings")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Facility URL")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        TextField("Enter facility URL", text: $facilityURL)
                            .textFieldStyle(HoverTextFieldStyle())
                            .onChange(of: facilityURL) { _ in
                                updateConfigurationName()
                            }
                        if !facilityURL.isEmpty && !isValidFacilityURL(facilityURL) {
                            Text("Invalid facility URL. Please enter a valid Ottawa Recreation URL.")
                                .font(.caption)
                                .foregroundColor(.red)
                            Link("View Ottawa Facilities", destination: URL(string: "https://ottawa.ca/en/recreation-and-parks/recreation-facilities")!)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sport Name")
                            .font(.subheadline)
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
                                                Text(sport)
                                                if sportName == sport {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
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
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .modifier(HoverMenuStyle())
                            .disabled(availableSports.isEmpty)
                            
                            if !facilityURL.isEmpty && isValidFacilityURL(facilityURL) {
                                Button(action: {
                                    fetchAvailableSports()
                                }) {
                                    Image(systemName: isFetchingSports ? "arrow.clockwise" : "magnifyingglass")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(HoverIconButtonStyle())
                                .disabled(isFetchingSports)
                            }
                        }
                        
                        if isFetchingSports {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Fetching available sports...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !availableSports.isEmpty {
                            Text("\(availableSports.count) sports found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of People")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        HStack(spacing: 20) {
                            Button(action: {
                                numberOfPeople = 1
                                updateConfigurationName()
                            }) {
                                HStack {
                                    Image(systemName: numberOfPeople == 1 ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(numberOfPeople == 1 ? .blue : .gray)
                                    Text("1 Person")
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(HoverRadioButtonStyle())
                            
                            Button(action: {
                                numberOfPeople = 2
                                updateConfigurationName()
                            }) {
                                HStack {
                                    Image(systemName: numberOfPeople == 2 ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(numberOfPeople == 2 ? .blue : .gray)
                                    Text("2 People")
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(HoverRadioButtonStyle())
                            
                            Spacer()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Configuration Name")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        TextField("Configuration Name", text: $name)
                            .textFieldStyle(HoverTextFieldStyle())
                    }
                }
                Divider()
                // Scheduling Section
                Group {
                    Text("Scheduling")
                        .font(.headline)
                        .foregroundColor(.primary)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Time Slots")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            StyledButton("Add Day") {
                                showDayPicker = true
                            }
                            .controlSize(.small)
                            .buttonStyle(IconHoverButtonStyle())
                        }
                        
                        if dayTimeSlots.isEmpty {
                            Text("No days selected. Click 'Add Day' to start scheduling.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            let weekdayOrder: [ReservationConfig.Weekday] = [
                                .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
                            ]
                            ForEach(Array(dayTimeSlots.keys.sorted { lhs, rhs in
                                weekdayOrder.firstIndex(of: lhs)! < weekdayOrder.firstIndex(of: rhs)!
                            }), id: \.self) { day in
                                DayTimeSlotEditor(
                                    day: day,
                                    slots: Binding(
                                        get: { dayTimeSlots[day] ?? [TimeSlot(time: Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date())] },
                                        set: { dayTimeSlots[day] = $0 }
                                    ),
                                    onAdd: { addTimeSlot(for: day) },
                                    onRemove: { idx in removeTimeSlot(for: day, at: idx) },
                                    onRemoveDay: { removeDay(day) }
                                )
                            }
                        }
                    }
                }
                Divider()
                // Preview Section
                Group {
                    Text("Preview")
                        .font(.headline)
                        .foregroundColor(.primary)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name: \(name.isEmpty ? "Not set" : name)")
                        Text("Sport: \(sportName.isEmpty ? "Not set" : sportName)")
                        Text("People: \(numberOfPeople)")
                        if !dayTimeSlots.isEmpty {
                            let weekdayOrder: [ReservationConfig.Weekday] = [
                                .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
                            ]
                            let sortedDays = dayTimeSlots.keys.sorted { lhs, rhs in
                                weekdayOrder.firstIndex(of: lhs)! < weekdayOrder.firstIndex(of: rhs)!
                            }
                            ForEach(sortedDays, id: \.self) { day in
                                let slots = dayTimeSlots[day] ?? []
                                let times = slots.map { $0.time.formatted(date: .omitted, time: .shortened) }.joined(separator: ", ")
                                if !times.isEmpty {
                                    Text("\(day.shortName): \(times)")
                                }
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(24)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .frame(minWidth: 420, maxWidth: 480, minHeight: 540, maxHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle(config == nil ? "Add Reservation Configuration" : "Edit Reservation Configuration")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                StyledButton("Cancel", role: .cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                StyledButton("Save", isDisabled: !isValidConfiguration) {
                    if isValidConfiguration {
                        saveConfiguration()
                    } else {
                        validationMessage = "Please fill in all required fields with valid data."
                        showingValidationAlert = true
                    }
                }
            }
        }
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
        .onAppear {
            loadConfiguration()
        }
        .sheet(isPresented: $showDayPicker) {
            DayPickerView(selectedDays: Set(dayTimeSlots.keys), onAdd: { day in
                if dayTimeSlots[day] == nil {
                    dayTimeSlots[day] = [TimeSlot(time: Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date())]
                }
            })
        }
    }
    
    // MARK: - Private Methods
    
    private func loadConfiguration() {
        guard let config = config else { return }
        
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
            dayTimeSlots: dayTimeSlots
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
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) {
            let facilityRange = Range(match.range(at: 1), in: url)!
            let facilityName = String(url[facilityRange])
            return facilityName.capitalized
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
        guard !facilityURL.isEmpty && isValidFacilityURL(facilityURL) else { return }
        
        isFetchingSports = true
        availableSports = []
        
        FacilityService.shared.fetchAvailableSports(from: facilityURL) { sports in
            DispatchQueue.main.async {
                self.isFetchingSports = false
                self.availableSports = sports
            }
        }
    }
    
    private func addTimeSlot(for day: ReservationConfig.Weekday) {
        let newTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
        if dayTimeSlots[day] == nil {
            dayTimeSlots[day] = [TimeSlot(time: newTime)]
        } else {
            dayTimeSlots[day]?.append(TimeSlot(time: newTime))
        }
    }
    private func removeTimeSlot(for day: ReservationConfig.Weekday, at index: Int) {
        if dayTimeSlots[day]?.count ?? 0 > 1 {
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
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(HoverRadioButtonStyle())
            }
            
            HStack {
                Spacer()
                StyledButton("Cancel", role: .cancel) {
                    dismiss()
                }
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
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(IconHoverButtonStyle())
                Button(action: onRemoveDay) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(HoverIconButtonStyle())
            }
            ForEach(Array(slots.enumerated().sorted { $0.element.time < $1.element.time }), id: \.element.id) { index, timeSlot in
                HStack {
                    DatePicker("", selection: Binding(
                        get: { slots[index].time },
                        set: { newTime in
                            slots[index] = TimeSlot(time: newTime)
                        }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .modifier(HoverDatePickerStyle())
                    Button(action: { onRemove(index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(HoverIconButtonStyle())
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