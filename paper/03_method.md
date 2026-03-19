# Method

<!-- Allocation: ~1,300 words (13%) -->

## Data Source and Sample

Data come from the Current Population Survey Civic Engagement and Volunteering Supplement (CPS-CEV), obtained via IPUMS-CPS (Flood et al., 2023). The CPS-CEV is administered as a supplement to the September CPS by the U.S. Census Bureau in collaboration with AmeriCorps. Approximately 57,000 households participate in each wave, making it the largest nationally representative survey measuring both volunteering behavior and civic engagement indicators simultaneously.

The CPS-CEV is uniquely suited to this study because it is the only nationally representative survey that simultaneously measures both volunteering behavior and in-person socialization frequency across a sample large enough to support subgroup analyses by generation. We pooled four waves of CPS-CEV data: September 2017, 2019, 2021, and 2023. These waves bracket the COVID-19 pandemic, allowing us to examine whether the socialization–volunteering relationship changed across this major disruption to social life. The analytic sample includes all U.S. adults aged 18 and older with valid supplement weights (VLSUPPWT > 0) and nonmissing values on the dependent variable (VLSTATUS ∈ {1, 2}), yielding *N* ≈ 201,000 spanning five generational cohorts.

Respondents with missing values on the key independent variable (CESOCIALIZE) were excluded from models involving socialization (less than 1% of the analytic sample). For moderating variables, cases with missing values were excluded listwise within each model. All analyses incorporate the supplement weight (VLSUPPWT) to produce nationally representative estimates. Because the CPS employs a stratified multistage cluster design, the survey design object specifies household-level clustering (using the SERIAL variable) and state-level stratification (using STATEFIP), with a lonely-PSU adjustment for strata containing a single sampling unit. IPUMS does not release the actual primary sampling unit identifiers used in the CPS design; SERIAL and STATEFIP represent the best available approximation and yield more conservative standard error estimates than a simple random sampling assumption.

## Measures

### Dependent Variable

Volunteering status was measured using VLSTATUS, which asks whether the respondent "did any volunteer activities through or for an organization" in the past 12 months (1 = volunteered, 2 = did not volunteer). This measure was dichotomized for logistic regression and treated as an external criterion variable for the latent profile analysis.

### Key Independent Variable

In-person socialization frequency was measured using CESOCIALIZE, which asks respondents how often they "got together socially with friends, relatives, or neighbors" in the past 12 months. Response options range from 1 = "Not at all" to 6 = "Basically every day." For logistic regression, socialization is entered as a factor variable with "Not at all" as the reference category, allowing estimation of nonlinear threshold effects at each transition. For the GBM analysis, it is entered as a continuous ordinal predictor.

### Generational Cohorts

Respondents were classified into five generational cohorts based on birth year (calculated as survey year minus age): Generation Z (born 1997 or later), Millennials (1981–1996), Generation X (1965–1980), Baby Boomers (1946–1964), and the Silent Generation (born before 1946). Generation Z serves as the reference category in regression models.

### Moderating Variables

Four theoretically motivated moderators were examined. *Education* was measured using EDUC (IPUMS harmonized) and dichotomized as bachelor's degree or higher (EDUC ≥ 111) versus less than a bachelor's degree, consistent with the civic voluntarism model's emphasis on educational thresholds. *Employment status* was dichotomized as currently employed (EMPSTAT ∈ {10, 12}) versus not employed. *Civic social media use* was measured using VLSOCMEDIA, which asks how often the respondent "posted, shared, or discussed issues on civic or political topics on social media" (1 = basically every day through 6 = not at all). This was dichotomized as any civic social media use (VLSOCMEDIA ≤ 4) versus no use, following the conceptual distinction between digital civic engagement and non-engagement.

