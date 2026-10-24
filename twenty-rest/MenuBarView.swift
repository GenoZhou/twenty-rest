import AppKit
import SwiftUI

struct MenuBarView: View {
    @Bindable var controller: RestCycleController
    @State private var launchAtLogin: Bool = LoginItemSettings.isEnabled
    @State private var loginError: String?

    private static let workMinuteOptions = [10, 15, 20, 25, 30, 45, 60]
    private static let restSecondOptions = [15, 20, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if controller.isInRest {
                actionSection
                Divider()
            }

            HStack(spacing: 8) {
                Picker("用眼", selection: $controller.workIntervalMinutes) {
                    ForEach(Self.workMinuteOptions, id: \.self) { minutes in
                        Text("\(minutes) 分").tag(minutes)
                    }
                }
                .labelsHidden()

                Text(":")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("休息", selection: $controller.restMinimumSeconds) {
                    ForEach(Self.restSecondOptions, id: \.self) { seconds in
                        Text("\(seconds) 秒").tag(seconds)
                    }
                }
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("经典 20:20：每用眼一段，向约 6 米外远眺至少数秒。左侧为用眼间隔，右侧为最低休息。")
                Text("- 锁屏超过休息时长自动重置。")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Divider()

            Toggle("登录时打开", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        try LoginItemSettings.setEnabled(enabled)
                        loginError = nil
                    } catch {
                        loginError = error.localizedDescription
                        launchAtLogin = LoginItemSettings.isEnabled
                    }
                }

            if let loginError {
                Text(loginError)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            Button("退出 Twenty Rest") {
                controller.stopTicker()
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 300)
        .onAppear {
            launchAtLogin = LoginItemSettings.isEnabled
            snapToPresetOptions()
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        Button("打开休息面板") {
            controller.isRestPanelPresented = true
        }
        Button("休息好了") { controller.markReturn() }
            .disabled(!controller.canReturn)
    }

    private func snapToPresetOptions() {
        controller.workIntervalMinutes = Self.nearest(
            controller.workIntervalMinutes,
            in: Self.workMinuteOptions
        )
        controller.restMinimumSeconds = Self.nearest(
            controller.restMinimumSeconds,
            in: Self.restSecondOptions
        )
    }

    private static func nearest(_ value: Int, in options: [Int]) -> Int {
        options.min(by: { abs($0 - value) < abs($1 - value) }) ?? value
    }
}
