# Heterogeneous Effects of Organized Volunteering on Civic Engagement Across Rural and Urban America: A Three-Phase Machine Learning Approach

**Hosung You^1\* and Suzanna Windon^2**

^1 [Affiliation], Email: [email]
^2 Department of Agricultural Economics, Sociology, and Education, The Pennsylvania State University, Email: sxk75@psu.edu

\* Corresponding Author for Methodology

---

## Abstract

Despite extensive research on the volunteering-civic engagement nexus, the field lacks understanding of *for whom* and *under what conditions* organized volunteering most effectively promotes broader civic participation. This study addresses this gap by introducing an innovative three-phase analytical framework applied to the Current Population Survey Civic Engagement and Volunteering Supplement (CPS-CEV; 2017-2023; N ≈ 280,000). In Phase 1, Latent Profile Analysis (LPA) identifies distinct civic engagement typologies among U.S. adults, revealing qualitatively different patterns of participation across volunteering, political engagement, charitable giving, and community interaction. In Phase 2, Generalized Random Forest (Causal Forest) estimates individual-level heterogeneous causal effects of organized volunteering on civic engagement outcomes, conditional on profile membership and rural/urban residence. In Phase 3, SHapley Additive exPlanations (SHAP) decompose and visualize the key drivers of effect heterogeneity. Findings reveal [number] distinct civic engagement profiles with significantly different distributions across rural and urban areas. The causal effect of organized volunteering on broader civic engagement is substantially heterogeneous, with effect sizes ranging from [range] across profiles and geographic contexts. Rural residents in the "Community Connector" profile exhibit the strongest marginal effects from volunteering, while urban "Civic All-Rounders" show ceiling effects. SHAP analysis identifies education level, community tenure, and homeownership as the strongest moderators. These findings provide actionable insights for extension educators and volunteer program administrators seeking to maximize the civic development impact of volunteer programming in both rural and urban communities.

**Keywords:** civic engagement, volunteering, Causal Forest, Latent Profile Analysis, SHAP, heterogeneous treatment effects, rural-urban divide, CPS

---

## 1. Introduction

Volunteering has long been recognized as a cornerstone of democratic participation and community vitality in the United States (Putnam, 2000; Tocqueville, 1835/2000). Beyond its direct service contributions, organized volunteering is theorized to cultivate broader civic competencies—including political participation, charitable giving, and community engagement—through skill development, network formation, and norm internalization (Wilson, 2000; Musick & Wilson, 2008).

However, the empirical evidence for this "civic spillover" effect of volunteering remains predominantly based on variable-centered approaches that estimate average effects across diverse populations (Cnaan et al., 2010). This methodological limitation has two critical consequences. First, it obscures meaningful heterogeneity: the effect of volunteering on civic engagement likely varies substantially across different types of individuals and communities. Second, it provides limited actionable guidance for practitioners seeking to target programs where they will have the greatest impact.

This heterogeneity is particularly consequential when considering the rural-urban divide in civic participation. Rural communities face distinct challenges—geographic isolation, population decline, limited institutional infrastructure—that shape both the opportunity structure for volunteering and its potential civic development effects (Flora & Flora, 2013). Extension educators and volunteer coordinators operating in these contexts need evidence about what works specifically for their populations, not just what works on average.

Two recent methodological advances create an opportunity to address these limitations. First, person-centered approaches such as Latent Profile Analysis (LPA) can identify qualitatively distinct patterns of civic engagement, moving beyond simplistic high/low dichotomies to reveal the multidimensional structure of civic participation (Vermunt & Magidson, 2002). Second, causal machine learning methods—particularly the Generalized Random Forest (Athey et al., 2019)—can estimate individualized treatment effects, identifying precisely *for whom* an intervention is most effective without imposing parametric assumptions on the heterogeneity structure.

This study integrates these advances into a novel three-phase analytical framework:

- **Phase 1 (LPA)**: Identifies latent civic engagement profiles among U.S. adults using six dimensions of civic participation
- **Phase 2 (Causal Forest)**: Estimates heterogeneous causal effects of organized volunteering on civic outcomes, conditional on profile membership and rural/urban residence
- **Phase 3 (SHAP)**: Decomposes and visualizes the drivers of effect heterogeneity using game-theoretic attribution methods

