# flowstate

[English](README.md) | **한국어**

Claude Code용 상태관리 + 지시 파이프라인 스킬.

모든 작업 지시를 7단계 파이프라인(정규화 → spec → 해소 → 계획 → 실행 → 기록 → handoff)으로 처리하고, 프로젝트에서 알게 된 사실과 결정을 `.flowstate/facts.md`에 한 줄 한 사실 형식으로 기록합니다. 반증된 사실은 삭제하지 않고 철회(RETIRED) 처리하며, "아까 그 함수" 같은 축약 지시는 기록과 코드 구조 분석으로 해소합니다.

[Lemmalog](https://github.com/JordyZomer/lemmalog) (Datalog 기반 LLM 메모리 엔진)의 설계를 차용했으며, 엔진이 설치되어 있으면 자동으로 위임합니다(증분 무효화, 증명 트리, 충돌 감지). 없으면 파일 모드로 동작합니다.

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/sang9390/flowstate/main/install.sh | bash
```

lemmalog 엔진까지 함께(선택 — rustup ~1.5GB + 빌드 수 분):

```bash
curl -fsSL https://raw.githubusercontent.com/sang9390/flowstate/main/install.sh | FLOWSTATE_WITH_ENGINE=1 bash
```

설치 후 새 `claude` 세션부터 자동 적용됩니다. `/flowstate`로 직접 호출도 가능합니다.

## 구조

```
flowstate/
├── SKILL.md                      # 7단계 파이프라인 본체
├── references/
│   ├── fact-protocol.md          # 사실 기록 형식·철회 규칙
│   └── handoff-template.md       # 세션 인수인계 양식
└── scripts/
    └── setup-lemmalog.sh         # 엔진 원클릭 세팅 (멱등)
```

## 파일 모드 vs 엔진 모드

| | 파일 모드 (기본) | 엔진 모드 (lemmalog) |
|---|---|---|
| 요구사항 | 없음 | Rust 툴체인 (스크립트가 자동 설치) |
| 사실 저장 | `.flowstate/facts.md` | facts.md + `.flowstate/lemmalog.snapshot` (프로젝트별 분리) |
| 추가 기능 | — | 자동 충돌 감지, 증명 트리(why), 대규모 사실 µs 쿼리 |

벤치마크(7개 시나리오 + 12세션 대형 시나리오, LLM 채점) 기준: 스킬 없는 기본 Claude Code 62/70 대비 flowstate 70/70. 파일/엔진 모드는 12세션 규모까지 동점 — 일상 사용은 파일 모드로 충분하고, 사실 수천 건 이상의 장기·대규모 프로젝트에서 엔진이 유효합니다.

## 동작 요약

- **모든 지시가 동일 파이프라인 통과** — 명확한 지시는 통과 비용 ~0, 모호하면 해소 단계만 깊게 동작 (fact 기록 조회 → 파일시스템·코드 구조 분석 → 그래도 안 되면 질문)
- **적응형 게이트** — 파괴적·비가역 작업, 범위 확장 시에만 정지·확인
- **철회 규율** — 결정 변경 시 이전 사실을 RETIRED로 이동(사유·시각 기록), 파생 사실 연쇄 철회, 전제(premised_on) 추적
- **환경변수** — `FLOWSTATE_NO_SETUP=1`: 엔진 자동 세팅 건너뜀

## 라이선스

MIT. Lemmalog 역시 MIT (JordyZomer/lemmalog).
