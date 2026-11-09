#!/usr/bin/env bash
# Publish docs/wiki/{zh,en} to this repository's GitHub Wiki.
#
# GitHub Wiki pages live in a separate git repository (<repo>.wiki.git) and are
# flat markdown files plus one _Sidebar.md. This script maps:
#
#   docs/wiki/zh/Home.md          -> Home.md
#   docs/wiki/en/Home-EN.md       -> Home-EN.md
#   docs/wiki/{zh,en}/_Sidebar.md -> _Sidebar.md  (concatenated)
#
# The wiki repository only exists after the first page has been created in the
# GitHub web UI (Repository -> Wiki -> "Create the first page").
#
# Usage:
#   ./scripts/sync-wiki.sh --output ./out/wiki      # preview layout only
#   ./scripts/sync-wiki.sh                          # build and push
#   ./scripts/sync-wiki.sh --no-push                # commit locally, don't push
set -euo pipefail

WIKI_REPO="${WIKI_REPO:-git@github.com:YUAXI/HomeAssistant-PWM-Fan-Controlx4.wiki.git}"
MESSAGE="${MESSAGE:-docs: sync wiki from docs/wiki}"
OUTPUT_DIR=""
NO_PUSH=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT_DIR="${2:?--output needs a directory}"; shift 2 ;;
    --repo)   WIKI_REPO="${2:?--repo needs a URL}"; shift 2 ;;
    --message) MESSAGE="${2:?--message needs text}"; shift 2 ;;
    --no-push) NO_PUSH=1; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZH_DIR="$REPO_ROOT/docs/wiki/zh"
EN_DIR="$REPO_ROOT/docs/wiki/en"

[[ -d "$ZH_DIR" ]] || { echo "missing $ZH_DIR" >&2; exit 1; }
[[ -d "$EN_DIR" ]] || { echo "missing $EN_DIR" >&2; exit 1; }

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/wiki-sync-XXXXXX")"
STAGING="$WORK_DIR/layout"
mkdir -p "$STAGING"

echo "==> Collecting pages"
cp "$ZH_DIR"/*.md "$STAGING"/
rm -f "$STAGING/_Sidebar.md"
echo "    zh: $(find "$ZH_DIR" -maxdepth 1 -name '*.md' ! -name '_Sidebar.md' | wc -l) pages"

cp "$EN_DIR"/*.md "$STAGING"/
rm -f "$STAGING/_Sidebar.md"
echo "    en: $(find "$EN_DIR" -maxdepth 1 -name '*.md' ! -name '_Sidebar.md' | wc -l) pages"

# ------------------------------------------------------------------ pair check
for f in "$ZH_DIR"/*.md; do
  name="$(basename "$f" .md)"
  [[ "$name" == "_Sidebar" ]] && continue
  [[ -f "$EN_DIR/$name-EN.md" ]] || echo "    warning: missing English page en/$name-EN.md" >&2
done

echo "==> Building _Sidebar.md"
{
  cat "$ZH_DIR/_Sidebar.md"
  printf '\n---\n\n'
  cat "$EN_DIR/_Sidebar.md"
} > "$STAGING/_Sidebar.md"

if [[ -n "$OUTPUT_DIR" ]]; then
  mkdir -p "$OUTPUT_DIR"
  cp "$STAGING"/*.md "$OUTPUT_DIR"/
  echo "==> Layout written to $OUTPUT_DIR"
  ls -1 "$OUTPUT_DIR" | sed 's/^/    /'
  exit 0
fi

# ----------------------------------------------------------------- clone/push
echo "==> Preparing wiki checkout"
if ! git ls-remote "$WIKI_REPO" >/dev/null 2>&1; then
  cat >&2 <<EOF
Wiki repository is not reachable: $WIKI_REPO

If the error is "Repository not found", the wiki has not been initialised yet:
  1. open https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/wiki
  2. click "Create the first page" and save any placeholder
  3. re-run this script; it replaces the placeholder with docs/wiki/zh/Home.md
EOF
  exit 1
fi

git clone "$WIKI_REPO" "$WORK_DIR/wiki"
cd "$WORK_DIR/wiki"
git pull --rebase || true
find . -maxdepth 1 -name '*.md' -delete
cp "$STAGING"/*.md .
echo "    $(find . -maxdepth 1 -name '*.md' | wc -l) files copied"

git add -A
if git diff --cached --quiet; then
  echo "==> No changes to publish"
  exit 0
fi
git commit -m "$MESSAGE"
if [[ $NO_PUSH -eq 1 ]]; then
  echo "==> --no-push: commit created at $WORK_DIR/wiki"
  exit 0
fi
git push
echo "==> Wiki published"
