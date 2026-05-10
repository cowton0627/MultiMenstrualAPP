# Runbook

操作流程速查。新流程請追加，不要刪舊的。

---

## Build & run on simulator

```bash
xcodebuild build \
  -project MultiMenstrualAPP.xcodeproj \
  -scheme MultiMenstrualAPP \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

要實際在模擬器跑 app，最簡單還是在 Xcode 內按 ⌘R。

## 跑全部測試

```bash
# 列出本機可用的 simulator UDID
xcrun simctl list devices available

# 用 UDID 跑（避免「找不到 destination」問題）
xcodebuild test \
  -project MultiMenstrualAPP.xcodeproj \
  -scheme MultiMenstrualAPP \
  -destination 'id=<simulator-UDID>' \
  CODE_SIGNING_ALLOWED=NO
```

或 `-destination 'platform=iOS Simulator,name=iPhone 15'`。CI 在 `.github/workflows/ci.yml` 也是跑這條。

## 重新產 App Icon

```bash
pip install --user --break-system-packages Pillow numpy   # 第一次
python3 scripts/gen_app_icon.py
```

輸出直接覆寫 `MultiMenstrualAPP/Resources/Assets.xcassets/AppIcon.appiconset/` 裡所有 37 個尺寸。改色 / 改花瓣形狀就改 `gen_app_icon.py` 頂部的 palette / petal 常數區塊。

## 加新 `.swift` 檔到專案（pbxproj 手動編輯）

如果不在 Xcode 內拖檔，需要在 `MultiMenstrualAPP.xcodeproj/project.pbxproj` **4 處**加 entry。以加 `Foo.swift` 進 `Shared/UI` group + main app target 為例：

1. **`PBXBuildFile` section**：
   ```
   <NEW_BUILD_ID> /* Foo.swift in Sources */ = {isa = PBXBuildFile; fileRef = <NEW_FILE_ID> /* Foo.swift */; };
   ```
2. **`PBXFileReference` section**：
   ```
   <NEW_FILE_ID> /* Foo.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Foo.swift; sourceTree = "<group>"; };
   ```
3. **parent `PBXGroup` children**：
   把 `<NEW_FILE_ID> /* Foo.swift */,` 加進對應 group 的 `children = (...)` 區塊
4. **`PBXSourcesBuildPhase` files**：
   把 `<NEW_BUILD_ID> /* Foo.swift in Sources */,` 加進 main target 的 sources phase

ID 用 24 字元 hex；本專案習慣用 `91F000xx2FFC100100A513EF` 系列。test target 用獨立的 sources phase（看 pbxproj 內 `91D7A0162FB2E08900A513EF /* Sources */`）。

驗證：`xcodebuild build` 應該過。

## CI failure 偵錯

GitHub Actions 跑 `.github/workflows/ci.yml`，失敗時：

1. 到 https://github.com/cowton0627/MultiMenstrualAPP/actions 看那次 run 的 log
2. workflow 失敗時會 upload `TestResults.xcresult` 為 artifact，下載後 `xcrun xcresulttool get --path TestResults.xcresult --format json` 或直接用 Xcode 開
3. 常見原因：CI runner 上 simulator 名字 / OS version 跟 workflow 裡寫的對不到 → 改 destination 為 `OS=latest` 或換型號

## Xcode 行為怪 / build 卡住

```bash
# 清 DerivedData（最常見的萬靈藥）
rm -rf ~/Library/Developer/Xcode/DerivedData/MultiMenstrualAPP-*

# 模擬器卡掉 / Core Data 殘留
xcrun simctl erase all   # 危險：清掉所有 simulator 的資料
```

清完重開 Xcode。

## 看 Core Data 實體資料

跑 app 時 Core Data store 在模擬器的 sandbox 內。用 simctl 查路徑：

```bash
# 找出 app 的 sandbox
xcrun simctl get_app_container booted cowton0627.MultiMenstrualAPP data
# 進去翻 Library/Application Support/<appname>/MultiPeriod.sqlite
```

`MultiPeriod.sqlite` 可以直接用 SQLite Browser 開來看。或在程式碼裡開啟 SQL log（`-com.apple.CoreData.SQLDebug 1` 加進 scheme arguments）。

## 匯出 / 匯入 JSON 備份手動操作

App 內走「設定 → 匯出資料」會打開系統 file exporter，存成 `MultiMenstrualAPP-yyyymmdd.json`。匯入流程吃同一格式（`schemaVersion: 1`），會用 UUID merge 既有資料。

JSON schema 由 `MultiMenstrualAPP/Features/Backup/Domain/ExportPayload.swift` 的 `ExportPayload / ExportProfile / ExportPeriodRecord` 決定。改 schema 必須升 `schemaVersion` 並在 `importInto` 中保留向下相容（已列入 `docs/roadmap.md` 的「想到再做」）。
