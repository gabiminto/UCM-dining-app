import Foundation

extension DiningViewModel {
    /// Warms every day and meal period for both dining halls after the first launch.
    /// This intentionally avoids changing the user's current selection while populating disk storage.
    public func preloadAllMenusIfNeeded() async {
        let completionKey = "all_menus_preloaded_v1"
        if await cacheStore.load(Bool.self, forKey: completionKey) == true {
            await restorePreloadedMenusFromDisk()
            return
        }

        do {
            for location in DiningLocation.defaultLocations {
                let overview = try await apiClient.fetchLocationMenuOverview(
                    companyId: companyId,
                    locationId: location.id
                )
                await cacheStore.save(
                    overview,
                    forKey: "overview_\(location.id)",
                    expiresAt: menuCacheExpirationDate()
                )

                for day in overview.menuGroups.filter(\.isDayOfWeek) {
                    let categories = try await apiClient.fetchMealCategories(
                        companyId: companyId,
                        locationId: location.id,
                        dayGroupId: day.id
                    )
                    await cacheStore.save(
                        categories,
                        forKey: "categories_\(location.id)_\(day.id)",
                        expiresAt: menuCacheExpirationDate()
                    )
                    categoryMemoryCache[categoryMemoryKey(locationId: location.id, dayId: day.id)] = categories

                    for category in categories {
                        let items = try await apiClient.fetchMenuItems(
                            companyId: companyId,
                            locationId: location.id,
                            dayGroupId: day.id,
                            categoryId: category.id,
                            profile: dietaryStore.profile
                        )
                        let key = "items_\(location.id)_\(day.id)_\(category.id)_\(dietaryStore.profile.activeFilterCount)"
                        await cacheStore.save(items, forKey: key, expiresAt: menuCacheExpirationDate())
                        itemMemoryCache[itemMemoryKey(locationId: location.id, dayId: day.id, categoryId: category.id)] = items
                    }
                }
            }

            await cacheStore.save(true, forKey: completionKey, expiresAt: .distantFuture)
        } catch {
            // Leave the completion marker unset so the next launch resumes the preload attempt.
        }
    }

    public func loadLocationScheduleAndMenu(for location: DiningLocation, autoSelectToday: Bool) async {
        errorMessage = nil

        let evaluation = DiningScheduleEvaluator.evaluate(for: location)
        let cacheKey = "overview_\(location.id)"
        let cachedOverview = await cacheStore.loadCached(LocationMenuOverview.self, forKey: cacheKey)

        if let cachedOverview {
            applyOverview(cachedOverview.value, evaluation: evaluation, autoSelectToday: autoSelectToday)
            isOfflineCachedMode = cachedOverview.isExpired
            isLoadingOverview = false
            if let day = selectedDayGroup {
                await loadCategoriesAndItems(for: day, autoSelectRecommendedMeal: autoSelectToday)
            }
        } else {
            isLoadingOverview = true
        }

        do {
            let overview = try await apiClient.fetchLocationMenuOverview(companyId: companyId, locationId: location.id)
            await cacheStore.save(overview, forKey: cacheKey, expiresAt: menuCacheExpirationDate())
            isOfflineCachedMode = false
            applyOverview(overview, evaluation: evaluation, autoSelectToday: autoSelectToday)
        } catch {
            if let cachedOverview {
                isOfflineCachedMode = true
                applyOverview(cachedOverview.value, evaluation: evaluation, autoSelectToday: autoSelectToday)
            } else {
                isOfflineCachedMode = true
                dayGroups = SampleMenuCatalog.pavilionDays
                mealCategories = SampleMenuCatalog.pavilionCategories
                selectedDayGroup = pickDay(from: dayGroups, weekday: evaluation.currentWeekdayIndex)
                selectedCategory = pickCategory(from: mealCategories, recommended: evaluation.recommendedMealName)
                menuItems = SampleMenuCatalog.samplePavilionItems
            }
        }
        isLoadingOverview = false

        if let day = selectedDayGroup {
            await loadCategoriesAndItems(for: day, autoSelectRecommendedMeal: autoSelectToday)
        }
    }

