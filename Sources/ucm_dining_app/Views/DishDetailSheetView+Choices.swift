import SwiftUI

extension DishDetailSheetView {
    internal var macroQuickPillsSection: some View {
        let macros = detailVM.scaledNutrition
        return HStack(spacing: 10) {
            macroPill(title: "Calories", value: "\(macros.calories)", unit: "kcal", color: UCMTheme.navy)
            macroPill(title: "Protein", value: "\(Int(macros.proteinGrams.rounded()))", unit: "g", color: UCMTheme.safeGreen)
            macroPill(title: "Carbs", value: "\(Int(macros.carbsGrams.rounded()))", unit: "g", color: UCMTheme.swapAmber)
            macroPill(title: "Fat", value: "\(Int(macros.fatGrams.rounded()))", unit: "g", color: UCMTheme.skyBlue)
        }
    }

    private func macroPill(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.black))
                .foregroundStyle(color)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    internal var choicesCustomizationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let detail = detailVM.detailData, !detail.sortedChoices.isEmpty {
                ForEach(detail.sortedChoices) { choice in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(choice.cleanTitle)
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            Text(choice.isMandatory ? "Required" : "Optional")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(choice.isMandatory ? UCMTheme.navy : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.primary.opacity(0.06), in: Capsule())
                        }

                        ForEach(choice.visibleVariations) { variation in
                            let isSelected = detailVM.selectedVariationIdsByChoice[choice.id]?.contains(variation.id) ?? false
                            Button {
                                Task { await detailVM.toggleVariation(choice: choice, variation: variation) }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isSelected ? UCMTheme.navy : .secondary)
                                        .font(.body.weight(.semibold))
                                    Text(variation.cleanName)
                                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if let flag = variation.flag {
                                        Circle()
                                            .fill(flagColor(flag))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    isSelected ? UCMTheme.navy.opacity(0.09) : Color.primary.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func flagColor(_ flag: String) -> Color {
        switch flag.lowercased() {
        case "green": return UCMTheme.safeGreen
        case "yellow": return UCMTheme.swapAmber
        case "red": return UCMTheme.alertRed
        default: return .secondary
        }
    }
}
