using CSV, DataFrames, Roots

include("parameters.jl")
include("model.jl")

# ─── Parameter labels for sensitivity output ────────────────────────────────

const param_labels = Dict(
    :λ  => "Risk aversion λ",
    :ρ  => "Correlation ρ",
    :Q  => "Variable costs Q",
    :cₓ => "Fixed costs cₓ",
    :ϕ  => "Loss fraction ϕ",
    :Ū  => "Alternative utility Ū",
    :b  => "Risk increase rate b",
    :p₀ => "Initial probability p₀",
)

# ─── Window boundary finding ────────────────────────────────────────────────

"""
    find_window_p(Ȳ, ϕ, λ, ρ, Q, cₓ, Ū)

Find the loss probabilities at which the window of opportunity opens and closes.
Uses a coarse grid to bracket the transitions, then refines with `find_zero`.
Returns `(p_open, p_close)` or `(NaN, NaN)` if no window exists.
"""
function find_window_p(Ȳ, ϕ, λ, ρ, Q, cₓ, Ū)
    Δ = ϕ * Ȳ

    # Gain from insurance over no insurance (at optimal δ*)
    function gain(p)
        δs = optimal_coverage(ρ, Q, λ, Δ, p)
        return utility_with_insurance(Ȳ, ϕ, p, λ, δs, ρ, Q, cₓ) -
               utility_no_insurance(Ȳ, ϕ, p, λ)
    end

    # Insured utility minus alternative livelihood
    function insured_vs_alt(p)
        δs = optimal_coverage(ρ, Q, λ, Δ, p)
        return utility_with_insurance(Ȳ, ϕ, p, λ, δs, ρ, Q, cₓ) - Ū
    end

    # Coarse grid to locate transitions
    ps = range(0.001, 0.999, length=10_000)
    window = [effective_coverage(Ȳ, ϕ, p, λ, ρ, Q, cₓ, Ū) > 0 for p in ps]

    first_open = findfirst(window)
    last_open  = findlast(window)

    if isnothing(first_open) || isnothing(last_open)
        return NaN, NaN
    end

    # Refine opening boundary
    p_lo = first_open > 1 ? ps[first_open - 1] : 0.001
    p_hi = ps[first_open]
    if gain(p_lo) * gain(p_hi) < 0
        p_open = find_zero(gain, (p_lo, p_hi))
    elseif insured_vs_alt(p_lo) * insured_vs_alt(p_hi) < 0
        p_open = find_zero(insured_vs_alt, (p_lo, p_hi))
    else
        p_open = p_hi
    end

    # Refine closing boundary
    p_lo = ps[last_open]
    p_hi = last_open < length(ps) ? ps[last_open + 1] : 0.999
    if insured_vs_alt(p_lo) * insured_vs_alt(p_hi) < 0
        p_close = find_zero(insured_vs_alt, (p_lo, p_hi))
    elseif gain(p_lo) * gain(p_hi) < 0
        p_close = find_zero(gain, (p_lo, p_hi))
    else
        p_close = p_lo
    end

    return p_open, p_close
end

"""
    p_to_t(p, p₀, b, t₀)

Map a probability boundary to a time: t = t₀ + (p - p₀) / b.
"""
p_to_t(p, p₀, b, t₀) = t₀ + (p - p₀) / b

# ─── Helpers to get/set parameters by symbol ────────────────────────────────

"""
    get_param(params, sym)

Retrieve a parameter value from a NamedTuple by symbol.
"""
get_param(params, sym) = getfield(params, sym)

"""
    set_param(params, sym, val)

Return a new NamedTuple with one parameter replaced.
"""
function set_param(params, sym, val)
    d = Dict(pairs(params))
    d[sym] = val
    return (; d...)
end

# ─── Sensitivity analysis ───────────────────────────────────────────────────

