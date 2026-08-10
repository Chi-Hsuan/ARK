# ARK 變更紀錄

`init-project` 技能升級專案時，依本檔逐版執行「升級動作」。

每個版本的格式：**變更內容**說明這版改了什麼，**升級動作**列出既有專案需要做什麼才能跟上。升級動作為「無」代表新版檔案複製進去就生效，不需額外處理。

---

## v1

首個版本。

### 變更內容

**中立層 `.ark/`**

- `workflow.md`——三個文件區塊的定位、角色交棒、需求生命週期、影響層面判定、所有角色的共同規則
- `roles/`——orchestrator、navigator、architect、builder、librarian
- `templates/`——需求書、異動影響評估書、測試問題追蹤表，以及 `templates/docs/` 文件骨架
- `standards/`——內部套件規範的存放處與撰寫格式
- `tools/sync-adapters.sh`——檢查與補齊技能轉接層

**技能 `.ark/skills/`（18 個）**

| 角色 | 技能 |
| --- | --- |
| 總管 | `init-project` |
| Navigator | `new-requirement`、`update-requirement-info`、`write-requirement`、`generate-edge-cases`、`track-progress` |
| Architect | `write-impact-assessment`、`revise-spec`、`log-test-issue`、`track-test-issues` |
| Builder | `write-code`、`write-unit-test`、`code-review`、`check-acceptance`、`fix-vulnerabilities` |
| 跨角色 | `change-requirement-status` |
| Librarian | `sync-library`、`check-library-consistency` |

**轉接層**

- Copilot：`.github/agents/*.agent.md`（5 個角色）、`.github/skills/`（每個技能一份薄殼）
- Codex：`AGENTS.md`

**文件結構**

`requirements/`（流動）、`spec/`（現況規格）、`library/`（現況知識庫）三個區塊。

### 升級動作

無（首版）。
