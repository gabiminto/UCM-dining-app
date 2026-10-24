import SwiftUI

public struct FDANutritionLabelView: View {
    public let nutrition: NutritionFactsSummary
    public let isRecalculating: Bool

    public init(nutrition: NutritionFactsSummary, isRecalculating: Bool = false) {
        self.nutrition = nutrition
        self.isRecalculating = isRecalculating
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Nutrition Facts")
                    .font(.title3.weight(.black))
                Spacer()
                if isRecalculating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let serving = nutrition.servingSize {
                    Text("Serving: \(serving)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Rectangle()
                .fill(Color.primary)
                .frame(height: 6)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Amount Per Selection")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("Calories")
                        .font(.title3.weight(.black))
                }
                Spacer()
                Text("\(nutrition.calories)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
            }

            Rectangle()
                .fill(Color.primary)
                .frame(height: 3)

            nutrientRow(title: "Total Fat", value: "\(formatDouble(nutrition.fatGrams))g", bold: true)
            nutrientRow(title: "  Saturated Fat", value: "\(formatDouble(nutrition.saturatedFatGrams))g", bold: false)
            nutrientRow(title: "  Trans Fat", value: "\(formatDouble(nutrition.transFatGrams))g", bold: false)
            nutrientRow(title: "Cholesterol", value: "\(Int(nutrition.cholesterolMg))mg", bold: true)
            nutrientRow(title: "Sodium", value: "\(Int(nutrition.sodiumMg))mg", bold: true)
            nutrientRow(title: "Total Carbohydrate", value: "\(formatDouble(nutrition.carbsGrams))g", bold: true)
            nutrientRow(title: "  Dietary Fiber", value: "\(formatDouble(nutrition.fiberGrams))g", bold: false)
            nutrientRow(title: "  Total Sugars", value: "\(formatDouble(nutrition.sugarGrams))g", bold: false)
            nutrientRow(title: "Protein", value: "\(formatDouble(nutrition.proteinGrams))g", bold: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1.5)
        )
    }

    private func nutrientRow(title: String, value: String, bold: Bool) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text(title)
                    .font(bold ? .subheadline.weight(.bold) : .subheadline)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
            Divider()
        }
    }

    private func formatDouble(_ val: Double) -> String {
        val.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(val)) : String(format: "%.1f", val)
    }
}
