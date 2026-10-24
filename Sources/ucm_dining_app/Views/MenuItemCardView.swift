import SwiftUI

public struct MenuItemCardView: View {
    public let item: MenuItemSummary
    public let macroEvaluation: DishMacroEvaluation
    public let caloriesBadge: String?
    public let showMacroRatio: Bool
    public let isFavorite: Bool
    public let onToggleFavorite: () -> Void
    public let onSelect: () -> Void

    public init(
        item: MenuItemSummary,
        macroEvaluation: DishMacroEvaluation,
        caloriesBadge: String? = nil,
        showMacroRatio: Bool = true,
        isFavorite: Bool,
        onToggleFavorite: @escaping () -> Void,
        onSelect: @escaping () -> Void
    ) {
        self.item = item
        self.macroEvaluation = macroEvaluation
        self.caloriesBadge = caloriesBadge
        self.showMacroRatio = showMacroRatio
        self.isFavorite = isFavorite
        self.onToggleFavorite = onToggleFavorite
        self.onSelect = onSelect
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 12) {
                    dishArtwork

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(item.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.trailing, 28)

                            if let calBadge = caloriesBadge ?? item.displayCaloriesBadge {
                                Text(calBadge)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.trailing, 28)
                            }
                        }

                        Text(item.cleanDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if macroEvaluation.isActualMeal || item.dietaryStatus != .unfiltered {
                            HStack(spacing: 8) {
                                if macroEvaluation.isActualMeal {
                                    proteinTierTag

                                    if showMacroRatio {
                                        macroRatioTag
                                    }
                                }

                                if item.dietaryStatus != .unfiltered {
                                    dietaryStatusPill
                                }

                                Spacer()
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                .padding(14)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isFavorite ? Color.red : Color.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
        }
        .ucmGlassCard(interactive: true)
    }

    @ViewBuilder
    private var dishArtwork: some View {
        if let imageURL = item.imageUrl.flatMap(URL.init(string:)) {
            AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                case .empty:
                    artworkFallback
                        .overlay { ProgressView().controlSize(.small) }
                case .failure:
                    artworkFallback
                @unknown default:
                    artworkFallback
                }
            }
            .frame(width: 88, height: 88)
            .clipped()
            .clipShape(.rect(cornerRadius: 12))
            .accessibilityHidden(true)
        } else {
            artworkFallback
                .frame(width: 88, height: 88)
                .accessibilityHidden(true)
        }
    }

    private var artworkFallback: some View {
        ZStack {
            UCMTheme.stationColor(item.station.category).opacity(0.16)
            Image(systemName: item.station.category.iconName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(UCMTheme.stationColor(item.station.category))
        }
        .clipShape(.rect(cornerRadius: 12))
    }

    private var proteinTierTag: some View {
        let color: Color = {
            if macroEvaluation.qualityTier.isGreat {
                return UCMTheme.safeGreen
            } else if macroEvaluation.qualityTier.isFair {
                return UCMTheme.swapAmber
            } else {
                return UCMTheme.alertRed
            }
        }()
        return Text(macroEvaluation.qualityTier.rawValue)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var macroRatioTag: some View {
        let isCarb = (macroEvaluation.ratioKind == .carbToFat)
        let tint: Color = isCarb ? UCMTheme.skyBlue : UCMTheme.navy
        return Text(macroEvaluation.formattedRatioText)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.10), in: Capsule())
    }

    private var dietaryStatusPill: some View {
        let color: Color = {
            switch item.dietaryStatus {
            case .safeMatch: return UCMTheme.safeGreen
            case .modifiableMatch: return UCMTheme.swapAmber
            case .restricted: return UCMTheme.alertRed
            case .unfiltered: return .secondary
            }
        }()
        return HStack(spacing: 4) {
            Image(systemName: item.dietaryStatus.iconName)
                .font(.caption2)
            Text(item.dietaryStatus.label)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(color)
    }
}
