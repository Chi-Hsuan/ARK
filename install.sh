#!/usr/bin/env bash
#
# ARK 安裝指令
#
# 把 ARK 的 agent、skill 與中立層複製到目標專案。
# 複製完成後，在該專案叫用 Ark 總管執行導入，完成設定與文件骨架建立。
#
# 用法：
#   在目標專案資料夾執行
#     git clone --depth 1 <ARK repo URL> /tmp/ark && /tmp/ark/install.sh
#
#   或指定目標路徑
#     /tmp/ark/install.sh /path/to/project
#
#   選項
#     -y    不詢問直接執行（非互動環境必須加）

set -euo pipefail

ARK_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ASSUME_YES=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) TARGET="$arg" ;;
  esac
done
TARGET="${TARGET:-$PWD}"

err() { printf '\033[31m錯誤\033[0m %s\n' "$1" >&2; exit 1; }
info() { printf '  %s\n' "$1"; }

# --- 檢查 -------------------------------------------------------------------

[ -f "$ARK_SRC/.ark/VERSION" ] || err "來源不是完整的 ARK repo：$ARK_SRC"
[ -d "$TARGET" ] || err "目標資料夾不存在：$TARGET"

TARGET="$(cd "$TARGET" && pwd)"
[ "$ARK_SRC" != "$TARGET" ] && [ "${TARGET#"$ARK_SRC"/}" = "$TARGET" ] \
  || err "目標不能是 ARK repo 本身或其子目錄：$TARGET"

VERSION="$(tr -d '[:space:]' < "$ARK_SRC/.ark/VERSION")"

if [ -f "$TARGET/.ark/VERSION" ]; then
  OLD="$(tr -d '[:space:]' < "$TARGET/.ark/VERSION")"
  MODE="更新"
  printf '\nARK %s → %s\n' "$OLD" "$VERSION"
else
  MODE="安裝"
  printf '\nARK %s\n' "$VERSION"
fi

printf '目標專案：%s\n\n將%s下列項目：\n' "$TARGET" "$MODE"
info ".ark/                    流程、角色、技能、範本、套件規範、工具"
info ".github/agents/Ark*      Copilot 角色"
info ".github/skills/          Copilot 技能"
info "AGENTS.md                Codex 入口"
printf '\n不會動到：專案既有的文件、其他 agent 檔、.ark/config.yml\n\n'

if [ "$ASSUME_YES" -eq 0 ]; then
  [ -t 0 ] || err "非互動環境請加上 -y"
  printf '繼續？[y/N] '
  read -r reply
  case "$reply" in [yY]*) ;; *) echo "已取消"; exit 0 ;; esac
fi

# --- 複製 -------------------------------------------------------------------

printf '\n'

# .ark/ ——中立層，除了 config.yml 之外全部覆寫
mkdir -p "$TARGET/.ark"
for item in VERSION CHANGELOG.md workflow.md roles skills templates standards tools; do
  [ -e "$ARK_SRC/.ark/$item" ] || continue
  rm -rf "$TARGET/.ark/${item:?}"
  cp -R "$ARK_SRC/.ark/$item" "$TARGET/.ark/"
done
info "已寫入 .ark/"

if [ -f "$TARGET/.ark/config.yml" ]; then
  info "保留既有 .ark/config.yml"
else
  info "未建立 .ark/config.yml（稍後由 Ark 總管依你的回答產生）"
fi

# Copilot 轉接層——只動 ARK 自己的檔案
mkdir -p "$TARGET/.github/agents"
find "$ARK_SRC/.github/agents" -maxdepth 1 -name 'Ark*.agent.md' -exec cp {} "$TARGET/.github/agents/" \;
info "已寫入 .github/agents/"

mkdir -p "$TARGET/.github/skills"
for skill in "$ARK_SRC/.github/skills"/*/; do
  [ -d "$skill" ] || continue
  name="$(basename "$skill")"
  rm -rf "${TARGET:?}/.github/skills/$name"
  cp -R "${skill%/}" "$TARGET/.github/skills/"
done
info "已寫入 .github/skills/"

# Codex 轉接層——專案已有自己的 AGENTS.md 時不覆寫
if [ -f "$TARGET/AGENTS.md" ] && ! head -5 "$TARGET/AGENTS.md" | grep -q '^# ARK$'; then
  cp "$ARK_SRC/AGENTS.md" "$TARGET/AGENTS.ark.md"
  info "偵測到既有 AGENTS.md，ARK 的版本另存為 AGENTS.ark.md"
  NEEDS_MERGE=1
else
  cp "$ARK_SRC/AGENTS.md" "$TARGET/AGENTS.md"
  info "已寫入 AGENTS.md"
  NEEDS_MERGE=0
fi

# --- 後續 -------------------------------------------------------------------

printf '\n\033[32m%s完成\033[0m\n\n接下來：\n' "$MODE"
echo "  1. 用 VS Code 開啟 $TARGET"
echo "  2. Reload Window（Copilot 才會載入 ARK 的 agent）"
echo "  3. 叫用 Ark 總管，選擇「導入 / 升級 ARK」完成設定"
echo "  4. 確認無誤後把 .ark/、.github/、AGENTS.md 與文件資料夾提交進版控"

if [ "${NEEDS_MERGE:-0}" -eq 1 ]; then
  printf '\n\033[33m注意\033[0m 這個專案原本就有 AGENTS.md。\n'
  echo "     Codex 只讀 AGENTS.md，請把 AGENTS.ark.md 的內容併入後刪除該檔，"
  echo "     否則 Codex 那側不會知道這是 ARK 專案。"
fi

printf '\n'
