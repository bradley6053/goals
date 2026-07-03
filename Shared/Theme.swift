import SwiftUI

/// Ember design tokens — dark cinematic. One place for every color, radius,
/// and type style so the whole app (and widgets) stay coherent.
enum Theme {
    // Surfaces
    static let bg = Color(red: 0.031, green: 0.031, blue: 0.047)        // #08080C
    static let card = Color(red: 0.075, green: 0.075, blue: 0.098)      // #131319
    static let elevated = Color(red: 0.106, green: 0.106, blue: 0.137)  // #1B1B23
    static let stroke = Color.white.opacity(0.08)

    // Text
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.35)

    // Radii
    static let radiusCard: CGFloat = 24
    static let radiusInner: CGFloat = 14

    // Type
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black).width(.condensed)
    }

    static func label(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold).width(.expanded)
    }
}

/// Per-goal accent. Stored on the goal by name so it round-trips through
/// SwiftData and the widget snapshot JSON.
struct Accent: Identifiable, Equatable {
    let name: String
    let displayName: String
    let primary: Color
    let secondary: Color

    var id: String { name }

    var gradient: LinearGradient {
        LinearGradient(colors: [secondary, primary],
                       startPoint: .leading, endPoint: .trailing)
    }

    static let ember = Accent(
        name: "ember", displayName: "Ember",
        primary: Color(red: 1.0, green: 0.42, blue: 0.21),
        secondary: Color(red: 1.0, green: 0.72, blue: 0.38))
    static let glacier = Accent(
        name: "glacier", displayName: "Glacier",
        primary: Color(red: 0.04, green: 0.52, blue: 1.0),
        secondary: Color(red: 0.39, green: 0.82, blue: 1.0))
    static let violet = Accent(
        name: "violet", displayName: "Violet",
        primary: Color(red: 0.55, green: 0.31, blue: 1.0),
        secondary: Color(red: 0.78, green: 0.44, blue: 1.0))
    static let jade = Accent(
        name: "jade", displayName: "Jade",
        primary: Color(red: 0.05, green: 0.65, blue: 0.47),
        secondary: Color(red: 0.39, green: 0.90, blue: 0.75))

    static let all: [Accent] = [.ember, .glacier, .violet, .jade]

    static func named(_ name: String) -> Accent {
        all.first { $0.name == name } ?? .ember
    }
}
