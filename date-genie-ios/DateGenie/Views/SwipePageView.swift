import SwiftUI

struct SwipePageView: View {
    @EnvironmentObject var viewModel: DateGenieViewModel
    @State private var selectedVenue: Venue?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Header
                VStack {
                    DateGenieHeader()
                    Spacer()
                }
                .zIndex(10)
                
                // Main Content
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(DesignSystem.Colors.magicGold)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(DesignSystem.Colors.loveRed)
                            Text(error)
                                .multilineTextAlignment(.center)
                                .padding()
                            Button("Retry") {
                                Task { await viewModel.loadVenues() }
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignSystem.Colors.genieBlue)
                        }
                    } else if let venue = viewModel.currentVenue {
                        VStack {
                            Spacer().frame(height: 80) // Clearance for header
                            
                            SwipeCardView(
                                venue: venue,
                                onDislike: viewModel.dislikeCurrentVenue,
                                onLike: viewModel.likeCurrentVenue,
                                onOpenDetail: { selectedVenue = $0 }
                            )
                            .padding(.horizontal, 16)
                            .frame(height: geometry.size.height * 0.6)
                            
                            Text("Adjust your filters to find more matches.")
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            Spacer()
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60))
                                .foregroundColor(DesignSystem.Colors.magicGold)
                            Text("All caught up!")
                                .font(DesignSystem.Typography.headerLarge())
                                .foregroundColor(DesignSystem.Colors.ink)
                            Text("Check back later for more venues.")
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.ink.opacity(0.7))
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                
                // Action Buttons (Fixed at bottom)
                if viewModel.currentVenue != nil {
                    VStack {
                        Spacer()
                        HStack(spacing: 40) {
                            Button(action: viewModel.dislikeCurrentVenue) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(DesignSystem.Colors.loveRed)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(DesignSystem.Colors.ink, lineWidth: 3)
                                    )
                                    .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 4, y: 4)
                            }
                            
                            Button(action: viewModel.likeCurrentVenue) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(DesignSystem.Colors.freshTeal)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(DesignSystem.Colors.ink, lineWidth: 3)
                                    )
                                    .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 4, y: 4)
                            }
                        }
                        .padding(.bottom, 110) // Lift above tab bar
                    }
                    .zIndex(20)
                }
            }
        }
        .mainBackground()
        .sheet(item: $selectedVenue) { venue in
            NavigationStack {
                VenueDetailView(venue: venue)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Back") { selectedVenue = nil }
                                .foregroundColor(DesignSystem.Colors.ink)
                        }
                    }
            }
        }
    }
}
