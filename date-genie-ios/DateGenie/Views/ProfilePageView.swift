import SwiftUI

struct ProfilePageView: View {
    @EnvironmentObject var viewModel: DateGenieViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with Logo
                DateGenieHeader()
                    .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 32) {
                        hero
                        stats
                        premiumCard
                    }
                    .padding(24)
                    .padding(.bottom, 120) // Clearance for tab bar
                }
            }
        }
        .mainBackground()
    }
    
    private var hero: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(DesignSystem.Colors.ink)
                .background(Color.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.ink, lineWidth: 3)
                )
                .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 4, y: 4)
            
            VStack(spacing: 4) {
                Text("Date Explorer")
                    .font(DesignSystem.Typography.headerLarge())
                    .foregroundColor(DesignSystem.Colors.ink)
                
                Text("Keep leveling up your romance game ✨")
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.ink.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
    
    private var stats: some View {
        HStack(spacing: 16) {
            statTile(title: "Saved", value: "\(viewModel.savedDates.count)", color: DesignSystem.Colors.magicGold)
            statTile(title: "Pack Steps", value: "\(viewModel.datePack.count)", color: DesignSystem.Colors.freshTeal)
            statTile(title: "Cities", value: "1", color: DesignSystem.Colors.loveRed)
        }
    }
    
    private func statTile(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(DesignSystem.Typography.headerLarge())
                .foregroundColor(DesignSystem.Colors.ink)
            Text(title)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(DesignSystem.Colors.ink, lineWidth: 3)
        )
        .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 4, y: 4)
    }
    
    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(DesignSystem.Colors.magicGold)
                Text("Premium perks coming soon")
                    .font(DesignSystem.Typography.headerMedium())
                    .foregroundColor(DesignSystem.Colors.textInverted)
            }
            
            Text("Unlock global cities, AI concierge, and competitive date leaderboards.")
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.textInverted.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            
            Button("Notify me") {}
                .font(DesignSystem.Typography.headerMedium())
                .foregroundColor(DesignSystem.Colors.ink)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(DesignSystem.Colors.magicGold)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(DesignSystem.Colors.ink, lineWidth: 2)
                )
                .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 2, y: 2)
        }
        .padding(24)
        .background(DesignSystem.Colors.ink)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(DesignSystem.Colors.ink, lineWidth: 3)
        )
        .shadow(color: DesignSystem.Colors.ink.opacity(0.3), radius: 0, x: 6, y: 6)
    }
}
