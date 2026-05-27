import SwiftUI

struct EditDraftSheet: View {
    @Binding var draft: BookDraft
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var authorsField: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("field_metadata") {
                    TextField("field_title", text: Binding($draft.title, replacingNilWith: ""))
                    TextField("field_authors_comma", text: $authorsField)
                    TextField("field_publisher", text: Binding($draft.publisher, replacingNilWith: ""))
                    TextField("field_year", value: $draft.year, format: .number.grouping(.never))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                Section("field_identifiers") {
                    TextField("field_isbn", text: Binding($draft.isbn, replacingNilWith: ""))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("field_ean5", text: Binding($draft.ean5, replacingNilWith: ""))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
            }
            .navigationTitle("scanner_edit_book")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common_save") {
                        commitAuthors()
                        onSave()
                    }
                }
            }
            .onAppear {
                authorsField = draft.authors.joined(separator: ", ")
            }
        }
    }

    private func commitAuthors() {
        let parts = authorsField
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        draft.authors = parts
    }
}

#Preview {
    @Previewable @State var draft = PreviewSamples.draftFull
    return EditDraftSheet(draft: $draft, onSave: {}, onCancel: {})
}
