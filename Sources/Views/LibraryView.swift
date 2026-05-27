import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \Book.updatedAt, order: .reverse) private var books: [Book]
    @State private var filter: BookDecision?

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { book in
                    NavigationLink(value: book) {
                        BookRow(book: book)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
            .toolbar {
                Picker("Filter", selection: $filter) {
                    Text("All").tag(BookDecision?.none)
                    ForEach(BookDecision.allCases) { d in
                        Text(d.rawValue.capitalized).tag(Optional(d))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var filtered: [Book] {
        guard let filter else { return books }
        return books.filter { $0.decision == filter }
    }
}

private struct BookRow: View {
    let book: Book

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(book.title ?? book.isbn ?? "—").font(.body)
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
