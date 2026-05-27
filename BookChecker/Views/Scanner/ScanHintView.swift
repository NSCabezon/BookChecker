import SwiftUI

struct ScanHintView: View {
    let textKey: LocalizedStringKey
    let actionLabelKey: LocalizedStringKey
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "barcode.viewfinder")
            Text(textKey).font(.subheadline)
            Spacer()
            Button(actionLabelKey) { onAction() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    ScanHintView(textKey: "scanner_hint_scan_isbn", actionLabelKey: "scanner_manual") {}
        .padding()
        .background(Color.gray)
}
