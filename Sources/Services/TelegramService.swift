import Foundation
import os.log

/// Telegram-specific errors
enum TelegramError: Error, LocalizedError {
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Telegram API"
        case let .apiError(message):
            return "Telegram API error: \(message)"
        }
    }
}

/// Test result for Telegram integration
enum TestResult {
    case success(String)
    case failure(String)

    var isSuccess: Bool {
        switch self {
        case .success: true
        case .failure: false
        }
    }

    var description: String {
        switch self {
        case let .success(message):
            message
        case let .failure(error):
            "Telegram test failed: \(error)"
        }
    }
}

/// Service for Telegram integration and notifications
///
/// Handles sending messages to Telegram chat via bot API
/// Provides validation and functionality for Telegram integration
class TelegramService: ObservableObject {
    static let shared = TelegramService()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "TelegramService")
    private let userSettingsManager = UserSettingsManager.shared

    // Test-related properties
    @Published var isTesting = false
    @Published var lastTestResult: TestResult?

    // Custom URLSession with User-Agent to prevent CFNetwork crashes
    private lazy var customSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "ODYSSEY-Telegram/1.0"]
        return URLSession(configuration: config)
    }()

    private init() { }

    // MARK: - Public Methods

    /// Tests Telegram integration by sending a test message
    ///
    /// - Parameters:
    ///   - botToken: The Telegram bot token
    ///   - chatId: The chat ID to send the test message to
    /// - Returns: Test result indicating success or failure
    func testIntegration(botToken: String, chatId: String) async -> TestResult {
        isTesting = true
        defer { isTesting = false }

        let testMessage = """
        🎯 ODYSSEY Test Message

        This is a test message from ODYSSEY to verify Telegram integration.
        Time: \(Date().formatted(date: .abbreviated, time: .shortened))
        """

        do {
            let success = try await sendMessage(botToken: botToken, chatId: chatId, message: testMessage)
            if success {
                let result = TestResult.success("Test message sent successfully!")
                lastTestResult = result
                return result
            } else {
                let result = TestResult.failure("Failed to send test message")
                lastTestResult = result
                return result
            }
        } catch {
            let result = TestResult.failure("Error: \(error.localizedDescription)")
            lastTestResult = result
            return result
        }
    }

    /// Sends a message to Telegram
    /// - Parameters:
    ///   - botToken: The Telegram bot token
    ///   - chatId: The chat ID to send the message to
    ///   - message: The message to send
    /// - Returns: Success or failure result
    func sendMessage(botToken: String, chatId: String, message: String) async throws -> Bool {
        let urlString = "https://api.telegram.org/bot\(botToken)/sendMessage"

        guard let url = URL(string: urlString) else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "chat_id": chatId,
            "text": message,
            "parse_mode": "HTML",
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            logger.error("Failed to serialize request: \(error.localizedDescription)")
            throw error
        }

        do {
            let (data, response) = try await customSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response from Telegram API")
                throw TelegramError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                return true
            } else {
                // Parse error response
                let errorData = data
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                logger.error("Telegram API error: \(errorString)")
                throw TelegramError.apiError(errorString)
            }
        } catch {
            logger.error("Failed to send Telegram message: \(error.localizedDescription)")
            throw error
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

        🥅 \(userSettingsManager.userSettings
            .localized("ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself")
        )
        """

        do {
            let success = try await sendMessage(
                botToken: userSettingsManager.userSettings.telegramBotToken,
                chatId: userSettingsManager.userSettings.telegramChatId,
                message: successMessage,
            )
            if success {
                logger.info("Success notification sent to Telegram for \(config.name)")
            } else {
                logger.error("Failed to send Telegram success notification for \(config.name)")
            }
        } catch {
            logger
                .error("Failed to send Telegram success notification for \(config.name): \(error.localizedDescription)")
        }
    }

    /// Formats time slots information for display
    /// - Parameter config: The reservation configuration
    /// - Returns: Formatted string of time slots
    private func formatTimeSlotsInfo(for config: ReservationConfig) -> String {
        let sortedDays = config.dayTimeSlots.keys.sorted { day1, day2 in
            ReservationConfig.Weekday.allCases.firstIndex(of: day1)! < ReservationConfig.Weekday.allCases
                .firstIndex(of: day2)!
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
