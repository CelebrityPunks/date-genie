import SwiftUI
import Kingfisher

struct VenueDetailView: View {
    let venue: Venue
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GeometryReader { proxy in
                    KFImage(URL(string: venue.photoUrl ?? ""))
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(ProgressView())
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .cornerRadius(24)
                }
                .frame(height: 320)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(venue.name)
                        .font(.largeTitle.weight(.semibold))
                    Text(venue.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(venue.aiPitch)
                        .font(.body)
                    if !venue.logisticsTip.isEmpty {
                        Label(venue.logisticsTip, systemImage: "info.circle")
                            .foregroundColor(.secondary)
                    }
                    tagList
                    infoSection
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var tagList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(venue.selectedCategories, id: \.self) { category in
                    Text(category)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.pink.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = URL(string: venue.bookingUrl) {
                Link("Booking / Website", destination: url)
            }
            Text("Rating: \(venue.rating, specifier: "%.1f") (\(venue.reviewCount) reviews)")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}
