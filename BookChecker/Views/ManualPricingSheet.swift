import SwiftUI
import SwiftData

struct ManualPricingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var book: Book

    @State private var minText: String = ""
    @State private var maxText: String = ""
    @State private var countText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("pricing_price_eur") {
                    TextField("pricing_minimum", text: $minText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("pricing_maximum", text: $maxText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                Section("pricing_listings") {
                    TextField("pricing_listings_count", text: $countText)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                Section {
                    Text("pricing_disclaimer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("pricing_manual_title")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common_save") {
                        save()
                        dismiss()
                    }
                    .disabled(!hasAnyValue)
                }
            }
            .onAppear { prefill() }
        }
    }

    private var hasAnyValue: Bool {
        parseDecimal(minText) != nil || parseDecimal(maxText) != nil
    }

    private func prefill() {
        if let min = book.priceMin { minText = formatDecimal(min) }
        if let max = book.priceMax { maxText = formatDecimal(max) }
        if let count = book.listingsCount { countText = "\(count)" }
    }

    private func save() {
        let parsedMin = parseDecimal(minText)
        let parsedMax = parseDecimal(maxText)
        // If only one entered, use it for both bounds.
        let resolvedMin = parsedMin ?? parsedMax
        let resolvedMax = parsedMax ?? parsedMin

        book.priceMin = resolvedMin
        book.priceMax = resolvedMax
        book.listingsCount = Int(countText)
        if let resolvedMin {
            book.listingsSample = [resolvedMin]
            if let resolvedMax, resolvedMax != resolvedMin {
                book.listingsSample.append(resolvedMax)
            }
        }
        book.priceCheckedAt = .now
        book.updatedAt = .now
        try? context.save()
    }

    private func parseDecimal(_ raw: String) -> Decimal? {
        let normalized = raw
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized)
    }

    private func formatDecimal(_ value: Decimal) -> String {
        var v = value
        var result = Decimal()
        NSDecimalRound(&result, &v, 2, .plain)
        return "\(result)"
    }
}

#Preview {
    let container = PreviewSamples.inMemoryContainer(with: [PreviewSamples.bookPending])
    return ManualPricingSheet(book: PreviewSamples.bookPending)
        .modelContainer(container)
}
