# Bowling Alone, Scrolling Together: Social Isolation and the Generational Fracture of Civic Engagement in America

## Research Proposal and Exploratory Findings

**Prepared for**: Dr. Suzanna Windon
**Prepared by**: Hosung You
**Date**: March 3, 2026
**Data Source**: Current Population Survey — Civic Engagement and Volunteering Supplement (CPS-CEV), 2017, 2019, 2021, 2023

---

## 1. The Discovery

While exploring the CPS-CEV data for our Pennsylvania civic engagement project, I encountered a finding that reframes the entire study. The data reveals a phenomenon far more consequential than state-level variation in volunteering patterns: **social isolation is the strongest behavioral correlate of civic disengagement across all generations, and Generation Z stands at the epicenter of a socialization crisis that education, employment, and digital connectivity fail to resolve.**

This document walks through the discovery process, the evidence, and a proposed research framework.

---

## 2. The Starting Point: A Coding Crisis That Became a Discovery

### 2.1 Three Coding Errors, One Breakthrough

The exploration began with correcting a series of variable coding errors in the CPS-CEV data that had distorted our earlier analyses:

**Error 1: VLSTATUS direction**
- Previous assumption: 1 = Did not volunteer, 2 = Volunteered
- Actual coding: **1 = Volunteered, 2 = Did not volunteer**
- Impact: Pennsylvania's volunteering rate was 33.6%, not the 66.4% we had reported

**Error 2: CE* frequency scale direction**
- Previous assumption: 1 = Basically every day, 6 = Not at all (all frequency variables)
- Actual coding for CEPOLCONV, CESOCCONTCT, CESOCIALIZE: **1 = Not at all, 6 = Basically every day**
- Verification: Cross-validated using education — CEPOLCONV=6 (highest frequency) has 44.5% Bachelor's+ vs. CEPOLCONV=1 has 21.5%
- Note: VLSOCMEDIA retains the opposite coding (1 = daily, 6 = never)

**Error 3: CE* and VL* scales run in opposite directions**
- The Civic Engagement supplement (CE*) uses ascending frequency (1=never → 6=daily)
- The Volunteering supplement (VL*) uses descending frequency (1=daily → 6=never)

These corrections eliminated the need for reverse-coding CE* variables and led me to systematically verify every variable's behavior through education cross-validation. That process, in turn, led to examining socialization patterns across generations — and the discovery described below.

### 2.2 Corrected Key Statistics (National, N=201,168)

| Metric | Corrected Value |
|--------|----------------|
| National volunteering rate | 31.5% |
| PA volunteering rate | 33.6% |
| National civic disengagement (0 of 4 formal activities) | 36.1% |
| COVID volunteering decline (2019 → 2021) | Approx. −6pp |
| Education gradient: <HS → Graduate+ | ~15% → ~55% |

---

## 3. The Core Finding: America's Socialization-Civic Engagement Nexus

### 3.1 The Socialization Crisis Is Generational, Not Pandemic

The CPS-CEV supplement asks respondents how often they "got together socially with friends, relatives, or neighbors" (CESOCIALIZE, coded 1=not at all to 6=basically every day).

**Percentage who NEVER socialize, by generation:**

| Generation | 2017 | 2019 | 2021 | 2023 |
|-----------|------|------|------|------|
| Gen Z (born ≥1997) | 44.6% | 46.3% | 48.4% | 46.6% |
| Millennial (1981–96) | 30.9% | 32.8% | 32.7% | 29.6% |
| Gen X (1965–80) | 20.8% | 24.9% | 25.6% | 24.0% |
| Boomer (1946–64) | 17.3% | 19.7% | 20.9% | 19.2% |
| Silent (born <1946) | 17.2% | 20.2% | 20.7% | 22.4% |

**Nearly half of Gen Z reports never socializing in person.** This was true in 2017 — two years before COVID. The pandemic modestly worsened the pattern (48.4% in 2021) but did not create it, and recovery has been minimal.

### 3.2 It Is a Cohort Effect, Not an Age Effect

To rule out the possibility that young adults are simply always more isolated, I compared Millennials and Gen Z at the same age:

| Comparison | NeverSoc | Vol | Disengaged | BA+ |
|-----------|----------|-----|-----------|-----|
| Millennials at age 20–25 (2017) | 40.0% | 26.3% | 53.1% | 25.9% |
| Gen Z at age 20–25 (2023) | **47.4%** | **22.4%** | **56.6%** | 25.9% |

Same age, identical education profile, but Gen Z is 7.4 percentage points more socially isolated and 3.5 points more civically disengaged. This is a generational shift.

