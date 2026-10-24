import Foundation
import Observation

@Observable
@MainActor
public final class DishDetailViewModel {
    public let itemSummary: MenuItemSummary
    public let location: DiningLocation
    public let companyId: String
    public let dietaryProfile: UserDietaryProfile

    public var detailData: MenuItemDetailData?
    public var selectedVariationIdsByChoice: [String: Set<String>] = [:]
    public var rawMaterialsResponse: RawMaterialsResponse?
    public var nutritionSummary: NutritionFactsSummary = NutritionFactsSummary()
    public var variationDetails: [VariationNutritionDetail] = []
    public var cautionNotes: [String] = []

    public var isLoadingDetail: Bool = false
    public var isRecalculatingNutrition: Bool = false
    public var smartSwapApplied: Bool = false
    public var servingsMultiplier: Double = 1.0

    private let apiClient: BigZpoonAPIClient

    public init(
        itemSummary: MenuItemSummary,
        location: DiningLocation,
        companyId: String,
        dietaryProfile: UserDietaryProfile,
        apiClient: BigZpoonAPIClient = .shared
    ) {
        self.itemSummary = itemSummary
        self.location = location
        self.companyId = companyId
        self.dietaryProfile = dietaryProfile
        self.apiClient = apiClient
        if let defaultCal = itemSummary.parsedDefaultCalories {
            self.nutritionSummary = NutritionFactsSummary(calories: defaultCal)
        }
    }

    public var allSelectedVariationIds: [String] {
        guard let detailData else { return [] }
        return detailData.sortedChoices.flatMap { choice in
            let set = selectedVariationIdsByChoice[choice.id] ?? []
            return choice.visibleVariations.filter { set.contains($0.id) }.map(\.id)
        }
    }

    public var selectedVariationNames: [String] {
        guard let detailData else { return [] }
        return detailData.sortedChoices.flatMap { choice in
            let set = selectedVariationIdsByChoice[choice.id] ?? []
            return choice.visibleVariations.filter { set.contains($0.id) }.map(\.cleanName)
        }
    }

    public var scaledNutrition: NutritionFactsSummary {
        nutritionSummary.scaled(by: servingsMultiplier)
    }

    public func loadDetailAndNutrition() async {
        isLoadingDetail = true
        if let detail = try? await apiClient.fetchMenuItemDetail(
            companyId: companyId,
            locationId: location.id,
            menuItemId: itemSummary.id,
            profile: dietaryProfile
        ) {
            self.detailData = detail
            self.smartSwapApplied = detail.intelligentSelectionMarked ?? false
            var initial = Dictionary(uniqueKeysWithValues: detail.sortedChoices.map { ($0.id, Set<String>()) })
            if let protein = WeeklyMacroExtractor.mainProteinVariation(in: detail) {
                initial[protein.choiceId] = [protein.variationId]
            }
            self.selectedVariationIdsByChoice = initial
            isLoadingDetail = false
            await recalculateNutrition()
        } else {
            isLoadingDetail = false
        }
    }

    public func toggleVariation(choice: MenuChoice, variation: MenuVariation) async {
        var current = selectedVariationIdsByChoice[choice.id] ?? []
        let single = choice.cleanTitle.localizedCaseInsensitiveContains("protein")
            || choice.cleanTitle.localizedCaseInsensitiveContains("bun")
            || choice.selectionType?.lowercased() == "only one"

        if single {
            current = (current.contains(variation.id) && !choice.isMandatory) ? [] : [variation.id]
        } else if current.contains(variation.id) {
            if !(choice.isMandatory && current.count == 1) { current.remove(variation.id) }
        } else {
            current.insert(variation.id)
        }
        selectedVariationIdsByChoice[choice.id] = current
        await recalculateNutrition()
    }

    public func applyPlantBasedSmartSwap() async {
        guard let detailData else { return }
        let kws = ["plant", "vegan", "tofu", "mushroom", "jackfruit", "beyond", "impossible", "chickpea"]
        for choice in detailData.sortedChoices {
            if let match = choice.visibleVariations.first(where: { v in
                kws.contains(where: { v.name.localizedCaseInsensitiveContains($0) })
            }) {
                selectedVariationIdsByChoice[choice.id] = [match.id]
            }
        }
        smartSwapApplied = true
        await recalculateNutrition()
    }

    public func recalculateNutrition() async {
        let varIds = allSelectedVariationIds
        guard !varIds.isEmpty else { return }
        isRecalculatingNutrition = true
        if let response = try? await apiClient.fetchRawMaterialsAndNutrition(
            companyId: companyId,
            locationId: location.id,
            menuItemId: itemSummary.id,
            variationIds: varIds,
            profile: dietaryProfile
        ) {
            self.rawMaterialsResponse = response
            self.nutritionSummary = NutritionFactsSummary.from(
                metricsMap: response.commonNutritionInfo,
                servingSize: response.servingSizeValue?.formatted
            )
            self.variationDetails = (response.nutritionDataForVariations ?? []).filter { varIds.contains($0.varId) }
            self.cautionNotes = (response.data ?? []).map(\.name)
        }
        isRecalculatingNutrition = false
    }
}