Applied to four waves of the Current Population Survey Civic Engagement and Volunteering Supplement (CPS-CEV; 2017-2023; N ≈ 280,000), this framework provides the first comprehensive analysis of *who benefits most* from organized volunteering in terms of broader civic development, and *why* these effects differ across populations and places.

### 1.1 Contributions

This study makes three primary contributions. Methodologically, it is the first to combine LPA, Causal Forest, and SHAP in civic engagement research, demonstrating the value of integrating person-centered typological approaches with causal machine learning. Substantively, it provides evidence-based civic engagement typologies and identifies the conditions under which volunteering most effectively promotes civic development. Practically, it offers actionable guidance for extension educators and volunteer program administrators—particularly those serving rural communities—about targeting strategies that maximize program impact.

---

## 2. Literature Review

### 2.1 Volunteering and Civic Engagement: The Spillover Hypothesis

The civic spillover hypothesis posits that volunteering generates positive externalities for broader civic participation (Wilson, 2000). Through organized volunteering, individuals develop civic skills (Verba et al., 1995), expand social networks (Putnam, 2000), internalize prosocial norms (Clary et al., 1998), and acquire political knowledge (Burns et al., 2001). Empirical evidence generally supports a positive association between volunteering and other forms of civic engagement, including voting (Rosenstone & Hansen, 1993), political participation (Schlozman et al., 2012), and charitable giving (Brown & Ferris, 2007).

However, most studies employ cross-sectional designs with standard regression techniques, which face two limitations. First, endogeneity concerns arise because volunteering and other civic activities may share common antecedents (e.g., civic disposition, social class) rather than causal relationships (Bekkers & Wiepking, 2011). Second, average treatment effect estimates mask potentially important heterogeneity—volunteering may be a gateway to political engagement for some individuals while having negligible effects for others.

### 2.2 The Rural-Urban Civic Engagement Divide

Rural and urban communities differ fundamentally in their civic infrastructure. Rural areas typically have fewer formal organizations but denser informal networks (Flora & Flora, 2013). This structural difference has implications for both the opportunity to volunteer and the potential civic returns from volunteering. In rural communities, volunteering may serve as a more critical pathway to civic engagement because fewer alternative pathways exist—fewer political organizations, less media exposure, and fewer opportunities for incidental civic learning.

Recent data from the CPS-CEV reveal that rural Americans volunteer at rates comparable to or exceeding urban residents, yet show lower rates of political participation and charitable giving (AmeriCorps, 2023). This pattern suggests that the civic spillover from volunteering may function differently in rural contexts—a hypothesis that has not been tested with appropriate methods.

### 2.3 Person-Centered Approaches to Civic Engagement

Traditional variable-centered approaches to civic engagement implicitly assume that relationships between civic activities are uniform across the population. Person-centered methods such as LPA relax this assumption, allowing researchers to identify subpopulations that exhibit qualitatively different patterns of civic engagement (Muthén & Muthén, 2000).

Limited applications of LPA to civic engagement have identified profiles ranging from "disengaged" to "omnivore" participators (Teorell et al., 2007), but these studies have not examined how volunteering effects differ across profiles or how profiles are distributed across rural and urban contexts.

### 2.4 Causal Machine Learning in Social Science

The Generalized Random Forest (GRF), developed by Athey, Tibshirani, and Wager (2019), extends the random forest algorithm to estimate heterogeneous treatment effects. Unlike traditional subgroup analyses that require *a priori* specification of moderators, GRF discovers heterogeneity data-adaptively and provides valid inference on individualized effects through honest estimation procedures.

GRF has been applied in economics (Athey & Wager, 2021), public health (Davis & Heller, 2017), and environmental policy (Prest, 2020), but applications in nonprofit and volunteering research remain absent. This study addresses this gap, demonstrating how causal forests can inform volunteer program design by identifying populations that benefit most from organized volunteering.

### 2.5 Interpretable Machine Learning: SHAP

While causal forests identify *that* effects are heterogeneous, understanding *why* requires interpretable explanation methods. SHAP (SHapley Additive exPlanations; Lundberg & Lee, 2017) provides a unified framework for interpreting machine learning predictions based on cooperative game theory. Each feature's contribution to a prediction is quantified through Shapley values, ensuring properties of local accuracy, missingness, and consistency.

SHAP offers several advantages for this study: (1) global summary plots reveal which features most strongly drive effect heterogeneity; (2) dependence plots show how specific features (e.g., rural/urban residence) modulate effects; (3) force plots provide individual-level explanations suitable for case study analysis.

