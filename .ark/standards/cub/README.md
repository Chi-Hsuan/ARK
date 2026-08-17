# cub-cloud 套件規範

資訊雲專案使用的 Java 套件（`cub-cloud-*`）規範。

## 文件清單

一個套件一份文件，檔名為 `cub-cloud-{領域}.md`。目前規劃中：

- `cub-cloud-db.md`
- `cub-cloud-redis.md`
- `cub-cloud-oss.md`
- `cub-cloud-security.md`
- `cub-cloud-encrypt.md`

文件陸續補齊中，**尚未到齊不影響使用**——技能只會載入實際存在的檔案。

## 專案指定方式

不是每個專案都會用到全部。在 `.ark/config.yml` 指定：

```yaml
standards:
  cub: [cub-cloud-db, cub-cloud-redis]
```

未指定時，`write-code` 會列出本資料夾實際存在的文件讓使用者複選，並寫回 config。

## 撰寫格式

見 [../README.md](../README.md)。frontmatter 為選填，新增文件時建議帶上 `packages` 與 `keywords`，讓技能能精準判斷本次是否用得到。
