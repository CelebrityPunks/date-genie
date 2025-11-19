import SwiftUI
import Kingfisher

struct SwipeCardView: View {
    @State private var offset: CGSize = .zero
    
    let venue: Venue
    let onDislike: () -> Void
    let onLike: () -> Void
    let onOpenDetail: (Venue) -> Void
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        ZStack {
            // Card Content
            VStack(spacing: 0) {
                // Image Area
                ZStack(alignment: .topTrailing) {
                    KFImage(URL(string: venue.photoUrl ?? ""))
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(ProgressView())
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                        .overlay(
                            Rectangle()
                                .stroke(DesignSystem.Colors.ink, lineWidth: 3)
                        )
                    
                    // Score Badge
                    Text(String(format: "%.1f", venue.dateabilityScore))
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.ink)
                        .padding(8)
                        .background(DesignSystem.Colors.magicGold)
                        .overlay(
                            Rectangle()
                                .stroke(DesignSystem.Colors.ink, lineWidth: 2)
                        )
                        .offset(x: -10, y: 10)
                        .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 2, y: 2)
                }
                
                // Info Area
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue.name)
                            .font(DesignSystem.Typography.headerMedium())
                            .foregroundColor(DesignSystem.Colors.ink)
                            .lineLimit(2)
                        
                        Text(venue.aiPitch)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.ink)
                            .lineLimit(3)
                    }
                    
                    if !venue.logisticsTip.isEmpty {
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(DesignSystem.Colors.genieBlue)
                            Text(venue.logisticsTip)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    // Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(venue.selectedCategories, id: \.self) { category in
                                Text(category)
                                    .font(.caption.bold())
                                    .foregroundColor(DesignSystem.Colors.ink)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white)
                                    .overlay(
                                        Capsule()
                                            .stroke(DesignSystem.Colors.ink, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .stroke(DesignSystem.Colors.ink, lineWidth: DesignSystem.Layout.borderWidth)
            )
            .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 8, y: 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .contentShape(Rectangle())
        .onTapGesture { onOpenDetail(venue) }
        .offset(x: offset.width)
        .rotationEffect(.degrees(Double(offset.width / 14)))
        .gesture(
            DragGesture()
                .onChanged { offset = $0.translation }
                .onEnded { value in
                    if value.translation.width > 120 {
                        triggerHaptic()
                        onLike()
                    } else if value.translation.width < -120 {
                        triggerHaptic()
                        onDislike()
                    }
                    withAnimation(.spring()) { offset = .zero }
                }
        )
    }
}
