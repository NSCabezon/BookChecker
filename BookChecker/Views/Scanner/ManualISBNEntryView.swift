import SwiftUI

struct ManualISBNEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    let onSubmit: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("ISBN (10 ó 13 dígitos)", text: $input)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
            }
            .navigationTitle("Entrada manual")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Añadir") {
                        let digits = input.filter(\.isNumber)
                        guard digits.count == 10 || digits.count == 13 else { return }
                        onSubmit(digits)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        let digits = input.filter(\.isNumber)
        return digits.count == 10 || digits.count == 13
    }
}

#Preview {
    ManualISBNEntryView { _ in }
}
