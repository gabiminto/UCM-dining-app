import Foundation

extension BigZpoonAPIClient {
    public func fetchMenuItems(
        companyId: String? = nil,
        locationId: String,
        dayGroupId: String,
        categoryId: String,
        profile: UserDietaryProfile
    ) async throws -> [MenuItemSummary] {
        var comps = URLComponents(url: baseURL.appendingPathComponent("menuitems"), resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "locationId", value: locationId),
            URLQueryItem(name: "menuGroupId", value: dayGroupId),
            URLQueryItem(name: "categoryId", value: categoryId),
            URLQueryItem(name: "isPreview", value: "false")
        ]
        if profile.hasActiveFilters {
            let prefsDict: [String: Any] = [
                "allergies": Array(profile.selectedAllergenIds),
                "lifestyleChoices": Array(profile.selectedLifestyleIds),
                "medicalGoals": [],
                "preferenceApplyStatus": true,
                "crossContactStatus": profile.crossContactSensitive
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: prefsDict),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                queryItems.append(URLQueryItem(name: "userPreferences", value: jsonString))
            }
        }
        comps.queryItems = queryItems
        guard let url = comps.url else { throw BigZpoonAPIError.invalidURL }
        let req = buildRequest(url: url, companyId: companyId ?? defaultCompanyId, locationId: locationId)
        let envelope: APIEnvelope<MenuItemsPayload> = try await perform(req)
        return Self.mergeMenuItems(payload: envelope.data, hasActiveFilters: profile.hasActiveFilters)
    }

    public func fetchMenuItemDetail(
        companyId: String? = nil,
        locationId: String,
        menuItemId: String,
        profile: UserDietaryProfile
    ) async throws -> MenuItemDetailData {
        let url = baseURL.appendingPathComponent("menu-items/\(menuItemId)")
        var req = buildRequest(url: url, companyId: companyId ?? defaultCompanyId, locationId: locationId)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "_id": menuItemId,
            "preferenceApplyStatus": profile.hasActiveFilters,
            "allergyIds": Array(profile.selectedAllergenIds),
            "lifestyleChoiceIds": Array(profile.selectedLifestyleIds),
            "crossContactStatus": profile.crossContactSensitive
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let envelope: APIEnvelope<MenuItemDetailData> = try await perform(req)
        return envelope.data
    }

    public func fetchRawMaterialsAndNutrition(
        companyId: String? = nil,
        locationId: String,
        menuItemId: String,
        variationIds: [String],
        profile: UserDietaryProfile
    ) async throws -> RawMaterialsResponse {
        let url = baseURL.appendingPathComponent("raw-materials")
        var req = buildRequest(url: url, companyId: companyId ?? defaultCompanyId, locationId: locationId)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "menuId": menuItemId,
            "fdaRounding": true,
            "allergyIds": Array(profile.selectedAllergenIds),
            "lifestyleChoiceIds": Array(profile.selectedLifestyleIds),
            "nutritionGoals": [],
            "preferenceApplyStatus": profile.hasActiveFilters,
            "skipCommonIngredients": [],
            "locationId": locationId,
            "crossContactStatus": profile.crossContactSensitive,
            "variationIds": variationIds
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(req)
    }

    public static func mergeMenuItems(payload: MenuItemsPayload, hasActiveFilters: Bool) -> [MenuItemSummary] {
        if !hasActiveFilters {
            return payload.menuItems ?? []
        }
        var results: [MenuItemSummary] = []
        for var item in (payload.greenMenus ?? []) {
            item.dietaryStatus = (item.showYellowThumb == true || item.allergyLifestyleYellow == true)
                ? .modifiableMatch
                : .safeMatch
            results.append(item)
        }
        for var item in (payload.yellowMenus ?? []) {
            item.dietaryStatus = .modifiableMatch
            results.append(item)
        }
        for var item in (payload.redMenus ?? []) {
            item.dietaryStatus = .restricted
            results.append(item)
        }
        if results.isEmpty, let plain = payload.menuItems {
            return plain
        }
        return results
    }
}
