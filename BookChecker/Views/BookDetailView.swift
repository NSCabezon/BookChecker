import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.pricingAggregator) private var pricingAggregator
    @Environment(\.metadataResolver) private var resolver
    @Bindable var book: Book
    @State private var showISBNScanner = false
    @State private var isRefreshingPrice = false
    @State private var isRefreshingRating = false
    @State private var showManualPricing = false
    @State private var showManualUserRating = false

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
                HStack {
                    TextField("ISBN", text: Binding($book.isbn, replacingNilWith: ""))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    Button {
                        showISBNScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Escanear ISBN")
                }
                TextField("EAN-5", text: Binding($book.ean5, replacingNilWith: ""))
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                TextField("Publisher", text: Binding($book.publisher, replacingNilWith: ""))
            }

            Section("Media en internet") {
                if let rating = book.rating {
                    RatingStarsView(rating: rating, count: book.ratingsCount)
                } else {
                    Text("Sin puntuación")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Button {
                    Task { await refreshRating() }
                } label: {
                    HStack {
                        if isRefreshingRating {
                            ProgressView()
                            Text("Buscando…")
                        } else {
                            Image(systemName: "arrow.clockwise")
                            Text(book.rating == nil ? "Buscar puntuación" : "Actualizar puntuación")
                        }
                    }
                }
                .disabled(isRefreshingRating || (book.isbn ?? "").isEmpty)
            }

            Section("Mi puntuación") {
                if let user = book.userRating {
                    RatingStarsView(rating: user, count: nil)
                } else {
                    Text("Sin valorar")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Button {
                    showManualUserRating = true
                } label: {
                    Label(book.userRating == nil ? "Puntuar libro" : "Editar mi puntuación", systemImage: "pencil")
                }
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
                Button {
                    Task { await refreshPricing() }
                } label: {
                    HStack {
                        if isRefreshingPrice {
                            ProgressView()
                            Text("Buscando…")
                        } else {
                            Image(systemName: "arrow.clockwise")
                            Text("Actualizar precio")
                        }
                    }
                }
                .disabled(isRefreshingPrice || (book.isbn ?? "").isEmpty)

                if book.priceMin == nil && book.priceMax == nil {
                    Button {
                        showManualPricing = true
                    } label: {
                        Label("Introducir manualmente", systemImage: "pencil")
                    }
                }
            }

            Section("Notes") {
                TextField("Notes", text: Binding($book.notes, replacingNilWith: ""), axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(book.title ?? book.isbn ?? "Book")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showISBNScanner) {
            ISBNScanSheet { isbn, ean5 in
                book.isbn = isbn
                if let ean5 { book.ean5 = ean5 }
                book.updatedAt = .now
            }
        }
        .sheet(isPresented: $showManualPricing) {
            ManualPricingSheet(book: book)
        }
        .sheet(isPresented: $showManualUserRating) {
            ManualRatingSheet(book: book)
        }
    }

    private func refreshPricing() async {
        isRefreshingPrice = true
        await updatePricing(for: book, using: pricingAggregator, context: context)
        isRefreshingPrice = false
    }

    private func refreshRating() async {
        isRefreshingRating = true
        await updateRating(for: book, using: resolver, context: context)
        isRefreshingRating = false
    }
}

#Preview {
    NavigationStack {
        BookDetailView(book: PreviewSamples.bookSell)
    }
    .modelContainer(PreviewSamples.inMemoryContainer(with: [PreviewSamples.bookSell]))
}
