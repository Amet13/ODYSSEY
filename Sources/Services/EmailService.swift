import Foundation
import Network
import os.log

/// Service for email/IMAP integration and testing
///
/// Handles IMAP connection testing and email validation
/// Provides test functionality for email settings
@MainActor
class EmailService: ObservableObject {
    static let shared = EmailService()

    @Published var isTesting = false
    @Published var lastTestResult: TestResult?

    private let logger = Logger(subsystem: "com.odyssey.app", category: "EmailService")
    private let userSettingsManager = UserSettingsManager.shared

    enum IMAPError: Error {
        case connectionFailed(String)
        case authenticationFailed(String)
        case commandFailed(String)
        case invalidResponse(String)
        case timeout(String)
        case unsupportedServer(String)

        var localizedDescription: String {
            switch self {
            case let .connectionFailed(message): UserSettingsManager.shared.userSettings.localized("Connection failed:") + " \(message)"
            case let .authenticationFailed(message): UserSettingsManager.shared.userSettings.localized("Authentication failed:") + " \(message)"
            case let .commandFailed(message): UserSettingsManager.shared.userSettings.localized("Command failed:") + " \(message)"
            case let .invalidResponse(message): UserSettingsManager.shared.userSettings.localized("Invalid response:") + " \(message)"
            case let .timeout(message): UserSettingsManager.shared.userSettings.localized("Connection timeout:") + " \(message)"
            case let .unsupportedServer(message): UserSettingsManager.shared.userSettings.localized("Unsupported server:") + " \(message)"
            }
        }
    }

    enum TestResult {
        case success(String)
        case failure(String)

