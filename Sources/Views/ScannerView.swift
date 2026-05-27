import SwiftUI
import SwiftData

struct ScannerView: View {
    @Environment(\.modelContext) private var context
    @State private var lastISBN: String?
    @State private var lastBook: Book?

    var body: some View {
        ZStack(alignment: .bottom) {
            ISBNScanner { isbn in
                Task { await handle(isbn: isbn) }
            }
            .ignoresSafeArea()

            if let book = lastBook {
                DecisionOverlay(book: book) { decision in
                    book.decision = decision
                    book.updatedAt = .now
                    try? context.save()
                }
                .padding()
                .transition(.move(edge: .bottom))
            }
        }
    }

    private func handle(isbn: String) async {
        guard isbn != lastISBN else { return }
        lastISBN = isbn

        let book = Book(isbn: isbn)
        context.insert(book)
        lastBook = book

        // TODO: lookup metadata + pricing en background, actualizar el book.
    }
}

private struct DecisionOverlay: View {
    let book: Book
    let onDecide: (BookDecision) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(book.title ?? book.isbn ?? "—")
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 16) {
                Button("Donate") { onDecide(.donate) }
                Button("Pending") { onDecide(.pending) }
                Button("Sell") { onDecide(.sell) }
                Button("Keep") { onDecide(.keep) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
