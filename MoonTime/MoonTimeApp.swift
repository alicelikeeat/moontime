import SwiftUI

@main
struct MoonTimeApp: App {
    @State private var store = DayStore()
    @State private var countdowns = CountdownStore()
    @State private var habits = HabitStore()
    @State private var alarms = AlarmStore()
    @AppStorage(GlassAppearance.backgroundKey) private var background = GlassAppearance.Background.plain
    @AppStorage(GlassAppearance.styleKey) private var glassStyle = GlassAppearance.Style.clear
    @AppStorage(GlassAppearance.frostKey) private var frost = 0.0
    @AppStorage(Palette.schemeKey) private var scheme = "colour"
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            let _ = { Palette.monochrome = scheme == "white" }()
            RootView()
                // Rebuild every screen when the colour scheme changes.
                .id(scheme)
                .tint(Palette.accent)
                .environment(store)
                .environment(countdowns)
                .environment(habits)
                .environment(alarms)
                .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                .environment(\.glassAppearance, GlassAppearance(background: background, style: glassStyle, frost: frost))
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.syncWithLiveActivity() }
                }
        }
    }
}
