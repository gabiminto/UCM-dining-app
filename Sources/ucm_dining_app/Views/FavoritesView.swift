import SwiftUI

public struct FavoritesView: View {
    public let favoritesStore: FavoritesStore
    public let diningViewModel: DiningViewModel
    public let onBrowseMenus: () -> Void

    public init(
        favoritesStore: FavoritesStore,
        diningViewModel: DiningViewModel,
        onBrowseMenus: @escaping () -> Void
    ) {
        self.favoritesStore = favoritesStore
        self.diningViewModel = diningViewModel
        self.onBrowseMenus = onBrowseMenus
    }

    public var body: some View {
        NavigationStack {
            Group {
                if favoritesStore.favorites.isEmpty {
                    ContentUnavailableView {
                        Label("No Saved Favorites", systemImage: "heart")
                    } description: {
                        Text("Save dishes to quickly find them whenever they’re being served.")
                    } actions: {
                        Button("Browse Menus", action: onBrowseMenus)
                            .buttonStyle(.borderedProminent)
                            .tint(UCMTheme.navy)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(favoritesStore.favorites) { fav in
                            let servingNow = diningViewModel.menuItems.contains {
                                $0.id == fav.menuItemId || $0.name.caseInsensitiveCompare(fav.name) == .orderedSame
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(fav.name)
                                        .font(.headline)
                                    if servingNow {
                                        Text("SERVING NOW")
                                            .font(.system(size: 10, weight: .heavy))
                                            .foregroundStyle(UCMTheme.deepNavy)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2)
                                            .background(UCMTheme.safeGreen, in: Capsule())
                                    }
                                    Spacer()
                                    if let cal = fav.caloriesBadge {
                                        Text(cal)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(fav.cleanDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                            .swipeActions {
                                Button(role: .destructive) {
                                    favoritesStore.removeFavorite(id: fav.id)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved Favorites")
        }
    }
}
