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
Rscript R/plot_risk_premium.R
Rscript R/plot_combined_p.R
Rscript R/plot_combined_t.R

echo "=== Pipeline complete. Figures in figures/ ==="
