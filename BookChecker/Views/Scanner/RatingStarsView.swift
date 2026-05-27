import SwiftUI

struct RatingStarsView: View {
    let rating: Double
    let count: Int?
    let compact: Bool

    init(rating: Double, count: Int? = nil, compact: Bool = false) {
        self.rating = rating
        self.count = count
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 4) {
            if compact {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", rating))
                    .font(.caption2)
                if let count {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(0..<5) { index in
                    Image(systemName: starSymbol(for: index))
                        .foregroundStyle(.yellow)
                }
                Text(String(format: "%.1f", rating))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                if let count {
                    Text("(\(count) reseñas)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func starSymbol(for index: Int) -> String {
        let threshold = Double(index)
        if rating >= threshold + 0.75 { return "star.fill" }
        if rating >= threshold + 0.25 { return "star.leadinghalf.filled" }
        return "star"
    }
}

#Preview("Full") {
    VStack(spacing: 12) {
        RatingStarsView(rating: 4.3, count: 287)
        RatingStarsView(rating: 2.7, count: 12)
        RatingStarsView(rating: 5.0, count: 1)
    }
    .padding()
}

#Preview("Compact") {
    RatingStarsView(rating: 4.3, count: 287, compact: true)
        .padding()
}
