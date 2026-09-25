import CoreGraphics

/// The arithmetic behind `FoldableRow` and `FoldableGrid`, kept free of SwiftUI so it can be tested
/// on its own.
enum FoldMath {
    /// Where `count` equal cells go across `width`. With a `band`, the cells before it share the
    /// width before it and the rest the width after it — each side's cells equal among themselves,
    /// each side getting the share of the cells its width earns, and never an empty side while
    /// there are two cells. Ranges are in the row's own coordinates.
    static func cells(
        count: Int,
        width: CGFloat,
        spacing: CGFloat,
        band: ClosedRange<CGFloat>?
    ) -> [ClosedRange<CGFloat>] {
        guard count > 0 else { return [] }
        guard let band, count > 1 else {
            return even(
                count: count,
                from: 0,
                width: width,
                spacing: spacing
            )
        }
        let before = band.lowerBound
        let after = width - band.upperBound
        guard before > 0, after > 0 else {
            return even(
                count: count,
                from: 0,
                width: width,
                spacing: spacing
            )
        }
        let first = share(of: count, before: before, after: after)
        return even(
            count: first,
            from: 0,
            width: before,
            spacing: spacing
        )
            + even(
                count: count - first,
                from: band.upperBound,
                width: after,
                spacing: spacing
            )
    }

    /// How many of `count` go before the fold: proportional to the widths, at least one each side.
    static func share(
        of count: Int,
        before: CGFloat,
        after: CGFloat
    ) -> Int {
        guard count > 1 else { return count }
        let proportional = Int(
            (Double(count) * before / (before + after))
                .rounded()
        )
        return min(max(proportional, 1), count - 1)
    }

    /// How many columns of at least `minimum` fit across `width`, never fewer than one.
    static func fitting(
        minimum: CGFloat,
        spacing: CGFloat,
        in width: CGFloat
    ) -> Int {
        max(1, Int((width + spacing) / (minimum + spacing)))
    }

    /// A grid's columns either side of a fold: fixed widths that fill each side exactly, with the
    /// gap between the two sides as the spacing after the last leading column. The widths and
    /// spacings sum to `width`, so a lazy grid places them without centring anything.
    static func columns(
        leadingCount: Int,
        trailingCount: Int,
        width: CGFloat,
        spacing: CGFloat,
        gap: ClosedRange<CGFloat>
    ) -> [(width: CGFloat, spacing: CGFloat)] {
        let leading = fixed(
            count: leadingCount,
            across: gap.lowerBound,
            spacing: spacing
        )
        let trailing = fixed(
            count: trailingCount,
            across: width - gap.upperBound,
            spacing: spacing
        )
        let fold = gap.upperBound - gap.lowerBound
        let gapped = leading.enumerated()
            .map { index, column in
                index == leading.count - 1 ? (column.width, fold) : column
            }
        return gapped + trailing
    }

    /// How far a flowing grid moves a row, in a scroll view a fold runs across (tabletop).
    ///
    /// Rows are equal height, `height + spacing` apart, and `top` is where this row would be in the
    /// window without the flow. The fold, with its margins, is `fold`, also in the window.
    ///
    /// The fold ends up between two rows. The row it would cut is either **held** just above it —
    /// it and every row above nudged up by how far it reaches in — or **sent** just below — it and
    /// every row below moved past the fold. Held while less than half of it has reached the fold,
    /// sent once more than half has. With a `window` (a fraction of a row's height) it swaps over
    /// that stretch, eased; with none it is simply one or the other, which is what `FoldableGrid`
    /// uses at rest. Every row's movement grows with its position, so rows only ever move apart,
    /// never over each other.
    static func flowShift(
        top: CGFloat,
        height: CGFloat,
        spacing: CGFloat,
        fold: ClosedRange<CGFloat>,
        window: CGFloat = 0.3
    ) -> CGFloat {
        let gap = fold.upperBound - fold.lowerBound
        let pitch = height + spacing
        guard height > 0, pitch > 0, gap > 0 else { return 0 }
        // How many rows above the row nearest the fold this one is — the nearest being the lowest
        // row whose top is at or above the fold's top. Negative below it.
        let rowsAbove = ((fold.lowerBound - top) / pitch)
            .rounded(.down)
        let nearest = top + rowsAbove * pitch
        let reach = nearest + height - fold.lowerBound
        guard reach > 0 else {
            // The fold falls in the spacing between two rows: the rows below it open up the rest.
            guard rowsAbove < 0 else { return 0 }
            return max(0, fold.upperBound - (nearest + pitch))
        }
        let held = rowsAbove >= 0 ? -reach : max(0, gap - reach - spacing)
        let sent = rowsAbove > 0 ? 0 : gap + height - reach
        guard window > 0 else { return reach < height / 2 ? held : sent }
        let start = height * (0.5 - window / 2)
        let end = height * (0.5 + window / 2)
        let progress = min(max((reach - start) / (end - start), 0), 1)
        let eased = progress * progress * (3 - 2 * progress)
        return held + (sent - held) * eased
    }

    private static func fixed(
        count: Int,
        across width: CGFloat,
        spacing: CGFloat
    ) -> [(width: CGFloat, spacing: CGFloat)] {
        guard count > 0 else { return [] }
        let gaps = spacing * CGFloat(count - 1)
        let size = max(1, (width - gaps) / CGFloat(count))
        return Array(repeating: (size, spacing), count: count)
    }

    private static func even(
        count: Int,
        from start: CGFloat,
        width: CGFloat,
        spacing: CGFloat
    ) -> [ClosedRange<CGFloat>] {
        guard count > 0 else { return [] }
        let gaps = spacing * CGFloat(count - 1)
        let cell = max(0, (width - gaps) / CGFloat(count))
        return (0..<count)
            .map { index in
                let x = start + CGFloat(index) * (cell + spacing)
                return x...(x + cell)
            }
    }
}
