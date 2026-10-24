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
                        Task { await viewModel.selectDay(day) }
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
                        .background(isSelected ? UCMTheme.deepNavy : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                        Task { await viewModel.selectCategory(category) }
                    } label: {
                        Text(category.displayName)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .background(
                                isSelected ? UCMTheme.deepNavy : Color.primary.opacity(0.06),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }
}
