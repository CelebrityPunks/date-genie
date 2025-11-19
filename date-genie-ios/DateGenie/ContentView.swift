import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = DateGenieViewModel()
    @State private var selectedTab = 1
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            DesignSystem.Colors.canvas
                .ignoresSafeArea()
            
            // Main Content
            Group {
                switch selectedTab {
                case 0:
                    FilterPageView(onSearchComplete: { selectedTab = 1 })
                case 1:
                    SwipePageView()
                case 2:
                    SavedDatesView()
                case 3:
                    DatePackPageView()
                case 4:
                    ProfilePageView()
                default:
                    SwipePageView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
        .environmentObject(viewModel)
        .preferredColorScheme(.light)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        (icon: "slider.horizontal.3", title: "Filters"),
        (icon: "sparkles.rectangle.stack.fill", title: "Swipe"),
        (icon: "heart.fill", title: "Saved"),
        (icon: "bag.fill", title: "Packs"),
        (icon: "person.fill", title: "Profile")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20, weight: .semibold))
                            .symbolEffect(.bounce, value: selectedTab == index)
                        
                        if selectedTab == index {
                            Circle()
                                .fill(DesignSystem.Colors.magicGold)
                                .frame(width: 6, height: 6)
                                .overlay(
                                    Circle()
                                        .stroke(DesignSystem.Colors.ink, lineWidth: 1)
                                )
                                .matchedGeometryEffect(id: "tab_dot", in: namespace)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .foregroundColor(selectedTab == index ? DesignSystem.Colors.ink : DesignSystem.Colors.ink.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .contentShape(Rectangle())
                }
            }
        }
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(DesignSystem.Colors.ink, lineWidth: 3)
        )
        .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 4, y: 4)
    }
    
    @Namespace private var namespace
}

#Preview {
    ContentView()
}
