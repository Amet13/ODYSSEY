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
            Image(systemName: AppConstants.SFSymbols.app)
              .symbolRenderingMode(.hierarchical)
              .font(.system(size: AppConstants.fontMassive))
              .foregroundColor(.odysseyPrimary)

            Text(NSLocalizedString("ODYSSEY", comment: "App name"))
              .font(.system(size: AppConstants.fontTitle3))
              .fontWeight(.semibold)

            Text(NSLocalizedString("about_app_subtitle", comment: "App subtitle"))
              .font(.system(size: AppConstants.fontSubheadline))
              .foregroundColor(.odysseySecondaryText)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppConstants.spacingSmall) {
              if let githubURL = URL(string: AppConstants.githubURL) {
                Link("Version \(appVersion)", destination: githubURL)
                  .font(.system(size: AppConstants.fontCaption))
                  .foregroundColor(.odysseyPrimary)
              } else {
                Text("Version \(appVersion)")
                  .font(.system(size: AppConstants.fontCaption))
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
                HStack(spacing: AppConstants.spacingTiny) {
                  if updateChecker.isCheckingForUpdates {
                    ProgressView()
                      .scaleEffect(AppConstants.scaleEffectSmall)
                  } else {
                    Image(systemName: AppConstants.SFSymbols.refresh)
                      .symbolRenderingMode(.hierarchical)
                  }
                }
              }
              .buttonStyle(.plain)
              .controlSize(.mini)
              .disabled(updateChecker.isCheckingForUpdates)
              .help("Check for updates.")
            }
          }

          HeaderFooterDivider()

          VStack(alignment: .leading, spacing: AppConstants.contentSpacing) {
            VStack(alignment: .leading, spacing: AppConstants.spacingSmall) {
              FeatureRow(
                icon: AppConstants.SFSymbols.appOutline,
                text: NSLocalizedString(
                  "about_feature_automated_booking",
                  comment: "Automated reservation booking",
                ),
              )
              FeatureRow(
                icon: AppConstants.SFSymbols.clock,
                text: NSLocalizedString(
                  "about_feature_scheduling", comment: "Smart scheduling system"),
              )
              FeatureRow(
                icon: AppConstants.SFSymbols.shield,
                text: NSLocalizedString(
                  "about_feature_webkit", comment: "Native WebKit automation"),
              )
              FeatureRow(
                icon: AppConstants.SFSymbols.envelopeBadge,
                text: NSLocalizedString(
                  "about_feature_email", comment: "Email verification support"),
              )
              FeatureRow(
                icon: AppConstants.SFSymbols.settings,
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
        .font(.system(size: AppConstants.fontCaption))
        .foregroundColor(.odysseyText)

      Spacer()
    }
  }
}
