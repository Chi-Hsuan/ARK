# AI Agent 影響分析 INDEX 使用說明

## 1. 設計目的

本資料庫提供 AI 與 SA 進行：

- 需求涉及功能辨識
- API 與程式入口定位
- Function 使用範圍評估
- 外部電文影響反查
- 回歸測試範圍初步評估

INDEX 是導航資料，不是規格書，也不是程式碼的替代品。

資訊可信順序：

1. Source Code：實際技術行為的最終依據
2. Spec：業務規則的依據
3. INDEX：快速定位與評估範圍的入口

若 INDEX 與程式碼不一致，分析結論以程式碼為準，並提出 INDEX 更新建議。

---

## 2. 資料結構

### 2.1 API Index

位置：

index/api_index.md

用途：

由自然語言需求、功能名稱或關鍵字，找到 API 與 Java 程式入口。

欄位定義：

| 欄位 | 填寫規則 |
|----------|----------|
| 功能分類 | 使用業務可理解的功能名稱 |
| 關鍵字 | 放入需求常見用語，以逗號分隔 |
| 使用場景 | 簡單描述何時會使用此 API |
| API | HTTP Method 加 URL |
| Service | Java 完整類別路徑加入口 Function |
| Service目的 | 一句話描述此入口負責的範圍 |
| Spec | 有規格文件時填路徑，沒有時填 - |

範例：

| 臺幣現金存提 | 現金存提,存款,提款,帳號清單 | 進入臺幣現金存提款功能時取得帳號清單 | POST /TWDW001/010 | com.cathaybk.dbs.twdw.twdw001.task.TWDW001_010.handle | 初始化存入、提出帳號及後續交易資料 | - |

限制：

- 同一個 API 與入口 Function 不可重複建立。
- Service 不可只寫 TWDW001_010.handle，必須使用完整類別路徑。
- 不在此處描述條件分支、錯誤處理或完整業務規則。

### 2.2 Function Index

位置：

index/functions/{API代號}.md

用途：

由 API 程式入口快速了解此 Service 呼叫哪些外部或共用 Function，以及使用原因。

新增方式：

`functions/` 底下的 `{API代號}.md` 是空白範本，檔名保留佔位符原樣，不要填寫或刪除它。新增一支 Service 時複製一份，改名為實際的 API 代號（例如 `TWDW001.md`）後再填內容。

固定格式：

1. Service 名稱
2. 用途
3. 程式位置
4. API
5. Function 範圍表

Function 範圍表欄位：

| 欄位 | 填寫規則 |
|----------|----------|
| Function | 實際呼叫的外部 Function 名稱 |
| 功能目的 | Function 做什麼，保持一句話 |
| 共用來源 | 外部 Function 所在的 Java 完整類別路徑 |
| 使用原因 | 說明此 Service 為何需要呼叫或使用它 |

共用來源範例：

com.cathaybk.dbs.twdw.utils.TWDWUtils

com.cathaybk.dbs.twdw.twdw001.msg.TWDW001_TxnData

限制：

- 程式位置與共用來源必須使用完整 Java 類別路徑。
- 只收錄定義在目前 Service 類別之外的 Function。
- 包含繼承基底類別、注入共用類別及靜態工具類別的 Function。
- 排除定義在目前 Service 類別內的 public、protected 或 private Function。
- Function 欄必須填外部類別實際被呼叫的方法，不可填目前 Service 的包裝方法。
- 外部 Function 指專案內可被多個 Service 使用的共用行為。
- 不收錄 DTO、Entity 的 getter/setter、建構子、Java 標準函式庫或集合操作。
- 只列出評估影響範圍所需資訊。
- 不加入相關電文欄位。
- 不加入輸入輸出欄位明細、完整流程、規則、例外、風險或測試說明。
- 電文關係統一放在 Downstream Api Index，避免重複維護。
- Function 不可由名稱猜測，必須從程式碼確認。

### 2.3 Function Reference

Function Reference 不建立獨立檔案。

反查方法：

