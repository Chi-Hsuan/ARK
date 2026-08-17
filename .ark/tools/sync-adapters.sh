#!/usr/bin/env bash
#
# 檢查並補齊技能轉接層
#
# `.ark/skills/` 是中立層，每個技能都需要對應的轉接層才能被工具載入：
#   - Copilot：`.github/skills/{技能}/SKILL.md`
#   - Claude Code：`.claude/skills/{技能}/SKILL.md`
#   - Codex：`AGENTS.md` 的技能表列出該檔案路徑
#
# 新增技能後忘記補轉接層，會造成各工具行為不一致。本工具負責偵測與補齊。
#
# 用法：
#   .ark/tools/sync-adapters.sh            只檢查，回報缺什麼（有缺漏時 exit 1）
#   .ark/tools/sync-adapters.sh --write    補上缺少的 Copilot 與 Claude Code 轉接層

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/.ark/skills"
AGENTS="$ROOT/AGENTS.md"
TARGETS=(".github/skills:Copilot" ".claude/skills:Claude Code")

WRITE=0
[ "${1:-}" = "--write" ] && WRITE=1

[ -d "$SRC" ] || { echo "找不到 $SRC" >&2; exit 1; }

green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red() { printf '\033[31m%s\033[0m\n' "$1"; }

write_adapter() {
  local skill_dir="$1" name="$2" out="$3"
  local sname desc title
  sname="$(sed -n 's/^name: *//p' "$skill_dir/SKILL.md" | head -1)"
  desc="$(sed -n 's/^description: *//p' "$skill_dir/SKILL.md" | head -1)"
  title="$(awk '/^---$/{c++; next} c>=2 && /^# /{sub(/^# /,""); print; exit}' "$skill_dir/SKILL.md")"
  mkdir -p "$(dirname "$out")"
  cat > "$out" <<EOF
---
name: ${sname:-$name}
description: $desc
---

# ${title:-$name}

本技能的實際步驟定義在 \`.ark/skills/$name/SKILL.md\`。

請讀取該檔案並完全依其步驟執行。若該檔案不存在，代表此專案尚未導入 ARK，請告知使用者並停止。
EOF
}

TOTAL="$(find "$SRC" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
printf '\n中立層技能：%s 個\n' "$TOTAL"

FAIL=0

# --- 各工具的技能轉接層 -----------------------------------------------------

for entry in "${TARGETS[@]}"; do
  dir="${entry%%:*}"; label="${entry##*:}"
  dst="$ROOT/$dir"
  missing=(); orphans=()

  for skill in "$SRC"/*/; do
    [ -f "${skill}SKILL.md" ] || continue
    name="$(basename "$skill")"
    [ -f "$dst/$name/SKILL.md" ] || missing+=("$name")
  done

  if [ -d "$dst" ]; then
    for d in "$dst"/*/; do
      [ -d "$d" ] || continue
      name="$(basename "$d")"
      [ -d "$SRC/$name" ] || orphans+=("$name")
    done
  fi

  echo
  if [ ${#missing[@]} -eq 0 ]; then
    green "✓ $label 轉接層齊全（${dir}）"
  elif [ "$WRITE" -eq 1 ]; then
    for name in "${missing[@]}"; do
      write_adapter "$SRC/$name" "$name" "$dst/$name/SKILL.md"
      green "＋ 已建立 $dir/$name/SKILL.md"
    done
  else
    red "✗ $label 缺少 ${#missing[@]} 個轉接層（${dir}）："
    printf '    %s\n' "${missing[@]}"
    echo "    補齊：.ark/tools/sync-adapters.sh --write"
    FAIL=1
  fi

  if [ ${#orphans[@]} -gt 0 ]; then
    yellow "⚠ $dir 有 ${#orphans[@]} 個轉接層在中立層找不到對應技能："
    printf '    %s\n' "${orphans[@]}"
    echo "    技能可能已改名或移除。請確認後手動刪除，本工具不會自動刪檔。"
  fi
done

# --- 角色轉接層 -------------------------------------------------------------

echo
ROLE_COUNT="$(find "$ROOT/.ark/roles" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
COPILOT_AGENTS="$(find "$ROOT/.github/agents" -maxdepth 1 -name 'Ark*.agent.md' 2>/dev/null | wc -l | tr -d ' ')"
CLAUDE_AGENTS="$(find "$ROOT/.claude/agents" -maxdepth 1 -name 'ark-*.md' 2>/dev/null | wc -l | tr -d ' ')"

if [ "$COPILOT_AGENTS" = "$ROLE_COUNT" ] && [ "$CLAUDE_AGENTS" = "$ROLE_COUNT" ]; then
  green "✓ 角色轉接層齊全（角色 ${ROLE_COUNT}／Copilot ${COPILOT_AGENTS}／Claude Code ${CLAUDE_AGENTS}）"
else
  red "✗ 角色轉接層數量不符：角色 ${ROLE_COUNT}／Copilot ${COPILOT_AGENTS}／Claude Code $CLAUDE_AGENTS"
  echo "    角色檔需手動建立對應的轉接層，本工具不自動產生"
  FAIL=1
fi

# --- AGENTS.md --------------------------------------------------------------

echo
missing_agents=()
for skill in "$SRC"/*/; do
  name="$(basename "$skill")"
  grep -q "\.ark/skills/$name/SKILL\.md" "$AGENTS" || missing_agents+=("$name")
done

if [ ${#missing_agents[@]} -eq 0 ]; then
  green "✓ AGENTS.md 技能表齊全"
else
  red "✗ AGENTS.md 技能表缺少 ${#missing_agents[@]} 項："
  printf '    %s\n' "${missing_agents[@]}"
  echo "    這份表格有角色分組，請手動加入正確的分組位置"
  FAIL=1
fi

echo
exit "$FAIL"
