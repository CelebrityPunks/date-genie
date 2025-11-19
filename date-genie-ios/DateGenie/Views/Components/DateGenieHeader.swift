import SwiftUI

struct DateGenieHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("Date")
                .font(DesignSystem.Typography.headerLarge())
                .foregroundColor(DesignSystem.Colors.ink)
            
            Image("DateGenieIcon")
                .resizable()
                .scaledToFit()
                .frame(height: 50) // Slightly larger as requested
                .shadow(color: DesignSystem.Colors.magicGold, radius: 0, x: 3, y: 3)
            
            Text("Genie")
                .font(DesignSystem.Typography.headerLarge())
                .foregroundColor(DesignSystem.Colors.ink)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}
