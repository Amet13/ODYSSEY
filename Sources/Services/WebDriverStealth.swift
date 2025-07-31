import Foundation

import WebKit

extension WebKitService {
    /// Simulates mouse movement to an element (cosmetic, but helps with some anti-bot scripts)
    func simulateMouseMovement(to selector: String) async {
        // Simulate mouse movement by scrolling to the element and waiting
        _ = try? await executeScriptInternal("window.odyssey.simulateMouseMovement('\(selector)');")
        let moveTime = Double.random(in: 0.2 ... 0.7)
        try? await Task.sleep(nanoseconds: UInt64(moveTime * 1_000_000_000))
    }

    /// Simulates human typing into an input element by sending keys one by one
    func simulateTyping(selector: String, text: String, fastHumanLike: Bool = false, blurAfter: Bool = false) async {
        guard webView != nil else { return }

        _ =
            try? await executeScriptInternal(
                "window.odyssey.simulateTyping('\(selector)', '\(text)', \(fastHumanLike), \(blurAfter));",
                )

        let isFastMode = UserDefaults.standard.bool(forKey: "WebKitFastMode")
        let delay: Double = fastHumanLike ? Double
            .random(in: 0.03 ... 0.08) :
            (isFastMode ? Double.random(in: 0.08 ... 0.15) : Double.random(in: 0.1 ... 0.25))
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Injects JavaScript to remove automation signatures and set navigator properties
    func injectAntiDetectionScript(userAgent: String? = nil, language: String? = nil) async {
        let userAgentString = userAgent ?? self.userAgent
        let languageString = language ?? "en-US,en"

        _ =
            try? await executeScriptInternal(
                "window.odyssey.injectAntiDetection('\(userAgentString)', '\(languageString)');",
                )
    }
}
