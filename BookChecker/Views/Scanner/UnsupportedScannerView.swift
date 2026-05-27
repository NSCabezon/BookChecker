import SwiftUI

struct UnsupportedScannerView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                Text("scanner_unsupported_title")
                    .font(.headline)
                Text("scanner_unsupported_message")
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