1. 取得 Function 名稱或完整共用類別名稱。
2. 搜尋 index/functions/ 內全部 Markdown。
3. 命中的檔案名稱代表使用該 Function 或類別的 Service。
4. 再回查 API Index，取得相關 API 與使用場景。

用途：

評估修改外部 Function 或其宣告類別時，可能影響哪些 Service 與 API。

### 2.4 Downstream Api Index

位置：

index/downstream_api_index.md

用途：

由外部系統或電文代號，反查使用的 Service、Function 與 API。

資料組織方式：

1. 第一層使用電文系統作為標題，例如 FNS、FST、MSP、MTS。
2. 第二層使用電文代號作為標題，例如 FNSCIF0003。
3. 每個電文代號下建立使用關係表。
4. 同一電文被多個 Service 使用時，在同一代號下增加多列，不重複建立代號標題。

使用關係表欄位：

| 欄位 | 填寫規則 |
|----------|----------|
| 電文名稱 | 可辨識的簡短名稱 |
| 電文目的 | 一句話描述電文用途 |
| 使用場景 | 說明何時使用 |
| 使用Service | 使用此電文的完整 Java 類別路徑 |
| 使用Function | 實際呼叫 Function |
| 相關API | 對外 API |
| Spec | 電文規格路徑，沒有時填 - |

限制：

- 系統名稱統一使用正式縮寫，例如 FNS，不使用 DEP HOST。
- 系統及電文代號依名稱排序，避免資料散落。
- 只有實際外部呼叫才可建立。
- 電文代號、Function 與 API 必須從程式碼確認。
- 不記錄 request 或 response 欄位明細。
- 不把 Downstream Api Index 的內容複製到 Function Index。

---
## 3. AI 查詢流程

### 情境一：由需求評估影響範圍

1. 從需求擷取功能、關鍵字與使用場景。
2. 查詢 API Index，找出候選 API 與完整 Java 入口。
3. 讀取對應 Function Index，取得外部 Function 與共用來源。
4. 用 Function 名稱或完整類別名稱反查其他 Function Index。
5. 查詢 Downstream Api Index，確認外部系統依賴。
6. 讀取實際程式碼，驗證入口、呼叫鏈與依賴。
7. 輸出直接影響、共用影響、外部系統影響與建議回歸範圍。

### 情境二：由程式或 Function 評估影響範圍

1. 確認完整 Java 類別名稱與 Function。
2. 搜尋全部 Function Index。
3. 找到使用它的 Service。
4. 回查 API Index 取得 API 與使用場景。
5. 必要時查詢 Downstream Api Index。
6. 由程式碼確認實際呼叫關係。

### 情境三：由電文評估影響範圍

1. 以系統名稱或電文代號查詢 Downstream Api Index。
2. 取得使用 Service、Function 與 API。
3. 讀取對應 Function Index。
4. 反查共用 Function 使用範圍。
5. 由程式碼確認呼叫條件與實際影響。

---

## 4. INDEX 更新規則

建立或更新 INDEX 時，AI 必須：

1. 先讀取程式碼，不可只依檔名推測。
2. 確認 API、入口 Function、完整 package 與 class 名稱。
3. API Index 僅新增或修改一筆功能導航資料。
4. Function Index 僅收錄目前 Service 呼叫的外部 Function。
5. 外部電文只維護在 Downstream Api Index。
6. 所有 Java 程式與物件使用完整類別路徑。
7. 無法從程式碼確認的內容填 - 或標記待確認，不可自行補完。
8. 寫入後檢查重複資料、Markdown 欄位數及檔案路徑。
9. 不因整理 INDEX 而修改應用程式碼。

---

## 5. 禁止事項

AI 不可：

- 將 INDEX 寫成規格書或程式逐行說明。
- 省略 Java package，只留下簡短類別名稱。
- 在 Function Index 重複維護電文。
- 將推測內容寫成已確認事實。
- 未讀程式碼就建立 Function 或呼叫關係。
- 因 INDEX 沒有資料就判定功能不存在。
- 用 INDEX 覆蓋 Source Code 或 Spec 的結論。