    public func loadCategoriesAndItems(for day: DayMenuGroup, autoSelectRecommendedMeal: Bool) async {
        let evaluation = DiningScheduleEvaluator.evaluate(for: selectedLocation)
        let catCacheKey = "categories_\(selectedLocation.id)_\(day.id)"
        if let cached = await cacheStore.loadCached([MealCategory].self, forKey: catCacheKey), !cached.value.isEmpty {
            guard !Task.isCancelled, selectedDayGroup?.id == day.id else { return }
            mealCategories = cached.value
            categoryMemoryCache[categoryMemoryKey(locationId: selectedLocation.id, dayId: day.id)] = cached.value
            if autoSelectRecommendedMeal || selectedCategory == nil || !mealCategories.contains(where: { $0.id == selectedCategory?.id }) {
                selectedCategory = pickCategory(from: mealCategories, recommended: evaluation.recommendedMealName)
            }
            if let category = selectedCategory {
                await loadMenuItems(day: day, category: category, revalidate: false)
            }
        }

        do {
            let fetchedCategories = try await apiClient.fetchMealCategories(
                companyId: companyId,
                locationId: selectedLocation.id,
                dayGroupId: day.id
            )
            if !fetchedCategories.isEmpty {
                guard !Task.isCancelled, selectedDayGroup?.id == day.id else { return }
                mealCategories = fetchedCategories
                categoryMemoryCache[categoryMemoryKey(locationId: selectedLocation.id, dayId: day.id)] = fetchedCategories
                await cacheStore.save(fetchedCategories, forKey: catCacheKey, expiresAt: menuCacheExpirationDate())
            }
        } catch {
            guard !Task.isCancelled, selectedDayGroup?.id == day.id else { return }
            if let cached = await cacheStore.load([MealCategory].self, forKey: catCacheKey), !cached.isEmpty {
                mealCategories = cached
            }
        }

        guard !Task.isCancelled, selectedDayGroup?.id == day.id else { return }
        if autoSelectRecommendedMeal || selectedCategory == nil || !mealCategories.contains(where: { $0.id == selectedCategory?.id }) {
            selectedCategory = pickCategory(from: mealCategories, recommended: evaluation.recommendedMealName)
        }

        if let category = selectedCategory {
            await loadMenuItems(day: day, category: category)
        }
    }

    public func loadMenuItems(
        day: DayMenuGroup,
        category: MealCategory,
        revalidate: Bool = true
    ) async {
        errorMessage = nil
        let itemsCacheKey = "items_\(selectedLocation.id)_\(day.id)_\(category.id)_\(dietaryStore.profile.activeFilterCount)"
        let cachedItems = await cacheStore.loadCached([MenuItemSummary].self, forKey: itemsCacheKey)

        if let cachedItems {
            guard isCurrentSelection(day: day, category: category), !Task.isCancelled else { return }
            menuItems = cachedItems.value
            itemMemoryCache[itemMemoryKey(locationId: selectedLocation.id, dayId: day.id, categoryId: category.id)] = cachedItems.value
            isOfflineCachedMode = cachedItems.isExpired
            isLoadingItems = false
            if !revalidate { return }
        } else {
            isLoadingItems = true
        }

        var loadedItems: [MenuItemSummary] = []
        do {
            let items = try await apiClient.fetchMenuItems(
                companyId: companyId,
                locationId: selectedLocation.id,
                dayGroupId: day.id,
                categoryId: category.id,
                profile: dietaryStore.profile
            )
            loadedItems = items
            itemMemoryCache[itemMemoryKey(locationId: selectedLocation.id, dayId: day.id, categoryId: category.id)] = items
            isOfflineCachedMode = false
            await cacheStore.save(items, forKey: itemsCacheKey, expiresAt: menuCacheExpirationDate())
        } catch {
            if let cachedItems {
                loadedItems = cachedItems.value
                isOfflineCachedMode = true
            } else if menuItems.isEmpty {
                loadedItems = SampleMenuCatalog.samplePavilionItems
                isOfflineCachedMode = true
            } else {
                loadedItems = menuItems
            }
        }

        guard isCurrentSelection(day: day, category: category), !Task.isCancelled else { return }
        menuItems = loadedItems
        isLoadingItems = false
        await hydrateLiveMacroSnapshots(for: loadedItems, categoryName: category.name)
    }

