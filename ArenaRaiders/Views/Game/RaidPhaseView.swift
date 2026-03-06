import SwiftUI

struct RaidPhaseView: View {
    @Bindable var vm: GameViewModel

    @State private var endTurnGlow: Bool = false

    var body: some View {
        ZStack {
            // Main layout: top opponent zone, center battlefield, bottom player zone
            VStack(spacing: 0) {
                // MARK: - Top: Opponent Zone (face-down cards + deck)
                opponentZone
                    .frame(height: 50)

                // MARK: - Center: Battlefield
                centerBattlefield
                    .frame(maxHeight: .infinity)

                // MARK: - Bottom: Player Zone
                playerZone
            }

            // MARK: - Roll Overlay (center, over chest)
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

    // MARK: - Opponent Zone (top edge)

    private var opponentZone: some View {
        HStack {
            // Face-down cards fanned at top (decorative opponent hand)
            HStack(spacing: -14) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [GameTheme.stoneGray, GameTheme.stoneDark],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 28, height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(GameTheme.gold.opacity(0.15), lineWidth: 0.5)
                        )
                        .rotationEffect(.degrees(Double(i - 2) * 4))
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                }
            }
            .padding(.leading, 24)

            Spacer()

            // Deck icon (top-right)
            HStack(spacing: 4) {
                ZStack {
                    // Stacked card backs
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(GameTheme.stoneDark)
                            .frame(width: 22, height: 30)
                            .offset(x: CGFloat(i) * 1.5, y: CGFloat(-i) * 1.5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(GameTheme.gold.opacity(0.1), lineWidth: 0.5)
                                    .offset(x: CGFloat(i) * 1.5, y: CGFloat(-i) * 1.5)
                            )
                    }
                }
                Text("\(vm.deckCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.trailing, 24)
        }
    }

    // MARK: - Center Battlefield

    private var centerBattlefield: some View {
        HStack(spacing: 0) {
            // Left-center: Treasure Chest
            VStack(spacing: 10) {
                Spacer()

                // Chest card (large, upright)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [GameTheme.surfaceDark, GameTheme.cardBackground],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 140, height: 180)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(GameTheme.gold.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: GameTheme.gold.opacity(0.15), radius: 12)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 4)

                    VStack(spacing: 10) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [GameTheme.gold, GameTheme.darkGold],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .shadow(color: GameTheme.gold.opacity(0.3), radius: 8)

                        Text("Treasure Chest")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Tier \(vm.chest?.tier ?? 1)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(GameTheme.gold.opacity(0.7))
                    }
                }

                // Chest HP bar
                HPBarView(
                    current: vm.chestHP,
                    max: vm.chestMaxIntegrity,
                    height: 14,
                    showCracks: true
                )
                .frame(width: 140)

                // ROLL button
                Button(action: { vm.rollForChest() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 16))
                        Text("ROLL")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(GameTheme.darkNavy)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [GameTheme.gold, GameTheme.darkGold],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: GameTheme.gold.opacity(0.4), radius: 8)
                }
                .disabled(vm.chestDestroyed)
                .opacity(vm.chestDestroyed ? 0.4 : 1.0)

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right-center: Gear slots + adventures area
            VStack(spacing: 16) {
                Spacer()

                // Active gear display
                VStack(spacing: 6) {
                    Text("GEAR")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(2)
                    GearSlotsView(gear: vm.activeGear, compact: false)
                }

                Spacer()
            }
            .frame(width: 200)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Player Zone (bottom)

    private var playerZone: some View {
        VStack(spacing: 6) {
            // Fanned hand along bottom edge
            FannedHandView(
                cards: vm.hand,
                selectedCardID: vm.selectedCardID,
                playerResources: vm.playerResources,
                onTapCard: { card in vm.selectCard(card) }
            )
            .frame(height: 140)

            // Bottom HUD bar
            HStack(spacing: 12) {
                // Champion portrait (bottom-left)
                ChampionPortraitView(
                    name: vm.championName,
                    currentHP: vm.playerHP,
                    maxHP: vm.playerMaxHP,
                    accentColor: GameTheme.gold,
                    label: "YOU"
                )

                Spacer()

                // Mana crystals
                ManaCrystalBar(
                    available: vm.playerResources,
                    total: vm.playerResources,
                    pulse: vm.resourcePulse
                )

                // END TURN button (Hearthstone-style)
                Button(action: { vm.endTurn() }) {
                    Text("END TURN")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(GameTheme.darkNavy)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [GameTheme.hpGreen, GameTheme.hpGreen.opacity(0.7)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(
                            color: GameTheme.hpGreen.opacity(endTurnGlow ? 0.6 : 0.2),
                            radius: endTurnGlow ? 10 : 4
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                endTurnGlow = true
            }
        }
    }
}
