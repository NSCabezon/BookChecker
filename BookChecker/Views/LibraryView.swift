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
                            Label("common_delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("library_title")
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
            .toolbar {
                Menu {
                    Button {
                        filter = nil
                    } label: {
                        if filter == nil {
                            Label("library_filter_all", systemImage: "checkmark")
                        } else {
                            Text("library_filter_all")
                        }
                    }
                    ForEach(BookDecision.allCases) { d in
                        Button {
                            filter = d
                        } label: {
                            if filter == d {
                                Label { Text(d.displayKey) } icon: { Image(systemName: "checkmark") }
                            } else {
                                Text(d.displayKey)
                            }
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
                Button("common_delete", role: .destructive) {
                    delete(book)
                }
                Button("common_cancel", role: .cancel) {
                    bookPendingDeletion = nil
                }
            } message: { _ in
                Text("library_delete_message")
            }
        }
    }

    private var deletionTitle: LocalizedStringKey {
        guard let book = bookPendingDeletion else { return "library_delete_unnamed" }
        if let label = book.title ?? book.isbn {
            return "library_delete_named \(label)"
        }
        return "library_delete_unnamed"
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

#Preview {
    LibraryView()
        .modelContainer(PreviewSamples.inMemoryContainer(with: [
            PreviewSamples.bookPending,
            PreviewSamples.bookSell,
            PreviewSamples.bookKeep
        ]))
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
            VStack(alignment: .trailing, spacing: 4) {
                Text(book.decision.displayKey)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
                if let rating = book.rating {
                    RatingStarsView(rating: rating, count: nil, compact: true)
                }
                if let min = book.priceMin, let max = book.priceMax {
                    Text("\(min.formatted(.currency(code: "EUR"))) – \(max.formatted(.currency(code: "EUR")))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if let min = book.priceMin {
                    Text(min.formatted(.currency(code: "EUR")))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