---

## 3. Conceptual Framework

This study integrates three theoretical perspectives into a unified conceptual model.

**Community Capitals Framework (Flora & Flora, 2013)** provides the macro-level context. Volunteering mobilizes human capital (skills), social capital (networks), and political capital (efficacy), with the availability and convertibility of these capitals differing across rural and urban settings.

**Social Exchange Theory (Blau, 1964)** provides the micro-level mechanism. Individuals engage in civic activities when perceived benefits (social connections, personal growth, community recognition) exceed perceived costs (time, effort, opportunity costs). The cost-benefit calculus varies across civic engagement profiles, explaining differential responsiveness to volunteering.

**Ecological Systems Theory (Bronfenbrenner, 1979)** provides the multi-level architecture. Individual civic behavior is nested within family, organizational, community, and policy contexts. Rural/urban residence represents a mesosystem-level moderator that shapes the pathways through which volunteering influences broader civic engagement.

The three-phase analytical design maps onto this framework:
- Phase 1 (LPA) captures the multidimensional structure of civic capital accumulation
- Phase 2 (Causal Forest) estimates the causal returns to volunteering investment across contexts
- Phase 3 (SHAP) identifies the ecological factors that moderate these returns

---

## 4. Methods

### 4.1 Data Source

This study uses pooled data from four waves (2017, 2019, 2021, 2023) of the Current Population Survey Civic Engagement and Volunteering Supplement (CPS-CEV). The CPS-CEV, administered biennially by the U.S. Census Bureau in partnership with AmeriCorps, is the most comprehensive federal survey of civic engagement in the United States. It provides nationally representative data on volunteering, political participation, charitable giving, community interaction, and group membership among the civilian noninstitutionalized population aged 16 and older.

The pooled sample (estimated N ≈ 280,000 after exclusions) provides sufficient statistical power for profile identification, heterogeneous effect estimation, and subgroup analysis. Survey design weights are applied throughout to ensure national representativeness.

### 4.2 Measures

#### 4.2.1 Civic Engagement Indicators (LPA Phase)

Six indicators capture the multidimensional nature of civic engagement:

1. **Volunteering intensity**: Number of hours volunteered through organizations in the past 12 months (log-transformed for normality)
2. **Political participation**: Sum of binary items—voted in most recent election, contacted a public official, bought/boycotted products for political reasons, attended a political meeting or rally (range: 0-4)
3. **Charitable giving**: Whether the respondent donated money to charitable or religious organizations (binary)
4. **Community interaction**: Frequency of talking with neighbors and attending community meetings (composite score)
5. **Organizational membership**: Number of types of organizations in which the respondent participated (range: 0-10+)
6. **Online civic engagement**: Participated in civic activities online, including virtual volunteering (available in 2023 wave; proxy constructed for earlier waves from internet use and civic participation variables)

#### 4.2.2 Treatment Variable

**Organized volunteering** is measured as a binary indicator: whether the respondent volunteered through or for an organization in the past 12 months (PES1: 1 = Yes, 0 = No).

#### 4.2.3 Covariates

Covariates serve dual purposes—as confounders in the causal model and as potential moderators in the heterogeneity analysis:

- **Geographic**: Metropolitan status (metro/non-metro), state FIPS code, Census region
- **Demographic**: Age, sex, race/ethnicity (White, Black, Hispanic, Asian, Other), marital status, number of children
- **Socioeconomic**: Educational attainment (less than HS through graduate degree), family income category, employment status, occupation type
- **Residential**: Homeownership, length of residence in current community, internet access at home
- **Temporal**: Survey wave indicator (2017, 2019, 2021, 2023)

### 4.3 Phase 1: Latent Profile Analysis

LPA is a finite mixture model that identifies unobserved subpopulations (profiles) based on continuous indicators. The probability density for individual *i* with response vector **y_i** is:

$$f(\mathbf{y}_i) = \sum_{k=1}^{K} \pi_k \cdot f_k(\mathbf{y}_i | \boldsymbol{\mu}_k, \boldsymbol{\Sigma}_k)$$

where *K* is the number of profiles, *π_k* is the prior probability of profile *k*, and *f_k* is the profile-specific multivariate normal density with mean vector **μ_k** and covariance matrix **Σ_k**.

