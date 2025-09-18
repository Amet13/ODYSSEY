import SwiftUI
import os.log

/// Settings view for configuring user information and integration settings
struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var configurationManager = ConfigurationManager.shared
  @StateObject private var userSettingsManager = UserSettingsManager.shared
  @StateObject private var emailService = EmailService.shared
  let godModeEnabled: Bool

  var body: some View {
    ZStack {
      SettingsFormView(
        configurationManager: configurationManager,
        userSettingsManager: userSettingsManager,
        emailService: emailService,
        godModeEnabled: godModeEnabled,
      )
    }
    .odysseyWindowBackground()
    .frame(width: AppConstants.windowMainWidth, height: AppConstants.windowMainHeight)
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
  let godModeEnabled: Bool

  @State private var tempSettings: UserSettings

  private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "SettingsView")

  init(
    configurationManager: ConfigurationManager,
    userSettingsManager: UserSettingsManager,
    emailService: EmailService,
    godModeEnabled: Bool
  ) {
    self.configurationManager = configurationManager
    self.userSettingsManager = userSettingsManager
    self.emailService = emailService
    self.godModeEnabled = godModeEnabled
    self._tempSettings = State(initialValue: userSettingsManager.userSettings)
  }

  // Helper function to detect Gmail accounts
  private func isGmailAccount(_ email: String) -> Bool {
    let domain = email.components(separatedBy: "@").last?.lowercased() ?? ""
    return domain == "gmail.com" || domain.hasSuffix(".gmail.com")
  }

  // Computed property for Gmail help URL
  private var gmailHelpURL: URL {
    URL(string: AppConstants.gmailAppPasswordURL) ?? URL(fileURLWithPath: "/")
  }

  var body: some View {
    VStack(spacing: AppConstants.spacingNone) {
      SettingsHeader()
      HeaderFooterDivider()
      SettingsContent(
        tempSettings: $tempSettings,
        userSettingsManager: userSettingsManager,
        emailService: emailService,
        isGmailAccount: isGmailAccount,
        godModeEnabled: godModeEnabled,
      )
      HeaderFooterDivider()
      SettingsFooter(
        userSettingsManager: userSettingsManager,
        emailService: emailService,
        configurationManager: configurationManager,
        dismiss: dismiss,
        showingValidationAlert: $showingValidationAlert,
        validationMessage: $validationMessage,
        saveSettings: saveSettings,
        cancelSettings: cancelSettings,
        tempSettings: $tempSettings,
      )
    }
    .frame(width: AppConstants.windowMainWidth, height: AppConstants.windowMainHeight)
    .alert("Validation Error", isPresented: $showingValidationAlert) {
      Button("OK") {}
    } message: {
      Text(validationMessage)
    }
    .onDisappear {
      emailService.lastTestResult = nil
    }
  }

  // MARK: - Actions

  private func saveSettings() {
    // Use centralized validation
    let validator = ConfigurationValidator.shared
    let validationResult = validator.validateUserSettings(tempSettings)
    if !validationResult.isValid {
      validationMessage = validationResult.errorMessage
      showingValidationAlert = true
      return
    }

    userSettingsManager.userSettings = tempSettings

    // Save settings to UserDefaults and Keychain
    userSettingsManager.saveSettings()

    // Store credentials in Keychain
    userSettingsManager.storeCredentialsInKeychain()

    // Reschedule autorun with new settings
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: AppConstants.rescheduleAutorunNotification, object: nil)
    }

    // Close the window immediately
    dismiss()
  }

  private func cancelSettings() {
    tempSettings = userSettingsManager.userSettings
    dismiss()
  }
}

private struct SettingsHeader: View {
  var body: some View {
    HStack(spacing: AppConstants.spacingLarge) {
      Image(systemName: AppConstants.SFSymbols.app)
        .symbolRenderingMode(.hierarchical)
        .font(.title3)
        .foregroundColor(.accentColor)
      Text("Settings")
        .font(.system(size: AppConstants.fontTitle3))
        .fontWeight(.semibold)
      Spacer()
    }
    .padding(.horizontal, AppConstants.screenPadding)
    .padding(.vertical, AppConstants.screenPadding)
  }
}

