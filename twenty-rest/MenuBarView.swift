import AppKit
import SwiftUI

struct MenuBarView: View {
    @Bindable var controller: RestCycleController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(phaseLabel)
                .font(.headline)

            Text(controller.statusTitle)
                .font(.title.monospacedDigit())

            Divider()

            if controller.isInRest {
                Button("打开休息面板") {
                    controller.isRestPanelPresented = true
                }
                Button("跳过休息") { controller.skip() }
                Button("稍后提醒") { controller.snooze() }
                Button("回来了") { controller.markReturn() }
                    .disabled(!controller.canReturn)
            } else if controller.isPaused {
                Button("继续计时") { controller.resume() }
            } else {
                Button("暂停计时") { controller.pause() }
            }

            Divider()

            SettingsLink {
                Text("设置…")
            }

            Button("退出 Twenty Rest") {
                controller.stopTicker()
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 220)
    }

    private var phaseLabel: String {
        switch controller.phase {
        case .workInterval:
            return "用眼计时"
        case .restMinimum:
            return "休息中"
        case .restAwaitingReturn:
            return "可以回来了"
        case .paused:
            return "已暂停"
        }
    }
}
