import SwiftUI

/// The example's stand-in content: a colour and a symbol per number, so every cell is told apart.
enum Palette {
    private static let colours: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown,
    ]

    private static let symbols = [
        "paintbrush", "paintpalette", "drop", "sparkles", "leaf", "flame",
        "moon", "star", "bolt", "cloud", "snowflake", "sun.max",
    ]

    static func colour(_ index: Int) -> Color {
        colours[index % colours.count]
    }

    static func symbol(_ index: Int) -> String {
        symbols[index % symbols.count]
    }
}
