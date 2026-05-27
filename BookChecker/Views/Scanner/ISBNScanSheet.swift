import SwiftUI

struct ISBNScanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var torchOn = false
    @State private var lastRawPayload: String?
    @State private var capturedISBN: String?
    @State private var capturedEAN5: String?
    let onScan: (String, String?) -> Void

    var body: some View {
        ZStack {
            if ISBNScanner.isAvailable {
                ISBNScanner(
                    torchOn: $torchOn,
                    onScan: { isbn, ean5 in
                        guard capturedISBN == nil else { return }
                        capturedISBN = isbn
                        capturedEAN5 = ean5
                    },
                    onRawDetect: { payload in lastRawPayload = payload }
                )
                .ignoresSafeArea()
            } else {
                UnsupportedScannerView()
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 12)
                }

                if let payload = lastRawPayload, capturedISBN == nil {
                    DetectedPayloadBadge(payload: payload, accepted: false)
                        .padding(.top, 4)
                }

                Spacer()

                TorchButton(isOn: $torchOn)
                    .padding(.bottom, 12)

                if let isbn = capturedISBN {
                    capturedCard(isbn: isbn, ean5: capturedEAN5)
                        .padding()
                }
            }
            .animation(.snappy, value: capturedISBN)
        }
        .onDisappear { torchOn = false }
    }

    @ViewBuilder
    private func capturedCard(isbn: String, ean5: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Detectado")
                    .font(.headline)
            }
            HStack(spacing: 6) {
                Text(isbn)
                    .font(.system(.callout, design: .monospaced))
                if let ean5 {
                    Text("+\(ean5)")
                        .font(.system(.callout, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tint.opacity(0.2), in: Capsule())
                }
            }
            HStack(spacing: 10) {
                Button("Reintentar", role: .cancel) {
                    capturedISBN = nil
                    capturedEAN5 = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Spacer()
                Button("Confirmar") {
                    onScan(isbn, ean5)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ISBNScanSheet { _, _ in }
}
