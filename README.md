# ARK

一組角色型 AI agent，協助團隊把需求、規格、程式與知識庫維持在同一條線上。

支援 **GitHub Copilot** 與 **Codex**，兩邊操作方式一致。

---

## 這是什麼

軟體開發的文件很容易與程式脫鉤——需求改了規格沒改、程式改了知識庫沒更新。等到有人發現時，已經沒有人記得當初為什麼那樣寫。

ARK 用四個角色分擔開發流程的各段，並且**所有交棒都透過文件**。agent 不靠對話記憶接力，而是讀寫固定位置的文件，因此每一次異動都會在文件上留下痕跡，也能被追蹤有沒有補完。

| 角色 | 職能 | 主要負責 |
| --- | --- | --- |
| **Ark Navigator** | PO | 需求開立、釐清、需求書、進度追蹤 |
| **Ark Architect** | SA | 異動影響評估、系統規格、測試問題的影響層面判定 |
| **Ark Builder** | PG | 程式、單元測試、code review、驗收檢核、弱點修復 |
| **Ark Librarian** | 知識庫 | 上線後回寫知識庫、與程式的一致性檢查 |

另有 **Ark 總管**作為統一入口，負責判斷專案狀態並切換角色。

---

## 安裝

ARK 是**複製進專案**使用的，不是全域安裝。一個專案只需要有一個人做一次，之後檔案跟著版控走，團隊其他人 clone 專案就能直接用。

### macOS / Linux

在**目標專案資料夾**執行：

```bash
git clone --depth 1 https://github.com/Chi-Hsuan/ARK.git /tmp/ark && /tmp/ark/install.sh && rm -rf /tmp/ark
```

### Windows

在 PowerShell 執行：

```powershell
git clone --depth 1 https://github.com/Chi-Hsuan/ARK.git $env:TEMP\ark
& "$env:TEMP\ark\install.ps1"
```

出現「無法載入檔案，因為這個系統上已停用指令碼執行」時改用：

```powershell
powershell -ExecutionPolicy Bypass -File "$env:TEMP\ark\install.ps1"
```

### 安裝之後

1. 用 VS Code 開啟該專案
2. **Reload Window**（Copilot 才會載入 ARK 的 agent）
3. 叫用 **Ark** 總管 → 選擇「導入 / 升級 ARK」
4. 依問答填入專案名稱與文件根目錄，總管會建立文件骨架
5. 把 `.ark/`、`.github/`、`AGENTS.md` 與文件資料夾**提交進版控**

第 5 步做完，團隊其他人不需要再執行任何安裝。

---

## 日常使用

| 工具 | 怎麼開始 |
| --- | --- |
| Copilot | 在 chat 的 agent 清單選擇 **Ark**（或直接選個別角色） |
| Codex | 直接對話即可，它會讀 `AGENTS.md` 進入總管 |

兩邊都是**先叫總管、再從選單挑工作**。角色可以在對話中途切換，不必回到總管。

Copilot 使用者也可以直接點選個別角色（Ark Navigator(PO)、Ark Architect(SA)…），但教學與新人上手建議統一走總管，這樣兩個工具的操作一致。

---

## 專案裡會多出什麼

```
你的專案/
├── .ark/                      ARK 的實質內容（流程、角色、技能、範本）
├── .github/
│   ├── agents/                Copilot 角色
│   └── skills/                Copilot 技能
├── AGENTS.md                  Codex 入口
└── docs_{專案名稱}/
    ├── requirements/          【流動】一需求一資料夾，上線後凍結
    ├── spec/                  【現況】前端 / 後端 / 資料庫規格
    └── library/               【現況】系統概要與各類索引
```

`requirements/` 是過程紀錄，`spec/` 與 `library/` 是現況快照。三者的接點是上線——`spec/` 在規格修訂當下就要跟上，`library/` 則在上線後回寫。

詳細說明見專案文件根目錄的 `README.md`。

---

## 更新 ARK

在專案資料夾重跑同一行安裝指令。腳本會顯示 `ARK 1 → 2`，覆寫 `.ark/` 但**保留 `.ark/config.yml`**；接著叫用總管執行升級，它會依 `.ark/CHANGELOG.md` 說明這版需要做什麼。

升級是**逐專案執行**的。這是刻意的設計——你不會希望改了 ARK 之後，所有正在進行中的專案隔天早上文件慣例全變了。

版本用兩個檔案追蹤：

| 檔案 | 意義 |
| --- | --- |
| `.ark/VERSION` | 目前這份 `.ark/` 檔案是哪一版（隨安裝覆寫） |
| `.ark/config.yml` 的 `ark_version` | 這個專案上次**完成升級**到哪一版 |

兩者不同 = 有升級動作還沒執行。

---

## 給維護者

### 中立層與轉接層

`.ark/` 是唯一的實質內容來源，Copilot 與 Codex 各自只有一層薄轉接：

| 檔案 | 角色 |
| --- | --- |
| `.ark/roles/`、`.ark/skills/`、`.ark/workflow.md` | **實質內容，改這裡** |
| `.github/agents/*.agent.md` | Copilot 轉接層，只負責指路 |
| `.github/skills/*/SKILL.md` | Copilot 技能轉接層，只負責指路 |
| `AGENTS.md` | Codex 轉接層 |

**修改角色行為或流程規則時只改 `.ark/`。** 改轉接層會讓兩個工具的行為開始分歧。

### 新增技能

在 `.ark/skills/` 新增後，兩側轉接層都要補：

```bash
.ark/tools/sync-adapters.sh          # 檢查缺什麼
.ark/tools/sync-adapters.sh --write  # 補上 Copilot 轉接層
```

`AGENTS.md` 的技能表有角色分組，工具只提示缺漏，需自行加到正確位置。

### 專案結構

```
ARK/
├── install.sh / install.ps1   安裝指令
├── AGENTS.md                  Codex 轉接層（也是 ARK 自己的）
├── .github/                   Copilot 轉接層
├── .ark/
│   ├── VERSION  CHANGELOG.md  config.yml
│   ├── workflow.md            共用流程與規則
│   ├── roles/                 五個角色定義
│   ├── skills/                各項工作的執行步驟
│   ├── templates/             文件範本與 docs 骨架
│   ├── standards/             內部套件規範
│   └── tools/                 維護用腳本
└── docs_ARK/                  ARK 自己的文件（dogfooding）
```

`docs_ARK/` 是 ARK 用自己的規範管理自己的文件——同時也是給人看的結構範例。
