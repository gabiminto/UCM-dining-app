import SwiftUI

public struct MenuHeroHeaderView: View {
    public let locations: [DiningLocation]
    public let selectedLocation: DiningLocation
    public let serviceStatus: ServiceStatusEvaluation
    public let onSelectLocation: (DiningLocation) -> Void
    public let onOpenHours: () -> Void

    public init(
        locations: [DiningLocation],
        selectedLocation: DiningLocation,
        serviceStatus: ServiceStatusEvaluation,
        onSelectLocation: @escaping (DiningLocation) -> Void,
        onOpenHours: @escaping () -> Void
    ) {
        self.locations = locations
        self.selectedLocation = selectedLocation
        self.serviceStatus = serviceStatus
        self.onSelectLocation = onSelectLocation
        self.onOpenHours = onOpenHours
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedLocation.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(serviceStatus.isOpen ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text(serviceStatus.statusHeadline)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button(action: onOpenHours) {
                    Label("Hours", systemImage: "clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dining Hours")
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(locations) { loc in
                        let isSelected = (loc.id == selectedLocation.id)
                        Button {
                            onSelectLocation(loc)
                        } label: {
                            Text(loc.displayName)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .frame(minHeight: 44)
                                .foregroundStyle(isSelected ? UCMTheme.deepNavy : .white)
                                .background(
                                    isSelected ? UCMTheme.brightGold : Color.white.opacity(0.12),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(UCMTheme.deepNavy.ignoresSafeArea(edges: .top))
    }
}
