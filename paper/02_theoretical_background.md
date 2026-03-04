# Theoretical Background

## Conceptualizing Civic Engagement as a Multidimensional Construct

Civic engagement encompasses the diverse ways in which individuals participate in the governance and collective life of their communities (Adler & Goggin, 2005). While early scholarship tended to equate civic participation with electoral behavior, contemporary conceptualizations recognize a broad spectrum of activities that includes volunteering, charitable giving, organizational membership, political voice, and informal community interaction (Ekman & Amnå, 2012; Zukin et al., 2006). This multidimensionality is both a theoretical strength and a methodological challenge: civic engagement cannot be reduced to a single indicator without losing essential information about the qualitative character of participation.

Zukin et al. (2006) proposed a typological distinction between *civic activities* (volunteering, community problem-solving, organizational membership), *political activities* (voting, contacting officials, protesting), *public voice activities* (boycotting, signing petitions, contacting media), and *cognitive engagement* (following news, discussing politics). While these categories provide useful conceptual scaffolding, they represent ideal types rather than empirical realities. In practice, individuals combine activities across categories in complex, idiosyncratic ways. A retired schoolteacher who volunteers at a food bank, donates to multiple charities, and contacts her state representative occupies a fundamentally different civic position than a young professional who boycotts companies over social issues but engages in no other civic activities—even though both register as "civically engaged" in variable-centered analyses.

This observation motivates the present study's adoption of a person-centered approach that seeks to discover, rather than assume, the empirical patterns through which civic activities cluster within individuals.

## Person-Centered Approaches to Civic Engagement

### From Variable-Centered to Person-Centered Analysis

The dominant tradition in civic engagement research employs variable-centered methods—regression, structural equation modeling, multilevel modeling—that estimate relationships between variables averaged across the entire sample (Bergman & Magnusson, 1997). These methods are powerful for testing specific hypotheses about directional relationships (e.g., "Does education predict volunteering?"), but they operate under an assumption of population homogeneity: the estimated relationship is assumed to hold, at least in direction and approximate magnitude, for all members of the sample.

Person-centered approaches relax this assumption by positing the existence of qualitatively distinct subpopulations, each characterized by a unique configuration of indicators (Muthén & Muthén, 2000). Rather than asking "what predicts civic engagement?" as though engagement were a unitary phenomenon experienced uniformly, person-centered methods ask "what *types* of civic actors exist, and how do they differ?" The unit of analysis shifts from the variable to the person, and the goal shifts from explaining variance to discovering structure.

### Latent Profile Analysis

Latent Profile Analysis (LPA), a finite mixture model for continuous indicators, is the primary tool for identifying person-centered subgroups in this study (Collins & Lanza, 2010). LPA assumes that observed patterns of civic engagement indicators reflect membership in unobserved (latent) subpopulations, each with its own profile of means on the indicator variables. The method simultaneously estimates the number and character of these latent profiles and assigns each individual a probability of membership in each profile.

The application of LPA to civic engagement is relatively nascent but growing. Existing typology research has identified profiles such as "all-around activists," "electoral specialists," "disengaged observers," and "community volunteers" in various national contexts (Teorell et al., 2007). However, most studies have relied on national samples that obscure state- and region-level variation, and few have connected LPA-derived profiles to subsequent predictive modeling. The present study addresses both gaps by estimating profiles within a single state (Pennsylvania) and using profile membership as a structuring variable for machine learning-based prediction.

## Theoretical Frameworks

### The Civic Voluntarism Model

The Civic Voluntarism Model (CVM), articulated by Verba, Schlozman, and Brady (1995), provides the primary theoretical framework for understanding individual-level predictors of civic engagement. The CVM identifies three categories of factors that explain why some people participate and others do not: *resources*, *engagement*, and *recruitment*.

