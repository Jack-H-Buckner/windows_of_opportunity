# CLAUDE.md — Instructions for building this project

## Project Goal

Build a clean, reproducible Julia + R pipeline that generates publication-quality figures for a paper on using parametric insurance to adapt to ecosystem tipping points. The mathematical model is fully specified in `README.md`. Read it first.

**Language split:** Julia handles all computation and data generation. R handles all plotting. Data passes between them as CSV files in `data/`.

## Key Design Decisions

### Model Choice
This codebase uses the **simple linear risk model** (probability of loss increases linearly over time) combined with the **full insurance/utility framework** from the Finsurance paper. Specifically:

- **Risk model**: `p_t = p_0 + b * (t - t_0)` — a linearly increasing probability of a bad year
- **Income**: Bernoulli — either `Y_bar` (good year) or `Y_bar * (1 - phi)` (bad year)
- **Utility**: Mean-variance preferences `U = E[Y] - (lambda/2) * Var[Y]`
- **Insurance premium**: Pure premium method `Pi = (delta * p_t * Delta + c_f) / (1 - Q)`
- **Variance with insurance**: `Var[Z] = (1 + delta^2 - 2*rho*delta) * Var[Y]`
- **Optimal coverage**: `delta_star = rho - Q / (lambda * (1-Q) * Delta * (1-p_t))`
- **Window of opportunity**: `delta_plus > 0` when `U_delta_star > U_0` and `U_delta_star > U_bar`

We do NOT use the population dynamics simulation model (logistic growth + Type III functional response) from the Finsurance paper. That model is replaced by the simple linear `p_t` formulation.

### Architecture
- `julia/parameters.jl`: Single source of truth for all default parameters and sensitivity ranges
- `julia/model.jl`: Pure functions, no side effects, no I/O. Takes parameters, returns values.
- `julia/analysis.jl`: Includes `parameters.jl` and `model.jl`, runs baseline and sensitivity analyses, writes CSVs to `data/`.
- `R/plot_*.R`: Each script reads CSVs from `data/`, produces one figure in `figures/`.
- `run.sh`: Runs Julia analysis then R plotting scripts in order.

### Julia Style
- Use broadcasting (`.`) for vectorized operations over arrays
- Use `DataFrames.jl` for tabular output and `CSV.jl` for writing
- Use `Roots.jl` (`find_zero`) for locating window boundaries in the sensitivity analysis
- All functions should have docstrings (triple-quoted `""" ... """`)
- Use descriptive variable names matching the math (e.g., `δ_star`, `λ`, `ρ` — Julia supports Unicode)
- Functions should be type-stable; use concrete types where possible

### R / ggplot Style
- Use `ggplot2` with `theme_classic()` as the base theme for all figures
- Font size: 12pt for axis labels, 10pt for tick labels
- Color palette: blue (`#2171B5`) for insured, orange/red (`#E6550D`) for uninsured, green (`#31A354`) for alternative livelihood
- Figures saved as PNG at **400 dpi** using `ggsave(..., dpi = 400)`
- Figure size: single-column `width = 3.5, height = 3` or double-column `width = 7, height = 3` (inches)
- Use `patchwork` for multi-panel layouts
- Load data with `readr::read_csv()` for consistency

## File-by-file Specification

### `julia/parameters.jl`

```julia
# Default parameters (as a NamedTuple or Dict)
const default_params = (
    # Income model
    Ȳ   = 2.0,       # Baseline income (no-loss year)
    ϕ   = 0.5,       # Fraction of income lost in event

    # Risk model (linear probability)
    p₀  = 0.0,       # Initial loss probability
    t₀  = 2020,      # Reference year
    b   = 1/150,      # Rate of increase in p (per year)

    # Preferences
    λ   = 1.0,        # Risk aversion parameter

    # Insurance
    ρ   = 0.9,        # Index-loss correlation
    Q   = 0.02,       # Variable expense ratio
    cₓ  = 0.02,       # Fixed cost of insurance contract (c_f)

    # Outside option
    Ū   = 1.5,        # Utility from alternative livelihood

    # Simulation
    t_start = 2020,
    t_end   = 2170,
)

# Sensitivity analysis ranges (uniform distributions)
const sensitivity_ranges = Dict(
    :λ   => (0.5, 3.0),
    :ρ   => (0.5, 1.0),
    :Q   => (0.0, 0.1),
    :cₓ  => (0.0, 0.1),
    :ϕ   => (0.2, 0.8),
    :Ȳ   => (1.0, 3.0),
    :b   => (1/300, 1/75),
    :Ū   => (0.5, 2.5),
)

const n_sensitivity_samples = 1000
```

