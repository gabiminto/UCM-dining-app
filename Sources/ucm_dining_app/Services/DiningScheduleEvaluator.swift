import Foundation

public struct ServiceStatusEvaluation: Equatable, Sendable {
    public let isOpen: Bool
    public let statusHeadline: String
    public let statusDetail: String
    public let recommendedMealName: String
    public let currentWeekdayIndex: Int

    public init(
        isOpen: Bool,
        statusHeadline: String,
        statusDetail: String,
        recommendedMealName: String,
        currentWeekdayIndex: Int
    ) {
        self.isOpen = isOpen
        self.statusHeadline = statusHeadline
        self.statusDetail = statusDetail
        self.recommendedMealName = recommendedMealName
        self.currentWeekdayIndex = currentWeekdayIndex
    }
}

public struct DiningServiceWindow: Codable, Identifiable, Equatable, Sendable {
    public let meal: String
    public let startMinutes: Int
    public let endMinutes: Int
    public let icon: String

    public var id: String { "\(meal)-\(startMinutes)-\(endMinutes)" }

    public var timeRange: String {
        "\(Self.timeLabel(startMinutes)) – \(Self.timeLabel(endMinutes))"
    }

    fileprivate static func timeLabel(_ minutes: Int) -> String {
        let normalizedMinutes = minutes % 1_440
        let hour = normalizedMinutes / 60
        let minute = normalizedMinutes % 60
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        return minute == 0 ? "\(displayHour):00 \(suffix)" : String(format: "%d:%02d %@", displayHour, minute, suffix)
    }
}

private struct DiningHallHours: Codable, Sendable {
    let weekday: [DiningServiceWindow]
    let weekend: [DiningServiceWindow]
}

private struct DiningHoursConfiguration: Codable, Sendable {
    let sourceURL: String
    let pavilion: DiningHallHours
    let ywdc: DiningHallHours

    static let bundled: DiningHoursConfiguration = {
        guard let url = Bundle.module.url(forResource: "dining-hours", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let configuration = try? JSONDecoder().decode(DiningHoursConfiguration.self, from: data) else {
            return fallback
        }
        return configuration
    }()

    static let fallback = DiningHoursConfiguration(
        sourceURL: "https://dining.ucmerced.edu/dining-locations-hours/pavilion/dining-center-hours",
        pavilion: DiningHallHours(
            weekday: [
                .init(meal: "Breakfast", startMinutes: 420, endMinutes: 600, icon: "sunrise.fill"),
                .init(meal: "Lunch", startMinutes: 660, endMinutes: 900, icon: "sun.max.fill"),
                .init(meal: "Dinner", startMinutes: 960, endMinutes: 1_260, icon: "moon.stars.fill")
            ],
            weekend: [
                .init(meal: "Breakfast", startMinutes: 540, endMinutes: 630, icon: "sunrise.fill"),
                .init(meal: "Lunch", startMinutes: 660, endMinutes: 900, icon: "sun.max.fill"),
                .init(meal: "Dinner", startMinutes: 960, endMinutes: 1_260, icon: "moon.stars.fill")
            ]
        ),
        ywdc: DiningHallHours(
            weekday: [
                .init(meal: "Lunch", startMinutes: 600, endMinutes: 840, icon: "sun.max.fill"),
                .init(meal: "Dinner", startMinutes: 900, endMinutes: 1_200, icon: "moon.stars.fill"),
                .init(meal: "Late Night", startMinutes: 1_260, endMinutes: 1_440, icon: "sparkles")
            ],
            weekend: []
        )
    )
}

/// Evaluates the bundled, periodically verified UC Merced dining schedule in Pacific Time.
public enum DiningScheduleEvaluator {
    public static let pacificTimeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
    public static let officialHoursURL = URL(string: DiningHoursConfiguration.bundled.sourceURL)

    public static func evaluate(for location: DiningLocation, at date: Date = Date()) -> ServiceStatusEvaluation {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pacificTimeZone
        let weekday = calendar.component(.weekday, from: date)
        let minutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let today = serviceWindows(for: location, weekday: weekday)

        if let active = today.first(where: { minutes >= $0.startMinutes && minutes < $0.endMinutes }) {
            let next = nextWindow(for: location, afterWeekday: weekday, minutes: active.endMinutes)
            return .init(
                isOpen: true,
                statusHeadline: nextHeadline(next, currentWeekday: weekday),
                statusDetail: "\(active.meal) Open",
                recommendedMealName: active.meal,
                currentWeekdayIndex: weekday
            )
        }

        let next = nextWindow(for: location, afterWeekday: weekday, minutes: minutes)
        return .init(
            isOpen: false,
            statusHeadline: nextHeadline(next, currentWeekday: weekday),
            statusDetail: "Closed",
            recommendedMealName: next.window.meal,
            currentWeekdayIndex: today.isEmpty ? next.weekday : weekday
        )
    }

    public static func serviceWindows(for location: DiningLocation, weekday: Int) -> [DiningServiceWindow] {
        let hours = location.name.uppercased() == "YWDC"
            ? DiningHoursConfiguration.bundled.ywdc
            : DiningHoursConfiguration.bundled.pavilion
        return weekday == 1 || weekday == 7 ? hours.weekend : hours.weekday
    }

    private static func nextWindow(
        for location: DiningLocation,
        afterWeekday weekday: Int,
        minutes: Int
    ) -> (window: DiningServiceWindow, weekday: Int) {
        if let laterToday = serviceWindows(for: location, weekday: weekday).first(where: { $0.startMinutes >= minutes }) {
            return (laterToday, weekday)
        }

        for offset in 1...7 {
            let nextWeekday = ((weekday - 1 + offset) % 7) + 1
            if let first = serviceWindows(for: location, weekday: nextWeekday).first {
                return (first, nextWeekday)
            }
        }

        return (DiningServiceWindow(meal: "Meal", startMinutes: 0, endMinutes: 0, icon: "fork.knife"), weekday)
    }

    private static func nextHeadline(
        _ next: (window: DiningServiceWindow, weekday: Int),
        currentWeekday: Int
    ) -> String {
        let dayPrefix = next.weekday == currentWeekday ? "" : "\(weekdayAbbreviation(next.weekday)) "
        return "Next: \(dayPrefix)\(next.window.meal) at \(DiningServiceWindow.timeLabel(next.window.startMinutes))"
    }

    private static func weekdayAbbreviation(_ weekday: Int) -> String {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][max(1, min(7, weekday)) - 1]
    }
}
