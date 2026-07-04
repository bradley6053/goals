import XCTest
@testable import Ember

/// Decode tests against real (trimmed) OpenGolfAPI responses, so DTO field
/// names stay honest without hitting the network.
final class GolfAPITests: XCTestCase {

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    func testSearchResponseDecodes() throws {
        let json = """
        {"courses":[{"id":"dfd21ea9","name":"Victoria National Golf Club",
        "course_name":"Victoria National Golf Club","latitude":38.0006,
        "longitude":-87.3470,"state":"IN","city":"Lamar","type":"Private",
        "par":72,"phone":"+18128588230","website":"http://example.com"}],
        "total":1,"_license":"ODbL-1.0"}
        """.data(using: .utf8)!

        let response = try decoder().decode(CourseSearchResponse.self, from: json)
        XCTAssertEqual(response.courses.count, 1)
        let course = try XCTUnwrap(response.courses.first)
        XCTAssertEqual(course.id, "dfd21ea9")
        XCTAssertEqual(course.displayName, "Victoria National Golf Club")
        XCTAssertEqual(course.location, "Lamar, IN")
        XCTAssertEqual(course.par, 72)
        XCTAssertEqual(course.latitude ?? 0, 38.0006, accuracy: 0.001)
    }

    func testDetailDecodesWithPartialData() throws {
        // Trimmed real shape: tees + holes_data present, most extras dropped;
        // hole 2 deliberately missing handicap and yardage.
        let json = """
        {"id":"dfd21ea9","course_name":"Victoria National Golf Club",
        "city":"Lamar","state":"IN","lat":38.0006,"lng":-87.3470,
        "type":"Private","par":72,"holes":18,"yardage":7242,
        "tees":[{"tee_key":"victorian-male","tee_name":"Victorian",
        "tee_color":null,"gender":"Male","course_rating":77.7,"slope":152,
        "par":72,"yardage":7242}],
        "holes_data":[{"number":1,"par":5,"handicap_index":13,
        "yardages":{"detected":454},"hazards":[]},
        {"number":2,"par":4}]}
        """.data(using: .utf8)!

        let detail = try decoder().decode(CourseDetailDTO.self, from: json)
        XCTAssertEqual(detail.holes, 18)
        XCTAssertEqual(detail.tees?.count, 1)
        XCTAssertEqual(detail.tees?.first?.slope, 152)
        XCTAssertEqual(detail.holesData?.count, 2)
        XCTAssertEqual(detail.holesData?.first?.yardages?.detected, 454)
        XCTAssertNil(detail.holesData?.last?.handicapIndex)
        XCTAssertNil(detail.holesData?.last?.yardages)
    }

    func testDetailDecodesWhenHoleDataMissingEntirely() throws {
        let json = """
        {"id":"abc","course_name":"Mystery Muni","par":70,"holes":18}
        """.data(using: .utf8)!

        let detail = try decoder().decode(CourseDetailDTO.self, from: json)
        XCTAssertEqual(detail.par, 70)
        XCTAssertNil(detail.tees)
        XCTAssertNil(detail.holesData)
    }
}
