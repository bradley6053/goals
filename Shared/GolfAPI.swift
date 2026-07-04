import Foundation
import CoreLocation
import SwiftData

/// OpenGolfAPI client — free, keyless, ODbL-licensed US course data.
/// Search and detail live under different path prefixes (verified live).
struct GolfAPIClient {
    var session: URLSession = .shared

    private static let searchBase = "https://api.opengolfapi.org/v1"
    private static let detailBase = "https://api.opengolfapi.org/api/v1"

    func searchCourses(query: String) async throws -> [CourseSummaryDTO] {
        var components = URLComponents(string: "\(Self.searchBase)/courses/search")!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components.url else { throw GolfAPIError.badURL }
        let response: CourseSearchResponse = try await fetch(url)
        return response.courses
    }

    func courseDetail(id: String) async throws -> CourseDetailDTO {
        guard let url = URL(string: "\(Self.detailBase)/courses/\(id)") else {
            throw GolfAPIError.badURL
        }
        return try await fetch(url)
    }

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw GolfAPIError.offline
        }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw GolfAPIError.http(http.statusCode)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw GolfAPIError.decoding
        }
    }
}

enum GolfAPIError: LocalizedError {
    case badURL
    case http(Int)
    case decoding
    case offline

    var errorDescription: String? {
        switch self {
        case .badURL: return "Bad request."
        case .http(let code): return "Course service error (\(code))."
        case .decoding: return "Couldn't read the course data."
        case .offline: return "No connection — check your signal and try again."
        }
    }
}

// MARK: - DTOs (everything non-essential optional; partial data must decode)

struct CourseSearchResponse: Decodable {
    var courses: [CourseSummaryDTO] = []
    var total: Int?
}

struct CourseSummaryDTO: Decodable, Identifiable {
    let id: String
    var courseName: String?
    var city: String?
    var state: String?
    var type: String?
    var par: Int?
    var latitude: Double?
    var longitude: Double?

    var displayName: String { courseName ?? "Unnamed course" }
    var location: String {
        [city, state].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

struct CourseDetailDTO: Decodable {
    var id: String?
    var courseName: String?
    var city: String?
    var state: String?
    var lat: Double?
    var lng: Double?
    var par: Int?
    var holes: Int?
    var yardage: Int?
    var tees: [TeeDTO]?
    var holesData: [HoleDTO]?
}

struct TeeDTO: Decodable {
    var teeKey: String?
    var teeName: String?
    var gender: String?
    var courseRating: Double?
    var slope: Int?
    var par: Int?
    var yardage: Int?
}

struct HoleDTO: Decodable {
    var number: Int?
    var par: Int?
    var handicapIndex: Int?
    var yardages: YardagesDTO?

    struct YardagesDTO: Decodable {
        var detected: Int?
    }
}

// MARK: - Importer

/// Maps API responses into cached SwiftData courses. Dedupes by apiID and
/// updates in place so replaying a course never re-fetches.
@MainActor
enum GolfCourseImporter {

    static func cachedCourse(apiID: String, in context: ModelContext) -> GolfCourse? {
        let descriptor = FetchDescriptor<GolfCourse>(
            predicate: #Predicate { $0.apiID == apiID })
        return try? context.fetch(descriptor).first
    }

    @discardableResult
    static func importCourse(summary: CourseSummaryDTO, detail: CourseDetailDTO,
                             into context: ModelContext) -> GolfCourse {
        let course = cachedCourse(apiID: summary.id, in: context)
            ?? {
                let new = GolfCourse(apiID: summary.id, name: summary.displayName)
                context.insert(new)
                return new
            }()

        course.name = detail.courseName ?? summary.displayName
        course.city = detail.city ?? summary.city ?? course.city
        course.state = detail.state ?? summary.state ?? course.state
        course.holeCount = detail.holes ?? course.holeCount
        course.par = detail.par ?? summary.par ?? course.par
        course.totalYardage = detail.yardage ?? course.totalYardage
        course.latitude = detail.lat ?? summary.latitude ?? course.latitude
        course.longitude = detail.lng ?? summary.longitude ?? course.longitude
        course.lastFetchedAt = Date()

        // Replace tee and hole sets wholesale — cascade cleans up the old rows.
        course.tees.forEach { context.delete($0) }
        course.tees = (detail.tees ?? []).compactMap { dto in
            guard let name = dto.teeName else { return nil }
            return GolfTee(teeKey: dto.teeKey ?? name, teeName: name,
                           gender: dto.gender ?? "", courseRating: dto.courseRating,
                           slope: dto.slope, par: dto.par, yardage: dto.yardage)
        }

        course.holes.forEach { context.delete($0) }
        course.holes = (detail.holesData ?? []).compactMap { dto in
            guard let number = dto.number, let par = dto.par else { return nil }
            return GolfHole(number: number, par: par,
                            handicapIndex: dto.handicapIndex,
                            yardage: dto.yardages?.detected)
        }

        geocodeIfNeeded(course)
        return course
    }

    /// One-time city/state geocode so manual and coordinate-less courses
    /// still get a passport pin. No location permission required.
    static func geocodeIfNeeded(_ course: GolfCourse) {
        guard course.latitude == nil, !course.city.isEmpty else { return }
        let query = "\(course.city), \(course.state)"
        let courseID = course.uuid
        CLGeocoder().geocodeAddressString(query) { placemarks, _ in
            guard let coordinate = placemarks?.first?.location?.coordinate else { return }
            Task { @MainActor in
                // The model may have been deleted while geocoding was in flight.
                guard let context = course.modelContext,
                      let fresh = try? context.fetch(FetchDescriptor<GolfCourse>(
                        predicate: #Predicate { $0.uuid == courseID })).first
                else { return }
                fresh.latitude = coordinate.latitude
                fresh.longitude = coordinate.longitude
            }
        }
    }
}
