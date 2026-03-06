import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PlayerProfile]
    @Query private var champions: [Champion]

    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showResetConfirm = false
    @State private var audioEnabled = true

    private var profile: PlayerProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                GameTheme.darkNavy.ignoresSafeArea()

                if let profile {
                    ScrollView {
                        VStack(spacing: 24) {
                            avatarSection(profile)
                            statsGrid(profile)
                            championRoster(profile)
                            settingsSection(profile)
                        }
                        .padding(.bottom, 40)
                    }
                } else {
                    ProgressView()
                        .tint(GameTheme.gold)
                }
            }
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Edit Name", isPresented: $isEditingName) {
                TextField("Player Name", text: $editedName)
                Button("Save") {
                    SaveSystem.updateDisplayName(editedName, context: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Reset Progress?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) {
                    SaveSystem.resetProgress(context: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset your wins, losses, and currency. Your card collection and champions will be kept.")
            }
        }
    }

    // MARK: - Avatar & Name

    @ViewBuilder
    private func avatarSection(_ profile: PlayerProfile) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GameTheme.gold.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(GameTheme.gold)
            }
            .padding(.top, 20)

            Button {
                editedName = profile.displayName
                isEditingName = true
            } label: {
                HStack(spacing: 6) {
                    Text(profile.displayName)
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(GameTheme.gold.opacity(0.7))
                }
            }

            // Currency
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(GameTheme.gold)
                Text("\(profile.currency)")
                    .font(.title3.bold())
                    .foregroundColor(GameTheme.gold)
            }
        }
    }

    // MARK: - Stats Grid

    @ViewBuilder
    private func statsGrid(_ profile: PlayerProfile) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(title: "Wins", value: "\(profile.totalWins)", icon: "trophy.fill")
            StatCard(title: "Losses", value: "\(profile.totalLosses)", icon: "xmark.shield.fill")
            StatCard(title: "Games", value: "\(profile.totalGames)", icon: "gamecontroller.fill")
        }
        .padding(.horizontal)

        // Win rate bar
        if profile.totalGames > 0 {
            VStack(spacing: 6) {
                Text("Win Rate: \(Int(profile.winRate * 100))%")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(GameTheme.gold)
                            .frame(width: Swift.max(0, geo.size.width * profile.winRate))
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Champion Roster

    @ViewBuilder
    private func championRoster(_ profile: PlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHAMPION ROSTER")
                .font(.caption.bold())
                .foregroundColor(GameTheme.gold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(champions) { champion in
                        let isUnlocked = profile.unlockedChampions.contains { $0.id == champion.id }
                        championPortrait(champion, unlocked: isUnlocked)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func championPortrait(_ champion: Champion, unlocked: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(unlocked ? GameTheme.cardBackground : Color.black.opacity(0.5))
                    .frame(width: 64, height: 64)

                if unlocked {
                    Image(systemName: archetypeIcon(champion.archetype))
                        .font(.title2)
                        .foregroundColor(GameTheme.rarityColor(champion.rarity))
                } else {
                    Image(systemName: "person.fill.questionmark")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.4))
                }
            }

            Text(unlocked ? champion.name : "???")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(unlocked ? .white : .gray.opacity(0.4))
                .lineLimit(1)
                .frame(width: 64)
        }
    }

    private func archetypeIcon(_ archetype: Archetype) -> String {
        switch archetype {
        case .warrior: return "shield.fill"
        case .rogue: return "swift"
        case .mage: return "wand.and.stars"
        case .paladin: return "cross.fill"
        case .berserker: return "flame.fill"
        case .shadow: return "moon.fill"
        }
    }

    // MARK: - Settings

    @ViewBuilder
    private func settingsSection(_ profile: PlayerProfile) -> some View {
        VStack(spacing: 0) {
            Text("SETTINGS")
                .font(.caption.bold())
                .foregroundColor(GameTheme.gold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)

            VStack(spacing: 1) {
                // Remove Ads
                settingsRow(icon: "xmark.circle.fill", title: "Remove Ads") {
                    if profile.hasRemovedAds {
                        Text("OWNED")
                            .font(.caption.bold())
                            .foregroundColor(GameTheme.hpGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(GameTheme.hpGreen.opacity(0.15))
                            .clipShape(Capsule())
                    } else {
                        Button("$2.99") {
                            SaveSystem.toggleRemoveAds(context: modelContext)
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(GameTheme.gold)
                        .clipShape(Capsule())
                    }
                }

                // Audio toggle
                settingsRow(icon: audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                            title: "Audio") {
                    Toggle("", isOn: $audioEnabled)
                        .labelsHidden()
                        .tint(GameTheme.gold)
                }

                // Reset Progress
                settingsRow(icon: "arrow.counterclockwise", title: "Reset Progress") {
                    Button("Reset") {
                        showResetConfirm = true
                    }
                    .font(.caption.bold())
                    .foregroundColor(GameTheme.hpRed)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(GameTheme.hpRed.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
    }

    @ViewBuilder
    private func settingsRow<Trailing: View>(
        icon: String,
        title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(GameTheme.gold)
                .frame(width: 28)

            Text(title)
                .font(.body)
                .foregroundColor(.white)

            Spacer()

            trailing()
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(GameTheme.gold)

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
