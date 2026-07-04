import Foundation

/// One hole's recorded result — a plain value type so all scoring math is
/// testable without SwiftData, mirroring how GoalMath stays pure.
struct HoleResult: Equatable {
    var holeNumber: Int
    var par: Int
    var strokes: Int
    var putts: Int
    /// nil = not applicable (par 3) or not recorded.
    var fairwayHit: Bool?
    var greenInRegulation: Bool
    var penalties: Int

    init(holeNumber: Int, par: Int, strokes: Int, putts: Int = 0,
         fairwayHit: Bool? = nil, greenInRegulation: Bool = false, penalties: Int = 0) {
        self.holeNumber = holeNumber
        self.par = par
        self.strokes = strokes
        self.putts = putts
        self.fairwayHit = fairwayHit
        self.greenInRegulation = greenInRegulation
        self.penalties = penalties
    }
}

/// Score relative to par, ordered best → worst.
enum ScoreType: Int, CaseIterable, Comparable {
    case albatross, eagle, birdie, par, bogey, doubleBogey, worse

    static func < (lhs: ScoreType, rhs: ScoreType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .albatross: return "Albatross"
        case .eagle: return "Eagle"
        case .birdie: return "Birdie"
        case .par: return "Par"
        case .bogey: return "Bogey"
        case .doubleBogey: return "Double"
        case .worse: return "Other"
        }
    }
}

/// In-round momentum for Live Round Vibes.
enum RoundVibe: Equatable {
    case hot      // last 3 holes all par or better
    case cold     // last 3 holes all double bogey or worse
    case neutral
}

enum GolfMath {

    static func scoreType(strokes: Int, par: Int) -> ScoreType {
        switch strokes - par {
        case ...(-3): return .albatross
        case -2: return .eagle
        case -1: return .birdie
        case 0: return .par
        case 1: return .bogey
        case 2: return .doubleBogey
        default: return .worse
        }
    }

    // MARK: Totals

    static func totalStrokes(_ results: [HoleResult]) -> Int {
        results.reduce(0) { $0 + $1.strokes }
    }

    static func totalToPar(_ results: [HoleResult]) -> Int {
        results.reduce(0) { $0 + ($1.strokes - $1.par) }
    }

    /// Front nine (holes 1–9) strokes for the holes actually played.
    static func outTotal(_ results: [HoleResult]) -> Int {
        totalStrokes(results.filter { $0.holeNumber <= 9 })
    }

    /// Back nine (holes 10–18) strokes for the holes actually played.
    static func inTotal(_ results: [HoleResult]) -> Int {
        totalStrokes(results.filter { $0.holeNumber >= 10 })
    }

    static func totalPutts(_ results: [HoleResult]) -> Int {
        results.reduce(0) { $0 + $1.putts }
    }

    static func totalPenalties(_ results: [HoleResult]) -> Int {
        results.reduce(0) { $0 + $1.penalties }
    }

    // MARK: Percentages

    /// Fairways hit over measurable holes (par 4/5 with a recorded value).
    /// nil when no hole qualifies, so callers can show "—" instead of 0%.
    static func firPercent(_ results: [HoleResult]) -> Double? {
        let measurable = results.filter { $0.par >= 4 && $0.fairwayHit != nil }
        guard !measurable.isEmpty else { return nil }
        let hit = measurable.filter { $0.fairwayHit == true }.count
        return Double(hit) / Double(measurable.count)
    }

    static func girPercent(_ results: [HoleResult]) -> Double? {
        guard !results.isEmpty else { return nil }
        let hit = results.filter(\.greenInRegulation).count
        return Double(hit) / Double(results.count)
    }

    static func threePuttCount(_ results: [HoleResult]) -> Int {
        results.filter { $0.putts >= 3 }.count
    }

    // MARK: Distribution & streaks

    static func distribution(_ results: [HoleResult]) -> [ScoreType: Int] {
        var counts: [ScoreType: Int] = [:]
        for result in results {
            counts[scoreType(strokes: result.strokes, par: result.par), default: 0] += 1
        }
        return counts
    }

    /// Longest run of consecutive birdie-or-better holes, in hole order.
    static func longestBirdieStreak(_ results: [HoleResult]) -> Int {
        var best = 0, current = 0
        for result in results.sorted(by: { $0.holeNumber < $1.holeNumber }) {
            if scoreType(strokes: result.strokes, par: result.par) <= .birdie {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    /// Momentum read on the most recent holes (pass the last 3 played).
    static func vibe(recent: [HoleResult]) -> RoundVibe {
        guard recent.count >= 3 else { return .neutral }
        let last3 = recent.suffix(3)
        if last3.allSatisfy({ $0.strokes <= $0.par }) { return .hot }
        if last3.allSatisfy({ $0.strokes - $0.par >= 2 }) { return .cold }
        return .neutral
    }

    /// Average of round totals, e.g. all-time 18-hole scoring average.
    /// 9- and 18-hole rounds should be averaged separately.
    static func scoringAverage(totals: [Int]) -> Double? {
        guard !totals.isEmpty else { return nil }
        return Double(totals.reduce(0, +)) / Double(totals.count)
    }
}

// MARK: - Formatting

enum GolfFormat {
    /// "E", "+3", "−2" — true minus sign, matching GoalFormat.
    static func vsPar(_ toPar: Int) -> String {
        if toPar == 0 { return "E" }
        if toPar < 0 { return "−\(abs(toPar))" }
        return "+\(toPar)"
    }

    /// "67%" or "—" when there's nothing to measure.
    static func percent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int((value * 100).rounded()))%"
    }

    /// "84.5" scoring average with one decimal, or "—".
    static func average(_ value: Double?) -> String {
        guard let value else { return "—" }
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() { return String(Int(rounded)) }
        return String(format: "%.1f", rounded)
    }
}
