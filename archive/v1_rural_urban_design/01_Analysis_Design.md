# Analysis Design: Latent Profile Analysis + Causal Forest + SHAP

## Heterogeneous Effects of Organized Volunteering on Civic Engagement: A Machine Learning Approach Using CPS-CEV Data

### Authors
- Hosung You (First Author — Methodological Contribution)
- Suzanna Windon, Ph.D. (Corresponding Author — Domain Expertise)

---

## 1. Research Overview

### 1.1 Research Problem
Existing studies on volunteering and civic engagement predominantly rely on variable-centered approaches (e.g., logistic regression, OLS) that assume homogeneous effects across populations. This approach obscures critical heterogeneity: volunteering may have differential effects on civic engagement depending on rural/urban residence, socioeconomic status, and demographic characteristics. Moreover, the multidimensional nature of civic engagement (volunteering, political participation, charitable giving, community interaction) has rarely been examined through person-centered typological approaches.

### 1.2 Research Purpose
This study introduces an innovative three-phase analytical framework combining Latent Profile Analysis (LPA), Causal Forest, and SHAP (SHapley Additive exPlanations) to:
1. Identify latent civic engagement profiles among U.S. adults
2. Estimate heterogeneous causal effects of organized volunteering across these profiles
3. Visualize and interpret the key drivers of effect heterogeneity

### 1.3 Research Questions

**RQ1 (Person-Centered Typology):**
How many qualitatively distinct civic engagement profiles exist among U.S. adults, and how are these profiles distributed across rural and urban areas?

**RQ2 (Heterogeneous Causal Effects):**
To what extent does the effect of organized volunteering on civic engagement outcomes vary across identified latent profiles and rural/urban residence?

**RQ3 (Explanatory Mechanisms):**
What individual- and community-level factors most strongly explain the heterogeneity in volunteering effects on civic engagement?

### 1.4 Theoretical Framework

**Community Capitals Framework (Flora & Flora, 2013)**
- Human capital, social capital, cultural capital, and political capital
- Volunteering as a mechanism for capital accumulation and transfer
- Rural/urban differential in capital availability and mobilization

**Positive Youth/Adult Development Framework (Lerner et al., 2005)**
- Contribution as a developmental outcome
- Leadership competencies as mediating factors

**Social Exchange Theory (Blau, 1964)**
- Cost-benefit calculus of civic participation
- Differential exchange structures in rural vs. urban contexts

---

## 2. Data Source

### 2.1 CPS Civic Engagement & Volunteering Supplement (CEV)

| Attribute | Details |
|-----------|---------|
| **Sponsor** | AmeriCorps + U.S. Census Bureau |
| **Waves** | September 2017, 2019, 2021, 2023 |
| **Sample Size** | ~90,000 households per wave (~360,000 total pooled) |
| **Sampling Design** | Stratified multistage probability sampling |
| **Population** | U.S. civilian noninstitutionalized population aged 16+ |
| **Weights** | Survey weights provided (PWSUPWGT) |
| **Access** | https://data.americorps.gov / https://cps.ipums.org |

### 2.2 Key Variables

#### Outcome Variables (Civic Engagement Indicators for LPA)

| Variable | Measure | Type |
|----------|---------|------|
| Volunteering frequency | Days volunteered in past 12 months | Continuous |
| Political participation | Voted, contacted officials, attended meetings | Count/Binary |
| Charitable giving | Donated to charitable organizations | Binary/Amount |
| Community interaction | Talked with neighbors, attended community events | Frequency scale |
| Group membership | Number of organizations participated in | Count |
| Virtual volunteering | Online/remote volunteering (2023 wave) | Binary |

#### Treatment Variable

| Variable | Operationalization |
|----------|-------------------|
| Organized volunteering | Volunteered through/for an organization in past 12 months (binary) |

#### Covariates (Effect Moderators)

| Category | Variables |
|----------|----------|
| **Geographic** | Rural/urban (metro status), state, region |
| **Demographic** | Age, sex, race/ethnicity, marital status, household size |
| **Socioeconomic** | Education level, household income, employment status |
| **Contextual** | Homeownership, internet access, length of residence |
| **Temporal** | Survey wave (2017/2019/2021/2023) |

### 2.3 Rural/Urban Classification

Using the CPS metropolitan statistical area (MSA) variable:
- **Urban**: Principal city of MSA or balance of MSA
- **Rural**: Non-metropolitan area
- Additional sensitivity analysis using USDA Rural-Urban Continuum Codes (merged at county level)

### 2.4 Sample Construction

```
Total CPS-CEV pooled sample (4 waves)
    ↓ Exclude: Age < 18
    ↓ Exclude: Missing on all civic engagement indicators
    ↓ Exclude: Missing on rural/urban classification
    ↓ Apply survey weights
    = Final analytic sample (estimated N ≈ 250,000–300,000)
```

---

## 3. Analytical Framework: Three-Phase Design

