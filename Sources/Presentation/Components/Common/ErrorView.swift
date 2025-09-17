import SwiftUI

struct ErrorView: View {
  let error: Error
  let retryAction: () -> Void

  var body: some View {
    VStack(spacing: AppConstants.spacingXLarge) {
      Image(systemName: AppConstants.SFSymbols.warningFill)
        .symbolRenderingMode(.hierarchical)
        .font(.title)
        .foregroundColor(.odysseyError)

      Text(error.localizedDescription)
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

      Button("Retry", action: retryAction)
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
    }
    .padding(AppConstants.contentPadding)
    .odysseyCardBackground(cornerRadius: AppConstants.cardCornerRadius)
    .if(!NSWorkspace.shared.accessibilityDisplayShouldReduceMotion) { view in
      view.transition(.opacity)
    }
  }
}

#Preview {
  ErrorView(
    error: NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"]),
    retryAction: {},
  )
}
