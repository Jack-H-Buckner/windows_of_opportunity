# Insurance for Adapting to Ecosystem Tipping Points

A clean, reproducible analysis exploring when parametric insurance can help resource users adapt to ecosystem regime shifts driven by climate change. The analysis identifies a **window of opportunity** — a finite period during which insurance improves well-being as environmental conditions deteriorate.

**Target journal:** Ecological Economics

## Overview

As climate change pushes social-ecological systems toward tipping points, resource users (e.g., fishers, farmers) face increasing income volatility from "dynamical flickering" between high- and low-productivity regimes. This project models how parametric insurance can buffer that volatility, and identifies the conditions under which insurance is beneficial.

The model combines:
- A **mean-variance utility framework** with index insurance (from Watson et al., 2026)
- A **simple linear risk model** where the probability of a loss event increases over time

## Mathematical Model

### Income and Risk

We assume a resource user earns baseline income $\bar{Y}$ in normal years. In each time period, an adverse event occurs with probability $p_t$, causing the user to lose a fraction $\phi$ of their income. The probability of a loss event increases linearly over time:

$$p_t = p_0 + b \cdot (t - t_0)$$

where $p_0$ is the initial probability of a loss, $b$ is the rate of increase, and $t_0$ is the reference time.

The user's income at time $t$ is a Bernoulli random variable:

$$Y_t = \begin{cases} \bar{Y} & \text{with probability } 1 - p_t \\ \bar{Y}(1 - \phi) & \text{with probability } p_t \end{cases}$$

This gives:

$$E[Y_t] = \bar{Y} - p_t \phi \bar{Y}$$

$$\text{Var}[Y_t] = p_t(1 - p_t)(\phi \bar{Y})^2$$

For notational convenience, define the loss magnitude $\Delta = \phi \bar{Y}$ (the income difference between good and bad years).

### Utility Without Insurance

The resource user has mean-variance preferences with risk aversion parameter $\lambda$:

$$U_0(t) = E[Y_t] - \frac{\lambda}{2} \text{Var}[Y_t]$$

Substituting:

$$U_0(t) = \bar{Y} - p_t \Delta - \frac{\lambda}{2} p_t(1 - p_t) \Delta^2$$

### Index Insurance

A parametric insurance product pays claims based on a binary index $I_t$ that is correlated with the true environmental state. The correlation between the index and actual losses is $\rho$, where $\rho = 1$ implies perfect correlation.

The insurance payout at coverage level $\delta$ is:

$$X_t = I_t \cdot \delta \cdot \Delta$$

The premium is set using the **pure premium method** (Schofield, 1998):

$$\Pi = \frac{\delta \, p_t \, \Delta + c_f}{1 - Q}$$

where $c_f$ is the fixed cost of administering the contract and $Q$ is the variable expense ratio.

### Income With Insurance

Income with insurance is:

$$Z_t = Y_t + \delta \, I_t \, \Delta - \Pi$$

**Expected income with insurance** reduces expected payoffs due to costs:

$$E[Z_t] = E[Y_t] - \frac{Q \, \delta \, p_t \, \Delta}{1 - Q} - \frac{c_f}{1 - Q}$$

**Variance of income with insurance** captures the risk-reduction benefit:

$$\text{Var}[Z_t] = (1 + \delta^2 - 2\rho\delta) \, \text{Var}[Y_t]$$

This follows from the covariance structure between income and insurance payouts (see Appendix C of Watson et al., 2026).

### Expected Utility With Insurance

Combining expected income and variance:

$$U_\delta(t) = E[Y_t] - \frac{Q \, \delta \, p_t \, \Delta}{1 - Q} - \frac{c_f}{1 - Q} - \frac{\lambda}{2}(1 + \delta^2 - 2\rho\delta) \, \text{Var}[Y_t]$$

### Optimal Coverage Level

Maximizing $U_\delta$ with respect to $\delta$ (first-order condition, see Appendix D of Watson et al., 2026):

$$\delta^* = \rho - \frac{Q}{\lambda(1 - Q) \Delta (1 - p_t)}$$

The optimal coverage depends on:
- $\rho$: correlation between insurance payouts and losses (higher → more coverage)
- $Q$: variable expense ratio (higher → less coverage)
- $\lambda$: risk aversion (higher → more coverage)
- $(1 - p_t)$: probability of the high state (acts like $P_H^*$ in the two-state model)

### When Does Insurance Improve Utility?

Insurance is worthwhile (i.e., $\delta^* > 0$ improves over no insurance) when the variance-reduction benefit exceeds fixed costs:

$$\frac{c_f}{1 - Q} < \frac{\lambda}{2}\left(\rho^2 - k^2\right) \text{Var}[Y_t]$$

