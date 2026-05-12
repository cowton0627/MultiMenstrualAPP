# Bugs / 踩坑紀錄

這份文件記錄專案開發過程踩過、或別人很可能會踩到的坑。每條包含**症狀 / 根因 / 解法**三段。新坑請追加在最下面，不要刪舊的。

---

## 1. 新增 `.swift` 檔後 build 通過但 type 找不到

- **症狀**：在 Xcode 或 SourceKit 看到 `Cannot find type 'X' in scope`，但檔案在資料夾內存在
- **根因**：檔案沒被加進 `MultiMenstrualAPP.xcodeproj/project.pbxproj`，Xcode 不知道要編譯它
- **解法**：在 pbxproj 手動 4 處編輯（`PBXBuildFile`、`PBXFileReference`、parent `PBXGroup` children、target `Sources` phase），或在 Xcode 內直接拖檔進 navigator 讓 IDE 自己處理。對應 `runbook.md` 的「加新 `.swift` 檔到專案」段

## 2. GitHub push 被 `workflow scope` 擋下

- **症狀**：`remote rejected — refusing to allow a Personal Access Token to create or update workflow`
- **根因**：PAT 沒開 `workflow` scope，GitHub 不允許它新增或修改 `.github/workflows/*`
- **解法**：到 https://github.com/settings/tokens 編輯 PAT 加上 `workflow` scope；或改用 SSH key push

## 3. View 裡 `PersistenceController.shared` fallback 害測試跑到真實 store

- **症狀**：unit test / SwiftUI Preview 看到正式資料、測試之間互相污染
- **根因**：早期 `MultiProfilesView.init(context: NSManagedObjectContext? = nil)` 在 `nil` 時 fallback 抓 `PersistenceController.shared`，導致沒注入 context 也能跑
- **解法**：移除 fallback，把 `context` 改成必填，由上層（`AppRootView`）從 `@Environment(\.managedObjectContext)` 注入

## 4. `@ObservedObject var person: Person` 在 entity 被刪除後讀寫即 crash

- **症狀**：在 PersonSettingsView 編輯到一半，他人或匯入流程把該 person 刪掉，dismiss 之後 view 讀到 dangling reference
- **根因**：view 直接持有 `NSManagedObject`，entity 的生命週期由 context 控制，不是 view
- **解法**：view 改吃 read model（`PersonProfile` / `PeriodRecordSnapshot`），save/delete 時 view model 用 `objectID` 走 repository 重撈，撈不到就丟 `RepositoryError.notFound`

## 5. Reload-token UUID hack 抓不到 Core Data 變動

- **症狀**：在 add sheet 或 import 流程新增了人物，dismiss 後 Profiles 列表沒更新
- **根因**：`ProfilesViewModel` 沒有訂閱 Core Data 變動，靠 `AppRootView` 的 `@State profilesReloadToken = UUID()` + `onSaved` callback 通知刷新；只要有任何寫入入口忘記串 callback 就漏
- **解法**：view model 改用 `NSFetchedResultsController` + 實作 `controllerDidChangeContent` delegate，Core Data 變動會自動 propagate 到 `@Published`，整套 callback 拆掉

## 6. SourceKit 紅字但 `xcodebuild` 過

- **症狀**：剛新增的檔案在 Xcode editor 看到一堆 `Cannot find ... in scope` 紅波浪，但 `xcodebuild build` 完全 OK
- **根因**：SourceKit 還沒重 index，跟編譯器不同套
- **解法**：忽略 SourceKit；以 `xcodebuild` 結果為準。或重啟 Xcode / 切 scheme 強迫 re-index

## 7. 多個 in-memory `NSPersistentContainer` 噴 `Failed to find a unique match for an NSEntityDescription`

- **症狀**：跑測試時 console 出現紅色 `+[Person entity] Failed to find a unique match for an NSEntityDescription to a managed object subclass`，但測試全部過
- **根因**：同一個 process 內多次 `NSPersistentContainer(name: "MultiPeriod")` 載入同一份 model，entity class 對不到唯一 model 來源
- **解法**：可忽略（不影響測試結果）。要消除得改 `TestCoreDataFactory` 共用一份 `NSManagedObjectModel` 物件，多個 store 共用之

## 8. struct 自訂 init 後 memberwise init 消失

- **症狀**：在測試裡 `ExportProfile(id: ..., name: ..., colorHex: ...)` 寫不出來，編譯說 `no exact matches in call to initializer`
- **根因**：Swift 在 struct 提供任何自訂 init 之後，就不會再自動合成 memberwise init
- **解法**：在 struct 內顯式補一個 memberwise init（已補在 `ExportProfile`）

## 9. macOS 系統 Python 不能直接 `pip install`

- **症狀**：`error: externally-managed-environment ... PEP 668`
- **根因**：macOS 內建 Python 受系統 site-packages 保護
- **解法**：跑 `pip install --user --break-system-packages Pillow numpy`；或裝 Homebrew / pyenv 自己一份 Python。用 icon 產生 script 之前需要這兩個套件
