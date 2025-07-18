import os.log
import SwiftUI

/// Settings view for configuring user information and integration settings
struct SettingsView: View {
    var body: some View {
        SettingsFormView()
    }
}

struct SettingsFormView: View {
    @ObservedObject var configurationManager = ConfigurationManager.shared
    @ObservedObject var userSettingsManager = UserSettingsManager.shared
    @ObservedObject var emailService = EmailService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveConfirmation = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    init() {
        // Setup notification categories for development builds
        // Remove setupNotificationCategories function and all notification-related code
    }

    private let logger = Logger(subsystem: "com.odyssey.app", category: "SettingsView")

    // Helper function to detect Gmail accounts
    private func isGmailAccount(_ email: String) -> Bool {
        let domain = email.components(separatedBy: "@").last?.lowercased() ?? ""
        return domain == "gmail.com" || domain.hasSuffix(".gmail.com")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
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

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 12) {
                    // Contact Information Section
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

                            settingsField(
                                title: "Phone Number",
                                value: $userSettingsManager.userSettings.phoneNumber,
                                placeholder: "234567890",
                                icon: "phone",
                                maxLength: 10,
                                )

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
                    Divider().padding(.horizontal, 4)
                    // Email Settings Section
                    settingsSection(
                        title: "Email Settings",
                        icon: "envelope.circle",
                        ) {
                        VStack(spacing: 16) {
                            // Email Address Field
                            settingsField(
                                title: "Email Address",
                                value: $userSettingsManager.userSettings.imapEmail,
                                placeholder: "your-email@domain.com",
                                icon: "envelope",
                                )
                            .onChange(of: userSettingsManager.userSettings.imapEmail) { _, newEmail in
                                // Auto-set IMAP server for Gmail accounts
                                if isGmailAccount(newEmail) {
                                    userSettingsManager.userSettings.imapServer = "imap.gmail.com"
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

                            // IMAP Server Field (auto-filled for Gmail)
                            settingsField(
                                title: "IMAP Server",
                                value: $userSettingsManager.userSettings.imapServer,
                                placeholder: "mail.myserver.com",
                                icon: "server.rack",
                                isReadOnly: isGmailAccount(userSettingsManager.userSettings.imapEmail),
                                )

                            // Password/App Password Field
                            settingsField(
                                title: isGmailAccount(userSettingsManager.userSettings.imapEmail) ?
                                    "Gmail App Password" :
                                    "Password",
                                value: $userSettingsManager.userSettings.imapPassword,
                                placeholder: isGmailAccount(userSettingsManager.userSettings.imapEmail) ?
                                    "16-character app password" : "my-password",
                                icon: "lock",
                                isSecure: true,
                                )

                            // Gmail App Password validation and help
                            if isGmailAccount(userSettingsManager.userSettings.imapEmail) {
                                if
                                    !userSettingsManager.userSettings.imapPassword.isEmpty,
                                    !userSettingsManager.userSettings.isGmailAppPasswordValid {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text(
                                            "Gmail App Password must be in format: 'xxxx xxxx xxxx xxxx' " +
                                                "(16 lowercase letters with spaces every 4 characters)",
                                            )
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        Spacer()
                                    }
                                }

                                HStack {
                                    Button("How to create Gmail App Password") {
                                        if let url = URL(string: "https://support.google.com/accounts/answer/185833") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                    .help("Opens Google's guide to creating app passwords")
                                    Spacer()
                                }
                            }

                            // Test Email Connection Button
                            if userSettingsManager.userSettings.hasEmailConfigured {
                                Button("Test Email") {
                                    emailService.lastTestResult = nil
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
                                }
                                .buttonStyle(.bordered)
                                .disabled(emailService.isTesting)
                                .help("Test email and fetch latest email")
                            }

                            // Test Results Section
                            if emailService.isTesting {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(
                                        "Testing email connection...",
                                        )
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                            if let result = emailService.lastTestResult {
                                HStack {
                                    Image(
                                        systemName: result
                                            .isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill",
                                        )
                                    .foregroundColor(result.isSuccess ? .green : .red)
                                    Text(result.description)
                                        .font(.caption)
                                        .foregroundColor(result.isSuccess ? .green : .red)
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    // Removed Divider after email settings section
                    // Divider().padding(.horizontal, 4)

                    // Notification Settings Section
                    // Removed NotificationSettingsSection
                }
                .padding()
            }

            // Bottom button bar
            Divider()
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(!userSettingsManager.userSettings.isValid)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
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
    }

    // MARK: - Helper Views

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
