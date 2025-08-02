import Foundation

public enum DomainError: Error, LocalizedError {
  case validation(ValidationError)
  case network(NetworkError)
  case storage(StorageError)
  case automation(AutomationError)
  case unknown(String)

  public var errorDescription: String? {
    switch self {
    case let .validation(error): return error.localizedDescription
    case let .network(error): return error.localizedDescription
    case let .storage(error): return error.localizedDescription
    case let .automation(error): return error.localizedDescription
    case let .unknown(message): return message
    }
  }
}

public enum ValidationError: Error, LocalizedError {
  case invalidEmail(String)
  case invalidURL(String)
  case requiredFieldMissing(String)
  case invalidFormat(String)

  public var errorDescription: String? {
    switch self {
    case let .invalidEmail(email): return "Invalid email format: \(email)"
    case let .invalidURL(url): return "Invalid URL format: \(url)"
    case let .requiredFieldMissing(field): return "Required field missing: \(field)"
    case let .invalidFormat(format): return "Invalid format: \(format)"
    }
  }
}

public enum NetworkError: Error, LocalizedError {
  case connectionFailed(String)
  case timeout(String)
  case serverError(String)
  case unauthorized(String)

  public var errorDescription: String? {
    switch self {
    case let .connectionFailed(message): return "Connection failed: \(message)"
    case let .timeout(message): return "Request timeout: \(message)"
    case let .serverError(message): return "Server error: \(message)"
    case let .unauthorized(message): return "Unauthorized: \(message)"
    }
  }
}

public enum StorageError: Error, LocalizedError {
  case saveFailed(String)
  case loadFailed(String)
  case deleteFailed(String)
  case notFound(String)

  public var errorDescription: String? {
    switch self {
    case let .saveFailed(message): return "Save failed: \(message)"
    case let .loadFailed(message): return "Load failed: \(message)"
    case let .deleteFailed(message): return "Delete failed: \(message)"
    case let .notFound(message): return "Not found: \(message)"
    }
  }
}

public enum AutomationError: Error, LocalizedError {
  case elementNotFound(String)
  case pageLoadTimeout(String)
  case scriptExecutionFailed(String)
  case humanBehaviorFailed(String)

  public var errorDescription: String? {
    switch self {
    case let .elementNotFound(element): return "Element not found: \(element)"
    case let .pageLoadTimeout(page): return "Page load timeout: \(page)"
    case let .scriptExecutionFailed(script): return "Script execution failed: \(script)"
    case let .humanBehaviorFailed(behavior): return "Human behavior failed: \(behavior)"
    }
  }
}