**Resources** include time, money, and civic skills—the practical capacities that enable participation. Education is the most consistently identified resource predictor of civic engagement, operating both directly (by providing civic knowledge) and indirectly (by increasing income and expanding social networks; Verba et al., 1995). Employment, paradoxically, both constrains time and develops civic skills through workplace interactions. The CVM predicts that resource-rich individuals will exhibit higher civic engagement overall but does not address whether different resource configurations lead to qualitatively different patterns of engagement—the question that motivates our person-centered approach.

**Engagement** refers to psychological orientations toward politics and community life, including political interest, partisan identity, and sense of civic duty. While the CPS-CEV data do not directly measure these orientations, behavioral proxies—such as frequency of political conversation and news consumption—capture related constructs.

**Recruitment** encompasses the social networks and institutional affiliations through which individuals are asked to participate. Organizational membership serves as both a form of civic engagement and a channel for recruitment into additional activities (Putnam, 2000). Rural and urban contexts differ substantially in the density and character of recruitment networks, with rural communities relying more heavily on church-based and Extension-affiliated organizations (Theodori, 2005).

### Social Capital Theory

Putnam's (2000) influential formulation of social capital as the "connections among individuals—social networks and the norms of reciprocity and trustworthiness that arise from them" (p. 19) provides a complementary lens for understanding civic engagement patterns. Putnam distinguished between *bonding* social capital (ties within homogeneous groups that provide solidarity and emotional support) and *bridging* social capital (ties across diverse groups that provide access to new information and resources).

For the present study, social capital theory yields two key predictions. First, social interaction frequency—a core indicator in our LPA model—reflects the density of social networks that generate civic recruitment opportunities. Individuals with frequent social contact are more likely to be exposed to requests for volunteering and other civic activities (Musick & Wilson, 2008). Second, the rural-urban dimension maps onto distinct social capital structures: rural communities tend toward bonding capital (dense, homogeneous ties) while urban environments offer more bridging capital (diverse, weak ties; Hofferth & Iceland, 1998). These structural differences may produce qualitatively different civic engagement profiles in rural versus urban contexts, even when aggregate participation rates appear similar.

The relevance of social capital theory extends to the COVID-19 analysis. The pandemic disrupted the in-person social interactions that sustain social capital, potentially eroding the recruitment mechanisms that drive volunteering (Lim & Laurence, 2015). If bonding and bridging capital were differentially affected—with dense rural networks proving more resilient than diffuse urban networks, or vice versa—then COVID's impact on civic engagement profiles should vary by geographic context.

### Community Capitals Framework

The Community Capitals Framework (CCF), developed by Flora and Flora (2008), extends social capital theory to encompass seven forms of community-level resources: natural, cultural, human, social, political, financial, and built capital. The CCF is particularly relevant for understanding rural-urban differences in civic engagement because it situates individual participation within the broader resource ecology of communities.

Rural communities, despite often having lower levels of human capital (educational attainment) and financial capital (household income), may compensate through strong cultural capital (shared norms of mutual aid and community responsibility) and political capital (direct relationships with local officials; Flora et al., 2016). This framework predicts that civic engagement profiles in rural areas may emphasize different dimensions—such as informal community interaction and direct political contact—compared to urban profiles that reflect access to formal organizational infrastructure.

The CCF also highlights the *spiraling* nature of community capitals: investment in one form generates returns in others. Volunteering, understood as an investment of human capital in social and political capital, may initiate positive spirals of community capacity-building. Conversely, civic disengagement—the focus of our threshold analysis—represents a potential downward spiral in which the withdrawal of individual participation erodes community-level resources, further discouraging participation.

### Ecological Systems Theory

Bronfenbrenner's (1979) Ecological Systems Theory provides a final integrative lens by situating civic engagement within nested contexts: the microsystem (immediate social relationships and organizational affiliations), mesosystem (connections between microsystem settings, such as the link between workplace and community organization), exosystem (community-level structures that indirectly shape participation, such as local government accessibility and nonprofit infrastructure), and macrosystem (cultural values, economic conditions, and policy environments).

