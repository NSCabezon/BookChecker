import AVFoundation
import SwiftUI
import Vision
import VisionKit

struct ISBNScanner: UIViewControllerRepresentable {
    let onScan: (String, String?) -> Void
    let onRawDetect: ((String) -> Void)?
    @Binding var torchOn: Bool

    init(
        torchOn: Binding<Bool>,
        onScan: @escaping (String, String?) -> Void,
        onRawDetect: ((String) -> Void)? = nil
    ) {
        self._torchOn = torchOn
        self.onScan = onScan
        self.onRawDetect = onRawDetect
    }

    static var isAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.ean13, .ean8, .upce]),
                .text()
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.onScan = onScan
        context.coordinator.onRawDetect = onRawDetect

        if !uiViewController.isScanning {
            do {
                try uiViewController.startScanning()
            } catch {
                print("ISBNScanner.startScanning failed: \(error)")
            }
        }

        applyTorch(torchOn, controller: uiViewController)
    }

    private func applyTorch(_ on: Bool, controller: DataScannerViewController) {
        guard let device = AVCaptureDevice.userPreferredCamera,
              device.hasTorch,
              device.isTorchAvailable else {
            print("Torch: no compatible device")
            return
        }
        guard (device.torchMode == .on) != on else { return }

        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: 1.0)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
            print("Torch set to \(on ? "ON" : "OFF")")
        } catch {
            print("Torch toggle failed: \(error)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onRawDetect: onRawDetect)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onScan: (String, String?) -> Void
        var onRawDetect: ((String) -> Void)?
        private var lastScannedISBN: String?
        private var lastScannedEAN5: String?
        private var lastScanAt: Date = .distantPast

        init(onScan: @escaping (String, String?) -> Void, onRawDetect: ((String) -> Void)?) {
            self.onScan = onScan
            self.onRawDetect = onRawDetect
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            correlate(allItems: allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            correlate(allItems: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            correlate(allItems: [item])
        }

        private func correlate(allItems: [RecognizedItem]) {
            var ean13Payload: String?
            var ean13Rect: CGRect?
            var fiveDigitTexts: [(text: String, rect: CGRect)] = []

            for item in allItems {
                switch item {
                case .barcode(let barcode):
                    guard let payload = barcode.payloadStringValue else { continue }
                    if isISBN(payload), ean13Payload == nil {
                        ean13Payload = payload
                        ean13Rect = rect(from: barcode.bounds)
                    }
                case .text(let text):
                    let raw = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    let digits = raw.filter(\.isNumber)
                    if digits.count == 5 {
                        fiveDigitTexts.append((digits, rect(from: text.bounds)))
                    }
                @unknown default:
                    continue
                }
            }

            guard let payload = ean13Payload, let bcRect = ean13Rect else { return }

            print("ISBNScanner detected payload: \(payload)")
            onRawDetect?(payload)

            let ean5 = pickAdjacentEAN5(barcodeRect: bcRect, candidates: fiveDigitTexts)
            if let ean5 {
                print("ISBNScanner detected EAN-5 add-on: \(ean5)")
            }

            guard shouldEmit(isbn: payload, ean5: ean5) else { return }
            lastScannedISBN = payload
            lastScannedEAN5 = ean5
            lastScanAt = .now
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onScan(payload, ean5)
        }

        private func rect(from bounds: RecognizedItem.Bounds) -> CGRect {
            let xs = [bounds.topLeft.x, bounds.topRight.x, bounds.bottomLeft.x, bounds.bottomRight.x]
            let ys = [bounds.topLeft.y, bounds.topRight.y, bounds.bottomLeft.y, bounds.bottomRight.y]
            let minX = xs.min() ?? 0
            let maxX = xs.max() ?? 0
            let minY = ys.min() ?? 0
            let maxY = ys.max() ?? 0
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }

        /// EAN-5 add-on prints to the right of the EAN-13, at roughly the same vertical band,
        /// within roughly one barcode-width of the right edge.
        private func pickAdjacentEAN5(barcodeRect: CGRect, candidates: [(text: String, rect: CGRect)]) -> String? {
            let verticalTolerance = barcodeRect.height
            let maxHorizontalGap = barcodeRect.width
            var best: (text: String, distance: CGFloat)?

            for candidate in candidates {
                let isRight = candidate.rect.midX > barcodeRect.maxX - barcodeRect.width * 0.1
                let verticallyAligned = abs(candidate.rect.midY - barcodeRect.midY) <= verticalTolerance
                let gap = candidate.rect.minX - barcodeRect.maxX
                let withinReach = gap < maxHorizontalGap

                guard isRight, verticallyAligned, withinReach else { continue }

                let distance = max(0, gap)
                if best == nil || distance < best!.distance {
                    best = (candidate.text, distance)
                }
            }
            return best?.text
        }

        private func isISBN(_ value: String) -> Bool {
            let digits = value.filter(\.isNumber)
            return digits.count == 13 || digits.count == 10
        }

        private func shouldEmit(isbn: String, ean5: String?) -> Bool {
            if isbn == lastScannedISBN,
               ean5 == lastScannedEAN5,
               Date.now.timeIntervalSince(lastScanAt) < 2 {
                return false
            }
            return true
        }
    }
}
