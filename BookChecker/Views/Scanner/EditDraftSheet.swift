import SwiftUI

struct EditDraftSheet: View {
    @Binding var draft: BookDraft
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var authorsField: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Metadata") {
                    TextField("Título", text: Binding($draft.title, replacingNilWith: ""))
                    TextField("Autores (separados por coma)", text: $authorsField)
                    TextField("Editorial", text: Binding($draft.publisher, replacingNilWith: ""))
                    TextField("Año", value: $draft.year, format: .number.grouping(.never))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                Section("Identificadores") {
                    TextField("ISBN", text: Binding($draft.isbn, replacingNilWith: ""))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("EAN-5", text: Binding($draft.ean5, replacingNilWith: ""))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
            }
            .navigationTitle("Editar libro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
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
