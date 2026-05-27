import AVFoundation
import SwiftUI
import VisionKit

struct OCRScanner: UIViewControllerRepresentable {
    let onTextTap: (String) -> Void
    @Binding var torchOn: Bool

    init(torchOn: Binding<Bool>, onTextTap: @escaping (String) -> Void) {
        self._torchOn = torchOn
        self.onTextTap = onTextTap
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.onTextTap = onTextTap

        if !uiViewController.isScanning {
            do {
                try uiViewController.startScanning()
            } catch {
                print("OCRScanner.startScanning failed: \(error)")
            }
        }

        applyTorch(torchOn)
    }

    private func applyTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.userPreferredCamera,
              device.hasTorch,
              device.isTorchAvailable else { return }
        guard (device.torchMode == .on) != on else { return }
        do {
            try device.lockForConfiguration()
            if on { try device.setTorchModeOn(level: 1.0) } else { device.torchMode = .off }
            device.unlockForConfiguration()
        } catch {
            print("OCRScanner torch toggle failed: \(error)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextTap: onTextTap)
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        if uiViewController.isScanning {
            uiViewController.stopScanning()
        }
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onTextTap: (String) -> Void

        init(onTextTap: @escaping (String) -> Void) {
            self.onTextTap = onTextTap
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            guard case let .text(text) = item else { return }
            let trimmed = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTextTap(trimmed)
        }
    }
}
