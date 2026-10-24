import AppKit
import SwiftUI

/// Lives on the MenuBarExtra label so Rest presentation works even when the menu window is closed.
struct RestPanelPresenter: View {
    @Bindable var controller: RestCycleController
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onChange(of: controller.isRestPanelPresented) { _, presented in
                if presented {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "rest-panel")
                } else {
                    dismissWindow(id: "rest-panel")
                }
            }
    }
}
