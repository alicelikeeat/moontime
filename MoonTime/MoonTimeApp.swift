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
    @AppStorage(Palette.schemeKey) private var scheme = "minimal"
    @AppStorage(Palette.colourKey) private var colourful = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Appearance defaults changed in 1.0.2 (flat content, minimal scheme);
        // reset older saved looks once so everyone starts from the new default.
        let defaults = UserDefaults.standard
        if defaults.integer(forKey: "appearance.version") < 2 {
            for key in [Palette.schemeKey, Palette.colourKey, GlassAppearance.backgroundKey,
                        GlassAppearance.styleKey, GlassAppearance.frostKey] {
                defaults.removeObject(forKey: key)
            }
            defaults.set(2, forKey: "appearance.version")
            Palette.scheme = .minimal
            Palette.colourful = false
        }
    }

    var body: some Scene {
        WindowGroup {
            let _ = {
                Palette.scheme = Palette.Scheme(rawValue: scheme) ?? .minimal
                Palette.colourful = colourful
            }()
            RootView()
                // Rebuild every screen when the colour scheme changes.
                .id("\(scheme)-\(colourful)")
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