"""
    sensitivity_p(params; δ=1e-4)

Compute elasticities of window boundaries in probability space for each
parameter in (λ, ρ, Q, cₓ, ϕ, Ū). Returns a DataFrame.
"""
function sensitivity_p(params; δ=1e-4)
    p = params
    p_open_base, p_close_base = find_window_p(p.Ȳ, p.ϕ, p.λ, p.ρ, p.Q, p.cₓ, p.Ū)

    sens_params = [:λ, :ρ, :Q, :cₓ, :ϕ, :Ū]
    rows = []

    for θ in sens_params
        θ_val = get_param(p, θ)
        h = max(abs(θ_val) * δ, δ)

        p_pert = set_param(p, θ, θ_val + h)
        p_open_pert, p_close_pert = find_window_p(p_pert.Ȳ, p_pert.ϕ, p_pert.λ, p_pert.ρ, p_pert.Q, p_pert.cₓ, p_pert.Ū)

        elas_open  = θ_val * (p_open_pert - p_open_base) / h
        elas_close = θ_val * (p_close_pert - p_close_base) / h

        push!(rows, (
            param       = String(θ),
            param_label = param_labels[θ],
            elasticity_open  = elas_open,
            elasticity_close = elas_close,
        ))
    end

    return DataFrame(rows)
end

"""
    sensitivity_t(params; δ=1e-4)

Compute elasticities of window boundaries in time space for each parameter
in (λ, ρ, Q, cₓ, ϕ, Ū, p₀, b). Returns a DataFrame.
"""
function sensitivity_t(params; δ=1e-4)
    p = params

    # Base boundaries: first in p-space, then map to t
    p_open_base, p_close_base = find_window_p(p.Ȳ, p.ϕ, p.λ, p.ρ, p.Q, p.cₓ, p.Ū)
    t_open_base  = p_to_t(p_open_base, p.p₀, p.b, p.t₀)
    t_close_base = p_to_t(p_close_base, p.p₀, p.b, p.t₀)

    sens_params = [:λ, :ρ, :Q, :cₓ, :ϕ, :Ū, :p₀, :b]
    rows = []

    for θ in sens_params
        θ_val = get_param(p, θ)
        h = max(abs(θ_val) * δ, δ)

        p_pert = set_param(p, θ, θ_val + h)

        # Recompute p-space boundaries with perturbed params
        p_open_pert, p_close_pert = find_window_p(p_pert.Ȳ, p_pert.ϕ, p_pert.λ, p_pert.ρ, p_pert.Q, p_pert.cₓ, p_pert.Ū)

        # Map to time using (possibly perturbed) b and p₀
        t_open_pert  = p_to_t(p_open_pert, p_pert.p₀, p_pert.b, p_pert.t₀)
        t_close_pert = p_to_t(p_close_pert, p_pert.p₀, p_pert.b, p_pert.t₀)

        elas_open  = θ_val * (t_open_pert - t_open_base) / h
        elas_close = θ_val * (t_close_pert - t_close_base) / h

        push!(rows, (
            param       = String(θ),
            param_label = param_labels[θ],
            elasticity_open  = elas_open,
            elasticity_close = elas_close,
        ))
    end

    return DataFrame(rows)
end

# ─── Main pipeline ──────────────────────────────────────────────────────────

function main()
    p = default_params
    mkpath("data")

    # ── 1. Baseline analysis ────────────────────────────────────────────────
    println("Running baseline analysis...")
    t_array = p.t_start:p.t_end
    baseline = window_of_opportunity(t_array, p.Ȳ, p.ϕ, p.p₀, p.b, p.t₀, p.λ, p.ρ, p.Q, p.cₓ, p.Ū)
    CSV.write("data/baseline.csv", baseline)
    println("  → data/baseline.csv ($(nrow(baseline)) rows)")

    # Sanity checks
    n_open = sum(baseline.window_open)
    println("  Window open for $n_open / $(nrow(baseline)) time steps")
    @assert n_open > 0 "Window should open for default parameters"
    @assert n_open < nrow(baseline) "Window should close for default parameters"

    # ── 2. Sensitivity in probability space ─────────────────────────────────
    println("Running sensitivity analysis (probability space)...")
    sens_p = sensitivity_p(p)
    CSV.write("data/sensitivity_p.csv", sens_p)
    println("  → data/sensitivity_p.csv")
    println(sens_p)

    # ── 3. Sensitivity in time space ────────────────────────────────────────
    println("Running sensitivity analysis (time space)...")
    sens_t = sensitivity_t(p)
    CSV.write("data/sensitivity_t.csv", sens_t)
    println("  → data/sensitivity_t.csv")
    println(sens_t)

    println("\nAnalysis complete.")
end

main()
