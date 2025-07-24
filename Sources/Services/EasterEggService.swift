import Foundation
import os.log
import SwiftUI

/**
 EasterEgg represents a hidden feature or surprise in the app.
 */
public struct EasterEgg: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let trigger: EasterEggTrigger
    public let action: @Sendable () -> Void
    public let isDiscovered: Bool

    public init(
        id: String,
        name: String,
        description: String,
        trigger: EasterEggTrigger,
        action: @escaping @Sendable () -> Void,
        isDiscovered: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.trigger = trigger
        self.action = action
        self.isDiscovered = isDiscovered
    }
}

/**
 EasterEggTrigger defines how an easter egg can be activated.
 */
public enum EasterEggTrigger: Sendable {
    case keyCombination(String) // e.g., "⌘⌥⇧E"
    case clickSequence(Int) // Number of clicks
    case timeBased(Date) // Specific time
    case configurationCount(Int) // Number of configs
    case successCount(Int) // Number of successful reservations
    case hidden // Manual discovery only
}

/**
 EasterEggService manages hidden features and surprises for power users.

 Provides fun easter eggs that users can discover through various triggers
 like key combinations, click sequences, or achieving certain milestones.

 ## Usage Example
 ```swift
 let easterEggService = EasterEggService.shared
 easterEggService.registerEasterEggs()
 easterEggService.checkForTriggers()
 ```
 */
