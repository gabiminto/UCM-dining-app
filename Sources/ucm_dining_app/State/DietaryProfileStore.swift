import Foundation
import Observation

@Observable
@MainActor
public final class DietaryProfileStore {
    public var profile: UserDietaryProfile {
        didSet { save() }
    }
    public var availablePreferences: PreferencesData = .defaultUCMPreferences

    private let storageKey = "ucm_dining_user_dietary_profile_v1"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(UserDietaryProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserDietaryProfile()
        }
    }

    public func toggleAllergen(_ id: String) {
        if profile.selectedAllergenIds.contains(id) {
            profile.selectedAllergenIds.remove(id)
        } else {
            profile.selectedAllergenIds.insert(id)
        }
    }

    public func toggleLifestyle(_ id: String) {
        if profile.selectedLifestyleIds.contains(id) {
            profile.selectedLifestyleIds.remove(id)
        } else {
            profile.selectedLifestyleIds.insert(id)
        }
    }

    public func clearAllFilters() {
        profile.selectedAllergenIds.removeAll()
        profile.selectedLifestyleIds.removeAll()
        profile.crossContactSensitive = false
        profile.showOnlySafeItems = false
    }

    public func selectedAllergenNames() -> [String] {
        availablePreferences.allergies
            .filter { profile.selectedAllergenIds.contains($0.id) }
            .map(\.name)
    }

    public func selectedLifestyleNames() -> [String] {
        availablePreferences.lifestyleChoices
            .filter { profile.selectedLifestyleIds.contains($0.id) }
            .map(\.name)
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(profile) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
}
