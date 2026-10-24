import SwiftUI

extension MenuExplorerView {
    internal var favoritesSpotlightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Your Favorites Serving Now", systemImage: "heart.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                Spacer()
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(favoritesServingNow) { favItem in
                        Button {
                            selectedItemForSheet = favItem
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                Text(favItem.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
    }

    internal var dishesListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.selectedCategory?.displayName ?? "Menu")
                    .font(.title3.weight(.bold))
                Spacer()
                Text("\(viewModel.filteredItems.count) items")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)

            if viewModel.isLoadingItems {
                HStack {
                    Spacer()
                    ProgressView("Loading Menu...")
                        .padding(.vertical, 32)
                    Spacer()
                }
            } else if viewModel.filteredItems.isEmpty {
                ContentUnavailableView(
                    "No Dishes Available",
                    systemImage: "fork.knife.circle",
                    description: Text("Try another meal period or adjust your dietary filters.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(viewModel.filteredItems) { item in
                    MenuItemCardView(
                        item: item,
                        macroEvaluation: viewModel.macroEvaluation(for: item),
                        caloriesBadge: viewModel.proteinCaloriesBadge(for: item),
                        showMacroRatio: dietaryStore.profile.showMacroRatiosOnCards,
                        isFavorite: favoritesStore.isFavorite(item: item),
                        onToggleFavorite: {
                            favoritesStore.toggleFavorite(
                                item: item,
                                locationName: viewModel.selectedLocation.displayName
                            )
                        },
                        onSelect: {
                            selectedItemForSheet = item
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