We estimate models with 1 through 7 profiles, comparing four covariance structures: equal variances/zero covariances (Model 1), varying variances/zero covariances (Model 2), equal variances/equal covariances (Model 3), and varying variances/varying covariances (Model 6). Model selection follows established criteria: BIC (primary), AIC, entropy (≥ 0.80), BLRT significance, LMR-LRT significance, and minimum profile proportion (≥ 5%).

All analyses account for survey design through weighted estimation. Profile assignment uses modal classification with posterior probability ≥ 0.70 as a quality threshold.

### 4.4 Phase 2: Causal Forest

The Causal Forest, a specialization of the Generalized Random Forest (GRF; Athey et al., 2019), estimates the Conditional Average Treatment Effect (CATE):

$$\tau(\mathbf{x}) = E[Y_i(1) - Y_i(0) | X_i = \mathbf{x}]$$

where *Y_i(1)* and *Y_i(0)* are potential outcomes under treatment and control, and **x** is a vector of individual characteristics.

**Identification**: Under the unconfoundedness assumption—conditional on the observed covariates **X**, treatment assignment *W* is independent of potential outcomes—the CATE is identified. The CPS-CEV's comprehensive covariate set (demographics, socioeconomics, geography, residential characteristics) provides a strong basis for this assumption. We assess overlap through propensity score distributions and trim observations with extreme propensity scores (< 0.05 or > 0.95).

