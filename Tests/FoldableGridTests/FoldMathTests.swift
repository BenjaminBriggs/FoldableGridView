import CoreGraphics
import Testing

@testable import FoldableGrid

@Suite("FoldMath")
struct FoldMathTests {
    @Test("without a fold the cells are equal and fill the width")
    func even() {
        let cells = FoldMath.cells(
            count: 4,
            width: 390,
            spacing: 6,
            band: nil
        )
        #expect(cells.count == 4)
        #expect(cells.first?.lowerBound == 0)
        #expect(abs((cells.last?.upperBound ?? 0) - 390) < 0.001)
        let widths = cells.map { cell in
            ((cell.upperBound - cell.lowerBound) * 1000)
                .rounded()
        }
        #expect(Set(widths).count == 1)
    }

    @Test("with a fold no cell touches it, and every cell stays in the row")
    func avoids() {
        let band: ClosedRange<CGFloat> = 435.5...475.5
        for count in 2...12 {
            let cells = FoldMath.cells(
                count: count,
                width: 827,
                spacing: 6,
                band: band
            )
            #expect(cells.count == count)
            for cell in cells {
                // Touching the band's edge is standing beside the fold; only reaching into it
                // fails.
                let clear =
                    cell.upperBound <= band.lowerBound
                    || cell.lowerBound >= band.upperBound
                #expect(clear)
                #expect(cell.lowerBound >= 0)
                #expect(cell.upperBound <= 827.001)
            }
        }
    }

    @Test("the cells split by the halves' widths, never leaving a side empty")
    func share() {
        #expect(FoldMath.share(of: 7, before: 455.5, after: 371.5) == 4)
        #expect(FoldMath.share(of: 12, before: 435.5, after: 351.5) == 7)
        #expect(FoldMath.share(of: 2, before: 900, after: 10) == 1)
        #expect(FoldMath.share(of: 2, before: 10, after: 900) == 1)
        #expect(FoldMath.share(of: 1, before: 400, after: 400) == 1)
    }

    @Test("a fold at the edge of the row changes nothing")
    func edgeBand() {
        let plain = FoldMath.cells(
            count: 3,
            width: 300,
            spacing: 4,
            band: nil
        )
        let edge = FoldMath.cells(
            count: 3,
            width: 300,
            spacing: 4,
            band: 0...40
        )
        #expect(plain == edge)
    }

    @Test("as many columns fit as the minimum allows, never fewer than one")
    func fitting() {
        #expect(FoldMath.fitting(minimum: 320, spacing: 12, in: 435.5) == 1)
        #expect(FoldMath.fitting(minimum: 116, spacing: 4, in: 435.5) == 3)
        #expect(FoldMath.fitting(minimum: 320, spacing: 12, in: 100) == 1)
    }

    @Test("folded columns fill each side exactly, the fold as the gap")
    func columns() {
        let gap: ClosedRange<CGFloat> = 435.5...515.5
        let columns = FoldMath.columns(
            leadingCount: 3,
            trailingCount: 2,
            width: 827,
            spacing: 4,
            gap: gap
        )
        #expect(columns.count == 5)
        // The last leading column is followed by the gap; the others by the usual spacing.
        #expect(columns[2].spacing == 80)
        #expect(columns[0].spacing == 4)
        let widths = columns.map(\.width)
        let leading = widths[0] + widths[1] + widths[2] + 4 * 2
        #expect(abs(leading - 435.5) < 0.001)
        let trailing = widths[3] + widths[4] + 4
        #expect(abs(trailing - (827 - 515.5)) < 0.001)
    }
}
