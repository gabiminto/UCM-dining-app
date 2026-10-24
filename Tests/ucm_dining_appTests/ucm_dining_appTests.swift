import Foundation
import Testing
@testable import ucm_dining_app

@Suite("UC Merced Dining Native App Tests")
struct UCMDiningAppTests {

    @Test("StationParser extracts UC Merced station badges and protein options")
    func testStationParser() {
        let rufus = StationParser.parse(
            description: "@RUFUS GRILL: Burger or Vegan Pretzel Bun. Choice of Protein : Oven Fried Crispy Chicken or Plant-Base Chick'N Tenders with Curly Fries.",
            itemName: "BobCat Chicken Sandwich"
        )
        #expect(rufus.station.category == .rufusGrill)
        #expect(!rufus.cleanDescription.hasPrefix("@RUFUS"))
        #expect(rufus.proteinOptions.contains("Oven Fried Crispy Chicken"))
        #expect(rufus.proteinOptions.contains("Plant-Base Chick'N Tenders"))

        let lakeWok = StationParser.parse(
            description: "@Lake Wok : Protein Choice of Honey Ginger Glazed Salmon or Honey Ginger Glazed Tofu. Sides of Brown Rice Pilaf.",
            itemName: "Healthy Concepts!"
        )
        #expect(lakeWok.station.category == .lakeWok)
        #expect(lakeWok.proteinOptions == ["Honey Ginger Glazed Salmon", "Honey Ginger Glazed Tofu"])

        let pizza = StationParser.parse(
            description: "π Pizza : Pizza Choice of Pepperoni Pizza or Four Cheese Pizza",
            itemName: "Wednesday Pizza"
        )
        #expect(pizza.station.category == .pizza)
    }

    @Test("DiningScheduleEvaluator evaluates Pacific Time hours for The Pavilion & YWDC")
    func testDiningScheduleEvaluator() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DiningScheduleEvaluator.pacificTimeZone

