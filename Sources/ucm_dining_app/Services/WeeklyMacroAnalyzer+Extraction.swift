import Foundation

public enum WeeklyMacroExtractor {
    /// Returns `true` only for actual meals/entrees, excluding non-meal items such as
    /// cream cheese, creamers, drinks, condiments, toppings, cereals, yogurts, pastries, and standalone sides.
    public static func isActualMeal(item: MenuItemSummary, categoryName: String? = nil) -> Bool {
        if let cat = categoryName?.lowercased() {
            let excludedCategories = ["bakery", "pastries", "ice cream", "recipes", "schedule", "help"]
            if excludedCategories.contains(where: { cat.contains($0) }) {
                return false
            }
        }

        let nameLower = item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let descLower = (item.description ?? "").lowercased()

        let nonMealKeywords = [
            "cream cheese", "creamer", "butter", "margarine", "jam", "jelly", "syrup", "honey",
            "dressing", "salsa", "guacamole", "sour cream", "hummus", "dip", "spread", "condiment",
            "topping", "toppings", "schmear", "mayo", "mustard", "ketchup", "relish",
            "coffee", "tea", "milk", "juice", "water", "soda", "lemonade", "drink", "beverage",
            "smoothie", "espresso", "latte", "cocoa", "hot chocolate",
            "cereal", "yogurt", "oatmeal", "grits", "cream of wheat", "fruit", "berries",
            "bagel", "toast", "muffin", "danish", "croissant", "scone", "shortcake", "cake",
            "cookie", "brownie", "pie", "ice cream", "pastry", "crackers", "charcuterie",
            "deli items", "salad bar"
        ]

        if nonMealKeywords.contains(where: { nameLower.contains($0) }) {
            return false
        }

        // Station-prepared entrees or items with protein/entree choices are actual meals
        let isStationEntree = descLower.hasPrefix("@")
            || descLower.hasPrefix("π")
            || descLower.contains("choice of protein")
            || descLower.contains("protein choice")
            || descLower.contains("pizza choice")
            || descLower.contains("served with")
            || descLower.contains("with sides")

        if isStationEntree {
            return true
        }

        // Also treat substantial entrees (>= 250 Cal) that aren't excluded above as meals
        if let cal = item.parsedDefaultCalories, cal >= 250 {
            return true
        }

        return false
    }

    /// Builds a serving-normalized macro snapshot strictly from the dish's **main source of protein**
    /// (excluding sides, buns, fries, and add-ons) using the live BigZpoon `/raw-materials` response.
    public static func mainProteinSnapshot(
        menuItemId: String,
        detail: MenuItemDetailData?,
        response: RawMaterialsResponse,
        itemDescription: String? = nil
    ) -> ItemMacroSnapshot {
        let allVarDetails = response.nutritionDataForVariations ?? []

        if let mainProteinVar = selectMainProteinVariation(detail: detail, variationDetails: allVarDetails) {
            let varSummary = mainProteinVar.nutritionSummary
            let macroMass = varSummary.proteinGrams + varSummary.carbsGrams + varSummary.fatGrams
            let servingOz = convertToOunces(
                value: mainProteinVar.servingSizeValue?.value,
                unit: mainProteinVar.servingSizeValue?.unit,
                macroMassGrams: macroMass
            ) ?? parseOunces(from: mainProteinVar.varName) ?? 4.0

            return ItemMacroSnapshot(
                menuItemId: menuItemId,
                proteinSourceName: mainProteinVar.varName,
                proteinGrams: varSummary.proteinGrams,
                carbsGrams: varSummary.carbsGrams,
                fatGrams: varSummary.fatGrams,
                servingAmountOz: servingOz,
                calories: varSummary.calories > 0 ? varSummary.calories : nil
            )
        }

        let summary = NutritionFactsSummary.from(
            metricsMap: response.commonNutritionInfo,
            servingSize: response.servingSizeValue?.formatted
        )
        let macroMass = summary.proteinGrams + summary.carbsGrams + summary.fatGrams
        let servingOz = convertToOunces(
            value: response.servingSizeValue?.value,
            unit: response.servingSizeValue?.unit,
            macroMassGrams: macroMass
        ) ?? (itemDescription.flatMap { parseOunces(from: $0) }) ?? 4.0

        return ItemMacroSnapshot(
            menuItemId: menuItemId,
            proteinSourceName: detail?.name,
            proteinGrams: summary.proteinGrams,
            carbsGrams: summary.carbsGrams,
            fatGrams: summary.fatGrams,
            servingAmountOz: servingOz,
            calories: summary.calories > 0 ? summary.calories : nil
        )
    }

