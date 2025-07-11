import os.log
import SwiftUI

/// Settings view for configuring user information and integration settings
struct SettingsView: View {
    @ObservedObject var configurationManager = ConfigurationManager.shared
    @ObservedObject var userSettingsManager = UserSettingsManager.shared
    @ObservedObject var telegramService = TelegramService.shared
    @ObservedObject var emailService = EmailService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveConfirmation = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    private let logger = Logger(subsystem: "com.odyssey.app", category: "SettingsView")

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!userSettingsManager.userSettings.isValid)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Contact Information Section
                    settingsSection(title: "Contact Information", icon: "person.circle") {
                        VStack(spacing: 16) {
                            settingsField(
                                title: "Full Name",
                                value: $userSettingsManager.userSettings.name,
                                placeholder: "John Doe",
                                icon: "person"
                            )

                            settingsField(
                                title: "Phone Number",
                                value: $userSettingsManager.userSettings.phoneNumber,
                                placeholder: "234567890",
                                icon: "phone",
                                maxLength: 10
                            )

                            if !userSettingsManager.userSettings.phoneNumber.isEmpty && !userSettingsManager.userSettings.isPhoneNumberValid {
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
                    Divider().padding(.horizontal)
                    // Email Settings Section
                    settingsSection(title: "Email Settings", icon: "envelope.circle") {
                        VStack(spacing: 16) {
                            settingsField(
                                title: "Email Address",
                                value: $userSettingsManager.userSettings.imapEmail,
                                placeholder: "my-email@my-domain.com",
                                icon: "envelope"
                            )

                            if !userSettingsManager.userSettings.imapEmail.isEmpty && !userSettingsManager.userSettings.isEmailValid {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Please enter a valid email address")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Spacer()
                                }
                            }

                            settingsField(
                                title: "IMAP Server",
                                value: $userSettingsManager.userSettings.imapServer,
                                placeholder: "mail.myserver.com",
                                icon: "server.rack"
                            )

                            settingsField(
                                title: "Password",
                                value: $userSettingsManager.userSettings.imapPassword,
                                placeholder: "my-password",
                                icon: "lock",
                                isSecure: true
                            )

                            if userSettingsManager.userSettings.hasEmailConfigured {
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Email settings configured")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }

                                    Button("Test IMAP Connection") {
                                        emailService.lastTestResult = nil
                                        Task {
                                            let result = await emailService.testIMAPConnection(
                                                email: userSettingsManager.userSettings.imapEmail,
                                                password: userSettingsManager.userSettings.imapPassword,
                                                server: userSettingsManager.userSettings.imapServer
                                            )
                                            await MainActor.run {
                                                emailService.lastTestResult = result
                                            }
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.blue)
                                    .disabled(emailService.isTesting)
                                    .help("Test IMAP connection and fetch latest email")

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
                                    }
                                }
                            }
                        }
                    }
                    Divider().padding(.horizontal)
                    // Telegram Integration Section
                    settingsSection(title: "Telegram Integration (Optional)", icon: "message.circle") {
                        VStack(spacing: 16) {
                            Toggle("Enable Telegram Integration", isOn: $userSettingsManager.userSettings.telegramEnabled)
                                .help("Enable or disable Telegram notifications")

                            if userSettingsManager.userSettings.telegramEnabled {
                                settingsField(
                                    title: "Bot Token",
                                    value: $userSettingsManager.userSettings.telegramBotToken,
                                    placeholder: "12345:AABBCCDDEEFFGG",
                                    icon: "key",
                                    isSecure: true
                                )

                                if !userSettingsManager.userSettings.telegramBotToken.isEmpty && !userSettingsManager.userSettings.isTelegramBotTokenValid {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("Bot token format: number:letters (e.g., 12345:ABCdefGHIjkl)")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Spacer()
                                    }
                                }

                                settingsField(
                                    title: "Chat ID",
                                    value: $userSettingsManager.userSettings.telegramChatId,
                                    placeholder: "12345678",
                                    icon: "number"
                                )

                                if !userSettingsManager.userSettings.telegramChatId.isEmpty && !userSettingsManager.userSettings.isTelegramChatIdValid {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("Chat ID can only contain numbers")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Spacer()
                                    }
                                }

                                if userSettingsManager.userSettings.hasTelegramConfigured {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Telegram integration configured")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                        }

                                        Button("Test Telegram Connection") {
                                            Task {
                                                let result = await telegramService.testIntegration(
                                                    botToken: userSettingsManager.userSettings.telegramBotToken,
                                                    chatId: userSettingsManager.userSettings.telegramChatId
                                                )
                                                await MainActor.run {
                                                    telegramService.lastTestResult = result
                                                }
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.blue)
                                        .disabled(telegramService.isTesting)
                                        .help("Send a test message to verify Telegram integration")

                                        if telegramService.isTesting {
                                            HStack {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                Text("Sending test message...")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                            }
                                        }

                                        if let result = telegramService.lastTestResult {
                                            HStack {
                                                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                    .foregroundColor(result.isSuccess ? .green : .red)
                                                Text(result.description)
                                                    .font(.caption)
                                                    .foregroundColor(result.isSuccess ? .green : .red)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
        .alert("Settings Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your settings have been saved successfully.")
        }
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") {}
        } message: {
            Text(validationMessage)
        }
    }

    // MARK: - Helper Views

    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
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

    private func settingsField(title: String, value: Binding<String>, placeholder: String, icon: String, isSecure: Bool = false, maxLength: Int? = nil) -> some View {
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

            if isSecure {
                SecureField(placeholder, text: value)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: value.wrappedValue) { newValue in
                        if let maxLength = maxLength, newValue.count > maxLength {
                            value.wrappedValue = String(newValue.prefix(maxLength))
                        }
                    }
            } else {
                TextField(placeholder, text: value)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: value.wrappedValue) { newValue in
                        if let maxLength = maxLength, newValue.count > maxLength {
                            value.wrappedValue = String(newValue.prefix(maxLength))
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

        // Validate Telegram settings if enabled
        if userSettingsManager.userSettings.telegramEnabled {
            if userSettingsManager.userSettings.telegramBotToken.isEmpty {
                validationMessage = "Please enter your Telegram bot token."
                showingValidationAlert = true
                return
            }

            if !userSettingsManager.userSettings.isTelegramBotTokenValid {
                validationMessage = "Invalid bot token format. Expected format: number:letters"
                showingValidationAlert = true
                return
            }

            if userSettingsManager.userSettings.telegramChatId.isEmpty {
                validationMessage = "Please enter your Telegram chat ID."
                showingValidationAlert = true
                return
            }

            if !userSettingsManager.userSettings.isTelegramChatIdValid {
                validationMessage = "Telegram Chat ID can only contain numbers."
                showingValidationAlert = true
                return
            }
        }

        // Settings are automatically saved by UserSettingsManager
        // No confirmation dialog needed
    }
}
