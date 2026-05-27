import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Bindable var book: Book

    var body: some View {
        Form {
            Section("Metadata") {
                TextField("Title", text: Binding($book.title, replacingNilWith: ""))
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

private extension Binding where Value == String {
    init(_ source: Binding<String?>, replacingNilWith fallback: String) {
        self.init(
            get: { source.wrappedValue ?? fallback },
            set: { source.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

private extension Binding {
    init<T>(_ source: Binding<T?>, default defaultValue: T) where Value == T {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }
}