@MainActor
public final class EasterEggService: ObservableObject, @unchecked Sendable {
    public static let shared = EasterEggService()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "EasterEggService")
    private let userDefaults = UserDefaults.standard
    private let discoveredEggsKey = "ODYSSEY_DiscoveredEasterEggs"

    @Published public private(set) var discoveredEggs: Set<String> = []
    @Published public private(set) var easterEggs: [EasterEgg] = []
    @Published public var isEnabled = true

    private var clickCount = 0
    private var lastClickTime: Date = .init()
    private var clickTimer: Timer?

    private init() {
        loadDiscoveredEggs()
        registerEasterEggs()
        logger.info("🥚 EasterEggService initialized.")
    }

    // MARK: - Easter Egg Registration

    /**
     Registers all easter eggs in the app.
     */
    private func registerEasterEggs() {
        // Clear existing eggs
        easterEggs.removeAll()

        // Register all easter eggs
        registerKonamiCode()
        registerSecretMenu()
        registerMatrixMode()
        registerRainbowMode()
        registerTimeTravel()
        registerGodMode()
        registerSecretStats()
        registerHiddenMessage()
        registerSoundEffects()
        registerAnimationMode()

        logger.info("🥚 Registered \(self.easterEggs.count) easter eggs.")
    }

    // MARK: - Individual Easter Eggs

    /**
     Konami Code easter egg - classic gaming reference.
     */
    private func registerKonamiCode() {
        let egg = EasterEgg(
            id: "konami_code",
            name: "Konami Code",
            description: "Up, Up, Down, Down, Left, Right, Left, Right, B, A - Classic gaming reference!",
            trigger: .keyCombination("↑↑↓↓←→←→BA"),
            action: { [weak self] in
                Task { @MainActor in self?.activateKonamiCode() }
            },
            isDiscovered: discoveredEggs.contains("konami_code"),
            )
        easterEggs.append(egg)
    }

    /**
     Secret menu easter egg - hidden configuration options.
     */
    private func registerSecretMenu() {
        let egg = EasterEgg(
            id: "secret_menu",
            name: "Secret Menu",
            description: "Triple-click the app icon to reveal hidden settings",
            trigger: .clickSequence(3),
            action: { [weak self] in
                Task { @MainActor in self?.activateSecretMenu() }
            },
            isDiscovered: discoveredEggs.contains("secret_menu"),
            )
        easterEggs.append(egg)
    }

    /**
     Matrix mode easter egg - green terminal aesthetic.
     */
    private func registerMatrixMode() {
        let egg = EasterEgg(
            id: "matrix_mode",
            name: "Matrix Mode",
            description: "Hold ⌘⌥M to enter the Matrix - green terminal aesthetic",
            trigger: .keyCombination("⌘⌥M"),
            action: { [weak self] in
                Task { @MainActor in self?.activateMatrixMode() }
            },
            isDiscovered: discoveredEggs.contains("matrix_mode"),
            )
        easterEggs.append(egg)
    }

    /**
     Rainbow mode easter egg - colorful animations.
     */
    private func registerRainbowMode() {
        let egg = EasterEgg(
            id: "rainbow_mode",
            name: "Rainbow Mode",
            description: "Hold ⌘⌥R for a colorful surprise",
            trigger: .keyCombination("⌘⌥R"),
            action: { [weak self] in
                Task { @MainActor in self?.activateRainbowMode() }
            },
            isDiscovered: discoveredEggs.contains("rainbow_mode"),
            )
        easterEggs.append(egg)
    }

    /**
     Time travel easter egg - midnight activation.
     */
    private func registerTimeTravel() {
        let egg = EasterEgg(
            id: "time_travel",
            name: "Time Travel",
            description: "Open the app at exactly midnight for a temporal surprise",
            trigger: .timeBased(Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) ?? Date()),
            action: { [weak self] in
                Task { @MainActor in self?.activateTimeTravel() }
            },
            isDiscovered: discoveredEggs.contains("time_travel"),
            )
        easterEggs.append(egg)
    }

    /**
     God mode easter egg - ultimate power.
     */
    private func registerGodMode() {
        let egg = EasterEgg(
            id: "god_mode",
            name: "God Mode",
            description: "Achieve 10 successful reservations to unlock ultimate power",
            trigger: .successCount(10),
            action: { [weak self] in
                Task { @MainActor in self?.activateGodMode() }
            },
            isDiscovered: discoveredEggs.contains("god_mode"),
            )
        easterEggs.append(egg)
    }

    /**
     Secret stats easter egg - hidden statistics.
     */
    private func registerSecretStats() {
        let egg = EasterEgg(
            id: "secret_stats",
            name: "Secret Stats",
            description: "Hold ⌘⌥S to view hidden statistics",
            trigger: .keyCombination("⌘⌥S"),
            action: { [weak self] in
                Task { @MainActor in self?.activateSecretStats() }
            },
            isDiscovered: discoveredEggs.contains("secret_stats"),
            )
        easterEggs.append(egg)
    }

    /**
     Hidden message easter egg - secret communication.
     */
    private func registerHiddenMessage() {
        let egg = EasterEgg(
            id: "hidden_message",
            name: "Hidden Message",
            description: "Type 'ODYSSEY' in any text field to reveal a secret message",
            trigger: .hidden,
            action: { [weak self] in
                Task { @MainActor in self?.activateHiddenMessage() }
            },
            isDiscovered: discoveredEggs.contains("hidden_message"),
            )
        easterEggs.append(egg)
    }

    /**
     Sound effects easter egg - audio surprises.
     */
    private func registerSoundEffects() {
        let egg = EasterEgg(
            id: "sound_effects",
            name: "Sound Effects",
            description: "Hold ⌘⌥F for retro sound effects",
            trigger: .keyCombination("⌘⌥F"),
            action: { [weak self] in
                Task { @MainActor in self?.activateSoundEffects() }
            },
            isDiscovered: discoveredEggs.contains("sound_effects"),
            )
        easterEggs.append(egg)
    }

    /**
     Animation mode easter egg - enhanced animations.
     */
    private func registerAnimationMode() {
        let egg = EasterEgg(
            id: "animation_mode",
            name: "Animation Mode",
            description: "Create 5 configurations to unlock enhanced animations",
            trigger: .configurationCount(5),
            action: { [weak self] in
                Task { @MainActor in self?.activateAnimationMode() }
            },
            isDiscovered: discoveredEggs.contains("animation_mode"),
            )
        easterEggs.append(egg)
    }

    // MARK: - Easter Egg Actions

    private func activateKonamiCode() {
        logger.info("🥚 Konami Code activated!")
        discoveredEggs.insert("konami_code")
        saveDiscoveredEggs()

        // Show a fun message
        showEasterEggMessage("🎮 Konami Code Activated!", "You've unlocked the classic gaming reference!")
    }

    private func activateSecretMenu() {
        logger.info("🥚 Secret Menu activated!")
        discoveredEggs.insert("secret_menu")
        saveDiscoveredEggs()

        // Show secret menu
        showEasterEggMessage("🔐 Secret Menu", "Hidden configuration options unlocked!")
    }

    private func activateMatrixMode() {
        logger.info("🥚 Matrix Mode activated!")
        discoveredEggs.insert("matrix_mode")
        saveDiscoveredEggs()

        // Apply matrix-style theme
        showEasterEggMessage("🟢 Matrix Mode", "Welcome to the digital realm!")
    }

    private func activateRainbowMode() {
        logger.info("🥚 Rainbow Mode activated!")
        discoveredEggs.insert("rainbow_mode")
        saveDiscoveredEggs()

        // Apply rainbow theme
        showEasterEggMessage("🌈 Rainbow Mode", "Colors everywhere!")
    }

    private func activateTimeTravel() {
        logger.info("🥚 Time Travel activated!")
        discoveredEggs.insert("time_travel")
        saveDiscoveredEggs()

        // Show time travel message
        showEasterEggMessage("⏰ Time Travel", "You've discovered temporal anomalies!")
    }

    private func activateGodMode() {
        logger.info("🥚 God Mode activated!")
        discoveredEggs.insert("god_mode")
        saveDiscoveredEggs()

        // Show god mode message
        showEasterEggMessage("⚡ God Mode", "Ultimate power unlocked!")
    }

    private func activateSecretStats() {
        logger.info("🥚 Secret Stats activated!")
        discoveredEggs.insert("secret_stats")
        saveDiscoveredEggs()

        // Show secret statistics
        showEasterEggMessage("📊 Secret Stats", "Hidden statistics revealed!")
    }

    private func activateHiddenMessage() {
        logger.info("🥚 Hidden Message activated!")
        discoveredEggs.insert("hidden_message")
        saveDiscoveredEggs()

        // Show hidden message
        showEasterEggMessage("💬 Hidden Message", "You've found the secret communication!")
    }

    private func activateSoundEffects() {
        logger.info("🥚 Sound Effects activated!")
        discoveredEggs.insert("sound_effects")
        saveDiscoveredEggs()

        // Enable sound effects
        showEasterEggMessage("🔊 Sound Effects", "Retro sounds enabled!")
    }

    private func activateAnimationMode() {
        logger.info("🥚 Animation Mode activated!")
        discoveredEggs.insert("animation_mode")
        saveDiscoveredEggs()

        // Enable enhanced animations
        showEasterEggMessage("🎬 Animation Mode", "Enhanced animations unlocked!")
    }

    // MARK: - Trigger Detection

    /**
     Checks for easter egg triggers based on current app state.
     */
    public func checkForTriggers() {
        guard isEnabled else { return }

        // Check configuration count
        let configCount = ConfigurationManager.shared.settings.configurations.count
        checkConfigurationCountTrigger(configCount)

        // Check success count (this would need to be tracked elsewhere)
        // For now, we'll use a placeholder
        let successCount = 0 // This should come from actual tracking
        checkSuccessCountTrigger(successCount)

        // Check time-based triggers
        checkTimeBasedTriggers()
    }

    /**
     Records a click for click sequence triggers.
     */
    public func recordClick() {
        guard isEnabled else { return }

        let now = Date()
        if now.timeIntervalSince(lastClickTime) < 2.0 {
            clickCount += 1
        } else {
            clickCount = 1
        }
        lastClickTime = now

        // Reset click timer
        clickTimer?.invalidate()
        clickTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.checkClickSequenceTrigger()
            }
        }
    }

    /**
     Checks for key combination triggers.
     - Parameter keyCombo: The key combination pressed
     */
    public func checkKeyCombination(_ keyCombo: String) {
        guard isEnabled else { return }

        for egg in easterEggs {
            if case let .keyCombination(triggerCombo) = egg.trigger {
                if keyCombo == triggerCombo {
                    egg.action()
                    break
                }
            }
        }
    }

    // MARK: - Private Trigger Methods

    private func checkConfigurationCountTrigger(_ count: Int) {
        for egg in easterEggs {
            if case let .configurationCount(triggerCount) = egg.trigger {
                if count >= triggerCount, !discoveredEggs.contains(egg.id) {
                    egg.action()
                    break
                }
            }
        }
    }

    private func checkSuccessCountTrigger(_ count: Int) {
        for egg in easterEggs {
            if case let .successCount(triggerCount) = egg.trigger {
                if count >= triggerCount, !discoveredEggs.contains(egg.id) {
                    egg.action()
                    break
                }
            }
        }
    }

    private func checkClickSequenceTrigger() {
        for egg in easterEggs {
            if case let .clickSequence(triggerCount) = egg.trigger {
                if clickCount >= triggerCount, !discoveredEggs.contains(egg.id) {
                    egg.action()
                    break
                }
            }
        }
        clickCount = 0
    }

    private func checkTimeBasedTriggers() {
        let now = Date()
        for egg in easterEggs {
            if case let .timeBased(triggerTime) = egg.trigger {
                let calendar = Calendar.current
                let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
                let triggerComponents = calendar.dateComponents([.hour, .minute], from: triggerTime)

                if
                    nowComponents.hour == triggerComponents.hour,
                    nowComponents.minute == triggerComponents.minute,
                    !discoveredEggs.contains(egg.id) {
                    egg.action()
                    break
                }
            }
        }
    }

    // MARK: - Utility Methods

    /**
     Shows an easter egg message to the user.
     - Parameters:
     - title: The message title
     - message: The message content
     */
    private func showEasterEggMessage(_ title: String, _ message: String) {
        // This would typically show a notification or alert
        logger.info("🥚 Easter Egg: \(title) - \(message)")

        // For now, we'll just log it
        // In a real implementation, you might show a notification or alert
    }

    /**
     Gets the number of discovered easter eggs.
     - Returns: Number of discovered easter eggs
     */
    public func getDiscoveredCount() -> Int {
        return discoveredEggs.count
    }

    /**
     Gets the total number of easter eggs.
     - Returns: Total number of easter eggs
     */
    public func getTotalCount() -> Int {
        return easterEggs.count
    }

    /**
     Resets all discovered easter eggs.
     */
    public func resetDiscoveredEggs() {
        discoveredEggs.removeAll()
        saveDiscoveredEggs()
        logger.info("🥚 Reset all discovered easter eggs.")
    }

    // MARK: - Persistence

    private func saveDiscoveredEggs() {
        let array = Array(discoveredEggs)
        userDefaults.set(array, forKey: discoveredEggsKey)
    }

    private func loadDiscoveredEggs() {
        if let array = userDefaults.array(forKey: discoveredEggsKey) as? [String] {
            discoveredEggs = Set(array)
        }
    }
}
