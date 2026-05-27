import SwiftUI
import VisionKit

struct ISBNScanner: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        private var lastScanned: String?
        private var lastScanAt: Date = .distantPast

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for item in addedItems {
                guard case let .barcode(barcode) = item,
                      let payload = barcode.payloadStringValue,
                      isISBN(payload),
                      shouldEmit(payload) else { continue }
                lastScanned = payload
                lastScanAt = .now
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onScan(payload)
            }
        }

        private func isISBN(_ value: String) -> Bool {
            let digits = value.filter(\.isNumber)
            return digits.count == 13 || digits.count == 10
        }

        private func shouldEmit(_ value: String) -> Bool {
            if value == lastScanned, Date.now.timeIntervalSince(lastScanAt) < 2 { return false }
            return true
        }
    }
}
