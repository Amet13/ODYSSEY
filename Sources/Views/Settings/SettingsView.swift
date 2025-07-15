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
    @ObservedObject var telegramService = TelegramService.shared
    @ObservedObject var emailService = EmailService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveConfirmation = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    private let logger = Logger(subsystem: "com.odyssey.app", category: "SettingsView")

    // Helper function to detect Gmail accounts
    private func isGmailAccount(_ email: String) -> Bool {
        let domain = email.components(separatedBy: "@").last?.lowercased() ?? ""
        return domain == "gmail.com" || domain.hasSuffix(".gmail.com")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(userSettingsManager.userSettings.localized("Settings"))
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
                    // Language Section
                    settingsSection(title: userSettingsManager.userSettings.localized("Language"), icon: "globe") {
                        Picker(
                            userSettingsManager.userSettings.localized("App Language"),
                            selection: $userSettingsManager.userSettings.language,
                        ) {
                            ForEach(UserSettings.Language.allCases) { lang in
                                Text(lang.rawValue).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                        .help(userSettingsManager.userSettings.localized("Choose the language for the app interface"))
                    }
                    Divider().padding(.horizontal, 4)
                    // Contact Information Section
                    settingsSection(
                        title: userSettingsManager.userSettings.localized("Contact Information"),
                        icon: "person.circle",
                    ) {
                        VStack(spacing: 16) {
                            settingsField(
                                title: userSettingsManager.userSettings.localized("Full Name"),
                                value: $userSettingsManager.userSettings.name,
                                placeholder: "John Doe",
                                icon: "person",
                                maxLength: 30,
                            )

                            settingsField(
                                title: userSettingsManager.userSettings.localized("Phone Number"),
                                value: $userSettingsManager.userSettings.phoneNumber,
                                placeholder: "234567890",
                                icon: "phone",
                                maxLength: 10,
                            )

                            if
                                !userSettingsManager.userSettings.phoneNumber.isEmpty,
                                !userSettingsManager.userSettings.isPhoneNumberValid
                            {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(
                                        userSettingsManager.userSettings
                                            .localized("Phone number must be exactly 10 digits"),
                                    )
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
                        title: userSettingsManager.userSettings.localized("Email Settings"),
                        icon: "envelope.circle",
                    ) {
                        VStack(spacing: 16) {
                            // Email Address Field
                            settingsField(
                                title: userSettingsManager.userSettings.localized("Email Address"),
                                value: $userSettingsManager.userSettings.imapEmail,
                                placeholder: "your-email@domain.com",
                                icon: "envelope",
                            )
                            .onChange(of: userSettingsManager.userSettings.imapEmail) { newEmail in
                                // Auto-set IMAP server for Gmail accounts
                                if isGmailAccount(newEmail) {
                                    userSettingsManager.userSettings.imapServer = "imap.gmail.com"
                                }
                            }

                            if
                                !userSettingsManager.userSettings.imapEmail.isEmpty,
                                !userSettingsManager.userSettings.isEmailValid
                            {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(
                                        userSettingsManager.userSettings
                                            .localized("Please enter a valid email address"),
                                    )
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    Spacer()
                                }
                            }

                            // IMAP Server Field (auto-filled for Gmail)
                            settingsField(
                                title: userSettingsManager.userSettings.localized("IMAP Server"),
                                value: $userSettingsManager.userSettings.imapServer,
                                placeholder: "mail.myserver.com",
                                icon: "server.rack",
                                isReadOnly: isGmailAccount(userSettingsManager.userSettings.imapEmail),
                            )

                            // Password/App Password Field
                            settingsField(
                                title: isGmailAccount(userSettingsManager.userSettings.imapEmail) ?
                                    userSettingsManager.userSettings.localized("Gmail App Password") :
                                    userSettingsManager.userSettings.localized("Password"),
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
                                    !userSettingsManager.userSettings.isGmailAppPasswordValid
                                {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text(
                                            userSettingsManager.userSettings
                                                .localized(
                                                    "Gmail App Password must be in format: 'xxxx xxxx xxxx xxxx' (16 lowercase letters with spaces every 4 characters)",
                                                ),
                                        )
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        Spacer()
                                    }
                                }

                                HStack {
                                    Button(
                                        userSettingsManager.userSettings
                                            .localized("How to create Gmail App Password"),
                                    ) {
                                        if
                                            let url =
                                            URL(string: "https://support.google.com/accounts/answer/185833")
                                        {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                    .help(
                                        userSettingsManager.userSettings
                                            .localized("Opens Google's guide to creating app passwords"),
                                    )
                                    Spacer()
                                }
                            }

                            // Test Email Connection Button
                            if userSettingsManager.userSettings.hasEmailConfigured {
                                Button(userSettingsManager.userSettings.localized("Test Email")) {
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
                                .help(
                                    userSettingsManager.userSettings
                                        .localized("Test email and fetch latest email"),
                                )
                            }

                            // Test Results Section
                            if emailService.isTesting {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(
                                        userSettingsManager.userSettings.localized("Testing email connection..."),
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
                    Divider().padding(.horizontal, 4)
                    // Telegram Integration Section
                    settingsSection(
                        title: userSettingsManager.userSettings.localized("Telegram Settings"),
                        icon: "message.circle",
                    ) {
                        VStack(spacing: 16) {
                            Toggle(
                                userSettingsManager.userSettings.localized("Enable Telegram Integration"),
                                isOn: $userSettingsManager.userSettings.telegramEnabled,
                            )
                            .help(
                                userSettingsManager.userSettings
                                    .localized("Enable or disable Telegram notifications"),
                            )

                            if userSettingsManager.userSettings.telegramEnabled {
                                settingsField(
                                    title: userSettingsManager.userSettings.localized("Bot Token"),
                                    value: $userSettingsManager.userSettings.telegramBotToken,
                                    placeholder: "12345:AABBCCDDEEFFGG",
                                    icon: "key",
                                    isSecure: true,
                                )

                                if
                                    !userSettingsManager.userSettings.telegramBotToken.isEmpty,
                                    !userSettingsManager.userSettings.isTelegramBotTokenValid
                                {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text(
                                            userSettingsManager.userSettings
                                                .localized(
                                                    "Bot token format: number:letters (e.g., 12345:ABCdefGHIjkl)",
                                                ),
                                        )
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        Spacer()
                                    }
                                }

                                settingsField(
                                    title: userSettingsManager.userSettings.localized("Chat ID"),
                                    value: $userSettingsManager.userSettings.telegramChatId,
                                    placeholder: "12345678",
                                    icon: "number",
                                )

                                if
                                    !userSettingsManager.userSettings.telegramChatId.isEmpty,
                                    !userSettingsManager.userSettings.isTelegramChatIdValid
                                {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text(
                                            userSettingsManager.userSettings
                                                .localized("Chat ID can only contain numbers"),
                                        )
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        Spacer()
                                    }
                                }

                                if userSettingsManager.userSettings.hasTelegramConfigured {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(
                                            userSettingsManager.userSettings
                                                .localized("Telegram integration configured"),
                                        )
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        Spacer()
                                    }

                                    Button(userSettingsManager.userSettings.localized("Test Telegram")) {
                                        Task {
                                            let result = await telegramService.testIntegration(
                                                botToken: userSettingsManager.userSettings.telegramBotToken,
                                                chatId: userSettingsManager.userSettings.telegramChatId,
                                            )
                                            await MainActor.run {
                                                telegramService.lastTestResult = result
                                            }
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(telegramService.isTesting)
                                    .help(
                                        userSettingsManager.userSettings
                                            .localized("Send a test message to verify Telegram"),
                                    )

                                    if telegramService.isTesting {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text(userSettingsManager.userSettings.localized("Sending test message..."))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                        }
                                    }

                                    if let result = telegramService.lastTestResult {
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
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            // Bottom button bar
            Divider()
            HStack {
                Spacer()
                Button(userSettingsManager.userSettings.localized("Cancel")) {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                Button(userSettingsManager.userSettings.localized("Save")) {
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
        .alert(userSettingsManager.userSettings.localized("Settings Saved"), isPresented: $showingSaveConfirmation) {
            Button(userSettingsManager.userSettings.localized("OK")) {
                dismiss()
            }
        } message: {
            Text(userSettingsManager.userSettings.localized("Your settings have been saved successfully."))
        }
        .alert(userSettingsManager.userSettings.localized("Validation Error"), isPresented: $showingValidationAlert) {
            Button(userSettingsManager.userSettings.localized("OK")) { }
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
                        .onChange(of: value.wrappedValue) { newValue in
                            if let maxLength, newValue.count > maxLength {
                                value.wrappedValue = String(newValue.prefix(maxLength))
                            }
                        }
                } else {
                    TextField(placeholder, text: value)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: value.wrappedValue) { newValue in
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
            validationMessage = userSettingsManager.userSettings.localized("Please enter your full name.")
            showingValidationAlert = true
            return
        }

        if userSettingsManager.userSettings.phoneNumber.isEmpty {
            validationMessage = userSettingsManager.userSettings.localized("Please enter your phone number.")
            showingValidationAlert = true
            return
        }

        if !userSettingsManager.userSettings.isPhoneNumberValid {
            validationMessage = userSettingsManager.userSettings.localized("Phone number must be exactly 10 digits.")
            showingValidationAlert = true
            return
        }

        if userSettingsManager.userSettings.imapEmail.isEmpty {
            validationMessage = userSettingsManager.userSettings.localized("Please enter your email address.")
            showingValidationAlert = true
            return
        }

        if !userSettingsManager.userSettings.isEmailValid {
            validationMessage = userSettingsManager.userSettings.localized("Please enter a valid email address.")
            showingValidationAlert = true
            return
        }

        if userSettingsManager.userSettings.imapServer.isEmpty {
            validationMessage = userSettingsManager.userSettings.localized("Please enter your IMAP server address.")
            showingValidationAlert = true
            return
        }

        if userSettingsManager.userSettings.imapPassword.isEmpty {
            validationMessage = userSettingsManager.userSettings.localized("Please enter your email password.")
            showingValidationAlert = true
            return
        }

        // Validate Telegram settings if enabled
        if userSettingsManager.userSettings.telegramEnabled {
            if userSettingsManager.userSettings.telegramBotToken.isEmpty {
                validationMessage = userSettingsManager.userSettings.localized("Please enter your Telegram bot token.")
                showingValidationAlert = true
                return
            }

            if !userSettingsManager.userSettings.isTelegramBotTokenValid {
                validationMessage = userSettingsManager.userSettings
                    .localized("Invalid bot token format. Expected format: number:letters")
                showingValidationAlert = true
                return
            }

            if userSettingsManager.userSettings.telegramChatId.isEmpty {
                validationMessage = userSettingsManager.userSettings.localized("Please enter your Telegram chat ID.")
                showingValidationAlert = true
                return
            }

            if !userSettingsManager.userSettings.isTelegramChatIdValid {
                validationMessage = userSettingsManager.userSettings
                    .localized("Telegram Chat ID can only contain numbers.")
                showingValidationAlert = true
                return
            }
        }

        // Settings are automatically saved by UserSettingsManager
        // No confirmation dialog needed
    }
}
