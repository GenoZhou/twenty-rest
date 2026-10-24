import SwiftUI

struct RestPanelView: View {
    @Bindable var controller: RestCycleController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("远眺休息")
                .font(.title2.weight(.semibold))

            Text(instructionText)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(controller.statusTitle)
                .font(.system(.largeTitle, design: .rounded).monospacedDigit())
                .frame(maxWidth: .infinity)

            HStack {
                Button("跳过") {
                    controller.skip()
                }
                Button("稍后（\(controller.snoozeMinutes) 分钟）") {
                    controller.snooze()
                }
                Spacer()
                Button("回来了") {
                    controller.markReturn()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!controller.canReturn)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onDisappear {
            // Closing the panel must not Return; only clear presentation state.
            controller.isRestPanelPresented = false
        }
    }

    private var instructionText: String {
        if controller.canReturn {
            return "最低休息时间已到。若还想多歇一会儿，关上面板即可；回到屏幕前再点「回来了」。"
        }
        return "请向约 6 米外看一会儿。倒计时是最低休息时长；结束后点「回来了」再开始下一段。"
    }
}