where $k = \frac{Q}{\lambda(1 - Q) \Delta (1 - p_t)}$.

### The Window of Opportunity

The effective optimal coverage, accounting for the option to not insure or to exit the resource sector entirely, is:

$$\delta^{+(t)} = \begin{cases} \delta^* & \text{if } U_{\delta^*}(t) > U_0(t) \text{ and } U_{\delta^*}(t) > \bar{U} \\ 0 & \text{otherwise} \end{cases}$$

where $\bar{U}$ is the utility from an alternative livelihood.

The **window of opportunity** is the set of times $t$ where $\delta^+(t) > 0$. It:
- **Opens** when loss risk becomes high enough to justify insurance costs
- **Closes** when conditions deteriorate to the point that even insured resource use is worse than the alternative livelihood

The **window of adaptation** is the interval between when uninsured resource use drops below $\bar{U}$ and when insured resource use drops below $\bar{U}$ — this is the extra time insurance buys for transitioning to alternative livelihoods.

## Parameters

| Parameter | Symbol | Default | Description |
|-----------|--------|---------|-------------|
| Baseline income | $\bar{Y}$ | 2.0 | Income in years without losses |
| Loss fraction | $\phi$ | 0.5 | Fraction of income lost in an event |
| Initial loss probability | $p_0$ | 0.0 | Probability of a loss at $t_0$ |
| Reference time | $t_0$ | 2020 | Year when $p_t = p_0$ |
| Rate of increase | $b$ | 1/150 | Annual increase in loss probability |
| Risk aversion | $\lambda$ | 1.0 | Mean-variance risk aversion parameter |
| Index correlation | $\rho$ | 0.9 | Correlation between index and losses |
| Variable expense ratio | $Q$ | 0.02 | Insurer's variable cost proportion |
| Fixed costs | $c_f$ | 0.02 | Fixed cost of insurance administration |
| Alternative utility | $\bar{U}$ | 1.5 | Utility from alternative livelihood |

## Analyses & Figures

The pipeline produces three main outputs, each generated from a separate analysis step in Julia and plotted in R.

### Analysis 1: Baseline Utility Curves & Window of Opportunity

**Data:** `data/baseline.csv` | **Figure:** `figures/utility_window.png`

Using the default parameters, compute utility with and without optimal insurance across a range of loss probabilities $p \in [0, 1]$ (equivalently, across time $t$). The figure shows three curves: utility without insurance $U_0(p)$, utility with optimal insurance $U_{\delta^*}(p)$, and the alternative livelihood utility $\bar{U}$ as a horizontal line.

Two shaded regions highlight the key intervals. The **window of opportunity** (grey shading) spans from the probability where insured utility first exceeds uninsured utility to the probability where insured utility drops below the alternative livelihood. The **window of adaptation** (purple shading) marks the additional range of probabilities over which insurance extends viable resource use beyond the point where uninsured utility already falls below $\bar{U}$. This figure is presented as a two-panel layout: one panel with probability $p$ on the x-axis and one with time $t$ on the x-axis.

The optimal coverage level $\delta^+(p)$ and the insurance premium $\Pi(p)$ are also computed and saved, though they appear as secondary panels or supplementary figures rather than in the main window-of-opportunity figure.

### Analysis 2: Sensitivity of the Window in Probability Space

**Data:** `data/sensitivity_p.csv` | **Figure:** `figures/sensitivity_p.png`

The sensitivity analysis quantifies how each model parameter affects when the window of opportunity opens and closes. For each parameter, we compute the **elasticity** — the proportional change in the window boundaries (in probability space) per unit change in the parameter, scaled by the parameter value:

$$\text{Elasticity}_{\theta} = \theta \cdot \frac{\partial p_{\text{boundary}}}{\partial \theta}$$

where $\theta$ is any model parameter ($\lambda$, $\rho$, $Q$, $c_f$, $\phi$, $\bar{U}$) and $p_{\text{boundary}}$ is either the probability at which the window opens or closes. Derivatives are computed numerically using a finite difference ($\delta = 10^{-4}$).

Note that $b$ (rate of risk increase) and $p_0$ (initial probability) do not appear in this analysis because the window boundaries in probability space depend only on the utility and insurance equations, not on how fast $p$ changes over time.

The figure is a two-panel horizontal lollipop chart (sorted by absolute elasticity magnitude). The left panel shows the elasticity of the **beginning** of the window (when insurance first becomes worthwhile), and the right panel shows the elasticity of the **end** of the window (when even insured resource use is no longer viable). A vertical dashed line at zero separates parameters that shift the boundary earlier (negative) from those that shift it later (positive).

