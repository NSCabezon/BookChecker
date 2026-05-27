import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Bindable var book: Book

    var body: some View {
        Form {
            Section("Metadata") {
                TextField("Title", text: Binding($book.title, replacingNilWith: ""))
                TextField("Authors (separados por coma)", text: Binding(
                    get: { book.authors.joined(separator: ", ") },
                    set: { newValue in
                        book.authors = newValue
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                    }
                ))
                TextField("ISBN", text: Binding($book.isbn, replacingNilWith: ""))
                TextField("Publisher", text: Binding($book.publisher, replacingNilWith: ""))
            }

            Section("Decision") {
                Picker("Decision", selection: $book.decision) {
                    ForEach(BookDecision.allCases) { d in
                        Text(d.rawValue.capitalized).tag(d)
                    }
                }
                if book.decision == .keep {
                    Picker("Reason", selection: Binding($book.keepReason, default: .other)) {
                        ForEach(KeepReason.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                }
            }

            Section("Pricing") {
                if let min = book.priceMin {
                    LabeledContent("Min", value: min.formatted(.currency(code: "EUR")))
                }
                if let max = book.priceMax {
                    LabeledContent("Max", value: max.formatted(.currency(code: "EUR")))
                }
                if let count = book.listingsCount {
                    LabeledContent("Listings", value: "\(count)")
                }
                if let at = book.priceCheckedAt {
                    LabeledContent("Checked", value: at.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Section("Notes") {
                TextField("Notes", text: Binding($book.notes, replacingNilWith: ""), axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(book.title ?? book.isbn ?? "Book")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BookDetailView(book: PreviewSamples.bookSell)
    }
    .modelContainer(PreviewSamples.inMemoryContainer(with: [PreviewSamples.bookSell]))
}

