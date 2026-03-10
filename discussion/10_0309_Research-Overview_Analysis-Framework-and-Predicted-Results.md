# 연구 전체 설명 — Bowling Alone, Scrolling Together

**작성일**: 2026-03-09
**작성자**: Hosung You
**목적**: Dr. Windon 미팅 전 연구 프레임워크, 분석 전략, 예측 결과 정리

---

## 이 연구가 무엇인가

이 연구는 **"왜 젊은 세대가 시민참여를 안 하는가?"**라는 질문에 대해 기존 답변("가치관이 다르다", "관심이 없다")을 뒤집고, **"사회적으로 만나지 않기 때문이다"**라는 새로운 설명을 전국 대표 데이터로 입증하는 논문입니다.

---

## 데이터

CPS-CEV (Current Population Survey — Civic Engagement and Volunteering Supplement)
- 미국 Census Bureau + AmeriCorps 공동 운영
- 4개 웨이브: 2017년 9월, 2019, 2021, 2023
- N = 201,168 (18세 이상, 유효 가중치 보유)
- 전국 대표 표본 (stratified multistage probability sampling)

---

## 핵심 변수

| 변수 | 역할 | 코딩 |
|------|------|------|
| VLSTATUS | 종속변수 (자원봉사 여부) | 1=함, 2=안 함 → 이진 |
| CESOCIALIZE | 핵심 독립변수 (대면 사교 빈도) | 1=전혀 안 함 → 6=매일 |
| Generation (birth year) | 핵심 조절변수 | Gen Z, Millennial, Gen X, Boomer, Silent |
| PEEDUCA | 조절변수 (교육) | BA+ vs. 이하 |
| PEMLR | 조절변수 (고용) | 취업 vs. 미취업 |
| VLSOCMEDIA | 조절변수 (시민적 소셜미디어) | 6→1 역코딩 |

---

## Research Questions (2개로 수렴)

**RQ1**: How does the relationship between in-person socialization frequency and volunteering differ across generational cohorts, and does this relationship exhibit nonlinear threshold effects?

**RQ2**: To what extent do education, employment, and civic social media use moderate the association between social isolation and volunteering, and does this moderation differ by generation?

---

## 분석 전략: 3단 구조

```
┌─────────────────────────────────────────────────────────────┐
│  1단계: 기술통계 (이미 완료)                                    │
│  교차분석표 → 패턴 발견 → RQ 도출                               │
│  "Gen Z 47% 고립, First Step 10-14pp, 교육 무효"               │
└───────────────────────┬─────────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  2단계: 정식 분석 (PRIMARY)                                    │
│  Survey-weighted logistic regression                         │
│  + Socialization × Generation interaction                    │
│  + Three-way interactions (× Education, × SM)                │
│  → 오즈비, 예측확률, 한계효과                                    │
└───────────────────────┬─────────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  3단계: 보충 분석 (SUPPLEMENTARY)                              │
│  A. LPA → 시민참여 유형학 (4-6 profiles)                       │
│  B. GBM + SHAP → 비선형성 포착, feature importance              │
│  → 2단계 결과를 person-centered + ML로 확인/보완                 │
└─────────────────────────────────────────────────────────────┘
```

**왜 이 구조인가**: 2단계(로지스틱 회귀)가 독자에게 가장 명확합니다. 오즈비와 한계효과는 사회과학 전공자 누구나 해석 가능합니다. LPA와 SHAP은 보충분석으로 두면 "단순히 변수 간 관계만 본 것 아니냐"는 리뷰어 비판에 대응하면서도 본문의 서사를 방해하지 않습니다.

---

## 타겟 저널

