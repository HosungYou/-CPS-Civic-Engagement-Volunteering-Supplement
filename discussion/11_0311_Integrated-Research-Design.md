# 통합 연구 설계 — Bowling Alone, Scrolling Together

**작성일**: 2026-03-11
**작성자**: Hosung You
**목적**: 최종 확정된 연구 프레임워크, 분석 구조, 코드/원고 매핑

---

## 설계 요약

| 항목 | 내용 |
|------|------|
| **데이터** | CPS-CEV 2017/2019/2021/2023 (4-wave pooled) |
| **N** | ~201,000 (18+, VLSUPPWT > 0, valid VLSTATUS) |
| **DV** | VLSTATUS (volunteered = 1, not = 0) |
| **핵심 IV** | CESOCIALIZE (1=Not at all → 6=Daily) |
| **핵심 Moderator** | Generation (Gen Z, Millennial, Gen X, Boomer, Silent) |
| **추가 Moderators** | Education (BA+), Employment, Civic SM, **Post-COVID** |
| **타겟 저널** | NVSQ (10,000 words) |

---

## 설계 변경 이력

| 날짜 | 변경 | 이유 |
|------|------|------|
| 03-09 | 초기 설계: 4-wave, 주분석 로지스틱 + 보충 LPA/GBM | 원래 계획 |
| 03-11 AM | 2023 전용으로 전환, LPA 7지표 (PES16F 포함) | PES16F (가상봉사)로 2023 enriched 설계 |
| 03-11 AM | PES16F 제외 (봉사자 전용 변수), LPA 6지표 | PRSUPVOL=1 제약 발견 |
| **03-11 PM** | **4-wave 복귀 + post_covid moderator 추가** | **PES16F 제외 후 2023 전용 근거 소멸; 4-wave = 더 큰 N + COVID 비교 가능** |

---

## Research Questions (최종)

### RQ1 (Variable-Centered — 로지스틱 회귀)
How does the association between in-person socialization frequency and volunteering differ across generational cohorts, and do education, employment, civic social media use, and the COVID-19 pandemic moderate this association differently by generation?

- H1: Socialization → volunteering (positive, all generations)
- H2: Gen Z plateau effect at higher socialization
- H3a: Education moderates; weaker for Gen Z
- H3b: Employment moderates; consistent across generations
- H3c: Civic SM moderates; stronger for older cohorts
- **H3d: Socialization-volunteering stable pre/post COVID (cohort > period)**

### RQ2 (Person-Centered — LPA)
What distinct civic engagement typologies emerge, and how are generations distributed?

- H4: Gen Z → low-engagement profiles
- H5: High-engagement → older cohorts

### RQ3 (Predictive Validation — GBM+SHAP)
Does ML confirm socialization as #1 predictor?

- H6: CESOCIALIZE = top feature importance
- H7: SHAP dependence → First Step Effect

---

## 분석 파이프라인

```
00_data_preparation.R
│  Input:  data/cps_00002.csv (IPUMS, 450K rows)
│  Filter: 4 waves, age 18+, VLSUPPWT > 0, valid VLSTATUS
│  Recode: IPUMS variable names, post_covid, generation, membership fix
│  Output: data/cev_clean.rds (~201K rows)
│          data/cev_for_shap.csv (Python용)
│
├──→ 01_descriptive_analysis.R
│    Tables 1-7: Sample characteristics, socialization × generation × wave,
│    pre/post COVID comparison, SM compensation, education interaction
│
├──→ 02_logistic_regression.R  ← PRIMARY (RQ1)
│    Model 1: soc_factor × generation + post_covid (control)
│    Model 2: soc_factor × generation × ba_plus
│    Model 3: soc_factor × generation × employed
│    Model 4: soc_factor × generation × civic_sm
│    Model 5: soc_factor × generation × post_covid  ← NEW
│    Output: data/logistic_models.rds
│    Figures: pred_prob_soc_gen.png, ame_first_step.png,
│             pred_prob_covid_comparison.png
│
├──→ 03_latent_profile_analysis.R  ← SUPPLEMENTARY A (RQ2)
│    6 indicators: boycott, puboff, polconv, socialize, membership, donated
│    Model selection: 2-7 profiles, subsample 20K → full sample
│    Output: data/cev_with_profiles.rds, data/profile_summary.rds
│    Figures: lpa_bic_elbow.png, lpa_generation_distribution.png,
│             lpa_vol_rate_profile_gen.png
│
└──→ 04_gbm_shap_analysis.py  ← SUPPLEMENTARY B (RQ3)
     Features: CESOCIALIZE, EDUC, AGE, faminc_log, VLSOCMEDIA_rev,
               demographics, region, generation dummies, post_covid
     Output: figures/shap_*.png
```

---

## 변수 코딩 (IPUMS ↔ 분석)

