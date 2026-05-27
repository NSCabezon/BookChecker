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