### 3.3 Neither Education Nor Employment Resolves the Crisis

**Education:**

| Generation | BA+ NeverSoc rate | BA+ Volunteering rate |
|-----------|------------------|---------------------|
| Gen Z | **42.1%** | 34.0% |
| Millennial | 25.5% | 43.1% |
| Gen X | 16.5% | 52.5% |
| Boomer | **13.4%** | 47.1% |

College-educated Gen Z members are three times more likely to never socialize than college-educated Boomers (42.1% vs. 13.4%). A bachelor's degree does not resolve Gen Z's socialization deficit.

**Employment:**

| Generation | Employed: NeverSoc | Not-Employed: NeverSoc |
|-----------|-------------------|----------------------|
| Gen Z | 45.6% | 48.3% |
| Boomer | 18.6% | 19.5% |

For Gen Z, employment has essentially no effect on socialization patterns. This distinguishes the current crisis from historical patterns where workplace integration served as a pathway to social connection and civic recruitment (Verba et al., 1995).

---

## 4. Civic Consequences: The Socialization–Engagement Gradient

### 4.1 The "First Step" Is Everything

Volunteering rates by socialization frequency show a striking nonlinear pattern:

| Socialization Level | Gen Z | Millennial | Gen X | Boomer |
|-------------------|-------|-----------|-------|--------|
| Never | 15.7% | 19.1% | 18.7% | 13.7% |
| A few times/year | 25.6% | 30.1% | 32.3% | 25.4% |
| Once a month | 32.4% | 37.2% | 40.0% | 33.3% |
| A few times/month | 33.4% | 38.6% | 43.0% | 36.8% |
| A few times/week | 31.9% | 42.0% | 48.7% | 41.5% |
| Daily | 34.6% | 42.5% | 44.3% | 40.7% |

**The single largest jump in volunteering occurs at the transition from "never" to "a few times a year"** — a gain of 10 to 14 percentage points across all generations. This is the most efficient intervention point: moving someone from complete social isolation to even minimal social contact produces the largest marginal increase in civic participation.

However, Gen Z exhibits a **ceiling effect** at approximately 34% volunteering — regardless of how frequently they socialize. Other generations continue to see gains at higher socialization frequencies, but Gen Z's volunteering rate plateaus. This suggests a structural barrier beyond socialization alone.

### 4.2 Social Isolation Produces Uniform Civic Floors Across Generations

When we control for socialization, the generational gap in civic engagement narrows dramatically:

| Condition | Gen Z | Millennial | Gen X | Boomer |
|----------|-------|-----------|-------|--------|
| HS diploma + Isolated | 12.2% | 11.5% | 11.8% | **~12%** |
| BA+ degree + Connected | 42.8% | 51.3% | 54.5% | **varies** |

The civic "floor" — the volunteering rate of socially isolated, high-school-educated adults — is approximately 12% regardless of generation. **Social isolation creates a universal civic minimum.** The generational differences emerge at the civic "ceiling," where Gen Z's maximum (42.8%) lags behind older cohorts (51–55%).

### 4.3 The Role Reversal That Breaks the Narrative

Perhaps the most counterintuitive finding:

| Group | N | Volunteering | Disengagement |
|-------|---|-------------|--------------|
| Gen Z — BA+, socially connected, politically talkative | 246 | **45.5%** | 31.3% |
| Average Boomer (all) | 67,631 | 32.3% | 31.0% |

**The most connected Gen Z members actually out-volunteer the average Boomer.** Gen Z's civic crisis is not about generational values or attitudes. It is about the fact that the vast majority of Gen Z is trapped in social isolation — and the small minority who escape it are more civically active than the generation typically held up as the civic benchmark.

---

## 5. The Digital Native Paradox

### 5.1 Social Media Compensates for Isolation — But More for Boomers Than Gen Z

Among socially isolated individuals, civic use of social media is associated with higher volunteering:

| Generation | Isolated + SM Use | Isolated + No SM | **Compensation Effect** |
|-----------|------------------|-----------------|----------------------|
| Gen Z | 22.6% vol | 17.0% vol | +5.5pp |
| Millennial | 28.6% | 21.5% | +7.1pp |
| Gen X | 29.5% | 22.7% | +6.8pp |
| **Boomer** | **28.3%** | **17.0%** | **+11.3pp** |
| **Silent** | **23.2%** | **12.2%** | **+10.9pp** |

**The digital native generation benefits least from digital civic tools.** For Boomers and the Silent Generation, civic social media use is associated with an 11-point increase in volunteering among the socially isolated. For Gen Z, the effect is half that size (+5.5pp).

