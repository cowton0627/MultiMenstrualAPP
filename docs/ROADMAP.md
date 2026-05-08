# Roadmap

這份文件把目前下一輪整理拆成可執行的 milestone 與 issue 草案，方便後續搬到 GitHub issue / milestone。

## Milestone P0: 穩定主流程與資料邊界

目標：

- 先讓 app flow、calendar flow、record editor flow 穩定
- 降低 UI 對 Core Data entity 的直接依賴
- 讓後續重構能在可測試的基礎上繼續

Issue 草案：

1. `P0-5` 將 `PersonSettingsView` 改成 profile input model 驅動，而不是直接綁 `Person`
2. `P0-6` 將 `RecordPeriodViewModel` 改成由 `PeriodRecordInput` / context model 驅動
3. `P0-7` 為 `CalendarViewModel` 補更多 action / state 單元測試
4. `P0-8` 統一錯誤處理與存檔後回饋，不再只用 `print` / `assertionFailure`

完成條件：

- editor flow 由上層協調
- 主要寫入入口集中
- 核心 domain 皆有基本測試保護

## Milestone P1: Domain / Data 分層

目標：

- 將 Core Data entity 從 feature UI 進一步隔離
- 補足 repository protocol 與 mapper

Issue 草案：

1. `P1-1` 為 `Person` / `PeriodRecord` 定義更清楚的 domain model
2. `P1-2` 將 `PersonRepository` / `PeriodRecordRepository` 對齊成一致介面
3. `P1-3` 把 `CalendarViewModel` 對 `PeriodRecord` entity 的依賴改成 read model
4. `P1-4` 新增 mapper，統一 entity -> UI model 轉換
5. `P1-5` 拆分 persistence concern 與 feature concern

完成條件：

- 主要畫面不再直接以 Core Data entity 當成 UI model
- repository 責任清楚
- mapper 位置與命名固定

## Milestone P2: UX / Design System / 維護性

目標：

- 整理視覺、命名、共用元件
- 提升可維護性與可替換性

Issue 草案：

1. `P2-1` 統一背景、字型、按鈕、表單列樣式
2. `P2-2` 清理歷史命名與資料夾 typo
3. `P2-3` 補畫面級測試或 snapshot 測試
4. `P2-4` 整理品牌資源與 splash 流程

## 建議實作順序

1. 先完成 `P0`
2. 再開始 `P1`
3. 最後才進 `P2`

原因：

- 現在真正的風險是資料邊界與 flow 邏輯，不是視覺
- 若 `P1` 太早做，很容易在 flow 還沒穩定時重複改動

## GitHub Issue 建議格式

標題建議：

- `[P0] 收斂 PersonSettings 的 entity 依賴`
- `[P1] 為 PeriodRecord 建立 read model 與 mapper`
- `[P2] 建立 shared design tokens`

每張 issue 內容至少包含：

- 背景
- 問題描述
- 目標
- 非目標
- 驗收條件