    /// Returns the variation that best represents a single serving of the dish's main protein.
    public static func mainProteinVariation(in detail: MenuItemDetailData) -> (choiceId: String, variationId: String)? {
        let choices = detail.sortedChoices
        let proteinChoice = choices.first(where: { choice in
            let title = choice.cleanTitle.lowercased()
            return title.contains("protein") || title.contains("entree") || title.contains("meat") || title.contains("pizza")
        }) ?? choices.first(where: { choice in
            let title = choice.cleanTitle.lowercased()
            return choice.isMandatory
                && !title.contains("bun")
                && !title.contains("side")
                && !title.contains("add")
                && !title.contains("bread")
                && !title.contains("tortilla")
        })

        guard let choice = proteinChoice else { return nil }
        let preferredIds = (choice.defaultSelectedVariationIds ?? []) + (choice.originalDefaultVariations ?? [])
        let variation = preferredIds.lazy.compactMap { id in
            choice.visibleVariations.first(where: { $0.id == id })
        }.first ?? choice.visibleVariations.first(where: { $0.flag == "green" }) ?? choice.visibleVariations.first

        guard let variation else { return nil }
        return (choice.id, variation.id)
    }

    /// Identifies the primary protein variation from `MenuItemDetailData` and `nutritionDataForVariations`,
    /// ignoring buns, sides, sauces, and add-ons.
    public static func selectMainProteinVariation(
        detail: MenuItemDetailData?,
        variationDetails: [VariationNutritionDetail]
    ) -> VariationNutritionDetail? {
        guard !variationDetails.isEmpty else { return nil }

        if let choices = detail?.sortedChoices {
            let proteinChoice = choices.first(where: {
                let t = $0.cleanTitle.lowercased()
                return t.contains("protein") || t.contains("entree") || t.contains("meat") || t.contains("pizza")
            }) ?? choices.first(where: {
                let t = $0.cleanTitle.lowercased()
                return $0.isMandatory && !t.contains("bun") && !t.contains("side") && !t.contains("add") && !t.contains("bread") && !t.contains("tortilla")
            })

            if let choice = proteinChoice {
                let preferredIds = (choice.defaultSelectedVariationIds ?? [])
                    + (choice.originalDefaultVariations ?? [])
                    + choice.visibleVariations.map(\.id)

                for varId in preferredIds {
                    if let matched = variationDetails.first(where: { $0.varId == varId }) {
                        return matched
                    }
                }
            }
        }

        let nonSideCandidates = variationDetails.filter { v in
            let lower = v.varName.lowercased()
            let isSide = lower.contains("bun") || lower.contains("fries") || lower.contains("rice")
                || lower.contains("beans") || lower.contains("coleslaw") || lower.contains("sauce")
                || lower.contains("tortilla") || lower.contains("roll") || lower.contains("chips")
                || lower.contains("lettuce") || lower.contains("tomato") || lower.contains("onion")
                || lower.contains("pickle") || lower.contains("carrots") || lower.contains("potatoes")
            return !isSide
        }

        let pool = nonSideCandidates.isEmpty ? variationDetails : nonSideCandidates
        return pool.max { a, b in
            let aSum = a.nutritionSummary
            let bSum = b.nutritionSummary
            let aOz = convertToOunces(value: a.servingSizeValue?.value, unit: a.servingSizeValue?.unit, macroMassGrams: aSum.proteinGrams + aSum.carbsGrams + aSum.fatGrams) ?? 4.0
            let bOz = convertToOunces(value: b.servingSizeValue?.value, unit: b.servingSizeValue?.unit, macroMassGrams: bSum.proteinGrams + bSum.carbsGrams + bSum.fatGrams) ?? 4.0
            return (aSum.proteinGrams / aOz) < (bSum.proteinGrams / bOz)
        }
    }

