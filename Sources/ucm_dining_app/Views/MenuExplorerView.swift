import SwiftUI

public struct MenuExplorerView: View {
    @Bindable public var viewModel: DiningViewModel
    public let dietaryStore: DietaryProfileStore
    public let favoritesStore: FavoritesStore

    @State internal var selectedItemForSheet: MenuItemSummary?
    @State internal var showingHoursSheet: Bool = false

    public init(
        viewModel: DiningViewModel,
        dietaryStore: DietaryProfileStore,
        favoritesStore: FavoritesStore
    ) {
        self.viewModel = viewModel
        self.dietaryStore = dietaryStore
        self.favoritesStore = favoritesStore
    }

    public var body: some View {
        VStack(spacing: 0) {
            MenuHeroHeaderView(
                locations: viewModel.locations,
                selectedLocation: viewModel.selectedLocation,
                serviceStatus: viewModel.serviceStatus,
                onSelectLocation: { loc in
                    Task { await viewModel.selectLocation(loc) }
                },
                onOpenHours: { showingHoursSheet = true }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    daySelectorStrip
                    mealCategoryStrip

                    if !favoritesServingNow.isEmpty {
                        favoritesSpotlightSection
                    }

                    dishesListSection
                }
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
            .background(UCMTheme.screenBackground)
            .refreshable {
                await viewModel.refreshCurrentMenu()
            }
        }
        .background(UCMTheme.screenBackground)
        .sheet(item: $selectedItemForSheet) { item in
            DishDetailSheetView(
                item: item,
                location: viewModel.selectedLocation,
                mealName: viewModel.selectedCategory?.displayName ?? "Meal",
                companyId: viewModel.companyId,
                dietaryProfile: dietaryStore.profile,
                favoritesStore: favoritesStore
            )
        }
        .sheet(isPresented: $showingHoursSheet) {
            DiningHoursSheetView()
        }
    }

    internal var favoritesServingNow: [MenuItemSummary] {
        viewModel.menuItems.filter { favoritesStore.isFavorite(item: $0) }
    }
}
