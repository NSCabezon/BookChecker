import SwiftUI

struct PreviewCard: View {
    let draft: BookDraft
    let onConfirm: () -> Void
    let onEdit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                cover
                VStack(alignment: .leading, spacing: 4) {
                    if let title = draft.title, !title.isEmpty {
                        Text(title)
                            .font(.headline)
                            .lineLimit(3)
                    } else {
                        Text("Sin título")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    if !draft.authors.isEmpty {
                        Text(draft.authors.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    HStack(spacing: 8) {
                        if let year = draft.year {
                            Text(String(year))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let publisher = draft.publisher, !publisher.isEmpty {
                            Text(publisher)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    if let isbn = draft.isbn {
                        HStack(spacing: 6) {
                            Text(isbn)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                            if let ean5 = draft.ean5 {
                                Text("+\(ean5)")
                                    .font(.system(.caption2, design: .monospaced))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(.tint.opacity(0.2), in: Capsule())
                            }
                        }
                    }
                    if let source = draft.source {
                        Text("Fuente: \(source)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button("Cancelar", role: .cancel, action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Editar", action: onEdit)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
                Button("Confirmar", action: onConfirm)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var cover: some View {
        if let url = draft.coverURL {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                placeholderCover
            }
            .frame(width: 64, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            placeholderCover
                .frame(width: 64, height: 96)
        }
    }

    private var placeholderCover: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(.quaternary)
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview("Full metadata") {
    PreviewCard(
        draft: PreviewSamples.draftFull,
        onConfirm: {},
        onEdit: {},
        onCancel: {}
    )
    .padding()
    .background(Color.gray)
}

#Preview("Minimal") {
    PreviewCard(
        draft: PreviewSamples.draftMinimal,
        onConfirm: {},
        onEdit: {},
        onCancel: {}
    )
    .padding()
    .background(Color.gray)
}
