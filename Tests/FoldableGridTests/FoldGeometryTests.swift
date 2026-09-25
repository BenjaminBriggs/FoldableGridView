import CoreGraphics
import Testing

@testable import FoldableGrid

/// The Duo's inner display on its side, partly open, as the lab measured it: an 867pt window with a
/// 40pt fold at 455.5 and 20pt margins either side.
private let bookFold = Fold(
    frame: CGRect(x: 455.5, y: 0, width: 40, height: 669),
    leadingMargin: 20,
    trailingMargin: 20
)

@Suite("FoldGeometry")
struct FoldGeometryTests {
    @Test("a fold down the middle is the band; with its margins, the clearance")
    func vertical() {
        let geometry = FoldGeometry(width: 867, fold: bookFold)
        #expect(geometry.band == 455.5...495.5)
        #expect(geometry.clearance == 435.5...515.5)
        #expect(geometry.isFolded)
        #expect(geometry.usableWidth == 827)
        #expect(geometry.leadingHalf == 435.5)
        #expect(geometry.trailingHalf == 351.5)
    }

    @Test("a fold across the view — tabletop — splits nothing")
    func horizontal() {
        let tabletop = Fold(
            frame: CGRect(x: 0, y: 455.5, width: 669, height: 40),
            leadingMargin: 0,
            trailingMargin: 0
        )
        let geometry = FoldGeometry(width: 669, fold: tabletop)
        #expect(geometry.band == nil)
        #expect(geometry.isFolded == false)
        #expect(geometry.usableWidth == 669)
    }

    @Test("a fold at or past an edge of the view splits nothing")
    func edge() {
        // A view that sits wholly in the leading half: the fold starts where the view ends.
        #expect(FoldGeometry(width: 455.5, fold: bookFold).band == nil)
        // A view that starts after the fold, in its own coordinates.
        let after = Fold(
            frame: CGRect(x: -40, y: 0, width: 40, height: 669)
        )
        #expect(FoldGeometry(width: 300, fold: after).band == nil)
    }

    @Test("the clearance never reaches past the view")
    func clamped() {
        let close = Fold(
            frame: CGRect(x: 10, y: 0, width: 40, height: 600),
            leadingMargin: 20,
            trailingMargin: 20
        )
        let geometry = FoldGeometry(width: 60, fold: close)
        #expect(geometry.clearance == 0...60)
    }

    @Test("no fold is the whole width, unfolded")
    func none() {
        let geometry = FoldGeometry(width: 390, fold: nil)
        #expect(geometry.isFolded == false)
        #expect(geometry.leadingHalf == nil)
        #expect(geometry.trailingHalf == nil)
        #expect(geometry.usableWidth == 390)
    }
}

@Suite("FoldGeometry, both ways")
struct FoldGeometryAxesTests {
    @Test("a fold down a view is also in the window's terms, to flow columns")
    func down() {
        let geometry = FoldGeometry(
            size: CGSize(width: 867, height: 635),
            origin: CGPoint(x: 10, y: 50),
            fold: bookFold
        )
        #expect(geometry.band == 455.5...495.5)
        #expect(geometry.down == 445.5...525.5)
        #expect(geometry.across == nil)
        #expect(geometry.acrossClearance == nil)
    }

    @Test("a fold across a view splits it locally and flows rows globally")
    func across() {
        let tabletop = Fold(
            frame: CGRect(x: 0, y: 455.5, width: 669, height: 40),
            topMargin: 20,
            bottomMargin: 20
        )
        let geometry = FoldGeometry(
            size: CGSize(width: 669, height: 835),
            origin: CGPoint(x: 0, y: 82),
            fold: tabletop
        )
        #expect(geometry.acrossClearance == 435.5...515.5)
        #expect(geometry.across == 517.5...597.5)
        #expect(geometry.band == nil)
        #expect(geometry.down == nil)
        #expect(geometry.height == 835)
    }

    @Test("a fold wholly outside a view neither splits nor flows it")
    func acrossOutside() {
        // A grid that starts below the fold, in its own coordinates.
        let above = Fold(
            frame: CGRect(x: 0, y: -60, width: 669, height: 40)
        )
        let geometry = FoldGeometry(
            size: CGSize(width: 669, height: 400),
            fold: above
        )
        #expect(geometry.acrossClearance == nil)
        #expect(geometry.across == nil)
    }
}