```
┌─────────────────────────────────────────────────────────┐
│                    PHASE 1: LPA                         │
│         Latent Profile Analysis                         │
│         "Who are they?" — Civic Engagement Typology     │
│                                                         │
│  Input: 6 civic engagement indicators                   │
│  Output: K latent profiles with posterior probabilities  │
│  Tool: R tidyLPA / Mplus                                │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    PHASE 2: Causal Forest               │
│         Generalized Random Forest (GRF)                 │
│         "What works for whom?" — Heterogeneous Effects  │
│                                                         │
│  Input: Treatment (volunteering) × Covariates           │
│         × Profile membership                            │
│  Output: Individual-level CATE (τ̂(Xi))                 │
│  Tool: R grf package                                    │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    PHASE 3: SHAP                        │
│         SHapley Additive exPlanations                   │
│         "Why?" — Interpretable Effect Decomposition     │
│                                                         │
│  Input: Causal Forest model + feature matrix            │
│  Output: SHAP values per feature per observation        │
│  Tool: Python shap / R shapr                            │
└─────────────────────────────────────────────────────────┘
```

---

## 4. Phase 1: Latent Profile Analysis (LPA)

### 4.1 Model Specification

**Indicator variables** (standardized z-scores):
1. Volunteering frequency (log-transformed)
2. Political participation index
3. Charitable giving (binary → probability)
4. Community interaction frequency
5. Group/organization membership count
6. Online civic engagement index

**Model comparison**: Fit 1-class through 7-class models

### 4.2 Model Selection Criteria

| Criterion | Preferred Direction |
|-----------|-------------------|
| BIC (Bayesian Information Criterion) | Lower is better |
| AIC (Akaike Information Criterion) | Lower is better |
| Entropy | Closer to 1.0 (≥ 0.80 acceptable) |
| BLRT (Bootstrap Likelihood Ratio Test) | Significant p-value supports k over k-1 |
| Lo-Mendell-Rubin LRT | Significant p-value supports k over k-1 |
| Smallest class proportion | ≥ 5% of total sample |

### 4.3 Post-LPA Analysis

- Assign each individual to their most likely profile (modal assignment)
- Compare profile distribution by rural/urban status (χ² test)
- Examine profile-by-wave interaction (temporal stability)

### 4.4 Expected Profiles (Hypothesized)

| Profile | Label | Characteristics |
|---------|-------|----------------|
| 1 | **Disengaged** | Low on all indicators |
| 2 | **Passive Donors** | High giving, low active participation |
| 3 | **Community Connectors** | High neighbor interaction, moderate volunteering |
| 4 | **Active Volunteers** | High organized volunteering, moderate political |
| 5 | **Civic All-Rounders** | High on all dimensions |

---

## 5. Phase 2: Causal Forest (Generalized Random Forest)

### 5.1 Model Specification

```r
# Core model specification
library(grf)

# Treatment: Organized volunteering (W)
# Outcome: Composite civic engagement score or specific outcome
# Covariates: X matrix (demographics + geography + SES + profile)

cf <- causal_forest(
  X = X_matrix,           # Covariates (including LPA profile as factor)
  Y = Y_outcome,          # Civic engagement outcome
  W = W_treatment,        # Organized volunteering (0/1)
  sample.weights = survey_weights,  # CPS survey weights
  num.trees = 5000,       # Number of trees
  honesty = TRUE,         # Honest estimation (sample splitting)
  tune.parameters = "all" # Auto-tune all hyperparameters
)
```

### 5.2 Identification Strategy

**Assumption**: Unconfoundedness (Selection on Observables)
- Conditional on the rich set of covariates in CPS, treatment assignment (organized volunteering) is independent of potential outcomes
- Strengthened by: (1) large covariate set, (2) survey design, (3) honesty in estimation

**Robustness checks**:
- Overlap assessment (propensity score trimming)
- Sensitivity analysis for hidden bias (Rosenbaum bounds)
- Comparison with traditional methods (PSM, IPW, OLS)

### 5.3 Key Outputs

| Output | Description |
|--------|-------------|
| τ̂(Xi) | Individual-level Conditional Average Treatment Effect |
| ATE | Average Treatment Effect (forest-level) |
| CATE by profile | Average effect within each LPA profile |
| CATE by rural/urban | Geographic heterogeneity |
| Variable importance | Which covariates drive heterogeneity |
| Best linear projection | Parametric summary of heterogeneity |

### 5.4 Multiple Outcomes Strategy

Run separate causal forests for each outcome:
1. **Political participation** (voted + contacted officials)
2. **Charitable giving** (donated to charity)
3. **Community interaction** (neighbor/community engagement)
4. **Group membership** (organizational participation count)

Apply Bonferroni or FDR correction for multiple comparisons.

---

## 6. Phase 3: SHAP Value Analysis

### 6.1 Implementation

```python
import shap

# Extract predictions from causal forest
# Use TreeSHAP for computational efficiency

explainer = shap.TreeExplainer(causal_forest_model)
shap_values = explainer.shap_values(X_matrix)
```

### 6.2 Planned Visualizations

