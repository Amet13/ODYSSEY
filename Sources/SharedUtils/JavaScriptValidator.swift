import Foundation
import JavaScriptCore
import os.log

/// JavaScript validation service for linting JavaScript code in Swift
/// Provides syntax validation, custom rule checking, and error reporting
@MainActor
final class JavaScriptValidator {
  static let shared = JavaScriptValidator()

  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem,
    category: "JavaScriptValidator"
  )

  private let context = JSContext()

  private init() {
    setupJavaScriptContext()
  }

  // MARK: - Setup

  private func setupJavaScriptContext() {
    guard let context = context else {
      logger.error("❌ Failed to create JavaScript context")
      return
    }

    // Set up error handling
    context.exceptionHandler = { context, exception in
      self.logger.error("❌ JavaScript error: \(exception?.toString() ?? "unknown")")
    }

    // Add console.log support
    context.setObject(JSConsole.self, forKeyedSubscript: "console" as NSString)

    logger.info("✅ JavaScript context initialized")
  }

  // MARK: - Validation Methods

  /// Validates JavaScript syntax and custom rules
  /// - Parameter code: JavaScript code to validate
  /// - Returns: Validation result with errors and warnings
  func validateJavaScript(_ code: String) -> JavaScriptValidationResult {
    logger.info("🔍 Validating JavaScript code...")

    var errors: [String] = []
    var warnings: [String] = []

    // 1. Syntax validation
    let syntaxResult = validateSyntax(code)
    errors.append(contentsOf: syntaxResult.errors)
    warnings.append(contentsOf: syntaxResult.warnings)

    // 2. Custom rule validation
    let customResult = validateCustomRules(code)
    errors.append(contentsOf: customResult.errors)
    warnings.append(contentsOf: customResult.warnings)

    // 3. Security validation
    let securityResult = validateSecurity(code)
    errors.append(contentsOf: securityResult.errors)
    warnings.append(contentsOf: securityResult.warnings)

    let result = JavaScriptValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      code: code
    )

    if result.isValid {
      logger.info("✅ JavaScript validation passed")
    } else {
      logger.error("❌ JavaScript validation failed with \(errors.count) errors")
    }

    return result
  }

  /// Validates JavaScript syntax using JavaScriptCore
  private func validateSyntax(_ code: String) -> (errors: [String], warnings: [String]) {
    var errors: [String] = []
    var warnings: [String] = []

    guard let context = context else {
      errors.append("JavaScript context not available")
      return (errors, warnings)
    }

    // Try to evaluate the code
    _ = context.evaluateScript(code)

    if let exception = context.exception {
      errors.append("Syntax error: \(exception.toString() ?? "unknown error")")
    }

    // Check for common issues
    if code.contains("console.log") {
      warnings.append("Consider using structured logging instead of console.log")
    }

    if code.contains("alert(") {
      errors.append("alert() is not allowed in automation code")
    }

    if code.contains("prompt(") {
      errors.append("prompt() is not allowed in automation code")
    }

    return (errors, warnings)
  }

  /// Validates custom rules specific to ODYSSEY
  private func validateCustomRules(_ code: String) -> (errors: [String], warnings: [String]) {
    var errors: [String] = []
    var warnings: [String] = []

    // Check for required patterns
    let requiredPatterns = [
      "try {",
      "} catch (error) {",
      "console.error",
      "return {",
    ]

    for pattern in requiredPatterns {
      if !code.contains(pattern) {
        warnings.append("Missing required pattern: \(pattern)")
      }
    }

    // Check for proper error handling
    if code.contains("try {") && !code.contains("} catch (error) {") {
      errors.append("Try block without proper catch error handling")
    }

    // Check for proper return statements
    if code.contains("return {") && !code.contains("success:") {
      warnings.append("Return object should include success property")
    }

    // Check for proper logging
    if code.contains("console.log") && !code.contains("[ODYSSEY]") {
      warnings.append("Log messages should include '[ODYSSEY]' prefix")
    }

    return (errors, warnings)
  }

  /// Validates security aspects of the JavaScript code
  private func validateSecurity(_ code: String) -> (errors: [String], warnings: [String]) {
    var errors: [String] = []
    var warnings: [String] = []

    // Check for dangerous patterns
    let dangerousPatterns = [
      "eval(",
      "Function(",
      "setTimeout(",
      "setInterval(",
      "document.write(",
      "innerHTML =",
    ]

    for pattern in dangerousPatterns {
      if code.contains(pattern) {
        errors.append("Dangerous pattern detected: \(pattern)")
      }
    }

    // Check for proper input validation
    if code.contains("document.querySelector") && !code.contains("null") {
      warnings.append("Consider adding null checks for DOM queries")
    }

    return (errors, warnings)
  }

  // MARK: - Utility Methods

  /// Validates all JavaScript functions in the project
  func validateAllJavaScriptFunctions() -> [String: JavaScriptValidationResult] {
    logger.info("🔍 Validating all JavaScript functions...")

    var results: [String: JavaScriptValidationResult] = [:]

    // Validate JavaScriptPages.swift
    if let pagesCode = extractJavaScriptFromSwiftFile("Sources/SharedUtils/JavaScriptPages.swift") {
      results["JavaScriptPages"] = validateJavaScript(pagesCode)
    }

    // Validate JavaScriptLibrary.swift
    if let libraryCode = extractJavaScriptFromSwiftFile(
      "Sources/SharedUtils/JavaScriptLibrary.swift")
    {
      results["JavaScriptLibrary"] = validateJavaScript(libraryCode)
    }

    // Validate JavaScriptForms.swift
    if let formsCode = extractJavaScriptFromSwiftFile("Sources/SharedUtils/JavaScriptForms.swift") {
      results["JavaScriptForms"] = validateJavaScript(formsCode)
    }

    return results
  }

  /// Extracts JavaScript code from Swift files
  private func extractJavaScriptFromSwiftFile(_ filePath: String) -> String? {
    guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
      logger.error("❌ Could not read file: \(filePath)")
      return nil
    }

    // Extract JavaScript code between triple quotes
    let pattern = #"\"\"\"\s*\n(.*?)\n\s*\"\"\""#
    let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])

    guard let regex = regex else { return nil }

    let range = NSRange(location: 0, length: content.utf16.count)
    let matches = regex.matches(in: content, options: [], range: range)

    var extractedCode = ""
    for match in matches {
      if let range = Range(match.range(at: 1), in: content) {
        extractedCode += content[range] + "\n"
      }
    }

    return extractedCode.isEmpty ? nil : extractedCode
  }
}

// MARK: - Supporting Types

/// Result of JavaScript validation
struct JavaScriptValidationResult {
  let isValid: Bool
  let errors: [String]
  let warnings: [String]
  let code: String

  var hasIssues: Bool {
    !errors.isEmpty || !warnings.isEmpty
  }

  var summary: String {
    if isValid && !hasIssues {
      return "✅ Valid JavaScript code"
    } else {
      var summary = "❌ JavaScript validation issues:\n"
      if !errors.isEmpty {
        summary += "Errors:\n" + errors.map { "  • \($0)" }.joined(separator: "\n") + "\n"
      }
      if !warnings.isEmpty {
        summary += "Warnings:\n" + warnings.map { "  • \($0)" }.joined(separator: "\n")
      }
      return summary
    }
  }
}

/// Console object for JavaScript context
@objc class JSConsole: NSObject {
  @objc func log(_ message: String) {
  }

  @objc func error(_ message: String) {
  }
}
