#!/usr/bin/env bash
# flowstate — lemmalog 엔진 원클릭 세팅 (멱등)
#
# 이미 세팅되어 있으면 즉시 종료(오버헤드 ~0). 최초 1회만:
#   rustup(~1.5GB) → lemmalog clone → cargo build → claude MCP 등록(user scope)
# 스냅샷은 상대 경로(.flowstate/lemmalog.snapshot)로 등록되어 프로젝트별로 분리 저장된다.

set -euo pipefail

REPO_DIR="${LEMMALOG_DIR:-$HOME/.local/share/lemmalog}"
BIN="$REPO_DIR/target/release/lemmalog-mcp"
SNAP_REL=".flowstate/lemmalog.snapshot"
REPO_URL="https://github.com/JordyZomer/lemmalog"

log() { printf '[lemmalog-setup] %s\n' "$*"; }

# fast path: 바이너리 존재 + MCP 등록 완료면 통과
if [[ -x "$BIN" ]] && claude mcp get lemmalog >/dev/null 2>&1; then
  log "이미 세팅됨 — $BIN"
  exit 0
fi

command -v claude >/dev/null 2>&1 || { log "claude CLI 없음 — 중단"; exit 1; }
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

# [4/4] MCP 등록 (user scope — 모든 프로젝트 적용, 스냅샷은 프로젝트별 상대 경로)
claude mcp remove --scope user lemmalog >/dev/null 2>&1 || true
claude mcp add --scope user lemmalog --env "LEMMALOG_MCP_PATH=$SNAP_REL" -- "$BIN"
log "[4/4] MCP 등록 완료 (스냅샷: 각 프로젝트의 $SNAP_REL)"
log "등록은 새 세션부터 적용됨. 확인: claude mcp list"
