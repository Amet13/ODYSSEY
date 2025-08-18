import SwiftUI

struct ErrorView: View {
  let error: Error
  let retryAction: () -> Void

  var body: some View {
    VStack(spacing: AppConstants.spacingXLarge) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: AppConstants.fontMassive))
        .foregroundColor(.odysseyError)

      Text(error.localizedDescription)
        .font(.system(size: AppConstants.fontBody))
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

      Button("Retry", action: retryAction)
        .buttonStyle(.borderedProminent)
    }
    .padding(AppConstants.contentPadding)
    .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
  }
}

#Preview {
  ErrorView(
    error: NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"]),
    retryAction: {},
  )
}
