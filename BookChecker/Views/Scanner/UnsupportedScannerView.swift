import SwiftUI

struct UnsupportedScannerView: View {
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

#Preview {
    UnsupportedScannerView()
}
