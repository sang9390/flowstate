# flowstate 스킬 원클릭 설치 (Windows PowerShell)
#
#   irm https://raw.githubusercontent.com/sang9390/flowstate/main/install.ps1 | iex
#
# 하는 일: 저장소를 임시 디렉터리에 받아 $env:USERPROFILE\.claude\skills\flowstate 로 복사.
# lemmalog 엔진 세팅 스크립트는 bash 전용 — Windows에서는 Git Bash 또는 WSL에서
# scripts/setup-lemmalog.sh 를 실행한다.

$ErrorActionPreference = 'Stop'

function Write-Log($msg) { Write-Host "[flowstate-install] $msg" }

$repoUrl = if ($env:FLOWSTATE_REPO) { $env:FLOWSTATE_REPO } else { 'https://github.com/sang9390/flowstate' }
$dest = Join-Path $env:USERPROFILE '.claude\skills\flowstate'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Log 'git 필요 — 중단'
    throw 'git not found'
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('flowstate-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    Write-Log "받는 중: $repoUrl"
    git clone --depth 1 --quiet $repoUrl (Join-Path $tmp 'repo')
    if ($LASTEXITCODE -ne 0) {
        Write-Log 'git clone 실패 — 중단'
        throw "git clone failed: $repoUrl"
    }

    if (Test-Path $dest) {
        Write-Log '기존 설치 발견 — 갱신'
        Remove-Item -Recurse -Force $dest
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item -Recurse (Join-Path $tmp 'repo\flowstate') $dest

    Write-Log "설치 완료: $dest (새 claude 세션부터 적용)"
    Write-Log '엔진(lemmalog)이 필요하면 Git Bash 또는 WSL에서: ~/.claude/skills/flowstate/scripts/setup-lemmalog.sh'
}
finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
