import SwiftUI

public struct DishDetailSheetView: View {
    public let item: MenuItemSummary
    public let location: DiningLocation
    public let mealName: String
    public let favoritesStore: FavoritesStore

    @State internal var detailVM: DishDetailViewModel
    @Environment(\.dismiss) internal var dismiss

    public init(
        item: MenuItemSummary,
        location: DiningLocation,
        mealName: String,
        companyId: String,
        dietaryProfile: UserDietaryProfile,
        favoritesStore: FavoritesStore
    ) {
        self.item = item
        self.location = location
        self.mealName = mealName
        self.favoritesStore = favoritesStore
        _detailVM = State(
            initialValue: DishDetailViewModel(
                itemSummary: item,
                location: location,
                companyId: companyId,
                dietaryProfile: dietaryProfile
            )
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    dishHeaderSection
                    macroQuickPillsSection

                    if detailVM.isLoadingDetail {
                        HStack {
                            Spacer()
                            ProgressView("Loading interactive choices & nutrition...")
                                .padding(.vertical, 24)
                            Spacer()
                        }
                    } else {
                        choicesCustomizationSection
                    }

                    FDANutritionLabelView(
                        nutrition: detailVM.scaledNutrition,
                        isRecalculating: detailVM.isRecalculatingNutrition
                    )

                    if !detailVM.variationDetails.isEmpty {
                        ingredientsBreakdownSection
                    }
                }
                .padding(16)
            }
            .background(UCMTheme.screenBackground)
            .navigationTitle(item.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        favoritesStore.toggleFavorite(item: item, locationName: location.displayName)
                    } label: {
                        Image(systemName: favoritesStore.isFavorite(item: item) ? "heart.fill" : "heart")
                            .foregroundStyle(favoritesStore.isFavorite(item: item) ? .red : .primary)
                    }
                }
            }
            .task {
                await detailVM.loadDetailAndNutrition()
            }
        }
    }

    internal var dishHeaderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(location.displayName) • \(mealName)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(item.cleanDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task { await detailVM.applyPlantBasedSmartSwap() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.arrow.triangle.circlepath")
                    Text(detailVM.smartSwapApplied ? "Plant-Forward Swap Applied" : "One-Tap Plant-Based Swap")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(UCMTheme.safeGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(UCMTheme.safeGreen.opacity(0.12), in: Capsule())
                .ucmGlassCard(interactive: true)
            }
            .buttonStyle(.plain)
        }
    }

    internal var ViewModelAccessor: DishDetailViewModel { detailVM }
}
