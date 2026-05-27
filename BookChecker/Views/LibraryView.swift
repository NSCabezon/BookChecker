import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Book.updatedAt, order: .reverse) private var books: [Book]
    @State private var filter: BookDecision?
    @State private var bookPendingDeletion: Book?

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { book in
                    NavigationLink(value: book) {
                        BookRow(book: book)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            bookPendingDeletion = book
                        } label: {
                            Label("Borrar", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
            .toolbar {
                Menu {
                    Button {
                        filter = nil
                    } label: {
                        Label("All", systemImage: filter == nil ? "checkmark" : "")
                    }
                    ForEach(BookDecision.allCases) { d in
                        Button {
                            filter = d
                        } label: {
                            Label(d.rawValue.capitalized, systemImage: filter == d ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            .confirmationDialog(
                deletionTitle,
                isPresented: Binding(
                    get: { bookPendingDeletion != nil },
                    set: { if !$0 { bookPendingDeletion = nil } }
                ),
                titleVisibility: .visible,
                presenting: bookPendingDeletion
            ) { book in
                Button("Borrar", role: .destructive) {
                    delete(book)
                }
                Button("Cancelar", role: .cancel) {
                    bookPendingDeletion = nil
                }
            } message: { _ in
                Text("Esta acción no se puede deshacer.")
            }
        }
    }

    private var deletionTitle: String {
        guard let book = bookPendingDeletion else { return "Borrar libro" }
        let label = book.title ?? book.isbn ?? "este libro"
        return "¿Borrar \(label)?"
    }

    private var filtered: [Book] {
        guard let filter else { return books }
        return books.filter { $0.decision == filter }
    }

    private func delete(_ book: Book) {
        context.delete(book)
        try? context.save()
        bookPendingDeletion = nil
    }
}

private struct BookRow: View {
    let book: Book

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(book.title ?? book.isbn ?? "—").font(.body)
                    if let ean5 = book.ean5 {
                        Text("#\(ean5)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.2), in: Capsule())
                    }
                }
                if !book.authors.isEmpty {
                    Text(book.authors.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(book.decision.rawValue.capitalized)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
        }
    }
}
