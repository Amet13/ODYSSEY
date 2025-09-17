import SwiftUI

struct AboutView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var updateChecker = UpdateChecker.shared
  @State private var showingUpdateAlert = false
  @State private var showingUpToDateAlert = false

  private var appVersion: String {
    let baseVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    #if DEBUG
      return "\(baseVersion)-dev"
    #else
      return baseVersion
    #endif
  }

  private var buildNumber: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
  }

  var body: some View {
    ZStack {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }

      VStack(spacing: AppConstants.spacingNone) {
        VStack(spacing: AppConstants.spacingLarge) {
          VStack(spacing: AppConstants.spacingMedium) {
            Image(systemName: "sportscourt.fill")
              .symbolRenderingMode(.hierarchical)
              .font(.system(size: AppConstants.fontColossal))
              .foregroundColor(.odysseyPrimary)

            Text(NSLocalizedString("ODYSSEY", comment: "App name"))
              .font(.title3)
              .fontWeight(.semibold)

            Text(NSLocalizedString("about_app_subtitle", comment: "App subtitle"))
              .font(.subheadline)
              .foregroundColor(.odysseySecondaryText)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppConstants.spacingSmall) {
              if let githubURL = URL(string: "https://github.com/Amet13/ODYSSEY") {
                Link("Version \(appVersion)", destination: githubURL)
                  .font(.system(size: AppConstants.tertiaryFont))
                  .foregroundColor(.odysseyPrimary)
              } else {
                Text("Version \(appVersion)")
                  .font(.system(size: AppConstants.tertiaryFont))
                  .foregroundColor(.odysseySecondaryText)
              }

              // Check for Updates Icon
              Button(action: {
                Task {
                  await updateChecker.checkForUpdates()
                  if updateChecker.updateAvailable {
                    showingUpdateAlert = true
                  } else {
                    showingUpToDateAlert = true
                  }
                }
              }) {
                if updateChecker.isCheckingForUpdates {
                  ProgressView()
                    .scaleEffect(0.6)
                } else {
                  Image(systemName: "arrow.clockwise")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: AppConstants.fontMicro))
                }
              }
              .buttonStyle(.plain)
              .disabled(updateChecker.isCheckingForUpdates)
              .help("Check for updates")
            }
          }

          HeaderFooterDivider()

          VStack(alignment: .leading, spacing: AppConstants.contentSpacing) {
            VStack(alignment: .leading, spacing: AppConstants.spacingSmall) {
              FeatureRow(
                icon: "sportscourt",
                text: NSLocalizedString(
                  "about_feature_automated_booking",
                  comment: "Automated reservation booking",
                ),
              )
              FeatureRow(
                icon: "clock",
                text: NSLocalizedString(
                  "about_feature_scheduling", comment: "Smart scheduling system"),
              )
              FeatureRow(
                icon: "shield",
                text: NSLocalizedString(
                  "about_feature_webkit", comment: "Native WebKit automation"),
              )
              FeatureRow(
                icon: "envelope",
                text: NSLocalizedString(
                  "about_feature_email", comment: "Email verification support"),
              )
              FeatureRow(
                icon: "gear",
                text: NSLocalizedString(
                  "about_feature_multi_config",
                  comment: "Multiple configuration support",
                ),
              )

            }
          }
        }
        .padding(.horizontal, AppConstants.screenPadding)
        .padding(.vertical, AppConstants.sectionDividerSpacing)
        // Remove stroke to avoid any visible border halos on material
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.modalCornerRadius))
        .onTapGesture {
          // Prevent tap from propagating to background when clicking on content
        }
      }
    }
    .frame(width: AppConstants.windowAboutWidth, height: AppConstants.windowAboutHeight)
    .alert("Update Available", isPresented: $showingUpdateAlert) {
      Button("Download Update") {
        updateChecker.openReleasesPage()
      }
      Button("Later", role: .cancel) {}
    } message: {
      if let latestVersion = updateChecker.latestVersion {
        Text("A new version (\(latestVersion)) is available. Would you like to download it?")
      } else {
        Text("A new version is available. Would you like to download it?")
      }
    }
    .alert("Up to Date", isPresented: $showingUpToDateAlert) {
      Button("OK") {}
    } message: {
      Text("You're running the latest version of ODYSSEY!")
    }
    .onKeyPress(.escape) {
      dismiss()
      return .handled
    }
  }
}

struct FeatureRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: AppConstants.spacingMedium) {
      Image(systemName: icon)
        .symbolRenderingMode(.hierarchical)
        .foregroundColor(.odysseyPrimary)
        .frame(width: AppConstants.iconSmall)

      Text(text)
        .font(.system(size: AppConstants.tertiaryFont))
        .foregroundColor(.odysseyText)

      Spacer()
    }
  }
}
