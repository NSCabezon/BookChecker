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
    private var primaryLabel: String { pendingISBN != nil ? "Buscar" : "Confirmar" }

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

            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)

            slotRow(label: "Título", value: title, isActive: isAwaitingTitle, onClear: onClearTitle)
            slotRow(label: "Autor", value: author, isActive: isAwaitingAuthor, onClear: onClearAuthor)

            HStack {
                Button("Limpiar", role: .destructive, action: onReset)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
                Button(primaryLabel, action: onPrimaryAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(title == nil || title?.isEmpty == true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var hint: String {
        if isAwaitingTitle { return "Toca el título en la cámara" }
        if isAwaitingAuthor { return "Toca el autor en la cámara" }
        return pendingISBN != nil ? "Listo. Busca metadata o ajusta los campos." : "Listo. Confirma o ajusta los campos."
    }

    @ViewBuilder
    private func slotRow(label: String, value: String?, isActive: Bool, onClear: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
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
                Text(isActive ? "Esperando…" : "—")
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
