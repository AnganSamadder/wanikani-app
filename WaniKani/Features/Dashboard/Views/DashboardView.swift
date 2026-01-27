import SwiftUI
import WaniKaniCore

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel(persistence: .shared)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let user = viewModel.user {
                    UserProfileHeader(user: user)
                } else {
                    Text("Welcome Guest")
                        .font(.largeTitle)
                }
                
                HStack(spacing: 16) {
                    StatusCard(title: "Lessons", count: 0, color: .pink)
                    StatusCard(title: "Reviews", count: 0, color: .blue)
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Dashboard")
        .refreshable {
            await viewModel.refresh()
        }
    }
}

struct UserProfileHeader: View {
    let user: User
    
    var body: some View {
        VStack {
            Text(user.username)
                .font(.title)
                .bold()
            Text("Level \(user.level)")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatusCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(color)
        .cornerRadius(16)
    }
}
