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
    @State private var showingSaveConfirmation = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var shouldClearTestResult = false

    private let logger = Logger(subsystem: "com.odyssey.app", category: "SettingsView")

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
                userSettingsManager: userSettingsManager,
                emailService: emailService,
                isGmailAccount: isGmailAccount,
                )
            Divider()
            SettingsFooter(
                userSettingsManager: userSettingsManager,
                emailService: emailService,
                dismiss: dismiss,
                showingSaveConfirmation: $showingSaveConfirmation,
                showingValidationAlert: $showingValidationAlert,
                validationMessage: $validationMessage,
                saveSettings: saveSettings,
                )
        }
        .frame(width: 440, height: 600)
        .alert("Settings Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your settings have been saved successfully.")
        }
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
        if userSettingsManager.userSettings.name.isEmpty {
            validationMessage = "Please enter your full name."
            showingValidationAlert = true
            return
        }

        if userSettingsManager.userSettings.phoneNumber.isEmpty {
            validationMessage = "Please enter your phone number."
            showingValidationAlert = true
            return
        }

        if !userSettingsManager.userSettings.isPhoneNumberValid {
            validationMessage = "Phone number must be exactly 10 digits."
            showingValidationAlert = true
            return
        }

        if userSettingsManager.userSettings.imapEmail.isEmpty {
            validationMessage = "Please enter your email address."
            showingValidationAlert = true
            return
        }

        if !userSettingsManager.userSettings.isEmailValid {
            validationMessage = "Please enter a valid email address."
            showingValidationAlert = true
            return
        }

        if userSettingsManager.userSettings.imapServer.isEmpty {
            validationMessage = "Please enter your IMAP server address."
            showingValidationAlert = true
            return
        }

        if userSettingsManager.userSettings.imapPassword.isEmpty {
            validationMessage = "Please enter your email password."
            showingValidationAlert = true
            return
        }

        // Settings are automatically saved by UserSettingsManager
        // No confirmation dialog needed
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
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ContactInformationSection(
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    )
                Divider().padding(.horizontal, 4)
                EmailSettingsSection(
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    isGmailAccount: isGmailAccount,
                    )
                Divider().padding(.horizontal, 4)
                SleepPreventionSection(userSettingsManager: userSettingsManager)
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
                    value: $userSettingsManager.userSettings.name,
                    placeholder: "John Doe",
                    icon: "person",
                    maxLength: 30,
                    )
                .onChange(of: userSettingsManager.userSettings.name) { _, _ in
                    if emailService.lastTestResult != nil {
                        emailService.lastTestResult = nil
                    }
                }

                settingsField(
                    title: "Phone Number",
                    value: $userSettingsManager.userSettings.phoneNumber,
                    placeholder: "234567890",
                    icon: "phone",
                    maxLength: 10,
                    )
                .onChange(of: userSettingsManager.userSettings.phoneNumber) { _, _ in
                    if emailService.lastTestResult != nil {
                        emailService.lastTestResult = nil
                    }
                }

                if
                    !userSettingsManager.userSettings.phoneNumber.isEmpty,
                    !userSettingsManager.userSettings.isPhoneNumberValid {
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
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    isGmailAccount: isGmailAccount,
                    )
                IMAPServerField(
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    isGmailAccount: isGmailAccount,
                    )
                PasswordField(
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    isGmailAccount: isGmailAccount,
                    )
                TestEmailButton(
                    userSettingsManager: userSettingsManager,
                    emailService: emailService,
                    isGmailAccount: isGmailAccount,
                    )
            }
        }
    }
}

private struct SleepPreventionSection: View {
    @ObservedObject var userSettingsManager: UserSettingsManager

    var body: some View {
        Toggle(isOn: $userSettingsManager.userSettings.preventSleepForAutorun) {
            Text("Prevent sleep before autorun (5:55pm)")
        }
        .help(
            "If enabled, ODYSSEY will prevent your Mac from sleeping 5 minutes before autorun and allow sleep after reservations are done.",
            )
    }
}

