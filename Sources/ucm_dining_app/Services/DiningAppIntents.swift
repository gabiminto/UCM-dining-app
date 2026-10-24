import AppIntents
import Foundation

public enum DiningHallIntentValue: String, AppEnum, Sendable {
    case pavilion = "pavilion"
    case ywdc = "ywdc"
    case both = "both"

    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Dining Hall"
    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .pavilion: "The Pavilion",
        .ywdc: "YWDC Dining",
        .both: "Both Dining Halls"
    ]

    public var location: DiningLocation {
        switch self {
        case .pavilion: .thePavilion
        case .ywdc: .ywdc
        case .both: .thePavilion
        }
    }

    public var locations: [DiningLocation] {
        switch self {
        case .pavilion: [.thePavilion]
        case .ywdc: [.ywdc]
        case .both: [.thePavilion, .ywdc]
        }
    }
}

public struct DiningMenuWidgetConfiguration: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "Dining Menu"
    public static let description = IntentDescription("Choose which UC Merced dining hall to show.")

    @Parameter(title: "Dining Hall", default: .pavilion)
    public var diningHall: DiningHallIntentValue

    public init() {}
}

public struct CheckDiningMenuIntent: AppIntent {
    public static let title: LocalizedStringResource = "Check Dining Menu"
    public static let description = IntentDescription("Hear what is being served at a UC Merced dining hall.")

    @Parameter(title: "Dining Hall", default: .pavilion)
    public var diningHall: DiningHallIntentValue

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshot = await MenuSnapshotService().snapshot(for: diningHall)
        let dishes = snapshot.itemNames.prefix(3).joined(separator: ", ")
        let message = dishes.isEmpty
            ? "No dishes are listed for \(snapshot.mealName) at \(snapshot.locationName)."
            : "\(snapshot.locationName) is serving \(snapshot.mealName). Highlights include \(dishes)."
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

public struct CheckDinnerMenusIntent: AppIntent {
    public static let title: LocalizedStringResource = "Check Tonight's Dinner Menus"
    public static let description = IntentDescription("Hear dinner highlights from both UC Merced dining halls.")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        async let pavilion = MenuSnapshotService().snapshot(for: .thePavilion, meal: "Dinner")
        async let ywdc = MenuSnapshotService().snapshot(for: .ywdc, meal: "Dinner")
        let (pavilionMenu, ywdcMenu) = await (pavilion, ywdc)

        let pavilionDishes = pavilionMenu.itemNames.prefix(3).joined(separator: ", ")
        let ywdcDishes = ywdcMenu.itemNames.prefix(3).joined(separator: ", ")
        let message = "For dinner, The Pavilion has \(pavilionDishes). YWDC has \(ywdcDishes)."
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

public struct CheckFullDayMenusIntent: AppIntent {
    public static let title: LocalizedStringResource = "Check Today's Menus"
    public static let description = IntentDescription("Hear today's meal highlights from both UC Merced dining halls.")

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        async let pavilion = MenuSnapshotService().fullDay(for: .thePavilion)
        async let ywdc = MenuSnapshotService().fullDay(for: .ywdc)
        let (pavilionMenus, ywdcMenus) = await (pavilion, ywdc)

        let pavilionSummary = spokenSummary(for: pavilionMenus)
        let ywdcSummary = spokenSummary(for: ywdcMenus)
        let message = "The Pavilion: \(pavilionSummary). YWDC: \(ywdcSummary)."
        return .result(dialog: IntentDialog(stringLiteral: message))
    }

    private func spokenSummary(for menus: [MenuSnapshot]) -> String {
        guard !menus.isEmpty else { return "No menu is currently listed" }
        return menus.map { menu in
            let highlights = menu.itemNames.prefix(2).joined(separator: " and ")
            return highlights.isEmpty
                ? "\(menu.mealName) has no listed dishes"
                : "for \(menu.mealName), \(highlights)"
        }
        .joined(separator: "; ")
    }
}

public struct UCMDiningShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckDiningMenuIntent(),
            phrases: [
                "Check the menu with \(.applicationName)",
                "What is for food at \(\.$diningHall) with \(.applicationName)"
            ],
            shortTitle: "Check Menu",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: CheckDinnerMenusIntent(),
            phrases: [
                "What's for dinner with \(.applicationName)",
                "What's on the menu tonight with \(.applicationName)",
                "Show me dinner at the dining halls with \(.applicationName)"
            ],
            shortTitle: "Dinner Menus",
            systemImageName: "moon.stars.fill"
        )
        AppShortcut(
            intent: CheckFullDayMenusIntent(),
            phrases: [
                "What's on the menu today with \(.applicationName)",
                "What's on the menu with \(.applicationName)",
                "Read today's dining menus with \(.applicationName)"
            ],
            shortTitle: "Today's Menus",
            systemImageName: "calendar"
        )
    }
}
