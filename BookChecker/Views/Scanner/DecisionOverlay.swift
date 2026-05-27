import SwiftUI
import SwiftData

struct DecisionOverlay: View {
    let book: Book
    let onDecide: (BookDecision) -> Void

    var body: some View {
        VStack(spacing: 10) {
            if let isbn = book.isbn {
                HStack(spacing: 6) {
                    Text(isbn)
                        .font(.system(.caption, design: .monospaced))
                    if let ean5 = book.ean5 {
                        Text("+\(ean5)")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.2), in: Capsule())
                    }
                }
                .foregroundStyle(.secondary)
            }
            Text(book.title ?? "Sin título")
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            if !book.authors.isEmpty {
                Text(book.authors.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button("Donate") { onDecide(.donate) }
                Button("Pending") { onDecide(.pending) }
                Button("Sell") { onDecide(.sell) }
                Button("Keep") { onDecide(.keep) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    let container = PreviewSamples.inMemoryContainer(with: [PreviewSamples.bookPending])
    return DecisionOverlay(book: PreviewSamples.bookPending) { _ in }
        .padding()
        .background(Color.gray)
        .modelContainer(container)
}
