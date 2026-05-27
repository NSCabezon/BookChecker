import SwiftUI

struct OCRPanel: View {
    let pendingISBN: String?
    let title: String?
    let author: String?
    let onClearTitle: () -> Void
    let onClearAuthor: () -> Void
    let onPrimaryAction: () -> Void
    let onReset: () -> Void

    private var isAwaitingTitle: Bool { title == nil }
    private var isAwaitingAuthor: Bool { title != nil && author == nil }
    private var primaryLabelKey: LocalizedStringKey { pendingISBN != nil ? "common_search" : "common_confirm" }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let pendingISBN {
                HStack(spacing: 6) {
                    Image(systemName: "barcode")
                        .font(.caption2)
                    Text(pendingISBN)
                        .font(.system(.caption, design: .monospaced))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.tint.opacity(0.2), in: Capsule())
            }

            Text(hintKey)
                .font(.caption)
                .foregroundStyle(.secondary)

            slotRow(labelKey: "field_title", value: title, isActive: isAwaitingTitle, onClear: onClearTitle)
            slotRow(labelKey: "field_author", value: author, isActive: isAwaitingAuthor, onClear: onClearAuthor)

            HStack {
                Button("common_clear", role: .destructive, action: onReset)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
                Button(primaryLabelKey, action: onPrimaryAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(title == nil || title?.isEmpty == true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var hintKey: LocalizedStringKey {
        if isAwaitingTitle { return "ocr_tap_title" }
        if isAwaitingAuthor { return "ocr_tap_author" }
        return pendingISBN != nil ? "ocr_ready_with_isbn" : "ocr_ready_no_isbn"
    }

    @ViewBuilder
    private func slotRow(labelKey: LocalizedStringKey, value: String?, isActive: Bool, onClear: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(labelKey)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            if let value {
                Text(value)
                    .font(.callout)
                    .lineLimit(2)
                Spacer()
                Button { onClear() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Text(isActive ? LocalizedStringKey("ocr_waiting") : LocalizedStringKey("—"))
                    .font(.callout)
                    .foregroundStyle(isActive ? .primary : .secondary)
                    .italic(!isActive)
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isActive ? Color.accentColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview("Empty") {
    OCRPanel(
        pendingISBN: nil,
        title: nil,
        author: nil,
        onClearTitle: {},
        onClearAuthor: {},
        onPrimaryAction: {},
        onReset: {}
    )
    .padding()
    .background(Color.gray)
}

#Preview("Title only") {
    OCRPanel(
        pendingISBN: nil,
        title: "El nombre de la rosa",
        author: nil,
        onClearTitle: {},
        onClearAuthor: {},
        onPrimaryAction: {},
        onReset: {}
    )
    .padding()
    .background(Color.gray)
}

#Preview("With pending ISBN") {
    OCRPanel(
        pendingISBN: "9788478888880",
        title: "El nombre de la rosa",
        author: "Umberto Eco",
        onClearTitle: {},
        onClearAuthor: {},
        onPrimaryAction: {},
        onReset: {}
    )
    .padding()
    .background(Color.gray)
}