This framework underscores that volunteering behavior is not solely a function of individual resources and preferences but is shaped by the contextual opportunities and constraints that vary systematically across geographic and temporal settings. The pandemic represents a macrosystem shock that propagated through all levels of the ecological system, disrupting microsystem interactions (social distancing), mesosystem connections (closure of organizations), and exosystem structures (shifts in nonprofit capacity and government priorities).

## Volunteering, Civic Engagement, and the Rural-Urban Divide

The relationship between volunteering and broader civic engagement has been characterized as reciprocal rather than unidirectional (Musick & Wilson, 2008). Volunteering exposes individuals to community needs, develops civic skills, and expands social networks—all of which facilitate engagement in other civic domains. Simultaneously, existing civic engagement (political interest, organizational membership) predicts entry into volunteering. This reciprocity complicates causal interpretation but enriches the descriptive and predictive analyses pursued here.

The rural-urban dimension adds a critical contextual layer. Contrary to deficit-based narratives that frame rural areas as civically disadvantaged, empirical evidence increasingly suggests that rural residents participate at rates comparable to, or exceeding, their urban counterparts once demographic composition is accounted for (Lim & Laurence, 2015). Rural communities may compensate for lower organizational density through higher per-capita participation intensity and stronger social obligation norms (Theodori, 2005). The critical question is not whether rural residents participate *more or less* but whether they participate *differently*—in distinct combinations and configurations of civic activities.

Pennsylvania offers a particularly informative setting for examining this question. The state's rural regions include both prosperous agricultural communities (Lancaster County) and economically distressed areas (portions of the Northern Tier and the coal regions), creating within-rural variation that challenges monolithic characterizations. Similarly, the state's urban contexts range from Philadelphia's postindustrial diversity to Scranton's declining Rust Belt economy, each presenting different civic engagement landscapes.

## The COVID-19 Pandemic and Civic Engagement

The COVID-19 pandemic represented the most significant disruption to American civic life since the Second World War. Stay-at-home orders, organizational closures, and public health concerns directly curtailed many forms of in-person civic participation, including volunteering (Corporation for National and Community Service, 2021). However, the pandemic's impact was not uniformly negative. Some communities experienced surges in mutual aid, virtual volunteering, and political mobilization, suggesting that crises can simultaneously suppress some forms of participation while activating others (Marston et al., 2020).

Emerging evidence points to generational asymmetry in the pandemic's civic engagement effects. Younger cohorts, while less constrained by health vulnerability, faced disproportionate economic disruption (unemployment, educational interruption) that may have redirected energy away from civic activities (Flanagan & Levine, 2010). Older cohorts, conversely, may have experienced health-related barriers to in-person participation while possessing the financial stability to maintain engagement through charitable giving and virtual means.

This study's inclusion of four CPS waves spanning the pandemic allows for a quasi-experimental examination of these dynamics within the LPA framework. By comparing the distribution and composition of civic engagement profiles across pre-pandemic (2017, 2019) and post-pandemic (2021, 2023) periods, we can assess whether COVID altered the *structure* of civic engagement—shifting the relative prevalence of distinct civic actor types—rather than simply reducing participation across the board.

## Machine Learning Interpretability in Social Science

### The Role of SHAP in Predictive-Interpretive Research

The application of machine learning methods in social science has been constrained by the "black box" problem: complex models that achieve high predictive accuracy often resist the interpretive demands of theory-driven research (Molnar, 2020). SHAP (SHapley Additive exPlanations), developed by Lundberg and Lee (2017), addresses this limitation by providing a unified framework for interpreting any predictive model's output.

Grounded in Shapley values from cooperative game theory, SHAP assigns each feature a contribution to each individual prediction, with the property that contributions sum to the difference between the prediction and the model's average output (Lundberg et al., 2020). This individual-level decomposition enables the kind of person-centered interpretation that aligns naturally with LPA-based research: rather than reporting a single coefficient for "education," SHAP reveals how education's predictive contribution varies across individuals, subgroups, and civic engagement profiles.

