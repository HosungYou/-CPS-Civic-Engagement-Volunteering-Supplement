# Bowling Alone, Scrolling Together

## Social Isolation and the Generational Divide in Volunteering

**Authors**: Hosung You & Suzanna R. Windon, The Pennsylvania State University

**Target Journal**: *Nonprofit and Voluntary Sector Quarterly* (NVSQ)

### Research Questions

**RQ1**: How does the relationship between in-person socialization frequency and volunteering differ across generational cohorts, and does this relationship exhibit nonlinear threshold effects?

**RQ2**: To what extent do education, employment, and civic social media use moderate the association between social isolation and volunteering, and does this moderation differ by generation?

### Key Findings (Exploratory)

- Nearly half of Gen Z adults (47%) report rarely or never socializing in person — predating COVID-19
- The "first step" from no socialization to minimal contact corresponds to the largest gain in volunteering (10–14 pp) across all generations
- Education and employment do not resolve Gen Z's socialization deficit
- Civic social media compensates for older adults' isolation (+11 pp for Boomers) but not Gen Z's (+5.5 pp)

### Analysis Framework

```
Stage 1: Descriptive Cross-tabulations (complete)
   ↓
Stage 2: Survey-Weighted Logistic Regression (PRIMARY)
   Socialization × Generation interactions
   Three-way interactions (× Education, × Social Media)
   ↓
Stage 3: Supplementary Analyses
   A. Latent Profile Analysis (4–6 civic engagement profiles)
   B. Gradient Boosting Machines + SHAP (nonlinear validation)
```

### Repository Structure

```
.
├── README.md
├── code/
│   ├── 00_data_preparation.R           # Data acquisition and cleaning
│   ├── 01_descriptive_analysis.R       # Exploratory cross-tabulations
│   ├── 02_logistic_regression.R        # Primary analysis (RQ1 & RQ2)
│   ├── 03_latent_profile_analysis.R    # Supplementary: LPA
│   ├── 04_gbm_shap_analysis.py        # Supplementary: GBM + SHAP
│   └── 05_robustness_checks.R         # Sensitivity analyses
├── paper/                              # Manuscript sections
│   ├── 01_introduction.md
│   ├── 02_theoretical_framework.md
│   ├── 03_method.md
│   ├── 04_results.md
│   └── 05_discussion.md
├── discussion/                         # Collaboration documents (date-themed)
│   ├── 01_0224_Initial-Collaboration-Proposal_Email-Draft.md
│   ├── 02–09: Meeting docs, coding decisions, proposals
│   └── 10_0309_Research-Overview_Analysis-Framework-and-Predicted-Results.md
├── figures/                            # Output figures
├── data/                               # Data files (CSV not tracked per IPUMS terms)
│   ├── cps_00001.pdf                   # IPUMS codebook
│   └── cps_00002.csv                   # IPUMS CPS extract (N=450K, 46 vars)
├── references/                         # Reference PDFs
└── archive/v1_rural_urban_design/      # Original PA-focused design (preserved)
```

### Data

| Attribute | Detail |
|-----------|--------|
| Source | CPS Civic Engagement & Volunteering Supplement (CPS-CEV) |
| Provider | U.S. Census Bureau + AmeriCorps via [IPUMS CPS](https://cps.ipums.org) |
| Waves | September 2017, 2019, 2021, 2023 |
| Analytic N | 201,168 (U.S. adults 18+, valid supplement weight) |
| Weight | VLSUPPWT |

### Software

- **R 4.4+**: `survey`, `tidyLPA`, `tidyverse`, `ipumsr`, `marginaleffects`
- **Python 3.11+**: `xgboost`, `shap`, `matplotlib`, `seaborn`

### Project History

| Date | Milestone |
|------|-----------|
| 2026-02-24 | Initial collaboration proposal to Dr. Windon |
| 2026-03-03 | Meeting document, operational definitions, coding error discovery |
| 2026-03-03 | Pivot from PA-focused to national scope based on exploratory findings |
| 2026-03-04 | "Bowling Alone, Scrolling Together" proposal with APA 7th citations |
| 2026-03-09 | Research framework finalized: 2 RQs, 3-stage analysis, NVSQ target |

### License

This project is for academic research purposes.
