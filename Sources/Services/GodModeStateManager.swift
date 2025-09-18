import Foundation
import os

/// Manages the global God Mode UI state for keyboard shortcuts.
@MainActor
public final class GodModeStateManager: ObservableObject, @unchecked Sendable {
  public static let shared = GodModeStateManager()

  @Published public var isGodModeUIEnabled = false

  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem, category: "GodModeStateManager")

  private init() {
    LoggingUtils.logInitialization(logger, "GodModeStateManager")
  }

  public func toggleGodModeUI() {
    isGodModeUIEnabled.toggle()
    LoggingUtils.logSuccess(logger, "God Mode UI toggled to: \(self.isGodModeUIEnabled)")
  }
}
