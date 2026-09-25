import CoreGraphics
import Testing

@testable import FoldableGrid

/// A grid of 100pt rows, 4pt apart, under a tabletop fold: 40pt at y 455.5 with 20pt margins either
/// side, so 80pt to keep clear from 435.5.
private let fold: ClosedRange<CGFloat> = 435.5...515.5
private let height: CGFloat = 100
private let spacing: CGFloat = 4

/// Where each of twelve rows is drawn when the grid has scrolled so that its first row's top is
/// `offset`.
private func rows(at offset: CGFloat) -> [ClosedRange<CGFloat>] {
    (0..<12)
        .map { index in
            let top = offset + CGFloat(index) * (height + spacing)
            let shift = FoldMath.flowShift(
                top: top,
                height: height,
                spacing: spacing,
                fold: fold
            )
            return (top + shift)...(top + shift + height)
        }
}

/// Every scroll position a pixel apart, across more than a row's travel either side of the fold.
private let offsets = stride(from: CGFloat(-200), through: 500, by: 0.5)

@Suite("Flow across a fold")
struct FlowTests {
    @Test("rows never overlap one another, at any scroll position")
    func ordered() {
        for offset in offsets {
            let drawn = rows(at: offset)
            for (upper, lower) in zip(drawn, drawn.dropFirst()) {
                #expect(upper.upperBound <= lower.lowerBound + 0.001)
            }
        }
    }

    @Test("no row reaches into the fold, except while one swaps sides")
    func clear() {
        let pitch = height + spacing
        for offset in offsets {
            // How far the row the fold would cut reaches into it, at this scroll position.
            let rowsAbove = ((fold.lowerBound - offset) / pitch)
                .rounded(.down)
            let reach = offset + rowsAbove * pitch + height - fold.lowerBound
            let swapping = reach > height * 0.35 && reach < height * 0.65
            guard swapping == false else { continue }
            for row in rows(at: offset) {
                let into =
                    min(row.upperBound, fold.upperBound)
                    - max(row.lowerBound, fold.lowerBound)
                #expect(into <= 0.001, "offset \(offset): \(row) on the fold")
            }
        }
    }

    @Test("the movement is continuous: a pixel of scrolling never jumps a row")
    func continuous() {
        var previous: [ClosedRange<CGFloat>]?
        for offset in offsets {
            let drawn = rows(at: offset)
            if let previous {
                for (before, after) in zip(previous, drawn) {
                    // A row may move faster than the scroll while it swaps, but never teleport.
                    #expect(abs(after.lowerBound - before.lowerBound) < 60)
                }
            }
            previous = drawn
        }
    }

    @Test("held, the row that would cross stops just above the fold")
    func held() {
        // The fourth row's top at 400: it reaches 64.5pt in, over half — sent. At 360 it reaches
        // 24.5, under a third — held, its bottom on the fold's top.
        let top: CGFloat = 360
        let shift = FoldMath.flowShift(
            top: top,
            height: height,
            spacing: spacing,
            fold: fold
        )
        #expect(abs(top + shift + height - fold.lowerBound) < 0.001)
    }

    @Test("sent, the row that would cross starts just below the fold")
    func sent() {
        let top: CGFloat = 420
        let shift = FoldMath.flowShift(
            top: top,
            height: height,
            spacing: spacing,
            fold: fold
        )
        #expect(abs(top + shift - fold.upperBound) < 0.001)
    }

    @Test("far from the fold, rows above are left alone")
    func farAbove() {
        #expect(
            FoldMath.flowShift(
                top: 0,
                height: height,
                spacing: spacing,
                fold: fold
            ) == 0
        )
    }
}

@Suite("Parting at rest")
struct RestTests {
    @Test("at rest no row is ever on the fold, and rows never overlap")
    func clearAtEveryPosition() {
        let pitch = height + spacing
        for offset in stride(from: CGFloat(-200), through: 500, by: 0.5) {
            let drawn = (0..<12)
                .map { index in
                    let top = offset + CGFloat(index) * pitch
                    let shift = FoldMath.flowShift(
                        top: top,
                        height: height,
                        spacing: spacing,
                        fold: fold,
                        window: 0
                    )
                    return (top + shift)...(top + shift + height)
                }
            for row in drawn {
                let into =
                    min(row.upperBound, fold.upperBound)
                    - max(row.lowerBound, fold.lowerBound)
                #expect(into <= 0.001, "offset \(offset): \(row) on the fold")
            }
            for (upper, lower) in zip(drawn, drawn.dropFirst()) {
                #expect(upper.upperBound <= lower.lowerBound + 0.001)
            }
        }
    }
}
