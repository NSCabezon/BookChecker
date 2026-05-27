import SwiftUI

struct ManualISBNEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    let onSubmit: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("scanner_isbn_field_placeholder", text: $input)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
            }
            .navigationTitle("scanner_manual_entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common_add") {
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