        // Friday at 12:30 PM Pacific -> Pavilion Open for Lunch
        let fridayNoon = calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 12, minute: 30))!
        let pavilionLunch = DiningScheduleEvaluator.evaluate(for: .thePavilion, at: fridayNoon)
        #expect(pavilionLunch.isOpen == true)
        #expect(pavilionLunch.recommendedMealName == "Lunch")
        #expect(pavilionLunch.currentWeekdayIndex == 6) // Friday

        // Friday at 9:30 PM Pacific -> YWDC Open for Late Night
        let fridayLateNight = calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 21, minute: 30))!
        let ywdcLate = DiningScheduleEvaluator.evaluate(for: .ywdc, at: fridayLateNight)
        #expect(ywdcLate.isOpen == true)
        #expect(ywdcLate.recommendedMealName == "Late Night")

        // Saturday at 12:00 PM Pacific -> YWDC Closed Weekends, Pavilion Open for Lunch
        let saturdayNoon = calendar.date(from: DateComponents(year: 2026, month: 10, day: 17, hour: 12, minute: 0))!
        let ywdcWeekend = DiningScheduleEvaluator.evaluate(for: .ywdc, at: saturdayNoon)
        #expect(ywdcWeekend.isOpen == false)
        #expect(ywdcWeekend.currentWeekdayIndex == 7) // Saturday stays selected even though the next service is Monday
    }

    @Test("NutritionFactsSummary aggregates and scales FDA nutrition metrics")
    func testNutritionSummaryAndScaling() {
        let metrics: [String: NutritionMetric] = [
            "cal": NutritionMetric(unit: "Kcal", slug: "calories", value: 640),
            "pro": NutritionMetric(unit: "g", slug: "protein", value: 32.5),
            "carb": NutritionMetric(unit: "g", slug: "total-carbohydrate", value: 48.0),
            "fat": NutritionMetric(unit: "g", slug: "total-fat", value: 22.0)
        ]
        let summary = NutritionFactsSummary.from(metricsMap: metrics, servingSize: "4 oz")
        #expect(summary.calories == 640)
        #expect(summary.proteinGrams == 32.5)
        #expect(summary.carbsGrams == 48.0)
        #expect(summary.fatGrams == 22.0)

        let doubleServing = summary.scaled(by: 1.5)
        #expect(doubleServing.calories == 960)
        #expect(doubleServing.proteinGrams == 48.8)
    }

    @Test("FavoritesStore manages saved menu items")
    @MainActor
    func testFavoritesStore() {
        let suiteName = "ucm_test_suite_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let favStore = FavoritesStore(defaults: defaults)
        let sampleItem = SampleMenuCatalog.samplePavilionItems[0]
        #expect(favStore.isFavorite(item: sampleItem) == false)
        favStore.toggleFavorite(item: sampleItem, locationName: "The Pavilion")
        #expect(favStore.isFavorite(item: sampleItem) == true)
    }

    @Test("WeeklyMacroDistribution normalizes by serving amount, classifies Poor/Fair/Great protein, and picks C/F vs P/F ratio")
    func testWeeklyMacroDistributionAndServingNormalization() {
        // Dish 1: Small 4 oz high-fat item (ratio = 16 / 18 = 0.89 < 1.7 -> Poor Carbs)
        let pastry = ItemMacroSnapshot(
            menuItemId: "pastry",
            proteinGrams: 3,
            carbsGrams: 16,
            fatGrams: 18,
            servingAmountOz: 4
        )
        // Dish 2: 4 oz wholesome grain bowl (ratio = 38 / 8 = 4.75 > 3.5 -> Great Carbs)
        let goodCarbs = ItemMacroSnapshot(
            menuItemId: "oatmeal",
            proteinGrams: 6,
            carbsGrams: 38,
            fatGrams: 8,
            servingAmountOz: 4
        )
        // Dish 3: 4 oz glazed salmon (ratio = 26 / 10 = 2.6, between 1.7 and 3.5 -> Fair Protein)
        let fairSalmon = ItemMacroSnapshot(
            menuItemId: "salmon",
            proteinGrams: 26,
            carbsGrams: 4,
            fatGrams: 10,
            servingAmountOz: 4
        )
        // Dish 4: 4 oz marinated lean beef (ratio = 34 / 7 = 4.86 > 3.5 -> Great Protein)
        let leanBeef = ItemMacroSnapshot(
            menuItemId: "beef",
            proteinGrams: 34,
            carbsGrams: 4,
            fatGrams: 7,
            servingAmountOz: 4
        )

        let distribution = WeeklyMacroDistribution.compute(from: [pastry, goodCarbs, fairSalmon, leanBeef])
        #expect(distribution.sampleCount == 4)

        let pastryEval = distribution.evaluate(snapshot: pastry)
        #expect(pastryEval.qualityTier == .poorCarbs)
        #expect(pastryEval.ratioKind == .carbToFat)

        let goodCarbsEval = distribution.evaluate(snapshot: goodCarbs)
        #expect(goodCarbsEval.qualityTier == .greatCarbs)
        #expect(goodCarbsEval.ratioKind == .carbToFat)

        let fairSalmonEval = distribution.evaluate(snapshot: fairSalmon)
        #expect(fairSalmonEval.qualityTier == .fairProtein)
        #expect(fairSalmonEval.ratioKind == .proteinToFat)

        let leanBeefEval = distribution.evaluate(snapshot: leanBeef)
        #expect(leanBeefEval.qualityTier == .greatProtein)
        #expect(leanBeefEval.ratioKind == .proteinToFat)

        // Verify isActualMeal excludes cream cheese, drinks, creamers, and bakery items
        let creamCheese = MenuItemSummary(id: "cc", name: "Cream Cheese Spread", description: "Whipped cream cheese")
        let coffeeCreamer = MenuItemSummary(id: "cr", name: "Vanilla Coffee Creamer", description: "Dairy creamer")
        let sodaDrink = MenuItemSummary(id: "dr", name: "Fountain Drink", description: "Assorted beverages")
        let sandwichMeal = SampleMenuCatalog.samplePavilionItems[0]

        #expect(WeeklyMacroExtractor.isActualMeal(item: creamCheese) == false)
        #expect(WeeklyMacroExtractor.isActualMeal(item: coffeeCreamer) == false)
        #expect(WeeklyMacroExtractor.isActualMeal(item: sodaDrink) == false)
        #expect(WeeklyMacroExtractor.isActualMeal(item: sandwichMeal) == true)

        // Verify mainProteinSnapshot extracts ONLY the "Choice of Protein :" variation and ignores buns/fries
        let detail = MenuItemDetailData(
            id: "sandwich-1",
            name: "BobCat Chicken Sandwich",
            choices: [
                MenuChoice(id: "c-bun", name: "Buns :", selectionMethod: "Optional", defaultSelectedVariationIds: ["v-bun"], redRobinOrder: 0, variations: [MenuVariation(id: "v-bun", name: "Burger Bun")]),
                MenuChoice(id: "c-pro", name: "Choice of Protein :", selectionMethod: "Mandatory", defaultSelectedVariationIds: ["v-chicken"], redRobinOrder: 1, variations: [MenuVariation(id: "v-chicken", name: "Oven Fried Crispy Chicken")]),
                MenuChoice(id: "c-side", name: "Sides :", selectionMethod: "Optional", defaultSelectedVariationIds: ["v-fries"], redRobinOrder: 2, variations: [MenuVariation(id: "v-fries", name: "Curly Fries")])
            ]
        )
        let variationDetails = [
            VariationNutritionDetail(
                varName: "Burger Bun",
                varId: "v-bun",
                servingSizeValue: ServingSizeInfo(value: 2, unit: "oz"),
                nutritionInfo: ["p": NutritionMetric(slug: "protein", value: 5), "c": NutritionMetric(slug: "total-carbohydrate", value: 28), "f": NutritionMetric(slug: "total-fat", value: 2)]
            ),
            VariationNutritionDetail(
                varName: "Oven Fried Crispy Chicken",
                varId: "v-chicken",
                servingSizeValue: ServingSizeInfo(value: 4, unit: "oz"),
                nutritionInfo: ["p": NutritionMetric(slug: "protein", value: 22), "c": NutritionMetric(slug: "total-carbohydrate", value: 8), "f": NutritionMetric(slug: "total-fat", value: 12)]
            ),
            VariationNutritionDetail(
                varName: "Curly Fries",
                varId: "v-fries",
                servingSizeValue: ServingSizeInfo(value: 4, unit: "oz"),
                nutritionInfo: ["p": NutritionMetric(slug: "protein", value: 3), "c": NutritionMetric(slug: "total-carbohydrate", value: 35), "f": NutritionMetric(slug: "total-fat", value: 16)]
            )
        ]
        let rawResponse = RawMaterialsResponse(
            code: 200,
            message: "Success",
            data: nil,
            commonNutritionInfo: ["p": NutritionMetric(slug: "protein", value: 30), "c": NutritionMetric(slug: "total-carbohydrate", value: 71), "f": NutritionMetric(slug: "total-fat", value: 30)],
            nutritionDataForVariations: variationDetails,
            menuItemAllergyLifestyleFlag: "green",
            servingSizeValue: ServingSizeInfo(value: 10, unit: "oz")
        )
        let mainProteinSnap = WeeklyMacroExtractor.mainProteinSnapshot(
            menuItemId: "sandwich-1",
            detail: detail,
            response: rawResponse
        )
        #expect(mainProteinSnap.proteinSourceName == "Oven Fried Crispy Chicken")
        #expect(mainProteinSnap.proteinGrams == 22)
        #expect(mainProteinSnap.carbsGrams == 8)
        #expect(mainProteinSnap.fatGrams == 12)
        #expect(mainProteinSnap.servingAmountOz == 4)
    }

    @Test("Live BigZpoonAPIClient decodes UC Merced Pavilion company, menu items, details, and FDA nutrition")
    func testLiveBigZpoonIntegration() async throws {
        let client = BigZpoonAPIClient.shared
        let company = try await client.fetchCompany()
        #expect(company.id == "61bd7ecd8c760e0011ac0fac")
        #expect(company.listSearchLocations.count >= 2)

        let items = try await client.fetchMenuItems(
            companyId: company.id,
            locationId: DiningLocation.thePavilion.id,
            dayGroupId: "61bd80ba5f2f930010bb6a7f", // Friday
            categoryId: "61bd80d05f2f930010bb6a81", // Lunch
            profile: UserDietaryProfile()
        )
        #expect(!items.isEmpty)

        if let firstItem = items.first {
            let detail = try await client.fetchMenuItemDetail(
                companyId: company.id,
                locationId: DiningLocation.thePavilion.id,
                menuItemId: firstItem.id,
                profile: UserDietaryProfile()
            )
            #expect(detail.id == firstItem.id)
            #expect(!detail.choices.isEmpty)
        }
    }
}
