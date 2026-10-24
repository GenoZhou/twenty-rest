import SwiftUI

@main
struct TwentyRestApp: App {
    @State private var controller = RestCycleController()

    init() {
        Self.registerLoginItemOnFirstLaunchIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(controller: controller)
        } label: {
            // Label(title, systemImage:) often renders icon-only in the menu bar.
            HStack(spacing: 4) {
                Image(systemName: "eye")
                Text(controller.statusTitle)
                    .monospacedDigit()
            }
            .background(RestPanelPresenter(controller: controller))
        }
        .menuBarExtraStyle(.window)

        Window("远眺休息", id: "rest-panel") {
            RestPanelView(controller: controller)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }

    private static func registerLoginItemOnFirstLaunchIfNeeded() {
        let key = "didConfigureLoginItem"
        guard UserDefaults.standard.object(forKey: key) == nil else { return }
        try? LoginItemSettings.setEnabled(true)
        UserDefaults.standard.set(true, forKey: key)
    }
}
