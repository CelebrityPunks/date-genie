import Foundation

/// User model following DateGenie manifesto rules (Codable, SwiftData-ready)
struct User: Codable, Identifiable {
    let id: String // Apple ID credential user identifier
    var email: String?
    var name: String?
    var createdAt: Date
    var preferences: UserPreferences?
    
    init(id: String, email: String? = nil, name: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = Date()
        self.preferences = nil
    }
}

/// User preferences for date planning (budget, radius, categories, vibe keywords)
struct UserPreferences: Codable {
    var budget: BudgetRange
    var radius: Int // in miles
    var categories: [String] // e.g., ["restaurant", "entertainment", "outdoor"]
    var vibeKeywords: [String] // e.g., ["romantic", "casual", "adventurous"]
    
    enum BudgetRange: String, Codable {
        case budget = "budget" // Under $50
        case moderate = "moderate" // $50-$100
        case premium = "premium" // $100-$200
        case luxury = "luxury" // $200+
    }
}

/// Extension for analytics tracking
extension User {
    var analyticsProperties: [String: Any] {
        var props: [String: Any] = [
            "user_id": id,
            "has_email": email != nil,
            "has_name": name != nil
        ]
        
        if let prefs = preferences {
            props["budget_range"] = prefs.budget.rawValue
            props["search_radius"] = prefs.radius
            props["category_count"] = prefs.categories.count
        }
        
        return props
    }
}


