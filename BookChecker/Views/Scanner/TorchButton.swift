import SwiftUI

struct TorchButton: View {
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
        .accessibilityLabel(isOn ? Text("scanner_torch_off_a11y") : Text("scanner_torch_on_a11y"))
    }
}

#Preview("Off") {
    @Previewable @State var isOn = false
    return TorchButton(isOn: $isOn)
        .padding()
        .background(Color.black)
}

#Preview("On") {
    @Previewable @State var isOn = true
    return TorchButton(isOn: $isOn)
        .padding()
        .background(Color.black)
}
