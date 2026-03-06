import SwiftUI

struct RaidPhaseView: View {
    @Bindable var vm: GameViewModel

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // MARK: - Left: Champion Info
                leftPanel
                    .frame(width: 160)
                    .padding(.leading, 16)

                Spacer(minLength: 8)

                // MARK: - Center: Treasure Chest
                centerPanel
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 8)

                // MARK: - Right: Player Hand
                rightPanel
                    .frame(width: 120)
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 12)

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

    // MARK: - Left Panel (Champion, HP, Resources, End Turn)

    private var leftPanel: some View {
        VStack(spacing: 12) {
            // Champion avatar
            ZStack {
                Circle()
                    .fill(GameTheme.surfaceDark)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(GameTheme.gold.opacity(0.4), lineWidth: 1)
                    )
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(GameTheme.gold)
            }

            // HP bar
            VStack(spacing: 2) {
                Text(vm.championName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                HPBarView(current: vm.playerHP, max: vm.playerMaxHP, height: 14)
                    .frame(width: 130)
            }

            // Resources
            ResourceCounterView(amount: vm.playerResources, pulse: vm.resourcePulse)

            // Gear slots
            GearSlotsView(gear: vm.activeGear, compact: true)

            Spacer()

            // Deck count
            HStack(spacing: 4) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                Text("Deck: \(vm.deckCount)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }

            // End Turn button
            Button(action: { vm.endTurn() }) {
                Text("END TURN")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Center Panel (Treasure Chest + Roll)

    private var centerPanel: some View {
        VStack(spacing: 16) {
            Spacer()

            // Chest card
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(GameTheme.surfaceDark)
                        .frame(width: 200, height: 130)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(GameTheme.gold.opacity(0.3), lineWidth: 1)
                        )

                    VStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [GameTheme.gold, GameTheme.darkGold],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )

                        Text("Treasure Chest")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Tier \(vm.chest?.tier ?? 1)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(GameTheme.gold.opacity(0.7))
                    }
                }

                HPBarView(
                    current: vm.chestHP,
                    max: vm.chestMaxIntegrity,
                    height: 16,
                    showCracks: true
                )
                .frame(width: 200)
            }

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

            Spacer()
        }
    }

    // MARK: - Right Panel (Vertical Hand of Cards)

    private var rightPanel: some View {
        VStack(spacing: 4) {
            Text("Hand")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
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
                .padding(.vertical, 4)
            }
        }
    }
}
