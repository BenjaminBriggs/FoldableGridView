#if DEBUG
import SwiftUI

/// Stand-ins for the previews: something with a colour and a number, sized like the thing each view
/// is for, so a preview reads as a calendar, a chart or a wall of cards rather than as boxes.
enum PreviewSample {
    static let colours: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown,
    ]

    static func colour(_ index: Int) -> Color {
        colours[index % colours.count]
    }
}

/// A card in a grid: `FoldableGrid`'s cell.
struct PreviewCard: View {
    let index: Int
    var height: CGFloat = 120

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(PreviewSample.colour(index).gradient)
            .frame(height: height)
            .overlay(alignment: .bottomLeading) {
                Text("Card \(index)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(12)
            }
    }
}

#endif
