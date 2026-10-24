import Foundation

// MARK: - Macro Quality Tier & Macro Ratio Kind

public enum MacroQualityTier: String, Codable, Sendable, Equatable {
    case poorProtein = "Poor Protein"
    case fairProtein = "Fair Protein"
    case greatProtein = "Great Protein"
    case poorCarbs = "Poor Carbs"
    case fairCarbs = "Fair Carbs"
    case greatCarbs = "Great Carbs"

    public var isGreat: Bool { self == .greatProtein || self == .greatCarbs }
    public var isFair: Bool { self == .fairProtein || self == .fairCarbs }
    public var isPoor: Bool { self == .poorProtein || self == .poorCarbs }
}

public enum MacroRatioKind: String, Codable, Sendable, Equatable {
    case carbToFat = "C/F"
    case proteinToFat = "P/F"

    public var fullLabel: String {
        switch self {
        case .carbToFat: return "Carb/Fat"
        case .proteinToFat: return "Protein/Fat"
        }
    }
}

// MARK: - Main Protein Serving-Normalized Macro Snapshot

public struct ItemMacroSnapshot: Codable, Sendable, Equatable {
    public let menuItemId: String
    public let proteinSourceName: String?
    public let proteinGrams: Double
    public let carbsGrams: Double
    public let fatGrams: Double
    public let servingAmountOz: Double
    public let calories: Int?

    public init(
        menuItemId: String,
        proteinSourceName: String? = nil,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double,
        servingAmountOz: Double,
        calories: Int? = nil
    ) {
        self.menuItemId = menuItemId
        self.proteinSourceName = proteinSourceName
        self.proteinGrams = max(0, proteinGrams)
        self.carbsGrams = max(0, carbsGrams)
        self.fatGrams = max(0, fatGrams)
        self.servingAmountOz = max(0.5, servingAmountOz)
        self.calories = calories.map { max(0, $0) }
    }

    /// Protein grams normalized per 1 oz of serving
    public var normalizedProteinPerOz: Double {
        proteinGrams / servingAmountOz
    }

    /// Carbohydrate grams normalized per 1 oz of serving
    public var normalizedCarbsPerOz: Double {
        carbsGrams / servingAmountOz
    }

    /// Fat grams normalized per 1 oz of serving
    public var normalizedFatPerOz: Double {
        fatGrams / servingAmountOz
    }

    /// Carb-to-Fat ratio (normalized by serving amount)
    public var carbToFatRatio: Double {
        normalizedCarbsPerOz / max(normalizedFatPerOz, 0.25)
    }

    /// Protein-to-Fat ratio (normalized by serving amount)
    public var proteinToFatRatio: Double {
        normalizedProteinPerOz / max(normalizedFatPerOz, 0.25)
    }

    /// Calories for one serving of the selected protein. Falls back to calories derived from macros.
    public var servingCalories: Int {
        calories ?? Int((proteinGrams * 4 + carbsGrams * 4 + fatGrams * 9).rounded())
    }
}

// MARK: - Dish Evaluation Result

public struct DishMacroEvaluation: Codable, Sendable, Equatable {
    public let isActualMeal: Bool
    public let qualityTier: MacroQualityTier
    public let ratioKind: MacroRatioKind
    public let ratioValue: Double
    public let normalizedProteinPerOz: Double
    public let normalizedCarbsPerOz: Double
    public let servingAmountOz: Double
    public let proteinZScore: Double
    public let carbZScore: Double

    public init(
        isActualMeal: Bool = true,
        qualityTier: MacroQualityTier,
        ratioKind: MacroRatioKind,
        ratioValue: Double,
        normalizedProteinPerOz: Double,
        normalizedCarbsPerOz: Double,
        servingAmountOz: Double,
        proteinZScore: Double,
        carbZScore: Double
    ) {
        self.isActualMeal = isActualMeal
        self.qualityTier = qualityTier
        self.ratioKind = ratioKind
        self.ratioValue = ratioValue
        self.normalizedProteinPerOz = normalizedProteinPerOz
        self.normalizedCarbsPerOz = normalizedCarbsPerOz
        self.servingAmountOz = servingAmountOz
        self.proteinZScore = proteinZScore
        self.carbZScore = carbZScore
    }

