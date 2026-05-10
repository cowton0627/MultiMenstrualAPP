# DECISIONS

這份文件只記「為什麼這樣選」與「放棄過哪些方案」，不重複 README 已經說過的「怎麼用 / 怎麼裝」。新增決策時請追加 section，盡量不要改舊的；放棄某條決策也用「Superseded by」標註，不要直接刪除歷史。

---

## 1. Feature-first 資料夾結構

`MultiMenstrualAPP/Features/{Profiles, Calendar, Records, PersonSettings, Insights, Backup}` 各自包一個 user-visible flow，內部自己分 `UI / Presentation / Domain`。

- **為什麼**：一個 feature 的 view、view model、domain logic 改起來會一起動，放一起 cohesion 高、cross-feature 影響小。
- **放棄過**：layer-first（`Views/ ViewModels/ Repositories/`）。早期就是這個結構，結果加新功能時要同時動四個資料夾，且容易跨 feature 重用而模糊邊界。
- **例外**：跨 feature 共用的東西放 `Shared/`（例：`Persistence/`、`UI/SettingsPanel.swift`、`Extensions/`）。

## 2. View 不直接持有 Core Data entity

所有 view / view model 對外只認 read model：
- `PersonProfile`：給編輯流程用（name, colorHex, objectID）
- `PersonSummary`：給列表用（多帶 `recordCount`、`latestStartDate`）
- `PeriodRecordSnapshot`：給 record editor 與 calendar picker 用

- **為什麼**：`NSManagedObject` 是 reference type，活在 context 裡，被刪除/換 context 會 crash 或行為飄。讓 view 拿到的就是 immutable struct，view layer 不再需要關心 Core Data 生命週期。
- **怎麼回寫**：editor view model 只記 `objectID`，存檔時透過 `Repository.save(..., objectID:)` 由 repository 自己再撈一次 entity。撈不到就 throw `RepositoryError.notFound`。
- **放棄過**：`PersonSettingsView` 一開始用 `@ObservedObject var person: Person`，refactor 成 input model 之後 view body 完全不再讀 entity（P0-5 / P0-6 commit）。

## 3. Repository protocol + concrete class

每個 repository 都對應一個 protocol（`PersonRepositoryProtocol`、`PeriodRecordRepositoryProtocol`），暴露「畫面實際會用到的 surface」。

- **為什麼**：未來測 view model 時可以塞 fake；同時也是「外部能呼叫什麼」的 documented contract。
- **故意限制**：protocol 不暴露 `Person` / `PeriodRecord` entity（例如 `fetchPerson(objectID:) -> Person?` 是 `private`），呼叫端只能拿到 read model，避免再次把 entity 漏出去。
- **寫入用 input struct**：`add(_ attributes: PersonAttributes)` / `update(objectID:, attributes:)` / `save(input: PeriodRecordInput, ...)`。把 add 與 update 餵的東西收成 struct 而不是散參數，介面對稱、未來加欄位也只動一個 type。
- **VM init 收 protocol**：`init(repository: PersonRepositoryProtocol)`。view 在 init 時自己建 concrete 並餵進去；測試可以 inject fake 而不必 mock NSManagedObjectContext。

## 4. 列表用 NSFetchedResultsController，不用 reload token

`ProfilesViewModel` / `CalendarViewModel` 都是 `NSObject` + 自己持有 FRC + 實作 `controllerDidChangeContent` 觸發 recompute。

- **為什麼**：Core Data 變動會自動 propagate 到 UI，不必手動 invalidate。
- **放棄過**：早期用 `@State profilesReloadToken = UUID()` + `onSaved` callback 一路傳到 sheet，sheet 存完呼 callback 讓上層重 fetch。問題是每多一個寫入入口（add、edit、import）就要再串一條線，最後變成「每個能寫的地方都要記得通知」。FRC 一次解決。

## 5. 跨 feature 的 data 集中在 `Shared/Persistence/`

`PersonRepository` 與 `PeriodRecordRepository` 都被 3+ 個 feature 用到，因此搬離 `Features/Profiles/Data/` 與 `Features/Records/`。

- **規則**：data 層只屬於某一個 feature 才放在 `Features/<X>/Data/`；只要被第二個 feature 引用就要升級到 `Shared/Persistence/`。
- **為什麼**：避免「為了拿一個 repository 而 import 不相關 feature 的目錄」。

## 6. 視覺 token 集中在 `AppTheme`

`AppTheme` 提供顏色、stroke、shadow、cornerRadius 常數；常用組合提供 `.cardSurface()` / `.elevatedCardSurface()` view modifier。

- **為什麼**：原本 8 個不同 view 各自寫 `RoundedRectangle(cornerRadius: 8) + .regularMaterial + AppTheme.subtleStroke + 可能加 softShadow` 那串，要改 corner radius 或 stroke 顏色得 grep 八個地方。
- **放棄過**：每個 view 自己 inline 那串組合。

## 7. 錯誤呈現走 `AlertError` + `.errorAlert(_:)`

VM 拋的錯誤由 view 用 `@State alertError: AlertError?` 接住，套 `.errorAlert($alertError)` modifier 就會 render 成單按鈕 alert。

- **為什麼**：之前散落的 `print("Save error:", error)` 與 `assertionFailure(...)` 在 release build 會被吞掉，使用者看不到任何回饋。
- **故意保留**：`SettingsHomeView` 的「匯入完成」用另一個 alert 不走 errorAlert，因為它是 success 訊息語意不同。

## 8. CalendarVM 是 `NSObject` 是因為 FRC delegate

`CalendarViewModel: NSObject, ObservableObject` 看起來很違和，但 `NSFetchedResultsControllerDelegate` 只能由 NSObject 實作；ProfilesViewModel 同模式。

- **為什麼**：Apple framework 的限制，無法解。
- **影響**：VM 的 init 必須先 `super.init()` 再 configure FRC，不能用 stored property 預設值。
