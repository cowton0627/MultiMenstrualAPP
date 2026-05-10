# Roadmap

整理工作的 milestone 列表。完成項目搬到底部「已完成」區，附上 commit hash 方便追溯。

---

## 現在優先

### Snapshot / UI 測試（P2-3）

讓 UI 退化能被 PR diff 抓到。

- 加入 `pointfreeco/swift-snapshot-testing` 為 SPM 依賴
- 為主要畫面建 baseline snapshot：`CalendarScreen`、`MultiProfilesView`、`InsightsHomeView`、`RecordPeriodView`
- 雙模式：light + dark
- CI workflow 跑 snapshot 測試，失敗時 upload diff artifact

依賴：需要決定基準模擬器型號（iPhone 15 / 16？）並 lock 在 CI 中。

### Brand / 上架素材（P2-4 剩下）

Splash dismissal 已改用 `.task / Task.sleep`（c8edfca）；其餘：

- jf-openhuninn 字型授權確認與 bundle 大小評估
- `CherryBlossom` Lottie 在 dark mode 下的對比檢查
- App Store icon / launch image / 隱私問卷（如需送審）

### Domain model 細部（P1-1 剩下）

read model 已到位（`PersonProfile` / `PersonSummary` / `PeriodRecordSnapshot`），write input 也對稱了（`PersonAttributes` 4fe7df3 / `PeriodRecordInput`）。剩下：

- 評估是否引入 `PersonID` / `PeriodRecordID` newtype 包住 `NSManagedObjectID`，避免 view layer 直接看到 Core Data 型別（低優先）

---

## 想到再做

- 匯出 JSON 升 schemaVersion 2（向下相容 v1）
- WidgetKit 顯示下次預測
- iPad layout 適配（目前 swatch grid 在 iPad 顯太鬆）
- Reminder 通知整合 `Shared/Services/ReminderScheduler.swift`（目前未串接 UI）

---

## 已完成

### P0 — 穩定主流程與資料邊界

| Item | 內容 | Commit |
|---|---|---|
| P0-5 | PersonSettingsView 改吃 `PersonProfile` input model | `197aa9a` |
| P0-6 | RecordPeriodViewModel 改吃 `PeriodRecordSnapshot` | `197aa9a` |
| P0-7 | CalendarViewModel 補單元測試（6 cases） | `d95c614` |
| P0-8 | 統一錯誤處理（`AlertError` + `.errorAlert(_:)`） | `e552425` |

### P1 — Domain / Data 分層

| Item | 內容 | Commit |
|---|---|---|
| P1-1 | Person / PeriodRecord domain model（read model）部分達成 | `197aa9a` |
| P1-2 | Repository protocol | `6498d79` |
| P1-3 | CalendarVM 對 PeriodRecord entity 改 read model（兩段） | `187ffe7`, `d962802` |
| P1-4 | mapper 位置統一（隱含於 P0-5 / P0-6） | — |
| P1-5 | persistence 拆分（repositories → `Shared/Persistence/`） | `e27d486`, `14c1bcf` |

### P2 — UX / Design System

| Item | 內容 | Commit |
|---|---|---|
| P2-1 | 卡片樣式抽 `cardSurface()` / `elevatedCardSurface()` | `bf3c490` |
| P2-2 | typo / 命名清理（Domin → Domain、Records / Person 搬進 Features/） | `38cc3ab` |
| P2-4 部分 | Splash dismissal 改 `.task` | `c8edfca` |

### Bonus（不在原 ROADMAP 內、session 過程完成）

- Stylised sakura app icon（程式產生，37 個尺寸）：`546899e`
- CalendarScreen 多筆紀錄改用 List sheet（threshold 5）：`5124eec`
- 3-tab 首頁 + JSON 匯入匯出：`b55ba56`
- AppRootView 拆成 Insights / Backup / SettingsPanel：`c567db3`
- ProfilesVM 改用 NSFetchedResultsController + 拿掉 reload-token 補丁：`187ffe7`
- 砍 ~2.4 MB 未使用 asset：`5b7ded7`
- GitHub Actions CI：`6742927`
- `DECISIONS.md`（架構決策記錄）：`0314553`
- `scripts/gen_app_icon.py` 收進 repo：`9aaf4f3`
- README 對齊現況：`9b2684c`
- VM / Backup 測試批次（從 23 → 52 cases）：`e1b1b42`, `54f4513`

---

## GitHub Issue 建議格式

開新 issue 時用 `.github/ISSUE_TEMPLATE/` 裡的模板（Bug Report / Refactor Task）。標題前綴維持：

- `[P0] / [P1] / [P2]` 表示 milestone
- `[Refactor] / [Bug] / [Feature]` 表示性質

每張 issue 至少包含：背景、問題、目標、非目標、驗收條件。