Among socially *connected* individuals, the pattern is even starker:

| Generation | Connected + SM | Connected + No SM | Delta |
|-----------|---------------|------------------|-------|
| Gen Z | 34.1% | 32.5% | +1.6pp |
| Boomer | 48.0% | 38.1% | +9.9pp |

For Gen Z who already socialize regularly, civic social media use adds almost nothing (+1.6pp). For connected Boomers, it adds nearly 10 points. Social media appears to function as a genuinely new civic channel for older adults but is merely ambient noise for a generation that has never known life without it.

### 5.2 The Civic Substitution: From Volunteering to Boycotting

Gen Z is not entirely civically absent — but the form of their engagement is shifting:

| Generation | Volunteering Δ (2017→2023) | Boycotting Δ | Donating Δ | Contacting Officials Δ |
|-----------|--------------------------|-------------|-----------|----------------------|
| **Gen Z** | **−2.6pp** | **+8.3pp** | +7.1pp | +0.6pp |
| Millennial | +2.8pp | +6.4pp | +4.4pp | +0.1pp |
| Gen X | −4.3pp | +4.9pp | −2.9pp | −2.1pp |
| Boomer | −2.3pp | +4.0pp | −1.9pp | −4.0pp |

Gen Z's boycotting rate more than doubled from 6.5% to 14.8% between 2017 and 2023, even as volunteering declined. This suggests a **"consumerization" of civic engagement** — replacing time-intensive, community-embedded participation (volunteering) with individual, market-mediated action (boycotting). The phenomenon aligns with Bennett and Segerberg's (2012) concept of "connective action" displacing traditional collective action.

---

## 6. COVID as Amplifier, Not Cause

### 6.1 The Pandemic Accelerated Pre-existing Divergence

| Generation | Indicator | 2017 | 2019 | 2021 (COVID) | 2023 |
|-----------|----------|------|------|-------------|------|
| Gen Z | Isolated (%) | 57.0 | 59.7 | **62.6** | 59.0 |
| Gen Z | Disengaged (%) | 62.7 | 57.9 | 61.1 | **55.5** |
| Gen Z | Boycotting (%) | 6.5 | 9.8 | 12.0 | **14.8** |
| Millennial | Disengaged (%) | 42.7 | 40.7 | 40.0 | **38.0** |
| Millennial | Active 3+ (%) | 10.6 | 11.6 | 12.4 | **13.1** |
| Boomer | Volunteering (%) | 34.0 | 34.2 | **28.4** | 31.7 |

The data shows three distinct generational responses to the pandemic:

1. **Gen Z: Deepening isolation with civic substitution.** Social isolation peaked during COVID but was already severe. Civic disengagement actually *improved* slightly by 2023 — but only because boycotting doubled, not because volunteering or formal participation recovered.

2. **Millennials: Steady civic maturation despite disruption.** The only generation showing continuous decline in disengagement and continuous growth in multi-domain civic activity, even through the pandemic. This may reflect life-course effects (entering peak parenting and career years) combined with political activation around social justice movements.

3. **Boomers: Classic V-shaped recovery.** Volunteering dropped sharply during COVID (34.2% → 28.4%) but substantially recovered (31.7%), while donation and boycotting rates remained stable or grew. Their civic infrastructure proved resilient.

---

## 7. Proposed Research Framework

### 7.1 Title

**"Bowling Alone, Scrolling Together: Social Isolation and the Generational Fracture of Civic Engagement in America"**

### 7.2 Research Questions

**RQ1 (Typological Structure):** What distinct civic engagement profiles emerge from Latent Profile Analysis of the national CPS-CEV sample, and how does generational membership predict profile classification?

*Expected: 4–6 profiles including "Isolated Disengaged" (22%), "Connected Disengaged" (14%), "Checkbook Citizens" (22%), "Consumer Activists" (8%), "Traditional Volunteers" (14%), and "All-around Civic" (14%). Gen Z will be disproportionately concentrated in the Isolated Disengaged profile.*

**RQ2 (The Socialization Gradient):** How does the predictive relationship between socialization frequency and volunteering vary across generational cohorts, and what role do education and digital connectivity play in moderating this relationship?

*Expected: GBM+SHAP analysis will identify socialization frequency as the top-ranked predictor across all profiles, with a pronounced nonlinear "first step" effect. SHAP interaction values will reveal that the socialization × education interaction operates differently for Gen Z (additive) versus older cohorts (multiplicative).*

**RQ3 (Pandemic Structural Change):** Did the COVID-19 pandemic alter the typological structure of civic engagement, and were these shifts consistent across generational cohorts?

