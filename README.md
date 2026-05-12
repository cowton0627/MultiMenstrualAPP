# MultiMenstrualAPP

A SwiftUI + Core Data iOS menstrual-cycle tracker built around managing **multiple profiles on a single device**, fully offline.

---

## 隱私與授權

此專案目前設計為離線使用，不包含雲端同步、第三方分析或廣告 SDK；經期資料儲存在裝置本機 Core Data。JSON 匯出會包含人物名稱、經期日期與備註，請視為敏感私人資料。詳細說明見 [`PRIVACY.md`](./PRIVACY.md)。

專案原始碼採 [MIT License](./LICENSE) 授權，可自由使用 / 修改 / 散布 / 商用，需保留 copyright 與 license 文字。第三方套件、字型、Lottie 動畫依各自授權，見 [`THIRD_PARTY_LICENSES.md`](./THIRD_PARTY_LICENSES.md)。

---

## 產品定位

「多人經期管理」的離線小工具。三個分頁：

- **首頁**：人物清單 → 個人月曆 → 新增 / 編輯經期紀錄
- **總覽**：跨人物統計（人數、紀錄數、即將來潮預測、最近紀錄）
- **設定**：JSON 匯出 / 匯入備份（schema v1）

人物用顏色區分；每人獨立週期、獨立預測（取最近 3 次週期平均推算下一次起始日 ±2 天的視窗）。

## 已完成功能

- Splash 進入動畫（櫻花 Lottie）
- 多人 profile 列表 + 新增 / 編輯 / 刪除
- 個人月曆：已記錄區間 + 預測視窗
- 經期紀錄新增 / 編輯（含「尚未結束」狀態）
- 跨人物統計與下次預測（總覽分頁）
- JSON 全量備份匯出 / 匯入
- 自製櫻花 app icon（程式產生，37 個尺寸）
- 共用錯誤 alert / 卡片樣式 / `AppTheme` design tokens
- GitHub Actions CI（push / PR 自動跑 build + test）

## 技術 / 架構

**技術棧**：SwiftUI · Core Data · iOS 15+ · Swift 5.0 · Lottie (`airbnb/lottie-ios`) · XCTest · GitHub Actions CI

**Design pattern**：

- **MVVM**：view ↔ `@Published` VM ↔ repository
- **Feature-first 結構**：每個 feature 分 `UI / Presentation / Domain` 三層
- **Read model (DTO)**：view / VM 不接觸 `NSManagedObject`，只用 `PersonProfile` / `PersonSummary` / `PeriodRecordSnapshot`
- **Repository + protocol**：VM 收 protocol，測試可 inject fake
- **Typed ID newtype**：`PersonID` / `PeriodRecordID` 包住 `NSManagedObjectID`，view layer 看不到 Core Data 型別
- **NSFetchedResultsController**：列表自動跟著 Core Data 變動 propagate，不靠手動 reload token
- **Design tokens**：`AppTheme` + `.cardSurface()` / `.elevatedCardSurface()` modifier
- **統一錯誤處理**：VM 拋 → `.errorAlert($alertError)` modifier

每項背後的取捨理由見 [`DECISIONS.md`](./DECISIONS.md)。

## 資料夾結構

```
MultiMenstrualAPP/
├── APP/                    # @main entry + Core Data persistence
├── Features/
│   ├── Profiles/           # 人物清單與新增
│   ├── Calendar/           # 月曆 + view model + domain logic
│   ├── Records/            # 經期紀錄編輯
│   ├── PersonSettings/     # 個人設定（編輯 / 刪除）
│   ├── Insights/           # 總覽分頁
│   └── Backup/             # JSON 匯出 / 匯入
├── Shared/
│   ├── UI/                 # RootView, AppRootView, AppTheme, modifiers, alerts
│   ├── Persistence/        # 跨 feature 共用 repository
│   ├── Extensions/
│   └── Services/
├── Resources/              # Assets / 字型 / Lottie
└── MultiMenstrualAPPTests/ # 單元測試
```

每個 feature 內部分 `UI / Presentation / Domain` 三層；read model（`PersonProfile` / `PersonSummary` / `PeriodRecordSnapshot`）跨層使用，view 不接觸 Core Data entity。

