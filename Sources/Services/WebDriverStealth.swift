import Foundation

import WebKit

extension WebKitService {
    /// Adds a random delay to mimic human-like timing
    func addRandomDelay() async {
        let isFastMode = UserDefaults.standard.bool(forKey: "WebKitFastMode")
        let delayRange = isFastMode ? (0.3 ... 0.8) : (0.5 ... 1.5)
        let delay = Double.random(in: delayRange)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Simulates mouse movement to an element (cosmetic, but helps with some anti-bot scripts)
    func simulateMouseMovement(to _: String) async {
        // Simulate mouse movement by scrolling to the element and waiting
        let script = """
        const el = document.querySelector(\" (selector)\");
        if (el) {
            el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
        """
        _ = try? await executeScriptInternal(script)
        let moveTime = Double.random(in: 0.2 ... 0.7)
        try? await Task.sleep(nanoseconds: UInt64(moveTime * 1_000_000_000))
    }

    /// Simulates human typing into an input element by sending keys one by one
    func simulateTyping(selector _: String, text: String, fastHumanLike: Bool = false, blurAfter: Bool = false) async {
        guard webView != nil else { return }
        for char in text {
            let script = """
            const el = document.querySelector(\" (selector)\");
            if (el) {
                el.focus();
                el.value += '\(char)';
                el.dispatchEvent(new Event('input', { bubbles: true }));
            }
            """
            _ = try? await executeScriptInternal(script)
            let isFastMode = UserDefaults.standard.bool(forKey: "WebKitFastMode")
            let delay: Double = fastHumanLike ? Double
                .random(in: 0.03 ... 0.08) :
                (isFastMode ? Double.random(in: 0.08 ... 0.15) : Double.random(in: 0.1 ... 0.25))
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if blurAfter {
            let blurScript = """
            const el = document.querySelector(\" (selector)\");
            if (el) { el.blur(); }
            """
            _ = try? await executeScriptInternal(blurScript)
        }
    }

    /// Simulates random scrolling on the page
    func simulateScrolling() async {
        let script = """
        const scrollY = Math.floor(Math.random() * (window.innerHeight / 2));
        window.scrollBy({ top: scrollY, left: 0, behavior: 'smooth' });
        """
        _ = try? await executeScriptInternal(script)
        let delay = Double.random(in: 0.2 ... 0.7)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Simulates random mouse movement on the page
    func moveMouseRandomly() async {
        let script = """
        const pointerX = Math.floor(Math.random() * window.innerWidth);
        const pointerY = Math.floor(Math.random() * window.innerHeight);
        const evt = new MouseEvent('mousemove', {
            bubbles: true,
            cancelable: true,
            clientX: pointerX,
            clientY: pointerY
        });
        document.dispatchEvent(evt);
        """
        _ = try? await executeScriptInternal(script)
        let delay = Double.random(in: 0.1 ... 0.4)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Injects JavaScript to remove automation signatures and set navigator properties
    func injectAntiDetectionScript(userAgent: String? = nil, language: String? = nil) async {
        let userAgentString = userAgent ?? self.userAgent
        let lang = language?.components(separatedBy: ",").first ?? "en-US"
        let langs = language?.components(separatedBy: ",") ?? ["en-US", "en"]
        let script = """
            // Remove webdriver property
            Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
            // Fake plugins and languages
            Object.defineProperty(navigator, 'plugins', {get: () => [1,2,3,4,5]});
            Object.defineProperty(navigator, 'languages', {get: () => \(langs)});
            Object.defineProperty(navigator, 'language', {get: () => '\(lang)'});
            // Fake Chrome object
            window.chrome = { runtime: {} };
            // Patch permissions
            const originalQuery = window.navigator.permissions.query;
            window.navigator.permissions.query = (parameters) =>
              parameters.name === 'notifications'
                ? Promise.resolve({ state: Notification.permission })
                : originalQuery(parameters);
            // User-Agent override
            Object.defineProperty(navigator, 'userAgent', {
              get: () => '\(userAgentString)'
            });
            // WebGL fingerprint spoof
            const getParameter = WebGLRenderingContext.prototype.getParameter;
            WebGLRenderingContext.prototype.getParameter = function(parameter) {
                if (parameter === 37445) return 'Intel Inc.';
                if (parameter === 37446) return 'Intel(R) Iris(TM) Plus Graphics 640';
                return getParameter.call(this, parameter);
            };
            // Canvas fingerprint spoof
            const toDataURL = HTMLCanvasElement.prototype.toDataURL;
            HTMLCanvasElement.prototype.toDataURL = function() {
                return toDataURL.apply(this, arguments) + 'a';
            };
            // Audio fingerprint spoof
            if (window.OfflineAudioContext) {
                const copy = window.OfflineAudioContext.prototype.getChannelData;
                window.OfflineAudioContext.prototype.getChannelData = function() {
                    const results = copy.apply(this, arguments);
                    results[0] = results[0] + 0.0001;
                    return results;
                };
            }
        """
        _ = try? await executeScriptInternal(script)
    }
}
