import SwiftUI

/// A lazy grid of cards whose lines part at the fold. Unfolded — flat, closed, not a foldable, or
/// before iOS 27.1 — it is exactly the grid it replaces.
///
/// It scrolls one way and its lines run the other, so each fold does one of two things to it:
/// - A fold **along** its lines splits them statically. A vertical grid (`columns:`) with a fold
///   down it (book) gives each half columns of its own, sized to that half; a horizontal grid
///   (`rows:`) does the same with rows for a fold across it (tabletop). The fold and its margins
///   are the gap. A plain lazy grid divides the whole width evenly, and the card nearest the middle
///   is bent over the crease.
/// - A fold **across** its lines is one they scroll past: rows under a tabletop fold, columns under
///   a book fold. `crossing` decides what they do — see `Crossing`.
public struct FoldableGrid<Content: View>: View {
    /// The lines of the grid: its columns when it scrolls vertically, its rows when it scrolls
    /// sideways.
    public enum Columns: Sendable {
        /// As many as fit at this minimum width (or height) — `GridItem(.adaptive(minimum:))`.
        case adaptive(minimum: CGFloat)
        /// Exactly this many, sharing the space — `count` × `GridItem(.flexible())`. Folded, the
        /// count is shared between the halves by their sizes.
        case count(Int)
    }

    public typealias Rows = Columns

    /// What the lines do when a fold runs across them as they scroll.
    public enum Crossing: Sendable {
        /// Nothing: they scroll over the fold like any scrolling content.
        case ignore
        /// Content 
        case avoid
    }

    let axis: Axis
    let lines: Columns
    /// Between cells within a line: `GridItem.spacing`.
    let lineSpacing: CGFloat
    /// Between the lines themselves, in the direction the grid scrolls.
    let stackSpacing: CGFloat
    let alignment: Alignment
    let crossing: Crossing
    let content: Content

    @State private var fold = FoldGeometry()
    /// The longest cell seen in the scrolling direction, for the room a flowing grid leaves at its
    /// end.
    @State private var lineLength: CGFloat = 0
    /// Whether the grid has come to rest, and so has parted around the fold. Scrolling clears it.
    @State private var isResting = false
    /// Waits for the grid to stop moving before it parts.
    @State private var settling: Task<Void, Never>?

    /// A grid that scrolls vertically: a `LazyVGrid`.
    ///
    /// - Parameters:
    ///   - spacing: Between columns.
    ///   - rowSpacing: Between rows.
    ///   - alignment: Of each cell in its column, as `GridItem.alignment`.
    ///   - crossing: What rows do as they scroll past a fold across the grid (tabletop).
    public init(
        columns: Columns,
        spacing: CGFloat = 8,
        rowSpacing: CGFloat = 8,
        alignment: Alignment = .top,
        crossing: Crossing = .avoid,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = .vertical
        self.lines = columns
        self.lineSpacing = spacing
        self.stackSpacing = rowSpacing
        self.alignment = alignment
        self.crossing = crossing
        self.content = content()
    }

    /// A grid that scrolls horizontally: a `LazyHGrid`. Put it in `ScrollView(.horizontal)`.
    ///
    /// - Parameters:
    ///   - spacing: Between rows.
    ///   - columnSpacing: Between columns.
    ///   - alignment: Of each cell in its row, as `GridItem.alignment`.
    ///   - crossing: What columns do as they scroll past a fold down the grid (book).
    public init(
        rows: Rows,
        spacing: CGFloat = 8,
        columnSpacing: CGFloat = 8,
        alignment: Alignment = .leading,
        crossing: Crossing = .avoid,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = .horizontal
        self.lines = rows
        self.lineSpacing = spacing
        self.stackSpacing = columnSpacing
        self.alignment = alignment
        self.crossing = crossing
        self.content = content()
    }

    private var isVertical: Bool { axis == .vertical }

    /// The fold the lines scroll past, while the grid flows around one — in window coordinates.
    private var flowingFold: ClosedRange<CGFloat>? {
        guard crossing == .avoid else { return nil }
        return isVertical ? fold.across : fold.down
    }

