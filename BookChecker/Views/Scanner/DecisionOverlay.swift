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
            if let t = book.title, !t.isEmpty {
                Text(t)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else {
                Text("common_no_title")
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            if !book.authors.isEmpty {
                Text(book.authors.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            hintRow

            HStack(spacing: 10) {
                Button(action: { commit(.donate) }) { Text(BookDecision.donate.displayKey) }
                Button(action: { commit(.pending) }) { Text(BookDecision.pending.displayKey) }
                Button(action: { commit(.sell) }) { Text(BookDecision.sell.displayKey) }
                Button(action: { commit(.keep) }) { Text(BookDecision.keep.displayKey) }
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
        .accessibilityHint(Text("overlay_a11y_hint"))
        .accessibilityAction(named: Text(BookDecision.keep.displayKey)) { commit(.keep) }
        .accessibilityAction(named: Text(BookDecision.sell.displayKey)) { commit(.sell) }
        .accessibilityAction(named: Text(BookDecision.donate.displayKey)) { commit(.donate) }
        .accessibilityAction(named: Text(BookDecision.pending.displayKey)) { commit(.pending) }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var hintRow: some View {
        if let staged = stagedDecision {
            Text(releaseKey(for: staged))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tint)
        } else {
            HStack(spacing: 12) {
                hintChip(symbol: "arrow.up", labelKey: BookDecision.keep.displayKey)
                hintChip(symbol: "arrow.down", labelKey: BookDecision.donate.displayKey)
                hintChip(symbol: "arrow.left.and.right", labelKey: BookDecision.sell.displayKey)
                hintChip(symbol: "hand.tap", labelKey: "overlay_hint_pending_doubletap")
            }
            .foregroundStyle(.secondary)
        }
    }

    private func hintChip(symbol: String, labelKey: LocalizedStringKey) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
            Text(labelKey)
        }
        .font(.caption2)
    }

    private func releaseKey(for decision: BookDecision) -> LocalizedStringKey {
        switch decision {
        case .keep: return "overlay_release_for_keep"
        case .sell: return "overlay_release_for_sell"
        case .donate: return "overlay_release_for_donate"
        case .pending: return "overlay_release_for_pending"
        }
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
}

#Preview {
    let container = PreviewSamples.inMemoryContainer(with: [PreviewSamples.bookPending])
    return DecisionOverlay(book: PreviewSamples.bookPending) { _ in }
        .padding()
        .background(Color.gray)
        .modelContainer(container)
}
