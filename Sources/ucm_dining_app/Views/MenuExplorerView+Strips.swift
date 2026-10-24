import SwiftUI

extension MenuExplorerView {
    internal var daySelectorStrip: some View {
        let todayWeekday = viewModel.serviceStatus.currentWeekdayIndex
        return ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(viewModel.dayGroups) { day in
                    let isSelected = (day.id == viewModel.selectedDayGroup?.id)
                    let isToday = (day.weekdayIndex == todayWeekday)
                    Button {
                        chooseDay(day)
                    } label: {
                        VStack(spacing: 2) {
                            if isToday {
                                Text("TODAY")
                                    .font(.system(size: 8, weight: .heavy))
                                    .foregroundStyle(isSelected ? UCMTheme.brightGold : UCMTheme.navy)
                            }
                            Text(day.shortDayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .frame(minWidth: 54, minHeight: 44)
                        .padding(.horizontal, 4)
                        .background(
                            isSelected ? UCMTheme.deepNavy : Color.primary.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: isSelected)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }

    internal var mealCategoryStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(viewModel.mealCategories) { category in
                    let isSelected = (category.id == viewModel.selectedCategory?.id)
                    Button {
                        chooseCategory(category)
                    } label: {
                        Text(category.displayName)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .ucmGlassControl(isSelected: isSelected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: isSelected)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }
}
