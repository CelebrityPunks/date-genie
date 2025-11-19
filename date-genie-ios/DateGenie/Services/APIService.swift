import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://date-genie.vercel.app"
    
    func searchVenues(
        city: String,
        categories: [String],
        budget: Double,
        radius: Double,
        userId: String
    ) async throws -> [Venue] {
        let url = URL(string: "\(baseURL)/api/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "city": city,
            "query": categories.joined(separator: " "),
            "budget": budget,
            "radius": radius,
            "categories": categories,
            "userId": userId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
               let message = apiError.error {
                throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: message
                ])
            } else {
                let rawBody = String(data: data, encoding: .utf8) ?? "<no body>"
                print("Server error \(httpResponse.statusCode): \(rawBody)")
                throw URLError(.badServerResponse)
            }
        }
        
        let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
        
        guard searchResponse.success else {
            throw NSError(domain: "APIError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: searchResponse.error ?? "Unknown error"
            ])
        }
        
        return searchResponse.data
    }
}

struct SearchResponse: Codable {
    let success: Bool
    let source: String?
    let data: [Venue]
    let latency: Int?
    let error: String?
}

struct APIErrorResponse: Codable {
    let success: Bool?
    let error: String?
}
