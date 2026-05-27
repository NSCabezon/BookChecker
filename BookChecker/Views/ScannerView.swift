import SwiftUI
import SwiftData

struct ScannerView: View {
    @Environment(\.modelContext) private var context
    @State private var lastISBN: String?
    @State private var lastBook: Book?
    @State private var lastRawPayload: String?
    @State private var showManualEntry = false
    @State private var torchOn = false

    var body: some View {
        ZStack {
            if ISBNScanner.isAvailable {
                ISBNScanner(
                    torchOn: $torchOn,
                    onScan: { isbn in Task { await handle(isbn: isbn) } },
                    onRawDetect: { payload in lastRawPayload = payload }
                )
                .ignoresSafeArea()
            } else {
                UnsupportedScannerView()
            }

            VStack {
                if let payload = lastRawPayload {
                    DetectedPayloadBadge(payload: payload, accepted: payload == lastISBN)
                        .padding(.top, 8)
                }

                Spacer()

                TorchButton(isOn: $torchOn)
                    .padding(.bottom, 12)

                if let book = lastBook {
                    DecisionOverlay(book: book) { decision in
                        book.decision = decision
                        book.updatedAt = .now
                        try? context.save()
                        withAnimation { lastBook = nil }
                    }
                    .padding()
                } else {
                    ScanHintView { showManualEntry = true }
                        .padding()
                }
            }
            .animation(.snappy, value: lastBook?.id)
            .animation(.snappy, value: lastRawPayload)
        }
        .sheet(isPresented: $showManualEntry) {
            ManualISBNEntryView { isbn in
                Task { await handle(isbn: isbn) }
            }
        }
        .onDisappear { torchOn = false }
    }

    private func handle(isbn: String) async {
        guard isbn != lastISBN else { return }
        lastISBN = isbn

        let book = Book(isbn: isbn)
        context.insert(book)
        try? context.save()
        withAnimation { lastBook = book }

        // TODO: lookup metadata + pricing en background, actualizar el book.
    }
}

private struct TorchButton: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: isOn ? "flashlight.on.fill" : "flashlight.off.fill")
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .foregroundStyle(isOn ? .yellow : .primary)
        }
        .accessibilityLabel(isOn ? "Apagar linterna" : "Encender linterna")
    }
}

private struct DetectedPayloadBadge: View {
    let payload: String
    let accepted: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: accepted ? "checkmark.circle.fill" : "barcode")
                .foregroundStyle(accepted ? .green : .yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(accepted ? "ISBN" : "Detectado")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(payload)
                    .font(.system(.callout, design: .monospaced))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct DecisionOverlay: View {
    let book: Book
    let onDecide: (BookDecision) -> Void

    var body: some View {
        VStack(spacing: 10) {
            if let isbn = book.isbn {
                Text(isbn)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Text(book.title ?? "Sin título")
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Button("Donate") { onDecide(.donate) }
                Button("Pending") { onDecide(.pending) }
                Button("Sell") { onDecide(.sell) }
                Button("Keep") { onDecide(.keep) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

private struct ScanHintView: View {
    let onManualEntry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "barcode.viewfinder")
            Text("Apunta a un ISBN")
                .font(.subheadline)
            Spacer()
            Button("Manual") { onManualEntry() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct UnsupportedScannerView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                Text("Cámara no disponible")
                    .font(.headline)
                Text("DataScannerViewController requiere un dispositivo real (A12+) y permiso de cámara. Usa la entrada manual.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
            .foregroundStyle(.white)
        }
    }
}

private struct ManualISBNEntryView: View {
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
