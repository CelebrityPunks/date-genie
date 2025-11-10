import SwiftUI
import Kingfisher

// Manifesto Rule #6: Swipe Cards with haptic feedback
struct SwipeCardView: View {
    @State private var offset: CGSize = .zero
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var showBookingAlert = false
    
    let venue: Venue
    let onSave: () -> Void
    let onSkip: () -> Void
    let onBook: () -> Void
    
    private func triggerHaptic() {
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(radius: 10)
            
            VStack(spacing: 0) {
                KFImage(URL(string: venue.photoUrl ?? ""))
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView().scaleEffect(1.5))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(venue.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(2)
                        Spacer()
                        Text("\(venue.dateabilityScore, specifier: "%.1f")")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .clipShape(Capsule())
                    }
                    
                    Text(venue.aiPitch)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    if !venue.logisticsTip.isEmpty {
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(venue.logisticsTip)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(venue.selectedCategories, id: \.self) { category in
                                Text(category)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            triggerHaptic()
                            onSkip()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.red)
                        }
                        Spacer()
                        Button(action: {
                            triggerHaptic()
                            onSave()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        Button(action: {
                            triggerHaptic()
                            onBook()
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .frame(width: 300, height: 500)
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                }
                .onEnded { _ in
                    let threshold = 100.0
                    if abs(offset.width) > threshold {
                        if offset.width > 0 {
                            onBook()
                        } else {
                            onSkip()
                        }
                    } else if offset.height < -threshold {
                        onSave()
                    }
                    withAnimation {
                        offset = .zero
                    }
                }
        )
        .animation(.spring(), value: offset)
    }
}
