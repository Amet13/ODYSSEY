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

                        Text("ODYSSEY")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Ottawa Drop-in Your Sports & Schedule Easily Yourself")
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
                        Text("About ODYSSEY")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(
                            "ODYSSEY is a native macOS menu bar application that automates sports reservation bookings " +
                                "for Ottawa Recreation facilities.",
                            )
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                        VStack(alignment: .leading, spacing: 6) {
                            FeatureRow(icon: "sportscourt", text: "Automated reservation booking")
                            FeatureRow(icon: "clock", text: "Smart scheduling system")
                            FeatureRow(icon: "shield", text: "Native WebKit automation")
                            FeatureRow(icon: "envelope", text: "Email verification support")
                            FeatureRow(icon: "gear", text: "Multiple configuration support")
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .onTapGesture {
                    // Prevent tap from propagating to background when clicking on content
                }
            }
        }
        .frame(width: 380, height: 400)
        .background(.clear)
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
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 14)

            Text(text)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}
