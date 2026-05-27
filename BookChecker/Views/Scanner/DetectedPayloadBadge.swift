import SwiftUI

struct DetectedPayloadBadge: View {
    let payload: String
    let accepted: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: accepted ? "checkmark.circle.fill" : "barcode")
                .foregroundStyle(accepted ? .green : .yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(accepted ? LocalizedStringKey("field_isbn") : LocalizedStringKey("scanner_detected"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(payload)
                    .font(.system(.callout, design: .monospaced))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview("Detected") {
    DetectedPayloadBadge(payload: "9780140449266", accepted: false)
        .padding()
        .background(Color.gray)
}

#Preview("Accepted") {
    DetectedPayloadBadge(payload: "9780140449266", accepted: true)
        .padding()
        .background(Color.gray)
}
