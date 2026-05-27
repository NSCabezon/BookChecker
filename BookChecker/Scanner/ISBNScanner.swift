import AVFoundation
import SwiftUI
import Vision
import VisionKit

struct ISBNScanner: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onRawDetect: ((String) -> Void)?
    @Binding var torchOn: Bool

    init(
        torchOn: Binding<Bool>,
        onScan: @escaping (String) -> Void,
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
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
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
        var onScan: (String) -> Void
        var onRawDetect: ((String) -> Void)?
        private var lastScanned: String?
        private var lastScanAt: Date = .distantPast

        init(onScan: @escaping (String) -> Void, onRawDetect: ((String) -> Void)?) {
            self.onScan = onScan
            self.onRawDetect = onRawDetect
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            process(items: addedItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            process(items: updatedItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            process(items: [item])
        }

        private func process(items: [RecognizedItem]) {
            for item in items {
                guard case let .barcode(barcode) = item,
                      let payload = barcode.payloadStringValue else { continue }
                print("ISBNScanner detected payload: \(payload)")
                onRawDetect?(payload)
                guard isISBN(payload), shouldEmit(payload) else { continue }
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
