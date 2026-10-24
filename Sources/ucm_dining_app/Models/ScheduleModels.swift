import Foundation

// MARK: - Day Menu Groups & Meal Categories

public struct LocationMenuOverview: Codable, Sendable, Equatable {
    public let menuGroups: [DayMenuGroup]
    public let menuCategories: [MealCategory]
    public let menuItems: [MenuItemSummary]?

    public init(
        menuGroups: [DayMenuGroup],
        menuCategories: [MealCategory],
        menuItems: [MenuItemSummary]? = nil
    ) {
        self.menuGroups = menuGroups
        self.menuCategories = menuCategories
        self.menuItems = menuItems
    }
}

public struct DayMenuGroup: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let order: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, order
    }

    public init(id: String, name: String, order: Int? = nil) {
        self.id = id
        self.name = name
        self.order = order
    }

    public var isDayOfWeek: Bool { weekdayIndex != nil }

    public var weekdayIndex: Int? {
        switch name.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "SUNDAY": return 1
        case "MONDAY": return 2
        case "TUESDAY": return 3
        case "WEDNESDAY": return 4
        case "THURSDAY": return 5
        case "FRIDAY": return 6
        case "SATURDAY": return 7
        default: return nil
        }
    }

    public var shortDayName: String {
        switch name.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "SUNDAY": return "Sun"
        case "MONDAY": return "Mon"
        case "TUESDAY": return "Tue"
        case "WEDNESDAY": return "Wed"
        case "THURSDAY": return "Thu"
        case "FRIDAY": return "Fri"
        case "SATURDAY": return "Sat"
        default: return name.capitalized
        }
    }

    public var fullDayName: String { name.capitalized }
}

public struct MealCategory: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let order: Int?
    public let explanationText: String?
    public let menuGroupIds: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, description, order, explanationText, menuGroupIds
    }

    public init(
        id: String,
        name: String,
        description: String? = nil,
        order: Int? = nil,
        explanationText: String? = nil,
        menuGroupIds: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.order = order
        self.explanationText = explanationText
        self.menuGroupIds = menuGroupIds
    }

    public var displayName: String {
        switch name {
        case "FoG Breakfast": return "Field of Greens (AM)"
        case "FoG Lunch & Dinner": return "Field of Greens"
        case "CG Lunch & Dinner": return "Common Grounds"
        case "Salad-Yogurt-Deli Bar": return "Salad & Deli Bar"
        default: return name
        }
    }

    public var iconName: String {
        let lower = name.lowercased()
        if lower.contains("breakfast") { return "sunrise.fill" }
        if lower.contains("lunch") && !lower.contains("fog") && !lower.contains("cg") { return "sun.max.fill" }
        if lower.contains("dinner") && !lower.contains("fog") && !lower.contains("cg") { return "moon.stars.fill" }
        if lower.contains("late night") { return "sparkles" }
        if lower.contains("bakery") || lower.contains("pastries") { return "birthday.cake.fill" }
        if lower.contains("fog") || lower.contains("salad") { return "leaf.fill" }
        if lower.contains("cg") { return "cup.and.saucer.fill" }
        if lower.contains("ice cream") { return "snowflake" }
        return "fork.knife"
    }

    public var serviceHoursSummary: String? {
        guard let explanationText, !explanationText.isEmpty else { return nil }
        return explanationText.components(separatedBy: "\n\n").first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
