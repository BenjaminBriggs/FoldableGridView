import FoldableGrid
import SwiftUI

@main
struct FoldableGridExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRoot()
        }
    }
}

/// Four screens: a calendar and a week of bars (`FoldableRow`), a photo grid, cards and a sideways
/// strip (`FoldableGrid`). On an iPhone Duo, partly open, each keeps off the crease on its own.
struct ExampleRoot: View {
    /// Remembered, so the app opens where it was left.
    @AppStorage("tab") private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            Tab("Photos", systemImage: "photo.on.rectangle", value: 0) {
                PhotosScreen()
            }
            Tab("Cards", systemImage: "rectangle.grid.2x2", value: 1) {
                CardsScreen()
            }
            Tab("Strip", systemImage: "rectangle.split.3x1", value: 2) {
                StripScreen()
            }
            Tab("Calendar", systemImage: "calendar", value: 3) {
                CalendarScreen()
            }
        }
    }
}
