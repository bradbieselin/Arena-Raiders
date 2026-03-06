import SwiftUI

struct ArenaPhaseView: View {
    @Bindable var vm: GameViewModel

    @State private var aiShake: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Main HStack
                HStack(spacing: 0) {
                    // LEFT COLUMN - Player
                    leftColumn
                        .frame(width: 120)

                    // CENTER COLUMN - Attack
                    centerColumn

                    // RIGHT COLUMN - AI
                    rightColumn
                        .frame(width: 120)
                }
                .padding(.horizontal, 8)

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
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Left Column (Player)

    private var leftColumn: some View {
        VStack(spacing: 8) {
            // Player avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(GameTheme.gold)
                )
                .overlay(
                    Circle().stroke(GameTheme.gold.opacity(0.4), lineWidth: 2)
                )

            Text(vm.championName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            HPBarView(current: vm.playerHP, max: vm.playerMaxHP, height: 12)
                .frame(width: 100)

            Text("\(vm.playerHP) HP")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(GameTheme.hpGreen)

            Spacer()

            // Resource counter
            HStack(spacing: 4) {
                Text("🪙")
                    .font(.system(size: 14))
                Text("\(vm.playerResources)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(GameTheme.gold)
            }

            // Gear slots
            GearSlotsView(gear: vm.activeGear, compact: true)

            // END TURN button
            Button(action: { vm.endTurn() }) {
                Text("END TURN")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(GameTheme.darkNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(GameTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Center Column (Attack + Hand)

    private var centerColumn: some View {
        VStack(spacing: 8) {
            // ARENA pill
            Text("ARENA COMBAT")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(GameTheme.hpRed.opacity(0.6))
                .clipShape(Capsule())

            Spacer()

            // VS label
            Text("VS")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(GameTheme.hpRed)

            // ATTACK button
            Button(action: {
                vm.attackOpponent()
                withAnimation(.easeInOut(duration: 0.06).repeatCount(6, autoreverses: true)) {
                    aiShake = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 0.1)) { aiShake = false }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18))
                    Text("ATTACK")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(width: 200)
                .padding(.vertical, 14)
                .background(GameTheme.hpRed)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            // Player hand
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
                .padding(.horizontal, 8)
            }
            .frame(height: 106)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Right Column (AI)

    private var rightColumn: some View {
        VStack(spacing: 8) {
            // AI avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(GameTheme.hpRed)
                )
                .overlay(
                    Circle().stroke(GameTheme.hpRed.opacity(0.4), lineWidth: 2)
                )
                .offset(x: aiShake ? -4 : 0)

            Text(vm.aiName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            HPBarView(current: vm.aiHP, max: vm.aiMaxHP, height: 12)
                .frame(width: 100)

            Text("\(vm.aiHP) HP")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(GameTheme.hpRed)

            Spacer()

            // GEAR label
            Text("GEAR")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .tracking(2)

            GearSlotsView(gear: vm.aiGear, compact: true)
        }
        .padding(.vertical, 12)
    }
}
