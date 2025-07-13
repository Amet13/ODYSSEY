import Foundation

/// User settings and configuration data for ODYSSEY
///
/// Stores personal information needed for reservations and notifications
/// including contact details, email settings, and optional Telegram integration
struct UserSettings: Codable, Equatable {
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
        case french = "Français"
        var id: String { rawValue }
    }

    var language: Language = {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("fr") { return .french }
        return .english
    }()

    var locale: Locale {
        switch language {
        case .english: return Locale(identifier: "en")
        case .french: return Locale(identifier: "fr")
        }
    }

    // MARK: - Equatable

    static func == (lhs: UserSettings, rhs: UserSettings) -> Bool {
        return lhs.phoneNumber == rhs.phoneNumber &&
            lhs.name == rhs.name &&
            lhs.imapEmail == rhs.imapEmail &&
            lhs.imapPassword == rhs.imapPassword &&
            lhs.imapServer == rhs.imapServer &&
            lhs.telegramEnabled == rhs.telegramEnabled &&
            lhs.telegramBotToken == rhs.telegramBotToken &&
            lhs.telegramChatId == rhs.telegramChatId &&
            lhs.language == rhs.language
    }

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
        switch language {
        case .english:
            englishLocalizations[key] ?? key
        case .french:
            frenchLocalizations[key] ?? key
        }
    }

    private var englishLocalizations: [String: String] {
        [
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
            "ODYSSEY – Ottawa Drop-in Your Sports & Schedule Easily Yourself":
                "ODYSSEY – Ottawa Drop-in Your Sports & Schedule Easily Yourself",
            "Add new configuration": "Add new configuration",
            "No Reservations Configured": "No Reservations Configured",
            "Add your first reservation configuration to get started with automated booking.":
                "Add your first reservation configuration to get started with automated booking.",
            "Add Configuration": "Add Configuration",
            "Configure user settings and integrations": "Configure user settings and integrations",
            "GitHub": "GitHub",
            "View ODYSSEY on GitHub": "View ODYSSEY on GitHub",
            "Quit": "Quit",
            "Quit ODYSSEY": "Quit ODYSSEY",
            "Run automated reservation booking for this configuration":
                "Run automated reservation booking for this configuration",
            "Enable or disable configuration": "Enable or disable configuration",
            "Edit configuration": "Edit configuration",
            "Delete configuration": "Delete configuration",
            "Delete Configuration": "Delete Configuration",
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
            "Invalid bot token format. Expected format: number:letters":
                "Invalid bot token format. Expected format: number:letters",
            "Please enter your Telegram chat ID.": "Please enter your Telegram chat ID.",
            "Telegram Chat ID can only contain numbers.": "Telegram Chat ID can only contain numbers.",
            "Settings Saved": "Settings Saved",
            "OK": "OK",
            "Your settings have been saved successfully.": "Your settings have been saved successfully.",
            "Validation Error": "Validation Error",
            "Test message sent successfully!": "Test message sent successfully!",
            "Test failed:": "Test failed:",
            "ODYSSEY Test Message": "ODYSSEY Test Message",
            "Hello! This is a test message from ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself.":
                "Hello! This is a test message from ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself.",
            "Telegram integration is working correctly!": "Telegram integration is working correctly!",
            "Invalid URL": "Invalid URL",
            "Failed to serialize request:": "Failed to serialize request:",
            "Invalid response": "Invalid response",
            "Network error:": "Network error:",
            "Connection failed:": "Connection failed:",
            "Authentication failed:": "Authentication failed:",
            "Command failed:": "Command failed:",
            "IMAP test failed:": "IMAP test failed:",
            "Email address is empty": "Email address is empty",
            "Password is empty": "Password is empty",
            "IMAP server is empty": "IMAP server is empty",
            "Invalid email format": "Invalid email format",
            "Connection cancelled": "Connection cancelled",
            "IMAP connection successful!": "IMAP connection successful!",
            "Failed to fetch email:": "Failed to fetch email:",
            "Failed to search mailbox:": "Failed to search mailbox:",
            "Failed to select INBOX:": "Failed to select INBOX:",
            "IMAP handshake failed:": "IMAP handshake failed:",
            "Invalid command encoding": "Invalid command encoding",
            "Send error:": "Send error:",
            "Receive error:": "Receive error:",
            "IMAP error:": "IMAP error:",
            "Connection timeout:": "Connection timeout:",
            "Unsupported server:": "Unsupported server:",
            "All IMAP connection attempts failed": "All IMAP connection attempts failed",
            "Unknown": "Unknown",
            "No Subject": "No Subject",
            "Unknown Date": "Unknown Date",
            "From:": "From:",
            "Subject:": "Subject:",
            "Date:": "Date:",
            "Run now": "Run now",
            "Reservation Success!": "Reservation Success!",
            "Successfully booked:": "Successfully booked:",
            "Facility:": "Facility:",
            "People:": "People:",
            "Schedule:": "Schedule:",
            "Booked at:": "Booked at:",
            "ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself":
                "ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself",
            "Last success": "Last success",
            "Last failed:": "Last failed:",
            "Running...": "Running...",
            "Never run": "Never run",
            "Last run:": "Last run:",
            "success": "success",
            "fail": "fail",
            "never": "never",
            "(manual)": "(manual)",
            "(auto)": "(auto)",
            "WebDriver not initialized": "WebDriver not initialized",
            "Failed to navigate to reservation page": "Failed to navigate to reservation page",
            "Sport button not found on page": "Sport button not found on page",
            "Page failed to load completely within timeout": "Page failed to load completely within timeout",
            "Failed to start WebDriver session": "Failed to start WebDriver session",
            "Failed to navigate to facility": "Failed to navigate to facility",
            "Automation error:": "Automation error:",
            "Reservation completed successfully": "Reservation completed successfully",
            "Add Reservation Configuration": "Add Reservation Configuration",
            "Edit Reservation Configuration": "Edit Reservation Configuration",
            "Sport Name": "Sport Name",
            "No sports available": "No sports available",
            "Select Sport": "Select Sport",
            "Fetching available sports...": "Fetching available sports...",
            "sports found": "sports found",
            "Number of People": "Number of People",
            "Configuration Name": "Configuration Name",
            "Time Slots": "Time Slots",
            "Add Day": "Add Day",
            "Maximum 2 time slots per day (no duplicates)": "Maximum 2 time slots per day (no duplicates)",
            "No days selected. Click 'Add Day' to start scheduling.": "No days selected. Click 'Add Day' to start scheduling.",
            "Preview": "Preview",
            "Name: ": "Name: ",
            "Sport: ": "Sport: ",
            "People: ": "People: ",
            "Not set": "Not set",
            "Please fill in all required fields with valid data.": "Please fill in all required fields with valid data.",
            "Facility URL": "Facility URL",
            "Please enter a valid Ottawa Recreation URL.": "Please enter a valid Ottawa Recreation URL.",
            "1 Person": "1 Person",
            "2 People": "2 People",
            "Enter facility URL": "Enter facility URL",
            "Add Time Slot (max 2)": "Add Time Slot (max 2)",
            "Mon": "Mon",
            "Tue": "Tue",
            "Wed": "Wed",
            "Thu": "Thu",
            "Fri": "Fri",
            "Sat": "Sat",
            "Sun": "Sun",
            "Monday": "Monday",
            "Tuesday": "Tuesday",
            "Wednesday": "Wednesday",
            "Thursday": "Thursday",
            "Friday": "Friday",
            "Saturday": "Saturday",
            "Sunday": "Sunday",
            "View Ottawa Facilities": "View Ottawa Facilities",
        ]
    }

    private var frenchLocalizations: [String: String] {
        [
            "Settings": "Paramètres",
            "Save": "Sauvegarder",
            "Cancel": "Annuler",
            "Contact Information": "Informations de contact",
            "Full Name": "Nom complet",
            "Phone Number": "Numéro de téléphone",
            "Phone number must be exactly 10 digits": "Le numéro de téléphone doit avoir exactement 10 chiffres",
            "Email Settings": "Paramètres de courriel",
            "Email Address": "Adresse de courriel",
            "Please enter a valid email address": "Veuillez entrer une adresse de courriel valide",
            "IMAP Server": "Serveur IMAP",
            "Password": "Mot de passe",
            "Email settings configured": "Paramètres de courriel configurés",
            "Test IMAP Connection": "Tester la connexion IMAP",
            "Testing email connection...": "Test de connexion courriel...",
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
            "Please enter your email address.": "Veuillez entrer votre adresse de courriel.",
            "Please enter your IMAP server address.": "Veuillez entrer l'adresse de votre serveur IMAP.",
            "Please enter your email password.": "Veuillez entrer votre mot de passe de courriel.",
            "Please enter your Telegram bot token.": "Veuillez entrer le jeton de votre bot Telegram.",
            "Invalid bot token format. Expected format: number:letters": "Format du jeton invalide. Format attendu : nombre:lettres",
            "Please enter your Telegram chat ID.": "Veuillez entrer votre identifiant de chat Telegram.",
            "Telegram Chat ID can only contain numbers.": "L'ID de chat Telegram ne peut contenir que des chiffres.",
            "Settings Saved": "Paramètres sauvegardés",
            "OK": "OK",
            "Your settings have been saved successfully.": "Vos paramètres ont été sauvegardés avec succès.",
            "Validation Error": "Erreur de validation",
            "Test message sent successfully!": "Message de test envoyé avec succès!",
            "Test failed:": "Test échoué :",
            "ODYSSEY Test Message": "Message de test ODYSSEY",
            "Hello! This is a test message from ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself.": "Bonjour! Ceci est un message de test d'ODYSSEY - Ottawa : Réservez vos sports et horaires facilement vous-même.",
            "Telegram integration is working correctly!": "L'intégration Telegram fonctionne correctement!",
            "Invalid URL": "URL invalide",
            "Failed to serialize request:": "Échec de sérialisation de la requête :",
            "Invalid response": "Réponse invalide",
            "Network error:": "Erreur réseau :",
            "Connection failed:": "Échec de connexion :",
            "Authentication failed:": "Échec d'authentification :",
            "Command failed:": "Commande échouée :",
            "IMAP test failed:": "Test IMAP échoué :",
            "Email address is empty": "L'adresse de courriel est vide",
            "Password is empty": "Le mot de passe est vide",
            "IMAP server is empty": "Le serveur IMAP est vide",
            "Invalid email format": "Format de courriel invalide",
            "Connection cancelled": "Connexion annulée",
            "IMAP connection successful!": "Connexion IMAP réussie!",
            "Failed to fetch email:": "Échec de récupération du courriel :",
            "Failed to search mailbox:": "Échec de recherche de la boîte de réception :",
            "Failed to select INBOX:": "Échec de sélection de la boîte de réception :",
            "IMAP handshake failed:": "Échec de poignée de main IMAP :",
            "Invalid command encoding": "Encodage de commande invalide",
            "Send error:": "Erreur d'envoi :",
            "Receive error:": "Erreur de réception :",
            "IMAP error:": "Erreur IMAP :",
            "Connection timeout:": "Délai d'attente de connexion :",
            "Unsupported server:": "Serveur non pris en charge :",
            "All IMAP connection attempts failed": "Toutes les tentatives de connexion IMAP ont échoué",
            "Unknown": "Inconnu",
            "No Subject": "Aucun sujet",
            "Unknown Date": "Date inconnue",
            "From:": "De :",
            "Subject:": "Sujet :",
            "Date:": "Date :",
            "Run now": "Exécuter maintenant",
            "Reservation Success!": "Réservation réussie!",
            "Successfully booked:": "Réservation réussie :",
            "Facility:": "Installation :",
            "People:": "Personnes :",
            "Schedule:": "Horaire :",
            "Booked at:": "Réservé à :",
            "ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself": "ODYSSEY - Ottawa : Réservez vos sports et horaires facilement vous-même",
            "Last success": "Dernier succès",
            "Last failed:": "Dernier échec :",
            "Running...": "En cours...",
            "Never run": "Jamais exécuté",
            "Last run:": "Dernière exécution :",
            "success": "succès",
            "fail": "échec",
            "never": "jamais",
            "(manual)": "(manuel)",
            "(auto)": "(auto)",
            "WebDriver not initialized": "WebDriver non initialisé",
            "Failed to navigate to reservation page": "Échec de navigation vers la page de réservation",
            "Sport button not found on page": "Bouton de sport non trouvé sur la page",
            "Page failed to load completely within timeout": "La page n'a pas pu se charger complètement dans le délai d'attente",
            "Failed to start WebDriver session": "Échec du démarrage de la session WebDriver",
            "Failed to navigate to facility": "Échec de navigation vers l'installation",
            "Automation error:": "Erreur d'automatisation :",
            "Reservation completed successfully": "Réservation terminée avec succès",
            "Add Reservation Configuration": "Ajouter une configuration de réservation",
            "Edit Reservation Configuration": "Modifier la configuration de réservation",
            "Sport Name": "Nom du sport",
            "No sports available": "Aucun sport disponible",
            "Select Sport": "Sélectionner un sport",
            "Fetching available sports...": "Récupération des sports disponibles...",
            "sports found": "sports trouvés",
            "Number of People": "Nombre de personnes",
            "Configuration Name": "Nom de la configuration",
            "Time Slots": "Créneaux horaires",
            "Add Day": "Ajouter un jour",
            "Maximum 2 time slots per day (no duplicates)": "Maximum 2 créneaux par jour (pas de doublons)",
            "No days selected. Click 'Add Day' to start scheduling.": "Aucun jour sélectionné. Cliquez sur 'Ajouter un jour' pour commencer la planification.",
            "Preview": "Aperçu",
            "Name: ": "Nom : ",
            "Sport: ": "Sport : ",
            "People: ": "Personnes : ",
            "Not set": "Non défini",
            "Please fill in all required fields with valid data.": "Veuillez remplir tous les champs requis avec des données valides.",
            "Facility URL": "URL de l'installation",
            "Please enter a valid Ottawa Recreation URL.": "Veuillez entrer une URL valide d'Ottawa Recreation.",
            "1 Person": "1 Personne",
            "2 People": "2 Personnes",
            "Enter facility URL": "Entrez l'URL de l'installation",
            "Add Time Slot (max 2)": "Ajouter un créneau (max 2)",
            "Mon": "Lun",
            "Tue": "Mar",
            "Wed": "Mer",
            "Thu": "Jeu",
            "Fri": "Ven",
            "Sat": "Sam",
            "Sun": "Dim",
            "Monday": "Lundi",
            "Tuesday": "Mardi",
            "Wednesday": "Mercredi",
            "Thursday": "Jeudi",
            "Friday": "Vendredi",
            "Saturday": "Samedi",
            "Sunday": "Dimanche",
            "View Ottawa Facilities": "Voir les installations d'Ottawa",
        ]
    }
}