| 순위 | 저널 | IF | 한도 | 이유 |
|------|------|-----|------|------|
| **1** | **NVSQ** | 3.8 | 10,000 words | CPS-CEV 핵심 데이터, volunteering이 DV, Dr. Windon 도메인 정합, 방법론 혁신 환영 |
| **2** | **Voluntas** | 2.4 | 8,000 words | 국제 범위, 비영리·자원봉사 초점, 2026년부터 Cambridge UP |
| **3** | **Social Forces** | 3.3 | 10,000 words | 야심적 선택, 강력한 기술통계 발견 필요 |

Note: American Behavioral Scientist는 special issue 전용 → 개별 투고 불가.

---

## 예측되는 결과

### A. Primary Analysis (Logistic Regression)

**Model 1: Socialization × Generation**

| 전환 | Gen Z OR | Millennial OR | Gen X OR | Boomer OR |
|------|---------|-------------|---------|---------|
| Not at all → A few times/year | **1.84** | **1.82** | **2.08** | **2.14** |
| A few times/year → Once/month | 1.39 | 1.38 | 1.40 | 1.46 |
| Once/month → A few times/month | 1.05 (ns) | 1.06 | 1.14 | 1.16 |
| A few times/month → A few times/week | 0.93 (ns) | 1.15 | 1.26 | 1.22 |
| A few times/week → Daily | 1.12 (ns) | 1.02 (ns) | 0.91 (ns) | 0.97 (ns) |

- 모든 세대에서 "전혀 안 함 → 가끔"의 OR이 가장 큼 (약 1.8-2.1) = **First Step Effect**
- Gen Z에서만 "가끔/월 → 자주/주"의 OR이 비유의미 → **천장효과**
- Interaction term (Socialization × Generation) p < .001 예측

**Model 2: Average Marginal Effects**

| 전환 | Gen Z AME | Boomer AME |
|------|----------|-----------|
| Not at all → A few times/year | **+9.9 pp** | **+11.7 pp** |
| A few times/year → Once/month | +6.8 pp | +7.9 pp |
| Once/month → Few times/month | +1.0 pp (ns) | +3.5 pp |
| Few times/month → Few times/week | -1.5 pp (ns) | +4.7 pp |

**Model 3: Three-way interactions**

| 상호작용 | 예측 | p-value |
|---------|------|---------|
| Socialization × Generation × Education | **유의미** | < .001 |
| Socialization × Generation × Employment | 비유의미 | > .10 |
| Socialization × Generation × Civic SM | **유의미** | < .001 |

---

### B. LPA 예측 결과 (6 Profiles)

5개 지표: CEBOYCOTT, CEPUBOFF, CEPOLCONV, CESOCIALIZE, VLMEMBERN

**Profile 1: "Isolated Disengaged" (고립된 비참여자) — 약 22%**
- 모든 지표 바닥. 사회적으로 고립, 시민적 활동 전무
- Gen Z 38%, Millennial 25%, Boomer 15%
- 자원봉사율: ~12% (civic floor)

**Profile 2: "Connected but Passive" (연결됐지만 수동적) — 약 14%**
- 사교 활동 활발하지만 시민적 행동으로 전환 안 됨
- 세대 비교적 균등 분포
- 자원봉사율: ~25%

**Profile 3: "Checkbook Citizens" (수표책 시민) — 약 22%**
- 기부하고 조직에 속하지만 적극적 행동은 약함
- Gen X, Boomer 과대대표
- 자원봉사율: ~35%

**Profile 4: "Consumer Activists" (소비자 행동주의) — 약 8%**
- 불매운동 매우 높음, 조직 참여 없이 소비를 통한 시민참여
- Gen Z, Millennial 과대대표
- 자원봉사율: ~18%

**Profile 5: "Traditional Volunteers" (전통적 자원봉사자) — 약 20%**
- Putnam의 고전적 시민상. 조직 활동, 이웃 교류, 지역사회 참여
- Gen X, Boomer 과대대표
- 자원봉사율: ~55%

**Profile 6: "All-Around Civic" (전방위 시민) — 약 14%**
- 모든 차원에서 활발. 고학력, 고소득, 높은 사회적 연결
- Boomer 약간 과대, Gen Z 극소수 (~5%)
- 자원봉사율: ~65%