架構選擇的理由見 [`DECISIONS.md`](./DECISIONS.md)。

## 重要檔案

- `MultiMenstrualAPP/APP/MultiMenstrualApp.swift` — `@main`
- `MultiMenstrualAPP/Shared/UI/RootView.swift` — splash → AppRootView 切換
- `MultiMenstrualAPP/Shared/UI/AppRootView.swift` — TabView 路由 + sheet 入口
- `MultiMenstrualAPP/Features/Calendar/UI/CalendarScreen.swift` — 月曆主畫面
- `MultiMenstrualAPP/Features/Records/RecordPeriodView.swift` — 經期紀錄編輯
- `MultiMenstrualAPP/Shared/Persistence/PersonRepository.swift`
- `MultiMenstrualAPP/Shared/Persistence/PeriodRecordRepository.swift`

## 資料模型

Core Data 兩個 entity：

- `Person`: `id`, `name`, `colorHex`, `createdAt`
- `PeriodRecord`: `id`, `startDate`, `endDate`, `notes`, `person`

刪除 `Person` 時其 `records` 會 cascade。

## Build & Test

Deployment target iOS 15+，Swift 5.0。

```bash
# Build
xcodebuild build \
  -project MultiMenstrualAPP.xcodeproj \
  -scheme MultiMenstrualAPP \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO

# 跑全部測試（52 cases）
xcodebuild test \
  -project MultiMenstrualAPP.xcodeproj \
  -scheme MultiMenstrualAPP \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  CODE_SIGNING_ALLOWED=NO
```

每次 push 到 `main` 與每個 PR 都會由 `.github/workflows/ci.yml` 自動跑 `xcodebuild test`。

目前測試分布：

- `CyclePredictorTests` / `RecordHitResolverTests` / `PeriodRangeMapperTests` — 純 domain logic
- `CalendarViewModelTests` / `AddPersonViewModelTests` / `RecordPeriodViewModelTests` / `PersonSettingsViewModelTests` / `ProfilesViewModelTests` — view models（用 in-memory Core Data container）
- `ExportPayloadTests` — JSON 備份 round-trip
- `TestCoreDataFactory` — 共用 in-memory container 與 entity factory

## 在自己的環境執行 / fork 後設定

repo 內 `PRODUCT_BUNDLE_IDENTIFIER` 設為 `cowton0627.MultiMenstrualAPP`、`DEVELOPMENT_TEAM` 為空。clone 下來後：

- **只在模擬器跑 / 跑測試**：上面的 `xcodebuild` 指令已帶 `CODE_SIGNING_ALLOWED=NO`，不需要任何 Apple Developer 帳號設定。
- **要在實機跑或上架**：在 Xcode 開啟專案 → 選 `MultiMenstrualAPP` target → **Signing & Capabilities** → 把 Team 改成你自己的 Apple Developer Team，並把 Bundle Identifier 改成你自己的 reverse-domain（例如 `com.yourname.MultiMenstrualAPP`），否則會撞別人的 Bundle ID。

## 重新產 App Icon

`scripts/gen_app_icon.py` 用 Pillow + numpy 產整套 37 個尺寸的櫻花 icon。改色或調花瓣形狀後重跑：

```bash
pip install --user --break-system-packages Pillow numpy
python3 scripts/gen_app_icon.py
```

輸出會直接覆寫 `MultiMenstrualAPP/Resources/Assets.xcassets/AppIcon.appiconset/`。

## 知識文件

- [`DECISIONS.md`](./DECISIONS.md) — 架構選擇的「為什麼」
- [`docs/roadmap.md`](./docs/roadmap.md) — 已完成 + 後續整理規劃
- [`bugs.md`](./bugs.md) — 踩過的坑（症狀 / 根因 / 解法）
- [`runbook.md`](./runbook.md) — Build / test / icon / pbxproj / CI 等操作流程
- `.github/ISSUE_TEMPLATE/` — issue 模板

## Repository

`https://github.com/cowton0627/MultiMenstrualAPP`
