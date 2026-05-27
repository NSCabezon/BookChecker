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
                Section("Precio (EUR)") {
                    TextField("Mínimo", text: $minText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Máximo", text: $maxText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                Section("Listings") {
                    TextField("Número de listings", text: $countText)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                Section {
                    Text("Si rellenas mínimo y máximo iguales, basta con uno. Los valores se guardan como `manual` y aparecen en la sección Pricing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Precio manual")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
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