Parameters are labeled with descriptive names (e.g., "Fixed costs $c_f$", "Risk aversion $\lambda$", "Loss-claims correlation $\rho$").

### Analysis 3: Sensitivity of the Window in Time

**Data:** `data/sensitivity_t.csv` | **Figure:** `figures/sensitivity_t.png`

This analysis complements Analysis 2 by computing elasticities of the window boundaries in **time** rather than probability. Because the mapping from probability to time depends on $p_0$ and $b$ (via $t = t_0 + (p - p_0)/b$), this formulation captures how the rate of environmental change affects the real-world duration and timing of the window.

$$\text{Elasticity}_{\theta} = \theta \cdot \frac{\partial t_{\text{boundary}}}{\partial \theta}$$

where $\theta$ now includes the full parameter set: $\lambda$, $\rho$, $Q$, $c_f$, $\phi$, $\bar{U}$, $p_0$, and $b$. In particular, $b$ enters directly: a faster rate of risk increase compresses the window in time even if the window boundaries in probability space are unchanged.

The figure follows the same two-panel lollipop layout as Analysis 2 but with "Time (years)" on the x-axis of the elasticity values and the full parameter set on the y-axis.

### Analysis 4: Premium and Risk Dynamics

**Data:** `data/baseline.csv` (reuses baseline output) | **Figure:** `figures/risk_premium.png`

A supporting figure showing how the loss probability $p_t$ and the insurance premium $\Pi_t$ evolve over time. Two panels: the left panel plots $p_t$ against time, and the right panel plots the premium alongside the expected claims $p_t \cdot \Delta$ to illustrate the loading (cost markup) of the insurance contract. This provides context for the utility analysis by showing that premiums track expected losses but include a fixed-cost wedge.

### Figure Summary

| Figure | File | Panels | Description |
|--------|------|--------|-------------|
| Window of opportunity | `figures/utility_window.png` | 2 | Utility vs. $p$ and vs. $t$, with shaded window regions |
| Sensitivity (probability) | `figures/sensitivity_p.png` | 2 | Elasticity of window boundaries in probability space |
| Sensitivity (time) | `figures/sensitivity_t.png` | 2 | Elasticity of window boundaries in time; includes $b$ and $p_0$ |
| Risk & premiums | `figures/risk_premium.png` | 2 | Loss probability and premium over time |

## Project Structure

```
├── run.sh                      # Execute the full pipeline (Julia analysis → R plotting)
├── julia/
│   ├── parameters.jl           # All model parameters (defaults + sensitivity ranges)
│   ├── model.jl                # Core model functions (utility, insurance, optimal coverage)
│   └── analysis.jl             # Generate data: baseline + sensitivity → CSV files
├── R/
│   ├── theme.R                 # Shared ggplot2 theme and color palette
│   ├── plot_utility.R          # Figure: utility curves & window of opportunity
│   ├── plot_sensitivity_p.R    # Figure: sensitivity lollipop charts (probability space)
│   ├── plot_sensitivity_t.R    # Figure: sensitivity lollipop charts (time space)
│   └── plot_risk_premium.R     # Figure: loss probability & premium over time
├── data/                       # Generated CSV files (gitignored)
└── figures/                    # Generated figures (gitignored, 400 dpi PNG)
```

## Usage

```bash
# Run the full pipeline (simulate + plot)
bash run.sh

# Or run individual steps
julia julia/analysis.jl              # Generates CSVs in data/
Rscript R/plot_utility.R             # Generates figures/utility_window.png
Rscript R/plot_sensitivity_p.R       # Generates figures/sensitivity_p.png
Rscript R/plot_sensitivity_t.R       # Generates figures/sensitivity_t.png
Rscript R/plot_risk_premium.R        # Generates figures/risk_premium.png
```

## Dependencies

### Julia (≥ 1.9)
- CSV.jl
- DataFrames.jl
- Roots.jl (for finding window boundaries)

### R (≥ 4.0)
- ggplot2
- dplyr
- readr
- patchwork (for multi-panel figures)

Install Julia packages:
```julia
using Pkg
Pkg.add(["CSV", "DataFrames", "Roots"])
```

Install R packages:
```r
install.packages(c("ggplot2", "dplyr", "readr", "patchwork"))
```

## References

- Watson, J.R., Buckner, J., Tilman, A. (2026). Adapting to Ecosystem Tipping Points Using Insurance. *Ecological Economics* (in prep).
- Tilman, A.R., Krueger, E.H., McManus, L.C., Watson, J.R. (2024). Maintaining human wellbeing as socio-environmental systems undergo regime shifts. *Ecological Economics*, 221, 108194.
- Schofield, D.B. (1998). Going from a Pure Premium to a Rate. Casualty Actuarial Society.
