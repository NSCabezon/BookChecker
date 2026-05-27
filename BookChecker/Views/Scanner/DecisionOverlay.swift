import SwiftUI
import SwiftData

struct DecisionOverlay: View {
    let book: Book
    let onDecide: (BookDecision) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var stagedDecision: BookDecision?

    private let threshold: CGFloat = 60

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

            hintRow

            HStack(spacing: 10) {
                Button("Donate") { commit(.donate) }
                Button("Pending") { commit(.pending) }
                Button("Sell") { commit(.sell) }
                Button("Keep") { commit(.keep) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .offset(dragOffset)
        .scaleEffect(stagedDecision != nil ? 1.03 : 1)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.7), value: dragOffset)
        .animation(.snappy, value: stagedDecision)
        .gesture(dragGesture)
        .onTapGesture(count: 2) { commit(.pending) }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Desliza arriba para guardar, abajo para donar, izquierda o derecha para vender, doble toque para dejar pendiente.")
        .accessibilityAction(named: "Keep") { commit(.keep) }
        .accessibilityAction(named: "Sell") { commit(.sell) }
        .accessibilityAction(named: "Donate") { commit(.donate) }
        .accessibilityAction(named: "Pending") { commit(.pending) }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var hintRow: some View {
        if let staged = stagedDecision {
            Text("Suelta para \(label(for: staged))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tint)
        } else {
            HStack(spacing: 12) {
                hintChip(symbol: "arrow.up", label: "Keep")
                hintChip(symbol: "arrow.down", label: "Donate")
                hintChip(symbol: "arrow.left.and.right", label: "Sell")
                hintChip(symbol: "hand.tap", label: "2× Pending")
            }
            .foregroundStyle(.secondary)
        }
    }

    private func hintChip(symbol: String, label: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
            Text(label)
        }
        .font(.caption2)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragOffset = value.translation
                stagedDecision = decision(for: value.translation)
            }
            .onEnded { value in
                if let decided = decision(for: value.translation) {
                    commit(decided)
                }
                dragOffset = .zero
                stagedDecision = nil
            }
    }

    private func decision(for translation: CGSize) -> BookDecision? {
        let x = translation.width
        let y = translation.height
        guard max(abs(x), abs(y)) >= threshold else { return nil }
        if abs(x) > abs(y) { return .sell }
        return y < 0 ? .keep : .donate
    }

    private func commit(_ decision: BookDecision) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onDecide(decision)
    }

    private func label(for decision: BookDecision) -> String {
        switch decision {
        case .keep: return "Keep"
        case .sell: return "Sell"
        case .donate: return "Donate"
        case .pending: return "Pending"
        }
    }
}

#Preview {
    let container = PreviewSamples.inMemoryContainer(with: [PreviewSamples.bookPending])
    return DecisionOverlay(book: PreviewSamples.bookPending) { _ in }
        .padding()
        .background(Color.gray)
        .modelContainer(container)
}
