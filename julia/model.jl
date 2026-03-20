"""
    loss_probability(t, p₀, b, t₀)

Compute p_t = p₀ + b * (t - t₀), clipped to [0, 1].
"""
function loss_probability(t, p₀, b, t₀)
    return clamp(p₀ + b * (t - t₀), 0.0, 1.0)
end

"""
    expected_income(Ȳ, ϕ, p_t)

E[Y_t] = Ȳ - p_t * ϕ * Ȳ
"""
function expected_income(Ȳ, ϕ, p_t)
    return Ȳ - p_t * ϕ * Ȳ
end

"""
    variance_income(Ȳ, ϕ, p_t)

Var[Y_t] = p_t * (1 - p_t) * (ϕ * Ȳ)^2
"""
function variance_income(Ȳ, ϕ, p_t)
    return p_t * (1 - p_t) * (ϕ * Ȳ)^2
end

"""
    utility_no_insurance(Ȳ, ϕ, p_t, λ)

U₀ = E[Y] - (λ/2) * Var[Y]
"""
function utility_no_insurance(Ȳ, ϕ, p_t, λ)
    EY = expected_income(Ȳ, ϕ, p_t)
    VY = variance_income(Ȳ, ϕ, p_t)
    return EY - (λ / 2) * VY
end

"""
    optimal_coverage(ρ, Q, λ, Δ, p_t)

δ* = ρ - Q / (λ * (1-Q) * Δ * (1 - p_t))

Returns max(δ*, 0). Δ = ϕ * Ȳ is the loss magnitude.
"""
function optimal_coverage(ρ, Q, λ, Δ, p_t)
    p_t >= 1.0 && return 0.0
    δ_star = ρ - Q / (λ * (1 - Q) * Δ * (1 - p_t))
    return max(δ_star, 0.0)
end

"""
    premium(δ, p_t, Δ, Q, cₓ)

Π = (δ * p_t * Δ + cₓ) / (1 - Q)
"""
function premium(δ, p_t, Δ, Q, cₓ)
    return (δ * p_t * Δ + cₓ) / (1 - Q)
end

"""
    variance_with_insurance(δ, ρ, var_Y)

Var[Z] = (1 + δ^2 - 2ρδ) * Var[Y]
"""
function variance_with_insurance(δ, ρ, var_Y)
    return (1 + δ^2 - 2 * ρ * δ) * var_Y
end

"""
    utility_with_insurance(Ȳ, ϕ, p_t, λ, δ, ρ, Q, cₓ)

Full utility with insurance at coverage δ.
U_δ = E[Y] - Q*δ*p_t*Δ/(1-Q) - cₓ/(1-Q) - (λ/2)*(1 + δ² - 2ρδ)*Var[Y]
"""
function utility_with_insurance(Ȳ, ϕ, p_t, λ, δ, ρ, Q, cₓ)
    Δ = ϕ * Ȳ
    EY = expected_income(Ȳ, ϕ, p_t)
    VY = variance_income(Ȳ, ϕ, p_t)
    return EY - Q * δ * p_t * Δ / (1 - Q) - cₓ / (1 - Q) - (λ / 2) * (1 + δ^2 - 2 * ρ * δ) * VY
end

"""
    effective_coverage(Ȳ, ϕ, p_t, λ, ρ, Q, cₓ, Ū)

Returns δ⁺: the effective optimal coverage.
δ⁺ = δ* if U(δ*) > U₀ and U(δ*) > Ū, else 0.
"""
function effective_coverage(Ȳ, ϕ, p_t, λ, ρ, Q, cₓ, Ū)
    Δ = ϕ * Ȳ
    δ_star = optimal_coverage(ρ, Q, λ, Δ, p_t)
    δ_star == 0.0 && return 0.0

    U_ins = utility_with_insurance(Ȳ, ϕ, p_t, λ, δ_star, ρ, Q, cₓ)
    U_no  = utility_no_insurance(Ȳ, ϕ, p_t, λ)

    if U_ins > U_no && U_ins > Ū
        return δ_star
    else
        return 0.0
    end
end

"""
    window_of_opportunity(t_array, Ȳ, ϕ, p₀, b, t₀, λ, ρ, Q, cₓ, Ū)

Returns a DataFrame with columns:
  t, p_t, U_0, U_delta, delta_plus, window_open, premium, expected_claims
"""
function window_of_opportunity(t_array, Ȳ, ϕ, p₀, b, t₀, λ, ρ, Q, cₓ, Ū)
    Δ = ϕ * Ȳ

    n = length(t_array)
    col_t       = collect(t_array)
    col_p       = loss_probability.(t_array, p₀, b, t₀)
    col_U0      = utility_no_insurance.(Ȳ, ϕ, col_p, λ)
    col_δ_star  = optimal_coverage.(ρ, Q, λ, Δ, col_p)
    col_δ_plus  = effective_coverage.(Ȳ, ϕ, col_p, λ, ρ, Q, cₓ, Ū)
    col_U_delta = utility_with_insurance.(Ȳ, ϕ, col_p, λ, col_δ_star, ρ, Q, cₓ)
    col_window  = col_δ_plus .> 0.0
    col_premium = premium.(col_δ_plus, col_p, Δ, Q, cₓ)
    col_claims  = col_δ_plus .* col_p .* Δ

    return DataFrame(
        t               = col_t,
        p_t             = col_p,
        U_0             = col_U0,
        U_delta         = col_U_delta,
        delta_plus      = col_δ_plus,
        window_open     = col_window,
        premium         = col_premium,
        expected_claims = col_claims,
    )
end
