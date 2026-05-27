import SwiftUI

struct ScanHintView: View {
    let text: String
    let actionLabel: String
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "barcode.viewfinder")
            Text(text).font(.subheadline)
            Spacer()
            Button(actionLabel) { onAction() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    ScanHintView(text: "Apunta a un ISBN", actionLabel: "Manual") {}
        .padding()
        .background(Color.gray)
}
