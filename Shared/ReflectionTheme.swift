import SwiftUI

/// Reflection design tokens — candlelit lectio calm. Deliberately warmer
/// and quieter than the blue-black Ember theme: deep umber surfaces, candle
/// gold light, and a serif voice for the quote itself. The app forces dark
/// mode, so every color here is explicit — never use semantic colors in
/// reflection views.
enum ReflectionTheme {
    // Surfaces — deep umber, not Theme.bg's blue-black
    static let bg = Color(red: 0.094, green: 0.070, blue: 0.055)      // #181209
    static let card = Color(red: 0.137, green: 0.104, blue: 0.082)    // warm panel
    static let stroke = Color(red: 0.93, green: 0.76, blue: 0.46).opacity(0.14)

    // Light
    static let candle = Color(red: 0.93, green: 0.76, blue: 0.46)     // candle gold
    static let glow = Color(red: 0.82, green: 0.45, blue: 0.24)       // low ember

    // Text — warm off-whites, never pure white
    static let textPrimary = Color(red: 0.95, green: 0.92, blue: 0.86)
    static let textSecondary = Color(red: 0.95, green: 0.92, blue: 0.86).opacity(0.6)
    static let textTertiary = Color(red: 0.95, green: 0.92, blue: 0.86).opacity(0.38)

    // Radii
    static let radiusCard: CGFloat = 24

    // Type — serif is the voice of this world
    static func quote(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func serif(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func label(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold).width(.expanded)
    }
}