    /// The fold along the lines, with its margins, in the grid's own coordinates; and how long the
    /// grid is across its lines.
    private var split: (clear: ClosedRange<CGFloat>, length: CGFloat)? {
        isVertical
            ? fold.clearance.map { ($0, fold.width) }
            : fold.acrossClearance.map { ($0, fold.height) }
    }

    public var body: some View {
        grid
            // The lines past a fold are drawn up to a fold and a line further on than they are laid
            // out; room for that at the end, so the last of them can still be scrolled to.
            .padding(
                isVertical ? .bottom : .trailing,
                flowingFold.map { $0.upperBound - $0.lowerBound + lineLength }
                    ?? 0
            )
            // Measured on the space the grid is offered, never on the grid: once its lines are
            // sized, a lazy grid is as big as they add up to, and the lines are worked out from the
            // size — so measuring the grid fed each layout into the next one's size. (Seen on the
            // Duo: the trailing column ran 25pt past the page into the camera column.)
            .frame(
                maxWidth: isVertical ? .infinity : nil,
                maxHeight: isVertical ? nil : .infinity,
                alignment: .topLeading
            )
            .foldGeometry($fold)
            // Where the grid is in the window: it changes while the grid scrolls, and stops when it
            // rests. The parting is only drawn, so it never moves this — no loop.
            .onGeometryChange(for: CGFloat.self) { proxy in
                let frame = proxy.frame(in: .global)
                return isVertical ? frame.minY : frame.minX
            } action: { _ in
                guard flowingFold != nil else { return }
                moved()
            }
            .onChange(of: flowingFold) { _, newValue in
                if newValue == nil {
                    settling?.cancel()
                    isResting = false
                } else {
                    moved()
                }
            }
    }

    @ViewBuilder private var grid: some View {
        if isVertical {
            LazyVGrid(
                columns: items,
                spacing: stackSpacing
            ) {
                cells
            }
        } else {
            LazyHGrid(
                rows: items,
                spacing: stackSpacing
            ) {
                cells
            }
        }
    }

    /// Cell by cell: a modifier on the caller's `ForEach` from out here does not reliably reach
    /// each cell of a lazy grid — on the Duo one collapsed the grid to a single column, and another
    /// moved nothing — so the grid takes the cells apart and gives each its own.
    private var cells: some View {
        ForEach(subviews: content) { cell in
            cell
                .modifier(
                    FlowAcrossFold(
                        axis: axis,
                        fold: isResting ? flowingFold : nil,
                        spacing: stackSpacing,
                        lineLength: $lineLength
                    )
                )
        }
    }

    /// The grid moved: close any gap as it goes, and part again once it has been still for a
    /// moment.
    private func moved() {
        if isResting {
            withAnimation(.smooth(duration: 0.25)) {
                isResting = false
            }
        }
        settling?.cancel()
        settling = Task {
            try? await Task.sleep(for: .milliseconds(120))
            guard Task.isCancelled == false else { return }
            withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
                isResting = true
            }
        }
    }

    private var items: [GridItem] {
        guard let split else { return unfolded }
        let before = split.clear.lowerBound
        let after = split.length - split.clear.upperBound
        let counts = counts(before: before, after: after)
        return FoldMath.columns(
            leadingCount: counts.0,
            trailingCount: counts.1,
            width: split.length,
            spacing: lineSpacing,
            gap: split.clear
        )
        // Flexible up to the size worked out, never fixed at it. With the size right they come out
        // exactly that big; with a stale one — a rotation passes through sizes the screen never
        // settles on — fixed lines made the grid that big, its frame reported the size back, and
        // the grid stayed bigger than the screen (seen on the Duo, portrait to landscape). Flexible
        // lines fit the space they are offered, and the next measurement puts them right.
        .map { line in
            GridItem(
                isVertical
                    ? .flexible(
                        minimum: 1,
                        maximum: line.width
                    )
                    : .fixed(line.width),
                spacing: line.spacing,
                alignment: alignment
            )
        }
    }

    /// How many lines each half gets: as many as fit at the minimum, or the count shared by size.
    private func counts(before: CGFloat, after: CGFloat) -> (Int, Int) {
        switch lines {
        case .adaptive(let minimum):
            let leading = FoldMath.fitting(
                minimum: minimum,
                spacing: lineSpacing,
                in: before
            )
            let trailing = FoldMath.fitting(
                minimum: minimum,
                spacing: lineSpacing,
                in: after
            )
            return (leading, trailing)
        case .count(let count):
            let leading = FoldMath.share(
                of: count,
                before: before,
                after: after
            )
            return (leading, count - leading)
        }
    }

    private var unfolded: [GridItem] {
        switch lines {
        case .adaptive(let minimum):
            [
                GridItem(
                    .adaptive(minimum: minimum),
                    spacing: lineSpacing,
                    alignment: alignment
                )
            ]
        case .count(let count):
            Array(
                repeating: GridItem(
                    .flexible(),
                    spacing: lineSpacing,
                    alignment: alignment
                ),
                count: max(count, 1)
            )
        }
    }
}

