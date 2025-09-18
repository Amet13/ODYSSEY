import AppKit
import Foundation
import ImageIO
import os

/// FileManager extensions for ODYSSEY app directories
extension FileManager {

  /// Gets the ODYSSEY app support directory for storing screenshots and other data
  /// - Returns: The path to the ODYSSEY app support directory
  public static func odysseyAppSupportDirectory() -> String {
    let fileManager = FileManager.default
    let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first!
    let odysseyDirectory = appSupportURL.appendingPathComponent("ODYSSEY")

    Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
      .info("📁 App support directory: \(appSupportURL.path).")
    Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
      .info("📁 ODYSSEY directory: \(odysseyDirectory.path).")

    // Create directory if it doesn't exist
    if !fileManager.fileExists(atPath: odysseyDirectory.path) {
      do {
        try fileManager.createDirectory(
          at: odysseyDirectory, withIntermediateDirectories: true, attributes: nil)
        Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
          .info("📁 Created ODYSSEY app support directory: \(odysseyDirectory.path).")
      } catch {
        Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
          .error("📁 Failed to create ODYSSEY app support directory: \(error.localizedDescription).")
      }
    } else {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .info("📁 ODYSSEY app support directory already exists: \(odysseyDirectory.path).")
    }

    return odysseyDirectory.path
  }

  /// Gets the ODYSSEY screenshots directory
  /// - Returns: The path to the screenshots directory
  public static func odysseyScreenshotsDirectory() -> String {
    let screenshotsDirectory = odysseyAppSupportDirectory().appending("/Screenshots")
    let fileManager = FileManager.default

    Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
      .info("📸 Screenshots directory: \(screenshotsDirectory).")

    // Create screenshots directory if it doesn't exist
    if !fileManager.fileExists(atPath: screenshotsDirectory) {
      do {
        try fileManager.createDirectory(
          atPath: screenshotsDirectory, withIntermediateDirectories: true, attributes: nil)
        Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
          .info("📁 Created screenshots directory: \(screenshotsDirectory).")
      } catch {
        Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
          .error("📁 Failed to create screenshots directory: \(error.localizedDescription).")
      }
    } else {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .info("📁 Screenshots directory already exists: \(screenshotsDirectory).")
    }

    // Verify directory is writable
    if fileManager.isWritableFile(atPath: screenshotsDirectory) {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .info("📁 Screenshots directory is writable: \(screenshotsDirectory).")
    } else {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .error("📁 Screenshots directory is NOT writable: \(screenshotsDirectory).")
    }

    return screenshotsDirectory
  }

  /// Gets the ODYSSEY logs directory
  /// - Returns: The path to the logs directory
  public static func odysseyLogsDirectory() -> String {
    let logsDirectory = odysseyAppSupportDirectory().appending("/Logs")
    let fileManager = FileManager.default

    Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
      .info("📝 Logs directory: \(logsDirectory).")

    // Create logs directory if it doesn't exist
    if !fileManager.fileExists(atPath: logsDirectory) {
      do {
        try fileManager.createDirectory(
          atPath: logsDirectory, withIntermediateDirectories: true, attributes: nil)
        Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
          .info("📁 Created logs directory: \(logsDirectory).")
      } catch {
        Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
          .error("📁 Failed to create logs directory: \(error.localizedDescription).")
      }
    } else {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .info("📁 Logs directory already exists: \(logsDirectory).")
    }

    return logsDirectory
  }

  /// Finds the most recent screenshot for a specific configuration
  /// - Parameter configName: The name of the configuration
  /// - Returns: The path to the most recent screenshot, or nil if none found
  static func findMostRecentScreenshot(for configName: String) -> String? {
    let screenshotsDirectory = odysseyScreenshotsDirectory()
    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: screenshotsDirectory) else {
      return nil
    }