When applied to gradient boosting machines (GBMs)—ensemble tree models that capture nonlinear relationships, interaction effects, and threshold dynamics—SHAP analysis provides a methodological complement to the person-centered typological approach of LPA. Where LPA discovers *who* the distinct civic actors are, SHAP reveals *what drives* their behavior by decomposing prediction into interpretable feature contributions.

### From Causal Inference to Predictive-Interpretive Framework

It is important to situate this study's analytical approach within the broader landscape of causal and predictive methods. Cross-sectional survey data, such as the CPS-CEV supplement, cannot support strong causal claims about the effects of volunteering or the determinants of civic engagement. Observational studies face well-known threats from confounding, reverse causation, and selection bias (Morgan & Winship, 2015). Methods such as causal forests and instrumental variable approaches require assumptions—notably unconfoundedness and exclusion restrictions—that are difficult to defend with cross-sectional civic engagement data.

Rather than overreaching with causal claims that the data cannot support, this study adopts a *predictive-interpretive* framework. The goal is not to estimate the causal effect of any single factor on civic engagement but to characterize the multivariate structure of civic engagement patterns (via LPA) and to identify the features that most strongly predict volunteering and civic disengagement (via GBM + SHAP). This approach is epistemologically honest about the limitations of cross-sectional data while extracting maximum interpretive value from the complex, multidimensional structure of the CPS-CEV supplement.

The predictive-interpretive framework aligns with what Shmueli (2010) termed "explanatory modeling" in the social sciences: the use of statistical models not for pure prediction nor for strict causal identification, but for revealing patterns, generating hypotheses, and informing theory development. By combining person-centered classification with feature-level prediction decomposition, the present study contributes to this growing tradition of methodology-driven social inquiry.

## Research Questions and Analytical Framework

Synthesizing the theoretical foundations reviewed above, this study pursues four research questions within an integrated analytical framework:

**RQ1 (Typological Structure):** Drawing on the multidimensional conceptualization of civic engagement and the person-centered tradition, we employ LPA to discover distinct profiles of civic engagement among Pennsylvania adults. Five indicators—consumer political action (boycotting), institutional political action (contacting officials), political conversation frequency, social interaction frequency, and organizational membership count—capture the breadth of civic participation theorized by Verba et al. (1995) and Zukin et al. (2006).

**RQ2 (Profile-Stratified Prediction):** Guided by the Civic Voluntarism Model's emphasis on resources, engagement, and recruitment, we estimate GBM models predicting volunteering participation within each LPA-derived profile. SHAP analysis decomposes these predictions to reveal how the importance of education (human capital), income (financial capital), age and generation (life course position), geography (community context), and social media use (digital engagement) varies across civic actor types. The Community Capitals Framework predicts that rural-urban differences will emerge not just in levels of participation but in the relative importance of different predictors.

**RQ3 (Civic Disengagement Threshold):** Informed by social capital theory's emphasis on the erosion of civic infrastructure, we examine the factors that predict complete formal civic disengagement—non-participation in volunteering, charitable giving, boycotting, or political contact. Two models—one using demographic predictors alone and one incorporating LPA profiles—allow us to assess both the demographic correlates and the typological context of disengagement.

**RQ4 (Pandemic Impact on Civic Structure):** Leveraging the quasi-experimental temporal structure of four CPS waves spanning the COVID-19 pandemic, we examine whether the pandemic altered the distribution of civic engagement profiles. Ecological Systems Theory predicts that this macrosystem shock propagated differentially across geographic contexts and generational cohorts, potentially reshaping the typological structure of civic engagement rather than simply reducing aggregate participation.

Together, these questions constitute a comprehensive examination of civic engagement heterogeneity that moves beyond average effects to reveal the person-level patterns, predictive structures, and temporal dynamics underlying civic life in a diverse American state.
