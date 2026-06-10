import SwiftUI

/// Paged tutorial shown on first launch and available from the Play tab.
struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let pages: [TutorialPage] = [
        TutorialPage(
            icon: "shield.lefthalf.filled",
            title: "Welcome to Arena Raiders",
            lines: [
                "A dice-driven card battler in two acts.",
                "Raid the vault for treasure, gear up, then face a champion in the arena.",
                "Win matches to earn gold, open packs, and grow your collection."
            ]
        ),
        TutorialPage(
            icon: "dice.fill",
            title: "The Raid",
            lines: [
                "Roll the D20 to crack open three treasure chests.",
                "1–9 is a MISS (+1 resource), 10–18 is a HIT (damage + 3 resources), 19–20 can CRIT for double damage and 5 resources.",
                "Break all three chests to advance to the arena."
            ]
        ),
        TutorialPage(
            icon: "rectangle.stack.fill",
            title: "Play Your Cards",
            lines: [
                "Spend resources to play cards from your hand — tap once to select, tap again to play.",
                "Gear equips to your head, chest, hands, feet, and weapon slots and wears down with use.",
                "Talents are permanent boosts; abilities and adventures give one-shot or delayed effects."
            ]
        ),
        TutorialPage(
            icon: "bolt.fill",
            title: "The Arena",
            lines: [
                "Face an AI champion in a duel to zero HP.",
                "Attack once per turn: your roll plus attack bonuses must beat their Avoidance, and Mitigation soaks damage.",
                "End your turn to refresh — but your opponent strikes back first!"
            ]
        ),
        TutorialPage(
            icon: "dollarsign.circle.fill",
            title: "Earn & Collect",
            lines: [
                "Victories earn gold — concede and you get nothing.",
                "Spend gold on card packs in the Shop and claim your daily bonus.",
                "Build 40-card decks in the Collection tab to find your winning strategy."
            ]
        )
    ]

    var body: some View {
        ZStack {
            GameTheme.darkNavy.ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .accessibilityLabel("Close tutorial")
                }
                .padding([.top, .horizontal])

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, tutorialPage in
                        pageView(tutorialPage)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    SoundManager.shared.play(.buttonTap)
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        dismiss()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "NEXT" : "LET'S RAID!")
                        .font(.headline)
                        .foregroundColor(GameTheme.darkNavy)
                        .frame(maxWidth: 320)
                        .padding(.vertical, 14)
                        .background(GameTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.bottom, 16)
                .accessibilityLabel(page < pages.count - 1 ? "Next page" : "Finish tutorial")
            }
        }
        .presentationBackground(GameTheme.darkNavy)
    }

    @ViewBuilder
    private func pageView(_ tutorialPage: TutorialPage) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: tutorialPage.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(GameTheme.gold)
                    .padding(.top, 8)

                Text(tutorialPage.title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(tutorialPage.lines.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 7))
                                .foregroundColor(GameTheme.gold)
                                .padding(.top, 5)

                            Text(line)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 36)
            }
        }
    }
}

private struct TutorialPage {
    let icon: String
    let title: String
    let lines: [String]
}

#Preview {
    HowToPlayView()
}
