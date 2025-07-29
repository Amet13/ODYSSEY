import SwiftUI

struct SuccessView: View {
    let message: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundColor(.green)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)

            Button("Continue", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    SuccessView(message: "Configuration saved successfully!") { }
}
