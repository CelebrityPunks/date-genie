import SwiftUI

struct FilterPageView: View {
    @EnvironmentObject var viewModel: DateGenieViewModel
    var onSearchComplete: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with Logo
                DateGenieHeader()
                    .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Location Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Where to?")
                                .font(DesignSystem.Typography.headerMedium())
                                .foregroundColor(DesignSystem.Colors.ink)
                            
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(DesignSystem.Colors.ink)
                                TextField("Enter city...", text: $viewModel.city)
                                    .foregroundColor(DesignSystem.Colors.ink)
                                    .font(DesignSystem.Typography.body())
                            }
                            .padding()
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DesignSystem.Colors.ink, lineWidth: 3)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(DesignSystem.Colors.ink)
                                    .offset(x: 4, y: 4)
                            )
                            
                            // Current Location Button
                            Button {
                                // Action: Request location
                            } label: {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text("Use Current Location")
                                }
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.ink)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(DesignSystem.Colors.magicGold)
                                .overlay(
                                    Capsule()
                                        .stroke(DesignSystem.Colors.ink, lineWidth: 2)
                                )
                                .clipShape(Capsule())
                            }
                        }
                        
                        // Radius Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Distance")
                                    .font(DesignSystem.Typography.headerMedium())
                                    .foregroundColor(DesignSystem.Colors.ink)
                                Spacer()
                                Text("\(Int(viewModel.radius)) km")
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(DesignSystem.Colors.ink)
                                    .padding(8)
                                    .background(DesignSystem.Colors.freshTeal)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(DesignSystem.Colors.ink, lineWidth: 2)
                                    )
                            }
                            
                            Slider(value: $viewModel.radius, in: 1...50, step: 1)
                                .tint(DesignSystem.Colors.genieBlue)
                        }
                        
                        // Vibes Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Vibe Check")
                                .font(DesignSystem.Typography.headerMedium())
                                .foregroundColor(DesignSystem.Colors.ink)
                            
                            FlexibleTagView(
                                availableTags: viewModel.availableCategories,
                                selectedTags: $viewModel.selectedCategories
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120) // Clearance for button
                }
            }
            
            // Search Button - Fixed at bottom
            Button(action: {
                Task {
                    let success = await viewModel.loadVenues()
                    if success { onSearchComplete?() }
                }
            }) {
                Text("Find Dates")
                    .font(DesignSystem.Typography.headerMedium())
                    .foregroundColor(DesignSystem.Colors.textInverted)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.ink)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(DesignSystem.Colors.ink, lineWidth: 3)
                    )
                    .cornerRadius(16)
                    .shadow(color: DesignSystem.Colors.ink.opacity(0.3), radius: 0, x: 6, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 90) // Lift above tab bar
        }
        .mainBackground()
    }
}

struct FlexibleTagView: View {
    let availableTags: [String]
    @Binding var selectedTags: Set<String>
    
    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(availableTags, id: \.self) { tag in
                    TagButton(title: tag, isSelected: selectedTags.contains(tag)) {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if tag == availableTags.last! {
                            width = 0 // last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: {d in
                        let result = height
                        if tag == availableTags.last! {
                            height = 0 // last item
                        }
                        return result
                    })
                }
            }
        }
        .frame(height: 200) // Fixed height for simplicity
    }
}

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? DesignSystem.Colors.ink : Color.white)
                .overlay(
                    Capsule()
                        .stroke(DesignSystem.Colors.ink, lineWidth: 2)
                )
                .clipShape(Capsule())
                .shadow(color: DesignSystem.Colors.ink, radius: 0, x: isSelected ? 2 : 4, y: isSelected ? 2 : 4)
                .offset(x: isSelected ? 2 : 0, y: isSelected ? 2 : 0)
        }
    }
}
