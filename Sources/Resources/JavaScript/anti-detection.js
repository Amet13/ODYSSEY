// ODYSSEY Anti-Detection Script
// Prevents detection of automation tools

function injectAntiDetectionScript(userAgent, language, _instanceId) {
  const selectedUserAgent =
    userAgent ||
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
  const lang = language?.split(',')[0] || 'en-US';
  const langs = language?.split(',') || ['en-US', 'en'];

  // Screen properties
  const selectedScreen = {
    width: 1440,
    height: 900,
    pixelRatio: 2,
  };

  return `
        (function() {
            try {
                // Remove webdriver property
                Object.defineProperty(navigator, 'webdriver', {
                    get: () => undefined,
                    configurable: true
                });

                // Fake plugins and languages
                Object.defineProperty(navigator, 'plugins', {
                    get: () => {
                        const plugins = [];
                        const mockPlugins = [
                            { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer', description: 'Portable Document Format' },
                            { name: 'Chrome PDF Viewer', filename: 'mhjfbmdgcfjbbpaeojofohoefgiehjai', description: '' },
                            { name: 'Native Client', filename: 'internal-nacl-plugin', description: '' }
                        ];
                        mockPlugins.forEach((plugin, index) => {
                            plugins[index] = {
                                name: plugin.name,
                                filename: plugin.filename,
                                description: plugin.description,
                                length: 1
                            };
                        });
                        plugins.length = mockPlugins.length;
                        return plugins;
                    },
                    configurable: true
                });

                Object.defineProperty(navigator, 'languages', {
                    get: () => ${JSON.stringify(langs)},
                    configurable: true
                });

                Object.defineProperty(navigator, 'language', {
                    get: () => '${lang}',
                    configurable: true
                });

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
                    get: () => '${selectedUserAgent}',
                    configurable: true
                });

                // Hardware properties
                Object.defineProperty(navigator, 'hardwareConcurrency', {
                    get: () => 8,
                    configurable: true
                });

                Object.defineProperty(navigator, 'maxTouchPoints', {
                    get: () => 0,
                    configurable: true
                });

                Object.defineProperty(navigator, 'vendor', {
                    get: () => 'Google Inc.',
                    configurable: true
                });

                // Screen properties
                Object.defineProperty(screen, 'width', {
                    get: () => ${selectedScreen.width},
                    configurable: true
                });

                Object.defineProperty(screen, 'height', {
                    get: () => ${selectedScreen.height},
                    configurable: true
                });

                Object.defineProperty(screen, 'availWidth', {
                    get: () => ${selectedScreen.width},
                    configurable: true
                });

                Object.defineProperty(screen, 'availHeight', {
                    get: () => ${selectedScreen.height},
                    configurable: true
                });

                Object.defineProperty(screen, 'colorDepth', {
                    get: () => 24,
                    configurable: true
                });

                Object.defineProperty(screen, 'pixelDepth', {
                    get: () => 24,
                    configurable: true
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

                // Remove automation indicators
                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Array) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array;
                }
                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Promise) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise;
                }
                if (window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol) {
                    delete window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol;
                }

                // Add mouse movement tracking
                if (!window.odysseyMouseMovements) {
                    window.odysseyMouseMovements = [];
                }

                // Anti-detection measures applied
            } catch (error) {
                console.error('[ODYSSEY] Error in anti-detection script:', error);
            }
        })();
    `;
}

// Export for use in Swift
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { injectAntiDetectionScript };
}
