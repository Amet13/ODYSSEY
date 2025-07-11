import Foundation
import Network
import os.log

/// Service for email/IMAP integration and testing
///
/// Handles IMAP connection testing and email validation
/// Provides test functionality for email settings
class EmailService: ObservableObject {
    static let shared = EmailService()

    @Published var isTesting = false
    @Published var lastTestResult: TestResult?

    private let logger = Logger(subsystem: "com.odyssey.app", category: "EmailService")

    enum IMAPError: Error {
        case connectionFailed(String)
        case authenticationFailed(String)
        case commandFailed(String)
        case invalidResponse(String)

        var localizedDescription: String {
            switch self {
            case let .connectionFailed(message): return "Connection failed: \(message)"
            case let .authenticationFailed(message): return "Authentication failed: \(message)"
            case let .commandFailed(message): return "Command failed: \(message)"
            case let .invalidResponse(message): return "Invalid response: \(message)"
            }
        }
    }

    enum TestResult {
        case success(String)
        case failure(String)

        var description: String {
            switch self {
            case let .success(message):
                return message
            case let .failure(error):
                return "IMAP test failed: \(error)"
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

    /// Tests IMAP connection and fetches the latest email from the mailbox
    /// - Parameters:
    ///   - email: The email address
    ///   - password: The email password
    ///   - server: The IMAP server address
    /// - Returns: Test result indicating success or failure with email details
    func testIMAPConnection(email: String, password: String, server: String) async -> TestResult {
        await MainActor.run {
            isTesting = true
        }

        defer {
            Task { @MainActor in
                isTesting = false
            }
        }

        // Validate inputs
        guard !email.isEmpty else {
            return .failure("Email address is empty")
        }

        guard !password.isEmpty else {
            return .failure("Password is empty")
        }

        guard !server.isEmpty else {
            return .failure("IMAP server is empty")
        }

        // Validate email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            return .failure("Invalid email format")
        }

        // Determine port based on server (default to 993 for SSL)
        let port: UInt16 = 993

        return await connectToIMAP(server: server, port: port, email: email, password: password)
    }

    /// Connects to IMAP server and fetches the latest email
    private func connectToIMAP(server: String, port: UInt16, email: String, password: String) async -> TestResult {
        let connection = NWConnection(host: NWEndpoint.Host(server), port: NWEndpoint.Port(integerLiteral: port), using: .tls)

        return await withCheckedContinuation { continuation in
            let resumeQueue = DispatchQueue(label: "EmailService.IMAP.resumeQueue")
            var hasResumed = false
            func safeResume(_ result: TestResult) {
                resumeQueue.sync {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: result)
                    }
                }
            }

            connection.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    // Connection established, now send IMAP commands
                    self?.performIMAPHandshake(connection: connection, email: email, password: password) { result in
                        safeResume(result)
                        connection.cancel()
                    }
                case let .failed(error):
                    self?.logger.error("IMAP connection failed: \(error)")
                    safeResume(.failure("Connection failed: \(error.localizedDescription)"))
                    connection.cancel()
                case .cancelled:
                    safeResume(.failure("Connection cancelled"))
                default:
                    break
                }
            }

            connection.start(queue: .global())
        }
    }

    /// Performs IMAP handshake and authentication
    private func performIMAPHandshake(connection: NWConnection, email: String, password: String, completion: @escaping (TestResult) -> Void) {
        // Send CAPABILITY command
        let capabilityCommand = "a001 CAPABILITY\r\n"
        sendIMAPCommand(connection: connection, command: capabilityCommand) { [weak self] (result: Result<String, IMAPError>) in
            switch result {
            case .success:
                // Send LOGIN command
                let loginCommand = "a002 LOGIN \"\(email)\" \"\(password)\"\r\n"
                self?.sendIMAPCommand(connection: connection, command: loginCommand) { [weak self] (result: Result<String, IMAPError>) in
                    switch result {
                    case .success:
                        // Select INBOX
                        let selectCommand = "a003 SELECT INBOX\r\n"
                        self?.sendIMAPCommand(connection: connection, command: selectCommand) { [weak self] (result: Result<String, IMAPError>) in
                            switch result {
                            case .success:
                                // SEARCH ALL to get all message IDs
                                let searchCommand = "a004 SEARCH ALL\r\n"
                                self?.sendIMAPCommand(connection: connection, command: searchCommand) { [weak self] (result: Result<String, IMAPError>) in
                                    switch result {
                                    case let .success(searchResponse):
                                        // Parse message IDs
                                        let lines = searchResponse.components(separatedBy: .newlines)
                                        let searchLine = lines.first(where: { $0.contains("SEARCH") }) ?? ""
                                        let parts = searchLine.components(separatedBy: " ")
                                        let ids = parts.dropFirst().compactMap { Int($0) }
                                        if let lastId = ids.last {
                                            // Fetch latest email headers
                                            let fetchCommand = "a005 FETCH \(lastId) BODY[HEADER.FIELDS (FROM SUBJECT DATE)]\r\n"
                                            self?.sendIMAPCommand(connection: connection, command: fetchCommand) { [weak self] (result: Result<String, IMAPError>) in
                                                switch result {
                                                case .success:
                                                    completion(.success("IMAP connection successful!"))
                                                case let .failure(error):
                                                    self?.logger.error("IMAP: FETCH failed: \(error.localizedDescription)")
                                                    completion(.failure("Failed to fetch email: \(error.localizedDescription)"))
                                                }
                                            }
                                        } else {
                                            completion(.success("IMAP connection successful!"))
                                        }
                                    case let .failure(error):
                                        completion(.failure("Failed to search mailbox: \(error.localizedDescription)"))
                                    }
                                }
                            case let .failure(error):
                                completion(.failure("Failed to select INBOX: \(error.localizedDescription)"))
                            }
                        }
                    case let .failure(error):
                        completion(.failure("Authentication failed: \(error.localizedDescription)"))
                    }
                }
            case let .failure(error):
                completion(.failure("IMAP handshake failed: \(error.localizedDescription)"))
            }
        }
    }

    /// Sends IMAP command and waits for response
    private func sendIMAPCommand(connection: NWConnection, command: String, completion: @escaping (Result<String, IMAPError>) -> Void) {
        guard let data = command.data(using: .utf8) else {
            completion(.failure(.commandFailed("Invalid command encoding")))
            return
        }

        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                completion(.failure(.commandFailed("Send error: \(error.localizedDescription)")))
                return
            }

            // Receive response
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { content, _, _, error in
                if let error = error {
                    completion(.failure(.commandFailed("Receive error: \(error.localizedDescription)")))
                    return
                }

                if let data = content, let response = String(data: data, encoding: .utf8) {
                    // Check if response indicates success
                    if response.contains("OK") {
                        completion(.success(response))
                    } else if response.contains("NO") || response.contains("BAD") {
                        completion(.failure(.commandFailed("IMAP error: \(response)")))
                    } else {
                        completion(.success(response))
                    }
                } else {
                    completion(.failure(.invalidResponse("Invalid response")))
                }
            }
        })
    }

    /// Parses email headers from IMAP response
    private func parseEmailHeaders(_ response: String) -> String {
        let lines = response.components(separatedBy: .newlines)
        var from = "Unknown"
        var subject = "No Subject"
        var date = "Unknown Date"

        for line in lines {
            if line.hasPrefix("From:") {
                from = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Subject:") {
                subject = String(line.dropFirst(9)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Date:") {
                date = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            }
        }

        return "From: \(from) - Subject: \(subject) - Date: \(date)"
    }
}
