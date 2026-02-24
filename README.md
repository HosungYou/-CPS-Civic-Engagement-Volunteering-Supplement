# CPS Civic Engagement & Volunteering Supplement (CEV) Study

## Heterogeneous Effects of Organized Volunteering on Civic Engagement Across Rural and Urban America: A Three-Phase Machine Learning Approach

### Authors
- **Hosung You** (First Author — Methodological Contribution)
- **Suzanna Windon, Ph.D.** (The Pennsylvania State University)

### Overview
This study introduces a three-phase analytical framework combining **Latent Profile Analysis (LPA)**, **Causal Forest (GRF)**, and **SHAP (SHapley Additive exPlanations)** to examine heterogeneous effects of organized volunteering on civic engagement using four waves of the CPS-CEV (2017-2023).

### Repository Structure

```
.
├── README.md                          # Project overview
├── 01_Analysis_Design.md              # Full analysis design document
├── 02_Manuscript_Draft.md             # Manuscript draft (Markdown)
├── 02_Manuscript_Draft.docx           # Manuscript draft (Word)
├── 01_Analysis_Design.docx            # Analysis design (Word)
├── code/
│   ├── 00_data_acquisition.R          # CPS-CEV data download and cleaning
│   ├── 01_descriptive_analysis.R      # Descriptive statistics and EDA
│   ├── 02_latent_profile_analysis.R   # Phase 1: LPA
│   ├── 03_causal_forest.R            # Phase 2: Causal Forest (GRF)
│   ├── 04_shap_analysis.py           # Phase 3: SHAP visualization
│   └── 05_robustness_checks.R        # Sensitivity analyses
├── figures/                           # Output figures
└── data/                              # Data directory (not tracked)
```

### Three-Phase Framework

```
Phase 1: LPA          →  Phase 2: Causal Forest  →  Phase 3: SHAP
"Who are they?"           "What works for whom?"      "Why?"
Civic engagement          Heterogeneous causal        Interpretable
typology                  effects estimation          decomposition
```

### Data
- **Source**: CPS Civic Engagement & Volunteering Supplement (CEV)
- **Waves**: 2017, 2019, 2021, 2023
- **Access**: [IPUMS CPS](https://cps.ipums.org) | [AmeriCorps Data](https://data.americorps.gov)

### Software Requirements
- R 4.4+ with packages: `tidyLPA`, `grf`, `survey`, `ipumsr`, `tidyverse`
- Python 3.11+ with packages: `shap`, `matplotlib`, `seaborn`, `geopandas`

### Target Journal
- *Nonprofit and Voluntary Sector Quarterly* (Primary)
- *Voluntas* (Secondary)

### License
This project is for academic research purposes.
