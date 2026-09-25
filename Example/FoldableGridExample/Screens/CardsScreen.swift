import FoldableGrid
import SwiftUI

/// `FoldableGrid` for cards: an adaptive wall, and a fixed two-up list. Folded, cards keep the
/// fold's margins clear as well as the fold, so none of them hugs the crease — and a fixed count is
/// shared between the halves by their widths.
struct CardsScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ADAPTIVE, 260PT MINIMUM")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    FoldableGrid(
                        columns: .adaptive(minimum: 260),
                        spacing: 12,
                        rowSpacing: 12
                    ) {
                        ForEach(1...6, id: \.self) { index in
                            Card(index: index)
                        }
                    }
                    Text("TWO COLUMNS")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)
                    FoldableGrid(
                        columns: .count(2),
                        spacing: 8,
                        rowSpacing: 8
                    ) {
                        ForEach(7...12, id: \.self) { index in
                            Row(index: index)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Cards")
        }
    }
}

private struct Card: View {
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Palette.colour(index).gradient)
                .frame(height: 140)
                .overlay {
                    Image(systemName: Palette.symbol(index))
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text("Card \(index)")
                    .font(.headline)
                Text("A card is too big to sit on a crease.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct Row: View {
    let index: Int

    var body: some View {
        HStack {
            Circle()
                .fill(Palette.colour(index).gradient)
                .frame(width: 32, height: 32)
            Text("Row \(index)")
            Spacer()
        }
        .padding(10)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: 10)
        )
    }
}

#Preview("Cards") {
    CardsScreen()
}
