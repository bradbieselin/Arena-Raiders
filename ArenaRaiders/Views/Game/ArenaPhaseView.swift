import SwiftUI

struct ArenaPhaseView: View {
    @Bindable var vm: GameViewModel

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // MARK: - Left: Player Champion
                playerPanel
                    .frame(width: 180)
                    .padding(.leading, 16)

                Spacer(minLength: 8)

                // MARK: - Center: Attack + Hand
                centerPanel
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 8)

                // MARK: - Right: AI Champion
                opponentPanel
                    .frame(width: 180)
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 12)

            // Roll overlay
            if vm.showRoll, let roll = vm.rollResult {
                RollOverlayView(
                    rollValue: roll,
                    label: vm.rollLabel,
                    labelColor: vm.rollColor
                )
                .allowsHitTesting(false)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Player Panel (Left)

    private var playerPanel: some View {
        VStack(spacing: 12) {
            Spacer()

            // Player avatar
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(GameTheme.surfaceDark)
                    .frame(width: 80, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(GameTheme.gold.opacity(0.4), lineWidth: 1)
                    )

                VStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(GameTheme.gold)
                    Text("YOU")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Name
            Text(vm.championName)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            // HP bar
            HPBarView(current: vm.playerHP, max: vm.playerMaxHP, height: 16)
                .frame(width: 150)

            // Gear slots
            GearSlotsView(gear: vm.activeGear, compact: true)

            // Resources
            ResourceCounterView(amount: vm.playerResources, pulse: vm.resourcePulse)

            Spacer()
        }
    }

    // MARK: - Center Panel (Attack + Hand)

    private var centerPanel: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("ARENA COMBAT")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(GameTheme.hpRed.opacity(0.7))
                .tracking(3)

            // Attack button
            Button(action: { vm.attackOpponent() }) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 22))
                    Text("ATTACK")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 50)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [GameTheme.hpRed, GameTheme.hpRed.opacity(0.7)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: GameTheme.hpRed.opacity(0.4), radius: 12)
            }

            // Player hand (horizontal scroll below attack button)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.hand) { card in
                        CardView(
                            card: card,
                            isSelected: vm.selectedCardID == card.id,
                            isAffordable: card.resourceCost <= vm.playerResources
                        )
                        .onTapGesture { vm.selectCard(card) }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 130)

            Spacer()
        }
    }

    // MARK: - Opponent Panel (Right)

    private var opponentPanel: some View {
        VStack(spacing: 12) {
            Spacer()

            // AI avatar
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(GameTheme.surfaceDark)
                    .frame(width: 80, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(GameTheme.hpRed.opacity(0.4), lineWidth: 1)
                    )

                VStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(GameTheme.hpRed)
                    Text("AI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Name
            Text(vm.aiName)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            // HP bar
            HPBarView(current: vm.aiHP, max: vm.aiMaxHP, height: 16)
                .frame(width: 150)

            // Gear slots
            GearSlotsView(gear: vm.aiGear, compact: true)

            Spacer()
        }
    }
}