| Visualization | Purpose | Figure |
|--------------|---------|--------|
| **SHAP Summary Plot (Beeswarm)** | Show how each feature pushes CATE up/down | Fig 3 |
| **SHAP Dependence Plot** | Rural/urban × education interaction on CATE | Fig 4 |
| **SHAP Force Plot** | Individual-level effect decomposition (exemplar cases) | Fig 5 |
| **SHAP Interaction Plot** | Two-way feature interactions driving heterogeneity | Fig 6 |
| **Geographic CATE Heatmap** | State-level average CATE overlaid on US map | Fig 7 |
| **Profile × CATE Bar Chart** | Average treatment effect by LPA profile | Fig 8 |
| **Radar Chart (per profile)** | Multidimensional civic engagement patterns | Fig 2 |
| **Sankey Diagram** | Profile transitions across 2017-2023 waves | Fig 9 |

---

## 7. Software and Reproducibility

### 7.1 Software Environment

| Tool | Package | Purpose |
|------|---------|---------|
| R 4.4+ | `tidyLPA` | Latent Profile Analysis |
| R 4.4+ | `grf` (v2.3+) | Generalized Random Forest / Causal Forest |
| R 4.4+ | `survey` | Survey-weighted estimation |
| R 4.4+ | `ipumsr` | CPS data import and processing |
| Python 3.11+ | `shap` (v0.44+) | SHAP values and visualization |
| Python 3.11+ | `matplotlib`, `seaborn` | Publication-quality figures |
| Python 3.11+ | `geopandas`, `folium` | Geographic visualizations |
| R/Python | `reticulate` | R-Python bridge |

### 7.2 Reproducibility

- All code deposited in GitHub repository
- Random seeds fixed for all stochastic procedures
- Docker/renv environment file for dependency management
- Pre-registration plan on OSF (recommended)

---

## 8. Expected Contributions

### 8.1 Methodological Contributions (1st Author Justification)
1. **First application** of Causal Forest + SHAP to civic engagement research
2. **Novel integration** of person-centered (LPA) and causal ML approaches
3. **Demonstration** of heterogeneous treatment effect estimation with large-scale survey data
4. **Replicable analytical pipeline** for civic engagement researchers

### 8.2 Substantive Contributions
1. Evidence-based civic engagement typology for rural and urban populations
2. Identification of "for whom" organized volunteering is most effective
3. Policy-relevant insights for targeting extension programs and volunteer development

### 8.3 Practical Contributions
1. Decision support tool for volunteer coordinators and extension educators
2. Geographic targeting maps for civic engagement interventions
3. Profile-specific program recommendations

---

## 9. Timeline

| Phase | Task | Duration |
|-------|------|----------|
| 1 | Data acquisition and cleaning (IPUMS CPS) | 2 weeks |
| 2 | LPA model estimation and profile identification | 2 weeks |
| 3 | Causal Forest estimation and diagnostics | 3 weeks |
| 4 | SHAP analysis and visualization | 2 weeks |
| 5 | Manuscript drafting | 3 weeks |
| 6 | Internal review and revision | 2 weeks |
| 7 | Journal submission | 1 week |
| **Total** | | **~15 weeks** |

---

## 10. Target Journals

| Priority | Journal | IF | Rationale |
|----------|---------|----|-----------|
| 1st | *Nonprofit and Voluntary Sector Quarterly* | 3.8 | Top journal for volunteering research; methodological innovation welcome |
| 2nd | *Voluntas: International Journal of Voluntary and Nonprofit Organizations* | 2.4 | International scope; interdisciplinary |
| 3rd | *Journal of Community Development* | — | Community development focus |
| 4th | *Social Science Research* | 2.9 | Methodological innovation in social science |
| Alt | *PLOS ONE* | 2.9 | Open access; rapid review; methods-focused |

---

## Appendix A: Variable Codebook (CPS-CEV)

| CPS Variable | Description | Coding |
|-------------|-------------|--------|
| PES1 | Volunteered through/for organization | 1=Yes, 2=No |
| PES2A-F | Types of volunteer activities | Multiple binary |
| PES3 | Number of organizations volunteered for | Count |
| PES5 | Hours volunteered in past 12 months | Continuous |
| PES6 | Main organization type | Categorical |
| PRS1-4 | Political participation items | Binary |
| PRS5-8 | Community interaction items | Frequency |
| PRS9-12 | Group membership items | Binary |
| PRS13 | Charitable giving | Binary |
| GESTFIPS | State FIPS code | Geographic |
| GTMETSTA | Metropolitan status | 1=Metro, 2=Non-metro |
| PEEDUCA | Education level | Categorical |
| HEFAMINC | Family income | Categorical ranges |
| PRTAGE | Age | Continuous |
| PESEX | Sex | 1=Male, 2=Female |
| PTDTRACE | Race/ethnicity | Categorical |

## Appendix B: Sensitivity Analysis Plan

1. **Propensity score trimming**: Exclude observations with extreme propensity scores (< 0.05 or > 0.95)
2. **Alternative rural/urban definitions**: USDA RUCC codes (9-level) vs. binary MSA
3. **Wave-specific analysis**: Run separate models by wave to assess temporal stability
4. **Alternative ML specifications**: Compare GRF with BART and Double Machine Learning
5. **Omitted variable bias**: Oster (2019) coefficient stability test
6. **Bootstrap confidence intervals**: 1,000 replications for all key estimates
