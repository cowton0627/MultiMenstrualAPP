# Roadmap

整理工作的 milestone 列表。完成項目搬到底部「已完成」區。

---

## 現在優先

### Snapshot / UI 測試（P2-3）

讓 UI 退化能被 PR diff 抓到。

- 加入 `pointfreeco/swift-snapshot-testing` 為 SPM 依賴
- 為主要畫面建 baseline snapshot：`CalendarScreen`、`MultiProfilesView`、`InsightsHomeView`、`RecordPeriodView`
- 雙模式：light + dark
- CI workflow 跑 snapshot 測試，失敗時 upload diff artifact

依賴：需要決定基準模擬器型號（iPhone 15 / 16？）並 lock 在 CI 中。

### Brand 素材

Splash dismissal 已改用 `.task / Task.sleep`；其餘：

- `CherryBlossom` Lottie 在 dark mode 下的對比檢查

---

## 想到再做

- 匯出 JSON 升 schemaVersion 2（向下相容 v1）
- WidgetKit 顯示下次預測
- iPad layout 適配（目前 swatch grid 在 iPad 顯太鬆）
- Reminder 通知整合 `Shared/Services/ReminderScheduler.swift`（目前未串接 UI）

---

## 已完成

### P0 — 穩定主流程與資料邊界

| Item | 內容 |
|---|---|
| P0-5 | PersonSettingsView 改吃 `PersonProfile` input model |
| P0-6 | RecordPeriodViewModel 改吃 `PeriodRecordSnapshot` |
| P0-7 | CalendarViewModel 補單元測試（6 cases） |
| P0-8 | 統一錯誤處理（`AlertError` + `.errorAlert(_:)`） |

### P1 — Domain / Data 分層

| Item | 內容 |
|---|---|
| P1-1 | Person / PeriodRecord domain model（read model）部分達成 |
| P1-2 | Repository protocol |
| P1-3 | CalendarVM 對 PeriodRecord entity 改 read model（兩段） |
| P1-4 | mapper 位置統一（隱含於 P0-5 / P0-6） |
| P1-5 | persistence 拆分（repositories → `Shared/Persistence/`） |

### P2 — UX / Design System

| Item | 內容 |
|---|---|
| P2-1 | 卡片樣式抽 `cardSurface()` / `elevatedCardSurface()` |
| P2-2 | typo / 命名清理（Domin → Domain、Records / Person 搬進 Features/） |
| P2-4 部分 | Splash dismissal 改 `.task` |

### Bonus（不在原 ROADMAP 內、session 過程完成）

- Stylised sakura app icon（程式產生，37 個尺寸）
- CalendarScreen 多筆紀錄改用 List sheet（threshold 5）
- `PersonID` / `PeriodRecordID` newtype 取代 `NSManagedObjectID` 在 view / route / read model 的曝光
- 3-tab 首頁 + JSON 匯入匯出
- AppRootView 拆成 Insights / Backup / SettingsPanel
- ProfilesVM 改用 NSFetchedResultsController + 拿掉 reload-token 補丁
- 砍 ~2.4 MB 未使用 asset
- GitHub Actions CI
- `DECISIONS.md`（架構決策記錄）
- `scripts/gen_app_icon.py` 收進 repo
- README 對齊現況
- VM / Backup 測試批次（從 23 → 52 cases）

---

## GitHub Issue 建議格式

開新 issue 時用 `.github/ISSUE_TEMPLATE/` 裡的模板（Bug Report / Refactor Task）。標題前綴維持：

- `[P0] / [P1] / [P2]` 表示 milestone
- `[Refactor] / [Bug] / [Feature]` 表示性質

每張 issue 至少包含：背景、問題、目標、非目標、驗收條件。