private struct SettingsFooter: View {
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let dismiss: DismissAction
    @Binding var showingSaveConfirmation: Bool
    @Binding var showingValidationAlert: Bool
    @Binding var validationMessage: String
    let saveSettings: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                Button("Save") {
                    UserSettingsManager.shared.saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

// Helper views for email settings
private struct EmailAddressField: View {
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            settingsField(
                title: "Email Address",
                value: $userSettingsManager.userSettings.imapEmail,
                placeholder: "your-email@domain.com",
                icon: "envelope",
                )
            .onChange(of: userSettingsManager.userSettings.imapEmail) { _, newEmail in
                if isGmailAccount(newEmail) {
                    userSettingsManager.userSettings.imapServer = "imap.gmail.com"
                }
                if emailService.lastTestResult != nil {
                    emailService.lastTestResult = nil
                }
            }

            if
                !userSettingsManager.userSettings.imapEmail.isEmpty,
                !userSettingsManager.userSettings.isEmailValid {
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
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        settingsField(
            title: "IMAP Server",
            value: $userSettingsManager.userSettings.imapServer,
            placeholder: "mail.myserver.com",
            icon: "server.rack",
            isReadOnly: isGmailAccount(userSettingsManager.userSettings.imapEmail),
            )
        .onChange(of: userSettingsManager.userSettings.imapServer) { _, _ in
            if emailService.lastTestResult != nil {
                emailService.lastTestResult = nil
            }
        }
    }
}

private struct PasswordField: View {
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            settingsField(
                title: isGmailAccount(userSettingsManager.userSettings.imapEmail) ?
                    "Gmail App Password" : "Password",
                value: $userSettingsManager.userSettings.imapPassword,
                placeholder: isGmailAccount(userSettingsManager.userSettings.imapEmail) ?
                    "16-character app password" : "my-password",
                icon: "lock",
                isSecure: true,
                )
            .onChange(of: userSettingsManager.userSettings.imapPassword) { _, _ in
                if emailService.lastTestResult != nil {
                    emailService.lastTestResult = nil
                }
            }

            if isGmailAccount(userSettingsManager.userSettings.imapEmail) {
                if
                    !userSettingsManager.userSettings.imapPassword.isEmpty,
                    !userSettingsManager.userSettings.isGmailAppPasswordValid {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        HStack(spacing: 0) {
                            Text("Gmail App Password must be in ")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Button("format") {
                                if let url = URL(string: AppConstants.gmailAppPasswordURL) {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                            .font(.caption)
                            Text(": 'xxxx xxxx xxxx xxxx'")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

private struct TestEmailButton: View {
    @ObservedObject var userSettingsManager: UserSettingsManager
    @ObservedObject var emailService: EmailService
    let isGmailAccount: (String) -> Bool

    var body: some View {
        VStack(spacing: 8) {
            if userSettingsManager.userSettings.hasEmailConfigured {
                Button(action: {
                    UserSettingsManager.shared.storeCredentialsInKeychain()
                    Task {
                        let result = await emailService.testIMAPConnection(
                            email: userSettingsManager.userSettings.imapEmail,
                            password: userSettingsManager.userSettings.imapPassword,
                            server: userSettingsManager.userSettings.imapServer,
                            provider: isGmailAccount(userSettingsManager.userSettings.imapEmail) ?
                                .gmail : .imap,
                            )
                        await MainActor.run {
                            emailService.lastTestResult = result
                            if result.isSuccess {
                                if isGmailAccount(userSettingsManager.userSettings.imapEmail) {
                                    userSettingsManager.saveLastSuccessfulGmailConfig(
                                        email: userSettingsManager.userSettings.imapEmail,
                                        appPassword: userSettingsManager.userSettings.imapPassword,
                                        )
                                } else {
                                    userSettingsManager.saveLastSuccessfulIMAPConfig(
                                        email: userSettingsManager.userSettings.imapEmail,
                                        password: userSettingsManager.userSettings.imapPassword,
                                        server: userSettingsManager.userSettings.imapServer,
                                        )
                                }
                            }
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
