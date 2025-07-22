import os.log
import SwiftUI

/// Settings view for configuring user information and integration settings
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var configurationManager = ConfigurationManager.shared
    @StateObject private var userSettingsManager = UserSettingsManager.shared
    @StateObject private var emailService = EmailService.shared
    var body: some View {
        SettingsFormView(
            configurationManager: configurationManager,
            userSettingsManager: userSettingsManager,
            emailService: emailService,
            )
    }
}

struct SettingsFormView: View {
    @ObservedObject var configurationManager: ConfigurationManager
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    @Environment(\.dismiss) private var dismiss
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var shouldClearTestResult = false

    // Temporary settings for form state management
    @State private var tempSettings: UserSettings

    private let logger = Logger(subsystem: "com.odyssey.app", category: "SettingsView")

    init(
        configurationManager: ConfigurationManager,
        userSettingsManager: UserSettingsManager,
        emailService: EmailService
    ) {
        self.configurationManager = configurationManager
        self.userSettingsManager = userSettingsManager
        self.emailService = emailService
        // Initialize temp settings with current values
        self._tempSettings = State(initialValue: userSettingsManager.userSettings)
    }

    // Helper function to detect Gmail accounts
    private func isGmailAccount(_ email: String) -> Bool {
        let domain = email.components(separatedBy: "@").last?.lowercased() ?? ""
        return domain == "gmail.com" || domain.hasSuffix(".gmail.com")
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsHeader()
            Divider()
            SettingsContent(
                tempSettings: $tempSettings,
                userSettingsManager: userSettingsManager,
                emailService: emailService,
                isGmailAccount: isGmailAccount,
                )
            Divider()
            SettingsFooter(
                userSettingsManager: userSettingsManager,
                emailService: emailService,
                dismiss: dismiss,
                showingValidationAlert: $showingValidationAlert,
                validationMessage: $validationMessage,
                saveSettings: saveSettings,
                cancelSettings: cancelSettings,
                )
        }
        .frame(width: 440, height: 600)
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
        .onDisappear {
            emailService.lastTestResult = nil
        }
    }

    // MARK: - Actions

    private func saveSettings() {
        // Validate required fields
        if tempSettings.name.isEmpty {
            validationMessage = "Please enter your full name."
            showingValidationAlert = true
            return
        }

        if tempSettings.phoneNumber.isEmpty {
            validationMessage = "Please enter your phone number."
            showingValidationAlert = true
            return
        }

        if !tempSettings.isPhoneNumberValid {
            validationMessage = "Phone number must be exactly 10 digits."
            showingValidationAlert = true
            return
        }

        if tempSettings.imapEmail.isEmpty {
            validationMessage = "Please enter your email address."
            showingValidationAlert = true
            return
        }

        if !tempSettings.isEmailValid {
            validationMessage = "Please enter a valid email address."
            showingValidationAlert = true
            return
        }

        // IMAP server validation (only for non-Gmail accounts)
        if !isGmailAccount(tempSettings.imapEmail), tempSettings.imapServer.isEmpty {
            validationMessage = "Please enter your IMAP server address."
            showingValidationAlert = true
            return
        }

        if tempSettings.imapPassword.isEmpty {
            validationMessage = "Please enter your email password."
            showingValidationAlert = true
            return
        }

        // Gmail app password validation
        if isGmailAccount(tempSettings.imapEmail), !tempSettings.isGmailAppPasswordValid {
            validationMessage =
                "Gmail app password must be 16 characters with spaces every 4 (e.g., 'abcd efgh ijkl mnop'). Please check the format and try again."
            showingValidationAlert = true
            return
        }

        // Update the actual settings with temp values
        userSettingsManager.userSettings = tempSettings

        // Save settings to UserDefaults and Keychain
        userSettingsManager.saveSettings()

        // Store credentials in Keychain
        userSettingsManager.storeCredentialsInKeychain()

        // Close the window immediately
        dismiss()
    }

    private func cancelSettings() {
        // Revert temp settings to original values
        tempSettings = userSettingsManager.userSettings
        dismiss()
    }
}

private struct SettingsHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sportscourt.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

private struct SettingsContent: View {
    @Binding var tempSettings: UserSettings
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ContactInformationSection(
                    tempSettings: $tempSettings,
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    )
                Divider().padding(.horizontal, 4)
                EmailSettingsSection(
                    tempSettings: $tempSettings,
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    isGmailAccount: isGmailAccount,
                    )
                Divider().padding(.horizontal, 4)
                AdvancedSettingsSection(tempSettings: $tempSettings)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if emailService.lastTestResult != nil {
                    emailService.lastTestResult = nil
                }
            }
            .padding()
        }
    }
}

private struct ContactInformationSection: View {
    @Binding var tempSettings: UserSettings
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService

