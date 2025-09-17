import Foundation

public enum DomainError: Error, LocalizedError {
  case validation(ValidationError)
  case network(NetworkError)
  case storage(StorageError)
  case automation(AutomationError)
  case unknown(String)

  public var errorDescription: String? {
    switch self {
    case .validation(let error): return error.localizedDescription
    case .network(let error): return error.localizedDescription
    case .storage(let error): return error.localizedDescription
    case .automation(let error): return error.localizedDescription
    case .unknown(let message): return message
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
    case .invalidEmail(let email): return "Invalid email format: \(email)"
    case .invalidURL(let url): return "Invalid URL format: \(url)"
    case .requiredFieldMissing(let field): return "Required field missing: \(field)"
    case .invalidFormat(let format): return "Invalid format: \(format)"
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
    case .connectionFailed(let message): return "Connection failed: \(message)"
    case .timeout(let message): return "Request timeout: \(message)"
    case .serverError(let message): return "Server error: \(message)"
    case .unauthorized(let message): return "Unauthorized: \(message)"
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
    case .saveFailed(let message): return "Save failed: \(message)"
    case .loadFailed(let message): return "Load failed: \(message)"
    case .deleteFailed(let message): return "Delete failed: \(message)"
    case .notFound(let message): return "Not found: \(message)"
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
    case .elementNotFound(let element): return "Element not found: \(element)"
    case .pageLoadTimeout(let page): return "Page load timeout: \(page)"
    case .scriptExecutionFailed(let script): return "Script execution failed: \(script)"
    case .humanBehaviorFailed(let behavior): return "Human behavior failed: \(behavior)"
    }
  }
}
