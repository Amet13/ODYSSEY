import Foundation

extension WebDriverService {
    /// Adds a random delay to mimic human-like timing
    func addRandomDelay() async {
        let delay = Double.random(in: 0.5 ... 2.0)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Simulates mouse movement to an element (cosmetic, but helps with some anti-bot scripts)
    func simulateMouseMovement(to _: String) async {
        // Optionally, you could use WebDriver Actions API for real mouse movement
        // Here, we just add a random delay to simulate the time it would take
        let moveTime = Double.random(in: 0.2 ... 0.7)
        try? await Task.sleep(nanoseconds: UInt64(moveTime * 1_000_000_000))
    }

    /// Simulates human typing into an input element by sending keys one by one
    func simulateTyping(elementId: String, text: String) async {
        guard let sessionId else { return }
        let sessionIdString = String(describing: sessionId)
        let elementIdString = String(describing: elementId)
        for char in text {
            let endpoint = WebDriverService.shared
                .baseURL + "/session/" + sessionIdString + "/element/" + elementIdString + "/value"
            let body: [String: Any] = [
                "text": String(char),
                "value": [String(char)],
            ]
            guard let request = createRequest(url: endpoint, method: "POST", body: body) else { continue }
            _ = try? await urlSession.data(for: request)
            // Random delay between keystrokes
            let delay = Double.random(in: 0.05 ... 0.2)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }

    /// Simulates random scrolling on the page
    func simulateScrolling() async {
        guard let sessionId else { return }
        let sessionIdString = String(describing: sessionId)
        let endpoint = WebDriverService.shared.baseURL + "/session/" + sessionIdString + "/execute/sync"
        let script = """
            const scrollY = Math.floor(Math.random() * (window.innerHeight / 2));
            window.scrollBy({ top: scrollY, left: 0, behavior: 'smooth' });
        """
        let body: [String: Any] = [
            "script": script,
            "args": [],
        ]
        guard let request = createRequest(url: endpoint, method: "POST", body: body) else { return }
        _ = try? await urlSession.data(for: request)
        // Random delay after scrolling
        let delay = Double.random(in: 0.2 ... 0.7)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Simulates random mouse movement on the page
    func moveMouseRandomly() async {
        guard let sessionId else { return }
        let sessionIdString = String(describing: sessionId)
        let endpoint = WebDriverService.shared.baseURL + "/session/" + sessionIdString + "/actions"
        let pointerX = Int.random(in: 0 ... 800)
        let pointerY = Int.random(in: 0 ... 600)
        let actions: [String: Any] = [
            "actions": [[
                "type": "pointer",
                "id": "mouse1",
                "parameters": ["pointerType": "mouse"],
                "actions": [
                    ["type": "pointerMove", "duration": 300, "x": pointerX, "y": pointerY],
                ],
            ]],
        ]
        guard let request = createRequest(url: endpoint, method: "POST", body: actions) else { return }
        _ = try? await urlSession.data(for: request)
        // Random delay after mouse move
        let delay = Double.random(in: 0.1 ... 0.4)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Injects JavaScript to remove WebDriver signatures and set navigator properties
    func injectAntiDetectionScript(userAgent: String? = nil, language: String? = nil) async {
        guard let sessionId else { return }
        let sessionIdString = String(describing: sessionId)
        let endpoint = WebDriverService.shared.baseURL + "/session/" + sessionIdString + "/execute/sync"
        let userAgentString = userAgent ??
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
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
                // Spoof vendor and renderer
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
        let body: [String: Any] = [
            "script": script,
            "args": [],
        ]
        guard let request = createRequest(url: endpoint, method: "POST", body: body) else { return }
        _ = try? await urlSession.data(for: request)
    }
}
