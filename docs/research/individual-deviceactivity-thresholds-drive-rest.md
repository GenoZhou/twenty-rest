# Research: individual 授权下 DeviceActivity 阈值能否驱动 Rest

**Ticket:** [#2](https://github.com/GenoZhou/twenty-rest/issues/2)  
**Branch:** `research/individual-deviceactivity-thresholds-drive-rest` (throwaway; not for merge)  
**Date:** 2026-10-24  
**Sources:** Apple Developer Documentation + iOS SDK `DeviceActivity` / `FamilyControls` swiftinterface only.

## Verdict

**Conditional.**

在 `FamilyControlsMember.individual` 授权下，应用**可以用** `DeviceActivitySchedule` + `DeviceActivityEvent.threshold`，在本机「前台应用 / 类别 / 网页」累计使用达到配置的 Work Interval 长度时，经 `DeviceActivityMonitor.eventDidReachThreshold` **粗粒度触发进入 Rest**。

但 API **没有**原生 Rest Cycle / Return / Reset；也不保证秒级准时、低电量下的投递 SLA。要与 ADR 0007 对齐，阈值只能作为 **本机粗信号驱动「进入 Rest」**；Return、lock≥Rest minimum→Reset、以及每次 Return/Reset 后重新武装下一轮 Work Interval，必须由应用状态机完成。  
**不足以**单独作为完整 Rest Cycle 的权威驱动；**足以**在授权有效且监控已正确重武装时，作为进入 Rest 的主粗信号（产品意图中的 local coarse signal）。

---

## 1. individual 授权实际保证什么

| 事实 | 来源 |
|------|------|
| 可对 `child` 或 `individual` 请求授权：`AuthorizationCenter.requestAuthorization(for:)` | [requestAuthorization(for:)](https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:)) |
| `individual`：设备所有者本人批准；系统用 Face ID / Touch ID 认证 | [Family Controls](https://developer.apple.com/documentation/familycontrols)；同上 `requestAuthorization(for:)` |
| `individual` 需要设备已设通行码；否则 `FamilyControlsError.authenticationMethodUnavailable` | [FamilyControlsError](https://developer.apple.com/documentation/familycontrols/familycontrolserror) |
| `individual` 授权后，系统**解除**阻止绕过家长管控的限制：用户可删除已授权应用、可登出 iCloud（与 child 路径不同） | [requestAuthorization(for:)](https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:)) |
| 授权状态可 externally 变化（含 Settings）；应用应观察 `authorizationStatus`；`revokeAuthorization` 可撤销 | [AuthorizationCenter](https://developer.apple.com/documentation/familycontrols/authorizationcenter)；[authorizationStatus](https://developer.apple.com/documentation/familycontrols/authorizationcenter/authorizationstatus) |
| 授权被撤后，`FamilyActivitySelection` 在授权期间提供的 tokens **作废** | [FamilyActivitySelection](https://developer.apple.com/documentation/familycontrols/familyactivityselection) |
| 未授权时 `startMonitoring` 可抛 `MonitoringError.unauthorized` | [MonitoringError.unauthorized](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/monitoringerror/unauthorized) |
| 需 Family Controls capability / entitlement；上架前需申请分发许可 | [Family Controls](https://developer.apple.com/documentation/familycontrols) |

**对 Rest 驱动的含义：** individual 路径**合法**开启 DeviceActivity 监控，无需家长管控儿童；但授权更易被用户自行撤销/删应用，监控不能假定长期不可撤。

---

## 2. 阈值与日程：API 保证什么

### 2.1 度量语义（与「屏幕使用」对齐）

| 事实 | 来源 |
|------|------|
| Device activity = 应用、类别或 web domain **在屏幕上处于 frontmost** 的累计时间；按时区（scheduled start）累计 | [DeviceActivityEvent](https://developer.apple.com/documentation/deviceactivity/deviceactivityevent) |
| Web domain 含 Safari 及通过 `STWebpageController` 贡献用量的第三方浏览器 | 同上 |
| `DeviceActivityEvent` 在指定 `applications` / `categories` / `webDomains` 组合累计使用**超过** `threshold`（`DateComponents`）时，系统调用扩展主类的 `eventDidReachThreshold` | [threshold](https://developer.apple.com/documentation/deviceactivity/deviceactivityevent/threshold)；[init(...threshold:)](https://developer.apple.com/documentation/deviceactivity/deviceactivityevent/init(applications:categories:webdomains:threshold:))；[eventDidReachThreshold](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor/eventdidreachthreshold(_:activity:)) |
| 若三者皆空，事件包含**全部** apps / categories / web domains（`includesAllActivity == true`） | [includesAllActivity](https://developer.apple.com/documentation/deviceactivity/deviceactivityevent/includesallactivity)；同上 init Discussion |
| 用户通过 `FamilyActivityPicker` 选择；app 只拿到 opaque tokens，再交给 DeviceActivity / ManagedSettings | [FamilyActivityPicker](https://developer.apple.com/documentation/familycontrols/familyactivitypicker)；[FamilyActivitySelection](https://developer.apple.com/documentation/familycontrols/familyactivityselection) |

这与产品「本机屏幕使用」粗信号一致（前台可见活动），且不依赖已否决的 idle / Vision 代理（ADR 0008 / 0009）。

### 2.2 日程窗口与重武装

| 事实 | 来源 |
|------|------|
| 监控绑在**日历日程** `DeviceActivitySchedule`（`intervalStart` / `intervalEnd` / `repeats` / 可选 `warningTime`）上 | [DeviceActivitySchedule](https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule) |
| `startMonitoring(_:during:events:)` 在指定 schedule 上启动；events 空则只收 interval start/end | [startMonitoring](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/startmonitoring(_:during:events:)) |
| 累计只计 **activity 的 scheduled interval 内**的使用 | DeviceActivityEvent init Discussion |
| `includesPastActivity`：是否把 `startMonitoring` **之前**、但仍在当前 schedule 窗口内的使用计入阈值；`false` 时可从「现在」重新起算 | [init(...includesPastActivity:)](https://developer.apple.com/documentation/deviceactivity/deviceactivityevent/init(applications:categories:webdomains:threshold:includespastactivity:)) |
| 默认 init（无 `includesPastActivity`）：若调用时 schedule 已在进行，系统**只考虑开始监控之后**的活动 | [init(...threshold:)](https://developer.apple.com/documentation/deviceactivity/deviceactivityevent/init(applications:categories:webdomains:threshold:)) Important |
| 再次 `startMonitoring` 同名 activity 会**覆盖**先前 schedule/events | [startMonitoring](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/startmonitoring(_:during:events:)) |
| 扩展可在主 app 未运行时由系统回调；样例在 `eventDidReachThreshold` / interval 回调里操作 `ManagedSettingsStore` | [DeviceActivityMonitor](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor)；[Device Activity](https://developer.apple.com/documentation/deviceactivity) |

**对 Work Interval 的映射（推断自上述保证，非 Apple 产品语义）：**

1. 在宽日历窗口（例如日重复、≥15 分钟且 ≤1 周）上挂 `threshold ≈ Work Interval`（默认 20 min 落在合法范围内）。  
2. `eventDidReachThreshold` → 应用进入 Rest。  
3. Return / Reset 后再次 `startMonitoring`（`includesPastActivity: false` 或默认「自监控开始起算」）→ 新一轮 Work Interval。  

API **不**提供「Rest 结束后自动清零」或 lock 时长语义；那是应用职责（ADR 0007）。

### 2.3 调度粒度与硬限制

| 限制 | 数值 / 行为 | 来源 |
|------|-------------|------|
| Schedule 最短 | **15 minutes**（`intervalTooShort`） | [intervalTooShort](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/monitoringerror/intervaltooshort) |
| Schedule（含 events）最长 | **one week**（`intervalTooLong`） | [intervalTooLong](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/monitoringerror/intervaltoolong) |
| 同时监控 activities 上限 | **20**（app + extensions）（`excessiveActivities`） | [excessiveActivities](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/monitoringerror/excessiveactivities) |
| 过密 / 过多 unique tightly-scheduled activities | `startMonitoring` 抛错；文档建议用 `warningTime` 代替拆碎 schedule | [startMonitoring](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/startmonitoring(_:during:events:)) |
| `warningTime` | 可在 interval 将起/将止、以及距 threshold 还差 `warningTime` 时回调 `eventWillReachThresholdWarning` | [warningTime](https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule/warningtime) |
| `intervalDidStart` / `intervalDidEnd` | **仅当设备正在使用时**才调用 | [intervalDidStart](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor/intervaldidstart(for:))；[intervalDidEnd](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor/intervaldidend(for:))；[DeviceActivityCenter](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter) |
| 时区 | 事件用量按 `nextInterval.start` 时的设备时区算满整个 interval；墙钟 end 不受中途时区变化影响 | [startMonitoring](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/startmonitoring(_:during:events:))；[nextInterval](https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule/nextinterval) |
| 平台 | DeviceActivity **macOS unavailable**（iOS 16+） | iOS SDK `DeviceActivity.swiftinterface` `@available(macOS, unavailable)` |

Threshold 本身以 `DateComponents` 表达；官方文档**未**单独给出「threshold 最短必须 ≥15 分钟」——15 分钟约束写在 **schedule interval** 上。Work Interval 默认 20 分钟作为 threshold 与「≥15 分钟日程窗口」兼容。

---

## 3. 授权撤销、后台、低电量

| 主题 | 官方说了什么 | 未说什么 |
|------|--------------|----------|
| 撤销 / 否认 | tokens 作废；`unauthorized`；`authorizationStatus` 可变 | 撤销瞬间是否保证投递最后一次 threshold 回调 |
| 后台 | Monitor 是 **app extension**；系统在 schedule/threshold 时调用，无需用户打开主 app | 扩展执行时长上限、被杀后的重试策略 |
| 低电量 / Low Power Mode | DeviceActivity 文档与 SDK interface **未**提及 LPM / 电池对回调的保证 | 任何投递延迟或丢弃的 SLA |

因此「可靠」在工程上应理解为：**系统承诺在用量超过 threshold 时调用扩展方法**，而非实时闹钟级保证。产品表述应保持 **coarse signal**。

---

## 4. 与 Rest Cycle / ADR 0007 的边界

| Rest Cycle 要素 | DeviceActivity 能否单独承担 |
|-----------------|---------------------------|
| 累计本机屏幕使用达到 Work Interval → 进入 Rest | **Conditional yes**：`eventDidReachThreshold` + 正确 schedule/event/重武装 |
| Rest 最短时长 UI / 「休息好了」Return | **No**：无对应 API；应用 UI |
| lock/sleep 墙钟 ≥ Rest minimum → Reset | **No**：DeviceActivity 不暴露 lock 墙钟；属应用（ADR 0007） |
| 短 lock 不计入用眼、Rest 累计墙钟 | **No**：需应用自己的 lock 观察 |
| 跨设备「一段用眼」Continuity | **No**（本票范围外）：Monitor 驱动的是本机；Report 扩展沙盒禁止网络与外泄敏感内容（[DeviceActivityReport](https://developer.apple.com/documentation/deviceactivity/deviceactivityreport)） |

**Report vs Monitor：** Report 沙盒「cannot make network requests or move sensitive content outside the extension’s address space」——与「用 Monitor 阈值作本地粗信号、自建同步 Rest Cycle」的产品分界一致；**不要**指望从 Report 抽出用量去驱动 Rest。

---

## 5. 明确回答（供 map / Continuity / to-spec）

**能否驱动 Rest？ → Conditional.**

- **Yes（有条件）：** individual 授权 + 合法 `startMonitoring`（日程 ≥15 分钟、≤1 周、activities ≤20）+ `DeviceActivityEvent.threshold` = Work Interval（空 selection = 全部前台用量，或用户选出的 apps/categories/domains）→ `eventDidReachThreshold` 可作为**进入 Rest** 的本机粗驱动；Return/Reset 后需 `includesPastActivity: false`（或等价重武装）开始下一 Work Interval。  
- **No（不能单独）：** 不能替代 ADR 0007 的 Rest 出口（仅 Return / Reset）与 lock≥Rest minimum→Reset；不能假定撤销授权、删应用、或未文档化的低电量场景下仍可靠；不能当作跨设备 Screen Time 明细。

**定位建议：** DeviceActivity 阈值 = Rest Cycle 的 **本机进入 Rest 粗信号**；Rest Cycle 权威状态机仍在应用（及后续自建 Continuity 同步），与 map issue #1 的产品意图一致。

---

## Source index

1. [Family Controls](https://developer.apple.com/documentation/familycontrols)  
2. [AuthorizationCenter.requestAuthorization(for:)](https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:))  
3. [AuthorizationCenter](https://developer.apple.com/documentation/familycontrols/authorizationcenter) / [authorizationStatus](https://developer.apple.com/documentation/familycontrols/authorizationcenter/authorizationstatus)  
4. [FamilyControlsError](https://developer.apple.com/documentation/familycontrols/familycontrolserror)  
5. [FamilyActivitySelection](https://developer.apple.com/documentation/familycontrols/familyactivityselection) / [FamilyActivityPicker](https://developer.apple.com/documentation/familycontrols/familyactivitypicker)  
6. [Device Activity](https://developer.apple.com/documentation/deviceactivity)  
7. [DeviceActivityCenter](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter) / [startMonitoring](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/startmonitoring(_:during:events:))  
8. [DeviceActivitySchedule](https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule) / [warningTime](https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule/warningtime) / [nextInterval](https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule/nextinterval)  
9. [DeviceActivityEvent](https://developer.apple.com/documentation/deviceactivity/deviceactivityevent) / [threshold](https://developer.apple.com/documentation/deviceactivity/deviceactivityevent/threshold) / inits with/without `includesPastActivity`  
10. [DeviceActivityMonitor](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor) / [eventDidReachThreshold](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor/eventdidreachthreshold(_:activity:))  
11. [MonitoringError](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/monitoringerror) cases: `intervalTooShort` (15 min), `intervalTooLong` (1 week), `excessiveActivities` (20), `unauthorized`  
12. [DeviceActivityReport](https://developer.apple.com/documentation/deviceactivity/deviceactivityreport) (sandbox; not a Rest driver)  
13. iOS SDK: `DeviceActivity.framework` / `FamilyControls.framework` `arm64e-apple-ios.swiftinterface`（平台可用性、`MonitoringError`、`FamilyControlsMember.individual`）  
14. Repo domain: `GLOSSARY.md`；`docs/adr/0007-unified-lock-reset-and-simpler-rest-exits.md`
