#!/usr/bin/env bash
# flowstate 스킬 원클릭 설치
#
#   curl -fsSL https://raw.githubusercontent.com/sang9390/flowstate/main/install.sh | bash
#
# 엔진(lemmalog)까지 함께 세팅하려면:
#   curl -fsSL https://raw.githubusercontent.com/sang9390/flowstate/main/install.sh | FLOWSTATE_WITH_ENGINE=1 bash
#
# 하는 일: 저장소를 임시 디렉터리에 받아 ~/.claude/skills/flowstate 로 복사.
# FLOWSTATE_WITH_ENGINE=1 이면 scripts/setup-lemmalog.sh 실행(rustup ~1.5GB + 빌드 + MCP 등록).

set -euo pipefail

REPO_URL="${FLOWSTATE_REPO:-https://github.com/sang9390/flowstate}"
DEST="$HOME/.claude/skills/flowstate"

log() { printf '[flowstate-install] %s\n' "$*"; }

command -v git >/dev/null 2>&1 || { log "git 필요 — 중단"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log "받는 중: $REPO_URL"
git clone --depth 1 --quiet "$REPO_URL" "$TMP/repo"

if [[ -d "$DEST" ]]; then
  log "기존 설치 발견 — 갱신"
  rm -rf "$DEST"
fi
mkdir -p "$HOME/.claude/skills"
cp -r "$TMP/repo/flowstate" "$DEST"
chmod +x "$DEST/scripts/"*.sh
log "설치 완료: $DEST (새 claude 세션부터 적용)"

if [[ "${FLOWSTATE_WITH_ENGINE:-0}" == "1" ]]; then
  log "엔진 세팅 시작 (lemmalog)..."
  "$DEST/scripts/setup-lemmalog.sh"
else
  log "엔진 없이 파일 모드로 동작. 엔진을 원하면: $DEST/scripts/setup-lemmalog.sh"
fi
