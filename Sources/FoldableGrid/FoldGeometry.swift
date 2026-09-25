import CoreGraphics

/// A fold as a reserved region reports it: its frame and the margins it asks to be kept clear
/// either side, in the coordinates of the view that asked.
public struct Fold: Equatable, Sendable {
    public var frame: CGRect
    public var leadingMargin: CGFloat
    public var trailingMargin: CGFloat
    public var topMargin: CGFloat
    public var bottomMargin: CGFloat

    public init(
        frame: CGRect,
        leadingMargin: CGFloat = 0,
        trailingMargin: CGFloat = 0,
        topMargin: CGFloat = 0,
        bottomMargin: CGFloat = 0
    ) {
        self.frame = frame
        self.leadingMargin = leadingMargin
        self.trailingMargin = trailingMargin
        self.topMargin = topMargin
        self.bottomMargin = bottomMargin
    }

    /// Whether it runs down the view — a foldable on its side (book posture) — rather than across
    /// it.
    public var runsDown: Bool { frame.height >= frame.width }
}

/// A view's size and the fold through it — everything a row, a grid or a single view needs to keep
/// off the crease.
///
/// A fold that splits the view — through the middle, with room either side — is reported in the
/// view's own coordinates: `band` and `clearance` for one running down it (book posture),
/// `acrossClearance` for one running across it (tabletop). A fold that lines *scroll past* is
/// reported in window coordinates, where a moving line compares its own position: `across` for a
/// vertical grid, `down` for a horizontal one. A fold at or past an edge splits nothing.
public struct FoldGeometry: Equatable, Sendable {
    public var width: CGFloat
    public var height: CGFloat = 0
    /// The fold itself — 40pt on the iPhone Duo. Nil unless it runs down the middle of the view.
    public var band: ClosedRange<CGFloat>?
    /// The fold and the margins its region asks to be kept clear (20pt each side on the Duo),
    /// clamped to the view. What a card should stay out of; a small cell can stand as close as
    /// `band`.
    public var clearance: ClosedRange<CGFloat>?
    /// A fold running *across* the view — tabletop — with its margins, in **window** coordinates:
    /// the top and bottom a scrolling row has to keep clear of, compared against its own window
    /// position as it moves. Nil unless one crosses the view. Only `FoldableGrid(crossing: .flow)`
    /// uses it.
    public var across: ClosedRange<CGFloat>?
    /// A fold running *across* the view with its margins, in the view's own coordinates, when it
    /// splits the view top from bottom — what a horizontal grid's rows part around.
    public var acrossClearance: ClosedRange<CGFloat>?
    /// A fold running *down* the view with its margins, in **window** coordinates: what the columns
    /// of a horizontally scrolling grid part around when they come to rest.
    public var down: ClosedRange<CGFloat>?

    public init(
        width: CGFloat = 0,
        band: ClosedRange<CGFloat>? = nil,
        clearance: ClosedRange<CGFloat>? = nil,
        across: ClosedRange<CGFloat>? = nil
    ) {
        self.width = width
        self.band = band
        self.clearance = clearance
        self.across = across
    }

    /// The geometry of a view `size` big whose top-leading corner is at `origin` in the window,
    /// given the active fold in the view's own coordinates (nil when there is none).
    public init(
        size: CGSize,
        origin: CGPoint = .zero,
        fold: Fold?
    ) {
        self.init(width: size.width, fold: fold)
        height = size.height
        guard let fold else { return }
        if fold.runsDown {
            guard
                fold.frame.maxX > 0,
                fold.frame.minX < size.width
            else { return }
            let leading = origin.x + fold.frame.minX - fold.leadingMargin
            let trailing = origin.x + fold.frame.maxX + fold.trailingMargin
            down = leading...trailing
        } else {
            guard
                fold.frame.maxY > 0,
                fold.frame.minY < size.height
            else { return }
            let top = fold.frame.minY - fold.topMargin
            let bottom = fold.frame.maxY + fold.bottomMargin
            across = (origin.y + top)...(origin.y + bottom)
            if fold.frame.minY > 0, fold.frame.maxY < size.height {
                acrossClearance = max(top, 0)...min(bottom, size.height)
            }
        }
    }

    /// The geometry of a view `width` wide, given the active fold (nil when there is none).
    public init(width: CGFloat, fold: Fold?) {
        self.width = width
        guard
            let fold,
            fold.runsDown,
            fold.frame.minX > 0,
            fold.frame.maxX < width
        else { return }
        band = fold.frame.minX...fold.frame.maxX
        let start = max(
            fold.frame.minX - fold.leadingMargin,
            0
        )
        let end = min(
            fold.frame.maxX + fold.trailingMargin,
            width
        )
        clearance = start...end
    }

    /// Whether a fold runs down the view.
    public var isFolded: Bool { band != nil }

    /// The width that can take content: the whole width, less the fold.
    public var usableWidth: CGFloat {
        width - (band.map { $0.upperBound - $0.lowerBound } ?? 0)
    }

    /// The part of the view before the fold's clearance, and after it. Nil unless folded.
    public var leadingHalf: CGFloat? { clearance.map { $0.lowerBound } }
    public var trailingHalf: CGFloat? {
        clearance.map { width - $0.upperBound }
    }
}
