import SwiftUI

struct ArenaPhaseView: View {
    @Bindable var vm: GameViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: - Top: Opponent Champion
                opponentSection
                    .padding(.top, 12)

                Spacer(minLength: 16)

                // MARK: - Middle: Attack Button
                attackSection

                Spacer(minLength: 16)

                // MARK: - Bottom: Player Champion
                playerSection
                    .padding(.bottom, 12)
            }

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

    // MARK: - Opponent Section

    private var opponentSection: some View {
        VStack(spacing: 10) {
            // Opponent card
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GameTheme.surfaceDark)
                        .frame(width: 70, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(GameTheme.hpRed.opacity(0.4), lineWidth: 1)
                        )

                    VStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundColor(GameTheme.hpRed)
                        Text("AI")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(vm.aiName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HPBarView(current: vm.aiHP, max: vm.aiMaxHP, height: 16)

                    GearSlotsView(gear: vm.aiGear, compact: true)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Attack Section

    private var attackSection: some View {
        VStack(spacing: 20) {
            Text("ARENA COMBAT")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(GameTheme.hpRed.opacity(0.7))
                .tracking(3)

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

            // Player hand in arena
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
        }
    }

    // MARK: - Player Section

    private var playerSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vm.championName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HPBarView(current: vm.playerHP, max: vm.playerMaxHP, height: 16)

                    HStack {
                        GearSlotsView(gear: vm.activeGear, compact: true)
                        Spacer()
                        ResourceCounterView(amount: vm.playerResources, pulse: vm.resourcePulse)
                    }
                }

                // Avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GameTheme.surfaceDark)
                        .frame(width: 70, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(GameTheme.gold.opacity(0.4), lineWidth: 1)
                        )

                    VStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundColor(GameTheme.gold)
                        Text("YOU")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
