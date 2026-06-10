import SwiftUI

struct GameScreenView: View {
    @State private var vm: GameViewModel

    init(session: GameSession) {
        _vm = State(initialValue: GameViewModel(session: session))
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 15/255, green: 23/255, blue: 42/255),
                    Color(red: 30/255, green: 41/255, blue: 59/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Phase content
            switch vm.phase {
            case .raid:
                RaidPhaseView(vm: vm)
            case .arena:
                ArenaPhaseView(vm: vm)
            }

            // Pause button
            if !vm.isGameOver && !vm.isPaused {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            SoundManager.shared.play(.buttonTap)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                vm.isPaused = true
                            }
                        } label: {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(10)
                        }
                        .accessibilityLabel("Pause game")
                    }
                    Spacer()
                }
            }

            // Pause overlay
            if vm.isPaused && !vm.isGameOver {
                PauseMenuView(vm: vm)
                    .transition(.opacity)
            }

            // Game over overlay
            if vm.isGameOver {
                GameOverView(vm: vm)
                    .transition(.opacity)
            }
        }
        .persistentSystemOverlays(.hidden)
    }
}

// MARK: - Pause Menu

struct PauseMenuView: View {
    @Bindable var vm: GameViewModel
    @Bindable private var settings = GameSettings.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { resume() }

            VStack(spacing: 16) {
                Text("PAUSED")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundColor(GameTheme.gold)

                VStack(spacing: 1) {
                    toggleRow(
                        icon: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        title: "Sound",
                        isOn: $settings.soundEnabled
                    )
                    toggleRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "Haptics",
                        isOn: $settings.hapticsEnabled
                    )
                }
                .frame(width: 280)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: resume) {
                    Text("RESUME")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(GameTheme.darkNavy)
                        .frame(width: 280)
                        .padding(.vertical, 14)
                        .background(GameTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Resume game")

                Button {
                    SoundManager.shared.play(.buttonTap)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.isPaused = false
                    }
                    vm.concede()
                } label: {
                    Text("CONCEDE MATCH")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(GameTheme.hpRed)
                        .frame(width: 280)
                        .padding(.vertical, 12)
                        .background(GameTheme.hpRed.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(GameTheme.hpRed.opacity(0.4), lineWidth: 1)
                        )
                }
                .accessibilityLabel("Concede match")
            }
            .padding(28)
            .background(GameTheme.surfaceDark)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(GameTheme.gold.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func resume() {
        SoundManager.shared.play(.buttonTap)
        withAnimation(.easeInOut(duration: 0.2)) {
            vm.isPaused = false
        }
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(GameTheme.gold)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Toggle(title, isOn: isOn)
                .labelsHidden()
                .tint(GameTheme.gold)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
    }
}
