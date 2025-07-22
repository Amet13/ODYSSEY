import Foundation
import SwiftUI

// MARK: - String Extensions

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
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            },
            )
    }
}

// MARK: - Color Extensions

public extension Color {
    /// Custom colors for the ODYSSEY app
    /// Use these for consistent branding and status feedback throughout the UI.
    /// Example: .odysseyPrimary, .odysseySuccess, .odysseyError
    static let odysseyPrimary = Color.blue
    static let odysseySecondary = Color.orange
    static let odysseySuccess = Color.green
    static let odysseyError = Color.red
    static let odysseyWarning = Color.yellow
    static let odysseyBackground = Color(.windowBackgroundColor)
    static let odysseyAccent = Color.accentColor
    static let odysseyInfo = Color.blue
}

// MARK: - Logger Extensions

import os.log

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
