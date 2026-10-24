import SwiftUI
import WidgetKit
import ucm_dining_app

struct DiningMenuEntry: TimelineEntry {
    let date: Date
    let snapshot: MenuSnapshot
    let configuration: DiningMenuWidgetConfiguration
}

struct DiningMenuProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DiningMenuEntry {
        DiningMenuEntry(
            date: .now,
            snapshot: MenuSnapshot(
                date: .now,
                locationName: "The Pavilion",
                mealName: "Lunch",
                status: "Open",
                items: [
                    MenuSnapshotItem(name: "Grilled Chicken", iconName: "flame.fill"),
                    MenuSnapshotItem(name: "Vegetable Stir Fry", iconName: "takeoutbag.and.cup.and.straw.fill"),
                    MenuSnapshotItem(name: "Pasta Primavera", iconName: "fork.knife")
                ]
            ),
            configuration: DiningMenuWidgetConfiguration()
        )
    }

    func snapshot(
        for configuration: DiningMenuWidgetConfiguration,
        in context: Context
    ) async -> DiningMenuEntry {
        await entry(for: configuration)
    }

    func timeline(
        for configuration: DiningMenuWidgetConfiguration,
        in context: Context
    ) async -> Timeline<DiningMenuEntry> {
        let entry = await entry(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)
            ?? .now.addingTimeInterval(1_800)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func entry(for configuration: DiningMenuWidgetConfiguration) async -> DiningMenuEntry {
        let snapshot = await MenuSnapshotService().snapshot(for: configuration.diningHall)
        return DiningMenuEntry(date: snapshot.date, snapshot: snapshot, configuration: configuration)
    }
}

struct DiningMenuWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DiningMenuEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemMedium ? 7 : 5) {
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(gold)
                        .frame(width: 24, height: 24)
                        .background(.white.opacity(0.12), in: Circle())
                        .widgetAccentable()

                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.snapshot.locationName)
                            .font(family == .systemMedium ? .headline : .subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(entry.snapshot.mealName.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(gold)
                    }
                }

                if entry.snapshot.items.isEmpty {
                    Text("No menu items listed")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(entry.snapshot.items.prefix(itemLimit), id: \.self) { item in
                            HStack(spacing: 8) {
                                Image(systemName: item.iconName)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(gold)
                                    .frame(width: 18, height: 18)
                                    .background(.white.opacity(0.10), in: Circle())
                                    .widgetAccentable()
                                Text(item.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Spacer(minLength: 1)

                HStack {
                    Text(entry.snapshot.status)
                    Spacer()
                    Text(entry.date, style: .time)
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.62))
        }
        .containerBackground(for: .widget) {
            Color(red: 0.00, green: 0.106, blue: 0.227)
        }
        .widgetURL(URL(string: "ucmdining://menu?location=\(entry.configuration.diningHall.rawValue)"))
    }

    private var itemLimit: Int {
        family == .systemMedium ? 3 : 1
    }

    private var gold: Color {
        Color(red: 0.957, green: 0.769, blue: 0.188)
    }
}

struct DiningMenuWidget: Widget {
    let kind = "edu.ucmerced.dining.menu"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: DiningMenuWidgetConfiguration.self,
            provider: DiningMenuProvider()
        ) { entry in
            DiningMenuWidgetView(entry: entry)
        }
        .configurationDisplayName("Dining Menu")
        .description("See the current menu at The Pavilion or YWDC.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    DiningMenuWidget()
} timeline: {
    DiningMenuEntry(
        date: .now,
        snapshot: MenuSnapshot(
            date: .now,
            locationName: "The Pavilion",
            mealName: "Lunch",
            status: "Open",
            items: [
                MenuSnapshotItem(name: "Grilled Chicken", iconName: "flame.fill"),
                MenuSnapshotItem(name: "Vegetable Stir Fry", iconName: "takeoutbag.and.cup.and.straw.fill"),
                MenuSnapshotItem(name: "Pasta Primavera", iconName: "fork.knife")
            ]
        ),
        configuration: DiningMenuWidgetConfiguration()
    )
}
