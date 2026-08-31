# fact-protocol — .flowstate/facts.md 형식과 규칙

Lemmalog 라인 프로토콜 호환. `#` 이후 주석을 제거하면 그대로 `lemmalog_observe`에 넣을 수 있는 형식을 유지한다.

## 파일 골격

```markdown
# flowstate facts
<!-- 한 줄 = 한 사실. 형식은 fact-protocol.md 참조. 직접 편집 시 형식 유지. -->

## ACTIVE

## RETIRED
```

## 사실 한 줄 형식

```
"주어" --관계[confidence]--> "목적어"  # @asserted=<ISO8601> @src=<출처> [@tags=...] [@to=<ISO8601> @reason=<이유>]
```

예:

```
"src/utils.py:add" --had_bug[0.9]--> "뺄셈 오타"  # @asserted=2026-08-31T12:00Z @src=obs:src/utils.py
"user" --decided[1.0]--> "이미지는 확장자별 폴더로 정리"  # @asserted=2026-08-31T12:05Z @src=user
```

## 필드 규칙

- **주어/목적어**: 항상 따옴표. 파일 내 심볼은 `"경로:심볼"` 형식. 대명사("그거", "아까")를 주어로 쓰지 않는다 — 반드시 실체로 해소 후 기록.
- **관계**: snake_case 동사. 자주 쓰는 것: `is`, `located_at`, `had_bug`, `fixed_by`, `decided`, `depends_on`, `contains`, `means`(축약어 → 실체 매핑).
- **confidence**: 생략 시 1.0.
  - `1.0` 사용자가 직접 말한 사실/결정
  - `0.9` 파일/코드에서 직접 관찰
  - `0.7` 추론 (반드시 `@src=derived:<근거 사실의 주어--관계>` 명시)
- **@src**: `user` | `obs:<파일경로>` | `derived:<근거>`. 근거 없는 사실은 기록 금지.
- **@tags**: 선택. 검색용 (예: `@tags=bug,decision`).

## 철회 (Retraction) 규칙

1. 반증되거나 취소된 사실은 **삭제하지 않는다.** ACTIVE에서 RETIRED 섹션으로 줄을 이동한다.
2. 이동 시 `@to=<철회 시각>` `@reason=<한 줄 이유>`를 주석에 추가한다.
3. **연쇄 철회**: `@src=derived:X`인 사실은 X가 철회되고 다른 근거가 없으면 함께 철회한다. 근거가 여러 개면 모든 근거가 철회됐을 때만 철회한다.
4. 같은 주어--관계에 새 값이 오면: 이전 사실 철회(@reason=superseded) 후 새 사실을 ACTIVE에 추가. 덮어쓰기 금지.

## 조회 규칙

- 조회는 항상 ACTIVE 섹션만 대상으로 한다. RETIRED는 이력 확인용.
- 축약 지시 해소 시: `means` 관계 우선 검색, 없으면 최근 `@asserted` 역순.

## lemmalog MCP 연동 (사용 가능할 때만)

- 신규 사실: 주석 제거한 라인을 `lemmalog_observe`로 전달.
- 조회: `lemmalog_query` / 심화는 `lemmalog_query_deep`, 근거 확인은 `lemmalog_why`.
- 엔진 결과와 파일이 불일치하면 파일이 진실의 원천 — 파일 기준으로 재동기화.
