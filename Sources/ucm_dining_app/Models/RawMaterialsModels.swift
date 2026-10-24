import Foundation

// MARK: - Raw Materials & Nutrition Facts Response

public struct RawMaterialsResponse: Decodable, Sendable {
    public let code: Int
    public let message: String?
    public let data: [RawMaterialNote]?
    public let commonNutritionInfo: [String: NutritionMetric]?
    public let nutritionDataForVariations: [VariationNutritionDetail]?
    public let menuItemAllergyLifestyleFlag: String?
    public let servingSizeValue: ServingSizeInfo?
}

public struct RawMaterialNote: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let lifestyleAllergyFlag: String?
    public let ingredientAllergy: [String]?
    public let ingredientLifestyle: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, lifestyleAllergyFlag
        case ingredientAllergy = "ingredinetAllergy"
        case ingredientLifestyle
    }
}

public struct ServingSizeInfo: Codable, Sendable, Equatable {
    public let value: Double?
    public let unit: String?

    public init(value: Double? = nil, unit: String? = nil) {
        self.value = value
        self.unit = unit
    }

    public var formatted: String? {
        guard let value, value > 0 else { return nil }
        let cleanVal = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
        return "\(cleanVal) \(unit ?? "oz")"
    }
}

public struct NutritionMetric: Codable, Sendable, Equatable {
    public let unit: String?
    public let slug: String?
    public let name: String?
    public let nutritionName: String?
    public let originalValue: Double?
    public let percentageDV: String?
    public let value: Double?

    public init(
        unit: String? = nil,
        slug: String? = nil,
        name: String? = nil,
        nutritionName: String? = nil,
        originalValue: Double? = nil,
        percentageDV: String? = nil,
        value: Double? = nil
    ) {
        self.unit = unit
        self.slug = slug
        self.name = name
        self.nutritionName = nutritionName
        self.originalValue = originalValue
        self.percentageDV = percentageDV
        self.value = value
    }

    enum CodingKeys: String, CodingKey {
        case unit, slug, name, nutritionName, originalValue, percentageDV, value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        nutritionName = try container.decodeIfPresent(String.self, forKey: .nutritionName)
        originalValue = try container.decodeIfPresent(Double.self, forKey: .originalValue)
        percentageDV = try container.decodeIfPresent(String.self, forKey: .percentageDV)
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .value) {
            value = doubleVal
        } else if let strVal = try? container.decodeIfPresent(String.self, forKey: .value),
                  let parsed = Double(strVal) {
            value = parsed
        } else {
            value = nil
        }
    }
}

public struct VariationNutritionDetail: Codable, Identifiable, Sendable, Equatable {
    public var id: String { varId }
    public let varName: String
    public let varId: String
    public let servingSizeValue: ServingSizeInfo?
    public let rawMaterials: [String]?
    public let nutritionInfo: [String: NutritionMetric]?
    public let ingredientAllergy: [String]?
    public let ingredientLifestyle: [String]?

    enum CodingKeys: String, CodingKey {
        case varName, varId, servingSizeValue, rawMaterials, nutritionInfo
        case ingredientAllergy = "ingredinetAllergy"
        case ingredientLifestyle
    }

    public init(
        varName: String,
        varId: String,
        servingSizeValue: ServingSizeInfo? = nil,
        rawMaterials: [String]? = nil,
        nutritionInfo: [String: NutritionMetric]? = nil,
        ingredientAllergy: [String]? = nil,
        ingredientLifestyle: [String]? = nil
    ) {
        self.varName = varName
        self.varId = varId
        self.servingSizeValue = servingSizeValue
        self.rawMaterials = rawMaterials
        self.nutritionInfo = nutritionInfo
        self.ingredientAllergy = ingredientAllergy
        self.ingredientLifestyle = ingredientLifestyle
    }

    public var nutritionSummary: NutritionFactsSummary {
        NutritionFactsSummary.from(metricsMap: nutritionInfo, servingSize: servingSizeValue?.formatted)
    }
}
