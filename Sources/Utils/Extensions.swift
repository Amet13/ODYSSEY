import Foundation
import SwiftUI

// MARK: - String Extensions

/**
 Extension for String utilities.

 ## Usage Example
 ```swift
 let email = "user@example.com"
 print(email.maskedForLogging) // Output: us***om

 let password = "abcd efgh ijkl mnop"
 print(password.isValidGmailAppPassword) // Output: true

 let text = "Your code is 1234."
 print(text.extractVerificationCode) // Output: Optional("1234")
 ```
 */
extension String {
    /// Returns a masked version of the string for logging (shows first 2 and last 2 characters)
    var maskedForLogging: String {
        guard count > 4 else { return "***" }
        let prefix = String(prefix(2))
        let suffix = String(suffix(2))
        return "\(prefix)***\(suffix)"
    }

    /// Validates if the string matches a Gmail App Password format
    var isValidGmailAppPassword: Bool {
        let pattern = "^[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}\\s[a-z]{4}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(startIndex..., in: self)
        return regex?.firstMatch(in: self, range: range) != nil
    }

    /// Extracts a 4-digit verification code from text
    var extractVerificationCode: String? {
        let pattern = "\\b\\d{4}\\b"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(startIndex..., in: self)

        if
            let match = regex?.firstMatch(in: self, range: range),
            let matchRange = Range(match.range, in: self) {
            return String(self[matchRange])
        }
        return nil
    }
}

// MARK: - Date Extensions

/**
 Extension for Date utilities.

 ## Usage Example
 ```swift
 let date = Date()
 print(date.imapSearchFormat) // Output: "7-Jun-2024"
 print(date.isWithinLast(10)) // Output: true/false
 ```
 */
extension Date {
    /// Returns a formatted string for IMAP search (dd-MMM-yyyy format)
    var imapSearchFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d-MMM-yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }

    /// Returns true if the date is within the last N minutes
    func isWithinLast(_ minutes: Int) -> Bool {
        let cutoff = Date().addingTimeInterval(-TimeInterval(minutes * 60))
        return self > cutoff
    }
}

// MARK: - Array Extensions

/**
 Extension for [String] utilities.

 ## Usage Example
 ```swift
 let codes = ["1234", "5678", "1234"]
 print(codes.mostRecentCode) // Output: Optional("1234")
 print(codes.uniqueCodes)    // Output: ["1234", "5678"]
 ```
 */
extension [String] {
    /// Returns the most recent verification code from an array of codes
    var mostRecentCode: String? {
        return last
    }

    /// Returns unique codes only
    var uniqueCodes: [String] {
        return Array(Set(self))
    }
}

// MARK: - View Extensions

/**
 Extension for SwiftUI View utilities.

 ## Usage Example
 ```swift
 Text("Loading...")
 .loadingOverlay(true)

 Text("Conditional")
 .if(true) { $0.foregroundColor(.red) }
 ```
 */
extension View {
    /// Adds a conditional modifier based on a boolean condition
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Adds a loading overlay when the condition is true
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ProgressView()
                        .scaleEffect(AppConstants.scaleEffectLarge)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(AppConstants.opacityLight))
                }
            },
            )
    }
}

// MARK: - Color Extensions

/**
 Extension for custom ODYSSEY colors with dark mode support.

 ## Usage Example
 ```swift
 Rectangle()
 .fill(Color.odysseyPrimary)
 ```
 */
public extension Color {
    /// Custom colors for the ODYSSEY app with dark mode support
    /// Use these for consistent branding and status feedback throughout the UI.
    /// Example: .odysseyPrimary, .odysseySuccess, .odysseyError

    /// Primary brand color - adapts to dark mode
    static let odysseyPrimary = Color.blue

    /// Secondary brand color - adapts to dark mode
    static let odysseySecondary = Color.orange

    /// Success color - adapts to dark mode
    static let odysseySuccess = Color.green

    /// Error color - adapts to dark mode
    static let odysseyError = Color.red

    /// Warning color - adapts to dark mode
    static let odysseyWarning = Color.orange

    /// Background color - adapts to system appearance
    static let odysseyBackground = Color(NSColor.windowBackgroundColor)

    /// Accent color - uses system accent
    static let odysseyAccent = Color.accentColor

    /// Info color - adapts to dark mode
    static let odysseyInfo = Color.blue

    /// Card background - adapts to system appearance
    static let odysseyCardBackground = Color(NSColor.controlBackgroundColor)

    /// Border color - adapts to system appearance
    static let odysseyBorder = Color(NSColor.separatorColor)

    /// Text color - adapts to system appearance
    static let odysseyText = Color(NSColor.labelColor)

    /// Secondary text color - adapts to system appearance
    static let odysseySecondaryText = Color(NSColor.secondaryLabelColor)

    /// Gray color - adapts to dark mode
    static let odysseyGray = Color.gray
}

// MARK: - Logger Extensions

import os.log

/**
 Extension for Logger utilities.

 ## Usage Example
 ```swift
 let logger = Logger(subsystem: "com.odyssey.app", category: "Test")
 logger.infoMasked("Logging email", sensitiveData: "user@example.com")
 logger.errorWithContext("Failed operation", error: MyError(), context: "Reservation")
 ```
 */
extension Logger {
    /// Logs a masked version of sensitive data
    func infoMasked(_ message: String, sensitiveData: String) {
        info("\(message): \(sensitiveData.maskedForLogging)")
    }

    /// Logs an error with additional context
    func errorWithContext(_ message: String, error: Error, context: String = "") {
        let contextPrefix = context.isEmpty ? "" : "[\(context)] "
        self.error("\(contextPrefix)\(message): \(error.localizedDescription)")
    }
}
