import SwiftUI

struct NotFoundCard: View {
    let isbn: String
    let onScanCover: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.yellow)
                Text("scanner_not_found_title")
                    .font(.headline)
            }
            Text("scanner_not_found \(isbn)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("common_cancel", role: .cancel, action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
                Button {
                    onScanCover()
                } label: {
                    Label("scanner_scan_cover", systemImage: "text.viewfinder")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    NotFoundCard(isbn: "9788478888880", onScanCover: {}, onCancel: {})
        .padding()
        .background(Color.gray)
}
