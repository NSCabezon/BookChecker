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
            Section("field_metadata") {
                TextField("field_title", text: Binding($book.title, replacingNilWith: ""))
                TextField("field_authors_comma", text: Binding(
                    get: { book.authors.joined(separator: ", ") },
                    set: { newValue in
                        book.authors = newValue
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                    }
                ))
                HStack {
                    TextField("field_isbn", text: Binding($book.isbn, replacingNilWith: ""))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    Button {
                        showISBNScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Text("detail_scan_isbn_a11y"))
                }
                TextField("field_ean5", text: Binding($book.ean5, replacingNilWith: ""))
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                TextField("field_publisher", text: Binding($book.publisher, replacingNilWith: ""))
            }

            Section("rating_online") {
                if let rating = book.rating {
                    RatingStarsView(rating: rating, count: book.ratingsCount)
                } else {
                    Text("rating_not_rated")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Button {
                    Task { await refreshRating() }
                } label: {
                    HStack {
                        if isRefreshingRating {
                            ProgressView()
                            Text("rating_searching")
                        } else {
                            Image(systemName: "arrow.clockwise")
                            Text(book.rating == nil ? LocalizedStringKey("rating_find") : LocalizedStringKey("rating_refresh"))
                        }
                    }
                }
                .disabled(isRefreshingRating || (book.isbn ?? "").isEmpty)
            }

            Section("rating_my_title") {
                if let user = book.userRating {
                    RatingStarsView(rating: user, count: nil)
                } else {
                    Text("rating_not_rated_yet")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Button {
                    showManualUserRating = true
                } label: {
                    Label(book.userRating == nil ? LocalizedStringKey("rating_rate_book") : LocalizedStringKey("rating_edit_my"), systemImage: "pencil")
                }
            }

            Section("decision_section") {
                Picker("decision_section", selection: $book.decision) {
                    ForEach(BookDecision.allCases) { d in
                        Text(d.displayKey).tag(d)
                    }
                }
                if book.decision == .keep {
                    Picker("decision_reason", selection: Binding($book.keepReason, default: .other)) {
                        ForEach(KeepReason.allCases) { r in
                            Text(r.displayKey).tag(r)
                        }
                    }
                }
            }

            Section("pricing_section") {
                if let min = book.priceMin {
                    LabeledContent("pricing_min", value: min.formatted(.currency(code: "EUR")))
                }
                if let max = book.priceMax {
                    LabeledContent("pricing_max", value: max.formatted(.currency(code: "EUR")))
                }
                if let count = book.listingsCount {
                    LabeledContent("pricing_listings", value: "\(count)")
                }
                if let at = book.priceCheckedAt {
                    LabeledContent("pricing_checked", value: at.formatted(date: .abbreviated, time: .shortened))
                }
                Button {
                    Task { await refreshPricing() }
                } label: {
                    HStack {
                        if isRefreshingPrice {
                            ProgressView()
                            Text("rating_searching")
                        } else {
                            Image(systemName: "arrow.clockwise")
                            Text("pricing_refresh")
                        }
                    }
                }
                .disabled(isRefreshingPrice || (book.isbn ?? "").isEmpty)

                if book.priceMin == nil && book.priceMax == nil {
                    Button {
                        showManualPricing = true
                    } label: {
                        Label("pricing_enter_manually", systemImage: "pencil")
                    }
                }
            }

            Section("field_notes") {
                TextField("field_notes", text: Binding($book.notes, replacingNilWith: ""), axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(book.title.map(Text.init) ?? book.isbn.map(Text.init) ?? Text("detail_book_fallback_title"))
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