    public static func estimatedSnapshot(for item: MenuItemSummary) -> ItemMacroSnapshot {
        let hasExplicitProteinChoice = !item.proteinHighlights.isEmpty
        let primaryText = (item.proteinHighlights.first ?? item.name).lowercased()
        let itemTitleLower = item.name.lowercased()
        let servingOz = parseOunces(from: primaryText) ?? 4.0
        let scale = servingOz / 4.0

        let carbDishKws = ["cereal", "muffin", "danish", "croissant", "scone", "shortcake", "cake", "pastry", "bread", "pita", "pizza", "oatmeal", "granola", "fruit", "potato", "rice", "noodle", "pasta", "tortilla", "chips", "ice cream"]
        if !hasExplicitProteinChoice && carbDishKws.contains(where: { itemTitleLower.contains($0) || primaryText.contains($0) }) {
            return ItemMacroSnapshot(menuItemId: item.id, proteinSourceName: item.name, proteinGrams: 5.0 * scale, carbsGrams: 34.0 * scale, fatGrams: 7.0 * scale, servingAmountOz: servingOz)
        }

        if primaryText.contains("salmon") || primaryText.contains("fish") || primaryText.contains("cod") || primaryText.contains("shrimp") {
            if primaryText.contains("battered") || primaryText.contains("fried") {
                return ItemMacroSnapshot(menuItemId: item.id, proteinSourceName: item.proteinHighlights.first, proteinGrams: 16.0 * scale, carbsGrams: 18.0 * scale, fatGrams: 11.0 * scale, servingAmountOz: servingOz)
            }
            return ItemMacroSnapshot(menuItemId: item.id, proteinSourceName: item.proteinHighlights.first, proteinGrams: 25.0 * scale, carbsGrams: 3.0 * scale, fatGrams: 9.0 * scale, servingAmountOz: servingOz)
        } else if (primaryText.contains("chicken") || primaryText.contains("turkey")) && (primaryText.contains("orange") || primaryText.contains("tso") || primaryText.contains("teriyaki")) {
            return ItemMacroSnapshot(menuItemId: item.id, proteinSourceName: item.proteinHighlights.first, proteinGrams: 16.0 * scale, carbsGrams: 22.0 * scale, fatGrams: 10.0 * scale, servingAmountOz: servingOz)
        } else if (primaryText.contains("chicken") || primaryText.contains("turkey")) && (primaryText.contains("crispy") || primaryText.contains("fried") || primaryText.contains("tender")) {
            return ItemMacroSnapshot(menuItemId: item.id, proteinSourceName: item.proteinHighlights.first, proteinGrams: 20.0 * scale, carbsGrams: 15.0 * scale, fatGrams: 14.0 * scale, servingAmountOz: servingOz)
        } else if primaryText.contains("chicken") || primaryText.contains("steak") || primaryText.contains("beef") || primaryText.contains("barbacoa") || primaryText.contains("tinga") {
            return ItemMacroSnapshot(menuItemId: item.id, proteinSourceName: item.proteinHighlights.first, proteinGrams: 26.0 * scale, carbsGrams: 3.0 * scale, fatGrams: 10.0 * scale, servingAmountOz: servingOz)
        } else if primaryText.contains("pork") || primaryText.contains("carnitas") || primaryText.contains("ribs") || primaryText.contains("chorizo") || primaryText.contains("bacon") || primaryText.contains("tocino") {
            return ItemMacroSnapshot(menuItemId: item.id, proteinSourceName: item.proteinHighlights.first, proteinGrams: 22.0 * scale, carbsGrams: 3.0 * scale, fatGrams: 15.0 * scale, servingAmountOz: servingOz)
        } else if primaryText.contains("egg") {
            return ItemMacroSnapshot(menuItemId: item.id, proteinSourceName: item.proteinHighlights.first, proteinGrams: 14.0 * scale, carbsGrams: 1.0 * scale, fatGrams: 12.0 * scale, servingAmountOz: servingOz)
        } else if primaryText.contains("tofu") || primaryText.contains("plant") || primaryText.contains("beyond") || primaryText.contains("impossible") {
            return ItemMacroSnapshot(menuItemId: item.id, proteinSourceName: item.proteinHighlights.first, proteinGrams: 14.0 * scale, carbsGrams: 15.0 * scale, fatGrams: 11.0 * scale, servingAmountOz: servingOz)
        } else {
            return ItemMacroSnapshot(menuItemId: item.id, proteinSourceName: item.name, proteinGrams: 5.0 * scale, carbsGrams: 28.0 * scale, fatGrams: 8.0 * scale, servingAmountOz: servingOz)
        }
    }

    public static func convertToOunces(value: Double?, unit: String?, macroMassGrams: Double = 0) -> Double? {
        guard let value, value > 0 else { return nil }
        let u = (unit ?? "oz").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch u {
        case "oz", "ounce", "ounces", "fl oz", "fl(oz)": return value
        case "g", "gram", "grams": return value / 28.3495
        case "lb", "lbs", "pound", "pounds": return value * 16.0
        case "cup", "cups": return value * 8.0
        case "tbsp", "tablespoon", "tablespoons": return value * 0.5
        case "tsp", "teaspoon", "teaspoons": return value * 0.17
        case "each", "serving", "slice", "piece", "roll", "tortilla", "waffle":
            let estimatedFromMacros = (macroMassGrams * 2.2) / 28.3495
            return max(value * 3.0, estimatedFromMacros)
        default:
            return value
        }
    }

    public static func parseOunces(from text: String) -> Double? {
        let pattern = #"(\d+(?:\.\d+)?)\s*oz"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)
        guard !matches.isEmpty else { return nil }

        var total: Double = 0
        for match in matches {
            if match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text),
               let val = Double(text[range]) {
                total += val
            }
        }
        return total > 0 ? total : nil
    }

    private static func estimateServingOz(from text: String, calories: Double) -> Double {
        if text.contains("muffin") || text.contains("croissant") || text.contains("scone") || text.contains("recipe") {
            return 4.0
        }
        return max(4.0, min(14.0, (calories / 85.0)))
    }
}
