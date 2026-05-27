import SwiftUI
import SwiftData

enum ScanMode: String, CaseIterable, Identifiable {
    case barcode
    case ocr

    var id: String { rawValue }
    var label: String {
        switch self {
        case .barcode: return "Código"
        case .ocr: return "OCR"
        }
    }
}

private enum OCRStage {
    case awaitingTitle
    case awaitingAuthor
    case ready
}

struct ScannerView: View {
    @Environment(\.modelContext) private var context
    @State private var scanMode: ScanMode = .barcode

    @State private var lastScanKey: String?
    @State private var lastBook: Book?
    @State private var lastRawPayload: String?
    @State private var showManualEntry = false
    @State private var torchOn = false

    @State private var ocrStage: OCRStage = .awaitingTitle
    @State private var ocrTitle: String?
    @State private var ocrAuthor: String?

    var body: some View {
        ZStack {
            scannerLayer

            VStack {
                if scanMode == .barcode, let payload = lastRawPayload {
                    DetectedPayloadBadge(payload: payload, accepted: lastBook != nil)
                        .padding(.top, 8)
                }

                Spacer()

                TorchButton(isOn: $torchOn)
                    .padding(.bottom, 12)

                bottomPanel

                Picker("Modo", selection: $scanMode) {
                    ForEach(ScanMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .animation(.snappy, value: lastBook?.id)
            .animation(.snappy, value: lastRawPayload)
            .animation(.snappy, value: scanMode)
            .animation(.snappy, value: ocrStage)
        }
        .sheet(isPresented: $showManualEntry) {
            ManualISBNEntryView { isbn in
                Task { await handleBarcode(isbn: isbn, ean5: nil) }
            }
        }
        .onDisappear { torchOn = false }
        .onChange(of: scanMode) { _, _ in resetOCR() }
    }

    @ViewBuilder
    private var scannerLayer: some View {
        if !ISBNScanner.isAvailable {
            UnsupportedScannerView()
        } else {
            switch scanMode {
            case .barcode:
                ISBNScanner(
                    torchOn: $torchOn,
                    onScan: { isbn, ean5 in Task { await handleBarcode(isbn: isbn, ean5: ean5) } },
                    onRawDetect: { payload in lastRawPayload = payload }
                )
                .ignoresSafeArea()
            case .ocr:
                OCRScanner(torchOn: $torchOn) { text in
                    handleOCRTap(text)
                }
                .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private var bottomPanel: some View {
        if let book = lastBook {
            DecisionOverlay(book: book) { decision in
                book.decision = decision
                book.updatedAt = .now
                try? context.save()
                withAnimation {
                    lastBook = nil
                    resetOCR()
                }
            }
            .padding()
        } else {
            switch scanMode {
            case .barcode:
                ScanHintView(text: "Apunta a un ISBN", actionLabel: "Manual") {
                    showManualEntry = true
                }
                .padding()
            case .ocr:
                OCRPanel(
                    stage: ocrStage,
                    title: ocrTitle,
                    author: ocrAuthor,
                    onClearTitle: { ocrTitle = nil; ocrStage = .awaitingTitle },
                    onClearAuthor: { ocrAuthor = nil; ocrStage = .awaitingAuthor },
                    onCreate: { Task { await handleOCRCreate() } },
                    onReset: { resetOCR() }
                )
                .padding()
            }
        }
    }

    private func handleBarcode(isbn: String, ean5: String?) async {
        let scanKey = "isbn:" + isbn + (ean5.map { "-" + $0 } ?? "")
        guard scanKey != lastScanKey else { return }
        lastScanKey = scanKey

        let book = Book(isbn: isbn, ean5: ean5)
        context.insert(book)
        try? context.save()
        withAnimation { lastBook = book }

        // TODO: lookup metadata + pricing en background, actualizar el book.
    }

    private func handleOCRTap(_ text: String) {
        switch ocrStage {
        case .awaitingTitle:
            ocrTitle = text
            ocrStage = ocrAuthor == nil ? .awaitingAuthor : .ready
        case .awaitingAuthor:
            ocrAuthor = text
            ocrStage = .ready
        case .ready:
            // Cycle: replace title, then author, then back to title
            if ocrTitle == nil {
                ocrTitle = text
            } else if ocrAuthor == nil {
                ocrAuthor = text
            } else {
                ocrTitle = text
                ocrStage = .awaitingAuthor
                ocrAuthor = nil
            }
        }
    }

    private func handleOCRCreate() async {
        guard let title = ocrTitle, !title.isEmpty else { return }
        let authors = ocrAuthor.map { [$0] } ?? []
        let scanKey = "ocr:\(title)|\(ocrAuthor ?? "")"
        lastScanKey = scanKey

        let book = Book(title: title, authors: authors)
        context.insert(book)
        try? context.save()
        withAnimation { lastBook = book }
    }

    private func resetOCR() {
        ocrTitle = nil
        ocrAuthor = nil
        ocrStage = .awaitingTitle
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
                HStack(spacing: 6) {
                    Text(isbn)
                        .font(.system(.caption, design: .monospaced))
                    if let ean5 = book.ean5 {
                        Text("+\(ean5)")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.2), in: Capsule())
                    }
                }
                .foregroundStyle(.secondary)
            }
            Text(book.title ?? "Sin título")
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            if !book.authors.isEmpty {
                Text(book.authors.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
    let text: String
    let actionLabel: String
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "barcode.viewfinder")
            Text(text).font(.subheadline)
            Spacer()
            Button(actionLabel) { onAction() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct OCRPanel: View {
    let stage: OCRStage
    let title: String?
    let author: String?
    let onClearTitle: () -> Void
    let onClearAuthor: () -> Void
    let onCreate: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)

            slotRow(label: "Título", value: title, isActive: stage == .awaitingTitle, onClear: onClearTitle)
            slotRow(label: "Autor", value: author, isActive: stage == .awaitingAuthor, onClear: onClearAuthor)

            HStack {
                Button("Limpiar", role: .destructive, action: onReset)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
                Button("Crear libro", action: onCreate)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(title == nil)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var hint: String {
        switch stage {
        case .awaitingTitle: return "Toca el título en la cámara"
        case .awaitingAuthor: return "Toca el autor en la cámara"
        case .ready: return "Listo. Crea el libro o ajusta los campos."
        }
    }

    @ViewBuilder
    private func slotRow(label: String, value: String?, isActive: Bool, onClear: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            if let value {
                Text(value)
                    .font(.callout)
                    .lineLimit(2)
                Spacer()
                Button { onClear() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Text(isActive ? "Esperando…" : "—")
                    .font(.callout)
                    .foregroundStyle(isActive ? .primary : .secondary)
                    .italic(!isActive)
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isActive ? Color.accentColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
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
