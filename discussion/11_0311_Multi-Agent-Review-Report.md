# 통합 멀티에이전트 리뷰 리포트
## "Bowling Alone, Scrolling Together" — NVSQ 투고 전 종합 평가

**작성일**: 2026-03-11
**평가 도구**: Diverga Multi-Agent Review (F1, A3 ×2, G5 ×2, Figures)
**평가 대상**: 전체 원고 (00_abstract ~ 05_discussion), 분석 코드 (00~04), Figures 12개

---

## Executive Summary

| 에이전트 | 영역 | 종합 판정 | 핵심 메시지 |
|---------|------|----------|-----------|
| **F1** (Internal Consistency) | 데이터·논리 정합성 | **95%+ 일관** | 4개 미세 불일치 (minor) |
| **Figures** (Figure Quality) | 시각 자료 품질 | **수정 필요** | 변수명 라벨링 + 4개 본문 추천 선정 |
| **A3** (Devil's Advocate) ×2 | 이론·방법·인과 취약점 | **11개 비평 도메인** | Survey design 오류, APC 문제, 인과 언어, 제도적 정렬 confound |
| **G5** (Academic Style) ×2 | AI 패턴·문체 | **AI 확률 52-62% (MEDIUM)** | 타겟 편집으로 해결 가능 |

---

## I. CRITICAL — 즉시 수정 필수

### 1. Survey Design Specification 오류 (A3-C8, NEW)

**현재 코드** (`02_logistic_regression.R`, line 33):
```r
svy <- svydesign(ids = ~1, weights = ~VLSUPPWT, data = data)
```

**문제**: CPS는 multi-stage clustered design. `ids = ~1`은 클러스터링과 층화를 완전히 무시하여 표준오차를 과소추정. p=.049 (employment interaction)는 올바른 design에서 비유의적일 가능성 높음.

**수정**:
```r
svy <- svydesign(ids = ~HRHHID, strata = ~GESTFIPS,
                  weights = ~VLSUPPWT, nest = TRUE, data = data)
```

**영향**: 5개 모델 전체 재실행 필요. p-value 전체 변동 가능.

### 2. APC 식별 문제 (A3-C2, Priority #1)

Gen Z는 데이터에서 18-26세. Gen Z plateau가 세대 효과인지 연령 효과인지 구분 불가.

**대응**:
- 21-30세 고정 연령대 비교 (2017 = Millennial, 2023 = Gen Z)
- age² 또는 age spline 추가 후 세대 효과 재검증
- **Reviewer likelihood**: Very High

### 3. 인과 언어 감사 (A3-C1, Priority #2)

"Structural consequence," "structural barrier," "disrupts," "produces" 등 인과적 함의가 있는 표현이 cross-sectional 데이터와 불일치.

**대응**: "structural consequence" → "structural correlate/association"으로 체계적 교체. 역인과를 Discussion 본문에서 진지하게 다룰 것.

### 4. 제도적 정렬 confound (A3, Priority #3)

조직 회원 수(membership)가 사교와 봉사를 모두 매개하는 공통 원인일 가능성. **기존 데이터로 테스트 가능.**

**대응**: 로지스틱 회귀에 membership을 직접 통제변수로 추가. First Step Effect 생존 여부 확인.

### 5. First Step Effect = 단순 오목성(concavity)? (A3-C3, Priority #4)

어떤 오목 함수에서든 첫 구간 AME가 가장 큼 — 수학적 필연.

**대응**: log-linear 연속 모델 적합 → 범주형 모델의 0→1 전환이 smooth curve 예측치를 초과하는지 비교.

---

## II. HIGH — 투고 전 수정 권장

### 6. AI 문체 패턴 완화 (G5)

**AI 확률**: 52-62% (MEDIUM) — Results 62%, Discussion 58%

**7개 Flagged Passages**:

| # | 위치 | 현재 | 수정안 |
|---|------|------|--------|
| 1 | Introduction 기여 단락 | "First, it extends... Second, it identifies... Third, it reveals..." | 삼분 열거 해체, 가장 반직관적 기여로 시작 |
| 2 | Results 마지막 종합 단락 | "Across the three analytic stages, a coherent and mutually reinforcing..." | **전체 삭제** → Discussion 서두로 이동 |
| 3 | Discussion 첫 문장 | "This study examined the association..." | 실질적 발견으로 시작: "Three independent analytic approaches arrived at the same answer..." |
| 4 | Discussion 결론 | "In conclusion, the loneliness epidemic..." | "In conclusion" 삭제 |
| 5 | Limitations 서두 | "Several limitations should be noted." | "This study has several limitations." 또는 통합 |
| 6 | Model 5 해석 | "This null result is among the most consequential..." | 경험적 주장 선행: "Model 5's non-significant interaction tells a clear story..." |
| 7 | Theoretical Framework | Generic examples in digital compensation | Boulianne (2020) 등 구체적 실증 근거로 앵커링 |

**어휘 다양성 수정**:

| 표현 | 빈도 | 조치 |
|------|------|------|
| "consistent with" | 11회 | 6회 이상 교체 → "corroborates," "as predicted by," 직접 주장 |
| "notable/notably" | 9회 | 3-4회로 축소, 정량적 표현으로 대체 |
| "striking/strikingly" | 5회 | 2회로 축소 |
| "This [finding/result]" 문두 | 11회 | 4-5회 변형 |
| "converge/convergent" | 4회 | 2회로 축소 |

### 7. 이론적 공백 (A3-C1A)

- **Lim (2008, ASR)**: identity-based recruitment appeals — NVSQ 독자 핵심 참고문헌
- **Beyerlein & Hipp (2006)**: organizational embedding of social ties — Gen Z plateau 설명
- **Cnaan & Handy (2005)**: episodic volunteering — binary DV의 한계

### 8. Narrative Cherry-Picking (A3-C7)

세 가지 반증이 Discussion에 미통합:
- Gen Z 높은 baseline (27.3%): service-learning/대학 지원서 봉사 의무 대안 설명
- Profile 3 (Socially Active Non-Donors): 사교 최고인데 봉사율 14.6% → 핵심 메커니즘 반증
- Activist Boycotter 이동: Gen Z 5.9% → 10.7% post-COVID → Dalton "engaged citizenship" 지지

### 9. "Loneliness Epidemic" 프레이밍 ≠ 측정 구인

CPS는 loneliness(외로움)를 측정하지 않음. CESOCIALIZE는 사교 빈도만 측정. → "social disconnection" 또는 "socialization decline"으로 교체 권장.

---

## III. MEDIUM — 투고 후 R&R 대응 가능

### 10. LPA 방법론 보완 (A3-C4)

- EII 외 다른 parameterization BIC 비교 미보고
- Gaussian mixture on z-scored binary variables → 분포 가정 위반
- Survey weight 미적용 → 프로파일 분포의 국가 대표성 한계
- **대응**: LCA (poLCA) 민감도 분석 추가

### 11. GBM "Validation" 표현 (A3-C5)

같은 데이터·같은 변수의 재분석은 validation이 아님.
- **대응**: "validation" → "complementary analysis" 또는 "triangulation"

### 12. Statistical Significance at N=201K (A3-C6)

- p=.049 (employment)는 Bonferroni 보정 후 비유의적 (adjusted α = .0125)
- 비유의적 결과에 대한 equivalence testing (TOST) 미실시
- **대응**: AME + CI를 primary metric으로, p-value는 보조적 보고

### 13. Results 45% vs Discussion 12% 비율

NVSQ 규범상 Discussion이 더 깊어야 함.
- **대응**: Profile descriptions, SHAP 상세를 supplementary로 이동, Discussion 15-18%로 확대

### 14. Survey Weight in LPA (A3-C2D)

LPA에 survey weight 미적용 → 프로파일 분포의 대표성 한계
- **대응**: 명시적 limitation 인정 또는 weighted descriptive statistics 보고

### 15. Robustness Checks 부재 (A3-C9)

`05_robustness_checks.R`은 다른 연구의 잔존 코드. 현재 연구 전용 robustness checks 미실행.
- **대응**: 연속형 socialization, 연령 제한 하위표본, wave별 회귀, 대안 세대 경계, survey design 민감도

---

## IV. Figure 수정 사항

| Figure | 상태 | 본문 추천 | 수정 사항 |
|--------|------|----------|----------|
| `pred_prob_soc_gen.png` | **Figure 1** | Yes | soc_factor → human-readable 라벨 |
| `ame_first_step.png` | **Figure 2** | Yes | 세대 라벨 확인, y축 단위 명확화 |
| `lpa_generation_distribution.png` | **Figure 3** | Yes | Profile 번호 → 서술 라벨 |
| `shap_genz_vs_boomer.png` | **Figure 4** | Yes | 변수 코드명 → readable 라벨 |
| `shap_dep_socialization_age.png` | 문제 | No | x축 인코딩 이상 — 재생성 필요 |
| 나머지 7개 | Supplementary | No | 동일한 변수명 라벨링 이슈 |

**공통 이슈**: 모든 figure에서 변수 코드명을 human-readable 라벨로 교체 필요.

---

## V. F1 내적 일관성 미세 수정 (4건)

1. Gen Z 전체 봉사율 23.9% vs pre/post COVID 분해 수치 간 명확화 문장 추가
2. Silent Generation "upward drift" 표현 → "modest increase" 등으로 완화
3. COVID wave 구분 (2021 = during pandemic) 주석 강화
4. Education × Generation 상호작용 효과 크기 정량화

---

## VI. 설계 의도 vs 최종 결과 비교

| 항목 | 원래 설계 | 최종 결과 | 판정 |
|------|----------|----------|------|
| N | ~201,000 | 201,168 | 일치 |
| 4-wave pooled | Yes | Yes | 일치 |
| 5 models | Yes | 5 models 완료 | 일치 |
| LPA 6지표 | Yes | 6지표, K=6 | 일치 |
| GBM+SHAP | Yes | AUC=.731 | 일치 |
| 10,000 words | ~10,250 목표 | 9,617 | 적합 |
| Results 45% | ~4,500w | 3,314w (38%) | 약간 하회 |
| Discussion 12% | ~1,200w | 1,598w (18%) | 초과 — 양호 |
| post_covid moderator | H3d | p=.344 (ns) | 설계대로 테스트 |
| PES16F 제외 | Limitation 언급 | Limitation에 포함 | 일치 |

---

## VII. 권장 수정 로드맵

```
Phase 1: 분석 보강 — 코드 수정 → 재실행 (시급순)
  ├─ 1. svydesign() 클러스터링 수정 → 5개 모델 재실행
  ├─ 2. age²/spline + 21-30세 고정 연령대 비교 (APC)
  ├─ 3. membership 직접 통제변수 추가
  ├─ 4. log-linear 연속 모델 vs 범주형 First Step 비교
  └─ 5. Figure 변수 라벨 교체

Phase 2: 원고 수정
  ├─ 1. 인과 언어 체계적 감사
  ├─ 2. G5 문체 수정 (7개 flagged passages + 어휘)
  ├─ 3. 이론 보강: Lim (2008), Beyerlein & Hipp (2006)
  ├─ 4. 반증 통합: Profile 3, Gen Z baseline, Activist Boycotter
  ├─ 5. "loneliness epidemic" → "social disconnection" 프레이밍
  ├─ 6. F1 미세 수정 4건
  └─ 7. "validation" → "triangulation" 용어

Phase 3: 최종 검토
  ├─ Discussion 확대 (practical implications 구체화)
  ├─ LCA 민감도 분석 (poLCA)
  ├─ Robustness checks 스크립트 작성·실행
  └─ DOCX 최종본 재생성
```

**Phase 1의 survey design 수정 결과에 따라 전체 결과 수치가 변동할 수 있으므로, 원고 수정(Phase 2)은 Phase 1 완료 후 시작.**

---

## 부록: 에이전트별 상세 리포트

각 에이전트의 전체 리포트는 다음 경로에 보관:
- F1: (session transcript)
- A3 #1: `/private/tmp/claude-501/-Users-hosung/tasks/ab4500759cd769c42.output`
- A3 #2: `/private/tmp/claude-501/-Users-hosung/tasks/a6bb6fbdbf6d384ab.output`
- G5 #1: `/private/tmp/claude-501/-Users-hosung/tasks/a9b11cbad5f55a153.output`
- G5 #2: `/private/tmp/claude-501/-Users-hosung/tasks/ac0d0996ba369f275.output`
- Figures: (session transcript)
