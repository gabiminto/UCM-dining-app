import SwiftUI

public struct UCMDiningRootView: View {
    @State private var dietaryStore: DietaryProfileStore
    @State private var favoritesStore: FavoritesStore
    @State private var diningViewModel: DiningViewModel
    @State private var selectedTab: Int = 0

    public init() {
        let dietary = DietaryProfileStore()
        let favs = FavoritesStore()
        _dietaryStore = State(initialValue: dietary)
        _favoritesStore = State(initialValue: favs)
        _diningViewModel = State(initialValue: DiningViewModel(dietaryStore: dietary))
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            MenuExplorerView(
                viewModel: diningViewModel,
                dietaryStore: dietaryStore,
                favoritesStore: favoritesStore
            )
            .tabItem {
                Label("Menus", systemImage: "fork.knife")
            }
            .tag(0)

            FavoritesView(
                favoritesStore: favoritesStore,
                diningViewModel: diningViewModel,
                onBrowseMenus: { selectedTab = 0 }
            )
            .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }
            .badge(favoritesStore.favorites.count)
            .tag(1)

            DietaryProfileView(
                dietaryStore: dietaryStore,
                onPreferencesChanged: {
                    Task {
                        await diningViewModel.refreshCurrentMenu()
                    }
                }
            )
            .tabItem {
                Label("Dietary & Goals", systemImage: "checkmark.shield.fill")
            }
            .tag(2)
        }
        .tint(UCMTheme.navy)
        .task {
            await diningViewModel.bootstrap()
        }
        .onOpenURL { url in
            guard url.scheme == "ucmdining", url.host == "menu" else { return }
            selectedTab = 0
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let requestedLocation = components?.queryItems?.first(where: { $0.name == "location" })?.value
            let location = requestedLocation == DiningHallIntentValue.ywdc.rawValue
                ? DiningLocation.ywdc
                : DiningLocation.thePavilion
            Task {
                await diningViewModel.selectLocation(location)
            }
        }
    }
}
