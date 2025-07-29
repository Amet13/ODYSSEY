import Foundation
import os.log

/// Manages the global God Mode UI state for keyboard shortcuts.
@MainActor
public final class GodModeStateManager: ObservableObject, @unchecked Sendable {
    public static let shared = GodModeStateManager()

    @Published public var isGodModeUIEnabled: Bool = false

    private let logger = Logger(subsystem: "com.odyssey.app", category: "GodModeStateManager")

    private init() {
        logger.info("🔧 GodModeStateManager initialized.")
    }

    public func toggleGodModeUI() {
        isGodModeUIEnabled.toggle()
        logger.info("⌨️ God Mode UI toggled to: \(self.isGodModeUIEnabled).")
    }

    public func setGodModeUI(_ enabled: Bool) {
        isGodModeUIEnabled = enabled
        logger.info("⌨️ God Mode UI set to: \(self.isGodModeUIEnabled).")
    }
}
