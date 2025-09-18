import SwiftUI

struct SuccessView: View {
  let message: String
  let action: () -> Void

  var body: some View {
    VStack(spacing: AppConstants.spacingXLarge) {
      Image(systemName: AppConstants.SFSymbols.successCircle)
        .symbolRenderingMode(.hierarchical)
        .font(.system(size: AppConstants.fontMassive))
        .foregroundColor(.odysseySuccess)

      Text(message)
        .font(.system(size: AppConstants.fontBody))
        .multilineTextAlignment(.center)
        .foregroundColor(.primary)

      Button("Continue", action: action)
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
    }
    .padding(AppConstants.contentPadding)
    .odysseyCardBackground(cornerRadius: AppConstants.cardCornerRadius)
    .if(!NSWorkspace.shared.accessibilityDisplayShouldReduceMotion) { v in v.transition(.opacity) }
  }
}

#Preview {
  SuccessView(message: "Configuration saved successfully!") {}
}
