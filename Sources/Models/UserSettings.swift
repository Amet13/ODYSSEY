import Foundation

/// User settings and configuration data for ODYSSEY
///
/// Stores personal information needed for reservations and notifications
/// including contact details, email settings, and optional Telegram integration
struct UserSettings: Codable {
    // Contact Information
    var phoneNumber: String = ""
    var name: String = ""

    // Email/IMAP Settings
    var imapEmail: String = ""
    var imapPassword: String = ""
    var imapServer: String = ""

    // Telegram Integration (Optional)
    var telegramEnabled: Bool = false
    var telegramBotToken: String = ""
    var telegramChatId: String = ""

    // Language
    enum Language: String, CaseIterable, Identifiable, Codable {
        case english = "English"
        case french = "French"
        var id: String { rawValue }
    }

    var language: Language = {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("fr") { return .french }
        return .english
    }()

    // Validation
    var isValid: Bool {
        !phoneNumber.isEmpty && !name.isEmpty && !imapEmail.isEmpty && !imapPassword.isEmpty && !imapServer.isEmpty &&
            isPhoneNumberValid && isEmailValid
    }

    var hasTelegramConfigured: Bool {
        telegramEnabled && !telegramBotToken.isEmpty && !telegramChatId.isEmpty
    }

    var hasEmailConfigured: Bool {
        !imapEmail.isEmpty && !imapPassword.isEmpty && !imapServer.isEmpty && isEmailValid
    }

    // Phone number validation (10 digits)
    var isPhoneNumberValid: Bool {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleaned.count == 10
    }

