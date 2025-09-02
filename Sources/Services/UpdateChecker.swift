import AppKit
import Foundation
import os.log

/// Service for checking for app updates via GitHub API
@MainActor
class UpdateChecker: ObservableObject {
  static let shared = UpdateChecker()

  private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "UpdateChecker")

  @Published var isCheckingForUpdates = false
  @Published var updateAvailable = false
  @Published var latestVersion: String?
  @Published var errorMessage: String?

  private let githubAPIURL = "https://api.github.com/repos/Amet13/ODYSSEY/releases/latest"
  private let releasesPageURL = "https://github.com/Amet13/ODYSSEY/releases"

  private init() {}

  /// Checks for updates by fetching the latest release from GitHub
  func checkForUpdates() async {
    await MainActor.run {
      isCheckingForUpdates = true
      errorMessage = nil
    }

    do {
      let latestRelease = try await fetchLatestRelease()
      let currentVersion = getCurrentVersion()

      await MainActor.run {
        latestVersion = latestRelease.tagName
        updateAvailable = isNewerVersionAvailable(
          current: currentVersion, latest: latestRelease.tagName)
        isCheckingForUpdates = false

        if updateAvailable {
          logger.info("🆕 Update available: \(latestRelease.tagName) (current: \(currentVersion))")
        } else {
          logger.info("✅ App is up to date: \(currentVersion)")
        }
      }
    } catch {
      await MainActor.run {
        errorMessage = "Failed to check for updates: \(error.localizedDescription)"
        isCheckingForUpdates = false
        logger.error("❌ Update check failed: \(error.localizedDescription)")
      }
    }
  }

  /// Opens the GitHub releases page in the default browser
  func openReleasesPage() {
    guard let url = URL(string: releasesPageURL) else {
      logger.error("❌ Invalid releases page URL")
      return
    }

    NSWorkspace.shared.open(url)
    logger.info("🌐 Opened releases page: \(self.releasesPageURL)")
  }

  // MARK: - Private Methods

  private func fetchLatestRelease() async throws -> GitHubRelease {
    guard let url = URL(string: githubAPIURL) else {
      throw UpdateError.invalidURL
    }

    var request = URLRequest(url: url)
    request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    request.setValue("ODYSSEY/\(AppConstants.appVersion)", forHTTPHeaderField: "User-Agent")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw UpdateError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      throw UpdateError.httpError(httpResponse.statusCode)
    }

    let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
    return release
  }

  private func getCurrentVersion() -> String {
    return AppConstants.appVersion
  }

  private func isNewerVersionAvailable(current: String, latest: String) -> Bool {
    // Remove 'v' prefix if present
    let cleanCurrent = current.replacingOccurrences(of: "^v", with: "", options: .regularExpression)
    let cleanLatest = latest.replacingOccurrences(of: "^v", with: "", options: .regularExpression)

    return compareVersions(current: cleanCurrent, latest: cleanLatest) < 0
  }

  private func compareVersions(current: String, latest: String) -> Int {
    let currentComponents = current.components(separatedBy: ".").compactMap { Int($0) }
    let latestComponents = latest.components(separatedBy: ".").compactMap { Int($0) }

    let maxLength = max(currentComponents.count, latestComponents.count)

    for i in 0..<maxLength {
      let currentValue = i < currentComponents.count ? currentComponents[i] : 0
      let latestValue = i < latestComponents.count ? latestComponents[i] : 0

      if currentValue < latestValue {
        return -1  // Current is older
      } else if currentValue > latestValue {
        return 1  // Current is newer
      }
    }

    return 0  // Versions are equal
  }
}

// MARK: - Data Models

struct GitHubRelease: Codable {
  let tagName: String
  let name: String
  let body: String
  let publishedAt: String
  let htmlUrl: String

  enum CodingKeys: String, CodingKey {
    case tagName = "tag_name"
    case name
    case body
    case publishedAt = "published_at"
    case htmlUrl = "html_url"
  }
}

// MARK: - Error Types

enum UpdateError: LocalizedError {
  case invalidURL
  case invalidResponse
  case httpError(Int)
  case decodingError

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid GitHub API URL"
    case .invalidResponse:
      return "Invalid response from GitHub API"
    case .httpError(let code):
      return "HTTP error: \(code)"
    case .decodingError:
      return "Failed to decode release information"
    }
  }
}
