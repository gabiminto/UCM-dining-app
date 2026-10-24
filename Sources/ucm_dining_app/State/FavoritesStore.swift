import Foundation
import Observation

@Observable
@MainActor
public final class FavoritesStore {
    public var favorites: [FavoriteDish] = [] {
        didSet { save() }
    }

    private let storageKey = "ucm_dining_favorites_v1"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([FavoriteDish].self, from: data) {
            self.favorites = decoded
        }
    }

    public func isFavorite(item: MenuItemSummary) -> Bool {
        favorites.contains {
            $0.menuItemId == item.id || $0.name.caseInsensitiveCompare(item.name) == .orderedSame
        }
    }

    public func toggleFavorite(item: MenuItemSummary, locationName: String) {
        if let existingIndex = favorites.firstIndex(where: {
            $0.menuItemId == item.id || $0.name.caseInsensitiveCompare(item.name) == .orderedSame
        }) {
            favorites.remove(at: existingIndex)
        } else {
            let fav = FavoriteDish(
                menuItemId: item.id,
                name: item.name,
                stationCategory: item.station.category,
                locationName: locationName,
                cleanDescription: item.cleanDescription,
                caloriesBadge: item.displayCaloriesBadge
            )
            favorites.insert(fav, at: 0)
        }
    }

    public func removeFavorite(id: String) {
        favorites.removeAll { $0.id == id }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
}