| 분석 변수 | IPUMS 원변수 | 코딩 |
|-----------|-------------|------|
| volunteered | VLSTATUS | 1→1, 2→0 |
| CESOCIALIZE | CESOCIALIZE | 1-6 그대로 (ascending) |
| generation | YEAR - AGE | birth year 기준 5 cohorts |
| ba_plus | EDUC | ≥111 → 1 |
| employed | EMPSTAT | {10,12} → 1 |
| civic_sm | VLSOCMEDIA | ≤4 → 1 (any use) |
| female | SEX | 2 → 1 |
| married | MARST | {1,2} → 1 |
| metro | METRO | {2,3,4} → 1 |
| region | STATEFIP | FIPS → 4 regions |
| faminc_log | FAMINC | category → midpoint → log |
| post_covid | YEAR | {2021,2023} → 1 |
| boycott | CEBOYCOTT | 2 → 1 (Yes) |
| puboff | CEPUBOFF | 2 → 1 (Yes) |
| donated | VLDONATE | 2 → 1 (Yes) |
| membership | VLMEMBER + VLMEMBERN | VLMEMBER=1 → 0; else VLMEMBERN count |

---

## LPA 지표 (6개)

| # | 지표 | 유형 | 전 웨이브 유효율 |
|---|------|------|----------------|
| 1 | boycott | Binary | ~94.5% |
| 2 | puboff | Binary | ~94.5% |
| 3 | polconv | Ordinal 1-6 | ~94.5% |
| 4 | socialize | Ordinal 1-6 | ~95.0% |
| 5 | membership | Count 0+ | ~94.5% (VLMEMBER 리코딩 후) |
| 6 | donated | Binary | ~94.0% |

**제외된 변수**: PES16F (가상 봉사) — PRSUPVOL=1 (봉사자)만 응답, 전체 표본 LPA 불가

---

## 원고 구조 (NVSQ 10,000 words)

| 파일 | 섹션 | 배분 | Words |
|------|------|------|-------|
| 00_abstract.md | Abstract | — | ~250 |
| 01_introduction.md | Introduction | 12% | ~1,200 |
| 02_theoretical_framework.md | Literature Review | 13% | ~1,300 |
| 02a_purpose_rq.md | Purpose & RQs | 5% | ~500 |
| 03_method.md | Method | 13% | ~1,300 |
| 04_results.md | Results (Reg + LPA + GBM) | 45% | ~4,500 |
| 05_discussion.md | Discussion + Conclusion | 12% | ~1,200 |
| **합계** | | | **~10,250** |

Results 내부 배분:
- Stage 1 (Regression): ~2,000 words (Models 1-5 + AME + COVID comparison)
- Stage 2 (LPA): ~1,500 words (Model selection + profiles + generation × profile)
- Stage 3 (GBM+SHAP): ~1,000 words (Feature importance + dependence + generation comparison)

---

## Post-COVID 분석의 범위 제한

| 하는 것 | 하지 않는 것 |
|---------|-------------|
| post_covid를 control로 Models 1-4에 포함 | Wave별 별도 모델 |
| Model 5: soc × gen × post_covid 3-way interaction | COVID 전후 트렌드 분석 |
| 기술통계 Table 4: 주요 지표 pre/post 비교 | APC 분해 |
| LPA: profile 분포 pre/post 비교 (기술적) | Wave × socialization 상호작용 |

**핵심 원칙**: COVID는 "하나의 moderator"이지 별도 RQ가 아님. scope = 기존 RQ2의 H3d.

---

## 실행 순서

1. ✅ 코드 수정 완료 (00, 01, 02, 03, 04)
2. ✅ 원고 재구조화 완료 (00-05 markdown + DOCX)
3. ⬜ `00_data_preparation.R` 실행 → `cev_clean.rds` + `cev_for_shap.csv`
4. ⬜ `01_descriptive_analysis.R` 실행 → 기술통계 표
5. ⬜ `02_logistic_regression.R` 실행 → 5개 모델 + 그림
6. ⬜ `03_latent_profile_analysis.R` 실행 → 프로파일 확정
7. ⬜ `04_gbm_shap_analysis.py` 실행 → SHAP 그림
8. ⬜ 결과를 04_results.md에 채우기
9. ⬜ Discussion 작성
10. ⬜ DOCX 최종본 생성 → Dr. Windon 리뷰

---

## PES16F 관련 메모

- Census 변수명: PES16F (S16F), IPUMS에서 아직 harmonize 안 됨
- 질문: "봉사활동 중 대면 vs 온라인 비율"
- Universe: PRSUPVOL=1 (봉사자만) → N≈14,500 in 2023
- 값: 1=All in-person, 2=More in-person, 3=Evenly split, 4=More online, 5=All online
- **현재 상태**: 분석에서 제외. Limitation에서 언급.
- **향후**: IPUMS extract에 추가 후 봉사자 하위분석 가능 (R&R 대응용)
