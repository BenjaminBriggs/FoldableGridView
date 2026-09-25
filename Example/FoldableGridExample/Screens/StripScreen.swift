import FoldableGrid
import SwiftUI

/// `FoldableGrid(rows:)`: a grid that scrolls sideways, a `LazyHGrid` underneath. Propped on a
/// table (a fold across the screen), its rows part either side of the crease. Held like a book (a
/// fold down it), its columns scroll past the crease as a plain grid and, when scrolling stops,
/// part around it.
struct StripScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                FoldableGrid(
                    rows: .adaptive(minimum: 150),
                    spacing: 8,
                    columnSpacing: 8,
                    alignment: .center
                ) {
                    ForEach(1...60, id: \.self) { index in
                        Tile(index: index)
                    }
                }
                .padding()
            }
            .navigationTitle("Strip")
        }
    }
}

private struct Tile: View {
    let index: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Palette.colour(index).gradient)
            .frame(width: 150)
            .frame(maxHeight: .infinity)
            .overlay {
                Image(systemName: Palette.symbol(index))
                    .font(.title)
                    .foregroundStyle(.white)
            }
    }
}

#Preview("Strip") {
    StripScreen()
}
