import SwiftUI

struct RaidPhaseView: View {
    @Bindable var vm: GameViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: - Top: Treasure Chest
                chestSection
                    .padding(.top, 8)

                Spacer(minLength: 12)

                // MARK: - Middle: Hand of Cards
                handSection

                Spacer(minLength: 12)

                // MARK: - Bottom Bar
                bottomBar
                    .padding(.bottom, 8)
            }

            // MARK: - Roll Overlay
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

    // MARK: - Chest Section

    private var chestSection: some View {
        VStack(spacing: 12) {
            // Chest card
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(GameTheme.surfaceDark)
                        .frame(height: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(GameTheme.gold.opacity(0.3), lineWidth: 1)
                        )

                    VStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [GameTheme.gold, GameTheme.darkGold],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )

                        Text("Treasure Chest")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Tier \(vm.chest?.tier ?? 1)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(GameTheme.gold.opacity(0.7))
                    }
                }

                HPBarView(
                    current: vm.chestHP,
                    max: vm.chestMaxIntegrity,
                    height: 18,
                    showCracks: true
                )
            }
            .padding(.horizontal, 24)

            // Roll button
            Button(action: { vm.rollForChest() }) {
                HStack(spacing: 8) {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 18))
                    Text("ROLL")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                }
                .foregroundColor(GameTheme.darkNavy)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [GameTheme.gold, GameTheme.darkGold],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: GameTheme.gold.opacity(0.3), radius: 8)
            }
            .disabled(vm.chestDestroyed)
            .opacity(vm.chestDestroyed ? 0.4 : 1.0)
        }
    }

    // MARK: - Hand Section

    private var handSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Hand")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("Deck: \(vm.deckCount)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.hand) { card in
                        CardView(
                            card: card,
                            isSelected: vm.selectedCardID == card.id,
                            isAffordable: card.resourceCost <= vm.playerResources
                        )
                        .onTapGesture {
                            vm.selectCard(card)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .frame(height: 130)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 16) {
            // Champion avatar + HP
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(GameTheme.surfaceDark)
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(GameTheme.gold)
                }
                HPBarView(current: vm.playerHP, max: vm.playerMaxHP, height: 10)
                    .frame(width: 50)
            }

            // Resources
            ResourceCounterView(amount: vm.playerResources, pulse: vm.resourcePulse)

            Spacer()

            // Gear slots
            GearSlotsView(gear: vm.activeGear, compact: true)

            // End Turn
            Button(action: { vm.endTurn() }) {
                Text("END TURN")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16)
    }
}