*COVID-19 period* was operationalized as a binary variable distinguishing pre-COVID waves (2017, 2019) from post-COVID waves (2021, 2023). This coding captures the broad disruption to social life rather than a precise epidemiological boundary, and is included to test whether the socialization–volunteering relationship is a stable feature or was altered by pandemic-related changes to social behavior.

### Latent Profile Analysis Indicators

Six indicators were used to construct civic engagement typologies:

1. **Boycotting** (CEBOYCOTT): Whether the respondent boycotted a product for social or political reasons (binary).
2. **Contacting officials** (CEPUBOFF): Whether the respondent contacted a public official (binary).
3. **Political conversation** (CEPOLCONV): Frequency of discussing politics (ordinal, 1–6).
4. **In-person socialization** (CESOCIALIZE): Frequency of in-person social contact (ordinal, 1–6).
5. **Organizational membership** (VLMEMBERN): Number of organizations to which the respondent belongs (count; respondents reporting no membership via VLMEMBER were coded as 0).
6. **Charitable donation** (VLDONATE): Whether the respondent donated to a charitable or religious organization (binary).

All six indicators are available across all four survey waves with approximately 94% valid response rates. This set captures multiple dimensions of civic life—political action, social connection, institutional membership, and philanthropic behavior—enabling person-centered identification of distinct engagement patterns.

### Control Variables

Models controlled for age (continuous), sex (female = 1), race/ethnicity (White non-Hispanic [reference], Black non-Hispanic, Hispanic, Asian non-Hispanic, other), marital status (married = 1), family income (log-transformed midpoint), metropolitan status (metro = 1), and Census region (Northeast, Midwest, South, West [reference]). In Models 1–4, the post-COVID indicator also serves as a control; in Model 5, it is the focal moderator.

## Analytic Strategy

The analysis proceeds through two integrated stages, each addressing a distinct research question while providing methodological triangulation.

### Stage 1: Survey-Weighted Logistic Regression (RQ1)

To address RQ1, we estimate survey-weighted logistic regression models predicting volunteering status. Socialization frequency is entered as a categorical predictor to capture nonlinear effects without imposing functional form assumptions. Model 1 includes the socialization × generation interaction with post-COVID as a control. Models 2–4 extend to three-way interactions: socialization × generation × education (Model 2), socialization × generation × employment (Model 3), and socialization × generation × civic social media (Model 4). Model 5 tests the socialization × generation × post-COVID interaction to assess whether the socialization–volunteering relationship changed across the pandemic period.

We report odds ratios and average marginal effects (AMEs) computed via the `marginaleffects` package (Arel-Bundock, 2023). AMEs represent the average change in the predicted probability of volunteering for a one-unit change in the predictor, averaged across the covariate distribution. Wald tests assess the statistical significance of interaction terms.

### Stage 2: Latent Profile Analysis (RQ2)

To address RQ2, we employ Latent Profile Analysis (LPA) to identify distinct civic engagement typologies using six standardized indicators (Collins & Lanza, 2010). We evaluate models with 2–7 profiles using the EII parameterization, selecting the optimal number based on BIC, entropy, and BLRT. Given the large sample size, model selection is conducted on a random subsample of 20,000 cases, with the selected model refit to the full sample. Profiles are characterized by indicator means, generational distribution, volunteering rates, and pre/post-COVID stability.

### Software

Regression analyses used R with the `survey` (Lumley, 2020) and `marginaleffects` (Arel-Bundock, 2023) packages. LPA used `mclust` (Scrucca et al., 2016).

### Robustness Checks

Three sets of robustness analyses tested the sensitivity of the regression findings. First, we compared the observed categorical AMEs to predictions from a smooth log-linear specification to confirm that the First Step Effect reflects a genuine threshold rather than an artifact of scale concavity. Second, we added organizational membership (VLMEMBERN) as a covariate to assess the extent to which the socialization pathway operates through institutional embeddedness. Third, we included a nonlinear age control (age-squared) alongside the generation variable to provide partial leverage against age-cohort confounding.
