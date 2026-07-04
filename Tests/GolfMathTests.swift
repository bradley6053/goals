import XCTest
@testable import Ember

final class GolfMathTests: XCTestCase {

    // Shorthand builder
    private func hole(_ number: Int, par: Int, strokes: Int, putts: Int = 2,
                      fir: Bool? = nil, gir: Bool = false, penalties: Int = 0) -> HoleResult {
        HoleResult(holeNumber: number, par: par, strokes: strokes, putts: putts,
                   fairwayHit: fir, greenInRegulation: gir, penalties: penalties)
    }

    // MARK: - Score types

    func testScoreTypeBoundaries() {
        XCTAssertEqual(GolfMath.scoreType(strokes: 2, par: 5), .albatross)
        XCTAssertEqual(GolfMath.scoreType(strokes: 3, par: 5), .eagle)
        XCTAssertEqual(GolfMath.scoreType(strokes: 3, par: 4), .birdie)
        XCTAssertEqual(GolfMath.scoreType(strokes: 4, par: 4), .par)
        XCTAssertEqual(GolfMath.scoreType(strokes: 5, par: 4), .bogey)
        XCTAssertEqual(GolfMath.scoreType(strokes: 6, par: 4), .doubleBogey)
        XCTAssertEqual(GolfMath.scoreType(strokes: 8, par: 4), .worse)
        XCTAssertEqual(GolfMath.scoreType(strokes: 1, par: 3), .eagle) // ace on a par 3
    }

    // MARK: - Totals

    func testTotalsAndVsPar() {
        let round = [hole(1, par: 4, strokes: 5), hole(2, par: 3, strokes: 3),
                     hole(3, par: 5, strokes: 4)]
        XCTAssertEqual(GolfMath.totalStrokes(round), 12)
        XCTAssertEqual(GolfMath.totalToPar(round), 0) // +1, E, −1
    }

    func testOutInSplit() {
        let eighteen = (1...18).map { hole($0, par: 4, strokes: $0 <= 9 ? 4 : 5) }
        XCTAssertEqual(GolfMath.outTotal(eighteen), 36)
        XCTAssertEqual(GolfMath.inTotal(eighteen), 45)
    }

    func testNineHoleRoundHasNoInTotal() {
        let nine = (1...9).map { hole($0, par: 4, strokes: 4) }
        XCTAssertEqual(GolfMath.outTotal(nine), 36)
        XCTAssertEqual(GolfMath.inTotal(nine), 0)
    }

    // MARK: - Stats

    func testFIRExcludesPar3sAndUnrecorded() {
        let round = [hole(1, par: 4, strokes: 4, fir: true),
                     hole(2, par: 3, strokes: 3, fir: nil),   // par 3 — excluded
                     hole(3, par: 5, strokes: 5, fir: false),
                     hole(4, par: 4, strokes: 4, fir: nil)]   // unrecorded — excluded
        XCTAssertEqual(GolfMath.firPercent(round), 0.5)
    }

    func testFIRNilWhenNothingMeasurable() {
        let par3Course = (1...9).map { hole($0, par: 3, strokes: 3) }
        XCTAssertNil(GolfMath.firPercent(par3Course))
        XCTAssertNil(GolfMath.firPercent([]))
    }

    func testGIRPercent() {
        let round = [hole(1, par: 4, strokes: 4, gir: true),
                     hole(2, par: 3, strokes: 4, gir: true),
                     hole(3, par: 5, strokes: 6, gir: false),
                     hole(4, par: 4, strokes: 5, gir: false)]
        XCTAssertEqual(GolfMath.girPercent(round), 0.5)
        XCTAssertNil(GolfMath.girPercent([]))
    }

    func testThreePuttCount() {
        let round = [hole(1, par: 4, strokes: 6, putts: 3),
                     hole(2, par: 4, strokes: 4, putts: 2),
                     hole(3, par: 4, strokes: 7, putts: 4)]
        XCTAssertEqual(GolfMath.threePuttCount(round), 2)
    }

    func testDistribution() {
        let round = [hole(1, par: 4, strokes: 3), hole(2, par: 4, strokes: 4),
                     hole(3, par: 4, strokes: 4), hole(4, par: 4, strokes: 5),
                     hole(5, par: 4, strokes: 6)]
        let dist = GolfMath.distribution(round)
        XCTAssertEqual(dist[.birdie], 1)
        XCTAssertEqual(dist[.par], 2)
        XCTAssertEqual(dist[.bogey], 1)
        XCTAssertEqual(dist[.doubleBogey], 1)
        XCTAssertNil(dist[.eagle])
    }

    func testLongestBirdieStreakRespectsHoleOrder() {
        // Birdies on 3, 4, 5 and 8 — passed out of order on purpose.
        let round = [hole(8, par: 4, strokes: 3), hole(1, par: 4, strokes: 4),
                     hole(3, par: 4, strokes: 3), hole(5, par: 5, strokes: 4),
                     hole(4, par: 3, strokes: 2), hole(2, par: 4, strokes: 5),
                     hole(6, par: 4, strokes: 4), hole(7, par: 4, strokes: 4)]
        XCTAssertEqual(GolfMath.longestBirdieStreak(round), 3)
    }

    func testVibe() {
        let hot = [hole(1, par: 4, strokes: 4), hole(2, par: 4, strokes: 3),
                   hole(3, par: 5, strokes: 5)]
        XCTAssertEqual(GolfMath.vibe(recent: hot), .hot)

        let cold = [hole(1, par: 4, strokes: 6), hole(2, par: 3, strokes: 5),
                    hole(3, par: 4, strokes: 7)]
        XCTAssertEqual(GolfMath.vibe(recent: cold), .cold)

        let mixed = [hole(1, par: 4, strokes: 4), hole(2, par: 4, strokes: 6),
                     hole(3, par: 4, strokes: 4)]
        XCTAssertEqual(GolfMath.vibe(recent: mixed), .neutral)

        XCTAssertEqual(GolfMath.vibe(recent: Array(hot.prefix(2))), .neutral) // needs 3 holes
    }

    func testScoringAverage() {
        XCTAssertEqual(GolfMath.scoringAverage(totals: [85, 90, 95]), 90)
        XCTAssertNil(GolfMath.scoringAverage(totals: []))
    }

    // MARK: - Formatting

    func testVsParFormatting() {
        XCTAssertEqual(GolfFormat.vsPar(0), "E")
        XCTAssertEqual(GolfFormat.vsPar(3), "+3")
        XCTAssertEqual(GolfFormat.vsPar(-2), "−2") // true minus sign
    }

    func testPercentFormatting() {
        XCTAssertEqual(GolfFormat.percent(0.5), "50%")
        XCTAssertEqual(GolfFormat.percent(0.667), "67%")
        XCTAssertEqual(GolfFormat.percent(nil), "—")
    }

    func testAverageFormatting() {
        XCTAssertEqual(GolfFormat.average(84.5), "84.5")
        XCTAssertEqual(GolfFormat.average(90.0), "90")
        XCTAssertEqual(GolfFormat.average(nil), "—")
    }

    func testEmptyRoundDegeneracy() {
        XCTAssertEqual(GolfMath.totalStrokes([]), 0)
        XCTAssertEqual(GolfMath.totalToPar([]), 0)
        XCTAssertEqual(GolfMath.longestBirdieStreak([]), 0)
        XCTAssertEqual(GolfMath.vibe(recent: []), .neutral)
        XCTAssertTrue(GolfMath.distribution([]).isEmpty)
    }
}