*Expected: Profile distribution shifts showing Gen Z's "Isolated Disengaged" proportion peaking in 2021 and partially recovering by 2023, while the "Consumer Activist" profile grows steadily. Millennials will show counter-trend growth in active profiles.*

**RQ4 (The Digital Native Paradox):** Does civic use of social media compensate for the civic consequences of social isolation, and does this compensation vary by generation?

*Expected: Social media compensation effect approximately +5.5pp for isolated Gen Z versus +11.3pp for isolated Boomers. Among socially connected individuals, social media will show negligible additional effect for Gen Z (+1.6pp) but substantial effect for Boomers (+9.9pp).*

### 7.3 Analytical Framework

**Phase 1: Latent Profile Analysis**
- 5 indicators: CEBOYCOTT (binary), CEPUBOFF (binary), CEPOLCONV (frequency, 1–6), CESOCIALIZE (frequency, 1–6), VLMEMBERN (count)
- National sample (N ≈ 200,000) enables robust subgroup estimation
- Model selection via BIC, entropy, and BLRT
- Generation as auxiliary variable (BCH method)

**Phase 2: Profile-Stratified Prediction (GBM + SHAP)**
- Gradient Boosting Machines predicting volunteering within each profile
- TreeSHAP decomposition of feature contributions
- Key predictors: generation, socialization frequency, education, employment, social media use, geography
- Focus on nonlinear effects and interaction terms

**Phase 3: Temporal Comparison**
- Profile distribution comparison across 2017, 2019, 2021, 2023 waves
- Generation × wave interaction analysis
- Pre-pandemic baseline (2017–2019) vs. pandemic/post-pandemic (2021–2023)

**Phase 4: Social Media Moderation Analysis**
- Socialization × social media × generation three-way interaction
- SHAP-based decomposition of compensation effects by profile and generation

### 7.4 Theoretical Framing

This study bridges three literatures:

1. **The Surgeon General's Advisory on Loneliness (2023)**: The U.S. Surgeon General declared loneliness and social isolation a public health epidemic, with extensive attention to mental and physical health consequences. The *civic* consequences of this epidemic remain underexplored. Our study provides the first large-scale empirical evidence that social isolation is not merely a health crisis but a democratic crisis.

2. **Putnam's Social Capital Framework (updated)**: *Bowling Alone* (2000) documented the decline of associational life in the late 20th century. Our findings suggest a new chapter: the decline has become generationally asymmetric, with Gen Z experiencing a qualitatively different form of disconnection than previous cohorts. Unlike Putnam's suburbanization-driven decline, Gen Z's isolation persists regardless of geography, education, or employment — suggesting roots in digital-age social infrastructure rather than community-level structural change.

3. **Bennett and Segerberg's Connective Action (2012)**: The "civic substitution" pattern — volunteering declining while boycotting surges — aligns with the shift from collective action (organized, community-embedded, requiring co-presence) to connective action (individualized, digitally mediated, requiring only a consumer identity). Our data suggests this shift is most pronounced in Gen Z and accelerated by the pandemic.

### 7.5 Data and Sample

| Parameter | Detail |
|----------|--------|
| Dataset | CPS-CEV Supplement via IPUMS |
| Waves | September 2017, 2019, 2021, 2023 |
| Sample | U.S. adults 18+, valid supplement weight |
| Analytic N | ~201,000 |
| Key variables | VLSTATUS (1=vol, 2=no), VLDONATE, CEBOYCOTT, CEPUBOFF, CEPOLCONV, CESOCIALIZE, VLSOCMEDIA, VLMEMBERN |
| Weights | VLSUPPWT (supplement weight) |
| Scope | National (shift from PA-only) |

### 7.6 Scale Coding (Verified)

| Variable | Type | Coding Direction | Verified By |
|----------|------|-----------------|-------------|
| VLSTATUS | Binary | 1=Volunteered, 2=Did not | Education cross-validation |
| VLDONATE | Binary | 1=Did not donate, 2=Donated | Direct |
| CEBOYCOTT | Binary | 1=No, 2=Yes | Direct |
| CEPUBOFF | Binary | 1=No, 2=Yes | Direct |
| CEPOLCONV | 6-point freq | 1=Never → 6=Daily | Education cross-validation |
| CESOCCONTCT | 6-point freq | 1=Never → 6=Daily | Education cross-validation |
| CESOCIALIZE | 6-point freq | 1=Never → 6=Daily | Education cross-validation |
| VLSOCMEDIA | 6-point freq | **1=Daily → 6=Never** | Distribution + cross-validation |

