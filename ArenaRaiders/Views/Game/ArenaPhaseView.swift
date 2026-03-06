import SwiftUI

struct ArenaPhaseView: View {
    @Bindable var vm: GameViewModel

    @State private var playerShake: Bool = false
    @State private var aiShake: Bool = false
    @State private var endTurnGlow: Bool = false

    var body: some View {
        ZStack {
            // Main layout
            VStack(spacing: 0) {
                // MARK: - Top: AI Opponent Zone
                aiZone
                    .frame(height: 90)

                // MARK: - Center: Battlefield (VS + Attack)
                centerBattlefield
                    .frame(maxHeight: .infinity)

                // MARK: - Bottom: Player Zone
                playerZone
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

    // MARK: - AI Zone (top)

    private var aiZone: some View {
        HStack(alignment: .top) {
            // AI Champion portrait (top-left)
            ChampionPortraitView(
                name: vm.aiName,
                currentHP: vm.aiHP,
                maxHP: vm.aiMaxHP,
                accentColor: GameTheme.hpRed,
                label: "AI"
            )
            .offset(x: aiShake ? -4 : 0)

            Spacer()

            // AI active gear spread across top-center
            HStack(spacing: 6) {
                GearSlotsView(gear: vm.aiGear, compact: true)
            }

            Spacer()

            // AI face-down hand (top-right)
            HStack(spacing: -10) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [GameTheme.hpRed.opacity(0.3), GameTheme.stoneDark],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 24, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(GameTheme.hpRed.opacity(0.2), lineWidth: 0.5)
                        )
                        .rotationEffect(.degrees(Double(i - 2) * 5))
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Center Battlefield

    private var centerBattlefield: some View {
        VStack(spacing: 16) {
            Spacer()

            // VS graphic
            ZStack {
                // Glow ring
                Circle()
                    .stroke(GameTheme.hpRed.opacity(0.15), lineWidth: 2)
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [GameTheme.hpRed.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)

                Text("VS")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [GameTheme.hpRed, GameTheme.hpRed.opacity(0.6)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: GameTheme.hpRed.opacity(0.4), radius: 8)
            }

            // ATTACK button (large, centered)
            Button(action: {
                vm.attackOpponent()
                // Trigger shake on AI portrait
                withAnimation(.spring(response: 0.1, dampingFraction: 0.2).repeatCount(4)) {
                    aiShake = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    aiShake = false
                }
            }) {
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
                        colors: [GameTheme.hpRed, GameTheme.hpRed.opacity(0.6)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: GameTheme.hpRed.opacity(0.5), radius: 12)
            }

            Spacer()
        }
    }

    // MARK: - Player Zone (bottom)

    private var playerZone: some View {
        VStack(spacing: 6) {
            // Fanned hand
            FannedHandView(
                cards: vm.hand,
                selectedCardID: vm.selectedCardID,
                playerResources: vm.playerResources,
                onTapCard: { card in vm.selectCard(card) }
            )
            .frame(height: 140)

            // Bottom HUD bar
            HStack(spacing: 12) {
                // Player champion portrait (bottom-left)
                ChampionPortraitView(
                    name: vm.championName,
                    currentHP: vm.playerHP,
                    maxHP: vm.playerMaxHP,
                    accentColor: GameTheme.gold,
                    label: "YOU"
                )
                .offset(x: playerShake ? -4 : 0)

                Spacer()

                // Gear slots
                GearSlotsView(gear: vm.activeGear, compact: true)

                // Mana crystals
                ManaCrystalBar(
                    available: vm.playerResources,
                    total: vm.playerResources,
                    pulse: vm.resourcePulse
                )

                // END TURN button
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
