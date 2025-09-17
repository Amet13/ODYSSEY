import SwiftUI

struct LoadingView: View {
  let message: String

  var body: some View {
    VStack(spacing: AppConstants.spacingXLarge) {
      ProgressView()
        .scaleEffect(AppConstants.scaleEffectLarge)
      Text(message)
        .font(.footnote)
        .foregroundColor(.secondary)
    }
    .padding(AppConstants.contentPadding)
    .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
  }
}

#Preview {
  LoadingView(message: "Loading configurations...")
}
