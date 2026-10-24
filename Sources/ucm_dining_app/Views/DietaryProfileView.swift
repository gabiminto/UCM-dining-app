import SwiftUI

public struct DietaryProfileView: View {
    @Bindable public var dietaryStore: DietaryProfileStore
    public let onPreferencesChanged: () -> Void

    public init(
        dietaryStore: DietaryProfileStore,
        onPreferencesChanged: @escaping () -> Void
    ) {
        self.dietaryStore = dietaryStore
        self.onPreferencesChanged = onPreferencesChanged
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Display Carb/Fat & Protein/Fat Ratios", isOn: $dietaryStore.profile.showMacroRatiosOnCards)

                    Toggle("Hide Restricted Dishes Automatically", isOn: $dietaryStore.profile.showOnlySafeItems)
                        .onChange(of: dietaryStore.profile.showOnlySafeItems) { _, _ in onPreferencesChanged() }

                    Toggle("Include Cross-Contact Caution", isOn: $dietaryStore.profile.crossContactSensitive)
                        .onChange(of: dietaryStore.profile.crossContactSensitive) { _, _ in onPreferencesChanged() }
                } header: {
                    Text("Menu Display & Filtering")
                } footer: {
                    Text("Shows C/F or P/F macro ratios on meal cards and highlights dishes that match your dietary profile.")
                }

                Section("Lifestyle & Dietary Preferences") {
                    ForEach(dietaryStore.availablePreferences.lifestyleChoices) { lifestyle in
                        let selected = dietaryStore.profile.selectedLifestyleIds.contains(lifestyle.id)
                        Button {
                            dietaryStore.toggleLifestyle(lifestyle.id)
                            onPreferencesChanged()
                        } label: {
                            HStack {
                                Label(lifestyle.name, systemImage: lifestyle.iconName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(UCMTheme.safeGreen)
                                }
                            }
                        }
                    }
                }

                Section("Allergens to Avoid (Big 9 + Sesame)") {
                    ForEach(dietaryStore.availablePreferences.allergies) { allergen in
                        let selected = dietaryStore.profile.selectedAllergenIds.contains(allergen.id)
                        Button {
                            dietaryStore.toggleAllergen(allergen.id)
                            onPreferencesChanged()
                        } label: {
                            HStack {
                                Label(allergen.name, systemImage: allergen.iconName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected {
                                    Image(systemName: "exclamationmark.shield.fill")
                                        .foregroundStyle(UCMTheme.alertRed)
                                }
                            }
                        }
                    }
                }

            }
            .navigationTitle("Dietary & Goals")
            .toolbar {
                if dietaryStore.profile.hasActiveFilters {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Reset Filters") {
                            dietaryStore.clearAllFilters()
                            onPreferencesChanged()
                        }
                    }
                }
            }
        }
    }
}
