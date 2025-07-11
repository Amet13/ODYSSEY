import Foundation
import os.log

/// Service for Telegram integration and notifications
///
/// Handles sending messages to Telegram chat via bot API
/// Provides validation and test functionality for Telegram integration
class TelegramService: ObservableObject {
    static let shared = TelegramService()

    @Published var isTesting = false
    @Published var lastTestResult: TestResult?

    private let logger = Logger(subsystem: "com.odyssey.app", category: "TelegramService")
    private let userSettingsManager = UserSettingsManager.shared

    // Custom URLSession with User-Agent to prevent CFNetwork crashes
    private lazy var customSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "ODYSSEY-Telegram/1.0"]
        return URLSession(configuration: config)
    }()

    enum TestResult {
        case success
        case failure(String)

        var description: String {
            switch self {
            case .success:
                UserSettingsManager.shared.userSettings.localized("Test message sent successfully!")
            case let .failure(error):
                UserSettingsManager.shared.userSettings.localized("Test failed:") + " \(error)"
            }
        }

        var isSuccess: Bool {
            switch self {
            case .success: true
            case .failure: false
            }
        }
    }

    private init() {}

    // MARK: - Public Methods

    /// Tests Telegram integration by sending a test message
    /// - Parameters:
    ///   - botToken: The Telegram bot token
    ///   - chatId: The Telegram chat ID
    /// - Returns: Test result indicating success or failure
    func testIntegration(botToken: String, chatId: String) async -> TestResult {
        let testMessage = """
        🥅 \(userSettingsManager.userSettings.localized("ODYSSEY Test Message"))

        \(userSettingsManager.userSettings.localized("Hello! This is a test message from ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself."))

        ✅ \(userSettingsManager.userSettings.localized("Telegram integration is working correctly!"))
        """
        return await sendMessage(botToken: botToken, chatId: chatId, message: testMessage)
    }

    /// Sends a message to Telegram
    /// - Parameters:
    ///   - botToken: The Telegram bot token
    ///   - chatId: The Telegram chat ID
    ///   - message: The message to send
    /// - Returns: Result indicating success or failure
    func sendMessage(botToken: String, chatId: String, message: String) async -> TestResult {
        let urlString = "https://api.telegram.org/bot\(botToken)/sendMessage"

        guard let url = URL(string: urlString) else {
            return .failure(userSettingsManager.userSettings.localized("Invalid URL"))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "chat_id": chatId,
            "text": message,
            "parse_mode": "HTML"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return .failure(userSettingsManager.userSettings.localized("Failed to serialize request:") + " \(error.localizedDescription)")
        }

        do {
            let (data, response) = try await customSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(userSettingsManager.userSettings.localized("Invalid response"))
            }

            if httpResponse.statusCode == 200 {
                return .success
            } else {
                // Parse error response
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.error("Telegram API error: \(responseString)")

                    // Try to extract error description from response
                    if let jsonData = responseString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let description = json["description"] as? String {
                        return .failure(description)
                    }
                }

                return .failure("HTTP \(httpResponse.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")
            }
        } catch {
            logger.error("Failed to send Telegram message: \(error.localizedDescription)")
            return .failure(userSettingsManager.userSettings.localized("Network error:") + " \(error.localizedDescription)")
        }
    }

    // MARK: - Notification Methods

    /// Sends a success notification to Telegram when a reservation is completed
    /// - Parameter config: The reservation configuration that was successfully executed
    func sendSuccessNotification(for config: ReservationConfig) async {
        guard userSettingsManager.userSettings.hasTelegramConfigured else {
            logger.info("Telegram notifications are disabled")
            return
        }

        logger.info("Sending success notification to Telegram for \(config.name)")

        // Extract facility name from URL
        let facilityName = ReservationConfig.extractFacilityName(from: config.facilityURL)

        // Format time slots information
        let timeSlotsInfo = formatTimeSlotsInfo(for: config)

        let successMessage = """
        <b>🎉 \(userSettingsManager.userSettings.localized("Reservation Success!"))</b>

        ✅ \(userSettingsManager.userSettings.localized("Successfully booked:")) \(config.sportName)

        🏢 \(userSettingsManager.userSettings.localized("Facility:")) \(facilityName)

        👥 \(userSettingsManager.userSettings.localized("People:")) \(config.numberOfPeople)

        📅 \(userSettingsManager.userSettings.localized("Schedule:")) \(timeSlotsInfo)

        🥅 \(userSettingsManager.userSettings.localized("ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself"))
        """

        let result = await sendMessage(
            botToken: userSettingsManager.userSettings.telegramBotToken,
            chatId: userSettingsManager.userSettings.telegramChatId,
            message: successMessage,
            )

        switch result {
        case .success:
            logger.info("Success notification sent to Telegram for \(config.name)")
        case let .failure(error):
            logger.error("Failed to send Telegram success notification: \(error)")
        }
    }

    /// Formats time slots information for display
    /// - Parameter config: The reservation configuration
    /// - Returns: Formatted string of time slots
    private func formatTimeSlotsInfo(for config: ReservationConfig) -> String {
        let sortedDays = config.dayTimeSlots.keys.sorted { day1, day2 in
            ReservationConfig.Weekday.allCases.firstIndex(of: day1)! < ReservationConfig.Weekday.allCases.firstIndex(of: day2)!
        }

        var scheduleInfo: [String] = []
        for day in sortedDays {
            if let timeSlots = config.dayTimeSlots[day], !timeSlots.isEmpty {
                let timeStrings = timeSlots.map { timeSlot in
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    return formatter.string(from: timeSlot.time)
                }.sorted()
                let dayShort = day.shortName
                let timesString = timeStrings.joined(separator: ", ")
                scheduleInfo.append("\(dayShort): \(timesString)")
            }
        }
        return scheduleInfo.joined(separator: " • ")
    }
}
