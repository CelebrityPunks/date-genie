import SwiftUI
import Kingfisher

struct SavedDatesView: View {
    @EnvironmentObject var viewModel: DateGenieViewModel
    @State private var selectedIDs: Set<String> = []
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with Logo
                DateGenieHeader()
                    .padding(.bottom, 20)
                
                VStack(spacing: 20) {
                    header
                    
                    if viewModel.savedDates.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 50))
                                .foregroundColor(DesignSystem.Colors.ink.opacity(0.5))
                            Text("No saved dates yet")
                                .font(DesignSystem.Typography.headerMedium())
                                .foregroundColor(DesignSystem.Colors.ink)
                            Text("Swipe right on venues to save them for later.")
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.ink.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.savedDates) { venue in
                                    SavedVenueRow(
                                        venue: venue,
                                        isSelected: selectedIDs.contains(venue.id),
                                        onToggle: {
                                            if selectedIDs.contains(venue.id) {
                                                selectedIDs.remove(venue.id)
                                            } else {
                                                selectedIDs.insert(venue.id)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.bottom, 120) // Clearance for tab bar
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if !selectedIDs.isEmpty {
                Button {
                    viewModel.addSavedToDatePack(ids: selectedIDs)
                    selectedIDs.removeAll()
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Add \(selectedIDs.count) to Date Pack")
                    }
                    .font(DesignSystem.Typography.headerMedium())
                    .foregroundColor(DesignSystem.Colors.textInverted)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.ink)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(DesignSystem.Colors.ink, lineWidth: 3)
                    )
                    .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 4, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .mainBackground()
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Saved Dates")
                    .font(DesignSystem.Typography.headerLarge())
                    .foregroundColor(DesignSystem.Colors.ink)
                Text("Build your perfect date pack.")
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.ink.opacity(0.7))
            }
            Spacer()
        }
    }
}

struct SavedVenueRow: View {
    let venue: Venue
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                KFImage(URL(string: venue.photoUrl ?? ""))
                    .placeholder {
                        Color.gray.opacity(0.2)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignSystem.Colors.ink, lineWidth: 2)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(venue.name)
                        .font(DesignSystem.Typography.headerMedium())
                        .foregroundColor(DesignSystem.Colors.ink)
                        .lineLimit(1)
                    
                    Text(venue.address)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.ink.opacity(0.7))
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.magicGold)
                        Text(String(format: "%.1f", venue.dateabilityScore))
                            .font(.caption2.bold())
                            .foregroundColor(DesignSystem.Colors.ink)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? DesignSystem.Colors.freshTeal : DesignSystem.Colors.ink.opacity(0.3))
                    .background(isSelected ? Color.white : Color.clear)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(DesignSystem.Colors.ink, lineWidth: isSelected ? 2 : 0)
                    )
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DesignSystem.Colors.ink, lineWidth: 3)
            )
            .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 4, y: 4)
        }
    }
}
