# ARK 專案文件架構範本

本資料夾是**與 ARK 協作的專案，建議採用的文件資料夾結構**。

ARK 由四個角色型 agent 組成，各自負責軟體開發流程的一段。它們共同的前提是：**文件是唯一的溝通介面**。agent 不靠對話記憶接力，而是靠讀寫這些文件把工作交棒給下一棒——因此文件放在哪、叫什麼名字、什麼時候該更新，都必須是可預期的。這份範本就是在定義那份可預期性。

## 資料夾總覽

```
{docs_root}/
├── README.md                                # 本檔案，說明整體文件架構
│
├── requirements/                            # 【流動】逐案管理，一需求一資料夾
│   ├── Requirements 需求資料夾說明.md          # 需求資料夾的結構與命名規則
│   ├── requirement_index.md                 # 需求總管，所有需求的單一入口索引
│   └── {年度}/
│       └── 【需求編號】_需求單位_需求名稱/
│           ├── 需求書_需求名稱.md
│           ├── 異動影響評估書_需求名稱.md
│           ├── 測試問題追蹤表_需求名稱.md
│           ├── release_docs/                # 上線文件 (Checkmarx、SonarQube 報告等)
│           └── bu_reference/                # 需求單位提供的參考文件
│
├── spec/                                    # 【現況】系統規格，回答「系統是怎麼做的」
│   ├── README.md                            # 規格的命名規則與撰寫範圍
│   ├── frontend/                            # 前端規格
│   ├── services/                            # 後端系統規格，同組 API 代號一個資料夾
│   │   └── {API代號前綴}_{功能名稱}/
│   │       └── 系統規格書_{API代號}_{功能名稱}-{子功能名稱}.md
│   └── schema/                              # 資料庫規格，一張表一份
│
├── library/                                 # 【現況】知識庫，回答「系統有什麼、在哪裡」
│   ├── system_overview.md                   # 系統概要：有哪些功能、主流程
│   ├── business/                            # 業務知識
│   └── index/                               # 各類索引
│       ├── INDEX_README.md                  # 索引的欄位定義、查詢流程與維護規則
│       ├── functions/                       # 一支 Service 一份
│       │   └── {API代號}.md              # 該 Service 呼叫的外部 function
│       ├── api_index.md                     # 本服務主要的後端 API
│       └── downstream_api_index.md          # 會呼叫到的下游服務
│
└── code/                                    # 【程式】實際程式碼，不進本 repo 的版控
    ├── README.md                            # 版控規則與已取得的倉庫清單
    ├── .gitignore                           # 只保留說明文件，其餘一律忽略
    └── {系統名稱}/                            # 各自帶有 .git 的獨立倉庫
```

## 三個區塊

整個架構分成三塊，第一刀切在**時間軸**：

| | requirements/ | spec/ + library/ |
| --- | --- | --- |
| 性質 | 流動 | 現況 |
| 描述的是 | 這次要改什麼 | 系統現在長什麼樣 |
| 生命週期 | 逐案建立，上線後凍結 | 持續更新，永遠反映最新狀態 |
| 讀者 | 需求關係人、開發者 | 任何要理解系統的人（含 agent） |

`requirements/` 是**過程紀錄**，一個需求上線後就成為歷史，不再變動。`spec/` 與 `library/` 是**現況快照**，任何時候讀它們都應該等於系統當下的真實樣貌。

第二刀切在**深度**——同樣描述現況，但用途不同：

| | spec/ | library/ |
| --- | --- | --- |
| 回答的問題 | 這塊是怎麼做的 | 系統有什麼、東西在哪裡 |
| 粒度 | 細節：欄位、介面、流程、資料結構 | 全貌與索引 |
| 典型用法 | 要動某個功能前，先讀它的規格 | 不知道從哪找起時，先讀它定位 |
| 更新時機 | 規格變更當下 | 需求上線後回寫 |

`library/` 是入口，`spec/` 是內容。找不到東西時從 `library/index/` 進去，找到之後到 `spec/` 讀細節。

三者的接點是上線：`spec/` 在規格修訂當下就要跟上，`library/` 則在上線後回寫。任一步沒做，現況文件就開始失真。

## code/ 不是文件區塊

`code/` 放的是程式碼本身，不是文件。它跟前三塊放在一起只有一個理由：**讓 agent 讀規格與讀程式不必跨 workspace**。

它與其他三塊有兩個關鍵差異：

- **不進本 repo 的版控**——每個子資料夾是獨立的 git 倉庫，由 `code/.gitignore` 排除，只有 `code/README.md` 會被提交
- **沒有 agent 負責維護**——ARK 的角色只讀它、不管理它的內容；程式的變更走各自倉庫的流程

細節見 [code/README.md](code/README.md)。

## 角色與文件對應

| 角色 | 對應職能 | 主要產出 / 維護的文件 |
| --- | --- | --- |
| Ark Navigator | PO | 需求書、`requirement_index.md` 的需求登錄與進度 |
| Ark Architect | SA | 異動影響評估書、`spec/` 系統規格、測試問題追蹤表的影響層面判定 |
| Ark Builder | PG | 程式與單元測試，依驗收標準驗收、修復 SonarQube / Checkmarx 弱點 |
| Ark Librarian | 知識庫維護 | 上線後回寫 `library/`、確認 `spec/` 與實際一致，並更新需求總管的「知識庫同步」欄 |

## 文件流轉

```
需求提出
  │
  ├─ Navigator ──▶ requirement_index.md 登錄一列
  │                需求書_需求名稱.md
  │
  ├─ Architect ──▶ 異動影響評估書_需求名稱.md
  │                （評估範圍、影響、驗收標準）
  │                spec/ 系統規格修訂
  │
  ├─ Builder ────▶ 程式實作、單元測試
  │                release_docs/ 存放掃描報告
  │
  ├─ 測試期間 ───▶ 測試問題追蹤表_需求名稱.md
  │                SA 判定影響層面 → 決定回頭改哪份文件
  │                （需求面 / 規格面 / 程式面）
  │
  └─ 上線後 ─────▶ Librarian 回寫 library/、確認 spec/ 一致
                   requirement_index.md 標記「已同步」
```

這條線有兩個防止文件與程式脫鉤的檢查點：

1. **測試期間**——每個 bug 都要判定影響層面。若屬需求面或規格面，需求書、異動影響評估書或 `spec/` 系統規格必須跟著改，由測試問題追蹤表的「文件更新狀態」欄追蹤
2. **上線後**——異動回寫 `library/`、確認 `spec/` 與實際一致，由需求總管的「知識庫同步」欄追蹤

## 延伸閱讀

- [requirements/Requirements 需求資料夾說明.md](requirements/Requirements%20需求資料夾說明.md) — 需求資料夾的結構與命名規則
- [requirements/requirement_index.md](requirements/requirement_index.md) — 需求總管，含狀態與知識庫同步定義
- [spec/README.md](spec/README.md) — 系統規格的命名規則與撰寫範圍
- [library/index/INDEX_README.md](library/index/INDEX_README.md) — 索引的欄位定義、查詢流程與維護規則
- [code/README.md](code/README.md) — 程式碼資料夾的版控規則與已取得的倉庫清單
