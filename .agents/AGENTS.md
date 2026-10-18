# PureAspectFrame AI 開發代理人工作規範 (AI Developer Guidelines)

> 本文件為所有 AI 代理人（**Antigravity**、**Cursor**、Claude Code 等）在開發本專案時必須嚴格遵守的最高指導方針。  
> 專案為純 macOS / iOS 原生 Swift 開發環境，所有編譯、單元測試、模擬器與實體機部署均在本機（macOS 26+）直接執行。

---

## 🛑 1. 核心開發守則：嚴格 TDD 與原子切片

為了保證代碼品質並在有限的對話長度與 AI 額度內穩健推進，**所有 AI 代理人喚醒時必須無條件遵循以下協議**：

### 1.1 喚醒啟動檢查（Start-of-Turn Routine）
任何開發任務開始前，**先執行且必須執行**以下動作：
1. 讀取 `BACKLOG.md` 與 `UIUX_SPEC.md`，確認當前所屬 Phase 與下一動任務。
2. 執行 `git status` 與 `git log -n 3`，確認本機工作區乾淨且無殘留死代碼。
3. 明確告知使用者：「*目前進度為 Task X.X，本次將依據 TDD 流程實作 Task Y.Y*」，然後才開始動作。

### 1.2 嚴格測試驅動開發鐵律（The Iron Law of TDD）
未經測試驗證的代碼嚴禁寫入產品檔案：
1. **Red（撰寫失敗測試）**：
   - 先在 `PureAspectFrameTests/` 中撰寫針對新功能或修復的測試案例。
   - 執行測試確認測試**確實編譯失敗或斷言失敗**，驗證測試有效性：
     ```bash
     xcodebuild test -scheme PureAspectFrame -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -quiet
     ```
2. **Green（最小實作通過）**：
   - 僅撰寫讓該測試剛好通過的最小必要程式碼，嚴禁一次過度工程擴散。
   - 再次執行測試，確認全部測試 100% 通過（0 失敗）。
3. **Refactor（嚴謹重構與優化）**：
   - 在測試保護傘下清理重複邏輯、優化命名與效能。
   - 每次重構後再次驗證測試全綠。

### 1.3 嚴禁批量生成，堅持原子循環（Atomic Slices）
* **一問一事**：一次僅專注於一個獨立功能點（例如「四邊留白連結邏輯」或「底欄防碰撞演算法」）。
* **嚴禁批量寫爛代碼**：嚴禁一口氣建立多個未經編譯與測試驗證的空白檔案。
* 任務規模控制在 15~30 分鐘的開發切片，保證在對話長度消耗前能安全著陸。

---

## 🤖 2. 模型分工建議 (Model Routing & Roles)

在 Antigravity 或 Cursor 中切換模型時，建議依任務複雜度分流：

1. **工蜂與快速實作 $\rightarrow$ Gemini 3.8 Flash**：
   - 日常程式碼撰寫、重構、快速修復 (Bug-fix)。
   - 執行測試循環、檔案搜尋與語法檢查。
2. **深度推理與架構判斷 $\rightarrow$ Claude Opus 5.5 / Sonnet 5.5**：
   - 複雜演算法設計（如 CoreGraphics 多圖無縫切割、座標系投影矩陣計算）。
   - 交叉審查、重大架構定案與疑難除錯。

---

## 🛠️ 3. 技術架構與設計規範 (Tech Stack & Architecture)

* **目標平台**：iOS 26.0+ 與 macOS 26.0+（不支援 visionOS）。
* **介面外觀**：
  - 原生 Apple **Liquid Glass** 透明玻璃質感（`LiquidGlassModifier.swift`）。
  - 純白或深色背景自適應 Light / Dark Mode，**全 App 嚴禁使用漸層背景**。
* **資料持久化**：
  - SwiftData 原生框架：`ManualLens`（手動老鏡庫）、`FrameTemplate`（畫布模板）、`ArtworkRecord`（匯出歷史）。
* **雙模式儲存策略**：
  - 「保留輸出圖片」：完整寫入高解析度點陣圖。
  - 「僅保留設定」：僅記錄相片參照與畫布設定，瀏覽或再次導出時即時重繪，節省 98% 空間。
* **影像與排版引擎**：
  - CoreGraphics 多層畫布合成（背景層、照片層、白框遮罩層、底欄資訊層）。
  - 坐標系轉換：CoreGraphics 原點在左下角（Y 軸向上），UIKit 文字繪製需做上下文垂直翻轉（CTM Flip），並啟用動態字級自動縮小以防文字重疊碰撞。
* **並行性與線程安全**：
  - Swift Concurrency (`@MainActor`, `Sendable`, `async/await`)，禁止阻塞主執行緒。

---

## 📱 4. 驗證協議 (Verification Protocols)

### 4.1 單元測試驗證
```bash
xcodebuild test -scheme PureAspectFrame -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -quiet
```
確認所有測試套件（ModelTests, ExifTests, ImageRendererTests, UIWorkflowTests 等）均通過。

### 4.2 iOS 模擬器畫面與互動驗證
1. 建置並安裝至模擬器：
   ```bash
   xcodebuild -scheme PureAspectFrame -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -configuration Debug -derivedDataPath /tmp/PureAspectFrameBuild build
   xcrun simctl install booted /tmp/PureAspectFrameBuild/Build/Products/Debug-iphonesimulator/PureAspectFrame.app
   xcrun simctl launch booted wangtc07.PureAspectFrame
   ```
2. 透過 Xcode MCP 工具或 simctl 捕捉實際執行畫面截圖進行視覺驗證：
   ```bash
   xcrun simctl io booted screenshot <path-to-screenshot.png>
   ```

### 4.3 實體手機 (iPhone) 部署驗證
* **開發團隊設定**：`DEVELOPMENT_TEAM = YQ96QH9M8W`
* **Bundle ID**：`wangtc07.PureAspectFrame`
* 建置並部署至實體裝置：
   ```bash
   # 1. 建置實體機版本
   xcodebuild -scheme PureAspectFrame -destination 'platform=iOS,id=<DEVICE_UDID>' -allowProvisioningUpdates -configuration Debug -derivedDataPath /tmp/PureAspectFrameIPhoneBuild build
   
   # 2. 安裝至實體手機
   xcrun devicectl device install app --device <DEVICE_UDID> /tmp/PureAspectFrameIPhoneBuild/Build/Products/Debug-iphoneos/PureAspectFrame.app
   ```
* **注意**：實體機首次啟動需在手機上前往「設定」$\rightarrow$「一般」$\rightarrow$「VPN 與裝置管理」信任開發者憑證。

---

## 📦 5. 驗證通過後的 Git 提交指令 (Git Commit Protocol)

在完成單元測試與畫面驗證後，必須立即執行版本控制收尾：

### 步驟 1：檢視異動清單
```bash
git status
git diff --stat
```

### 步驟 2：更新開發看板
在 `BACKLOG.md` 中將已驗證完成之任務核取標記更新為 `[x]`。

### 步驟 3：暫存與語意化提交
依據異動性質選用正確語意前綴：
* `feat(...)`: 新功能實作
* `fix(...)`: 缺陷修復
* `test(...)`: 增加或修改單元測試
* `refactor(...)`: 程式碼結構重構（無功能增減）
* `docs(...)`: 文件或規範更新

**執行範例**：
```bash
# 暫存變更檔案
git add BACKLOG.md PureAspectFrame/ PureAspectFrameTests/ .agents/

# 執行語意化 Commit
git commit -m "feat(core): 完成畫布四邊留白直調與動態底欄防重疊引擎"

# 檢視提交歷史確認
git log -n 1 --stat
```
