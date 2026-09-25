import FoldableGrid
import SwiftUI

/// `FoldableGrid(columns: .adaptive(minimum:), crossing: .flow)`: a contact sheet. Unfolded it is
/// the `LazyVGrid` it replaces. With a fold down the screen (book) each half gets its own columns;
/// with one across it (tabletop) the rows flow over the crease as they scroll and settle either
/// side of it — so no photo is folded in half either way.
struct PhotosScreen: View {
    @State private var flowCrossing = true
    var body: some View {
        NavigationStack {
            ScrollView {
                FoldableGrid(
                    columns: .adaptive(minimum: 104),
                    spacing: 3,
                    rowSpacing: 3,
                    alignment: .center,
                    crossing: flowCrossing ? .avoid : .ignore
                ) {
                    ForEach(1...120, id: \.self) { index in
                        Photo(index: index)
                    }
                }
            }
            .navigationTitle("Photos")
            .toolbar {
                Button {
                    withAnimation {
                        flowCrossing.toggle()
                    }
                } label: {
                    Image(systemName: "scroll.fill")
                }
            }
        }
    }
}

private struct Photo: View {
    let index: Int

    var body: some View {
        Rectangle()
            .fill(Palette.colour(index).gradient)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(systemName: Palette.symbol(index))
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.85))
            }
    }
}

#Preview("Photos") {
    PhotosScreen()
}
