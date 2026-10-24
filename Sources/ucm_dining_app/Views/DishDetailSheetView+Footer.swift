import SwiftUI

extension DishDetailSheetView {
    internal var ingredientsBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Selected Component Ingredients & Allergens")
                .font(.headline)

            ForEach(detailVM.variationDetails) { varDetail in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(varDetail.varName)
                            .font(.subheadline.weight(.bold))
                        Spacer()
                        Text("\(varDetail.nutritionSummary.calories) Cal")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    if let allergens = varDetail.ingredientAllergy, !allergens.isEmpty {
                        Text("Contains: \(allergens.joined(separator: ", "))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(UCMTheme.alertRed)
                    }
                    if let raw = varDetail.rawMaterials, !raw.isEmpty {
                        Text(raw.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .ucmGlassCard()
            }
        }
    }
}
