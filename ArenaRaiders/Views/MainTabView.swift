import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    private let darkNavy = Color(red: 15/255, green: 23/255, blue: 42/255)
    private let gold = Color(red: 255/255, green: 215/255, blue: 0/255)

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            PlayView()
                .tabItem {
                    Label(Tab.play.title, systemImage: Tab.play.systemImage)
                }
                .tag(Tab.play)

            CardCollectionView()
                .tabItem {
                    Label(Tab.collection.title, systemImage: Tab.collection.systemImage)
                }
                .tag(Tab.collection)

            ShopView()
                .tabItem {
                    Label(Tab.shop.title, systemImage: Tab.shop.systemImage)
                }
                .tag(Tab.shop)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.title, systemImage: Tab.profile.systemImage)
                }
                .tag(Tab.profile)
        }
        .tint(gold)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
