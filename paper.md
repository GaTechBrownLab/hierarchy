# Quantifying Multi-Signal Quorum Sensing: The *las* and *rhl* Systems in *Pseudomonas aeruginosa* Form a Biased Reciprocal Network That Can Tune Responses to Physical and Social Environments

Stephen Thomas<sup>1</sup>, Ayatollah Samir El-Zayat<sup>2</sup>, James Gurney<sup>3</sup>, Jennifer Rattray<sup>1</sup>, Sam P. Brown<sup>1</sup>

> 1. School of Biological Sciences, Georgia Institute of Technology, Atlanta, GA USA 30332.
> 2. Faculty of Agriculture, Cairo University, Cairo, Egypt 12613.
> 3. Department of Biology, College of Arts and Sciences, Georgia State University, Atlanta, GA USA 30303.

**Abstract:** Bacterial quorum sensing is often mediated by multiple signaling systems that interact with each other. The quorum sensing systems of *Pseudomonas aeruginosa,* for example, have been considered hierarchical, with the *las* system acting as a master regulator. By experimentally controlling the concentration of auto-inducer signals in a signal deficient strain (PAO1Δ*lasI*Δ*rhlI*), we show that the two primary quorum sensing systems—_las_ and _rhl_—act reciprocally rather than hierarchically. Just as the *las* system's 3‑oxo‑C<sub>12</sub>‑HSL can induce increased expression of *rhlI,* the *rhl* system's C<sub>4</sub>‑HSL increases the expression level of *lasI.* We develop a mathematical model to quantify relationships both within and between the *las* and *rhl* quorum sensing systems and the downstream genes they influence. The results show that not only do the systems interact in a reciprocal manner, but they do so asymmetrically, cooperatively, and nonlinearly, with the combination of C<sub>4</sub>‑HSL and 3‑oxo‑C<sub>12</sub>‑HSL increasing expression level far more than the sum of their individual effects. We next extend our parameterized mathematical model to generate quantitative predictions on how a QS-controlled effector gene (*lasB*) responds to changes in bacterial stationary phase density, and find close quantitative agreement with an independent dataset. Finally, we use a counter-factual approach to assess how changes in multi-signal interactions modulate functional responses to  variation in social (population density) and physical (mass transfer) environment and demonstrate that a reciprocal architecture is more responsive to density and more robust to mass transfer than a strict hierarchy.

## Introduction

Bacterial cells of many species communicate with each other by exchanging diffusible signal molecules [@Papenfort2016; @Whiteley2017]. This mechanism, known as quorum sensing (QS), has been well-studied at the level of specific molecular interactions. We now understand how those interactions shape the creation of and response to signal molecules in model organisms such as *Pseudomonas aeruginosa* [@Pearson1997]. We have identified downstream effector genes such as virulence factors whose production depends on QS signals [@Chugani2001; @Kiratisin2002], and we have recognized that many species possess multiple QS circuits [@Papenfort2016]. Despite this knowledge, we face gaps in our understanding of how quorum sensing influences bacterial behavior. How does QS guide bacterial actions in response to environmental conditions? What benefits do multiple QS circuits provide? And ultimately, how does QS contribute to bacterial fitness? Answering these questions requires an understanding of quorum sensing at the dynamical systems level as well as the molecular level.

Quorum sensing relies on several components interacting in a dynamical system [@Popat2015; @Perez2018]. Individual cells synthesize small molecules called signals or inducers. These diffuse or are actively transported between the intracellular and extracellular environments [@Pearson1999]. Within cells, signal molecules bind to receptor proteins that serve as transcription factors [@Bottomley2007]. As signal concentration grows, genes activated by these transcription factors trigger a change in the cell\'s behavior [@Whiteley1999]. Those molecules related to a particular signal—the signal synthase, the signal molecule, and the cognate receptor—form a quorum sensing system. Some bacterial species have multiple QS systems, the opportunistic pathogen *Pseudomonas aeruginosa* among them. Among its multiple systems, *las* and *rhl* acyl-homoserine lactone (AHL) signaling systems have been especially well studied [@Pesci1997; @Lee2015]. The *las* system includes the LasI signal synthase, N-(3-oxododecanoyl)-l-homoserine lactone (3‑oxo‑C<sub>12</sub>‑HSL) signal, and LasR receptor. The corresponding components of the *rhl* system are RhlI, N-butyryl-homoserine lactone (C<sub>4</sub>‑HSL), and RhlR. Schuster and Greenberg [-@Schuster2007] estimate that these two systems control expression of as much as 10% of the bacterial genome.

*P. aeruginosa* provides a model for understanding interactions between multiple QS systems. How does the behavior of one system, determined by the concentration of signal it produces, affect the behavior of a different system? How does expression of the one system's synthase or receptor respond to the concentration of another systems signal? We classify possible multi-system architectures into three broad patterns shown in Figure [-@fig:architectures]. *Independent systems* (Figure [-@fig:architectures]A) have no influence on each other; *hierarchical systems* (Figure [-@fig:architectures]B) have a relationship but only in one direction, and *reciprocal systems* (Figure [-@fig:architectures]C) each exert influence on the other. At this level we do not consider the underlying mechanism(s) of the inter-system effects. For example, the signal of one system may bind directly to the receptor of the other; alternatively, the signal/receptor complex of one system may act as a transcriptional regulator of components in the second system. In both cases we simply denote the first system as influencing the second.

