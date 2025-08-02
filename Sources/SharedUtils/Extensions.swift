import Foundation
import SwiftUI
import os.log

// MARK: - String Extensions

/// Extension for String utilities.
///
/// Provides masking, validation, and extraction capabilities for strings used throughout the application.
extension String {
  /// Returns a masked version of the string for logging (shows first 2 and last 2 characters)
  var maskedForLogging: String {
    guard count > 4 else { return "***" }
    let prefix = String(prefix(2))
    let suffix = String(suffix(2))
    return "\(prefix)***\(suffix)"
  }

  /// Extracts a 4-digit verification code from text
  var extractVerificationCode: String? {
    let pattern = "\\b\\d{4}\\b"
    let regex = try? NSRegularExpression(pattern: pattern)
    let range = NSRange(startIndex..., in: self)

    if let match = regex?.firstMatch(in: self, range: range),
      let matchRange = Range(match.range, in: self)
    {
      return String(self[matchRange])
    }
    return nil
  }
}

// MARK: - Date Extensions

/// Extension for Date utilities.
///
/// Provides date formatting and validation capabilities for IMAP operations and time-based checks.
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

/// Extension for [String] utilities.
///
/// Provides verification code management and deduplication capabilities for email verification workflows.
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

/// Extension for SwiftUI View utilities.
///
/// Provides conditional modifiers and loading overlay capabilities for enhanced UI interactions.
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

/// Extension for custom ODYSSEY colors with dark mode support.
///
/// Provides a consistent color palette for the ODYSSEY application with automatic dark mode adaptation.
extension Color {
  /// Custom colors for the ODYSSEY app with dark mode support
  /// Use these for consistent branding and status feedback throughout the UI.

  /// Primary brand color - adapts to dark mode
  public static let odysseyPrimary = Color.blue

  /// Secondary brand color - adapts to dark mode
  public static let odysseySecondary = Color.orange

  /// Success color - adapts to dark mode
  public static let odysseySuccess = Color.green

  /// Error color - adapts to dark mode
  public static let odysseyError = Color.red

  /// Warning color - adapts to dark mode
  public static let odysseyWarning = Color.orange

  /// Background color - adapts to system appearance
  public static let odysseyBackground = Color(NSColor.windowBackgroundColor)

  /// Accent color - uses system accent
  public static let odysseyAccent = Color.accentColor

  /// Info color - adapts to dark mode
  public static let odysseyInfo = Color.blue

  /// Card background - adapts to system appearance
  public static let odysseyCardBackground = Color(NSColor.controlBackgroundColor)

  /// Border color - adapts to system appearance
  public static let odysseyBorder = Color(NSColor.separatorColor)

  /// Text color - adapts to system appearance
  public static let odysseyText = Color(NSColor.labelColor)

  /// Secondary text color - adapts to system appearance
  public static let odysseySecondaryText = Color(NSColor.secondaryLabelColor)

  /// Gray color - adapts to dark mode
  public static let odysseyGray = Color.gray
}

// MARK: - Logger Extensions

/// Extension for Logger utilities.
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

/// A standardized divider for splitting headers and footers in all views
public struct HeaderFooterDivider: View {
  public init() {}
  public var body: some View {
    Divider().padding(.horizontal, AppConstants.contentPadding)
  }
}
