# MultiMenstrualAPP

`MultiMenstrualAPP` 是一個以 SwiftUI 與 Core Data 實作的 iOS 經期追蹤 App，支援在同一支裝置中管理多個人物 profile，為每個人記錄經期區間、在月曆上顯示紀錄，並依最近週期做簡單預測。

## 目前產品定位

這個專案目前不是 camera 或 media app，而是「多人經期管理」產品。核心使用流程是：

1. 新增人物 profile
2. 進入個人的月曆畫面
3. 新增、編輯、刪除經期紀錄
4. 依歷史紀錄估算下一次週期視窗

## 已完成功能

- Splash 進入流程
- 多人 profile 列表
- 新增人物
- 個人月曆畫面
- 新增 / 編輯經期紀錄
- 編輯 / 刪除人物
- 經期區間映射
- 點選日期命中紀錄判斷
- 簡單週期預測

## 技術架構

目前程式碼正從「畫面直接驅動流程」整理成較清楚的分層：

- `MultiMenstrualAPP/APP`
  - App entry
  - Core Data persistence
- `MultiMenstrualAPP/Shared`
  - `RootView`
  - `AppRootView`
  - shared UI / utilities
- `MultiMenstrualAPP/Features/Profiles`
  - profile list
  - add person
  - profile repository / models
- `MultiMenstrualAPP/Features/Calendar`
  - calendar UI
  - calendar view model
  - domain logic
- `MultiMenstrualAPP/Records`
  - record editor
  - record repository
- `MultiMenstrualAPP/Person`
  - person settings

### 目前重要檔案

- `MultiMenstrualAPP/APP/MultiMenstrualApp.swift`
- `MultiMenstrualAPP/Shared/UI/RootView.swift`
- `MultiMenstrualAPP/Shared/UI/AppRootView.swift`
- `MultiMenstrualAPP/Features/Profiles/UI/MultiProfilesView.swift`
- `MultiMenstrualAPP/Features/Calendar/UI/CalendarScreen.swift`
- `MultiMenstrualAPP/Records/RecordPeriodView.swift`

## 資料模型

目前 Core Data 主要有兩個 entity：

- `Person`
  - `id`
  - `name`
  - `colorHex`
  - `createdAt`
- `PeriodRecord`
  - `id`
  - `startDate`
  - `endDate`
  - `notes`
  - `person`

## 近期重構進度

最近一輪已經完成：

- app flow 改成由 `AppRootView` 統一協調
- 新增 `AppRoute` / `AppSheet`
- `CalendarScreen` 不再自己持有 editor sheet
- `CalendarViewModel` 改成輸出 action
- 補齊 calendar domain 單元測試
- 開始把 UI 對 Core Data entity 的直接依賴往下壓
- 將 git repository 根目錄整理到專案外層，納入 `.xcodeproj`

## 測試

目前已補上的核心單元測試：

- `CyclePredictorTests`
- `RecordHitResolverTests`
- `PeriodRangeMapperTests`

Build for testing：

```bash
xcodebuild -project MultiMenstrualAPP.xcodeproj \
  -scheme MultiMenstrualAPP \
  -destination 'generic/platform=iOS Simulator' \
  build-for-testing
```

## 下一步

下一輪整理方向已放在：

- `docs/ROADMAP.md`
- `.github/ISSUE_TEMPLATE/`

主要會繼續處理：

- repository / domain model 分層
- calendar flow 與 entity coupling 收斂
- README / repo 管理規格化

## Repository

GitHub repository:

- `https://github.com/cowton0627/MultiMenstrualAPP`
