#!/usr/bin/env bash
#
# 檢查並補齊技能轉接層
#
# `.ark/skills/` 是中立層，每個技能都需要對應的轉接層才能被工具載入：
#   - Copilot：`.github/skills/{技能}/SKILL.md`
#   - Codex：`AGENTS.md` 的技能表列出該檔案路徑
#
# 新增技能後忘記補轉接層，會造成兩個工具行為不一致。本工具負責偵測與補齊。
#
# 用法：
#   .ark/tools/sync-adapters.sh            只檢查，回報缺什麼（有缺漏時 exit 1）
#   .ark/tools/sync-adapters.sh --write    補上缺少的 Copilot 轉接層

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/.ark/skills"
DST="$ROOT/.github/skills"
AGENTS="$ROOT/AGENTS.md"

WRITE=0
[ "${1:-}" = "--write" ] && WRITE=1

[ -d "$SRC" ] || { echo "找不到 $SRC" >&2; exit 1; }

green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red() { printf '\033[31m%s\033[0m\n' "$1"; }

missing_copilot=()
missing_agents=()
orphans=()

for dir in "$SRC"/*/; do
  [ -f "${dir}SKILL.md" ] || continue
  name="$(basename "$dir")"
  [ -f "$DST/$name/SKILL.md" ] || missing_copilot+=("$name")
  if [ -f "$AGENTS" ] && ! grep -q "\.ark/skills/$name/SKILL\.md" "$AGENTS"; then
    missing_agents+=("$name")
  fi
done

if [ -d "$DST" ]; then
  for dir in "$DST"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    [ -d "$SRC/$name" ] || orphans+=("$name")
  done
fi

printf '\n中立層技能：%s 個\n\n' "$(find "$SRC" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"

# --- Copilot 轉接層 ---------------------------------------------------------

if [ ${#missing_copilot[@]} -eq 0 ]; then
  green "✓ Copilot 轉接層齊全"
else
  if [ "$WRITE" -eq 1 ]; then
    for name in "${missing_copilot[@]}"; do
      skill="$SRC/$name/SKILL.md"
      sname="$(sed -n 's/^name: *//p' "$skill" | head -1)"
      desc="$(sed -n 's/^description: *//p' "$skill" | head -1)"
      title="$(awk '/^---$/{c++; next} c>=2 && /^# /{sub(/^# /,""); print; exit}' "$skill")"
      mkdir -p "$DST/$name"
      cat > "$DST/$name/SKILL.md" <<EOF
---
name: ${sname:-$name}
description: $desc
---

# ${title:-$name}

本技能的實際步驟定義在 \`.ark/skills/$name/SKILL.md\`。

請讀取該檔案並完全依其步驟執行。若該檔案不存在，代表此專案尚未導入 ARK，請告知使用者並停止。
EOF
      green "＋ 已建立 .github/skills/$name/SKILL.md"
    done
  else
    red "✗ Copilot 缺少 ${#missing_copilot[@]} 個轉接層："
    printf '    %s\n' "${missing_copilot[@]}"
    echo "    補齊：.ark/tools/sync-adapters.sh --write"
  fi
fi

# --- AGENTS.md --------------------------------------------------------------

echo
if [ ${#missing_agents[@]} -eq 0 ]; then
  green "✓ AGENTS.md 技能表齊全"
else
  red "✗ AGENTS.md 技能表缺少 ${#missing_agents[@]} 項："
  printf '    %s\n' "${missing_agents[@]}"
  echo "    這份表格有角色分組，請手動加入正確的分組位置"
fi

# --- 孤兒轉接層 -------------------------------------------------------------

if [ ${#orphans[@]} -gt 0 ]; then
  echo
  yellow "⚠ 有 ${#orphans[@]} 個轉接層在中立層找不到對應技能："
  printf '    %s\n' "${orphans[@]}"
  echo "    技能可能已改名或移除。請確認後手動刪除，本工具不會自動刪檔。"
fi

echo
if [ ${#missing_agents[@]} -gt 0 ] || { [ ${#missing_copilot[@]} -gt 0 ] && [ "$WRITE" -eq 0 ]; }; then
  exit 1
fi
