# MoonTime

iOS 时间管理 App（SwiftUI，iOS 17+），根据 MoonTime 设计稿实现：规划 → 专注 → 复盘。

## 屏幕

| 设计稿 | 代码 |
| --- | --- |
| 今天 · 时间轴 | `MoonTime/Views/TodayView.swift`、`DayTimeline.swift` |
| 专注计时 | `MoonTime/Views/FocusView.swift` |
| 晚间复盘 | `MoonTime/Views/ReviewView.swift` |
| 收件箱（Tab 栏入口） | `MoonTime/Views/InboxView.swift` |
| 锁屏实时活动 + 灵动岛四种状态 | `MoonTimeWidgets/FocusLiveActivity.swift` |

- 点一个时间块开始专注；长按可标记完成、移到明天或删除。
- 专注时会启动实时活动（锁屏 + 灵动岛紧凑/最小/展开），按钮（暂停、+15 分钟、完成）直接在锁屏上生效。
- 下一个时间块开始前 5 分钟提醒（推迟 10 分钟 / 好的）。
- 复盘页根据当天实际用时对比计划，自动生成一句总结。

## 运行

需要 Xcode 15+ 和 [XcodeGen](https://github.com/yonaskolb/XcodeGen)：

```sh
brew install xcodegen
xcodegen
open MoonTime.xcodeproj
```

在两个 target 的 Signing 里选你的开发团队，必要时把 `project.yml` 里的 bundle id（`com.example.moontime`）改成你自己的。实时活动需要真机或 iOS 17 模拟器。

## 已知限制

- 数据目前只在内存里，带一天示例数据；下一步可以接 SwiftData 和日历（EventKit）同步。
- App 在后台时，"即将开始"提醒由本地通知发出；要让锁屏上的实时活动在后台也切换成提醒样式，需要服务端发 ActivityKit 推送。

## 未签名 IPA

每次推送到 `main` 或开发分支，GitHub Actions（`.github/workflows/unsigned-ipa.yml`）都会在 macOS 上构建一个未签名的 `MoonTime-unsigned.ipa`，发布到仓库的 Releases（预发布）。安装前需要用 AltStore、Sideloadly 或自己的开发者证书重新签名。

## 玻璃效果

iOS 26 及以上使用系统的 Liquid Glass（`glassEffect`），iOS 17–25 回退为毛玻璃材质加高光描边。相关代码在 `MoonTime/Views/Glass.swift`。
