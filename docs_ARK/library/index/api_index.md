# API Index

## 文件目的

本文件用於：

1. 接收自然語言需求
2. 快速定位相關功能
3. 快速找出相關 API
4. 快速找出 Service 入口
5. 快速定位 Spec 文件

不提供詳細規格內容。

詳細內容請至對應 Spec 查看。

---

## API 清單

| 功能分類 | 關鍵字 | 使用場景 | API | Service | Service目的 | Spec |
|----------|----------|----------|----------|----------|--------|--------|
| TBA | TBA | TBA | TBA | TBA | TBA | TBA |

---

## 使用規則

### 查詢方式

優先使用：

- 關鍵字
- 使用場景

進行搜尋。

### 查詢流程

1. 從需求描述擷取關鍵字與使用場景
2. 依關鍵字與使用場景查詢本文件
3. 取得可能相關的 API 與 Service
4. 進入 Function Index 分析共用邏輯影響
5. 依需要進一步查看 Spec 文件

---

## 維護原則

新增 API 時必須補充：

- 功能分類
- 關鍵字
- 使用場景
- API
- Service
- Service目的
- Spec位置

若僅修改規格內容：

無需修改本文件。

若新增業務場景：

必須更新使用場景欄位。

---

## AI 使用指引

閱讀需求後：

Step1:
先依關鍵字與使用場景查詢 API Index。

Step2:
取得相關 API 與 Service。

Step3:
至 Function Index 查詢相關 Function。

Step4:
若涉及外部系統，再查詢 Downstream API Index。

Step5:
輸出：

- 可能影響功能
- 可能影響 API
- 可能影響 Service
- 建議查看 Spec
- 建議進一步分析 Function