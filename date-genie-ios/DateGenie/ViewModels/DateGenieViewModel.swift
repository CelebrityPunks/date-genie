import Foundation
import Combine
import SwiftUI

struct DatePackItem: Identifiable, Equatable {
    let id = UUID()
    let venue: Venue
    var scheduledAt: Date = Date()
    var note: String = ""
    
    static func == (lhs: DatePackItem, rhs: DatePackItem) -> Bool {
        lhs.id == rhs.id && lhs.scheduledAt == rhs.scheduledAt && lhs.note == rhs.note
    }
}

@MainActor
final class DateGenieViewModel: ObservableObject {
    @Published var venues: [Venue] = []
    @Published var currentIndex = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var savedDates: [Venue] = []
    @Published var datePack: [DatePackItem] = []
    
    @Published var city: String = "New York"
    @Published var radius: Double = 10
    @Published var selectedCategories: Set<String> = ["Food", "Romantic"]
    @Published var detectedCity: String?
    @Published var isUsingCurrentLocation = false
    @Published var locationError: String?
    
    let availableCategories = [
        "Food", "Live Events", "Active", "Bars/Drinks",
        "Nature", "Romantic", "Cultural", "Adventure", "Relaxed"
    ]
    let maxCategories = 3
    
    private let api = APIService.shared
    private let analytics = PostHogAnalytics.shared
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        locationService.$cityName
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.detectedCity = $0 }
            .store(in: &cancellables)
        locationService.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.locationError = $0 }
            .store(in: &cancellables)
    }
    
    var currentVenue: Venue? {
        guard venues.indices.contains(currentIndex) else { return nil }
        return venues[currentIndex]
    }
    
    var isDatePackActive: Bool { selectedCategories.count > 1 }
    var hasLocation: Bool { resolvedCity != nil }
    
    private var resolvedCity: String? {
        if isUsingCurrentLocation {
            return detectedCity
        }
        let cleaned = city.trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? nil : cleaned
    }
    
    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else if selectedCategories.count < maxCategories {
            selectedCategories.insert(category)
        }
    }
    
    @discardableResult
    func loadVenues() async -> Bool {
        guard let location = resolvedCity,
              !selectedCategories.isEmpty else { return false }
        isLoading = true
        errorMessage = nil
        do {
            let results = try await api.searchVenues(
                city: location,
                categories: Array(selectedCategories),
                budget: 500,
                radius: radius,
                userId: "demo_user"
            )
            venues = results
            currentIndex = 0
            analytics.capture("search_performed", properties: [
                "city": location,
                "categories": Array(selectedCategories),
                "result_count": venues.count,
                "date_pack": isDatePackActive
            ])
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func likeCurrentVenue() {
        guard let venue = currentVenue else { return }
        if !savedDates.contains(where: { $0.id == venue.id }) {
            savedDates.append(venue)
        }
        analytics.capture("card_liked", properties: [
            "venue_id": venue.id,
            "venue_name": venue.name
        ])
        advanceCard()
    }
    
    func dislikeCurrentVenue() {
        guard let venue = currentVenue else { return }
        analytics.capture("card_disliked", properties: [
            "venue_id": venue.id,
            "venue_name": venue.name
        ])
        advanceCard()
    }
    
    private func advanceCard() {
        withAnimation {
            currentIndex = min(currentIndex + 1, venues.count)
        }
    }
    
    func addSavedToDatePack(ids: Set<String>) {
        let selected = savedDates.filter { ids.contains($0.id) }
        for venue in selected {
            guard !datePack.contains(where: { $0.venue.id == venue.id }) else { continue }
            datePack.append(DatePackItem(venue: venue))
        }
    }
    
    func removeFromDatePack(_ item: DatePackItem) {
        datePack.removeAll { $0.id == item.id }
    }
    
    func requestCurrentLocation() {
        isUsingCurrentLocation = true
        locationService.fetchCurrentCity()
    }
    
    func disableCurrentLocation() {
        isUsingCurrentLocation = false
    }
}
