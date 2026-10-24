import SwiftUI

public struct DiningHoursSheetView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                ScrollView {
                    VStack(spacing: 16) {
                        hallCard(
                            location: .thePavilion,
                            address: "5203 Lake Rd",
                            weekdayGroups: ["Monday – Friday", "Saturday – Sunday"],
                            date: context.date
                        )

                        hallCard(
                            location: .ywdc,
                            address: "5212 Lake Rd",
                            weekdayGroups: ["Monday – Friday", "Saturday – Sunday"],
                            date: context.date
                        )

                        sourceNote
                    }
                    .padding(16)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Dining Hours")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func hallCard(
        location: DiningLocation,
        address: String,
        weekdayGroups: [String],
        date: Date
    ) -> some View {
        let status = DiningScheduleEvaluator.evaluate(for: location, at: date)
        let currentWeekday = weekday(for: date)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: location == .thePavilion ? "fork.knife.circle.fill" : "takeoutbag.and.cup.and.straw.fill")
                    .font(.title2)
                    .foregroundStyle(UCMTheme.skyBlue)
                    .frame(width: 42, height: 42)
                    .background(UCMTheme.skyBlue.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(location.displayName)
                        .font(.headline)
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusBadge(status)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(status.statusDetail)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(status.isOpen ? UCMTheme.safeGreen : .primary)
                Text(status.statusHeadline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ForEach(Array(weekdayGroups.enumerated()), id: \.offset) { index, label in
                let representativeWeekday = index == 0 ? 2 : 7
                scheduleGroup(
                    label: label,
                    windows: DiningScheduleEvaluator.serviceWindows(for: location, weekday: representativeWeekday),
                    isToday: index == 0 ? (2...6).contains(currentWeekday) : (currentWeekday == 1 || currentWeekday == 7),
                    activeMeal: status.isOpen ? status.recommendedMealName : nil
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private func scheduleGroup(
        label: String,
        windows: [DiningServiceWindow],
        isToday: Bool,
        activeMeal: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                if isToday {
                    Text("TODAY")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(UCMTheme.navy)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(UCMTheme.skyBlue.opacity(0.22), in: Capsule())
                }
            }

            if windows.isEmpty {
                Label("Closed", systemImage: "moon.zzz.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(windows) { window in
                    let isActive = isToday && activeMeal == window.meal
                    HStack(spacing: 12) {
                        Image(systemName: window.icon)
                            .foregroundStyle(isActive ? UCMTheme.safeGreen : UCMTheme.skyBlue)
                            .frame(width: 22)
                        Text(window.meal)
                            .font(.subheadline.weight(isActive ? .bold : .medium))
                        Spacer()
                        Text(window.timeRange)
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(isActive ? UCMTheme.safeGreen : .secondary)
                    }
                    .padding(12)
                    .background(
                        isActive ? UCMTheme.safeGreen.opacity(0.12) : Color.secondary.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
            }
        }
    }

    private func statusBadge(_ status: ServiceStatusEvaluation) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(status.isOpen ? UCMTheme.safeGreen : Color.secondary)
                .frame(width: 7, height: 7)
            Text(status.isOpen ? "OPEN" : "CLOSED")
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(status.isOpen ? UCMTheme.safeGreen : .secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background((status.isOpen ? UCMTheme.safeGreen : Color.secondary).opacity(0.12), in: Capsule())
    }

    private var sourceNote: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Hours may change for holidays and academic breaks.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let officialHoursURL = DiningScheduleEvaluator.officialHoursURL {
                Link("Check official UC Merced dining hours", destination: officialHoursURL)
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 4)
    }

    private func weekday(for date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = DiningScheduleEvaluator.pacificTimeZone
        return calendar.component(.weekday, from: date)
    }
}
