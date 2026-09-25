import SwiftUI

extension GeometryProxy {
    /// The fold while the device is partly open, in this proxy's coordinates. Nil when it is
    /// closed, flat, before iOS 27.1, or not a foldable. The default query returns active regions
    /// only, and the fold's region is active only while partly open — so nil means "lay out as
    /// usual".
    public var activeFold: Fold? {
        #if os(iOS)
        guard #available(iOS 27.1, *) else { return nil }
        return reservedRegions(kind: .division)
            .first
            .map { region in
                Fold(
                    frame: region.frame,
                    leadingMargin: region.margins.leading,
                    trailingMargin: region.margins.trailing,
                    topMargin: region.margins.top,
                    bottomMargin: region.margins.bottom
                )
            }
        #else
        return nil
        #endif
    }

    /// This view's width and the vertical fold through it.
    public var foldGeometry: FoldGeometry {
        FoldGeometry(
            size: size,
            origin: frame(in: .global).origin,
            fold: activeFold
        )
    }
}

extension View {
    /// Keeps `geometry` up to date with this view's width and the fold through it — including when
    /// the device folds or opens and nothing else about the view changes.
    ///
    /// The measuring is a `GeometryReader` in the background: it proposes nothing, so the view lays
    /// out exactly as it did, and its body is re-run when the fold's region changes, which is the
    /// reason for it. `onGeometryChange` is *not* re-run then — folding changes neither the size
    /// nor the position of a view — so a fold read there keeps the posture the view appeared in.
    public func foldGeometry(_ geometry: Binding<FoldGeometry>) -> some View {
        modifier(FoldMeasuring(geometry: geometry))
    }
}

private struct FoldMeasuring: ViewModifier {
    @Binding var geometry: FoldGeometry

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(
                            of: proxy.foldGeometry,
                            initial: true
                        ) { _, newValue in
                            geometry = newValue
                        }
                }
            }
    }
}
