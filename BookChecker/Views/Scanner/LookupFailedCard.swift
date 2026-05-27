import SwiftUI

struct LookupFailedCard: View {
    let message: String
    let onRetry: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("scanner_lookup_error")
                    .font(.headline)
            }
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("common_cancel", role: .cancel, action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
                Button("common_retry", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    LookupFailedCard(message: "Sin conexión a internet", onRetry: {}, onCancel: {})
        .padding()
        .background(Color.gray)
}
