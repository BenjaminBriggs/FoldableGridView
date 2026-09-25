import SwiftUI

/// Equal cells across the width — a week of days, a row of bars, a toolbar of buttons — that part
/// at the fold. With a fold running down it, the cells before it share the leading half and the
/// rest the trailing half, so nothing stands on the crease; otherwise it is an `HStack` of equal
/// cells.
///
/// The halves are rarely equal (a camera column takes one edge), so neither are the cells either
/// side; each side's cells are equal among themselves. Cells stand as close to the fold as its band
/// — for something the size of a card, use `FoldableGrid`, which keeps the fold's margins clear
/// too.
public struct FoldableRow<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat
    let content: Content

    @State private var fold = FoldGeometry()

    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        FoldRowLayout(
            alignment: alignment,
            spacing: spacing,
            band: fold.band
        ) {
            content
        }
        .foldGeometry($fold)
    }
}

private struct FoldRowLayout: Layout {
    let alignment: VerticalAlignment
    let spacing: CGFloat
    let band: ClosedRange<CGFloat>?

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width =
            proposal.width
            ?? subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width }
        let cells = FoldMath.cells(
            count: subviews.count,
            width: width,
            spacing: spacing,
            band: band
        )
        let height = zip(subviews, cells)
            .map { subview, cell in
                subview.sizeThatFits(
                    ProposedViewSize(
                        width: cell.upperBound - cell.lowerBound,
                        height: proposal.height
                    )
                )
                .height
            }
            .max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let cells = FoldMath.cells(
            count: subviews.count,
            width: bounds.width,
            spacing: spacing,
            band: band
        )
        for (subview, cell) in zip(subviews, cells) {
            let width = cell.upperBound - cell.lowerBound
            let size = subview.sizeThatFits(
                ProposedViewSize(
                    width: width,
                    height: bounds.height
                )
            )
            let y =
                switch alignment {
                case .top: bounds.minY
                case .bottom: bounds.maxY - size.height
                default: bounds.midY - size.height / 2
                }
            subview.place(
                at: CGPoint(x: bounds.minX + cell.lowerBound, y: y),
                proposal: ProposedViewSize(
                    width: width,
                    height: size.height
                )
            )
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("A week of bars", traits: .landscapeLeft) {
    let values: [CGFloat] = [0.5, 0.8, 0.35, 0.9, 0.6, 1, 0.3]
    FoldableRow(alignment: .bottom, spacing: 8) {
        ForEach(Array(values.enumerated()), id: \.offset) { index, value in
            RoundedRectangle(cornerRadius: 6)
                .fill(PreviewSample.colour(index).gradient)
                .frame(height: 140 * value)
                .frame(maxWidth: .infinity)
        }
    }
    .frame(height: 160)
    .padding()
}

#Preview("A week", traits: .landscapeLeft) {
    let days = ["M", "T", "W", "T", "F", "S", "S"]
    VStack(spacing: 8) {
        FoldableRow(spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                Text(day)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        ForEach(0..<4, id: \.self) { week in
            FoldableRow(spacing: 4) {
                ForEach(1...7, id: \.self) { day in
                    Text("\(week * 7 + day)")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            .quaternary,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
            }
        }
    }
    .padding()
}
#endif