        var description: String {
            switch self {
            case let .success(message):
                message
            case let .failure(error):
                UserSettingsManager.shared.userSettings.localized("IMAP test failed:") + " \(error)"
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

    func testIMAPConnection(email: String, password: String, server: String) async -> TestResult {
        isTesting = true
        defer { isTesting = false }
        guard !email.isEmpty else {
            return .failure(userSettingsManager.userSettings.localized("Email address is empty"))
        }
        guard !password.isEmpty else {
            return .failure(userSettingsManager.userSettings.localized("Password is empty"))
        }
        guard !server.isEmpty else {
            return .failure(userSettingsManager.userSettings.localized("IMAP server is empty"))
        }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            return .failure(userSettingsManager.userSettings.localized("Invalid email format"))
        }
        let portConfigurations = [
            (port: UInt16(993), useTLS: true, description: "SSL/TLS"),
            (port: UInt16(143), useTLS: false, description: "Plain"),
            (port: UInt16(143), useTLS: true, description: "STARTTLS")
        ]
        for config in portConfigurations {
            logger.info("Trying IMAP connection to \(server):\(config.port) (\(config.description))")
            let result = await connectToIMAP(
                server: server,
                port: config.port,
                useTLS: config.useTLS,
                email: email,
                password: password,
                )
            if case .success = result { return result }
            if case let .failure(error) = result {
                logger.warning("IMAP connection failed on \(server):\(config.port): \(error)")
            }
        }
        return .failure(userSettingsManager.userSettings.localized("All IMAP connection attempts failed"))
    }

    private func connectToIMAP(server: String, port: UInt16, useTLS: Bool, email: String, password: String) async -> TestResult {
        let parameters = NWParameters.tcp
        if useTLS {
            parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolTLS.Options(), at: 0)
        }
        let connection = NWConnection(
            host: NWEndpoint.Host(server),
            port: NWEndpoint.Port(integerLiteral: port),
            using: parameters,
            )
        return await withCheckedContinuation { continuation in
            let hasResumed = AtomicBool(false)
            @Sendable func safeResume(_ result: TestResult) {
                if hasResumed.testAndSet() {
                    Task { @MainActor in
                        self.isTesting = false
                        self.lastTestResult = result
                        continuation.resume(returning: result)
                    }
                }
            }
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                safeResume(.failure(IMAPError.timeout("Connection timed out after 30 seconds").localizedDescription))
            }
            connection.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    Task {
                        await self.performIMAPHandshake(connection: connection, email: email, password: password, useTLS: useTLS) { result in
                            timeoutTask.cancel()
                            safeResume(result)
                            connection.cancel()
                        }
                    }
                case let .failed(error):
                    timeoutTask.cancel()
                    safeResume(.failure(IMAPError.connectionFailed(error.localizedDescription).localizedDescription))
                    connection.cancel()
                case .cancelled:
                    timeoutTask.cancel()
                    safeResume(.failure(IMAPError.connectionFailed("Connection cancelled").localizedDescription))
                case let .waiting(error):
                    logger.warning("IMAP connection waiting: \(error)")
                default:
                    break
                }
            }
            connection.start(queue: .global())
        }
    }

    private func performIMAPHandshake(connection: NWConnection, email: String, password: String, useTLS: Bool, completion: @escaping (TestResult) -> Void) async {
        receiveIMAPResponse(connection: connection) { [weak self] (result: Result<String, IMAPError>) in
            guard let self else { return }
            switch result {
            case let .success(greeting):
                logger.info("IMAP greeting received: \(greeting.prefix(100))")
                if !useTLS, greeting.contains("STARTTLS") {
                    Task {
                        await self.upgradeToTLS(connection: connection) { tlsResult in
                            switch tlsResult {
                            case .success:
                                Task { await self.continueIMAPHandshake(connection: connection, email: email, password: password, completion: completion) }
                            case let .failure(error):
                                completion(.failure(error.localizedDescription))
                            }
                        }
                    }
                } else {
                    Task { await self.continueIMAPHandshake(connection: connection, email: email, password: password, completion: completion) }
                }
            case let .failure(error):
                completion(.failure(error.localizedDescription))
            }
        }
    }

    private func continueIMAPHandshake(connection: NWConnection, email: String, password: String, completion: @escaping (TestResult) -> Void) async {
        await sendIMAPCommand(connection: connection, command: "a001 CAPABILITY\r\n") { [weak self] (result: Result<String, IMAPError>) in
            guard let self else { return }
            switch result {
            case .success:
                let loginCommand = "a002 LOGIN \"\(email)\" \"\(password)\"\r\n"
                Task {
                    await self.sendIMAPCommand(connection: connection, command: loginCommand) { [weak self] (result: Result<String, IMAPError>) in
                        guard let self else { return }
                        switch result {
                        case .success:
                            let selectCommand = "a003 SELECT INBOX\r\n"
                            Task {
                                await self.sendIMAPCommand(connection: connection, command: selectCommand) { [weak self] (result: Result<String, IMAPError>) in
                                    guard let self else { return }
                                    switch result {
                                    case .success:
                                        let searchCommand = "a004 SEARCH ALL\r\n"
                                        Task {
                                            await self.sendIMAPCommand(connection: connection, command: searchCommand) { [weak self] (result: Result<String, IMAPError>) in
                                                guard let self else { return }
                                                switch result {
                                                case let .success(searchResponse):
                                                    let lines = searchResponse.components(separatedBy: .newlines)
                                                    let searchLine = lines.first(where: { $0.contains("SEARCH") }) ?? ""
                                                    let parts = searchLine.components(separatedBy: " ")
                                                    let ids = parts.dropFirst().compactMap { Int($0) }
                                                    if let lastId = ids.last {
                                                        let fetchCommand = "a005 FETCH \(lastId) BODY[HEADER.FIELDS (FROM SUBJECT DATE)]\r\n"
                                                        Task {
                                                            await self.sendIMAPCommand(connection: connection, command: fetchCommand) { (result: Result<String, IMAPError>) in
                                                                switch result {
                                                                case .success:
                                                                    completion(.success(self.userSettingsManager.userSettings.localized("IMAP connection successful!")))
                                                                case let .failure(error):
                                                                    self.logger.error("IMAP: FETCH failed: \(error.localizedDescription)")
                                                                    completion(.failure(self.userSettingsManager.userSettings.localized("Failed to fetch email:") + " \(error.localizedDescription)"))
                                                                }
                                                            }
                                                        }
                                                    } else {
                                                        completion(.success(userSettingsManager.userSettings.localized("IMAP connection successful!")))
                                                    }
                                                case let .failure(error):
                                                    completion(.failure(userSettingsManager.userSettings.localized("Failed to search mailbox:") + " \(error.localizedDescription)"))
                                                }
                                            }
                                        }
                                    case let .failure(error):
                                        completion(.failure(userSettingsManager.userSettings.localized("Failed to select INBOX:") + " \(error.localizedDescription)"))
                                    }
                                }
                            }
                        case let .failure(error):
                            completion(.failure(userSettingsManager.userSettings.localized("Authentication failed:") + " \(error.localizedDescription)"))
                        }
                    }
                }
            case let .failure(error):
                completion(.failure(userSettingsManager.userSettings.localized("IMAP handshake failed:") + " \(error.localizedDescription)"))
            }
        }
    }

    private func upgradeToTLS(connection: NWConnection, completion: @escaping (Result<Void, IMAPError>) -> Void) async {
        await sendIMAPCommand(connection: connection, command: "a001 STARTTLS\r\n") { (result: Result<String, IMAPError>) in
            switch result {
            case .success:
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    completion(.success(()))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func sendIMAPCommand(connection: NWConnection, command: String, completion: @escaping (Result<String, IMAPError>) -> Void) async {
        guard let data = command.data(using: .utf8) else {
            completion(.failure(.commandFailed(userSettingsManager.userSettings.localized("Invalid command encoding"))))
            return
        }
        let localizedSendError = userSettingsManager.userSettings.localized("Send error:")
        connection.send(content: data, completion: .contentProcessed { error in
            if let error {
                completion(.failure(.commandFailed(localizedSendError + " \(error.localizedDescription)")))
                return
            }
            Task { @MainActor in
                self.receiveIMAPResponse(connection: connection, completion: completion)
            }
        })
    }

    private func receiveIMAPResponse(connection: NWConnection, completion: @escaping (Result<String, IMAPError>) -> Void) {
        let localizedReceiveError = userSettingsManager.userSettings.localized("Receive error:")
        let localizedIMAPError = userSettingsManager.userSettings.localized("IMAP error:")
        let localizedInvalidResponse = userSettingsManager.userSettings.localized("Invalid response")

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { content, _, _, error in
            if let error {
                completion(.failure(.commandFailed(localizedReceiveError + " \(error.localizedDescription)")))
                return
            }
            if let data = content, let response = String(data: data, encoding: .utf8) {
                if response.contains("OK") {
                    completion(.success(response))
                } else if response.contains("NO") || response.contains("BAD") {
                    completion(.failure(.commandFailed(localizedIMAPError + " \(response)")))
                } else {
                    completion(.success(response))
                }
            } else {
                completion(.failure(.invalidResponse(localizedInvalidResponse)))
            }
        }
    }

    private func parseEmailHeaders(_ response: String) -> String {
        let lines = response.components(separatedBy: .newlines)
        var from = userSettingsManager.userSettings.localized("Unknown")
        var subject = userSettingsManager.userSettings.localized("No Subject")
        var date = userSettingsManager.userSettings.localized("Unknown Date")
        for line in lines {
            if line.hasPrefix("From:") {
                from = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Subject:") {
                subject = String(line.dropFirst(9)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Date:") {
                date = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            }
        }
        return "\(userSettingsManager.userSettings.localized("From:")) \(from) - \(userSettingsManager.userSettings.localized("Subject:")) \(subject) - \(userSettingsManager.userSettings.localized("Date:")) \(date)"
    }

    // MARK: - Notification Methods

    /// Sends a success notification email when a reservation is completed
    /// - Parameter config: The reservation configuration that was successfully executed
    func sendSuccessNotification(for config: ReservationConfig) async {
        guard userSettingsManager.userSettings.hasEmailConfigured else {
            logger.info("Email notifications are disabled")
            return
        }

        await MainActor.run {
            self.logger.info("Sending success notification email for \(config.name)")
            // For now, just log the success
            // In a full implementation, this would send an actual email
            let facilityName = ReservationConfig.extractFacilityName(from: config.facilityURL)
            self.logger.info("Success notification would be sent for \(config.sportName) at \(facilityName) to \(self.userSettingsManager.userSettings.imapEmail)")
        }
    }
}

final class AtomicBool {
    private let lock = NSLock()
    private var value: Bool
    init(_ value: Bool) { self.value = value }
    func testAndSet() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if value { return false }
        value = true
        return true
    }
}
