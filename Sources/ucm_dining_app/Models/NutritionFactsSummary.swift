import Foundation

// MARK: - Structured Nutrition Facts Summary

public struct NutritionFactsSummary: Codable, Hashable, Sendable {
    public var calories: Int
    public var proteinGrams: Double
    public var carbsGrams: Double
    public var fatGrams: Double
    public var saturatedFatGrams: Double
    public var transFatGrams: Double
    public var cholesterolMg: Double
    public var sodiumMg: Double
    public var fiberGrams: Double
    public var sugarGrams: Double
    public var addedSugarGrams: Double
    public var servingSize: String?

    public init(
        calories: Int = 0,
        proteinGrams: Double = 0,
        carbsGrams: Double = 0,
        fatGrams: Double = 0,
        saturatedFatGrams: Double = 0,
        transFatGrams: Double = 0,
        cholesterolMg: Double = 0,
        sodiumMg: Double = 0,
        fiberGrams: Double = 0,
        sugarGrams: Double = 0,
        addedSugarGrams: Double = 0,
        servingSize: String? = nil
    ) {
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.saturatedFatGrams = saturatedFatGrams
        self.transFatGrams = transFatGrams
        self.cholesterolMg = cholesterolMg
        self.sodiumMg = sodiumMg
        self.fiberGrams = fiberGrams
        self.sugarGrams = sugarGrams
        self.addedSugarGrams = addedSugarGrams
        self.servingSize = servingSize
    }

    public static func from(
        metricsMap: [String: NutritionMetric]?,
        servingSize: String? = nil
    ) -> NutritionFactsSummary {
        guard let metricsMap else { return NutritionFactsSummary(servingSize: servingSize) }
        var summary = NutritionFactsSummary(servingSize: servingSize)
        for metric in metricsMap.values {
            let val = metric.value ?? metric.originalValue ?? 0
            let slug = (metric.slug ?? metric.nutritionName ?? metric.name ?? "").lowercased()
            switch slug {
            case "calories", "cal": summary.calories = Int(val.rounded())
            case "protein": summary.proteinGrams = val
            case "total-carbohydrate", "total carbohydrate", "tot carb": summary.carbsGrams = val
            case "total-fat", "total fat": summary.fatGrams = val
            case "saturated-fat", "saturated fat", "sat fat": summary.saturatedFatGrams = val
            case "trans-fat", "trans fat": summary.transFatGrams = val
            case "cholesterol", "cholest": summary.cholesterolMg = val
            case "sodium": summary.sodiumMg = val
            case "dietary-fiber", "dietary fiber", "fiber": summary.fiberGrams = val
            case "sugar": summary.sugarGrams = val
            case "added-sugar", "added sugar": summary.addedSugarGrams = val
            default: break
            }
        }
        return summary
    }

    public func scaled(by multiplier: Double) -> NutritionFactsSummary {
        NutritionFactsSummary(
            calories: Int((Double(calories) * multiplier).rounded()),
            proteinGrams: (proteinGrams * multiplier * 10).rounded() / 10,
            carbsGrams: (carbsGrams * multiplier * 10).rounded() / 10,
            fatGrams: (fatGrams * multiplier * 10).rounded() / 10,
            saturatedFatGrams: (saturatedFatGrams * multiplier * 10).rounded() / 10,
            transFatGrams: (transFatGrams * multiplier * 10).rounded() / 10,
            cholesterolMg: (cholesterolMg * multiplier).rounded(),
            sodiumMg: (sodiumMg * multiplier).rounded(),
            fiberGrams: (fiberGrams * multiplier * 10).rounded() / 10,
            sugarGrams: (sugarGrams * multiplier * 10).rounded() / 10,
            addedSugarGrams: (addedSugarGrams * multiplier * 10).rounded() / 10,
            servingSize: servingSize
        )
    }
}
