import Foundation

public struct MenuSnapshotItem: Hashable, Sendable {
    public let name: String
    public let iconName: String
    public let imageURL: URL?

    public init(name: String, iconName: String, imageURL: URL? = nil) {
        self.name = name
        self.iconName = iconName
        self.imageURL = imageURL
    }
}

public struct MenuSnapshot: Sendable {
    public let date: Date
    public let locationName: String
    public let mealName: String
    public let status: String
    public let items: [MenuSnapshotItem]

    public var itemNames: [String] { items.map(\.name) }

    public init(date: Date, locationName: String, mealName: String, status: String, items: [MenuSnapshotItem]) {
        self.date = date
        self.locationName = locationName
        self.mealName = mealName
        self.status = status
        self.items = items
    }
}

public struct MenuSnapshotService: Sendable {
    private let client: BigZpoonAPIClient

    public init(client: BigZpoonAPIClient = .shared) {
        self.client = client
    }

    public func snapshot(
        for selection: DiningHallIntentValue,
        at date: Date = Date()
    ) async -> MenuSnapshot {
        guard selection == .both else {
            return await snapshot(for: selection.location, at: date)
        }

        async let pavilion = snapshot(for: DiningLocation.thePavilion, at: date)
        async let ywdc = snapshot(for: DiningLocation.ywdc, at: date)
        let (pavilionSnapshot, ywdcSnapshot) = await (pavilion, ywdc)
        let items = pavilionSnapshot.items.prefix(2).map {
            MenuSnapshotItem(name: "Pavilion · \($0.name)", iconName: $0.iconName, imageURL: $0.imageURL)
        } + ywdcSnapshot.items.prefix(2).map {
            MenuSnapshotItem(name: "YWDC · \($0.name)", iconName: $0.iconName, imageURL: $0.imageURL)
        }
        return MenuSnapshot(
            date: date,
            locationName: "Both Dining Halls",
            mealName: pavilionSnapshot.mealName,
            status: "Live menus",
            items: items
        )
    }

    public func snapshot(
        for location: DiningLocation,
        meal requestedMeal: String? = nil,
        at date: Date = Date()
    ) async -> MenuSnapshot {
        let status = DiningScheduleEvaluator.evaluate(for: location, at: date)

        do {
            let overview = try await client.fetchLocationMenuOverview(locationId: location.id)
            let days = overview.menuGroups.filter(\.isDayOfWeek)
            guard let day = days.first(where: { $0.weekdayIndex == status.currentWeekdayIndex }) ?? days.first else {
                throw BigZpoonAPIError.apiError("No menu day available.")
            }
            let categories = try await client.fetchMealCategories(locationId: location.id, dayGroupId: day.id)
            let mealName = requestedMeal ?? status.recommendedMealName
            guard let category = categories.first(where: {
                $0.name.localizedCaseInsensitiveContains(mealName)
            }) ?? categories.first else {
                throw BigZpoonAPIError.apiError("No meal period available.")
            }
            let items = try await client.fetchMenuItems(
                locationId: location.id,
                dayGroupId: day.id,
                categoryId: category.id,
                profile: UserDietaryProfile()
            )
            return MenuSnapshot(
                date: date,
                locationName: location.displayName,
                mealName: category.displayName,
                status: status.statusDetail,
                items: Array(items.prefix(5).map { item in
                    MenuSnapshotItem(
                        name: item.name,
                        iconName: item.station.category.iconName,
                        imageURL: item.imageUrl.flatMap(URL.init(string:))
                    )
                })
            )
        } catch {
            return MenuSnapshot(
                date: date,
                locationName: location.displayName,
                mealName: requestedMeal ?? status.recommendedMealName,
                status: status.statusDetail,
                items: Array(SampleMenuCatalog.samplePavilionItems.prefix(5).map { item in
                    MenuSnapshotItem(name: item.name, iconName: item.station.category.iconName)
                })
            )
        }
    }

    public func fullDay(for location: DiningLocation, at date: Date = Date()) async -> [MenuSnapshot] {
        let status = DiningScheduleEvaluator.evaluate(for: location, at: date)

        do {
            let overview = try await client.fetchLocationMenuOverview(locationId: location.id)
            let days = overview.menuGroups.filter(\.isDayOfWeek)
            guard let day = days.first(where: { $0.weekdayIndex == status.currentWeekdayIndex }) ?? days.first else {
                return []
            }
            let categories = try await client.fetchMealCategories(locationId: location.id, dayGroupId: day.id)
            var snapshots: [MenuSnapshot] = []

            for category in categories {
                let menuItems = try await client.fetchMenuItems(
                    locationId: location.id,
                    dayGroupId: day.id,
                    categoryId: category.id,
                    profile: UserDietaryProfile()
                )
                snapshots.append(
                    MenuSnapshot(
                        date: date,
                        locationName: location.displayName,
                        mealName: category.displayName,
                        status: status.statusDetail,
                        items: Array(menuItems.prefix(4).map { item in
                            MenuSnapshotItem(
                                name: item.name,
                                iconName: item.station.category.iconName,
                                imageURL: item.imageUrl.flatMap(URL.init(string:))
                            )
                        })
                    )
                )
            }
            return snapshots
        } catch {
            return []
        }
    }
}
