import Foundation
import os.log

@MainActor
public final class ReservationErrorHandler: @unchecked Sendable {
  public static let shared = ReservationErrorHandler()
  private let logger = Logger(
    subsystem: AppConstants.loggingSubsystem, category: "ReservationErrorHandler")
  private let statusManager = ReservationStatusManager.shared
  private let webKitService = WebKitService.shared

  public func handleReservationError(
    _ error: Error,
    config: ReservationConfig,
    runType: ReservationRunType,
  ) async {
    logger.error("❌ Reservation error: \(error.localizedDescription).")

    if let webKitService = try? await getWebKitServiceIfAvailable() {
      if let pageSource = try? await webKitService.getPageSource() {
        logger.error("📄 DOM Snapshot (first 1000 chars): \(pageSource.prefix(1_000)).")
      } else {
        logger.error("⚠️ Failed to capture DOM snapshot for error context.")
      }

      // Capture current URL for context
      if let currentURL = webKitService.currentURL {
        logger.error("🌐 Current URL at error: \(currentURL).")
      }
    }

    // Provide user-friendly error message
    let userFriendlyMessage = getUserFriendlyErrorMessage(error)

    await MainActor.run {
      if runType == .manual { statusManager.isRunning = false }
      statusManager.lastRunStatus = ReservationRunStatus.failed(userFriendlyMessage)
      statusManager.setLastRunInfo(
        for: config.id,
        status: .failed(userFriendlyMessage),
        date: Date(),
        runType: runType,
      )
      statusManager.lastRunDate = Date()
      statusManager.currentTask = "Reservation failed: \(userFriendlyMessage)"

      // Show user-facing error banner
      logger.error("❌ Reservation failed: \(userFriendlyMessage).")
    }

    logger.error("❌ Reservation failed for \(config.name): \(error.localizedDescription).")

    // Take screenshot before disconnecting if WebKit service is available
    if webKitService.isConnected, webKitService.webView != nil {
      logger.info("📸 Taking failure screenshot for \(config.name)...")

      // Set screenshot directory on the WebKit service only if not already set
      await MainActor.run {
        if webKitService.currentScreenshotDirectory == nil {
          webKitService.setScreenshotDirectory(FileManager.odysseyScreenshotsDirectory())
        }
      }

      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
      let timestamp = dateFormatter.string(from: Date())
      let filename =
        "\(config.name.replacingOccurrences(of: " ", with: "_"))_\(timestamp).jpg"
      if let screenshotPath = await webKitService.takeScreenshot(
        filename: filename, quality: AppConstants.defaultScreenshotQuality,
        maxWidth: AppConstants.defaultScreenshotMaxWidth,
        format: AppConstants.defaultScreenshotFormat)
      {
        logger.info("📸 Failure screenshot saved: \(screenshotPath).")

        // Update the last run info with the screenshot path
        await MainActor.run {
          statusManager.setLastRunInfo(
            for: config.id,
            status: .failed(userFriendlyMessage),
            date: Date(),
            runType: runType,
            screenshotPath: screenshotPath
          )
        }
      } else {
        logger.error("❌ Failed to capture failure screenshot for \(config.name).")
      }
    } else {
      logger.warning("⚠️ WebKit service not available for screenshot capture.")
    }

    logger.info("🧹 Cleaning up WebKit session after error.")

    let shouldClose = UserSettingsManager.shared.userSettings.autoCloseDebugWindowOnFailure
    if shouldClose {
      logger.info("🪟 Auto-close on failure enabled - closing window.")
      await webKitService.disconnect(closeWindow: true)
    } else {
      logger.info("🪟 Auto-close on failure disabled - keeping window open to show error.")
      await webKitService.disconnect(closeWindow: false)
    }
  }

  public func handleError(_ error: String, configId: UUID?, runType: ReservationRunType = .manual)
    async
  {
    await MainActor.run {
      if runType == .manual { statusManager.isRunning = false }
      statusManager.lastRunStatus = ReservationRunStatus.failed(error)
      statusManager.currentTask = "Error: \(error)"
      statusManager.lastRunDate = Date()
      if let configId {
        statusManager.setLastRunInfo(
          for: configId, status: .failed(error), date: Date(), runType: runType)
      }
    }
    logger.error("❌ Reservation error: \(error).")
  }

  public func handleWebKitCrash() async {
    logger.error("💥 WebKit crash detected, attempting recovery.")
    await webKitService.reset()
    logger.info("✅ WebKit service reset successful.")
  }

  /// Helper to get WebKitService if available and connected
  private func getWebKitServiceIfAvailable() async throws -> WebKitService? {
    let service = WebKitService.shared
    if service.isConnected, service.webView != nil {
      return service
    }
    return nil
  }

  /// Converts technical error messages to user-friendly messages
  /// - Parameter error: The error to convert
  /// - Returns: User-friendly error message
  private func getUserFriendlyErrorMessage(_ error: Error) -> String {
    if let reservationError = error as? ReservationError {
      switch reservationError {
      case let .network(message):
        return
          "Network connection issue: \(message). Please check your internet connection and try again."
      case let .facilityNotFound(message):
        return "Facility not found: \(message). Please verify the facility URL is correct."
      case let .slotUnavailable(message):
        return "Time slot unavailable: \(message). Please try a different time or day."
      case let .automationFailed(message):
        return
          "Automation failed: \(message). Please try again or contact support if the issue persists."
      case .pageLoadTimeout:
        return "Page took too long to load. Please check your internet connection and try again."
      case .groupSizePageLoadTimeout:
        return "Group size page failed to load. Please try again."
      case .numberOfPeopleFieldNotFound:
        return "Could not find the number of people field. The website may have changed."
      case .confirmButtonNotFound:
        return "Could not find the confirm button. The website may have changed."
      case .timeSlotSelectionFailed:
        return
          "Failed to select time slot. The slot may be unavailable or the website may have changed."
      case .contactInfoPageLoadTimeout:
        return "Contact information page failed to load. Please try again."
      case .contactInfoFieldNotFound:
        return "Could not find contact information fields. Please check your settings."
      case .contactInfoConfirmButtonNotFound:
        return "Could not find the confirm button on contact page. The website may have changed."
      case .emailVerificationFailed:
        return "Email verification failed. Please check your email settings and try again."
      case .sportButtonNotFound:
        return "Could not find the sport selection button. The website may have changed."
      case .webKitTimeout:
        return "Operation timed out. Please try again."
      case let .unknown(message):
        return "An unexpected error occurred: \(message). Please try again."
      }
    }

    // Handle other error types
    let errorMessage = error.localizedDescription
    if errorMessage.contains("network") || errorMessage.contains("connection") {
      return "Network connection issue. Please check your internet connection and try again."
    } else if errorMessage.contains("timeout") {
      return "Operation timed out. Please try again."
    } else if errorMessage.contains("not found") || errorMessage.contains("404") {
      return "The requested page was not found. Please check the facility URL."
    } else {
      return "An error occurred: \(errorMessage). Please try again."
    }
  }
}
