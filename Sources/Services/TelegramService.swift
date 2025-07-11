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
                return "Test message sent successfully!"
            case let .failure(error):
                return "Test failed: \(error)"
            }
        }

        var isSuccess: Bool {
            switch self {
            case .success: return true
            case .failure: return false
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
        🥅 ODYSSEY Test Message

        Hello! This is a test message from ODYSSEY - Ottawa Drop-in Your Sports & Schedule Easily Yourself.

        ✅ Telegram integration is working correctly!
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
            return .failure("Invalid URL")
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
            return .failure("Failed to serialize request: \(error.localizedDescription)")
        }

        do {
            let (data, response) = try await customSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure("Invalid response")
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
                       let description = json["description"] as? String
                    {
                        return .failure(description)
                    }
                }

                return .failure("HTTP \(httpResponse.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")
            }
        } catch {
            logger.error("Failed to send Telegram message: \(error.localizedDescription)")
            return .failure("Network error: \(error.localizedDescription)")
        }
    }
}
