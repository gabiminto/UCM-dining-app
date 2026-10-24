import Foundation

// MARK: - Menu Item Detail & Variations

public struct MenuItemDetailData: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    public let imageUrl: String?
    public let choices: [MenuChoice]
    public let intelligentSelectionMarked: Bool?
    public let allergyRestrictions: [RestrictionEntry]?
    public let lifestyleRestrictions: [RestrictionEntry]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, description, imageUrl, choices, intelligentSelectionMarked
        case allergyRestrictions, lifestyleRestrictions
    }

    public init(
        id: String,
        name: String,
        description: String? = nil,
        imageUrl: String? = nil,
        choices: [MenuChoice] = [],
        intelligentSelectionMarked: Bool? = nil,
        allergyRestrictions: [RestrictionEntry]? = nil,
        lifestyleRestrictions: [RestrictionEntry]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.choices = choices
        self.intelligentSelectionMarked = intelligentSelectionMarked
        self.allergyRestrictions = allergyRestrictions
        self.lifestyleRestrictions = lifestyleRestrictions
    }

    public var sortedChoices: [MenuChoice] {
        choices.sorted { ($0.redRobinOrder ?? 99) < ($1.redRobinOrder ?? 99) }
    }
}

public struct MenuChoice: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let selectionMethod: String?
    public let selectionType: String?
    public let defaultSelectedVariationIds: [String]?
    public let originalDefaultVariations: [String]?
    public let redRobinOrder: Int?
    public let variations: [MenuVariation]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, selectionMethod, selectionType
        case defaultSelectedVariationIds, originalDefaultVariations, redRobinOrder, variations
    }

    public init(
        id: String,
        name: String,
        selectionMethod: String? = nil,
        selectionType: String? = nil,
        defaultSelectedVariationIds: [String]? = nil,
        originalDefaultVariations: [String]? = nil,
        redRobinOrder: Int? = nil,
        variations: [MenuVariation] = []
    ) {
        self.id = id
        self.name = name
        self.selectionMethod = selectionMethod
        self.selectionType = selectionType
        self.defaultSelectedVariationIds = defaultSelectedVariationIds
        self.originalDefaultVariations = originalDefaultVariations
        self.redRobinOrder = redRobinOrder
        self.variations = variations
    }

    public var cleanTitle: String {
        name.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isMandatory: Bool {
        selectionMethod?.lowercased() == "mandatory"
    }

    public var visibleVariations: [MenuVariation] {
        variations
            .filter { ($0.visibility ?? "Visible").lowercased() == "visible" }
            .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
    }
}

public struct MenuVariation: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let menuItemChoiceId: String?
    public let description: String?
    public let order: Int?
    public let visibility: String?
    public let clickAble: Bool?
    public let flag: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, menuItemChoiceId, description, order, visibility, clickAble, flag
    }

    public init(
        id: String,
        name: String,
        menuItemChoiceId: String? = nil,
        description: String? = nil,
        order: Int? = nil,
        visibility: String? = "Visible",
        clickAble: Bool? = true,
        flag: String? = "green"
    ) {
        self.id = id
        self.name = name
        self.menuItemChoiceId = menuItemChoiceId
        self.description = description
        self.order = order
        self.visibility = visibility
        self.clickAble = clickAble
        self.flag = flag
    }

    public var cleanName: String {
        name.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var hasCrossContactAsterisk: Bool {
        name.contains("*")
    }
}

public struct RestrictionEntry: Codable, Hashable, Sendable {
    public let id: String
    public let status: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case status
    }

    public init(id: String, status: String) {
        self.id = id
        self.status = status
    }
}