    var body: some View {
        settingsSection(
            title: "Contact Information",
            icon: "person.circle",
            ) {
            VStack(spacing: 16) {
                settingsField(
                    title: "Full Name",
                    value: $tempSettings.name,
                    placeholder: "John Doe",
                    icon: "person",
                    maxLength: 30,
                    )
                .onChange(of: tempSettings.name) { _, _ in
                    if emailService.lastTestResult != nil {
                        emailService.lastTestResult = nil
                    }
                }
                .accessibilityLabel("Full Name")

                settingsField(
                    title: "Phone Number",
                    value: $tempSettings.phoneNumber,
                    placeholder: "234567890",
                    icon: "phone",
                    maxLength: 10,
                    )
                .onChange(of: tempSettings.phoneNumber) { _, _ in
                    if emailService.lastTestResult != nil {
                        emailService.lastTestResult = nil
                    }
                }

                if
                    !tempSettings.phoneNumber.isEmpty,
                    !tempSettings.isPhoneNumberValid {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Phone number must be exactly 10 digits")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
        }
    }
}

private struct EmailSettingsSection: View {
    @Binding var tempSettings: UserSettings
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        settingsSection(
            title: "Email Settings",
            icon: "envelope.circle",
            ) {
            VStack(spacing: 16) {
                EmailAddressField(
                    tempSettings: $tempSettings,
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    isGmailAccount: isGmailAccount,
                    )
                IMAPServerField(
                    tempSettings: $tempSettings,
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    isGmailAccount: isGmailAccount,
                    )
                PasswordField(
                    tempSettings: $tempSettings,
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    isGmailAccount: isGmailAccount,
                    )
                TestEmailButton(
                    tempSettings: $tempSettings,
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    isGmailAccount: isGmailAccount,
                    )
            }
        }
    }
}

private struct AdvancedSettingsSection: View {
    @Binding var tempSettings: UserSettings

    var body: some View {
        settingsSection(title: "Advanced Settings", icon: "gearshape") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Toggle("", isOn: Binding(
                        get: { tempSettings.preventSleepForAutorun },
                        set: { newValue in
                            tempSettings.preventSleepForAutorun = newValue
                            print("🔧 Prevent sleep setting changed to: \(newValue)")
                        },
                        ))
                    Text("Prevent sleep before autorun (5:55pm)")
                    Spacer()
                }
                .help(
                    "If enabled, ODYSSEY will prevent your Mac from sleeping 5 minutes before autorun and allow sleep after reservations are done.",
                    )

                HStack {
                    Toggle("", isOn: Binding(
                        get: { tempSettings.autoCloseDebugWindowOnFailure },
                        set: { newValue in
                            tempSettings.autoCloseDebugWindowOnFailure = newValue
                            print("🔧 Auto close debug window setting changed to: \(newValue)")
                        },
                        ))
                    Text("Automatically close debug window on failure")
                    Spacer()
                }
                .help(
                    "If enabled, the debug window will close automatically after a reservation failure. If disabled, the window will remain open so you can inspect the error.",
                    )
            }
        }
    }
}

private struct SettingsFooter: View {
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let dismiss: DismissAction
    @Binding var showingValidationAlert: Bool
    @Binding var validationMessage: String
    let saveSettings: () -> Void
    let cancelSettings: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button("Cancel") {
                    cancelSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityLabel("Cancel")
                .keyboardShortcut(.escape)
                Button("Save") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .accessibilityLabel("Save Settings")
                .keyboardShortcut("s", modifiers: .command)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

// Helper views for email settings
private struct EmailAddressField: View {
    @Binding var tempSettings: UserSettings
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            settingsField(
                title: "Email Address",
                value: $tempSettings.imapEmail,
                placeholder: "your-email@domain.com",
                icon: "envelope",
                )
            .onChange(of: tempSettings.imapEmail) { _, newEmail in
                if isGmailAccount(newEmail) {
                    tempSettings.imapServer = "imap.gmail.com"
                }
                if emailService.lastTestResult != nil {
                    emailService.lastTestResult = nil
                }
            }
            .accessibilityLabel("Email Address")

            if
                !tempSettings.imapEmail.isEmpty,
                !tempSettings.isEmailValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Please enter a valid email address")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
    }
}

private struct IMAPServerField: View {
    @Binding var tempSettings: UserSettings
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        settingsField(
            title: "IMAP Server",
            value: $tempSettings.imapServer,
            placeholder: "mail.myserver.com",
            icon: "server.rack",
            isReadOnly: isGmailAccount(tempSettings.imapEmail),
            )
        .onChange(of: tempSettings.imapServer) { _, _ in
            if emailService.lastTestResult != nil {
                emailService.lastTestResult = nil
            }
        }
        .accessibilityLabel("IMAP Server")
    }
}

