# Optimal Aging and Refill Decisions in a Declining Whiskey Market

EBGN 645 (Computational Economics) course project, Andrew Bauman, Colorado School of Mines.

A mid-size bourbon distiller has a full warehouse of fixed size. Every year it decides
how many barrels of each age to sell and how many new barrels to fill. Zero fills is
allowed, so "sell down and stop refilling" can come out of the model. Each age has its
own downward-sloping demand, so selling several ages at once can be optimal. The
Milestone 2 Faustmann model is kept as a benchmark and supplies the terminal value.

## Files

| File | What it does |
|---|---|
| `params.gms` | Calibration inputs (Table 1). Values marked `(ASSUMED)` are illustrative |
| `calc.gms` | Derived parameters: gallons by age, price curve, demand decline, Faustmann LEV, terminal values |
| `model.gms` | Sets, variables, equations of the dynamic model |
| `solve_scen.gms` | Solves one scenario twice so the terminal value matches the demand slope |
| `run_all.gms` | Runs the baseline, experiments, sensitivities, grid and checks; writes `results/*.csv` |
| `make_figures.py` | Builds Figures 1-3 and Tables 2-3 from the CSVs |
| `bourbon_faustmann_simple.gms` | Milestone 2 toy model (single rotation age), kept for reference |

## How to run

```
gams run_all --maxage=10     # horizon 2026-2065, ages 1-10 (481 rows, 841 columns)
python make_figures.py       # figures and tables (needs pandas, matplotlib)
```

`--maxage=10` keeps the model inside the GAMS demo license (1,000 rows or columns for
nonlinear models). No barrel is ever held past age 6, so tracking ages 11-15 adds only
empty variables: a full 15-age run gives the same results to within one barrel. Plain
`gams run_all` tracks all 15 ages and needs a full license. `--lastyr=2055` shortens
the horizon (NPV changes by less than $0.2M; no utilization or regime result changes).

Results are reported for 2026-2045 in every case. The extra years after 2045 keep the
end of the horizon from distorting the reported window. The QCP solver is CPLEX; any
convex QCP solver works (change `option qcp` in `model.gms`).

## Outputs (`results/`)

| File | Contents | Used for |
|---|---|---|
| `summary.csv` | One row per sensitivity x demand case: NPV, sale ages, fills, utilization, shadow prices, Faustmann age | Tables 2-3 |
| `paths.csv` | Yearly fills, sales, utilization, sale age, capacity shadow price, revenue | Figure 2 |
| `inventory.csv` | Barrels on hand, sold, and price by age and year (calibrated values) | Figure 1 |
| `grid.csv` | Aging premium (tilt) x demand decline (g) grid with refill regime | Figure 3 |
| `checks.csv` | Model checks | Section 5 |
| `table2_baseline_vs_experiment.csv`, `table3_sensitivity.csv` | Formatted tables | Paper |
| `fig1_*.png`, `fig2_*.png`, `fig3_*.png` | Figures | Paper |

## Model in brief

Indices: year `y` (2026-2065), barrel age `a` (1-15, or 1-`maxage`).
Decisions: barrels on hand `INV(a,y)`, barrels sold `SELL(a,y)`, barrels filled `FILL(y)`.

- Price paid for age `a` in year `y` ($ per proof gallon):
  `pInt(a,y) - pBase(a)*slope*SELL(a,y)/K`, where
  `pBase(a) = pM2(a)*(1+tilt)^(a-1)` and
  `pInt(a,y) = pBase(a)*(1 - g - gam*a)^min(t,Tdecl)`
- Objective: discounted revenue minus fill costs `C*FILL` and holding costs `h` per occupied
  position, plus a terminal value for barrels and positions left after the horizon
- Constraints: new fills become age-1 barrels next year; unsold barrels age one year;
  barrels at the oldest age tracked must be sold; occupied positions plus new fills <= `K`
- `slope = 0`, `h = 0`, flat demand reproduces the Milestone 2 Faustmann answer (sell at age 4)

## Scenarios

- **Demand cases:** `base` (flat), `decl_old` (experiment: demand for older bourbon falls,
  `gam = 0.001` for 10 years), `decl_all` (all ages fall, `g = 0.005` for 10 years)
- **Sensitivities** (each run on all three cases): `r` 0.04/0.12, `delta` 0.03/0.05,
  `C` 450/700, `h` 0/25, `slope` 0/0.10/0.50, `tilt` -0.02/+0.02
- **Grid:** `tilt` from -0.02 to +0.04 by `g` from 0 to 0.03
