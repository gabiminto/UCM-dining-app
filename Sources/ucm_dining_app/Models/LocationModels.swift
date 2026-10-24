import Foundation

// MARK: - Generic API Envelope

public struct APIEnvelope<T: Decodable & Sendable>: Decodable, Sendable {
    public let code: Int
    public let message: String?
    public let data: T
    public let nutritionServiceStatus: Bool?
}

// MARK: - Company & Locations

public struct CompanyData: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let websiteUrl: String?
    public let imageUrl: String?
    public let widgetSlug: String?
    public let listSearchLocations: [DiningLocation]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, websiteUrl, imageUrl, widgetSlug, listSearchLocations
    }

    public init(
        id: String,
        name: String,
        websiteUrl: String? = nil,
        imageUrl: String? = nil,
        widgetSlug: String? = nil,
        listSearchLocations: [DiningLocation] = []
    ) {
        self.id = id
        self.name = name
        self.websiteUrl = websiteUrl
        self.imageUrl = imageUrl
        self.widgetSlug = widgetSlug
        self.listSearchLocations = listSearchLocations
    }
}

public struct DiningLocation: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let state: String?
    public let zipCode: String?
    public let address: String?
    public let locationNo: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, state, zipCode, address, locationNo
    }

    public init(
        id: String,
        name: String,
        state: String? = "CA",
        zipCode: String? = "95340",
        address: String? = nil,
        locationNo: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.state = state
        self.zipCode = zipCode
        self.address = address
        self.locationNo = locationNo
    }

    public var displayName: String {
        switch name.uppercased() {
        case "THE PAVILION": return "The Pavilion"
        case "YWDC": return "YWDC Dining"
        default: return name.capitalized
        }
    }

    public var fullSubtitle: String {
        switch name.uppercased() {
        case "THE PAVILION": return "Main All-You-Care-To-Eat Dining Center"
        case "YWDC": return "Yablokoff-Wallace Dining Center"
        default: return address ?? "UC Merced Campus"
        }
    }

    public var iconName: String {
        switch name.uppercased() {
        case "THE PAVILION": return "fork.knife.circle.fill"
        case "YWDC": return "takeoutbag.and.cup.and.straw.fill"
        default: return "building.2.fill"
        }
    }

    public static let thePavilion = DiningLocation(
        id: "61df4a34d5507a00103ee41e",
        name: "THE PAVILION",
        address: "5203 Lake Rd, Merced, CA 95340, USA",
        locationNo: 12443
    )

    public static let ywdc = DiningLocation(
        id: "628672b52903a50010fa751e",
        name: "YWDC",
        address: "5212 Lake Rd, Merced, CA 95340, USA",
        locationNo: 12462
    )

    public static let defaultLocations: [DiningLocation] = [.thePavilion, .ywdc]
}