private struct PasswordField: View {
    @Binding var tempSettings: UserSettings
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            settingsField(
                title: isGmailAccount(tempSettings.imapEmail) ?
                    "Gmail App Password" : "Password",
                value: $tempSettings.imapPassword,
                placeholder: isGmailAccount(tempSettings.imapEmail) ?
                    "16-character app password" : "my-password",
                icon: "lock",
                isSecure: true,
                )
            .onChange(of: tempSettings.imapPassword) { _, _ in
                if emailService.lastTestResult != nil {
                    emailService.lastTestResult = nil
                }
            }
            .accessibilityLabel(
                isGmailAccount(tempSettings.imapEmail) ? "Gmail App Password" :
                    "Password",
                )

            // Gmail App Password validation
            if isGmailAccount(tempSettings.imapEmail), !tempSettings.imapPassword.isEmpty {
                if !tempSettings.isGmailAppPasswordValid {
                    HStack {
                        Spacer()
                        Link(
                            "How to create Gmail app password?",
                            destination: URL(string: "https://support.google.com/accounts/answer/185833")!,
                            )
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Gmail app password format is valid")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
        }
    }
}

private struct TestEmailButton: View {
    @Binding var tempSettings: UserSettings
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        VStack(spacing: 8) {
            if tempSettings.hasEmailConfigured {
                Button(action: {
                    // Temporarily update the actual settings for testing
                    let originalSettings = userSettingsManager.userSettings
                    userSettingsManager.userSettings = tempSettings

                    UserSettingsManager.shared.storeCredentialsInKeychain()
                    Task {
                        let result = await emailService.testIMAPConnection(
                            email: tempSettings.imapEmail,
                            password: tempSettings.imapPassword,
                            server: tempSettings.imapServer,
                            provider: isGmailAccount(tempSettings.imapEmail) ?
                                .gmail : .imap,
                            )
                        await MainActor.run {
                            emailService.lastTestResult = result
                            if result.isSuccess {
                                if isGmailAccount(tempSettings.imapEmail) {
                                    userSettingsManager.saveLastSuccessfulGmailConfig(
                                        email: tempSettings.imapEmail,
                                        appPassword: tempSettings.imapPassword,
                                        )
                                } else {
                                    userSettingsManager.saveLastSuccessfulIMAPConfig(
                                        email: tempSettings.imapEmail,
                                        password: tempSettings.imapPassword,
                                        server: tempSettings.imapServer,
                                        )
                                }
                            }
                            // Restore original settings
                            userSettingsManager.userSettings = originalSettings
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.badge")
                            .font(.system(size: 14))
                        Text("Test Email")
                            .font(.system(size: 13))
                    }
                }
                .buttonStyle(.bordered)
                .disabled(emailService.isTesting)
                .help("Test email and fetch latest email")
                .accessibilityLabel("Test Email")
            }

            if emailService.isTesting {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Testing email connection...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            if let result = emailService.lastTestResult {
                HStack {
                    Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.isSuccess ? .green : .red)
                    Text(result.description)
                        .font(.caption)
                        .foregroundColor(result.isSuccess ? .green : .red)
                    Spacer()
                }
                .padding(.top, 4)
                .onTapGesture {
                    emailService.lastTestResult = nil
                }
            }
        }
    }
}

// MARK: - Helper Views

@MainActor
private func settingsSection(title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
            Spacer()
        }

        content()
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    .cornerRadius(8)
}

@MainActor
private func settingsField(
    title: String,
    value: Binding<String>,
    placeholder: String,
    icon: String,
    isSecure: Bool = false,
    maxLength: Int? = nil,
    isReadOnly: Bool = false,
    ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 16)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }

        if isReadOnly {
            TextField(placeholder, text: value)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.secondary)
                .disabled(true)
        } else {
            if isSecure {
                SecureField(placeholder, text: value)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: value.wrappedValue) { _, newValue in
                        if let maxLength, newValue.count > maxLength {
                            value.wrappedValue = String(newValue.prefix(maxLength))
                        }
                    }
            } else {
                TextField(placeholder, text: value)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: value.wrappedValue) { _, newValue in
                        if let maxLength, newValue.count > maxLength {
                            value.wrappedValue = String(newValue.prefix(maxLength))
                        }
                    }
            }
        }
    }
}

#if DEBUG
final class PreviewSettingsMockEmailService: EmailServiceProtocol, ObservableObject {
    @Published var isTesting: Bool = false
    @Published var lastTestResult: EmailService.TestResult?
    @Published var userFacingError: String?
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Task { @MainActor in
            ServiceRegistry.shared.register(PreviewSettingsMockEmailService(), for: EmailServiceProtocol.self)
        }
        return SettingsView()
    }
}
#endif
