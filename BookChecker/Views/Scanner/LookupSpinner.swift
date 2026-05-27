import SwiftUI

struct LookupSpinner: View {
    let messageKey: LocalizedStringKey

    init(messageKey: LocalizedStringKey = "scanner_lookup_default") {
        self.messageKey = messageKey
    }

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(messageKey)
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
    LookupSpinner(messageKey: "rating_searching")
        .padding()
        .background(Color.gray)
}
