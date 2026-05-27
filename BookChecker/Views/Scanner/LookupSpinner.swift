import SwiftUI

struct LookupSpinner: View {
    let message: String

    init(message: String = "Buscando…") {
        self.message = message
    }

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.subheadline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    LookupSpinner()
        .padding()
        .background(Color.gray)
}

#Preview("Custom message") {
    LookupSpinner(message: "Buscando por título…")
        .padding()
        .background(Color.gray)
}