private struct SettingsContent: View {
  @Binding var tempSettings: UserSettings
  @ObservedObject var userSettingsManager: UserSettingsManager
  @ObservedObject var emailService: EmailService
  let isGmailAccount: (String) -> Bool
  let godModeEnabled: Bool

  var body: some View {
    ScrollView {
      VStack(spacing: AppConstants.contentSpacing) {
        ContactInformationSection(
          tempSettings: $tempSettings,
          userSettingsManager: userSettingsManager,
          emailService: emailService,
        )
        SectionDivider()
        EmailSettingsSection(
          tempSettings: $tempSettings,
          userSettingsManager: userSettingsManager,
          emailService: emailService,
          isGmailAccount: isGmailAccount,
        )
        // Advanced Settings Section
        SectionDivider()
        AdvancedSettingsSection(tempSettings: $tempSettings)
      }
      .contentShape(Rectangle())
      .onTapGesture {
        if emailService.lastTestResult != nil {
          emailService.lastTestResult = nil
        }
      }
      .padding(.horizontal, AppConstants.screenPadding)
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
      VStack(spacing: AppConstants.spacingLarge) {
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

        if !tempSettings.phoneNumber.isEmpty,
          !tempSettings.isPhoneNumberValid
        {
          HStack {
            Image(systemName: AppConstants.SFSymbols.warningFill)
              .symbolRenderingMode(.hierarchical)
              .foregroundColor(.odysseyWarning)
            Text("Phone number must be exactly 10 digits")
              .font(.footnote)
              .foregroundColor(.odysseyWarning)
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
      VStack(spacing: AppConstants.spacingLarge) {
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
      VStack(alignment: .leading, spacing: AppConstants.spacingLarge) {

        // Notification Settings
        VStack(alignment: .leading, spacing: AppConstants.spacingMedium) {
          HStack {
            Toggle(
              "",
              isOn: Binding(
                get: { tempSettings.showNotifications },
                set: { newValue in
                  tempSettings.showNotifications = newValue
                },
              ))
            Text("Enable notifications")
            Spacer()
          }
          .help(
            "If enabled, ODYSSEY will show notifications for reservation success, failure, and automation completion."
          )
        }

        // Browser Window Controls
        VStack(alignment: .leading, spacing: AppConstants.spacingMedium) {
          HStack {
            Toggle(
              "",
              isOn: Binding(
                get: { tempSettings.showBrowserWindow },
                set: { newValue in
                  tempSettings.showBrowserWindow = newValue
                },
              ))
            Text("Show browser window")
            Spacer()
          }
          .help(
            "If enabled, the browser window will be visible during automation, "
              + "which can help bypass captcha detection. If disabled, automation runs invisibly in the background.",
          )

          if tempSettings.showBrowserWindow {
            HStack {
              Toggle(
                "",
                isOn: Binding(
                  get: { tempSettings.autoCloseDebugWindowOnFailure },
                  set: { newValue in
                    tempSettings.autoCloseDebugWindowOnFailure = newValue
                  },
                ))
              Text("Automatically close browser window on failure")
              Spacer()
            }
            .help(
              "If enabled, the browser window will close automatically after a reservation failure. "
                + "If disabled, the window will remain open so you can inspect the error.",
            )
          }
        }

        // Custom Autorun Time Section
        VStack(alignment: .leading, spacing: AppConstants.spacingMedium) {
          HStack {
            Toggle(
              "",
              isOn: Binding(
                get: { tempSettings.useCustomAutorunTime },
                set: { newValue in
                  tempSettings.useCustomAutorunTime = newValue
                },
              ))
            Text("Use custom autorun time")
            Spacer()
          }
          .help(
            "If enabled, you can set a custom time for autorun. If disabled, the default time of 6:00 PM will be used.",
          )

          if tempSettings.useCustomAutorunTime {
            HStack {
              DatePicker(
                "Autorun Time",
                selection: Binding(
                  get: { tempSettings.customAutorunTime },
                  set: { newTime in
                    // Always set seconds to 0 for precise timing
                    let calendar = Calendar.current
                    let hour = calendar.component(.hour, from: newTime)
                    let minute = calendar.component(.minute, from: newTime)
                    // Use a consistent base date (January 1, 2000) to avoid date-related issues
                    let baseDate =
                      calendar.date(
                        from: DateComponents(
                          year: 2_000,
                          month: 1,
                          day: 1,
                        )) ?? Date()
                    let normalizedTime =
                      calendar.date(
                        bySettingHour: hour,
                        minute: minute,
                        second: 0,
                        of: baseDate,
                      ) ?? newTime
                    tempSettings.customAutorunTime = normalizedTime
                  },
                ),
                displayedComponents: .hourAndMinute,
              )
              .labelsHidden()
              .controlSize(.small)
              .frame(width: AppConstants.buttonHeightLarge * 3)

              Text("(Default: 6:00 PM)")
                .font(.system(size: AppConstants.fontCaption))
                .foregroundColor(.secondary)

              Spacer()
            }
            .help(
              "Set a custom time for autorun scheduling. This time will be used for all automatic reservation runs.",
            )
          }
        }

        // Custom Prior Days (God Mode)
        VStack(alignment: .leading, spacing: AppConstants.spacingMedium) {
          HStack {
            Toggle(
              "",
              isOn: Binding(
                get: { tempSettings.useCustomPriorDays },
                set: { newValue in
                  tempSettings.useCustomPriorDays = newValue
                },
              ))
            Text("Use custom prior days")
            Spacer()
          }
          .help(
            "If enabled, choose how many days before the reservation to run (default: 2).",
          )

          if tempSettings.useCustomPriorDays {
            HStack(spacing: AppConstants.spacingMedium) {
              Stepper(
                value: Binding(
                  get: { tempSettings.customPriorDays },
                  set: { newValue in tempSettings.customPriorDays = max(0, min(7, newValue)) }
                ), in: 0...7
              ) {
                Text("Prior days: \(tempSettings.customPriorDays)")
                  .font(.system(size: AppConstants.fontBody))
              }
              .controlSize(.small)
              .frame(maxWidth: AppConstants.maxContentWidth * 0.366, alignment: .leading)
              Spacer()
            }
            .help("Number of days before reservation date to run. Useful for debugging/testing.")
          }
        }

      }
    }
  }
}

private struct SettingsFooter: View {
  @ObservedObject var userSettingsManager: UserSettingsManager
  @ObservedObject var emailService: EmailService
  @ObservedObject var configurationManager: ConfigurationManager
  let dismiss: DismissAction
  @Binding var showingValidationAlert: Bool
  @Binding var validationMessage: String
  let saveSettings: () -> Void
  let cancelSettings: () -> Void
  @Binding var tempSettings: UserSettings

  var body: some View {
    VStack(spacing: AppConstants.spacingMedium) {
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
        .disabled(!tempSettings.isValid)
      }
      .padding(.horizontal, AppConstants.screenPadding)
      .padding(.vertical, AppConstants.contentPadding)
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
    VStack(alignment: .leading, spacing: AppConstants.spacingTiny) {
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

      if !tempSettings.imapEmail.isEmpty,
        !tempSettings.isEmailValid
      {
        HStack {
          Image(systemName: AppConstants.SFSymbols.warningFill)
            .foregroundColor(.odysseyWarning)
          Text("Please enter a valid email address")
            .font(.system(size: AppConstants.fontCaption))
            .foregroundColor(.odysseyWarning)
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

  // Computed property for Gmail help URL
  private var gmailHelpURL: URL {
    URL(string: "https://support.google.com/accounts/answer/185833") ?? URL(fileURLWithPath: "/")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: AppConstants.spacingTiny) {
      settingsField(
        title: isGmailAccount(tempSettings.imapEmail) ? "Gmail App Password" : "Password",
        value: $tempSettings.imapPassword,
        placeholder: isGmailAccount(tempSettings.imapEmail)
          ? "16-character app password" : "my-password",
        icon: "lock",
        isSecure: true,
      )
      .onChange(of: tempSettings.imapPassword) { _, _ in
        if emailService.lastTestResult != nil {
          emailService.lastTestResult = nil
        }
      }
      .accessibilityLabel(
        isGmailAccount(tempSettings.imapEmail) ? "Gmail App Password" : "Password",
      )

      // Gmail App Password validation
      if isGmailAccount(tempSettings.imapEmail), !tempSettings.imapPassword.isEmpty {
        if !tempSettings.isGmailAppPasswordValid {
          HStack {
            Spacer()
            Link(
              "How to create Gmail app password?",
              destination: gmailHelpURL,
            )
            .font(.system(size: AppConstants.fontCaption))
            .foregroundColor(.odysseyPrimary)
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
    VStack(spacing: AppConstants.spacingMedium) {
      if tempSettings.hasEmailConfigured {
        Button(action: {
          let originalSettings = userSettingsManager.userSettings
          userSettingsManager.userSettings = tempSettings

          UserSettingsManager.shared.storeCredentialsInKeychain()
          Task {
            let result = await emailService.testIMAPConnection(
              email: tempSettings.imapEmail,
              password: tempSettings.imapPassword,
              server: tempSettings.imapServer,
              provider: isGmailAccount(tempSettings.imapEmail) ? .gmail : .imap,
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
          HStack(spacing: AppConstants.spacingSmall) {
            Image(systemName: AppConstants.SFSymbols.envelopeBadge)
              .font(.system(size: AppConstants.fontBody))
            Text("Test Email")
              .font(.system(size: AppConstants.fontBody))
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
            .scaleEffect(AppConstants.scaleEffectSmall)
          Text("Testing email connection...")
            .font(.system(size: AppConstants.fontBody))
            .foregroundColor(.secondary)
          Spacer()
        }
      }

      if let result = emailService.lastTestResult {
        HStack {
          Image(
            systemName: result.isSuccess
              ? AppConstants.SFSymbols.successCircleFill : AppConstants.SFSymbols.xmarkCircleFill
          )
          .foregroundColor(result.isSuccess ? .odysseySuccess : .odysseyError)
          Text(result.description)
            .font(.footnote)
            .foregroundColor(result.isSuccess ? .odysseySuccess : .odysseyError)
          Spacer()
        }
        .padding(.top, AppConstants.paddingTiny)
        .onTapGesture {
          emailService.lastTestResult = nil
        }
      }
    }
  }
}

// MARK: - Helper Views

@MainActor
private func settingsSection(title: String, icon: String, @ViewBuilder content: () -> some View)
  -> some View
{
  VStack(alignment: .leading, spacing: AppConstants.contentSpacing) {
    HStack {
      Image(systemName: icon)
        .symbolRenderingMode(.hierarchical)
        .foregroundColor(.accentColor)
      Text(title)
        .font(.system(size: AppConstants.fontSubheadline))
        .fontWeight(.semibold)
      Spacer()
    }

    content()
  }
  // Vertical padding within section content; horizontal handled by outer container
  .padding(.vertical, AppConstants.sectionDividerSpacing)
  .cornerRadius(AppConstants.inputCornerRadius)
  // No background to avoid double-layer gray; window already provides material
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
  VStack(alignment: .leading, spacing: AppConstants.spacingTiny) {
    HStack {
      Image(systemName: icon)
        .symbolRenderingMode(.hierarchical)
        .foregroundColor(.secondary)
        .frame(width: AppConstants.iconSmall)
      Text(title)
        .font(.system(size: AppConstants.fontSubheadline))
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
