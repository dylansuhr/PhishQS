import SwiftUI

// Home screen displaying latest setlist without card styling
struct TourDashboardView: View {
    @State private var showingDateSearch = false

    var body: some View {
        VStack(spacing: 20) {
            // Latest setlist display (no card styling)
            LatestSetlistView()
            
            Spacer()
            
            // Search by date button
            Button(action: {
                showingDateSearch = true
            }) {
                Text("search by date")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .cornerRadius(25)
            }
            .padding(.bottom, 20)
        }
        .padding()
        .background(Color(.systemGray6))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("QS_transparent")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 28)
            }
        }
        .sheet(isPresented: $showingDateSearch) {
            NavigationStack {
                YearListView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        TourDashboardView()
    }
}