import Foundation
import SwiftData

@Model
final class GolfCourse {
    var uuid: UUID = UUID()
    /// OpenGolfAPI course id; nil means the course was entered manually.
    var apiID: String?
    var name: String = ""
    var city: String = ""
    var state: String = ""
    var holeCount: Int = 18
    var par: Int = 72
    var totalYardage: Int?
    var latitude: Double?
    var longitude: Double?
    var addedAt: Date = Date()
    var lastFetchedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \GolfTee.course)
    var tees: [GolfTee] = []

    @Relationship(deleteRule: .cascade, inverse: \GolfHole.course)
    var holes: [GolfHole] = []

    @Relationship(deleteRule: .cascade, inverse: \GolfRound.course)
    var rounds: [GolfRound] = []

    init(apiID: String? = nil, name: String, city: String = "", state: String = "",
         holeCount: Int = 18, par: Int = 72, totalYardage: Int? = nil,
         latitude: Double? = nil, longitude: Double? = nil) {
        self.uuid = UUID()
        self.apiID = apiID
        self.name = name
        self.city = city
        self.state = state
        self.holeCount = holeCount
        self.par = par
        self.totalYardage = totalYardage
        self.latitude = latitude
        self.longitude = longitude
        self.addedAt = Date()
    }
}

@Model
final class GolfTee {
    var uuid: UUID = UUID()
    var teeKey: String = ""
    var teeName: String = ""
    var gender: String = ""
    var courseRating: Double?
    var slope: Int?
    var par: Int?
    var yardage: Int?
    var course: GolfCourse?

    init(teeKey: String, teeName: String, gender: String = "",
         courseRating: Double? = nil, slope: Int? = nil,
         par: Int? = nil, yardage: Int? = nil) {
        self.uuid = UUID()
        self.teeKey = teeKey
        self.teeName = teeName
        self.gender = gender
        self.courseRating = courseRating
        self.slope = slope
        self.par = par
        self.yardage = yardage
    }
}

@Model
final class GolfHole {
    var uuid: UUID = UUID()
    var number: Int = 1
    var par: Int = 4
    var handicapIndex: Int?
    var yardage: Int?
    var course: GolfCourse?

    init(number: Int, par: Int, handicapIndex: Int? = nil, yardage: Int? = nil) {
        self.uuid = UUID()
        self.number = number
        self.par = par
        self.handicapIndex = handicapIndex
        self.yardage = yardage
    }
}

@Model
final class GolfRound {
    var uuid: UUID = UUID()
    var startedAt: Date = Date()
    /// nil while the round is in progress — the resume query keys off this.
    var completedAt: Date?
    var holeCount: Int = 18
    /// Snapshotted from the chosen tee so old rounds survive course re-imports.
    var teeName: String = ""
    var courseRating: Double?
    var slope: Int?
    var course: GolfCourse?

    @Relationship(deleteRule: .cascade, inverse: \GolfHoleScore.round)
    var scores: [GolfHoleScore] = []

    init(holeCount: Int, teeName: String = "",
         courseRating: Double? = nil, slope: Int? = nil) {
        self.uuid = UUID()
        self.startedAt = Date()
        self.holeCount = holeCount
        self.teeName = teeName
        self.courseRating = courseRating
        self.slope = slope
    }
}

@Model
final class GolfHoleScore {
    var uuid: UUID = UUID()
    var holeNumber: Int = 1
    /// Snapshotted par so the scorecard stays true if course data changes.
    var par: Int = 4
    var strokes: Int = 0
    var putts: Int = 0
    /// nil = par 3 (no fairway to hit) or not recorded.
    var fairwayHit: Bool?
    var greenInRegulation: Bool = false
    var penalties: Int = 0
    /// Set when the golfer swipes past the hole — gates confetti and totals.
    var committed: Bool = false
    var round: GolfRound?

    init(holeNumber: Int, par: Int) {
        self.uuid = UUID()
        self.holeNumber = holeNumber
        self.par = par
        self.strokes = par
        self.putts = 2
    }
}

// MARK: - Derived state

extension GolfRound {
    var isComplete: Bool { completedAt != nil }

    /// Scores in hole order — SwiftData relationships don't guarantee order.
    var orderedScores: [GolfHoleScore] {
        scores.sorted { $0.holeNumber < $1.holeNumber }
    }

    /// Only holes the golfer has actually committed count toward totals.
    var committedResults: [HoleResult] {
        orderedScores.filter(\.committed).map(\.asResult)
    }

    var totalStrokes: Int { GolfMath.totalStrokes(committedResults) }
    var totalToPar: Int { GolfMath.totalToPar(committedResults) }
    var holesPlayed: Int { committedResults.count }
}

extension GolfHoleScore {
    var asResult: HoleResult {
        HoleResult(holeNumber: holeNumber, par: par, strokes: strokes, putts: putts,
                   fairwayHit: fairwayHit, greenInRegulation: greenInRegulation,
                   penalties: penalties)
    }

    var scoreType: ScoreType {
        GolfMath.scoreType(strokes: strokes, par: par)
    }
}

extension GolfCourse {
    var completedRounds: [GolfRound] {
        rounds.filter(\.isComplete)
    }

    /// Best (lowest) completed total for a given round length.
    func bestScore(holeCount: Int) -> Int? {
        completedRounds
            .filter { $0.holeCount == holeCount }
            .map(\.totalStrokes)
            .min()
    }

    var orderedHoles: [GolfHole] {
        holes.sorted { $0.number < $1.number }
    }
}