    // Email validation
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: imapEmail)
    }

    // Telegram bot token validation (format: number:letters)
    var isTelegramBotTokenValid: Bool {
        let tokenRegex = "^[0-9]+:[A-Za-z0-9_-]+$"
        let tokenPredicate = NSPredicate(format: "SELF MATCHES %@", tokenRegex)
        return tokenPredicate.evaluate(with: telegramBotToken)
    }

    // Telegram chat ID validation (numbers only)
    var isTelegramChatIdValid: Bool {
        let cleaned = telegramChatId.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleaned == telegramChatId && !cleaned.isEmpty
    }

    // Helper methods
    func getFormattedPhoneNumber() -> String {
        // Basic phone number formatting
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if cleaned.count == 10 {
            return "(\(cleaned.prefix(3))) \(cleaned.dropFirst(3).prefix(3))-\(cleaned.dropFirst(6))"
        }
        return phoneNumber
    }

    func getEmailDomain() -> String {
        let components = imapEmail.components(separatedBy: "@")
        return components.count > 1 ? components[1] : ""
    }

    func localized(_ key: String) -> String {
        let en: [String: String] = [
            "Settings": "Settings",
            "Save": "Save",
            "Cancel": "Cancel",
            "Contact Information": "Contact Information",
            "Full Name": "Full Name",
            "Phone Number": "Phone Number",
            "Phone number must be exactly 10 digits": "Phone number must be exactly 10 digits",
            "Email Settings": "Email Settings",
            "Email Address": "Email Address",
            "Please enter a valid email address": "Please enter a valid email address",
            "IMAP Server": "IMAP Server",
            "Password": "Password",
            "Email settings configured": "Email settings configured",
            "Test IMAP Connection": "Test IMAP Connection",
            "Testing email connection...": "Testing email connection...",
            "Telegram Integration (Optional)": "Telegram Integration (Optional)",
            "Enable Telegram Integration": "Enable Telegram Integration",
            "Bot Token": "Bot Token",
            "Chat ID": "Chat ID",
            "Telegram integration configured": "Telegram integration configured",
            "Test Telegram Connection": "Test Telegram Connection",
            "Sending test message...": "Sending test message...",
            "Language": "Language",
            "App Language": "App Language",
            "Choose the language for the app interface": "Choose the language for the app interface",
            "ODYSSEY – Ottawa Drop-in Your Sports & Schedule Easily Yourself": "ODYSSEY – Ottawa Drop-in Your Sports & Schedule Easily Yourself",
            "Add new configuration": "Add new configuration",
            "No Reservations Configured": "No Reservations Configured",
            "Add your first reservation configuration to get started with automated booking.": "Add your first reservation configuration to get started with automated booking.",
            "Add Configuration": "Add Configuration",
            "Settings": "Settings",
            "Configure user settings and integrations": "Configure user settings and integrations",
            "GitHub": "GitHub",
            "View ODYSSEY on GitHub": "View ODYSSEY on GitHub",
            "Quit": "Quit",
            "Quit ODYSSEY": "Quit ODYSSEY",
            "Run automated reservation booking for this configuration": "Run automated reservation booking for this configuration",
            "Enable or disable configuration": "Enable or disable configuration",
            "Edit configuration": "Edit configuration",
            "Delete configuration": "Delete configuration",
            "Delete Configuration": "Delete Configuration",
            "Cancel": "Cancel",
            "Delete": "Delete",
            "Are you sure you want to delete '": "Are you sure you want to delete '",
            "'? This action cannot be undone.": "'? This action cannot be undone.",
            "now": "now",
            "day": "day",
            "days": "days",
            "hour": "hour",
            "hours": "hours",
            "minute": "minute",
            "minutes": "minutes",
            "Next autorun:": "Next autorun:",
            "Please enter your full name.": "Please enter your full name.",
            "Please enter your phone number.": "Please enter your phone number.",
            "Please enter your email address.": "Please enter your email address.",
            "Please enter your IMAP server address.": "Please enter your IMAP server address.",
            "Please enter your email password.": "Please enter your email password.",
            "Please enter your Telegram bot token.": "Please enter your Telegram bot token.",
            "Invalid bot token format. Expected format: number:letters": "Invalid bot token format. Expected format: number:letters",
            "Please enter your Telegram chat ID.": "Please enter your Telegram chat ID.",
            "Telegram Chat ID can only contain numbers.": "Telegram Chat ID can only contain numbers.",
            "Settings Saved": "Settings Saved",
            "OK": "OK",
            "Your settings have been saved successfully.": "Your settings have been saved successfully.",
            "Validation Error": "Validation Error",
        ]
        let fr: [String: String] = [
            "Settings": "Paramètres",
            "Save": "Enregistrer",
            "Cancel": "Annuler",
            "Contact Information": "Informations de contact",
            "Full Name": "Nom complet",
            "Phone Number": "Numéro de téléphone",
            "Phone number must be exactly 10 digits": "Le numéro de téléphone doit comporter exactement 10 chiffres",
            "Email Settings": "Paramètres e-mail",
            "Email Address": "Adresse e-mail",
            "Please enter a valid email address": "Veuillez entrer une adresse e-mail valide",
            "IMAP Server": "Serveur IMAP",
            "Password": "Mot de passe",
            "Email settings configured": "Paramètres e-mail configurés",
            "Test IMAP Connection": "Tester la connexion IMAP",
            "Testing email connection...": "Test de connexion e-mail...",
            "Telegram Integration (Optional)": "Intégration Telegram (optionnel)",
            "Enable Telegram Integration": "Activer l'intégration Telegram",
            "Bot Token": "Jeton du bot",
            "Chat ID": "ID de chat",
            "Telegram integration configured": "Intégration Telegram configurée",
            "Test Telegram Connection": "Tester la connexion Telegram",
            "Sending test message...": "Envoi du message de test...",
            "Language": "Langue",
            "App Language": "Langue de l'application",
            "Choose the language for the app interface": "Choisissez la langue de l'interface de l'application",
            "ODYSSEY – Ottawa Drop-in Your Sports & Schedule Easily Yourself": "ODYSSEY – Ottawa : Réservez vos sports et horaires facilement vous-même",
            "Add new configuration": "Ajouter une nouvelle configuration",
            "No Reservations Configured": "Aucune configuration de réservation",
            "Add your first reservation configuration to get started with automated booking.": "Ajoutez votre première configuration de réservation pour commencer la réservation automatique.",
            "Add Configuration": "Ajouter une configuration",
            "Settings": "Paramètres",
            "Configure user settings and integrations": "Configurer les paramètres utilisateur et les intégrations",
            "GitHub": "GitHub",
            "View ODYSSEY on GitHub": "Voir ODYSSEY sur GitHub",
            "Quit": "Quitter",
            "Quit ODYSSEY": "Quitter ODYSSEY",
            "Run automated reservation booking for this configuration": "Exécuter la réservation automatique pour cette configuration",
            "Enable or disable configuration": "Activer ou désactiver la configuration",
            "Edit configuration": "Modifier la configuration",
            "Delete configuration": "Supprimer la configuration",
            "Delete Configuration": "Supprimer la configuration",
            "Cancel": "Annuler",
            "Delete": "Supprimer",
            "Are you sure you want to delete '": "Êtes-vous sûr de vouloir supprimer '",
            "'? This action cannot be undone.": "'? Cette action est irréversible.",
            "now": "maintenant",
            "day": "jour",
            "days": "jours",
            "hour": "heure",
            "hours": "heures",
            "minute": "minute",
            "minutes": "minutes",
            "Next autorun:": "Prochaine exécution automatique :",
            "Please enter your full name.": "Veuillez entrer votre nom complet.",
            "Please enter your phone number.": "Veuillez entrer votre numéro de téléphone.",
            "Please enter your email address.": "Veuillez entrer votre adresse e-mail.",
            "Please enter your IMAP server address.": "Veuillez entrer l'adresse de votre serveur IMAP.",
            "Please enter your email password.": "Veuillez entrer votre mot de passe e-mail.",
            "Please enter your Telegram bot token.": "Veuillez entrer le jeton de votre bot Telegram.",
            "Invalid bot token format. Expected format: number:letters": "Format du jeton invalide. Format attendu : nombre:lettres",
            "Please enter your Telegram chat ID.": "Veuillez entrer votre identifiant de chat Telegram.",
            "Telegram Chat ID can only contain numbers.": "L'ID de chat Telegram ne peut contenir que des chiffres.",
            "Settings Saved": "Paramètres enregistrés",
            "OK": "OK",
            "Your settings have been saved successfully.": "Vos paramètres ont été enregistrés avec succès.",
            "Validation Error": "Erreur de validation",
        ]
        switch language {
        case .english: return en[key] ?? key
        case .french: return fr[key] ?? key
        }
    }
}
