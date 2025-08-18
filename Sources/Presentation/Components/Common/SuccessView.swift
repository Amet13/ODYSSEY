import SwiftUI

struct SuccessView: View {
  let message: String
  let action: () -> Void

  var body: some View {
    VStack(spacing: AppConstants.spacingXLarge) {
      Image(systemName: "checkmark.circle")
        .font(.system(size: AppConstants.fontMassive))
        .foregroundColor(.green)

      Text(message)
        .font(.system(size: AppConstants.fontBody))
        .multilineTextAlignment(.center)

      Button("Continue", action: action)
        .buttonStyle(.borderedProminent)
    }
    .padding(AppConstants.contentPadding)
  }
}

#Preview {
  SuccessView(message: "Configuration saved successfully!") {}
}
