import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Query private var profiles: [PlayerProfile]

    private let darkNavy = Color(red: 15/255, green: 23/255, blue: 42/255)
    private let gold = Color(red: 255/255, green: 215/255, blue: 0/255)

    private var profile: PlayerProfile? {
        profiles.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                darkNavy.ignoresSafeArea()

                if let profile {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(gold.opacity(0.15))
                                    .frame(width: 100, height: 100)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(gold)
                            }
                            .padding(.top, 20)

                            Text(profile.displayName)
                                .font(.title.bold())
                                .foregroundColor(.white)

                            Text("\(profile.totalGames) Games Played")
                                .font(.subheadline)
                                .foregroundColor(gold)

                            // Stats grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                StatCard(title: "Wins", value: "\(profile.totalWins)", icon: "trophy.fill")
                                StatCard(title: "Losses", value: "\(profile.totalLosses)", icon: "xmark.shield.fill")
                                StatCard(title: "Cards", value: "\(profile.uniqueCardsOwned)", icon: "rectangle.stack.fill")
                                StatCard(title: "Currency", value: "\(profile.currency)", icon: "dollarsign.circle.fill")
                            }
                            .padding(.horizontal)

                            Spacer()
                        }
                    }
                } else {
                    ProgressView()
                        .tint(gold)
                }
            }
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    private let darkNavy = Color(red: 15/255, green: 23/255, blue: 42/255)
    private let gold = Color(red: 255/255, green: 215/255, blue: 0/255)

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(gold)

            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
        .modelContainer(for: PlayerProfile.self, inMemory: true)
}