**모델 선택 기준 예측:**

| 모델 | BIC | Entropy | BLRT p | 최소 class % |
|------|-----|---------|--------|-------------|
| 4-class | 중간 | .82 | < .001 | 12% |
| 5-class | 낮음 | .84 | < .001 | 8% |
| **6-class** | **최저** | **.85** | **< .001** | **8%** |
| 7-class | 상승 | .83 | .08 | 4% ← 너무 작음 |

---

### C. GBM + SHAP 예측 결과

**Feature Importance (전체 표본):**

```
CESOCIALIZE  ████████████████████  (.182)  ← 1위
PEEDUCA      ██████████████        (.141)
PRTAGE       ███████████           (.118)
Generation   ██████████            (.103)
HEFAMINC     ████████              (.085)
VLSOCMEDIA   ██████                (.064)
GTMETSTA     ████                  (.042)
Marital      ███                   (.038)
PESEX        ███                   (.035)
Survey wave  ██                    (.022)
```

**SHAP Dependence Plot (CESOCIALIZE) 예측:**
- 모든 세대에서 1→2 전환의 기울기가 가장 가파름 = First Step
- Gen Z 곡선은 3 (once a month)에서 평탄해짐
- Boomer 곡선은 5 (few times/week)까지 상승 지속

**세대별 Feature Importance 비교:**

| Feature | Gen Z 순위 | Boomer 순위 | 해석 |
|---------|-----------|------------|------|
| CESOCIALIZE | **1위** (.195) | **1위** (.170) | 양쪽 다 1위, Gen Z에서 상대적 중요도 더 높음 |
| PEEDUCA | 2위 (.130) | 3위 (.125) | 비슷 |
| PRTAGE | 5위 (.065) | 2위 (.148) | Boomer 내 나이 효과 큼 (은퇴 전후) |
| VLSOCMEDIA | **6위** (.045) | **4위** (.098) | **Gen Z에서 소셜미디어 중요도 훨씬 낮음** |
| HEFAMINC | 3위 (.110) | 5위 (.072) | Gen Z에서 소득 제약이 더 강력 |

---

## 논문의 서사 흐름 (Narrative Arc)

```
① 미국의 사회적 고립 위기 (Surgeon General 2023)
   ↓
② 이 위기는 세대적으로 비대칭이다
   Gen Z 47% 고립 (COVID 이전, cohort effect)
   ↓
③ 고립은 자원봉사의 가장 강력한 상관물이다
   Logistic regression: socialization × generation 유의미
   GBM: CESOCIALIZE = feature importance 1위
   LPA: "Isolated Disengaged" profile에 Gen Z 38% 집중
   ↓
④ "First Step"이 가장 효율적 개입점이다
   Never → Minimal = 10-14pp gain (최대 한계효과)
   SHAP dependence plot: 1→2 전환의 기울기 최대
   ↓
⑤ 통상적 해법이 Gen Z에게 작동하지 않는다
   Education × Generation: 3-way interaction 유의미
   Employment × Generation: 비유의미
   Social Media × Generation: Gen Z에서 보상효과 절반
   ↓
⑥ 필요한 것은 물리적 사회적 인프라 투자이다
   Extension, community development, low-threshold programs
   "How do we create the social contact that makes
    volunteer recruitment possible?"
```

---

## 남은 작업 순서

1. Dr. Windon 이메일 발송 → 미팅 일정 확정
2. 정식 LPA 분석 (R tidyLPA / Mplus) → 모델 선택 → 프로파일 확정
3. Survey-weighted logistic regression (R survey package) → OR, AME 산출
4. GBM + SHAP (Python xgboost + shap) → feature importance + dependence plots
5. 원고 초안 수치 업데이트 → Dr. Windon 리뷰
6. NVSQ 투고
