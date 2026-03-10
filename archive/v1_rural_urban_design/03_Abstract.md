# Research Abstract

## Heterogeneous Effects of Organized Volunteering on Civic Engagement Across Rural and Urban America: A Three-Phase Machine Learning Approach

**Hosung You¹ and Suzanna Windon²**

¹ Department of Agricultural Economics, Sociology, and Education, The Pennsylvania State University
² Department of Agricultural Economics, Sociology, and Education, The Pennsylvania State University

**Corresponding Author**: Hosung You (newhosung@gmail.com)

---

### Abstract

Despite extensive research on the volunteering–civic engagement nexus, the field lacks understanding of *for whom* and *under what conditions* organized volunteering most effectively promotes broader civic participation. This study addresses this gap by introducing an innovative three-phase analytical framework applied to the Current Population Survey Civic Engagement and Volunteering Supplement (CPS-CEV; 2017–2023; *N* ≈ 280,000).

In **Phase 1**, Latent Profile Analysis (LPA) identifies distinct civic engagement typologies among U.S. adults, revealing qualitatively different patterns of participation across volunteering, political engagement, charitable giving, and community interaction. In **Phase 2**, Generalized Random Forest (Causal Forest) estimates individual-level heterogeneous causal effects of organized volunteering on civic engagement outcomes, conditional on profile membership and rural/urban residence. In **Phase 3**, SHapley Additive exPlanations (SHAP) decompose and visualize the key drivers of effect heterogeneity.

This study integrates three theoretical perspectives—Community Capitals Framework, Social Exchange Theory, and Ecological Systems Theory—to explain why volunteering effects differ across populations and places. Methodologically, this is the first study to combine LPA, Causal Forest, and SHAP in civic engagement research, demonstrating the value of integrating person-centered typological approaches with causal machine learning. Substantively, it provides evidence-based civic engagement typologies and identifies the conditions under which volunteering most effectively promotes civic development. Practically, it offers actionable guidance for Extension educators and volunteer program administrators—particularly those serving rural communities—about targeting strategies that maximize program impact.

**Keywords**: civic engagement, volunteering, Causal Forest, Latent Profile Analysis, SHAP, heterogeneous treatment effects, rural-urban divide, Current Population Survey

---

### Research Design Summary

| Phase | Method | Purpose | Software |
|-------|--------|---------|----------|
| 1 | Latent Profile Analysis (LPA) | Identify civic engagement typologies | R (`tidyLPA`) |
| 2 | Causal Forest (GRF) | Estimate heterogeneous treatment effects | R (`grf`) |
| 3 | SHAP Values | Interpret and visualize effect drivers | Python (`shap`) |

### Data

- **Source**: Current Population Survey — Civic Engagement & Volunteering Supplement (CPS-CEV)
- **Waves**: September 2017, 2019, 2021, 2023
- **Sample**: ~280,000 U.S. adults (16+), nationally representative
- **Access**: IPUMS CPS (https://cps.ipums.org)

### Target Journal

- *Nonprofit and Voluntary Sector Quarterly* (Primary)
- *Voluntas: International Journal of Voluntary and Nonprofit Organizations* (Secondary)

### GitHub Repository

https://github.com/HosungYou/-CPS-Civic-Engagement-Volunteering-Supplement