    public var formattedRatioText: String {
        String(format: "%@ %.1f", ratioKind.rawValue, ratioValue)
    }
}

// MARK: - Weekly Macro Distribution & Normalizer

public struct WeeklyMacroDistribution: Codable, Sendable, Equatable {
    public let meanNormalizedProtein: Double
    public let stdDevNormalizedProtein: Double
    public let meanNormalizedCarbs: Double
    public let stdDevNormalizedCarbs: Double
    public let sampleCount: Int

    public init(
        meanNormalizedProtein: Double = 4.2,
        stdDevNormalizedProtein: Double = 1.6,
        meanNormalizedCarbs: Double = 3.8,
        stdDevNormalizedCarbs: Double = 2.2,
        sampleCount: Int = 0
    ) {
        self.meanNormalizedProtein = meanNormalizedProtein
        self.stdDevNormalizedProtein = max(0.2, stdDevNormalizedProtein)
        self.meanNormalizedCarbs = meanNormalizedCarbs
        self.stdDevNormalizedCarbs = max(0.2, stdDevNormalizedCarbs)
        self.sampleCount = sampleCount
    }

    public static func compute(from snapshots: [ItemMacroSnapshot]) -> WeeklyMacroDistribution {
        guard !snapshots.isEmpty else { return WeeklyMacroDistribution() }
        let count = Double(snapshots.count)

        let proteins = snapshots.map(\.normalizedProteinPerOz)
        let carbs = snapshots.map(\.normalizedCarbsPerOz)

        let meanP = proteins.reduce(0, +) / count
        let meanC = carbs.reduce(0, +) / count

        let varP = proteins.reduce(0) { $0 + ($1 - meanP) * ($1 - meanP) } / count
        let varC = carbs.reduce(0) { $0 + ($1 - meanC) * ($1 - meanC) } / count

        return WeeklyMacroDistribution(
            meanNormalizedProtein: meanP,
            stdDevNormalizedProtein: max(0.4, varP.squareRoot()),
            meanNormalizedCarbs: meanC,
            stdDevNormalizedCarbs: max(0.4, varC.squareRoot()),
            sampleCount: snapshots.count
        )
    }

    /// Evaluates a dish's serving-normalized macros:
    /// - Great: ratio >= 3.0
    /// - Fair: ratio between 1.7 and 3.0
    /// - Poor: ratio < 1.7
    public func evaluate(snapshot: ItemMacroSnapshot, isActualMeal: Bool = true) -> DishMacroEvaluation {
        let pZ = (snapshot.normalizedProteinPerOz - meanNormalizedProtein) / stdDevNormalizedProtein
        let cZ = (snapshot.normalizedCarbsPerOz - meanNormalizedCarbs) / stdDevNormalizedCarbs

        let isCarbFocused = snapshot.normalizedCarbsPerOz > snapshot.normalizedProteinPerOz

        let tier: MacroQualityTier
        let kind: MacroRatioKind
        let ratio: Double

        if isCarbFocused {
            kind = .carbToFat
            ratio = snapshot.carbToFatRatio
            if ratio >= 3.0 {
                tier = .greatCarbs
            } else if ratio >= 1.7 {
                tier = .fairCarbs
            } else {
                tier = .poorCarbs
            }
        } else {
            kind = .proteinToFat
            ratio = snapshot.proteinToFatRatio
            if ratio >= 3.0 {
                tier = .greatProtein
            } else if ratio >= 1.7 {
                tier = .fairProtein
            } else {
                tier = .poorProtein
            }
        }

        return DishMacroEvaluation(
            isActualMeal: isActualMeal,
            qualityTier: tier,
            ratioKind: kind,
            ratioValue: ratio,
            normalizedProteinPerOz: snapshot.normalizedProteinPerOz,
            normalizedCarbsPerOz: snapshot.normalizedCarbsPerOz,
            servingAmountOz: snapshot.servingAmountOz,
            proteinZScore: pZ,
            carbZScore: cZ
        )
    }
}