/// Moves each cell of a flowing grid by `FoldMath.flowShift` for where its line is now — a visual
/// effect, so it follows the scroll every frame without laying anything out again. Down for a
/// vertical grid, along for a horizontal one.
private struct FlowAcrossFold: ViewModifier {
    let axis: Axis
    /// The fold to part around — nil while the grid scrolls, or when it is not flowing.
    let fold: ClosedRange<CGFloat>?
    let spacing: CGFloat
    @Binding var lineLength: CGFloat

    /// Always applied, the offset zero when there is nothing to part around: a modifier that came
    /// and went would give every cell a new identity, and the gap would snap rather than open and
    /// close.
    func body(content: Content) -> some View {
        content
            .visualEffect { effect, proxy in
                let frame = proxy.frame(in: .global)
                let vertical = axis == .vertical
                let shift =
                    fold.map { fold in
                        FoldMath.flowShift(
                            top: vertical ? frame.minY : frame.minX,
                            height: vertical ? frame.height : frame.width,
                            spacing: spacing,
                            fold: fold,
                            window: 0
                        )
                    } ?? 0
                return effect.offset(
                    x: vertical ? 0 : shift,
                    y: vertical ? shift : 0
                )
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                axis == .vertical ? proxy.size.height : proxy.size.width
            } action: { newValue in
                lineLength = max(lineLength, newValue)
            }
    }
}

// MARK: - Previews

#Preview("Adaptive cards", traits: .landscapeLeft) {
    ScrollView {
        FoldableGrid(
            columns: .adaptive(minimum: 240),
            spacing: 12,
            rowSpacing: 12
        ) {
            ForEach(1...9, id: \.self) { index in
                PreviewCard(index: index)
            }
        }
        .padding()
    }
}

#Preview("Photos", traits: .landscapeLeft) {
    ScrollView {
        FoldableGrid(
            columns: .adaptive(minimum: 100),
            spacing: 4,
            rowSpacing: 4,
            alignment: .center
        ) {
            ForEach(1...30, id: \.self) { index in
                PreviewCard(index: index, height: 100)
            }
        }
        .padding()
    }
}

#Preview("Two columns", traits: .landscapeLeft) {
    ScrollView {
        FoldableGrid(
            columns: .count(2),
            spacing: 8,
            rowSpacing: 8
        ) {
            ForEach(1...6, id: \.self) { index in
                PreviewCard(index: index, height: 80)
            }
        }
        .padding()
    }
}

#Preview("Photos flowing over a tabletop fold") {
    ScrollView {
        FoldableGrid(
            columns: .adaptive(minimum: 100),
            spacing: 4,
            rowSpacing: 4,
            alignment: .center,
            crossing: .avoid
        ) {
            ForEach(1...40, id: \.self) { index in
                PreviewCard(index: index, height: 100)
            }
        }
        .padding()
    }
}

#Preview("A horizontal strip", traits: .landscapeLeft) {
    ScrollView(.horizontal) {
        FoldableGrid(
            rows: .count(2),
            spacing: 8,
            columnSpacing: 8
        ) {
            ForEach(1...24, id: \.self) { index in
                PreviewCard(index: index, height: 120)
                    .frame(width: 140)
            }
        }
        .padding()
    }
}
