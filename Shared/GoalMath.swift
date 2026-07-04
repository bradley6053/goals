import Foundation

/// Pure progress math shared by app, widgets, and tests.
/// Works for both directions: losing weight (start 220 → target 200)
/// and building up (save $0 → $5,000).
enum GoalDirection {
    case increasing
    case decreasing
}

enum GoalMath {
    static func direction(start: Double, target: Double) -> GoalDirection {
        target >= start ? .increasing : .decreasing
    }

    /// 0...1 progress toward the target, clamped.
    static func fraction(start: Double, target: Double, current: Double) -> Double {
        let span = target - start
        guard span != 0 else { return 1 }
        return min(1, max(0, (current - start) / span))
    }

    /// Whether `value` (a milestone or the target itself) has been reached.
    static func reached(value: Double, start: Double, target: Double, current: Double) -> Bool {
        switch direction(start: start, target: target) {
        case .increasing: return current >= value - 0.000_001
        case .decreasing: return current <= value + 0.000_001
        }
    }

    /// Signed change from the starting value, e.g. -12 for 12 lbs lost.
    static func deltaFromStart(start: Double, current: Double) -> Double {
        current - start
    }

    /// How much further to a given value, always positive.
    static func remaining(to value: Double, current: Double, start: Double, target: Double) -> Double {
        switch direction(start: start, target: target) {
        case .increasing: return max(0, value - current)
        case .decreasing: return max(0, current - value)
        }
    }
}

// MARK: - Formatting

enum GoalFormat {
    /// "12" or "12.5" — trims trailing zeros.
    static func number(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    /// "$5,000" or "12.5 lbs". Currency units prefix; everything else suffixes.
    static func value(_ value: Double, unit: String) -> String {
        let trimmedUnit = unit.trimmingCharacters(in: .whitespaces)
        if trimmedUnit == "$" || trimmedUnit == "€" || trimmedUnit == "£" {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = value == value.rounded() ? 0 : 1
            let text = formatter.string(from: NSNumber(value: value)) ?? number(value)
            return "\(trimmedUnit)\(text)"
        }
        if trimmedUnit.isEmpty {
            return number(value)
        }
        return "\(number(value)) \(trimmedUnit)"
    }

    /// Signed delta like "−12 lbs" or "+$1,200". Uses a true minus sign.
    static func signedDelta(_ delta: Double, unit: String) -> String {
        let magnitude = value(abs(delta), unit: unit)
        if delta < 0 { return "−\(magnitude)" }
        if delta > 0 { return "+\(magnitude)" }
        return magnitude
    }

    /// The big label for a milestone. Decreasing goals read as deltas ("−10 lbs"),
    /// increasing goals as absolute values ("$3,000").
    static func milestoneLabel(value: Double, start: Double, target: Double, unit: String) -> String {
        switch GoalMath.direction(start: start, target: target) {
        case .decreasing:
            return signedDelta(value - start, unit: unit)
        case .increasing:
            return GoalFormat.value(value, unit: unit)
        }
    }

    /// "🔥 12 days" (or "🔥 1 day"). Shared by app + widget headlines.
    static func streakHeadline(_ days: Int) -> String {
        "🔥 \(days) \(days == 1 ? "day" : "days")"
    }

    /// "42 / 100" style count headline.
    static func countHeadline(current: Double, target: Double) -> String {
        "\(number(current)) / \(number(target))"
    }
}
