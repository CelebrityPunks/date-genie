import Foundation

// Manifesto Rule #3: Type Safety - All models Codable
struct Venue: Codable, Identifiable {
    let id: String
    let name: String
    let address: String
    let priceLevel: String
    let rating: Double
    let reviewCount: Int
    let categories: [String]
    let location: Location
    let vibeTags: [String]
    let selectedCategories: [String]
    let dateabilityScore: Double
    let aiPitch: String
    let logisticsTip: String
    let bookingUrl: String
    let photoUrl: String?
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

// Date categories for picker
enum DateCategory: String, Codable, CaseIterable {
    case Food, Fun
    case LiveEvents = "Live Events"
    case Active
    case BarsDrinks = "Bars/Drinks"
    case Nature
    case Romantic
    case Cultural
    case Adventure
    case Relaxed
    case Seasonal
}
