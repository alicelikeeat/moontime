import SwiftUI

@main
struct MoonTimeApp: App {
    @State private var store = DayStore()
    @State private var countdowns = CountdownStore()
    @AppStorage(GlassAppearance.backgroundKey) private var background = GlassAppearance.Background.plain
    @AppStorage(GlassAppearance.styleKey) private var glassStyle = GlassAppearance.Style.clear
    @AppStorage(GlassAppearance.frostKey) private var frost = 0.0
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(countdowns)
                .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                .environment(\.glassAppearance, GlassAppearance(background: background, style: glassStyle, frost: frost))
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.syncWithLiveActivity() }
                }
        }
    }
}
