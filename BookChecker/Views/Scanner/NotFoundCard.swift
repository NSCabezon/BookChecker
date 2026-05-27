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
                Text("No encontrado")
                    .font(.headline)
            }
            Text("ISBN \(isbn) no aparece en los catálogos. Puedes escanear la portada para capturar título y autor.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Cancelar", role: .cancel, action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
                Button {
                    onScanCover()
                } label: {
                    Label("Escanear portada", systemImage: "text.viewfinder")
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
