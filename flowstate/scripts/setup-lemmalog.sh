#!/usr/bin/env bash
# flowstate — lemmalog 엔진 원클릭 세팅 (멱등)
#
# 이미 세팅되어 있으면 즉시 종료(오버헤드 ~0). 최초 1회만:
#   rustup(~1.5GB) → lemmalog clone → cargo build → claude/kimi MCP 등록
# 스냅샷은 상대 경로(.flowstate/lemmalog.snapshot)로 등록되어 프로젝트별로 분리 저장된다.

set -euo pipefail

REPO_DIR="${LEMMALOG_DIR:-$HOME/.local/share/lemmalog}"
BIN="$REPO_DIR/target/release/lemmalog-mcp"
SNAP_REL=".flowstate/lemmalog.snapshot"
REPO_URL="https://github.com/JordyZomer/lemmalog"

log() { printf '[lemmalog-setup] %s\n' "$*"; }

# CLI 감지: claude / kimi — 존재하는 모든 CLI에 등록한다
HAVE_CLAUDE=0; HAVE_KIMI=0
if command -v claude >/dev/null 2>&1; then HAVE_CLAUDE=1; fi
if command -v kimi >/dev/null 2>&1; then HAVE_KIMI=1; fi
[[ $HAVE_CLAUDE -eq 1 || $HAVE_KIMI -eq 1 ]] || { log "claude/kimi CLI 없음 — 중단"; exit 1; }

# 존재하는 모든 CLI에 lemmalog가 등록돼 있으면 0 (kimi는 get 서브커맨드가 없어 list로 확인)
registered_everywhere() {
  if [[ $HAVE_CLAUDE -eq 1 ]] && ! claude mcp get lemmalog >/dev/null 2>&1; then return 1; fi
  if [[ $HAVE_KIMI -eq 1 ]] && ! kimi mcp list 2>/dev/null | grep -q lemmalog; then return 1; fi
  return 0
}

# fast path: 바이너리 존재 + MCP 등록 완료면 통과
if [[ -x "$BIN" ]] && registered_everywhere; then
  log "이미 세팅됨 — $BIN"
  exit 0
fi

command -v git >/dev/null 2>&1 || { log "git 없음 — 중단"; exit 1; }

# [1/4] Rust 툴체인
if ! command -v cargo >/dev/null 2>&1; then
  if [[ -x "$HOME/.cargo/bin/cargo" ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
  else
    log "[1/4] rustup 설치 중 (~1.5GB, 최초 1회)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
fi
log "[1/4] cargo 준비됨: $(cargo --version)"

# [2/4] 소스
if [[ -d "$REPO_DIR/.git" ]]; then
  git -C "$REPO_DIR" pull --ff-only || log "pull 실패 — 기존 체크아웃으로 진행"
else
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi
log "[2/4] 소스 준비됨: $REPO_DIR"

# [3/4] 빌드
log "[3/4] 빌드 중 (수 분 소요)..."
cargo build --release --features mcp --manifest-path "$REPO_DIR/Cargo.toml"
[[ -x "$BIN" ]] || { log "빌드 산출물 없음: $BIN — 중단"; exit 1; }
log "[3/4] 빌드 완료: $BIN"

# [4/4] MCP 등록 — 존재하는 CLI 전부 (스냅샷은 프로젝트별 상대 경로)
REGISTERED_ON=""
if [[ $HAVE_CLAUDE -eq 1 ]]; then
  # user scope — 모든 프로젝트 적용
  claude mcp remove --scope user lemmalog >/dev/null 2>&1 || true
  claude mcp add --scope user lemmalog --env "LEMMALOG_MCP_PATH=$SNAP_REL" -- "$BIN"
  REGISTERED_ON+="claude "
fi
if [[ $HAVE_KIMI -eq 1 ]]; then
  # kimi는 scope 옵션 없음 — 전역 ~/.kimi/mcp.json 단일
  kimi mcp remove lemmalog >/dev/null 2>&1 || true
  kimi mcp add -e "LEMMALOG_MCP_PATH=$SNAP_REL" lemmalog "$BIN"
  REGISTERED_ON+="kimi "
fi
log "[4/4] MCP 등록 완료: ${REGISTERED_ON% }(스냅샷: 각 프로젝트의 $SNAP_REL)"
log "등록은 새 세션부터 적용됨."
