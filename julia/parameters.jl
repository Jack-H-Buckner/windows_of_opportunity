# Default parameters (as a NamedTuple)
const default_params = (
    # Income model
    Ȳ   = 2.0,       # Baseline income (no-loss year)
    ϕ   = 0.5,       # Fraction of income lost in event

    # Risk model (linear probability)
    p₀  = 0.0,       # Initial loss probability
    t₀  = 2020,      # Reference year
    b   = 1/150,     # Rate of increase in p (per year)

    # Preferences
    λ   = 1.0,       # Risk aversion parameter

    # Insurance
    ρ   = 0.9,       # Index-loss correlation
    Q   = 0.05,      # Variable expense ratio
    cₓ  = 0.02,      # Fixed cost of insurance contract (c_f)

    # Outside option
    Ū   = 1.5,       # Utility from alternative livelihood

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
