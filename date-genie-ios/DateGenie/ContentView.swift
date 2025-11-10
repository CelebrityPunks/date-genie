import SwiftUI

struct ContentView: View {
    @State private var venues: [Venue] = []
    @State private var currentIndex = 0
    @State private var isLoading = false
    
    private let api = APIService.shared
    private let analytics = PostHogAnalytics.shared
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.pink.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if isLoading {
                ProgressView("Finding perfect dates...")
                    .scaleEffect(1.5)
            } else if venues.isEmpty {
                VStack(spacing: 20) {
                    Text("No venues found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button("Search Again") {
                        Task { await loadVenues() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if currentIndex < venues.count {
                SwipeCardView(
                    venue: venues[currentIndex],
                    onSave: {
                        saveVenue(venues[currentIndex])
                        nextCard()
                    },
                    onSkip: {
                        skipVenue(venues[currentIndex])
                        nextCard()
                    },
                    onBook: {
                        bookVenue(venues[currentIndex])
                        nextCard()
                    }
                )
                .transition(.asymmetric(insertion: .scale, removal: .opacity))
            } else {
                VStack(spacing: 20) {
                    Text("You've seen all venues!")
                        .font(.title2)
                    
                    Button("Search for more") {
                        currentIndex = 0
                        Task { await loadVenues() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task {
            await loadVenues()
        }
    }
    
    private func loadVenues() async {
        isLoading = true
        
        do {
            venues = try await api.searchVenues(
                city: "NYC",
                categories: ["Food", "Romantic"],
                budget: 100,
                radius: 10,
                userId: "test_user_123"
            )
            
            currentIndex = 0
            
            analytics.capture("search_performed", properties: [
                "city": "NYC",
                "categories": ["Food", "Romantic"],
                "result_count": venues.count
            ])
            
        } catch {
            print("❌ Search failed:", error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func nextCard() {
        withAnimation {
            currentIndex += 1
        }
    }
    
    private func saveVenue(_ venue: Venue) {
        analytics.capture("card_swiped_up", properties: [
            "venue_id": venue.id,
            "venue_name": venue.name
        ])
        
        print("💾 Saved: \(venue.name)")
    }
    
    private func skipVenue(_ venue: Venue) {
        analytics.capture("card_swiped_left", properties: [
            "venue_id": venue.id,
            "venue_name": venue.name,
            "disliked": true
        ])
        
        print("⏭️ Skipped: \(venue.name)")
    }
    
    private func bookVenue(_ venue: Venue) {
        analytics.capture("card_swiped_right", properties: [
            "venue_id": venue.id,
            "venue_name": venue.name,
            "booking_url": venue.bookingUrl
        ])
        
        if let url = URL(string: venue.bookingUrl) {
            UIApplication.shared.open(url)
        }
        
        print("📅 Booking: \(venue.name)")
    }
}

#Preview {
    ContentView()
}
