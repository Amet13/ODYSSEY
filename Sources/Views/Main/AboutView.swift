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
            // Background that closes the window when tapped
            Color.white // Solid white background
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }

            // Content area
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)

                        Text(NSLocalizedString("ODYSSEY", comment: "App name"))
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(NSLocalizedString("about_app_subtitle", comment: "App subtitle"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        if let githubURL = URL(string: "https://github.com/Amet13/ODYSSEY") {
                            Link("Version \(appVersion)", destination: githubURL)
                                .font(.caption2)
                                .foregroundColor(.blue)
                        } else {
                            Text("Version \(appVersion)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("about_section_title", comment: "About ODYSSEY"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.bottom, 2)
                        Text(NSLocalizedString("about_app_description", comment: "App description"))
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        VStack(alignment: .leading, spacing: 6) {
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
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .onTapGesture {
                    // Prevent tap from propagating to background when clicking on content
                }
                // --- New Sections ---
                EasterEggsSection()
            }
        }
        .frame(width: AppConstants.windowAboutWidth, height: AppConstants.windowAboutHeight)
        .background(.clear)
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }
}

private struct EasterEggsSection: View {
    @ObservedObject private var eggService = EasterEggService.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Easter Eggs")
                .font(.headline)
                .padding(.top, 8)
            if eggService.easterEggs.filter(\.isDiscovered).isEmpty {
                Text("No easter eggs discovered yet. Keep exploring!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(eggService.easterEggs.filter(\.isDiscovered)) { egg in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(egg.name)
                                .font(.caption).bold()
                            Text(egg.description)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    Divider()
                }
            }
        }
        .padding(.top, 8)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: AppConstants.iconSmall)

            Text(text)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}
