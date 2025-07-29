import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var body: some View {
        ZStack {
            Color.odysseyBackground.ignoresSafeArea()
            Color.white
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: AppConstants.spacingNone) {
                VStack(spacing: AppConstants.spacingLarge) {
                    VStack(spacing: AppConstants.spacingMedium) {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: AppConstants.fontColossal))
                            .foregroundColor(.odysseyPrimary)

                        Text(NSLocalizedString("ODYSSEY", comment: "App name"))
                            .font(.system(size: AppConstants.accentFont))
                            .fontWeight(.bold)

                        Text(NSLocalizedString("about_app_subtitle", comment: "App subtitle"))
                            .font(.system(size: AppConstants.tertiaryFont))
                            .foregroundColor(.odysseySecondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        if let githubURL = URL(string: "https://github.com/Amet13/ODYSSEY") {
                            Link("Version \(appVersion)", destination: githubURL)
                                .font(.system(size: AppConstants.tertiaryFont))
                                .foregroundColor(.odysseyPrimary)
                        } else {
                            Text("Version \(appVersion)")
                                .font(.system(size: AppConstants.tertiaryFont))
                                .foregroundColor(.odysseySecondaryText)
                        }
                    }

                    Divider()

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
                                text: NSLocalizedString("about_feature_scheduling", comment: "Smart scheduling system"),
                                )
                            FeatureRow(
                                icon: "shield",
                                text: NSLocalizedString("about_feature_webkit", comment: "Native WebKit automation"),
                                )
                            FeatureRow(
                                icon: "envelope",
                                text: NSLocalizedString("about_feature_email", comment: "Email verification support"),
                                )
                            FeatureRow(
                                icon: "gear",
                                text: NSLocalizedString(
                                    "about_feature_multi_config",
                                    comment: "Multiple configuration support",
                                    ),
                                )
                            FeatureRow(
                                icon: "terminal",
                                text: NSLocalizedString(
                                    "about_feature_cli",
                                    comment: "CLI for remote automation",
                                    ),
                                )
                        }
                    }
                }
                .padding(.horizontal, AppConstants.sectionPadding)
                .padding(.vertical, AppConstants.contentPadding)
                .onTapGesture {
                    // Prevent tap from propagating to background when clicking on content
                }
            }
        }
        .frame(width: AppConstants.windowAboutWidth, height: AppConstants.windowAboutHeight)
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
                .foregroundColor(.odysseyPrimary)
                .frame(width: AppConstants.iconSmall)

            Text(text)
                .font(.system(size: AppConstants.tertiaryFont))
                .foregroundColor(.odysseyText)

            Spacer()
        }
    }
}
