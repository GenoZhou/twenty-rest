import SwiftUI

struct SettingsView: View {
    @Bindable var controller: RestCycleController
    @State private var launchAtLogin: Bool = LoginItemSettings.isEnabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("节奏") {
                Stepper(value: $controller.workIntervalMinutes, in: 1...120) {
                    Text("用眼间隔：\(controller.workIntervalMinutes) 分钟")
                }
                Stepper(value: $controller.restMinimumSeconds, in: 5...300, step: 5) {
                    Text("最低休息：\(controller.restMinimumSeconds) 秒")
                }
                Stepper(value: $controller.snoozeMinutes, in: 1...30) {
                    Text("稍后提醒：\(controller.snoozeMinutes) 分钟")
                }
            }

            Section("启动") {
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
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .padding()
        .onAppear {
            launchAtLogin = LoginItemSettings.isEnabled
        }
    }
}
