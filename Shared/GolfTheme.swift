import SwiftUI

/// Sweetens Cove design tokens — warm cream clubhouse, deep pine ink,
/// brand sky blue. "Golf is supposed to be fun." Deliberately the opposite
/// personality of the dark Ember theme; the app forces dark mode, so every
/// color here is explicit — never use semantic colors in golf views.
enum GolfTheme {
    // Surfaces — cream cardstock
    static let bg = Color(red: 0.965, green: 0.945, blue: 0.898)       // #F6F1E5
    static let card = Color(red: 0.995, green: 0.99, blue: 0.965)      // near-white
    static let sand = Color(red: 0.91, green: 0.87, blue: 0.78)        // grid fill
    static let stroke = Color(red: 0.12, green: 0.24, blue: 0.19).opacity(0.18)

    // Ink
    static let ink = Color(red: 0.10, green: 0.22, blue: 0.17)         // deep pine
    static let inkSoft = Color(red: 0.10, green: 0.22, blue: 0.17).opacity(0.6)
    static let inkFaint = Color(red: 0.10, green: 0.22, blue: 0.17).opacity(0.35)

    // Accents
    static let fairway = Color(red: 0.16, green: 0.45, blue: 0.29)     // course green
    static let sky = Color(red: 0.12, green: 0.44, blue: 0.70)         // brand blue
    static let flag = Color(red: 0.83, green: 0.36, blue: 0.22)        // scoring red
    static let gold = Color(red: 0.78, green: 0.60, blue: 0.22)        // trophies

    /// Circles for birdies, squares for bogeys — classic scorecard notation.
    static let birdie = sky
    static let bogey = flag

    // Radii
    static let radiusCard: CGFloat = 20
    static let radiusInner: CGFloat = 12

    // Type — rounded black display + serif club charm + expanded labels
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func serif(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func label(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold).width(.expanded)
    }

    static func score(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
    }
}
