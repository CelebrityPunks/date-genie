import SwiftUI

struct DatePackPageView: View {
    @EnvironmentObject var viewModel: DateGenieViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with Logo
                DateGenieHeader()
                    .padding(.bottom, 20)
                
                if viewModel.datePack.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bag.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(DesignSystem.Colors.ink.opacity(0.5))
                        Text("Your Date Pack is empty")
                            .font(DesignSystem.Typography.headerMedium())
                            .foregroundColor(DesignSystem.Colors.ink)
                        Text("Build a multi-step date by adding venues from Saved Dates.")
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.ink.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach($viewModel.datePack) { $item in
                                datePackRow(item: $item)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .mainBackground()
    }

    private func datePackRow(item: Binding<DatePackItem>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.wrappedValue.venue.name)
                    .font(DesignSystem.Typography.headerMedium())
                    .foregroundColor(DesignSystem.Colors.ink)
                Spacer()
                Button(role: .destructive) {
                    viewModel.removeFromDatePack(item.wrappedValue)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(DesignSystem.Colors.loveRed)
                        .font(.system(size: 20, weight: .bold))
                }
            }
            
            Text(item.wrappedValue.venue.address)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.ink.opacity(0.7))
            
            Divider()
                .overlay(DesignSystem.Colors.ink)
            
            DatePicker("When", selection: item.scheduledAt)
                .font(DesignSystem.Typography.body())
                .tint(DesignSystem.Colors.genieBlue)
                .foregroundColor(DesignSystem.Colors.ink)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.ink)
                
                TextField("Booking info, ideas...", text: item.note)
                    .font(DesignSystem.Typography.body())
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DesignSystem.Colors.ink, lineWidth: 2)
                    )
            }
            
            if let url = URL(string: item.wrappedValue.venue.bookingUrl) {
                Link(destination: url) {
                    HStack {
                        Text("Open booking / site")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.genieBlue)
                    .underline()
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DesignSystem.Colors.ink, lineWidth: 3)
        )
        .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 4, y: 4)
    }
}
