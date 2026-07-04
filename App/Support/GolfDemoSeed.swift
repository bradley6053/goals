import Foundation
import SwiftData

/// Seeds demo golf data when launched with "-seedGolfDemo" — a 9-hole and an
/// 18-hole course, two finished rounds, and one in progress. Simulator
/// screenshots only, same pattern as DemoSeed.
enum GolfDemoSeed {
    static func runIfRequested(container: ModelContainer) {
        guard ProcessInfo.processInfo.arguments.contains("-seedGolfDemo") else { return }
        let context = ModelContext(container)
        let existing = (try? context.fetch(FetchDescriptor<GolfCourse>())) ?? []
        guard existing.isEmpty else { return }

        // 9-hole course in the Sweetens Cove spirit.
        let cove = GolfCourse(name: "Sweetens Cove Golf Club",
                              city: "South Pittsburg", state: "TN",
                              holeCount: 9, par: 36, totalYardage: 3301,
                              latitude: 35.045, longitude: -85.693)
        cove.holes = zip(1...9, [4, 4, 3, 5, 4, 3, 4, 5, 4]).map {
            GolfHole(number: $0, par: $1)
        }
        cove.tees = [GolfTee(teeKey: "blue", teeName: "Blue",
                             courseRating: 36.1, slope: 129, par: 36, yardage: 3301)]
        context.insert(cove)

        // Local 18-holer.
        let helfrich = GolfCourse(name: "Helfrich Hills Golf Course",
                                  city: "Evansville", state: "IN",
                                  holeCount: 18, par: 71, totalYardage: 6300,
                                  latitude: 37.985, longitude: -87.612)
        let helfrichPars = [4, 4, 3, 5, 4, 4, 3, 4, 5, 4, 3, 4, 5, 4, 4, 3, 4, 4]
        helfrich.holes = zip(1...18, helfrichPars).map { GolfHole(number: $0, par: $1) }
        helfrich.tees = [GolfTee(teeKey: "white", teeName: "White",
                                 courseRating: 69.8, slope: 118, par: 71, yardage: 6300)]
        context.insert(helfrich)

        // Finished 9 at the Cove — a good day, one birdie run.
        let coveRound = GolfRound(holeCount: 9, teeName: "Blue",
                                  courseRating: 36.1, slope: 129)
        coveRound.course = cove
        coveRound.startedAt = Date().addingTimeInterval(-14 * 86400)
        coveRound.completedAt = coveRound.startedAt.addingTimeInterval(2.5 * 3600)
        let coveStrokes = [4, 3, 3, 5, 5, 2, 4, 6, 4]
        coveRound.scores = cove.orderedHoles.enumerated().map { index, hole in
            let score = GolfHoleScore(holeNumber: hole.number, par: hole.par)
            score.strokes = coveStrokes[index]
            score.putts = index % 3 == 0 ? 1 : 2
            score.fairwayHit = hole.par >= 4 ? index % 2 == 0 : nil
            score.greenInRegulation = coveStrokes[index] <= hole.par
            score.committed = true
            return score
        }
        context.insert(coveRound)

        // Finished 18 at Helfrich.
        let helfrichRound = GolfRound(holeCount: 18, teeName: "White",
                                      courseRating: 69.8, slope: 118)
        helfrichRound.course = helfrich
        helfrichRound.startedAt = Date().addingTimeInterval(-5 * 86400)
        helfrichRound.completedAt = helfrichRound.startedAt.addingTimeInterval(4.2 * 3600)
        let helfrichStrokes = [5, 4, 4, 6, 4, 5, 3, 5, 5, 4, 4, 5, 7, 4, 5, 3, 4, 5]
        helfrichRound.scores = helfrich.orderedHoles.enumerated().map { index, hole in
            let score = GolfHoleScore(holeNumber: hole.number, par: hole.par)
            score.strokes = helfrichStrokes[index]
            score.putts = index % 4 == 0 ? 3 : 2
            score.fairwayHit = hole.par >= 4 ? index % 3 != 0 : nil
            score.greenInRegulation = helfrichStrokes[index] <= hole.par
            score.penalties = index == 12 ? 1 : 0
            score.committed = true
            return score
        }
        context.insert(helfrichRound)

        // Round in progress at the Cove, thru 4.
        let liveRound = GolfRound(holeCount: 9, teeName: "Blue",
                                  courseRating: 36.1, slope: 129)
        liveRound.course = cove
        liveRound.startedAt = Date().addingTimeInterval(-45 * 60)
        let liveStrokes = [4, 5, 3, 4]
        liveRound.scores = cove.orderedHoles.map { hole in
            let score = GolfHoleScore(holeNumber: hole.number, par: hole.par)
            if hole.number <= 4 {
                score.strokes = liveStrokes[hole.number - 1]
                score.committed = true
            }
            score.fairwayHit = hole.par >= 4 ? hole.number % 2 == 1 : nil
            score.greenInRegulation = hole.number <= 4 && hole.number % 2 == 1
            return score
        }
        context.insert(liveRound)

        try? context.save()
    }
}
