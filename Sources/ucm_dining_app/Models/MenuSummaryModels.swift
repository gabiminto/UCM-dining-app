import Foundation

// MARK: - Menu Items & Dietary Buckets

public struct MenuItemsPayload: Codable, Sendable, Equatable {
    public let enableOrdering: Bool?
    public let menuItems: [MenuItemSummary]?
    public let greenMenus: [MenuItemSummary]?
    public let yellowMenus: [MenuItemSummary]?
    public let redMenus: [MenuItemSummary]?

    public init(
        enableOrdering: Bool? = false,
        menuItems: [MenuItemSummary]? = nil,
        greenMenus: [MenuItemSummary]? = nil,
        yellowMenus: [MenuItemSummary]? = nil,
        redMenus: [MenuItemSummary]? = nil
    ) {
        self.enableOrdering = enableOrdering
        self.menuItems = menuItems
        self.greenMenus = greenMenus
        self.yellowMenus = yellowMenus
        self.redMenus = redMenus
    }
}

public struct MenuItemSummary: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let imageUrl: String?
    public let order: Int?
    public let menuNo: Int?
    public let minmaxCaloriesRange: String?
    public let caloriesInfo: String?
    public let allergyLifestyleYellow: Bool?
    public let showYellowThumb: Bool?
    public var dietaryStatus: DietaryMatchStatus = .unfiltered

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, description, imageUrl, order
        case menuNo = "menu_no"
        case minmaxCaloriesRange, caloriesInfo, allergyLifestyleYellow, showYellowThumb
    }

    public init(
        id: String,
        name: String,
        description: String? = nil,
        imageUrl: String? = nil,
        order: Int? = nil,
        menuNo: Int? = nil,
        minmaxCaloriesRange: String? = nil,
        caloriesInfo: String? = nil,
        allergyLifestyleYellow: Bool? = nil,
        showYellowThumb: Bool? = nil,
        dietaryStatus: DietaryMatchStatus = .unfiltered
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.order = order
        self.menuNo = menuNo
        self.minmaxCaloriesRange = minmaxCaloriesRange
        self.caloriesInfo = caloriesInfo
        self.allergyLifestyleYellow = allergyLifestyleYellow
        self.showYellowThumb = showYellowThumb
        self.dietaryStatus = dietaryStatus
    }

    public var parsedDetails: ParsedMenuDescription {
        StationParser.parse(description: description ?? "", itemName: name)
    }

    public var station: StationInfo { parsedDetails.station }
    public var cleanDescription: String { parsedDetails.cleanDescription }
    public var proteinHighlights: [String] { parsedDetails.proteinOptions }

    public var parsedDefaultCalories: Int? {
        guard let caloriesInfo else { return nil }
        let digits = caloriesInfo.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digits)
    }

    public var displayCaloriesBadge: String? {
        if let cal = parsedDefaultCalories {
            return "\(cal) Cal"
        }
        if let range = minmaxCaloriesRange, !range.isEmpty {
            return "\(range) Cal"
        }
        return nil
    }
}