### `julia/model.jl`

Functions to implement:

```julia
"""
    loss_probability(t, p₀, b, t₀)

Compute p_t = p₀ + b * (t - t₀), clipped to [0, 1].
"""
function loss_probability(t, p₀, b, t₀)

"""
    expected_income(Ȳ, ϕ, p_t)

E[Y_t] = Ȳ - p_t * ϕ * Ȳ
"""
function expected_income(Ȳ, ϕ, p_t)

"""
    variance_income(Ȳ, ϕ, p_t)

Var[Y_t] = p_t * (1 - p_t) * (ϕ * Ȳ)^2
"""
function variance_income(Ȳ, ϕ, p_t)

"""
    utility_no_insurance(Ȳ, ϕ, p_t, λ)

U₀ = E[Y] - (λ/2) * Var[Y]
"""
function utility_no_insurance(Ȳ, ϕ, p_t, λ)

"""
    optimal_coverage(ρ, Q, λ, Δ, p_t)

δ* = ρ - Q / (λ * (1-Q) * Δ * (1 - p_t))
Returns max(δ*, 0). Δ = ϕ * Ȳ is the loss magnitude.
"""
function optimal_coverage(ρ, Q, λ, Δ, p_t)

"""
    premium(δ, p_t, Δ, Q, cₓ)

Π = (δ * p_t * Δ + cₓ) / (1 - Q)
"""
function premium(δ, p_t, Δ, Q, cₓ)

"""
    variance_with_insurance(δ, ρ, var_Y)

Var[Z] = (1 + δ^2 - 2ρδ) * Var[Y]
"""
function variance_with_insurance(δ, ρ, var_Y)

"""
    utility_with_insurance(Ȳ, ϕ, p_t, λ, δ, ρ, Q, cₓ)

Full utility with insurance at coverage δ.
U_δ = E[Y] - Q*δ*p_t*Δ/(1-Q) - cₓ/(1-Q) - (λ/2)*(1 + δ² - 2ρδ)*Var[Y]
"""
function utility_with_insurance(Ȳ, ϕ, p_t, λ, δ, ρ, Q, cₓ)

"""
    effective_coverage(Ȳ, ϕ, p_t, λ, ρ, Q, cₓ, Ū)

Returns δ⁺: the effective optimal coverage.
δ⁺ = δ* if U(δ*) > U₀ and U(δ*) > Ū, else 0.
"""
function effective_coverage(Ȳ, ϕ, p_t, λ, ρ, Q, cₓ, Ū)

"""
    window_of_opportunity(t_array, Ȳ, ϕ, p₀, b, t₀, λ, ρ, Q, cₓ, Ū)

Returns a DataFrame with columns:
  t, p_t, U_0, U_delta, delta_plus, window_open
"""
function window_of_opportunity(t_array, Ȳ, ϕ, p₀, b, t₀, λ, ρ, Q, cₓ, Ū)
```

### `julia/analysis.jl`

This is the main entry point. It:

1. `include("parameters.jl")` and `include("model.jl")`
2. **Baseline analysis**: Call `window_of_opportunity` with default params over `t_start:t_end`. Write `data/baseline.csv` with columns: `t, p_t, U_0, U_delta, delta_plus, window_open, premium, expected_claims`.
3. **Sensitivity in probability space**: For each parameter `θ` in (`λ`, `ρ`, `Q`, `cₓ`, `ϕ`, `Ū`), perturb by `δ = 1e-4`, recompute where the window opens/closes in probability space using `find_zero`, and calculate elasticity `θ * ∂p_boundary/∂θ`. Note: `b` and `p₀` are excluded because the window boundaries in probability space do not depend on how fast `p` changes over time. Write `data/sensitivity_p.csv` with columns: `param`, `param_label`, `elasticity_open`, `elasticity_close`.
4. **Sensitivity in time space**: For each parameter `θ` in (`λ`, `ρ`, `Q`, `cₓ`, `ϕ`, `Ū`, `p₀`, `b`), perturb by `δ = 1e-4`, recompute where the window opens/closes in time using the mapping `t = t₀ + (p - p₀)/b`, and calculate elasticity `θ * ∂t_boundary/∂θ`. This brings `b` and `p₀` into the analysis — a faster rate of risk increase (`b`) compresses the window in real time even if the probability boundaries are unchanged. Write `data/sensitivity_t.csv` with columns: `param`, `param_label`, `elasticity_open`, `elasticity_close`.