![architectures](Figures/architectures.svg){#fig:architectures}

<div custom-style="Image Caption"><p>
**Figure [-@fig:architectures]. The relationship between quorum sensing systems may be  classified as independent, hierarchical, or reciprocal.** (A) Independent: the signal of each has no influence on the expression of synthase or receptor in the other. (B) Hierarchical: one system's signal influences expression of the other's components, but without reciprocation. (C) Reciprocal: both systems' signals influence the others' components.
</p></div>
In the case of *las* and *rhl,* independent, isolated operation was eliminated as early as 1996 when Latifi et al. [-@Latifi1996] used *lacZ* transcriptional fusions to show that the combination of LasR and 3‑oxo‑C<sub>12</sub>‑HSL controls expression of *rhlR,* demonstrating that the *las* system influences the *rhl* system. These and other results have led many researchers to view *las* and *rhl* as a hierarchy, with the *las* system serving as master QS system controlling both its own activation and that of the *rhl* system (Figure [-@fig:hierarchy]). We confirm this consensus view via a structured literature review (Tables S.1 and S.2). The review literature is silent on whether the *rhl* signal C<sub>4</sub>‑HSL can influence the expression of the *las* synthase or receptor. If *lasI* or *lasR* respond to the *rhl* signal, then the strict hierarchical view may be missing an important factor that determines the overall system response.

![hierarchy](Figures/hierarchy.svg){#fig:hierarchy}

<div custom-style="Caption"><p>
**Figure [-@fig:hierarchy]. The *P. aeruginosa* QS regulatory network is typically viewed as a hierarchy, with the *las* system on top.** Solid arrows summarize the relationships depicted in 17 review papers published since 1996 (Tables SI.1 and SI.2). All papers show the *las* system affecting the *rhl* system, but none identify a *las* synthase or receptor gene as a target of the *rhl* system (dashed line).
</p></div>
Our experiments explicitly examine the influence of both QS systems on each other, and the resulting data reveal three key insights. First, the traditional hierarchical view of *las* and *rhl* is incomplete. Our results confirm that *las* can exert control over the *rhl* system, but we also observe the converse: *rhl* influences the *las* system, specifically expression of *lasI.* Second, we show that maximum expression of genes in both QS systems requires both signals in combination, highlighting the importance of understanding the nature of the relationship between these systems. Finally, we demonstrate how that relationship can affect  QS-controlled behavior. In particular, we show that, compared to a strict hiearchy, the reciprocity we observe provides more sensitivity to population density and more robustness to interfering physical environmental variation.

## Results

To uncover interactions between the *las* and *rhl* systems, we experimentally assess QS gene expression in an AHL null strain (PAO1Δ*lasI*Δ*rhlI*) exposed to defined, exogenous concentrations of the signal molecules 3‑oxo‑C₁₂‑HSL (*las* system) and C<sub>4</sub>‑HSL (*rhl* system). We use bioluminescence (lux) reporters for *lasI* and *rhlI* to estimate expression levels of the respective signal synthase genes. We then develop mathematical models to quantify the effects of each system on the other and their consequent responses to environmental variation.

### The _las_ and _rhl_ Systems Influence Each Other

We first evaluate quorum sensing behavior under the influence of a single signal. We establish a baseline expression level by measuring reporter luminescence with no signal present. We then observe the increase in luminescence as exogenously controlled signal concentration increases. The ratio of luminescence with signal to luminescence with no signal represents the fold-change in expression induced by the defined signal concentration. Figure [-@fig:single_c12] shows the results for 3‑oxo‑C<sub>12</sub>‑HSL. As expected, expression of both genes increases as signal concentration increases. The availability of the *las* signal molecule influences the expression of *rhlI* as well as *lasI,* and, therefore, the *las* system affects the *rhl* system.

![single_c12](Figures/single_c12.svg){#fig:single_c12}

<div custom-style="Caption"><p>
**Figure [-@fig:single_c12]. The *las* signal 3‑oxo‑C<sub>12</sub>‑HSL increases the expression of *lasI* and *rhlI* in a signal null PAO1.** Plots show fold-change in RLU/OD (relative light units per optical density) values compared to baseline with no exogenous signals in NPAO1∆*lasI*∆*rhlI* cultures. Genomic reporter fusions *lasI:luxCDABE,* *rhlI:luxCDABE,* and *lasB:luxCDABE* were used to generate luminescence. Points are individual observations within the time window of peak expression; dashed lines show a locally weighted regression of the mean fold-change for each concentration value. Figures S.1 and S.2 show the underlying expression data for the entire time course of the experiments. 
</p></div>


While we find no surprises with 3‑oxo‑C<sub>12</sub>‑HSL, our experiments with C<sub>4</sub>‑HSL challenge the conventional hierarchical view. Figure [-@fig:single_c4] shows those results: expression of *las* and *rhlI* increases with higher C<sub>4</sub>‑HSL concentration. The response of *lasI* (Figure [-@fig:single_c4]A) does not correspond to a simple hierarchy with *las* as the master. Here we find that the *rhl* system affects the *las* system.

![single_c4](Figures/single_c4.svg){#fig:single_c4}

<div custom-style="Caption"><p>
**Figure [-@fig:single_c4]. The *rhl* signal C<sub>4</sub>‑HSL increases the expression of *lasI* and *rhlI* in a signal null PAO1.** Expression of both genes grows with increased concentration of C<sub>4</sub>‑HSL. Plots are constructed as in Figure [-@fig:single_c12]. Strains and reporters also as in Figure [-@fig:single_c12]. Note that panel A shows results are not captured by the consensus *las→rhl* hierarchy, as it clearly indicates that *lasI,* in the *las* system, responds to the signal produced by the *rhl* system. As above, Figures S.1 and S.2 show the underlying expression data for the entire time course of the experiments.
</p></div>


To quantify the impact of each signal alone, we model gene expression using Michaelis-Menten kinetics under quasi-steady state assumptions. The resulting dynamics provide a simple model of transcription factor binding [@Santillán2008; @Bolouri2008 chapter 9] as well as more general processes such as enzyme activity and substrate-receptor binding.

For a single signal, gene expression is defined by Equation [-@eq:singlesignal], where _ɑ<sub>0</sub>_ is basal expression, _ɑ_ is the maximum increase in expression from auto-induction, [_S_ ] is the signal concentration, and *K* is the disassociation constant of the binding event or, equivalently, the signal concentration corresponding to half of the maximum expression gain. With this model we quantify two qualities: how strongly a signal can increase gene expression above its basal level (_ɑ_), and how sensitive gene expression is to the presence of the signal (*K*).

$$
E(S) = \alpha_0 + 
\alpha \frac{[S]}{[S] + K}
$$ {#eq:singlesignal}

<img src="Figures/eq_singlesignal.svg" width="100%"/>

By minimizing the sum of squared error (with non-linear regression using the Gauss-Newton algorithm), we estimate model parameters from our data, using only those observations in which a single signal is present. TableS.3 details the results. Our model fits illustrate that while the *las* and *rhl* systems have reciprocal impacts, those impacts are not symmetrical. The *las* signal 3‑oxo‑C<sub>12</sub>‑HSL has a substantially greater influence on gene expression than C<sub>4</sub>‑HSL. In both cases the potential fold-change from 3‑oxo‑C<sub>12</sub>‑HSL is approximately six times greater than the potential fold-change from C<sub>4</sub>‑HSL. Both *lasI* and *rhlI* are also more sensitive to 3‑oxo‑C<sub>12</sub>‑HSL than to the C<sub>4</sub>‑HSL as the concentrations required to reach half of maximal expression are roughly 4 times and 30 times higher for the latter.

### _las_ and _rhl_ Combine Non-Linearly and Synergistically

Figures [-@fig:single_c12] and [-@fig:single_c4] consider the effects of each signal in isolation, but wildtype cells with functioning synthase genes can produce both signals. To understand environments where both signals are present, we use controlled concentrations of both signals in combination. Figure [-@fig:combined] presents those results in the form of heat maps. The qualitative responses of both genes are similar: raising the concentration of either signal increases expression regardless of the concentration of the other signal. As with our observations of C<sub>4</sub>‑HSL alone, these results demonstrate again that the *rhl* system (via C<sub>4</sub>‑HSL) affects the *las* system (*lasI* expression).

![combined](Figures/combined.svg){#fig:combined}

<div custom-style="Caption"><p>
**Figure [-@fig:combined]. Expression of *lasI* and *rhlI* is maximal in the presence of both C<sub>4</sub>‑HSL and 3‑oxo‑C<sub>12</sub>‑HSL.** Expression of both genes grows with increased concentration of either signal when both signals are combined. Heatmaps show fold-change in RLU/OD values compared to baseline with no exogenous signals. All underlying expression data through time is shown in Figures S.1 and S.2.
</p></div>


Having established a simple model for each signal in isolation, we next consider whether that model is sufficient to explain the effect of the signals in combination. Can we estimate total expression as the sum of expression induced by each signal alone? Such a response could result from two independent binding sites in the promoter regions [@Buchler2003], one site for LasR/3‑oxo‑C<sub>12</sub>‑HSL and a separate site for RhlR/C<sub>4</sub>‑HSL. Figure [-@fig:single_all] clearly shows that we cannot. The maximum expression observed, shown as a "ceiling" in that figure's panels, far exceeds the sum of the signals' individual influence. The presence of both signals boosts expression by as much as 30-fold beyond the level of what a simple sum would predict.

![single_all](Figures/single_all.svg){#fig:single_all}

<div custom-style="Caption"><p>
__Figure [-@fig:single_all]. Neither 3‑oxo‑C<sub>12</sub>‑HSL nor C<sub>4</sub>‑HSL alone can achieve maximal expression of *lasI* or *rhlI.*__ Both genes require non-zero concentrations of both signals to achieve maximum expression. The flat surfaces in the plots indicate the maximum mean expression level measured across all combinations of signal concentrations. The plotted points represent observed expression levels when C<sub>4</sub>‑HSL is withheld (red) and when 3‑oxo‑C<sub>12</sub>‑HSL is withheld (yellow). Lines indicate the model predictions (Equation [-@eq:singlesignal], parameters in Table S.3).
</p></div>


To account for the synergy between the signals, we incorporate a cooperativity term in the gene expression model. Note that the cooperativity term is a multiplication of signals, and it alone cannot explain the full response, as the product is necessarily zero when any signal is absent. This term accounts for any non-additive interaction, for example the ability of one bound transcription factor to recruit the binding of a second transcription factor [@Kaplan2008]. Equation [-@eq:multisignal] shows the result. Each gene has a basal expression level, amplification from each signal alone, and additional amplification from each pair-wise combination of signals. The interaction from these pair-wise combinations captures the cooperative enhancement from the combined signals.

$$
E_i(\mathbf{S}) \ \ = \ \ \alpha_{i,0} \ \ \ + \ \ \ 
\sum_{j=1}^{\mathrm{N_S}}\alpha_{i,j}\frac{[S_j]}{[S_j] + K_{i,j}} \ \ \ + \ \ \
\sum_{j=1}^{\mathrm{N_S}-1}\sum_{j' = j+1}^{\mathrm{N_S}}
\alpha_{i,j,j'}\frac{[S_j][S_{j'}]}{([S_j] + K_{Qi,j,j'})([S_{j'}] + K_{Qi,j',j})}
$$ {#eq:multisignal}

<img src="Figures/eq_multisignal.svg" width="100%"/>

For both *lasI* and *rhlI* we again minimize the sum of squared errors to estimate parameter values. The resulting multi-signal models in Table S.4 have R^2^ values of 0.82 and 0.77. Figure [-@fig:multiple] compares the model estimates with observations. For both genes, the model captures the effect of either signal in isolation and both signals in combination.

![multiple](Figures/multiple.svg){#fig:multiple}

<div custom-style="Caption"><p>
**Figure [-@fig:multiple]. Multi-signal models of Equation [-@eq:multisignal] for *lasI* and *rhlI* expression capture the synergistic effects of both signals.** Model estimates are shown as orange grid lines. Spheres show the mean value of expression observed at each combination of signal concentrations. Lines extend from these mean values to the relevant grid point for clarity. The coefficient of determination (R<sup>2</sup>) for the models is 0.82 and 0.77, respectively. Figures S.4 and S.5 present more detailed comparisons between model and observations.
</p></div>

The parameter estimates in Table S.4 quantify the relative effect of individual and combined signals. For both *lasI* and *rhlI,* a single signal increases expression no more than 38- or 35-fold. Both signals combined, however, increase expression an *additional* 30- or 27-fold. The maximum expression induced by both signals nearly doubles compared to the maximum expression induced by any signal alone. Figure [-@fig:reciprocal] summarizes the model parameters graphically. It answers the question posed in Figure [-@fig:hierarchy]—the *rhl* system does influence the *las* system—and it shows the relative magnitudes of the effects.

![reciprocal](Figures/reciprocal.svg){#fig:reciprocal}

<div custom-style="Caption"><p>
**Figure [-@fig:reciprocal]. The *las* and *rhl* quorum sensing systems have a reciprocal, but unequal relationship.** Red arrows represent maximum fold-change induction from *las*'s 3‑oxo‑C<sub>12</sub>‑HSL and yellow arrows maximum fold-change induction from *rhl'*s C<sub>4</sub>‑HSL. The orange component is additional induction from the combination of both signals. Arrow thickness is proportional to fold-change. Inset shows relative contribution of each signal to total maximum fold-change for expression levels of *lasI* and *rhlI,* and half concentration values for each.
</p></div>

### *las* and *rhl* Synergy Also Shapes Control of Quorum Sensing Effector Genes

Our results, summarized in Figure [-@fig:reciprocal], establish that both AHL signals influence the expression levels of both synthase genes in a synergistic manner. We note that the methods outlined in Figures [-@fig:single_c12]–[-@fig:reciprocal] for the *lasI* and *rhlI* synthase genes can be applied to any QS-controlled gene of interest and can quantify dual signal control over expression levels. Here we look at _lasB,_ a classic QS effector gene that codes for the secreted digestive enzyme LasB and a widely used as a model of  QS-mediated virulence [@Casilag2016; @Cigana2021] and cooperation [@Diggle2007; @Allen2016; @Sexton2017].

The prior literature provides a clear expectation that *lasB* expression will be positively influenced by both AHL signal molecules. [@Pearson1997; @Nouwens2003], but does not provide a quantitative summary of the relative importance of each signal’s contribution—alone and via synergistic effects. Using the approach outlined above, we measure luminescence of a *lasB* reporter in an AHL signal null strain exposed to defined, exogenous concentrations of both AHL signals, revealing maximal activation under dual-signal exposure (Figure [-@fig:lasb_expression]A). Fitting Equation [-@eq:multisignal] to the data highlights that *lasB* expression is dominated by the synergistic combination of both signals rather than either signal in isolation (Figure [-@fig:lasb_expression]B). Notably, *lasB* expression is more senstive to C<sub>4</sub>‑HSL than to 3‑oxo‑C<sub>12</sub>‑HSL. (Figure [-@fig:lasb_expression]C).

![lasb_expression](Figures/lasb_expression.svg){#fig:lasb_expression}

<div custom-style="Caption"><p>
**Figure [-@fig:lasb_expression]. Expression of *lasB* is maximal in the presence of both C<sub>4</sub>‑HSL and 3‑oxo‑C<sub>12</sub>‑HSL.** (A) Heatmap showing fold-change in RLU/OD values compared to baseline with no exogenous signals. (B) Surface plot showing raw RLU/OD values comparing maximum measured expression (blue “ceiling”) with observed expression levels when C<sub>4</sub>‑HSL is withheld (red) and when 3‑oxo‑C<sub>12</sub>‑HSL is withheld (yellow). Lines indicate the model predictions (Equation [-@eq:singlesignal]). (C) Summary of model parameters in context of <em>lasI</em> and <em>rhlI.</em> Figure S.3 shows underlying expression data for full time course of experiments; Table S.5 lists the parameter values, and Figures S.6 and S.7 provide a detailed comparison of model predictions and observations.
</p></div>


### Mathematical Models Incorporating Multi-signal Interactions Predict Quorum Sensing Response to Environmental Variation

Our parameterized gene expression model (Equation [-@eq:multisignal]) predicts gene *i*‘s expression *E<sub>i</sub>* as a function of the AHL signal environment **S** (Figures [-@fig:multiple] and S.6), which leaves open the question of how the signal environment **S** relates to underlying dimensions of environmental variation—the hypothesized sensing targets of quorum sensing (population density [@Fuqua1994], diffusion [@Redfield2002], efficiency [@Hense2007], containment [@Boedicker2009], genotypes [@Allen2016], combinations [@Cornforth2014], etc.)

To connect our gene expression model to critical environmental dimensions of bacterial population density and mass transfer (e.g. diffusion or advective flow), we build on previous models of extracellular signal dynamics [@James2000; @Dockery2001; @Ward2001; @Brown2013; @Cornforth2014]. We assume that signal concentration increases in proportion to the corresponding synthase’s expression level, multiplied by the number of cells expressing synthase, and decreases due to a constant rate of decay and removal via mass transfer. These assumptions lead to the differential equation model of Equation [-@eq:dynamics], where _S<sub>i</sub>_ is the concentration of signal _i_, _E<sub>i</sub>_ (**S**) is the expression level of the synthase for signal _i_ (as a function of both signal concentrations, **S**, see Equation [-@eq:multisignal]) and _c<sub>i</sub>_ a proportionality constant, _N_ is the population density; _𝛿<sub>i</sub>_ is the decay rate of signal _i,_ and _m_ is the rate of mass transfer.
$$
\frac{\mathrm{d}S_i}{\mathrm{dt}} \ \ = \ \ 
c_i E_i(\mathbf{S})\cdot N \ \ - \ \ 
 \delta_i \cdot S_i \ \ - \ \ 
 m \cdot S_i
$$ {#eq:dynamics}

<img src="Figures/eq_dynamics.svg" width="100%"/>

This equation models the dynamics of extracellular signal concentrations in response to environmental conditions defined by density *N* and mass transfer rate *m.* While it is possible to derive analytical equilibrium solutions to Equation [-@eq:dynamics] for either independent (Equation[-@eq:singlesignal] or synergistic (Equation [-@eq:multisignal]) signal activation *E<sub>i</sub>*(**S**), the resulting solutions are cumbersome and do not yield clear insights into system behavior. (See supporting information.)

To numerically solve for equilibrium signal values in Equation [-@eq:dynamics] that result from given values of population density and mass transfer rate, we derive parameter estimates for synergistic _E<sub>i</sub>_(**S**) from our experimental data (Equation [-@eq:multisignal], Table S.4). The remaining parameters, _c<sub>i</sub>_ and *𝜹<sub>i</sub>*, we estimate from published literature as detailed in the supporting information and summarized in Table S.3 and Figure S.8. We can connect these equilibrium signal values to QS-controlled effector behavior using our model of *lasB* expression (Equation [-@eq:multisignal] as parameterized by Table S.5). Integrating these steps allows us to probe how *lasB* expression varies as the social (*N*) and physical (*m*) environmentals change.

In Figure [-@fig:lasb_response] we illustrate our integrated model prediction of *lasB* expression as a function of change in stationary phase population density, *N* (solid line, Figure [-@fig:lasb_response]), capturing the causal chain from environment *N* to signal levels **S** (Equation [-@eq:dynamics]) and signals **S** to *lasB* expression (Equation [-@eq:multisignal], Figure [-@fig:lasb_expression], Table S.5). To test this prediction using an independent dataset, we use previously published data on *lasB* expression as a function of stationary phase density [@Rattray2022]. Our model prediction is in strong agreement with the data (R<sup>2</sup> = 0.91), demonstrating not only the utility of our approach but also providing theoretical support for the conclusions of the prior experimental study [@Rattray2022]: QS controlled behaviors in *P. aeruginosa* are not governed by a critical cell density or ‘quorum’ threshold separating off/on states, but are better described as producing graded or rheostatic responses to changes in density.

![lasb_response](Figures/lasb_response.svg){#fig:lasb_response}

<div custom-style="Caption"><p>
**Figure [-@fig:lasb_response]. _lasB_ responds to increasing bacterial density in a graded manner.** Reaction norm [@Stearns1989] showing predicted _lasB_ expression level (solid line), as a function of population carrying capacity. For each density value, equation [-@eq:dynamics] provides an estimate of equilibrium signal concentrations for 3‑oxo‑C<sub>12</sub>‑HSL and C<sub>4</sub>‑HSL. The model of equation [-@eq:multisignal], parameterized by the estimates of Table S.5, then predicts _lasB_ expression from those concentrations. The figure also shows independent experimental observations of _lasB_ expression as a function of bacterial carrying capacity, manipulated by varying the concentration of limiting carbon [@Rattray2022]. Model predictions are in good agreement with independent experimental data (R<sup>2</sup> = 0.91). Note that the model parameters are not fitted to the data in this figure.
</p></div>
### Multi-Signal Architectures Govern Functional Responses to Environmental Variation 

Following an initial validation of our quantitative predictions linking environmental properties to QS-controlled behaviors (Figure [-@fig:lasb_response]), we now turn to counter-factual analyses of our model to assess how changes in model architecture translate to changes in the ability to sense and respond to differences in environmental conditions. Specifically, we  ask: how do reciprocal versus hierarchical versus independent architectures (Figure [-@fig:architectures]) influence QS signal and effector responses to variation in bacterial density and mass transfer? To answer that question, we recognize that Equation [-@eq:multisignal] is general enough to model hierarchical and independent architectures in addition to reciprocal architectures. Those alternatives emerge when specific *ɑ* parameter values are equal to zero.

Starting with our full reciprocal activation model (Table S.4), we can derive a _las_-controlled hierarchical model by setting *ɑ*<sub>1,2</sub> and *ɑ*<sub>1,1,2</sub> to zero (removing influences of the *rhl* system on the *las* system). To derive an independent model we additionally set *ɑ*<sub>2,1</sub> and *ɑ*<sub>2,1,2</sub> to zero (removing influences of the *las* system on the *rhl* system). These adjustments (parameters summarized in Table S.6) allow the multi-signal architecture to represent the alternate models Figure [-@fig:architectures] depicts, but they also diminish the total weight of QS activation processes. To compensate for this diminished activation we also examine rescaled hierarchical and rescaled independent parameter sets, where the maximal activation weightings are held constant across models (parameters in table S.7).

Using our alternate models, we examine in Figure [-@fig:lasb_heatmaps] how equilibrium *lasB* expression changes over a range of population densities *N* and mass transfer rates *m*, for all three architectures. Note that in Figure [-@fig:lasb_heatmaps]A (reciprocal architecture) with *m =* 0, we recover the graded response to increasing stationary density *N* predicted theoretically and confirmed empirically in Figure [-@fig:lasb_response]. Looking across alternate models without rescaling (Figures [-@fig:lasb_heatmaps]A-C) we see that removing activating processes from *rhl* to *las* (hierarchical model) and also from *las* to *rhl* (independent model) leads unsurprisingly to a general weakening of QS maximal response. In the re-scaled models (Figures [-@fig:lasb_heatmaps]D-F) we normalize maximal expression, so we can contrast functional responses to changes in density and mass transfer. Comparing these panels we can see that changes in architecture change the functional response to environmental variables. In comparison to the hierarchical or independent models, the reciprocal architecture broadens the environmental parameter space where *lasB* expression is elevated (areas above 5% black line, and above 50% white line), and also reduces the slope of activation contours (angles of black and white lines). The change in contour slope indicates a greater robustness to increasing mass transfer, given a reciprocal activation architecture. In Figure S.8 we assess the temporal activation dynamics of *lasB* under the three alternate architectures, and highlight that even under the rescaled model the reciprocal architecture provides the most rapid activation process (given high density and low mass transfer).



![lasb_heatmaps](Figures/lasb_heatmaps.svg){#fig:lasb_heatmaps}

<div custom-style="Caption"><p>
**Figure [-@fig:lasb_heatmaps]. The reciprocal QS architecture generates a greater response to population density and is more robust to environmental interference.** The figure shows heat maps of _lasB_ expression levels for three quorum sensing architectures. Both population density and mass transfer rate are varied over the same ranges for all heatmaps. The lines on each heat map indicate density and mass transfer values for which _lasB_ expression is constant, either 50% of its maximum value (white) or 5% of its maximum value (black). Expression levels calculated from equation [-@eq:multisignal] model with parameters from Tables S.5, S.6 and S.7.
</p></div>

## Discussion

In this study we consider different architectures for multi-signal quorum sensing systems (Figure [-@fig:architectures]) and show that the conventional *las-rhl* hierarchical view of QS in *P. aeruginosa* (Figure [-@fig:hierarchy]) is incomplete. Specifically, we find that both the *las* and *rhl* systems regulate each other. Figure [-@fig:single_c12] corroborates the influence of *las* on *rhl*, but, contrary to the hierarchical view, we also show in Figure [-@fig:single_c4] that the *rhl* signal C<sub>4</sub>‑HSL can influence the *las* synthase *lasI.* This effect is substantial, as C<sub>4</sub>‑HSL alone induces more than a six-fold increase in *lasI* expression compared to basal levels. We confirm these results when both signals are present simultaneously (Figure [-@fig:combined]), and further show that both *las* and *rhl* synthase genes require both signals for maximal expression. By fitting a mathematical model, we demonstrate that simple additive effects are insufficient to explain our data (Figure [-@fig:single_all]). Closing the gap apparent in Figure [-@fig:single_all] requires that the signals interact cooperatively to augment their additive effects. By modeling both the reciprocal relationship and the effect of cooperativity, we provide a quantitative model for QS in a model system, and conclude that the *las*-*rhl* relationship forms a biased reciprocal network (Figure [-@fig:reciprocal]). We then model the effect of this architecture on a representative QS-controlled gene (*lasB*) and compare the results with other architectures. We demonstrate that the type of architecture can have a qualitative effect on QS-mediated behavior. In particular, we find that, compared to a strict hierarchy, the reciprocal architecture results in *lasB* expression that is more sensitive to population density and more robust in the presence of environmental interference (Figure [-@fig:lasb_heatmaps]).

By focusing on signal concentration as the factor determining behavior, our approach accommodates multiple possible molecular mechanisms. It does mean, however, that we cannot easily distinguish between them. For example, C<sub>4</sub>‑HSL could be causing an increase in *lasI* expression by enabling the formation of LasR dimers, albeit less efficiently than 3‑oxo‑C<sub>12</sub>‑HSL. Alternatively, it could be the case that the RhlR/C<sub>4</sub>‑HSL complex serves as an activating transcription factor for *lasI.* Additional experiments would be required to distinguish between these two cases.

It should be noted that our use of *ΔlasIΔrhlI* cells might cause differences between our observations and wild type responses. In particular, we make two assumptions about the mutant strain. First, we assume that the only effect of the *lasI* and *rhlI* deletions is an inability to successfully produce LasI and RhlI proteins. Secondly, we assume that the only relevant phenotypic function of those proteins is the synthesis of the corresponding signal molecules. Although we cannot rule out pleiotropic effects from the strain construction or lack of synthase proteins, we find no reports of pleiotropic effects in the literature and do not expect that any such effects would alter our conclusions.

Our first key result demonstrates that the *las* and *rhl* systems form a reciprocal architecture, extending existing research into the relationship between those systems. Many researchers [@Pesci1997; @deKievit2002; @Medina2003] have shown that the *las* system is essential for maximal expression of genes in the *rhl* system. Our data substantiates those results, but we also show the converse: the *rhl* system, in particular its signal C<sub>4</sub>‑HSL, is essential for maximum expression of a gene in the *las* system. We further extend prior results by considering the combination of both signals and by quantifying the relationship between the systems. Most previous attempts at this quantification have assumed a hierarchical architecture. For example, de Kievit et al. [-@deKievit2002] demonstrate that LasR/3‑oxo‑C<sub>12</sub>‑HSL alone influences *rhlI* expression more than RhlR/C<sub>4</sub>‑HSL alone, a result consistent with our data. Their analysis, however, is limited to measuring the response of the *rhl* system. Analyses of the effect of C<sub>4</sub>‑HSL on the *las* system are much less common, though Wargo and Hogan [-@Wargo2007] do report that a *rhlI* mutant produced the same 3‑oxo‑C<sub>12</sub>‑HSL concentrations as wild type. Those experiments were conducted in *Escherichia coli,* however, and the authors acknowledge that *E. coli* may include its own regulators that mimic the behavior of C<sub>4</sub>‑HSL. As with other published reports, the focus is on single signals in isolation, which necessarily neglects the effect of both signals combined.

In shifting from the molecular to the population level, we adopt common single signal QS mathematical models [@Dockery2001; @Brown2013]. This approach has produced both theoretical conjectures [@Pai2009] and experimental interpretations [@Fekete2010]. Our analysis extends the models to account for multiple QS signals and interactions between them. In this way we can study not only isolated quorum sensing systems, but also networks of interrelated systems. We can both characterize the architectures of those systems and quantify the intra-system and inter-system effects.

By choosing the *las* and *rhl* quorum sensing systems for this study, we focus on a relatively straightforward QS architecture. It consists of only two systems that reinforce each other. *P. aeruginosa* has other QS systems such as *pqs* [@Pesci1999], however, and it is not unique in having more than two. Other species (*V. cholerae,* *A. fischeri,* and *V. harveyi*) have at least three parallel systems [@Waters2005], and some may have as many as eight [@Brachmann2013]. Our modeling approach can accomodate all of these species as Equations [-@eq:multisignal] and [-@eq:dynamics] allow for any number of distinct QS systems.

Furthermore, different systems do not always reinforce each other. In some cases one system can repress another, as is the case with the *pqs* system of *P. aeruginosa* [@McGrath2004]. Cross-system repression has been identified in *B. subtilis* [@Lazazzera1997], *V. fluvialis* [@Wang2013], and *V. cholerae* [@Herzog2019]. Quantifying that repression with our models can distinguish different population-level behaviors. Repression by one system can limit expression of the other system, or it can stop expression entirely. Those possibilities may have vastly different effects on the population-level response to changes in stationary phase density.

Finally, although we are able to model QS architectures at the cellular and population level, it is not clear how traditional gene regulatory networks can achieve the responses we observe. Syed et al. [-@Syed2023] show that gene expression cooperativity in *Drosophila* may be driven by enhancers, but their results are limited to a single transcription factor with multiple binding sites. Long et al. [-@Long2009] suggest that multiple activating transcription factors combine additively, but that can only be true if the effects of each are independent. In contrast, Kaplan et al. [-@Kaplan2008] claim that multiple inputs controlling gene expression usually combine multiplicatively. This relationship holds when the binding of one factor to the promoter depends on the presence of the second at that promoter. As Figure [-@fig:single_all] makes clear, neither approach can adequately explain our data.

Sauer et al. [-@Sauer1995] make related observations for a protein complex in *Drosophila melanogaster*; both of the developmental regulators BCD and HB alone induce a 6-fold increase by themselves but combine to induce a greater than 65-fold increase. These results offer a tantalizing possibility that further investigations into the mechanisms of *P. aeruginosa* quorum sensing interactions can provide insights into more general gene regulatory networks.

## Methods

### Data Collection

We used three strains for the experimental observations: l*asB:luxCDABE* genomic reporter fusion in NPAO1∆*lasI*∆*rhlI,* *lasI:luxCDABE* genomic reporter fusion in NPAO1∆*lasI*∆*rhlI,* and *rhlI:luxCDABE* genomic reporter fusion in NPAO1∆*lasI*∆*rhlI.* We streaked out all strains in Luria-Bertani (LB) agar at 37°C for 24 hours and then subcultured a single colony in 10 mL LB, incubated at 37°C under shaking conditions (180 rpm) for 24 hours.

We prepared 3‑oxo‑C<sub>12</sub>‑HSL and C<sub>4</sub>‑HSL in methanol at 7 different concentrations: 0.1, 0.5, 1, 2, 3, 4 and 5 µM, each diluted from 100 mM stock. We centrifuged all cultures and washed each three times using PBS. We then re-suspended in LB and diluted to an OD (600) of 0.05. We then transferred 200 µl of each culture to a black 96-well plate with a clear bottom and inoculated with signals at the indicated concentrations. We repeated each experiment to generate five replicates. Methanol with no signal was used as a control. The plates were incubated in BioSpa at 37°c for 18 h. Measurements of OD (600) and RLU (Relative Luminescence Units) were collected every hour.

### Data Analysis

We estimated parameter values in Tables S.3, S.4, S.5, and S.6 with non-linear regression by least squares using the Gauss-Newton algorithm [@Ratkowsky1983]. Observations were limited to time ranges with peak expression values. (See supporting Information for detailed time course analysis.) Comparisons of model predictions and observed values are available in supporting Information. Equilibrium values shown in Figure [-@fig:lasb_response] were computed using a Trust-Region-Dogleg Algorithm [@Powell1968]. Analyses performed and data visualizations created with _MATLAB: Version 9.13 (R2022b)_ from The MathWorks Inc., Natick, MA and *Stata Statistical Software: Release 17* from StataCorp LLC, College Station, TX. All original code is available on GitHub at https://github.com/GaTechBrownLab.

Additional third-party modules:

<div custom-style="Bibliography"><p>
Jann B. “PALETTES: Stata module to provide color palettes, symbol palettes, and line pattern palettes,” *Statistical Software Components* S458444, Boston College Department of Economics, 2017, revised 27 May 2020.
</p></div>

<div custom-style="Bibliography"><p>
Jann B. “COLRSPACE: Stata module providing a class-based color management system in Mata,” *Statistical Software Components* S458597, Boston College Department of Economics, 2019, revised 06 Jun 2020.
</p></div>

<div custom-style="Bibliography"><p>
Jann B. “HEATPLOT: Stata module to create heat plots and hexagon plots,” _Statistical Software Components_ S458598, Boston College Department of Economics, 2019, revised 13 Oct 2020.
</p></div>

Custom color schemes adapted from seaboarn.

<div custom-style="Bibliography"><p>
Watson ML. “seaborn: statistical data visualization.” *Journal of Open Source Software* 2021 Apr 06;**6(60)**: doi: 10.21105/joss.03021.
</p></div>
## References

