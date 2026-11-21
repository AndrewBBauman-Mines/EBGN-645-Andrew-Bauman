"""Build the Milestone 3 figures and tables from the GAMS output in results/.

Run after `gams run_all`:
    python make_figures.py

Needs pandas and matplotlib.
"""
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import LinearSegmentedColormap, ListedColormap

RES = Path(__file__).resolve().parent / "results"

# Palette: categorical slots in fixed order, one sequential blue ramp
INK, INK2, GRID, SURF = "#0b0b0b", "#52514e", "#e4e3df", "#fcfcfb"
CASE_COLOR = {"base": "#2a78d6", "decl_old": "#eb6834", "decl_all": "#1baf7a"}
CASE_LABEL = {
    "base": "Baseline (flat demand)",
    "decl_old": "Experiment: older bourbon declines",
    "decl_all": "All ages decline",
}
BLUES = LinearSegmentedColormap.from_list(
    "blues", ["#f0efec", "#cde2fb", "#86b6ef", "#3987e5", "#1c5cab", "#0d366b"]
)

plt.rcParams.update({
    "font.size": 10, "axes.edgecolor": INK2, "axes.labelcolor": INK,
    "xtick.color": INK2, "ytick.color": INK2, "axes.spines.top": False,
    "axes.spines.right": False, "figure.facecolor": "white",
    "axes.facecolor": "white", "savefig.dpi": 200, "savefig.bbox": "tight",
})

summary = pd.read_csv(RES / "summary.csv")
paths = pd.read_csv(RES / "paths.csv")
inv = pd.read_csv(RES / "inventory.csv")
grid = pd.read_csv(RES / "grid.csv")


# ---------------------------------------------------------------- Figure 1
def fig_inventory():
    fig, axes = plt.subplots(1, 2, figsize=(11, 4), sharey=True)
    vmax = inv["onhand"].max()
    for ax, case in zip(axes, ["base", "decl_old"]):
        d = inv[inv["case"] == case].pivot(index="age", columns="year", values="onhand")
        im = ax.imshow(d.values, aspect="auto", origin="lower", cmap=BLUES,
                       vmin=0, vmax=vmax,
                       extent=[d.columns.min() - 0.5, d.columns.max() + 0.5,
                               d.index.min() - 0.5, d.index.max() + 0.5])
        ax.set_title(CASE_LABEL[case], loc="left", color=INK)
        ax.set_xlabel("Year")
        ax.spines[["left", "bottom"]].set_visible(False)
    axes[0].set_ylabel("Barrel age (years)")
    cb = fig.colorbar(im, ax=axes, shrink=0.9, pad=0.02)
    cb.set_label("Barrels on hand")
    cb.outline.set_visible(False)
    fig.suptitle("Figure 1. Barrels on hand by age and year", x=0.06, y=1.04, ha="left",
                 fontweight="bold", color=INK)
    fig.savefig(RES / "fig1_inventory_by_age.png")
    plt.close(fig)


# ---------------------------------------------------------------- Figure 2
def fig_paths():
    p = paths[paths["sens"] == "none"]
    fig, axes = plt.subplots(1, 2, figsize=(11, 3.8))
    for case in ["base", "decl_old", "decl_all"]:
        d = p[p["case"] == case]
        axes[0].plot(d["year"], d["fill"], color=CASE_COLOR[case], lw=2,
                     label=CASE_LABEL[case])
        axes[1].plot(d["year"], d["util"] * 100, color=CASE_COLOR[case], lw=2)
    axes[0].set_title("New barrels filled per year", loc="left", color=INK)
    axes[0].set_ylabel("Barrels")
    axes[1].set_title("Warehouse utilization", loc="left", color=INK)
    axes[1].set_ylabel("% of capacity")
    axes[1].set_ylim(0, 105)
    for ax in axes:
        ax.grid(axis="y", color=GRID, lw=0.8)
        ax.set_axisbelow(True)
        ax.set_xlabel("Year")
        ax.xaxis.set_major_locator(plt.MaxNLocator(integer=True))
    axes[0].legend(frameon=False, loc="upper right", fontsize=9)
    fig.suptitle("Figure 2. Refill decisions under each demand case", x=0.06,
                 ha="left", fontweight="bold", color=INK)
    fig.tight_layout()
    fig.savefig(RES / "fig2_fills_and_utilization.png")
    plt.close(fig)


# ---------------------------------------------------------------- Figure 3
def fig_regimes():
    util = grid.pivot(index="tilt", columns="g", values="util_ss")
    reg = grid.pivot(index="tilt", columns="g", values="regime")
    fig, ax = plt.subplots(figsize=(8, 4.6))
    cmap = ListedColormap(["#1c5cab", "#86b6ef", "#f0efec"])  # full, partial, stop
    ax.imshow(reg.values, cmap=cmap, vmin=0.5, vmax=3.5, origin="lower", aspect="auto")
    names = {1: "Full", 2: "Partial", 3: "Stop"}
    for i in range(reg.shape[0]):
        for j in range(reg.shape[1]):
            rg = int(reg.values[i, j])
            ax.text(j, i, f"{names[rg]}\n{util.values[i, j]:.0%}", ha="center",
                    va="center", fontsize=8, color="white" if rg == 1 else INK)
    ax.set_xticks(range(reg.shape[1]), [f"{g:.2%}" for g in reg.columns])
    ax.set_yticks(range(reg.shape[0]), [f"{t:+.0%}" for t in reg.index])
    ax.set_xlabel("Annual demand decline for 10 years, all ages (g)")
    ax.set_ylabel("Change in aging premium per year (tilt)")
    ax.spines[["left", "bottom"]].set_visible(False)
    ax.tick_params(length=0)
    ax.set_title("Figure 3. Refill regime once the decline ends\n"
                 "Cell label: average warehouse utilization, 2038-2045",
                 loc="left", fontsize=10, color=INK)
    fig.savefig(RES / "fig3_refill_regimes.png")
    plt.close(fig)


# ---------------------------------------------------------------- Tables
ITEMS = {
    "npv_musd": "NPV ($M, 2026)",
    "age26": "Avg sale age 2026 (yr)",
    "age45": "Avg sale age 2045 (yr)",
    "fills": "Barrels filled 2026-45",
    "util45": "Utilization 2045",
    "empty45": "Empty positions 2045",
    "cap45": "Position shadow price 2045 ($)",
    "tfaust": "Faustmann age at final prices (yr)",
}


def tables():
    s = summary.set_index(["sens", "case"])
    t2 = s.loc["none", list(ITEMS)].T.rename(index=ITEMS)[["base", "decl_old", "decl_all"]]
    t2.columns = [CASE_LABEL[c] for c in t2.columns]
    t2.round(2).to_csv(RES / "table2_baseline_vs_experiment.csv")

    t3 = (s.xs("decl_old", level="case")[["npv_musd", "age45", "fills", "util45", "tfaust"]]
            .join(s.xs("base", level="case")[["npv_musd", "util45"]], rsuffix="_base"))
    t3["npv_loss_musd"] = t3["npv_musd_base"] - t3["npv_musd"]
    t3 = t3[["npv_musd_base", "npv_musd", "npv_loss_musd", "util45_base", "util45",
             "age45", "fills", "tfaust"]]
    t3.round(2).to_csv(RES / "table3_sensitivity.csv")


if __name__ == "__main__":
    fig_inventory()
    fig_paths()
    fig_regimes()
    tables()
    print("Wrote figures and tables to", RES)
