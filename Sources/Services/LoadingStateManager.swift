import Foundation
import os.log
import SwiftUI

/// Centralized loading state management for the application
/// Handles all loading states, progress indicators, and user feedback
@MainActor
public final class LoadingStateManager: ObservableObject {
    public static let shared = LoadingStateManager()
    private let logger = Logger(subsystem: "com.odyssey.app", category: "LoadingStateManager")

    // Loading state properties
    @Published public var isLoading = false
    @Published public var loadingMessage = ""
    @Published public var progress: Double = 0.0
    @Published public var showProgress = false
    @Published public var currentTask = ""
    @Published public var errorMessage: String?
    @Published public var showError = false

    // Task-specific loading states
    @Published public var isReservationRunning = false
    @Published public var isEmailTesting = false
    @Published public var isSportsFetching = false
    @Published public var isConfigurationSaving = false

    // Progress tracking
    private var totalSteps: Int = 0
    private var currentStep: Int = 0

    private init() {
        logger.info("🔧 LoadingStateManager initialized")
    }

    deinit {
        logger.info("🧹 LoadingStateManager deinitialized")
    }

    // MARK: - General Loading States

    /// Shows a loading state with a message
    /// - Parameter message: The loading message to display
    public func showLoading(message: String) {
        isLoading = true
        loadingMessage = message
        showProgress = false
        errorMessage = nil
        showError = false
        logger.info("🔄 Loading started: \(message)")
    }

    /// Hides the loading state
    public func hideLoading() {
        isLoading = false
        loadingMessage = ""
        showProgress = false
        progress = 0.0
        currentTask = ""
        totalSteps = 0
        currentStep = 0
        logger.info("✅ Loading completed")
    }

    /// Shows an error message
    /// - Parameter message: The error message to display
    public func showError(_ message: String) {
        errorMessage = message
        showError = true
        isLoading = false
        logger.error("❌ Error displayed: \(message)")
    }

    /// Hides the error message
    public func hideError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Progress Tracking

    /// Starts progress tracking with a total number of steps
    /// - Parameters:
    ///   - totalSteps: The total number of steps
    ///   - message: The initial message
    public func startProgress(totalSteps: Int, message: String) {
        self.totalSteps = totalSteps
        self.currentStep = 0
        self.progress = 0.0
        self.loadingMessage = message
        self.showProgress = true
        self.isLoading = true
        logger.info("📊 Progress started: \(message) (\(totalSteps) steps)")
    }

    /// Updates progress to the next step
    /// - Parameter message: The message for the current step
    public func nextStep(_ message: String) {
        currentStep += 1
        progress = Double(currentStep) / Double(totalSteps)
        currentTask = message
        logger.info("📊 Progress step \(self.currentStep)/\(self.totalSteps): \(message)")
    }

    /// Updates progress with a specific value
    /// - Parameters:
    ///   - progress: The progress value (0.0 to 1.0)
    ///   - message: The current message
    public func updateProgress(_ progress: Double, message: String) {
        self.progress = max(0.0, min(1.0, progress))
        self.currentTask = message
        logger.debug("📊 Progress updated: \(String(format: "%.1f", progress * 100))% - \(message)")
    }

    // MARK: - Task-Specific Loading States

    /// Shows reservation automation loading
    /// - Parameter configName: The name of the configuration being run
    public func showReservationLoading(configName: String) {
        isReservationRunning = true
        showLoading(message: "Running reservation for \(configName)...")
        logger.info("🏃 Reservation loading started for: \(configName)")
    }

    /// Hides reservation automation loading
    public func hideReservationLoading() {
        isReservationRunning = false
        hideLoading()
        logger.info("✅ Reservation loading completed")
    }

    /// Shows email testing loading
    public func showEmailTesting() {
        isEmailTesting = true
        showLoading(message: "Testing email connection...")
        logger.info("📧 Email testing started")
    }

    /// Hides email testing loading
    public func hideEmailTesting() {
        isEmailTesting = false
        hideLoading()
        logger.info("✅ Email testing completed")
    }

    /// Shows sports fetching loading
    public func showSportsFetching() {
        isSportsFetching = true
        showLoading(message: "Fetching available sports...")
        logger.info("🏀 Sports fetching started")
    }

    /// Hides sports fetching loading
    public func hideSportsFetching() {
        isSportsFetching = false
        hideLoading()
        logger.info("✅ Sports fetching completed")
    }

    /// Shows configuration saving loading
    public func showConfigurationSaving() {
        isConfigurationSaving = true
        showLoading(message: "Saving configuration...")
        logger.info("💾 Configuration saving started")
    }

    /// Hides configuration saving loading
    public func hideConfigurationSaving() {
        isConfigurationSaving = false
        hideLoading()
        logger.info("✅ Configuration saving completed")
    }

    // MARK: - Utility Methods

    /// Checks if any loading state is active
    public var isAnyLoading: Bool {
        return isLoading || isReservationRunning || isEmailTesting || isSportsFetching || isConfigurationSaving
    }

    /// Gets the current loading message
    public var currentLoadingMessage: String {
        if !loadingMessage.isEmpty {
            return loadingMessage
        }

        if isReservationRunning {
            return "Running reservation..."
        } else if isEmailTesting {
            return "Testing email..."
        } else if isSportsFetching {
            return "Fetching sports..."
        } else if isConfigurationSaving {
            return "Saving configuration..."
        }

        return "Loading..."
    }

    /// Resets all loading states
    public func resetAllStates() {
        isLoading = false
        loadingMessage = ""
        progress = 0.0
        showProgress = false
        currentTask = ""
        errorMessage = nil
        showError = false
        isReservationRunning = false
        isEmailTesting = false
        isSportsFetching = false
        isConfigurationSaving = false
        totalSteps = 0
        currentStep = 0
        logger.info("🔄 All loading states reset")
    }
}

// MARK: - Loading State Views

/// A loading overlay view
public struct LoadingOverlay: View {
    let message: String
    let showProgress: Bool
    let progress: Double

    public init(message: String, showProgress: Bool = false, progress: Double = 0.0) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: AppConstants.spacingLarge) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))

                Text(message)
                    .font(.system(size: AppConstants.fontLarge))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if showProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                }
            }
            .padding(AppConstants.paddingLarge)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadiusLarge)
                    .fill(Color(.windowBackgroundColor))
                    .shadow(radius: AppConstants.shadowRadiusLarge),
                )
        }
    }
}

/// A loading button that shows a spinner when loading
public struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    public init(title: String, isLoading: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppConstants.spacingSmall) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }

                Text(title)
                    .font(.system(size: AppConstants.fontMedium))
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .disabled(isLoading)
    }
}
