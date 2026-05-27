import SwiftUI
import SwiftData

struct ManualRatingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var book: Book

    @State private var ratingValue: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Tu puntuación") {
                    HStack {
                        Slider(value: $ratingValue, in: 0...5, step: 0.5)
                        Text(String(format: "%.1f", ratingValue))
                            .font(.system(.callout, design: .monospaced))
                            .frame(width: 40, alignment: .trailing)
                    }
                    RatingStarsView(rating: ratingValue, count: nil)
                }
                if let avg = book.rating {
                    Section("Media en internet") {
                        RatingStarsView(rating: avg, count: book.ratingsCount, compact: true)
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Text("Esta puntuación es tuya y solo aparece en tu biblioteca. No se sube a internet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Mi puntuación")
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
                }
                ToolbarItem(placement: .destructiveAction) {
                    if book.userRating != nil {
                        Button("Borrar") {
                            book.userRating = nil
                            book.updatedAt = .now
                            try? context.save()
                            dismiss()
                        }
                    }
                }
            }
            .onAppear { prefill() }
        }
    }

    private func prefill() {
        ratingValue = book.userRating ?? 0
    }

    private func save() {
        book.userRating = ratingValue > 0 ? ratingValue : nil
        book.updatedAt = .now
        try? context.save()
    }
}

#Preview {
    let container = PreviewSamples.inMemoryContainer(with: [PreviewSamples.bookSell])
    return ManualRatingSheet(book: PreviewSamples.bookSell)
        .modelContainer(container)
}
