import Foundation

// MARK: - Preferences (Allergens, Lifestyles, Nutrition Goals)

public struct PreferencesData: Codable, Sendable, Equatable {
    public let allergies: [AllergenOption]
    public let lifestyleChoices: [LifestyleOption]
    public let medicalGoals: [MedicalGoalOption]?

    public init(
        allergies: [AllergenOption] = [],
        lifestyleChoices: [LifestyleOption] = [],
        medicalGoals: [MedicalGoalOption]? = nil
    ) {
        self.allergies = allergies
        self.lifestyleChoices = lifestyleChoices
        self.medicalGoals = medicalGoals
    }

    public static let defaultUCMPreferences = PreferencesData(
        allergies: [
            AllergenOption(id: "5e74c4f49888990010db39d2", name: "Milk", description: "Cow's milk & dairy proteins.", order: 0),
            AllergenOption(id: "5e74c4fc9888990010db39d3", name: "Eggs", description: "Chicken & poultry egg proteins.", order: 1),
            AllergenOption(id: "5e74c51c9888990010db39d7", name: "Gluten", description: "Wheat, rye & barley proteins.", order: 2),
            AllergenOption(id: "5e74c5099888990010db39d5", name: "Wheat", description: "Foods containing wheat.", order: 3),
            AllergenOption(id: "5e74c5389888990010db39da", name: "Soy", description: "Soybeans & soy protein.", order: 4),
            AllergenOption(id: "5e74c5249888990010db39d8", name: "Peanuts", description: "Peanuts & peanut derivatives.", order: 6),
            AllergenOption(id: "5e74c52e9888990010db39d9", name: "Tree nuts", description: "Almonds, cashews, walnuts, pecans.", order: 8),
            AllergenOption(id: "5e74c5039888990010db39d4", name: "Fish", description: "Salmon, tuna, cod & finfish.", order: 9),
            AllergenOption(id: "5e74c5139888990010db39d6", name: "Shellfish", description: "Shrimp, crab & lobster.", order: 10),
            AllergenOption(id: "5efa354af8f2160011599634", name: "Sesame", description: "Sesame seeds, tahini & oil.", order: 11),
        ],
        lifestyleChoices: [
            LifestyleOption(id: "5e74c40b9888990010db39cd", name: "Vegetarian", description: "No meat, poultry, or fish.", order: 0),
            LifestyleOption(id: "5e74c4119888990010db39ce", name: "Vegan", description: "No animal, egg, or dairy products.", order: 1),
            LifestyleOption(id: "6378eef964490e001140c121", name: "Plant Based", description: "Plant-forward ingredients.", order: 2),
            LifestyleOption(id: "5e74c41e9888990010db39d0", name: "Halal", description: "Halal dietary preparation.", order: 3),
            LifestyleOption(id: "5e74c4179888990010db39cf", name: "Pescatarian", description: "Vegetarian plus seafood.", order: 4),
            LifestyleOption(id: "60f6b23565383c001066f699", name: "Keto", description: "Low-carb, high-fat diet.", order: 8, isNutritionDependent: true),
            LifestyleOption(id: "60f6b6aa65383c001066f767", name: "Atkins 20", description: "Low net-carbohydrate diet.", order: 9, isNutritionDependent: true),
        ]
    )
}

public struct AllergenOption: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let imageUrl: String?
    public let order: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, description, imageUrl, order
    }

    public init(id: String, name: String, description: String? = nil, imageUrl: String? = nil, order: Int? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.order = order
    }

    public var iconName: String {
        switch name.lowercased() {
        case "milk": return "drop.fill"
        case "eggs": return "oval.fill"
        case "gluten": return "leaf.circle.fill"
        case "wheat": return "leaf.fill"
        case "soy": return "circle.grid.2x1.fill"
        case "peanuts": return "allergens"
        case "tree nuts": return "tree.fill"
        case "fish": return "fish.fill"
        case "shellfish": return "tortoise.fill"
        case "sesame": return "sparkles"
        default: return "exclamationmark.shield.fill"
        }
    }
}

public struct LifestyleOption: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let imageUrl: String?
    public let order: Int?
    public let isNutritionDependent: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, description, imageUrl, order, isNutritionDependent
    }

    public init(
        id: String,
        name: String,
        description: String? = nil,
        imageUrl: String? = nil,
        order: Int? = nil,
        isNutritionDependent: Bool? = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.order = order
        self.isNutritionDependent = isNutritionDependent
    }

    public var iconName: String {
        switch name.lowercased() {
        case "vegetarian": return "leaf.fill"
        case "vegan": return "camera.macro"
        case "plant based": return "leaf.circle.fill"
        case "halal": return "checkmark.seal.fill"
        case "pescatarian": return "fish.circle.fill"
        case "keto": return "flame.fill"
        case "atkins 20": return "bolt.heart.fill"
        default: return "heart.circle.fill"
        }
    }
}

public struct MedicalGoalOption: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let abbreviation: String?
    public let unit: String?
    public let maxValOrderForMedGoal: Double?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, abbreviation, unit, maxValOrderForMedGoal
    }
}
