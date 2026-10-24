import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum UCMTheme {
    /// UC Merced Official Navy Blue (#002856)
    public static let navy = adaptiveColor(
        light: (0.00, 0.157, 0.337),
        dark: (0.34, 0.68, 1.00)
    )
    /// UC Merced Rich Deep Navy (#001B3A)
    public static let deepNavy = Color(red: 0.00, green: 0.106, blue: 0.227)
    /// UC Merced Official Bobcat Gold (#DAA900)
    public static let gold = Color(red: 0.855, green: 0.663, blue: 0.00)
    /// Soft Warm Gold Accent (#F4C430)
    public static let brightGold = Color(red: 0.957, green: 0.769, blue: 0.188)
    /// Sierra Sky Blue (#1E88E5)
    public static let skyBlue = Color(red: 0.118, green: 0.533, blue: 0.898)

    /// Semantic Dietary Status Colors
    public static let safeGreen = adaptiveColor(light: (0.08, 0.48, 0.25), dark: (0.35, 0.85, 0.57))
    public static let swapAmber = adaptiveColor(light: (0.72, 0.39, 0.00), dark: (1.00, 0.72, 0.25))
    public static let alertRed = adaptiveColor(light: (0.76, 0.12, 0.18), dark: (1.00, 0.44, 0.48))

    /// Adaptive surfaces used by cards and screen backgrounds.
    #if canImport(UIKit)
    public static let screenBackground = Color(uiColor: .systemGroupedBackground)
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    #else
    public static let screenBackground = Color(nsColor: .windowBackgroundColor)
    public static let cardBackground = Color(nsColor: .controlBackgroundColor)
    #endif
    public static let subtleBorder = Color.primary.opacity(0.08)

    public static func stationColor(_ station: StationCategory) -> Color {
        switch station {
        case .all:
            return navy
        case .rufusGrill, .plancha:
            return Color(red: 0.85, green: 0.33, blue: 0.16)
        case .lakeWok, .flame:
            return Color(red: 0.78, green: 0.18, blue: 0.28)
        case .cascabel, .carbone:
            return Color(red: 0.84, green: 0.52, blue: 0.06)
        case .ciao, .deux:
            return Color(red: 0.16, green: 0.52, blue: 0.78)
        case .pizza:
            return Color(red: 0.82, green: 0.26, blue: 0.20)
        case .fieldOfGreens, .brot:
            return Color(red: 0.16, green: 0.64, blue: 0.38)
        case .commonGrounds:
            return Color(red: 0.45, green: 0.32, blue: 0.22)
        case .bakery, .glacies:
            return Color(red: 0.65, green: 0.34, blue: 0.75)
        case .chefSpecial:
            return gold
        }
    }

    private static func adaptiveColor(
        light: (red: Double, green: Double, blue: Double),
        dark: (red: Double, green: Double, blue: Double)
    ) -> Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traits in
            let components = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: components.red, green: components.green, blue: components.blue, alpha: 1)
        })
        #elseif canImport(AppKit)
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let components = isDark ? dark : light
            return NSColor(red: components.red, green: components.green, blue: components.blue, alpha: 1)
        })
        #else
        Color(red: light.red, green: light.green, blue: light.blue)
        #endif
    }
}

public extension View {
    @ViewBuilder
    func ucmGlassCard(interactive: Bool = false) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(
                interactive ? .regular.interactive() : .regular,
                in: .rect(cornerRadius: 16)
            )
        } else {
            background(UCMTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(UCMTheme.subtleBorder, lineWidth: 1)
                }
        }
    }

    func ucmSurfaceCard(cornerRadius: CGFloat = 18) -> some View {
        background(UCMTheme.cardBackground, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(UCMTheme.subtleBorder, lineWidth: 1)
            }
    }

    @ViewBuilder
    func ucmGlassControl(isSelected: Bool = false) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(
                isSelected
                    ? .regular.tint(UCMTheme.deepNavy).interactive()
                    : .regular.interactive(),
                in: .capsule
            )
        } else {
            background(
                isSelected ? UCMTheme.deepNavy : UCMTheme.cardBackground,
                in: Capsule()
            )
            .overlay {
                Capsule().strokeBorder(UCMTheme.subtleBorder, lineWidth: 1)
            }
        }
    }
}
