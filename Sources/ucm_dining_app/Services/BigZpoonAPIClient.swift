import Foundation

public enum BigZpoonAPIError: LocalizedError, Sendable {
    case invalidURL
    case httpError(Int)
    case apiError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid UC Merced Dining API URL."
        case .httpError(let code): return "Server responded with HTTP \(code)."
        case .apiError(let message): return message
        }
    }
}

/// Native async/await client for the UC Merced BigZpoon Dining API (`https://widget.api.eagle.bigzpoon.com`).
public struct BigZpoonAPIClient: Sendable {
    public static let shared = BigZpoonAPIClient()

    public let baseURL = URL(string: "https://widget.api.eagle.bigzpoon.com")!
    public let defaultCompanySlug = "uc-merced-the-pavilion"
    public let defaultCompanyId = "61bd7ecd8c760e0011ac0fac"
    public let deviceId: String
    internal let session: URLSession

    public init(session: URLSession = .shared, deviceId: String = "ucm-ios-native-client") {
        self.session = session
        self.deviceId = deviceId
    }

    public func fetchCompany() async throws -> CompanyData {
        let url = baseURL.appendingPathComponent("company")
        var req = URLRequest(url: url)
        req.setValue(defaultCompanySlug, forHTTPHeaderField: "x-comp-id")
        req.setValue(deviceId, forHTTPHeaderField: "device-id")
        let envelope: APIEnvelope<CompanyData> = try await perform(req)
        return envelope.data
    }

    public func fetchPreferences(companyId: String? = nil, locationId: String) async throws -> PreferencesData {
        let url = baseURL.appendingPathComponent("preferences")
        var req = buildRequest(url: url, companyId: companyId ?? defaultCompanyId, locationId: locationId)
        req.httpMethod = "GET"
        let envelope: APIEnvelope<PreferencesData> = try await perform(req)
        return envelope.data
    }

    public func fetchLocationMenuOverview(companyId: String? = nil, locationId: String) async throws -> LocationMenuOverview {
        var comps = URLComponents(url: baseURL.appendingPathComponent("locations/menugroups"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "locationId", value: locationId)]
        guard let url = comps.url else { throw BigZpoonAPIError.invalidURL }
        let req = buildRequest(url: url, companyId: companyId ?? defaultCompanyId, locationId: locationId)
        let envelope: APIEnvelope<LocationMenuOverview> = try await perform(req)
        return envelope.data
    }

    public func fetchMealCategories(
        companyId: String? = nil,
        locationId: String,
        dayGroupId: String
    ) async throws -> [MealCategory] {
        var comps = URLComponents(url: baseURL.appendingPathComponent("menucategories"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "locationId", value: locationId),
            URLQueryItem(name: "menuGroupIds", value: dayGroupId)
        ]
        guard let url = comps.url else { throw BigZpoonAPIError.invalidURL }
        let req = buildRequest(url: url, companyId: companyId ?? defaultCompanyId, locationId: locationId)
        let envelope: APIEnvelope<[MealCategory]> = try await perform(req)
        return envelope.data.sorted { ($0.order ?? 99) < ($1.order ?? 99) }
    }

    internal func buildRequest(url: URL, companyId: String, locationId: String) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue(companyId, forHTTPHeaderField: "x-comp-id")
        req.setValue(deviceId, forHTTPHeaderField: "device-id")
        req.setValue(locationId, forHTTPHeaderField: "location-id")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        return req
    }

    internal func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw BigZpoonAPIError.httpError(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