*Note: CE* variables (Civic Engagement supplement) use ascending frequency, while VL* variables (Volunteering supplement) use descending frequency. No reverse-coding of CE* variables is needed.*

---

## 8. Why This Story Matters

### 8.1 For Community Development and Extension

The finding that the "first step" from never socializing to even minimal social contact produces the largest civic engagement gain (10–14pp) has direct programmatic implications. Community development practitioners and Extension educators need not aim for intensive social integration — even low-threshold social programming (community meals, drop-in events, casual gathering spaces) may produce disproportionate civic returns, particularly for socially isolated young adults.

### 8.2 For Policy

The failure of education and employment to resolve Gen Z's socialization deficit challenges two dominant policy assumptions: (1) that expanding educational access inherently strengthens civic capacity, and (2) that labor market integration provides a sufficient pathway to community connection. Our data suggests that civic infrastructure — the physical and institutional spaces where people encounter one another — requires deliberate investment independent of human capital development.

### 8.3 For the Loneliness Conversation

By connecting the Surgeon General's loneliness epidemic to measurable civic outcomes using a nationally representative dataset, this study adds democratic health to the growing case for treating social isolation as a public priority. The finding that 60% of Gen Z is completely civically disengaged — and that this is primarily a socialization problem, not a values or attitude problem — reframes the generational discourse from "young people don't care" to "young people aren't connected."

### 8.4 The Counterintuitive Headline

The study's most provocative finding: **the most socially connected, college-educated Gen Z members volunteer at higher rates than the average Baby Boomer.** The "generational decline" narrative collapses once socialization is accounted for. The crisis is not that a generation has abandoned civic life — it is that nearly half a generation has been cut off from the social infrastructure that makes civic life possible.

---

## 9. Shift from Pennsylvania to National Scope

### 9.1 Rationale

Our original design focused on Pennsylvania (N=5,478). The shift to national scope (N≈201,000) is motivated by:

1. **The finding is generational, not geographic.** Social isolation and its civic consequences do not vary substantially by state. The pattern holds across all 50 states and DC.

2. **Statistical power for LPA subgroups.** National data enables robust estimation of 5–6 profiles with sufficient cell sizes for generation × profile × wave cross-tabulations.

3. **Broader impact.** A national study directly addresses the Surgeon General's advisory and speaks to federal and state policymakers, not just Pennsylvania Extension.

4. **PA can serve as a case study within the national framework**, if desired — highlighting within-state rural/urban variation as an illustrative example.

### 9.2 What We Lose

- The Extension-specific framing tied to Penn State's community development mission
- The rural-urban analysis specific to Pennsylvania's unique geography (Appalachian, agricultural, post-industrial)
- The Community Capitals Framework, which is most applicable at the community level

### 9.3 What We Gain

- A nationally representative finding with policy relevance to the Surgeon General's advisory
- 37× larger sample for robust subgroup analysis
- The "generational fracture" framing, which requires national scope to establish as a cohort (not regional) effect
- Potential for high-impact publication venue

---

## 10. Open Questions for Discussion

1. **Scope**: Do we commit to the national framing, or maintain a PA focus with national context? My recommendation is national with PA as an optional illustrative case.

2. **Title and framing**: "Bowling Alone, Scrolling Together" positions us in conversation with Putnam's foundational work. Is this too ambitious, or appropriately so?

3. **Causal language**: The findings are cross-sectional and associational. The "first step" effect is predictive, not causal. Should we frame this as a predictive-interpretive study (SHAP-based) or pursue quasi-causal methods (e.g., panel-like cohort comparisons across waves)?

4. **The Gen Z ceiling effect**: Gen Z's volunteering plateaus at ~34% regardless of socialization frequency. This suggests a barrier beyond social connection — possibly institutional (fewer accessible volunteer organizations), economic (time constraints), or cultural (preference for individual over collective action). Should we explicitly investigate this ceiling?

5. **Target journal**: The generational + loneliness + civic engagement combination could fit:
   - *American Behavioral Scientist* (civic engagement focus)
   - *Journal of Youth and Adolescence* (generational focus)
   - *Social Forces* or *Social Problems* (broad sociological)
   - *Nonprofit and Voluntary Sector Quarterly* (volunteering focus)
   - *Journal of Community Psychology* (community connection focus)

6. **Timeline and next steps**: If we agree on the national framing, I can begin the formal LPA analysis immediately. The data is clean and the coding is verified.

---

*All statistics in this document are based on exploratory analysis of the CPS-CEV supplement (N=201,168 adults with valid supplement weights across four waves). Formal analysis with survey weights, model selection procedures, and inferential testing will follow upon agreement on research design.*
