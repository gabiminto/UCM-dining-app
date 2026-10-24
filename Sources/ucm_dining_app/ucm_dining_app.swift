import SwiftUI

/// Native iOS SwiftUI App Scene for UC Merced Dining (The Pavilion & YWDC).
public struct UCMDiningAppScene: Scene {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            UCMDiningRootView()
        }
    }
}

#Preview("UC Merced Dining Native App") {
    UCMDiningRootView()
}
