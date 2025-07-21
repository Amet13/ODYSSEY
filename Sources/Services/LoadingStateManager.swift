import Combine
import Foundation
import os.log
import SwiftUI

/// Loading state for different operations
enum LoadingState {
    case idle
    case loading(String)
    case progress(Progress)
    case success(String)
    case error(String)
}

/// Progress tracking for long-running operations
struct Progress {
    let current: Int
    let total: Int
    let message: String

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var isComplete: Bool {
        return current >= total
    }
}

/**
 LoadingStateManager is responsible for tracking and publishing loading/progress state, error/success banners, and notifications for user feedback.
 */
@MainActor
class LoadingStateManager: ObservableObject {
    static let shared = LoadingStateManager()

    private let logger = Logger(subsystem: "com.odyssey.app", category: "LoadingStateManager")

    @Published var currentState: LoadingState = .idle
    @Published var isLoading: Bool = false
    @Published var progress: Progress?
    @Published var message: String = ""
    @Published var notification: BannerNotification? // New: for in-app banners

    private var cancellables = Set<AnyCancellable>()

    init() {
        logger.info("🔧 LoadingStateManager initialized.")
        setupBindings()
    }

    deinit {
        logger.info("🧹 LoadingStateManager deinitialized.")
    }

    private func setupBindings() {
        $currentState
            .map { state in
                switch state {
                case .idle:
                    return false
                case .loading, .progress, .success, .error:
                    return true
                }
            }
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)

        $currentState
            .map { state in
                switch state {
                case .idle:
                    return ""
                case let .loading(message):
                    return message
                case let .progress(progress):
                    return progress.message
                case let .success(message):
                    return message
                case let .error(message):
                    return message
                }
            }
            .assign(to: \.message, on: self)
            .store(in: &cancellables)

        $currentState
            .map { state in
                switch state {
                case let .progress(progress):
                    return progress
                default:
                    return nil
                }
            }
            .assign(to: \.progress, on: self)
            .store(in: &cancellables)
    }

    // MARK: - State Management

    /// Set loading state with message
    /// - Parameter message: Loading message
    func setLoading(_ message: String) {
        logger.info("⏳ Setting loading state: \(message).")
        currentState = .loading(message)
    }

    /// Set progress state
    /// - Parameter progress: Progress information
    func setProgress(_ progress: Progress) {
        logger.info("📊 Setting progress: \(progress.current)/\(progress.total) - \(progress.message).")
        currentState = .progress(progress)
    }

    /// Set success state
    /// - Parameter message: Success message
    func setSuccess(_ message: String) {
        logger.info("✅ Setting success state: \(message).")
        currentState = .success(message)

        // Auto-reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if case .success = self.currentState {
                self.reset()
            }
        }
    }

    /// Set error state
    /// - Parameter message: Error message
    func setError(_ message: String) {
        logger.error("❌ Setting error state: \(message).")
        currentState = .error(message)

        // Auto-reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if case .error = self.currentState {
                self.reset()
            }
        }
    }

    /**
     Resets the loading state and clears notifications.
     */
    func reset() {
        logger.info("🔄 Resetting loading state to idle.")
        currentState = .idle
    }

    // MARK: - Progress Tracking

    /// Start progress tracking for reservation automation
    /// - Parameter totalSteps: Total number of steps
    func startReservationProgress(totalSteps: Int) {
        let progress = Progress(current: 0, total: totalSteps, message: "Starting reservation...")
        setProgress(progress)
    }

    /// Update progress for reservation automation
    /// - Parameters:
    ///   - currentStep: Current step number
    ///   - message: Progress message
    func updateReservationProgress(currentStep: Int, message: String) {
        guard case let .progress(progress) = currentState else { return }

        let newProgress = Progress(current: currentStep, total: progress.total, message: message)
        setProgress(newProgress)
    }

    /// Complete progress tracking
    /// - Parameter message: Completion message
    func completeProgress(_ message: String) {
        guard case let .progress(progress) = currentState else { return }

        let finalProgress = Progress(current: progress.total, total: progress.total, message: message)
        setProgress(finalProgress)

        // Auto-transition to success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setSuccess(message)
        }
    }

    // MARK: - Notification Banner Support

    struct BannerNotification: Identifiable {
        enum BannerType { case success, error, info }
        let id = UUID()
        let type: BannerType
        let message: String
    }

    /**
     Shows a success banner notification with the given message.
     - Parameter message: The message to display.
     */
    func showSuccessBanner(_ message: String) {
        notification = BannerNotification(type: .success, message: message)
        logger.info("✅ Success banner: \(message)")
    }

    /**
     Shows an error banner notification with the given message.
     - Parameter message: The message to display.
     */
    func showErrorBanner(_ message: String) {
        notification = BannerNotification(type: .error, message: message)
        logger.error("❌ Error banner: \(message)")
    }

    /**
     Shows an info banner notification with the given message.
     - Parameter message: The message to display.
     */
    func showInfoBanner(_ message: String) {
        notification = BannerNotification(type: .info, message: message)
        logger.info("ℹ️ Info banner: \(message)")
    }

    // MARK: - Convenience Methods

    /// Show loading for async operation
    /// - Parameters:
    ///   - message: Loading message
    ///   - operation: Async operation to perform
    func withLoading<T: Sendable>(_ message: String, operation: @escaping () async throws -> T) async throws -> T {
        setLoading(message)

        do {
            let result = try await operation()
            setSuccess("Operation completed successfully.")
            return result
        } catch {
            setError("Operation failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Show progress for multi-step operation
    /// - Parameters:
    ///   - totalSteps: Total number of steps
    ///   - operation: Operation with progress callback
    func withProgress<T: Sendable>(
        totalSteps: Int,
        operation: @escaping (@escaping @Sendable (Int, String) -> Void) async throws -> T
    ) async throws -> T {
        startReservationProgress(totalSteps: totalSteps)

        do {
            let result = try await operation { [weak self] currentStep, message in
                Task { @MainActor in
                    self?.updateReservationProgress(currentStep: currentStep, message: message)
                }
            }

            self.completeProgress("Operation completed successfully.")

            return result
        } catch {
            self.setError("Operation failed: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Apply loading state overlay
    /// - Parameter loadingState: Current loading state
    /// - Returns: View with loading overlay
    func loadingOverlay(_ loadingState: LoadingState) -> some View {
        self.overlay(
            Group {
                switch loadingState {
                case .idle:
                    EmptyView()
                case let .loading(message):
                    LoadingOverlayView(message: message)
                case let .progress(progress):
                    ProgressOverlayView(progress: progress)
                case let .success(message):
                    SuccessOverlayView(message: message)
                case let .error(message):
                    ErrorOverlayView(message: message)
                }
            },
            )
    }
}

// MARK: - Loading Overlay Views

struct LoadingOverlayView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text(message)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 8),
            )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}

struct ProgressOverlayView: View {
    let progress: Progress

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress.percentage)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 200)

            Text(progress.message)
                .font(.headline)
                .foregroundColor(.primary)

            Text("\(progress.current) of \(progress.total)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 8),
            )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}

struct SuccessOverlayView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text(message)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 8),
            )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}

struct ErrorOverlayView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text(message)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 8),
            )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}
