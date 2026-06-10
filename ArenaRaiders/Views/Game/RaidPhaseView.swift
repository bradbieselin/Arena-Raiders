import SwiftUI

struct RaidPhaseView: View {
    @Bindable var vm: GameViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // LAYER 2 - Main HStack
                HStack(spacing: 0) {
                    // LEFT COLUMN - Player Info
                    leftColumn
                        .frame(width: 120)

                    // CENTER COLUMN - Battlefield
                    centerColumn

                    // RIGHT COLUMN - AI Info
                    rightColumn
                        .frame(width: 120)
                }
                .padding(.horizontal, 8)

                // Roll Overlay
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

            // Player name
            Text(vm.championName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            // HP bar
            HPBarView(current: vm.playerHP, max: vm.playerMaxHP, height: 12)
                .frame(width: 100)

            // HP number
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

    // MARK: - Center Column (Battlefield)

    private var centerColumn: some View {
        VStack(spacing: 8) {
            // YOUR TURN pill
            Text("YOUR TURN")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundColor(GameTheme.darkNavy)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(GameTheme.gold)
                .clipShape(Capsule())

            Spacer()

            // Treasure Chest card
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(GameTheme.darkNavy)
                    .frame(width: 140, height: 180)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(GameTheme.gold, lineWidth: 2)
                    )

                VStack(spacing: 8) {
                    Text("📦")
                        .font(.system(size: 36))
                    Text("Treasure Chest")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Tier \(vm.chest?.tier ?? 1)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GameTheme.gold.opacity(0.7))
                }
            }

            // Chest HP bar
            HPBarView(
                current: vm.chestHP,
                max: vm.chestMaxIntegrity,
                height: 12,
                showCracks: true
            )
            .frame(width: 160)

            // Chest HP fraction
            Text("\(vm.chestHP)/\(vm.chestMaxIntegrity)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            // ROLL button
            Button(action: { vm.rollForChest() }) {
                Text("ROLL")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(GameTheme.darkNavy)
                    .frame(width: 160)
                    .padding(.vertical, 10)
                    .background(GameTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(vm.chestDestroyed)
            .opacity(vm.chestDestroyed ? 0.4 : 1.0)

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

    // MARK: - Right Column (Raid Progress)

    private var rightColumn: some View {
        VStack(spacing: 8) {
            Text("RAID")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundColor(GameTheme.gold)
                .padding(.top, 8)

            // Chest progress indicators (3 chests per raid)
            VStack(spacing: 6) {
                ForEach(1...GameSession.maxChests, id: \.self) { tier in
                    chestProgressRow(tier: tier)
                }
            }
            .accessibilityLabel("\(vm.chestsBroken) of \(GameSession.maxChests) chests broken")

            Spacer()

            // Turn counter
            infoRow(icon: "clock.fill", label: "Turn \(vm.currentTurn)")

            // Deck & discard counts
            infoRow(icon: "rectangle.stack.fill", label: "Deck \(vm.deckCount)")
            infoRow(icon: "tray.fill", label: "Used \(vm.discardCount)")

            Spacer()

            // GEAR label
            Text("GEAR")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .tracking(2)

            // Player's equipped gear
            GearSlotsView(gear: vm.activeGear, compact: true)
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func chestProgressRow(tier: Int) -> some View {
        let isBroken = tier <= vm.chestsBroken
        let isCurrent = tier == vm.chestsBroken + 1

        HStack(spacing: 6) {
            Image(systemName: isBroken ? "checkmark.seal.fill" : "shippingbox.fill")
                .font(.system(size: 13))
                .foregroundColor(
                    isBroken ? GameTheme.hpGreen :
                    isCurrent ? GameTheme.gold : .white.opacity(0.25)
                )

            Text("Tier \(tier)")
                .font(.system(size: 11, weight: isCurrent ? .bold : .medium, design: .rounded))
                .foregroundColor(isCurrent ? .white : .white.opacity(isBroken ? 0.6 : 0.35))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(width: 100, alignment: .leading)
        .background(isCurrent ? GameTheme.gold.opacity(0.12) : Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func infoRow(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 100, alignment: .leading)
    }
}
