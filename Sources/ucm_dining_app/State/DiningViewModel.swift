import Foundation
import Observation

@Observable
@MainActor
public final class DiningViewModel {
    public var companyId: String = "61bd7ecd8c760e0011ac0fac"
    public var locations: [DiningLocation] = DiningLocation.defaultLocations
    public var selectedLocation: DiningLocation = .thePavilion

    public var dayGroups: [DayMenuGroup] = SampleMenuCatalog.pavilionDays
    public var selectedDayGroup: DayMenuGroup?

    public var mealCategories: [MealCategory] = SampleMenuCatalog.pavilionCategories
    public var selectedCategory: MealCategory?

    public var menuItems: [MenuItemSummary] = []
    public var weeklyPoolItems: [MenuItemSummary] = SampleMenuCatalog.samplePavilionItems
    public var itemMacroSnapshots: [String: ItemMacroSnapshot] = [:]
    public var showMacroRatioOnCards: Bool = true
    public var selectedStation: StationCategory = .all
    public var searchQuery: String = ""

    public var isLoadingOverview: Bool = false
    public var isLoadingItems: Bool = false
    public var errorMessage: String?
    public var isOfflineCachedMode: Bool = false

    internal let apiClient: BigZpoonAPIClient
    internal let cacheStore: MenuCacheStore
    public let dietaryStore: DietaryProfileStore

    public init(
        apiClient: BigZpoonAPIClient = .shared,
        cacheStore: MenuCacheStore = .shared,
        dietaryStore: DietaryProfileStore
    ) {
        self.apiClient = apiClient
        self.cacheStore = cacheStore
        self.dietaryStore = dietaryStore
    }

    public var serviceStatus: ServiceStatusEvaluation {
        DiningScheduleEvaluator.evaluate(for: selectedLocation)
    }

    /// Weekly distribution of serving-normalized protein and carbohydrate values across the week's actual meals.
    public var weeklyMacroDistribution: WeeklyMacroDistribution {
        var combinedById: [String: ItemMacroSnapshot] = [:]
        for item in weeklyPoolItems where WeeklyMacroExtractor.isActualMeal(item: item) {
            combinedById[item.id] = itemMacroSnapshots[item.id] ?? WeeklyMacroExtractor.estimatedSnapshot(for: item)
        }
        for item in menuItems where WeeklyMacroExtractor.isActualMeal(item: item, categoryName: selectedCategory?.name) {
            combinedById[item.id] = itemMacroSnapshots[item.id] ?? WeeklyMacroExtractor.estimatedSnapshot(for: item)
        }
        for (id, snap) in itemMacroSnapshots {
            combinedById[id] = snap
        }
        let snapshots = Array(combinedById.values)
        return WeeklyMacroDistribution.compute(
            from: snapshots.isEmpty ? SampleMenuCatalog.samplePavilionItems.map(WeeklyMacroExtractor.estimatedSnapshot) : snapshots
        )
    }

    public func macroEvaluation(for item: MenuItemSummary) -> DishMacroEvaluation {
        let mealFlag = WeeklyMacroExtractor.isActualMeal(item: item, categoryName: selectedCategory?.name)
        let snapshot = itemMacroSnapshots[item.id] ?? WeeklyMacroExtractor.estimatedSnapshot(for: item)
        return weeklyMacroDistribution.evaluate(snapshot: snapshot, isActualMeal: mealFlag)
    }

    public func proteinCaloriesBadge(for item: MenuItemSummary) -> String? {
        guard WeeklyMacroExtractor.isActualMeal(item: item, categoryName: selectedCategory?.name) else {
            return item.displayCaloriesBadge
        }
        let snapshot = itemMacroSnapshots[item.id] ?? WeeklyMacroExtractor.estimatedSnapshot(for: item)
        return "\(snapshot.servingCalories) cal"
    }

    public var availableStations: [StationCategory] {
        var found = Set<StationCategory>()
        for item in menuItems {
            found.insert(item.station.category)
        }
        var ordered: [StationCategory] = [.all]
        for st in StationCategory.allCases where st != .all && found.contains(st) {
            ordered.append(st)
        }
        return ordered
    }

    public var filteredItems: [MenuItemSummary] {
        menuItems.filter { item in
            if selectedStation != .all && item.station.category != selectedStation {
                return false
            }
            if dietaryStore.profile.hasActiveFilters && dietaryStore.profile.showOnlySafeItems {
                if item.dietaryStatus == .restricted {
                    return false
                }
            }
            let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if !q.isEmpty {
                let matchesName = item.name.localizedCaseInsensitiveContains(q)
                let matchesDesc = item.cleanDescription.localizedCaseInsensitiveContains(q)
                let matchesStation = item.station.rawBadgeName.localizedCaseInsensitiveContains(q)
                if !(matchesName || matchesDesc || matchesStation) {
                    return false
                }
            }
            return true
        }
    }

    public func bootstrap() async {
        // Load cached overview if present
        if let cachedCompany = await cacheStore.load(CompanyData.self, forKey: "company_info") {
            self.companyId = cachedCompany.id
            if !cachedCompany.listSearchLocations.isEmpty {
                self.locations = cachedCompany.listSearchLocations
            }
        }
        // Fetch live company & preferences in parallel
        async let companyTask = try? apiClient.fetchCompany()
        async let prefsTask = try? apiClient.fetchPreferences(companyId: companyId, locationId: selectedLocation.id)

        if let company = await companyTask {
            self.companyId = company.id
            if !company.listSearchLocations.isEmpty {
                self.locations = company.listSearchLocations
            }
            await cacheStore.save(company, forKey: "company_info")
        }
        if let prefs = await prefsTask, !prefs.allergies.isEmpty {
            dietaryStore.availablePreferences = prefs
            await cacheStore.save(prefs, forKey: "preferences_\(selectedLocation.id)")
        }

        await loadLocationScheduleAndMenu(for: selectedLocation, autoSelectToday: true)

        Task { [weak self] in
            await self?.preloadAllMenusIfNeeded()
        }
    }

    public func selectLocation(_ location: DiningLocation) async {
        guard selectedLocation.id != location.id else { return }
        selectedLocation = location
        selectedStation = .all
        await loadLocationScheduleAndMenu(for: location, autoSelectToday: true)
    }

    public func selectDay(_ day: DayMenuGroup) async {
        setSelectedDay(day)
        await loadSelectedDay()
    }

    public func setSelectedDay(_ day: DayMenuGroup) {
        selectedDayGroup = day
        selectedStation = .all
    }

    public func loadSelectedDay() async {
        guard let selectedDayGroup else { return }
        await loadCategoriesAndItems(for: selectedDayGroup, autoSelectRecommendedMeal: false)
    }

    public func selectCategory(_ category: MealCategory) async {
        setSelectedCategory(category)
        await loadSelectedCategory()
    }

    public func setSelectedCategory(_ category: MealCategory) {
        selectedCategory = category
        selectedStation = .all
    }

    public func loadSelectedCategory() async {
        guard let selectedCategory else { return }
        if let day = selectedDayGroup {
            await loadMenuItems(day: day, category: selectedCategory)
        }
    }

    public func refreshCurrentMenu() async {
        if let day = selectedDayGroup, let category = selectedCategory {
            await loadMenuItems(day: day, category: category)
        } else {
            await loadLocationScheduleAndMenu(for: selectedLocation, autoSelectToday: true)
        }
    }
}
