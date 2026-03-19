# Bowling Alone, Scrolling Together

## Social Isolation and the Generational Divide in Volunteering

**Authors**: Hosung You & Suzanna R. Windon, The Pennsylvania State University

**Target Journal**: *Nonprofit and Voluntary Sector Quarterly* (NVSQ)

### Research Questions

**RQ1** (Variable-Centered): How does the association between in-person socialization frequency and volunteering differ across generational cohorts, and do education, employment, civic social media use, and the COVID-19 pandemic moderate this association differently by generation?

**RQ2** (Person-Centered): What distinct civic engagement profiles emerge from latent profile analysis, and how are generational cohorts distributed across these profiles?

### Key Findings

- **First Step Effect**: Across all five generations, the transition from no socialization to minimal contact is associated with the largest marginal gain in volunteering probability (7-10 pp) — comparable in magnitude to the education gradient (BA+ vs. no BA)
- **Gen Z Plateau**: Beyond moderate socialization, Gen Z's volunteering probability plateaus — a pattern absent in all older cohorts — yet Gen Z's baseline volunteering probability at zero socialization (27.3%) exceeds every older generation
- **Temporal Stability**: These patterns are present before COVID-19 and unchanged afterward, establishing them as cohort characteristics rather than pandemic artifacts
- **Social Disconnection**: Over half of Gen Z (50.6%) occupies civic engagement profiles defined by social isolation, while only 3.7% reaches Fully Engaged status

### Analytic Strategy

```
Stage 1: Survey-Weighted Logistic Regression (RQ1)
   Socialization x Generation interactions
   Three-way interactions (x Education, x Employment, x Civic SM, x COVID)
   Average Marginal Effects (First Step Effect)
   ↓
Stage 2: Latent Profile Analysis (RQ2)
   6-profile solution (EII parameterization)
   Generational distribution, volunteering rates, pre/post-COVID stability
```

### Repository Structure

```
.
├── README.md
├── code/
│   ├── 00_data_preparation.R              # Data acquisition and cleaning
│   ├── 01_descriptive_analysis.R          # Exploratory cross-tabulations
│   ├── 02_logistic_regression.R           # Primary analysis (RQ1)
│   ├── 03_latent_profile_analysis.R       # Person-centered analysis (RQ2)
│   ├── 05_robustness_checks.R             # Sensitivity analyses
│   ├── 11_conceptual_framework.py         # Conceptual framework figure
│   ├── 12_improved_figures.R              # Improved publication figures
│   ├── 13_publication_figures.R           # Final publication-quality figures
│   ├── 14_apa_tables.R                    # APA-formatted table generation
│   └── 15_additional_tables.R             # Supplementary tables
├── paper/                                 # Manuscript sections (Markdown → DOCX)
│   ├── 00_abstract.md
│   ├── 01_introduction.md
│   ├── 02_theoretical_framework.md
│   ├── 02a_purpose_rq.md
│   ├── 03_method.md
│   ├── 04_results.md
│   ├── 05_discussion.md
│   ├── build_docx.py                      # Markdown → APA 7th DOCX converter
│   └── Bowling_Alone_CLEAN.docx           # Compiled manuscript
├── figures/
│   ├── conceptual_framework.png           # Fig 1: Conceptual framework
│   ├── fig1_pred_prob.png                 # Fig 2: Predicted probabilities
│   ├── fig4_ame_first_step.png            # Fig 3: First Step Effect AMEs
│   ├── fig2_lpa_heatmap.png               # Fig 4: LPA profile heatmap
│   └── fig3_lpa_gen_dist.png              # Fig 5: Generational distribution
├── tables/
│   ├── table1_sample_characteristics.csv  # Table 1: Sample characteristics
│   ├── table2_regression.csv              # Table 2: Logistic regression
│   ├── table3_first_step_ame.csv          # Table 3: First Step AMEs
│   ├── table4_lpa_fit.csv                 # Table 4: LPA model fit
│   ├── table5_lpa_profiles.csv            # Table 5: LPA profiles
│   ├── table_gen_wave.csv                 # Table 6: Generation x wave rates
│   └── table_covid_3period.csv            # Supplementary: COVID periods
├── data/
│   ├── cps_00001.pdf                      # IPUMS codebook
│   └── cps_00002.csv.gz                   # IPUMS CPS extract (compressed)
├── references/                            # Reference PDFs
├── scripts/                               # Manuscript revision helper scripts
├── discussion/                            # Collaboration documents
└── archive/v1_rural_urban_design/         # Original PA-focused design (preserved)
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

- **R 4.4+**: `survey`, `mclust`, `marginaleffects`, `tidyverse`, `ipumsr`
- **Python 3.11+**: `python-docx` (manuscript build)

### Project History

| Date | Milestone |
|------|-----------|
| 2026-02-24 | Initial collaboration proposal to Dr. Windon |
| 2026-03-03 | Pivot from PA-focused to national scope based on exploratory findings |
| 2026-03-04 | "Bowling Alone, Scrolling Together" proposal with APA 7th citations |
| 2026-03-09 | Research framework finalized: 2 RQs, 3-stage analysis, NVSQ target |
| 2026-03-19 | Major revision: streamlined to 2-method design (regression + LPA), removed ML/SHAP, added conceptual framework, expanded tables (6), publication figures (5), APA 7th DOCX build |

### License

This project is for academic research purposes.
