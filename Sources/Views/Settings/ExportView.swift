import SwiftUI

struct ExportView: View {
    @ObservedObject var configurationManager: ConfigurationManager
    @StateObject private var cliExportService = CLIExportService()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedConfigIds: Set<String> = []
    @State private var exportToken: String = ""
    @State private var isExporting: Bool = false
    @State private var errorMessage: String?

    init(configurationManager: ConfigurationManager) {
        print(
            "DEBUG: ExportView init called with \(configurationManager.settings.configurations.count) configurations",
        )
        self.configurationManager = configurationManager
    }

    var body: some View {
        let configs = configurationManager.settings.configurations

        ZStack {
            Color.odysseyBackground.ignoresSafeArea()
            VStack(spacing: AppConstants.spacingNone) {
                // Header section - styled like other views
                HStack(spacing: AppConstants.spacingLarge) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: AppConstants.primaryFont))
                        .foregroundColor(.accentColor)
                    Text("Export Configurations")
                        .font(.system(size: AppConstants.primaryFont))
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, AppConstants.contentPadding)
                .padding(.vertical, AppConstants.contentPadding)

                Divider().padding(.horizontal, AppConstants.contentPadding)

                // Configuration selection section
                ScrollView {
                    VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {
                        HStack {
                            Text("Select Configurations")
                                .font(.system(size: AppConstants.primaryFont))
                                .fontWeight(.semibold)
                            Spacer()
                            Button("Select All") {
                                selectedConfigIds = Set(configs.map(\.id.uuidString))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .font(.system(size: AppConstants.fontBody))
                        }
                        .padding(.top, AppConstants.paddingMedium)

                        if configs.isEmpty {
                            VStack(spacing: AppConstants.spacingLarge) {
                                Image(systemName: "sportscourt.fill")
                                    .font(.system(size: AppConstants.iconLarge))
                                    .foregroundColor(.odysseySecondaryText)
                                VStack(spacing: AppConstants.spacingSmall) {
                                    Text("No Configurations Available")
                                        .font(.system(size: AppConstants.primaryFont))
                                        .fontWeight(.semibold)
                                    Text("Please add a configuration first to export")
                                        .font(.system(size: AppConstants.secondaryFont))
                                        .foregroundColor(.odysseySecondaryText)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(AppConstants.contentPadding)
                        } else {
                            LazyVStack(spacing: AppConstants.spacingNone) {
                                ForEach(configs, id: \.id) { config in
                                    ConfigurationSelectionRow(
                                        config: config,
                                        isSelected: selectedConfigIds.contains(config.id.uuidString),
                                        onToggle: { selected in
                                            let configId = config.id.uuidString
                                            if selected {
                                                selectedConfigIds.insert(configId)
                                            } else {
                                                selectedConfigIds.remove(configId)
                                            }
                                        },
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.contentPadding)
                }

                // Footer section - styled like other views
                Divider().padding(.horizontal, AppConstants.contentPadding)
                HStack {
                    Button("Export Token") {
                        Task {
                            await generateExportToken()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedConfigIds.isEmpty || isExporting)
                    .font(.system(size: AppConstants.fontBody))
                    .controlSize(.regular)
                    .accessibilityLabel("Export Token")

                    if isExporting {
                        HStack(spacing: AppConstants.spacingSmall) {
                            ProgressView()
                                .scaleEffect(AppConstants.scaleEffectSmall)
                            Text("Generating token...")
                                .font(.system(size: AppConstants.fontBody))
                        }
                    }

                    if !exportToken.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.odysseySuccess)
                            Text("Token copied to clipboard")
                                .font(.system(size: AppConstants.fontBody))
                                .foregroundColor(.odysseySuccess)
                        }
                    }

                    if let errorMessage {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.odysseyError)
                            Text(errorMessage)
                                .font(.system(size: AppConstants.fontBody))
                                .foregroundColor(.odysseyError)
                        }
                    }

                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .accessibilityLabel("Done")
                    .keyboardShortcut(.escape)
                }
                .padding(.horizontal, AppConstants.contentPadding)
                .padding(.vertical, AppConstants.contentPadding)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(width: AppConstants.windowMainWidth, height: AppConstants.windowMainHeight)
    }

    private func generateExportToken() async {
        isExporting = true
        errorMessage = nil
        do {
            let token = try await cliExportService.exportForCLI(selectedConfigIds: Array(selectedConfigIds))
            await MainActor.run {
                exportToken = token
                isExporting = false

                // Copy token to clipboard
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(token, forType: .string)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isExporting = false
            }
        }
    }
}

struct ConfigurationSelectionRow: View {
    let config: ReservationConfig
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button(action: { onToggle(!isSelected) }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .odysseyAccent : .odysseySecondaryText)
                    .font(.system(size: AppConstants.iconTiny))
                VStack(alignment: .leading, spacing: AppConstants.spacingTiny) {
                    Text(config.name)
                        .font(.system(size: AppConstants.fontBody))
                        .fontWeight(.medium)
                    Text("\(config.sportName) • \(ReservationConfig.extractFacilityName(from: config.facilityURL))")
                        .font(.system(size: AppConstants.tertiaryFont))
                        .foregroundColor(.odysseySecondaryText)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, AppConstants.paddingSmall)
        .padding(.horizontal, AppConstants.contentPadding)
    }
}
