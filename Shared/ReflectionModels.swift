import Foundation

/// The six themes the daily quote rotates through. Lives in Shared so a
/// future widget can show the quote of the day without app code.
enum ReflectionCategory: String, Codable, CaseIterable {
    case scripture, saints, fatherhood, marriage, leadership, virtue

    var displayName: String {
        switch self {
        case .scripture:  return "Scripture"
        case .saints:     return "Saints & Writers"
        case .fatherhood: return "Fatherhood"
        case .marriage:   return "Marriage"
        case .leadership: return "Leadership"
        case .virtue:     return "Virtue"
        }
    }
}

/// One entry in the reflection library. `id` is a stable slug so a future
/// widget snapshot or "favorite" feature can reference quotes across builds.
struct ReflectionQuote: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let attribution: String
    let category: ReflectionCategory
}