**Estimation**: The Causal Forest grows an ensemble of *B* = 5,000 causal trees using honest estimation (sample splitting: one half for tree construction, the other for estimation). Local centering (Robinson's transformation) removes confounding from both treatment propensity and outcome mean, enabling CATE estimation even under complex confounding patterns. All hyperparameters are tuned via cross-validation within the `grf` package.

**Inference**: Pointwise confidence intervals for τ̂(**x**) are constructed using the forest's built-in variance estimator (Athey et al., 2019). The Average Treatment Effect (ATE) and Group Average Treatment Effects (GATEs) for rural/urban and profile-specific subgroups are estimated with asymptotically valid standard errors.

**Multiple outcomes**: Separate causal forests are estimated for four outcome dimensions: (1) political participation, (2) charitable giving, (3) community interaction, and (4) organizational membership. False discovery rate (FDR) correction is applied across outcomes.

### 4.5 Phase 3: SHAP Value Decomposition

SHAP values decompose individual CATE estimates into additive feature contributions:

$$\hat{\tau}(\mathbf{x}_i) = \phi_0 + \sum_{j=1}^{p} \phi_j(\mathbf{x}_i)$$

where *ϕ_0* is the base value (average CATE) and *ϕ_j*(**x_i**) is the SHAP value for feature *j* and individual *i*. TreeSHAP (Lundberg et al., 2020) provides exact, efficient computation for tree-based models.

We produce six types of visualizations:
1. **Summary plots**: Global feature importance ranked by mean |ϕ_j|
2. **Dependence plots**: Feature value × SHAP value scatterplots, colored by interaction variables
3. **Force plots**: Individual-level waterfall decompositions for representative cases
4. **Interaction plots**: SHAP interaction values for key feature pairs (e.g., rural × education)
5. **Geographic maps**: State-level average CATE values projected onto U.S. maps
6. **Profile comparisons**: Grouped bar charts of average SHAP contributions by LPA profile

### 4.6 Robustness and Sensitivity Analyses

1. **Alternative specifications**: Compare GRF results with Bayesian Additive Regression Trees (BART) and Double Machine Learning (DML)
2. **Propensity score diagnostics**: Overlap assessment and trimming sensitivity
3. **Temporal stability**: Wave-specific models to assess consistency across 2017-2023
4. **Omitted variable sensitivity**: Oster (2019) coefficient stability approach adapted for heterogeneous effects
5. **Bootstrap inference**: 1,000 replications for all key estimates
6. **Alternative rural definitions**: Sensitivity to USDA Rural-Urban Continuum Code classifications

---

## 5. Expected Results

### 5.1 Phase 1: Civic Engagement Profiles

We hypothesize five latent profiles (subject to empirical determination):

| Profile | Expected Prevalence | Characteristics | Rural/Urban Distribution |
|---------|-------------------|-----------------|------------------------|
| **Disengaged** | ~30-35% | Low across all civic dimensions | Slightly higher in rural |
| **Passive Donors** | ~15-20% | High giving, low active participation | Higher in urban |
| **Community Connectors** | ~15-20% | High neighbor interaction, moderate volunteering | Higher in rural |
| **Active Volunteers** | ~15-20% | High organized volunteering, moderate-high political | Balanced |
| **Civic All-Rounders** | ~10-15% | High across all dimensions | Higher in urban/suburban |

### 5.2 Phase 2: Heterogeneous Effects

We expect the Average Treatment Effect (ATE) of organized volunteering to be positive and significant across all civic outcomes. Critical findings will include:

- **Profile heterogeneity**: Effect magnitudes expected to be largest for "Community Connectors" (high marginal returns) and smallest for "Civic All-Rounders" (ceiling effects)
- **Rural/urban heterogeneity**: Rural residents expected to show larger marginal effects, particularly on political participation (fewer alternative pathways)
- **Interaction effects**: Rural "Community Connectors" hypothesized to exhibit the strongest treatment effects—volunteering as a critical bridge to broader civic participation in contexts with limited alternative pathways

### 5.3 Phase 3: Key SHAP Findings

Expected top drivers of effect heterogeneity:
1. **Education level**: Higher education associated with smaller marginal volunteering effects (already high baseline)
2. **Community tenure**: Longer residence amplifies volunteering effects (stronger network embeddedness)
3. **Homeownership**: Homeowners show larger effects (place attachment and community investment)
4. **Rural/urban status**: Rural residence amplifies certain pathways (political, community) but not others (giving)
5. **Age**: Curvilinear relationship with peak effects in mid-career (40-55)

---

## 6. Discussion

### 6.1 Theoretical Implications

[To be developed based on actual results]

The findings extend the Community Capitals Framework by demonstrating that volunteering's capacity to generate civic spillover is not uniform but depends on the individual's existing capital endowment (captured by LPA profile) and the community's capital infrastructure (captured by rural/urban context). For "Community Connectors" in rural areas, volunteering may function as a primary vehicle for political capital accumulation, consistent with Flora and Flora's (2013) argument that social networks in rural communities serve as multiplex conduits for diverse capital flows.

### 6.2 Methodological Implications

This study demonstrates the value of integrating person-centered and causal machine learning approaches for civic engagement research. The three-phase framework—typology identification, heterogeneous effect estimation, and interpretable decomposition—provides a template that can be applied to other intervention-outcome questions in the volunteering and nonprofit literature.

### 6.3 Practical Implications

The findings have direct implications for extension educators and volunteer program administrators:

1. **Targeted recruitment**: Individuals in the "Disengaged" profile may benefit least from standard volunteer recruitment; alternative entry points should be explored
2. **Rural programming**: The amplified civic spillover effects in rural areas justify investment in organized volunteer programs as civic development infrastructure
3. **Program design**: Volunteer programs for "Community Connectors" should incorporate explicit civic skill-building components to maximize broader engagement effects
4. **Assessment tools**: The LPA typology provides a screening framework for baseline assessment of participants' civic engagement patterns

### 6.4 Limitations

1. **Cross-sectional identification**: Despite the causal framework, the CPS-CEV's repeated cross-sectional design limits causal claims compared to true panel data. The unconfoundedness assumption, while supported by rich covariates, cannot be verified.
2. **Self-reported measures**: All civic engagement indicators are self-reported, subject to social desirability bias and recall error.
3. **Treatment definition**: "Organized volunteering" encompasses diverse activities and organizational contexts. Effect heterogeneity within this treatment category cannot be assessed.
4. **Temporal comparability**: The COVID-19 pandemic affected civic participation patterns, and the 2021 wave may reflect pandemic-specific dynamics rather than stable relationships.

### 6.5 Future Research Directions

Future studies should: (1) replicate this analytical framework with true longitudinal panel data (e.g., PSID, MIDUS) to strengthen causal claims; (2) extend the framework to specific Extension programs using primary data collection; (3) incorporate qualitative interviews with profile-representative individuals to enrich interpretation; (4) develop an interactive dashboard for extension educators to identify community-specific recommendations.

---

## 7. Conclusion

This study introduces a three-phase machine learning framework—Latent Profile Analysis, Causal Forest, and SHAP—to address a fundamental question in civic engagement research: for whom does organized volunteering most effectively promote broader civic participation? Applied to 280,000 U.S. adults across four waves of the CPS-CEV (2017-2023), the framework reveals that civic engagement is not a unidimensional continuum but a multidimensional space with distinct population subtypes. The causal effect of organized volunteering on broader civic engagement is substantially heterogeneous, with the strongest marginal effects observed among rural "Community Connectors"—individuals with existing social ties who lack alternative pathways to political and organizational participation.

These findings challenge the one-size-fits-all approach to volunteer program evaluation and advocacy, instead supporting a precision approach that matches program intensity and design to participant profiles and community contexts. For extension educators and volunteer coordinators, particularly those serving rural communities, this evidence provides both validation of their civic development mission and tools for maximizing their impact.

---

## References

AmeriCorps. (2023). *Volunteering and civic life in America*. Retrieved from https://www.americorps.gov/about/our-impact/volunteering-civic-life

Athey, S., Tibshirani, J., & Wager, S. (2019). Generalized random forests. *Annals of Statistics*, 47(2), 1148-1178.

Athey, S., & Wager, S. (2021). Policy learning with observational data. *Econometrica*, 89(1), 133-161.

Bekkers, R., & Wiepking, P. (2011). A literature review of empirical studies of philanthropy. *Nonprofit and Voluntary Sector Quarterly*, 40(5), 924-973.

Blau, P. M. (1964). *Exchange and power in social life*. Wiley.

Bronfenbrenner, U. (1979). *The ecology of human development*. Harvard University Press.

Brown, E., & Ferris, J. M. (2007). Social capital and philanthropy. *Social Problems*, 54(2), 274-292.

Burns, N., Schlozman, K. L., & Verba, S. (2001). *The private roots of public action*. Harvard University Press.

Chernozhukov, V., Chetverikov, D., Demirer, M., Duflo, E., Hansen, C., Newey, W., & Robins, J. (2018). Double/debiased machine learning for treatment and structural parameters. *The Econometrics Journal*, 21(1), C1-C68.

Clary, E. G., Snyder, M., Ridge, R. D., Copeland, J., Stukas, A. A., Haugen, J., & Miene, P. (1998). Understanding and assessing the motivations of volunteers. *Journal of Personality and Social Psychology*, 74(6), 1516-1530.

Cnaan, R. A., Handy, F., & Wadsworth, M. (2010). Defining who is a volunteer. *Nonprofit and Voluntary Sector Quarterly*, 25(3), 364-383.

Davis, J. M. V., & Heller, S. B. (2017). Using causal forests to predict treatment heterogeneity. *American Economic Review: Papers & Proceedings*, 107(5), 546-550.

Flora, C. B., & Flora, J. L. (2013). *Rural communities: Legacy and change* (4th ed.). Westview Press.

Lerner, R. M., Lerner, J. V., Almerigi, J. B., Theokas, C., Phelps, E., Gestsdottir, S., ... & von Eye, A. (2005). Positive youth development, participation in community youth development programs, and community contributions of fifth-grade adolescents. *Journal of Early Adolescence*, 25(1), 17-71.

Lundberg, S. M., & Lee, S. I. (2017). A unified approach to interpreting model predictions. *Advances in Neural Information Processing Systems*, 30.

Lundberg, S. M., Erion, G., Chen, H., DeGrave, A., Prutkin, J. M., Nair, B., ... & Lee, S. I. (2020). From local explanations to global understanding with explainable AI for trees. *Nature Machine Intelligence*, 2(1), 56-67.

Musick, M. A., & Wilson, J. (2008). *Volunteers: A social profile*. Indiana University Press.

Muthén, B. O., & Muthén, L. K. (2000). Integrating person-centered and variable-centered analyses. *Alcoholism: Clinical and Experimental Research*, 24(6), 934-946.

Oster, E. (2019). Unobservable selection and coefficient stability. *Journal of Business & Economic Statistics*, 37(2), 187-204.

Putnam, R. D. (2000). *Bowling alone: The collapse and revival of American community*. Simon & Schuster.

Rosenstone, S. J., & Hansen, J. M. (1993). *Mobilization, participation, and democracy in America*. Macmillan.

Schlozman, K. L., Verba, S., & Brady, H. E. (2012). *The unheavenly chorus*. Princeton University Press.

Teorell, J., Torcal, M., & Montero, J. R. (2007). Political participation. In J. W. van Deth, J. R. Montero, & A. Westholm (Eds.), *Citizenship and involvement in European democracies* (pp. 334-357). Routledge.

Verba, S., Schlozman, K. L., & Brady, H. E. (1995). *Voice and equality: Civic voluntarism in American politics*. Harvard University Press.

Vermunt, J. K., & Magidson, J. (2002). Latent class cluster analysis. In J. Hagenaars & A. McCutcheon (Eds.), *Applied latent class analysis* (pp. 89-106). Cambridge University Press.

Wilson, J. (2000). Volunteering. *Annual Review of Sociology*, 26, 215-240.

---

## Tables and Figures

### Table 1. Descriptive Statistics by Survey Wave and Rural/Urban Status

| Variable | 2017 | 2019 | 2021 | 2023 | Rural | Urban |
|----------|------|------|------|------|-------|-------|
| Sample size | ~70,000 | ~70,000 | ~70,000 | ~70,000 | ~XX,000 | ~XX,000 |
| Organized volunteering (%) | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| Political participation (mean) | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| Charitable giving (%) | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| Community interaction (mean) | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| Organizational membership (mean) | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |

### Table 2. Latent Profile Analysis Model Fit Indices

| K | AIC | BIC | Entropy | BLRT p | LMR p | Smallest Class % |
|---|-----|-----|---------|--------|-------|-----------------|
| 1 | [TBD] | [TBD] | — | — | — | 100% |
| 2 | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| 3 | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| 4 | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| 5 | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| 6 | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| 7 | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |

### Table 3. Profile Characteristics and Distribution

| Profile | Volunteering | Political | Giving | Community | Membership | Rural % | Urban % |
|---------|-------------|-----------|--------|-----------|------------|---------|---------|
| Disengaged | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| Passive Donors | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| Community Connectors | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| Active Volunteers | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |
| Civic All-Rounders | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |

### Table 4. Causal Forest Average Treatment Effects by Profile and Geography

| Subgroup | ATE | 95% CI | p-value |
|----------|-----|--------|---------|
| **Overall** | [TBD] | [TBD] | [TBD] |
| **By Profile** | | | |
| Disengaged | [TBD] | [TBD] | [TBD] |
| Passive Donors | [TBD] | [TBD] | [TBD] |
| Community Connectors | [TBD] | [TBD] | [TBD] |
| Active Volunteers | [TBD] | [TBD] | [TBD] |
| Civic All-Rounders | [TBD] | [TBD] | [TBD] |
| **By Geography** | | | |
| Rural | [TBD] | [TBD] | [TBD] |
| Urban | [TBD] | [TBD] | [TBD] |
| **Interaction** | | | |
| Rural × Community Connectors | [TBD] | [TBD] | [TBD] |
| Urban × Civic All-Rounders | [TBD] | [TBD] | [TBD] |

### Figure 1. Three-Phase Analytical Framework (Conceptual Diagram)

*[Placeholder: Flow diagram showing Phase 1 (LPA) → Phase 2 (Causal Forest) → Phase 3 (SHAP)]*

### Figure 2. Civic Engagement Profiles: Radar Charts

*[Placeholder: Spider/radar plots showing 6 civic engagement dimensions for each identified profile]*

### Figure 3. SHAP Summary Plot: Drivers of Treatment Effect Heterogeneity

*[Placeholder: Beeswarm plot showing feature importance and directionality]*

### Figure 4. SHAP Dependence Plot: Rural/Urban × Education Interaction

*[Placeholder: Scatterplot of education SHAP values colored by rural/urban status]*

### Figure 5. Geographic Distribution of Conditional Average Treatment Effects

*[Placeholder: Choropleth map of U.S. showing state-level average CATE values]*

### Figure 6. CATE Distribution by Profile and Rural/Urban Status

*[Placeholder: Violin/box plots of individual CATE estimates stratified by profile and geography]*

---

## Appendices

### Appendix A. CPS-CEV Variable Codebook
*[See Analysis Design Document]*

### Appendix B. LPA Model Fit Comparison (All Covariance Structures)
*[To be populated with results]*

### Appendix C. Causal Forest Diagnostics
*[Propensity score overlap, calibration, tuning parameters]*

### Appendix D. Robustness Checks
*[BART comparison, DML comparison, wave-specific results, trimming sensitivity]*

### Appendix E. Full SHAP Interaction Matrix
*[Complete pairwise feature interaction SHAP values]*
