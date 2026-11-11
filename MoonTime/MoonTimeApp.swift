import SwiftUI

@main
struct MoonTimeApp: App {
    @State private var store = DayStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.syncWithLiveActivity() }
                }
        }
    }
}
