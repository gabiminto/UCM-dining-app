import Foundation

// MARK: - Station Information

public enum StationCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case all = "All Stations"
    case rufusGrill = "Rufus Grill"
    case lakeWok = "Lake Wok"
    case cascabel = "Cascabel"
    case ciao = "Ciao"
    case pizza = "Pizza"
    case fieldOfGreens = "Field of Greens"
    case commonGrounds = "Common Grounds"
    case bakery = "Bakery"
    case plancha = "Plancha"
    case carbone = "Carbone"
    case flame = "Flame"
    case brot = "Brot"
    case deux = "Deux"
    case glacies = "Glacies"
    case chefSpecial = "Chef's Table"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .rufusGrill: return "flame.fill"
        case .lakeWok: return "takeoutbag.and.cup.and.straw.fill"
        case .cascabel: return "sun.haze.fill"
        case .ciao: return "fork.knife"
        case .pizza: return "chart.pie.fill"
        case .fieldOfGreens: return "leaf.fill"
        case .commonGrounds: return "cup.and.saucer.fill"
        case .bakery: return "birthday.cake.fill"
        case .plancha: return "flame.circle.fill"
        case .carbone: return "sparkles"
        case .flame: return "flame.fill"
        case .brot: return "carrot.fill"
        case .deux: return "fish.fill"
        case .glacies: return "snowflake"
        case .chefSpecial: return "star.circle.fill"
        }
    }

    public var cuisineTagline: String {
        switch self {
        case .all: return "Every station active for this meal"
        case .rufusGrill: return "Burgers, comfort classics & grilled favorites"
        case .lakeWok: return "Pan-Asian stir fry, pho, bao & rice bowls"
        case .cascabel: return "Taqueria, fajitas, chilaquiles & Latin flavors"
        case .ciao: return "Mediterranean, pasta, flatbreads & Italian"
        case .pizza: return "Artisan oven-baked pizzas"
        case .fieldOfGreens: return "Plant-forward & allergy-conscious station"
        case .commonGrounds: return "Deli sandwiches, soups & grab-and-go"
        case .bakery: return "Freshly baked pastries, muffins & desserts"
        case .plancha: return "YWDC grill & crispy tenders"
        case .carbone: return "YWDC street tacos & Latin kitchen"
        case .flame: return "YWDC wok & Southeast Asian specialties"
        case .brot: return "YWDC roasted proteins & wholesome sides"
        case .deux: return "YWDC coastal & seasonal plates"
        case .glacies: return "YWDC ice cream & sweet toppings bar"
        case .chefSpecial: return "Pavilion & YWDC culinary recipes"
        }
    }
}

public struct StationInfo: Codable, Hashable, Sendable {
    public let category: StationCategory
    public let rawBadgeName: String

    public init(category: StationCategory, rawBadgeName: String? = nil) {
        self.category = category
        self.rawBadgeName = rawBadgeName ?? category.rawValue
    }
}

public struct ParsedMenuDescription: Equatable, Sendable {
    public let station: StationInfo
    public let cleanDescription: String
    public let proteinOptions: [String]

    public init(station: StationInfo, cleanDescription: String, proteinOptions: [String]) {
        self.station = station
        self.cleanDescription = cleanDescription
        self.proteinOptions = proteinOptions
    }
}

// MARK: - Dietary Compatibility Status

public enum DietaryMatchStatus: String, Codable, Sendable, Equatable {
    case unfiltered
    case safeMatch
    case modifiableMatch
    case restricted

    public var label: String {
        switch self {
        case .unfiltered: return ""
        case .safeMatch: return "Matches Profile"
        case .modifiableMatch: return "Smart Swap Available"
        case .restricted: return "Contains Restricted Item"
        }
    }

    public var iconName: String {
        switch self {
        case .unfiltered: return "circle"
        case .safeMatch: return "checkmark.shield.fill"
        case .modifiableMatch: return "arrow.triangle.2.circlepath.circle.fill"
        case .restricted: return "exclamationmark.triangle.fill"
        }
    }
}
