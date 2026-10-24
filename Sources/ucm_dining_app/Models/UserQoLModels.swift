import Foundation

// MARK: - User Dietary Profile & Favorites

public struct UserDietaryProfile: Codable, Equatable, Sendable {
    public var selectedAllergenIds: Set<String>
    public var selectedLifestyleIds: Set<String>
    public var crossContactSensitive: Bool
    public var showOnlySafeItems: Bool
    public var showMacroRatiosOnCards: Bool

    public init(
        selectedAllergenIds: Set<String> = [],
        selectedLifestyleIds: Set<String> = [],
        crossContactSensitive: Bool = false,
        showOnlySafeItems: Bool = false,
        showMacroRatiosOnCards: Bool = true
    ) {
        self.selectedAllergenIds = selectedAllergenIds
        self.selectedLifestyleIds = selectedLifestyleIds
        self.crossContactSensitive = crossContactSensitive
        self.showOnlySafeItems = showOnlySafeItems
        self.showMacroRatiosOnCards = showMacroRatiosOnCards
    }

    enum CodingKeys: String, CodingKey {
        case selectedAllergenIds, selectedLifestyleIds, crossContactSensitive, showOnlySafeItems
        case showMacroRatiosOnCards
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        selectedAllergenIds = try c.decodeIfPresent(Set<String>.self, forKey: .selectedAllergenIds) ?? []
        selectedLifestyleIds = try c.decodeIfPresent(Set<String>.self, forKey: .selectedLifestyleIds) ?? []
        crossContactSensitive = try c.decodeIfPresent(Bool.self, forKey: .crossContactSensitive) ?? false
        showOnlySafeItems = try c.decodeIfPresent(Bool.self, forKey: .showOnlySafeItems) ?? false
        showMacroRatiosOnCards = try c.decodeIfPresent(Bool.self, forKey: .showMacroRatiosOnCards) ?? true
    }

    public var hasActiveFilters: Bool {
        !selectedAllergenIds.isEmpty || !selectedLifestyleIds.isEmpty
    }

    public var activeFilterCount: Int {
        selectedAllergenIds.count + selectedLifestyleIds.count
    }
}

public struct FavoriteDish: Codable, Identifiable, Equatable, Sendable {
    public var id: String { menuItemId }
    public let menuItemId: String
    public let name: String
    public let stationCategory: StationCategory
    public let locationName: String
    public let cleanDescription: String
    public let caloriesBadge: String?
    public let savedAt: Date

    public init(
        menuItemId: String,
        name: String,
        stationCategory: StationCategory,
        locationName: String,
        cleanDescription: String,
        caloriesBadge: String? = nil,
        savedAt: Date = Date()
    ) {
        self.menuItemId = menuItemId
        self.name = name
        self.stationCategory = stationCategory
        self.locationName = locationName
        self.cleanDescription = cleanDescription
        self.caloriesBadge = caloriesBadge
        self.savedAt = savedAt
    }
}