### `R/plot_utility.R`
- Read `data/baseline.csv`
- Main figure: two-panel layout (`patchwork`)
  - Left panel: utility vs probability `p_t`
  - Right panel: utility vs time `t`
- Three curves per panel:
  - Orange/red (`#E6550D`): utility without insurance (`U_0`)
  - Blue (`#2171B5`): utility with optimal insurance (`U_delta`)
  - Green (`#31A354`) horizontal dashed line: alternative utility (`U_bar`)
- Two shaded regions per panel:
  - Grey (alpha 0.1): **window of opportunity** — from where insured > uninsured to where insured < `U_bar`
  - Purple (alpha 0.1): **window of adaptation** — from where uninsured < `U_bar` to where insured < `U_bar`
- Legend at top-right or outside right
- `theme_classic()` base, `ggsave("figures/utility_window.png", dpi = 400, width = 7, height = 3)`

### `R/plot_sensitivity_p.R`
- Read `data/sensitivity_p.csv`
- Two-panel horizontal lollipop chart (`patchwork`), sorted by absolute elasticity magnitude
  - Left panel: **"Beginning of window"** — elasticity of the probability where the window opens
  - Right panel: **"End of window"** — elasticity of the probability where the window closes
- Parameters included: `λ`, `ρ`, `Q`, `c_f`, `ϕ`, `Ū` (no `b` or `p₀`)
- Each point is a dot connected to a vertical dashed line at zero by a horizontal grey segment (lollipop style)
- Y-axis: parameter display labels (e.g., "Risk aversion λ", "Fixed costs c_f")
- X-axis: "Elasticity (proportional effect)"
- `theme_classic()`, `ggsave("figures/sensitivity_p.png", dpi = 400, width = 7, height = 3.5)`

### `R/plot_sensitivity_t.R`
- Read `data/sensitivity_t.csv`
- Same two-panel horizontal lollipop layout as `plot_sensitivity_p.R`
  - Left panel: **"Beginning of window"** — elasticity of the time when the window opens
  - Right panel: **"End of window"** — elasticity of the time when the window closes
- Parameters included: `λ`, `ρ`, `Q`, `c_f`, `ϕ`, `Ū`, `p₀`, **`b`** (full set)
- X-axis: "Elasticity (proportional effect on time)"
- `theme_classic()`, `ggsave("figures/sensitivity_t.png", dpi = 400, width = 7, height = 4)`

### `R/plot_risk_premium.R`
- Read `data/baseline.csv`
- Two-panel layout (`patchwork`):
  - Left panel: loss probability `p_t` vs time `t` — a single increasing line
  - Right panel: insurance premium `premium` and expected claims `expected_claims` vs time `t` — two lines showing the loading/markup
- `theme_classic()`, `ggsave("figures/risk_premium.png", dpi = 400, width = 7, height = 3)`

### `run.sh`
```bash
#!/bin/bash
set -e

mkdir -p data figures

echo "=== Running Julia analysis ==="
julia julia/analysis.jl

echo "=== Generating figures in R ==="
Rscript R/plot_utility.R
Rscript R/plot_sensitivity_p.R
Rscript R/plot_sensitivity_t.R
Rscript R/plot_risk_premium.R

echo "=== Pipeline complete. Figures in figures/ ==="
```

## Plotting Style Reference (R/ggplot2)

All R scripts should include this common theme setup at the top:

```r
library(ggplot2)
library(dplyr)
library(readr)
library(patchwork)

# Color palette
col_insured    <- "#2171B5"
col_uninsured  <- "#E6550D"
col_alternative <- "#31A354"

# Common theme
theme_pub <- theme_classic() +
  theme(
    text = element_text(size = 12),
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 12),
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.margin = margin(5, 10, 5, 5)
  )
```

Consider extracting this into an `R/theme.R` file that gets `source()`d by each plotting script.

## Testing

Add basic sanity checks in `julia/analysis.jl` (or a separate `julia/test_model.jl`):
- `δ*` should be ≈ 0 when `p_t = 0` (no risk, no need for insurance)
- `δ*` should approach `ρ` when `Q = 0` (no expenses)
- `U_δ >= U₀` when `δ = δ*` and fixed costs are excluded
- Utility without insurance should decrease monotonically as `p_t` increases
- Window should open and close for default parameters