    public func hydrateLiveMacroSnapshots(for items: [MenuItemSummary], categoryName: String? = nil) async {
        let mealItems = items.filter {
            itemMacroSnapshots[$0.id] == nil && WeeklyMacroExtractor.isActualMeal(item: $0, categoryName: categoryName)
        }
        guard !mealItems.isEmpty else { return }

        let compId = companyId
        let locId = selectedLocation.id
        let profile = dietaryStore.profile
        let client = apiClient
        let cache = cacheStore

        let fetched: [(String, ItemMacroSnapshot)] = await withTaskGroup(of: (String, ItemMacroSnapshot)?.self) { group in
            for item in mealItems {
                group.addTask {
                    let snapKey = "protein_only_macro_snap_v3_\(item.id)"
                    if let cachedSnap = await cache.load(ItemMacroSnapshot.self, forKey: snapKey) {
                        return (item.id, cachedSnap)
                    }
                    do {
                        let detail = try await client.fetchMenuItemDetail(
                            companyId: compId,
                            locationId: locId,
                            menuItemId: item.id,
                            profile: profile
                        )
                        let defaultVarIds = detail.sortedChoices.flatMap { choice -> [String] in
                            let defs = choice.defaultSelectedVariationIds ?? choice.originalDefaultVariations ?? []
                            if !defs.isEmpty { return defs }
                            if choice.isMandatory, let first = choice.visibleVariations.first { return [first.id] }
                            return []
                        }
                        guard !defaultVarIds.isEmpty else { return nil }
                        let raw = try await client.fetchRawMaterialsAndNutrition(
                            companyId: compId,
                            locationId: locId,
                            menuItemId: item.id,
                            variationIds: defaultVarIds,
                            profile: profile
                        )
                        let snap = WeeklyMacroExtractor.mainProteinSnapshot(
                            menuItemId: item.id,
                            detail: detail,
                            response: raw,
                            itemDescription: item.description
                        )
                        await cache.save(snap, forKey: snapKey)
                        return (item.id, snap)
                    } catch {
                        return nil
                    }
                }
            }
            var results: [(String, ItemMacroSnapshot)] = []
            for await pair in group {
                if let pair { results.append(pair) }
            }
            return results
        }

        for (id, snap) in fetched {
            itemMacroSnapshots[id] = snap
        }
    }

    private func applyOverview(
        _ overview: LocationMenuOverview,
        evaluation: ServiceStatusEvaluation,
        autoSelectToday: Bool
    ) {
        if let weekItems = overview.menuItems, !weekItems.isEmpty {
            weeklyPoolItems = weekItems
        }
        let validDays = overview.menuGroups
            .filter { $0.isDayOfWeek }
            .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
        if !validDays.isEmpty {
            dayGroups = validDays
        }
        if autoSelectToday || selectedDayGroup == nil {
            selectedDayGroup = pickDay(from: dayGroups, weekday: evaluation.currentWeekdayIndex)
        }
    }

    private func pickDay(from days: [DayMenuGroup], weekday: Int) -> DayMenuGroup? {
        days.first(where: { $0.weekdayIndex == weekday }) ?? days.first
    }

    private func pickCategory(from categories: [MealCategory], recommended: String) -> MealCategory? {
        categories.first(where: { $0.name.caseInsensitiveCompare(recommended) == .orderedSame })
            ?? categories.first(where: { $0.name.localizedCaseInsensitiveContains(recommended) })
            ?? categories.first
    }

    private func isCurrentSelection(day: DayMenuGroup, category: MealCategory) -> Bool {
        selectedDayGroup?.id == day.id && selectedCategory?.id == category.id
    }

    private func menuCacheExpirationDate(from now: Date = Date()) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DiningScheduleEvaluator.pacificTimeZone
        let refreshDeadline = now.addingTimeInterval(30 * 60)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        return min(refreshDeadline, nextDay ?? refreshDeadline)
    }

    private func restorePreloadedMenusFromDisk() async {
        for location in DiningLocation.defaultLocations {
            guard let overview = await cacheStore.load(LocationMenuOverview.self, forKey: "overview_\(location.id)") else {
                continue
            }
            for day in overview.menuGroups.filter(\.isDayOfWeek) {
                let categoryKey = "categories_\(location.id)_\(day.id)"
                guard let categories = await cacheStore.load([MealCategory].self, forKey: categoryKey) else {
                    continue
                }
                categoryMemoryCache[categoryMemoryKey(locationId: location.id, dayId: day.id)] = categories
                for category in categories {
                    let diskKey = "items_\(location.id)_\(day.id)_\(category.id)_\(dietaryStore.profile.activeFilterCount)"
                    if let items = await cacheStore.load([MenuItemSummary].self, forKey: diskKey) {
                        itemMemoryCache[itemMemoryKey(locationId: location.id, dayId: day.id, categoryId: category.id)] = items
                    }
                }
            }
        }
    }
}
