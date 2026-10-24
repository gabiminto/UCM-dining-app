import SwiftUI
import WidgetKit
import ucm_dining_app

struct DiningMenuEntry: TimelineEntry {
    let date: Date
    let snapshots: [MenuSnapshot]
    let configuration: DiningMenuWidgetConfiguration

    var snapshot: MenuSnapshot { snapshots[0] }
}

struct DiningMenuProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DiningMenuEntry {
        DiningMenuEntry(
            date: .now,
            snapshots: [MenuSnapshot(
                date: .now,
                locationName: "The Pavilion",
                mealName: "Lunch",
                status: "Open",
                items: [
                    MenuSnapshotItem(name: "Grilled Chicken", iconName: "flame.fill"),
                    MenuSnapshotItem(name: "Vegetable Stir Fry", iconName: "takeoutbag.and.cup.and.straw.fill"),
                    MenuSnapshotItem(name: "Pasta Primavera", iconName: "fork.knife")
                ]
            )],
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
        let snapshots: [MenuSnapshot]
        if configuration.diningHall == .both {
            async let pavilion = MenuSnapshotService().snapshot(for: DiningLocation.thePavilion)
            async let ywdc = MenuSnapshotService().snapshot(for: DiningLocation.ywdc)
            snapshots = await [pavilion, ywdc]
        } else {
            snapshots = [await MenuSnapshotService().snapshot(for: configuration.diningHall)]
        }
        return DiningMenuEntry(date: snapshots[0].date, snapshots: snapshots, configuration: configuration)
    }
}

struct DiningMenuWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DiningMenuEntry

    var body: some View {
        Group {
            if entry.configuration.diningHall == .both, entry.snapshots.count == 2 {
                bothDiningHalls
            } else {
                singleDiningHall(entry.snapshot)
            }
        }
        .containerBackground(for: .widget) {
            Color(red: 0.00, green: 0.106, blue: 0.227)
        }
        .widgetURL(URL(string: "ucmdining://menu?location=\(entry.configuration.diningHall.rawValue)"))
    }

    private func singleDiningHall(_ snapshot: MenuSnapshot) -> some View {
        VStack(alignment: .leading, spacing: family == .systemMedium ? 7 : 5) {
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(gold)
                        .frame(width: 24, height: 24)
                        .background(.white.opacity(0.12), in: Circle())
                        .widgetAccentable()

                    VStack(alignment: .leading, spacing: 1) {
                        Text(snapshot.locationName)
                            .font(family == .systemMedium ? .headline : .subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(snapshot.mealName.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(gold)
                    }
                }

                if snapshot.items.isEmpty {
                    Text("No menu items listed")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(snapshot.items.prefix(itemLimit), id: \.self) { item in
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
                    Text(snapshot.status)
                    Spacer()
                    Text(entry.date, style: .time)
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    @ViewBuilder
    private var bothDiningHalls: some View {
        if family == .systemMedium {
            HStack(alignment: .top, spacing: 12) {
                hallTable(entry.snapshots[0], itemCount: 3)
                Divider().overlay(.white.opacity(0.16))
                hallTable(entry.snapshots[1], itemCount: 3)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                hallTable(entry.snapshots[0], itemCount: 1)
                Divider().overlay(.white.opacity(0.16))
                hallTable(entry.snapshots[1], itemCount: 1)
            }
        }
    }

    private func hallTable(_ snapshot: MenuSnapshot, itemCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: "fork.knife")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(gold)
                Text(snapshot.locationName.replacingOccurrences(of: " Dining", with: ""))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            Text(snapshot.mealName.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(gold)
                .lineLimit(1)

            ForEach(snapshot.items.prefix(itemCount), id: \.self) { item in
                HStack(spacing: 5) {
                    Image(systemName: item.iconName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(gold)
                        .frame(width: 12)
                    Text(item.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }

            if snapshot.items.isEmpty {
                Text("No items listed")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        snapshots: [MenuSnapshot(
            date: .now,
            locationName: "The Pavilion",
            mealName: "Lunch",
            status: "Open",
            items: [
                MenuSnapshotItem(name: "Grilled Chicken", iconName: "flame.fill"),
                MenuSnapshotItem(name: "Vegetable Stir Fry", iconName: "takeoutbag.and.cup.and.straw.fill"),
                MenuSnapshotItem(name: "Pasta Primavera", iconName: "fork.knife")
            ]
        )],
        configuration: DiningMenuWidgetConfiguration()
    )
}
