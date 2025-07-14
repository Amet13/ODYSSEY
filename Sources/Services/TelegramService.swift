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
    /// - Parameters:
    ///   - config: The reservation configuration that was successfully executed
    ///   - screenshotData: Optional screenshot data to include
    func sendSuccessNotification(for config: ReservationConfig, screenshotData: Data? = nil) async {
        guard userSettingsManager.userSettings.hasTelegramConfigured else {
            logger.info("Telegram notifications are disabled")
            return
        }

        logger.info("Sending success notification to Telegram for \(config.name, privacy: .private)")

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
            if let screenshotData {
                // Send single message with photo and caption
                await sendPhotoWithCaption(
                    screenshotData: screenshotData,
                    caption: successMessage,
                    configName: config.name,
                )
            } else {
                // Send text-only message if no screenshot
                let success = try await sendMessage(
                    botToken: userSettingsManager.userSettings.telegramBotToken,
                    chatId: userSettingsManager.userSettings.telegramChatId,
                    message: successMessage,
                )
                if success {
                    logger.info("Success notification sent to Telegram for \(config.name, privacy: .private)")
                } else {
                    logger
                        .error("Failed to send Telegram success notification for \(config.name, privacy: .private)")
                }
            }
        } catch {
            logger
                .error(
                    "Failed to send Telegram success notification for \(config.name, privacy: .private): \(error.localizedDescription)",
                )
        }
    }

    /// Sends a failure notification to Telegram when a reservation fails
    /// - Parameters:
    ///   - config: The reservation configuration that failed
    ///   - error: The error message describing the failure
    ///   - screenshotData: Optional screenshot data to include
    func sendFailureNotification(for config: ReservationConfig, error: String, screenshotData: Data? = nil) async {
        guard userSettingsManager.userSettings.hasTelegramConfigured else {
            logger.info("Telegram notifications are disabled")
            return
        }

        logger.info("Sending failure notification to Telegram for \(config.name, privacy: .private)")

        // Extract facility name from URL
        let facilityName = ReservationConfig.extractFacilityName(from: config.facilityURL)

        // Format time slots information
        let timeSlotsInfo = formatTimeSlotsInfo(for: config)

        let failureMessage = """
        <b>❌ \(userSettingsManager.userSettings.localized("Reservation Failed"))</b>

        🎯 \(userSettingsManager.userSettings.localized("Failed to book:")) \(config.sportName)

        🏢 \(userSettingsManager.userSettings.localized("Facility:")) \(facilityName)

        👥 \(userSettingsManager.userSettings.localized("People:")) \(config.numberOfPeople)

        📅 \(userSettingsManager.userSettings.localized("Schedule:")) \(timeSlotsInfo)

        ⚠️ \(userSettingsManager.userSettings.localized("Error:")) \(error)

        🥅 \(userSettingsManager.userSettings
            .localized("ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself")
        )
        """

        do {
            if let screenshotData {
                // Send single message with photo and caption
                await sendPhotoWithCaption(
                    screenshotData: screenshotData,
                    caption: failureMessage,
                    configName: config.name,
                )
            } else {
                // Send text-only message if no screenshot
                let success = try await sendMessage(
                    botToken: userSettingsManager.userSettings.telegramBotToken,
                    chatId: userSettingsManager.userSettings.telegramChatId,
                    message: failureMessage,
                )

                if success {
                    logger.info("Failure notification sent to Telegram for \(config.name, privacy: .private)")
                } else {
                    logger
                        .error("Failed to send Telegram failure notification for \(config.name, privacy: .private)")
                }
            }
        } catch {
            logger
                .error(
                    "Failed to send Telegram failure notification for \(config.name, privacy: .private): \(error.localizedDescription)",
                )
        }
    }

    /// Sends a photo with caption to Telegram (single message)
    /// - Parameters:
    ///   - screenshotData: The screenshot data to send
    ///   - caption: The caption text to include with the photo
    ///   - configName: The name of the configuration for logging
    private func sendPhotoWithCaption(screenshotData: Data, caption: String, configName: String) async {
        let urlString = "https://api.telegram.org/bot\(userSettingsManager.userSettings.telegramBotToken)/sendPhoto"

        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL for sending photo with caption")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add chat_id
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n".utf8))
        body.append(Data("\(userSettingsManager.userSettings.telegramChatId)\r\n".utf8))

        // Add caption with parse_mode
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".utf8))
        body.append(Data("\(caption)\r\n".utf8))

        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"parse_mode\"\r\n\r\n".utf8))
        body.append(Data("HTML\r\n".utf8))

        // Add photo
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(
            Data("Content-Disposition: form-data; name=\"photo\"; filename=\"screenshot.png\"\r\n".utf8),
        )
        body.append(Data("Content-Type: image/png\r\n\r\n".utf8))
        body.append(screenshotData)
        body.append(Data("\r\n".utf8))

        // End boundary
        body.append(Data("--\(boundary)--\r\n".utf8))

        request.httpBody = body

        do {
            let (data, response) = try await customSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response from Telegram API for photo with caption")
                return
            }

            if httpResponse.statusCode == 200 {
                logger
                    .info("Failure notification with screenshot sent to Telegram for \(configName, privacy: .private)")
            } else {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.error("Failed to send photo with caption to Telegram: \(errorString)")
            }
        } catch {
            logger.error("Failed to send photo with caption to Telegram: \(error.localizedDescription)")
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