    do {
      let files = try fileManager.contentsOfDirectory(atPath: screenshotsDirectory)
      let screenshotFiles = files.filter {
        $0.hasSuffix(".png")
          && $0.contains("failure_\(configName.replacingOccurrences(of: " ", with: "_"))")
      }

      if screenshotFiles.isEmpty {
        return nil
      }

      // Sort by modification date (most recent first)
      let sortedFiles = screenshotFiles.sorted { file1, file2 in
        let path1 = "\(screenshotsDirectory)/\(file1)"
        let path2 = "\(screenshotsDirectory)/\(file2)"

        let date1 =
          (try? fileManager.attributesOfItem(atPath: path1)[.modificationDate] as? Date)
          ?? Date.distantPast
        let date2 =
          (try? fileManager.attributesOfItem(atPath: path2)[.modificationDate] as? Date)
          ?? Date.distantPast

        return date1 > date2
      }

      return "\(screenshotsDirectory)/\(sortedFiles.first!)"
    } catch {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .error("📸 Failed to find screenshot for \(configName): \(error.localizedDescription).")
      return nil
    }
  }

  /// Opens a screenshot file using the default system application
  /// - Parameter screenshotPath: The path to the screenshot file
  /// - Returns: True if the file was opened successfully
  static func openScreenshot(_ screenshotPath: String) -> Bool {
    let url = URL(fileURLWithPath: screenshotPath)

    guard FileManager.default.fileExists(atPath: screenshotPath) else {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .error("📸 Screenshot file does not exist: \(screenshotPath).")
      return false
    }

    let success = NSWorkspace.shared.open(url)
    if success {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .info("📸 Opened screenshot: \(screenshotPath).")
    } else {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .error("📸 Failed to open screenshot: \(screenshotPath).")
    }
    return success
  }

  /// Cleans up old screenshots to manage disk space
  /// - Parameter maxAge: Maximum age in days before screenshots are deleted (default: 30 days)
  /// - Returns: Number of screenshots deleted
  static func cleanupOldScreenshots(maxAge: Int = AppConstants.defaultScreenshotRetentionDays)
    -> Int
  {
    let screenshotsDirectory = odysseyScreenshotsDirectory()
    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: screenshotsDirectory) else {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .info("📸 No screenshots directory found for cleanup.")
      return 0
    }

    do {
      let files = try fileManager.contentsOfDirectory(atPath: screenshotsDirectory)
      let screenshotFiles = files.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") }

      if screenshotFiles.isEmpty {
        Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
          .info("📸 No screenshot files found for cleanup.")
        return 0
      }

      let cutoffDate = Date().addingTimeInterval(-TimeInterval(maxAge * 24 * 60 * 60))
      var deletedCount = 0

      for filename in screenshotFiles {
        let filePath = "\(screenshotsDirectory)/\(filename)"

        do {
          let attributes = try fileManager.attributesOfItem(atPath: filePath)
          if let modificationDate = attributes[.modificationDate] as? Date {
            if modificationDate < cutoffDate {
              try fileManager.removeItem(atPath: filePath)
              deletedCount += 1
              Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
                .info("🗑️ Deleted old screenshot: \(filename)")
            }
          }
        } catch {
          Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
            .error("❌ Error processing screenshot \(filename): \(error.localizedDescription)")
        }
      }

      if deletedCount > 0 {
        Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
          .info("🧹 Cleanup completed: \(deletedCount) old screenshots deleted.")
      } else {
        Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
          .info("🧹 Cleanup completed: No old screenshots found.")
      }

      return deletedCount
    } catch {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .error("❌ Error during screenshot cleanup: \(error.localizedDescription)")
      return 0
    }
  }

  // MARK: - Image Compression Utilities

  /// Compresses an NSImage to JPEG format with specified quality
  /// - Parameters:
  ///   - image: The image to compress
  ///   - quality: JPEG quality from 0.0 (lowest) to 1.0 (highest), default 0.7
  ///   - maxWidth: Maximum width in pixels, maintains aspect ratio if specified
  /// - Returns: Compressed JPEG data
  static func compressImage(_ image: NSImage, quality: Float = 0.7, maxWidth: CGFloat? = nil)
    -> Data?
  {
    guard let tiffData = image.tiffRepresentation else {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .error("📸 Failed to get bitmap representation for image compression.")
      return nil
    }

    var finalImage = image

    // Resize image if maxWidth is specified
    if let maxWidth = maxWidth, image.size.width > maxWidth {
      let scaleFactor = maxWidth / image.size.width
      let newSize = NSSize(width: maxWidth, height: image.size.height * scaleFactor)

      let resizedImage = NSImage(size: newSize)
      resizedImage.lockFocus()
      image.draw(in: NSRect(origin: .zero, size: newSize))
      resizedImage.unlockFocus()

      finalImage = resizedImage
    }

    // Convert to JPEG with specified quality
    guard let jpegData = finalImage.jpegRepresentation(quality: quality) else {
      Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
        .error("📸 Failed to compress image to JPEG format.")
      return nil
    }

    let originalSize = tiffData.count
    let compressedSize = jpegData.count

    Logger(subsystem: AppConstants.loggingSubsystem, category: "FileManagerExtensions")
      .info(
        "📸 Image compressed: \(originalSize) bytes → \(compressedSize) bytes (ratio: \(String(format: "%.1f", Double(compressedSize) / Double(originalSize))))"
      )

    return jpegData
  }

  /// Gets the file size of a file in human-readable format
  /// - Parameter filePath: Path to the file
  /// - Returns: Human-readable file size string
  static func getFileSizeString(_ filePath: String) -> String {
    let fileManager = FileManager.default

    do {
      let attributes = try fileManager.attributesOfItem(atPath: filePath)
      let fileSize = attributes[.size] as? Int64 ?? 0

      let formatter = ByteCountFormatter()
      formatter.allowedUnits = [.useKB, .useMB]
      formatter.countStyle = .file

      return formatter.string(fromByteCount: fileSize)
    } catch {
      return "Unknown size"
    }
  }
}
