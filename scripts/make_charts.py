"""Render the README charts from the dbt marts (run after `make build`)."""

from pathlib import Path

import duckdb
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "images"
OUT.mkdir(parents=True, exist_ok=True)
con = duckdb.connect(str(ROOT / "data" / "warehouse" / "olist.duckdb"), read_only=True)

SURFACE, INK, INK_2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df"
BLUE, ORANGE = "#2a78d6", "#eb6834"

plt.rcParams.update({
    "font.family": "DejaVu Sans", "font.size": 11, "text.color": INK,
    "axes.edgecolor": GRID, "axes.labelcolor": INK_2, "xtick.color": INK_2, "ytick.color": INK_2,
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE,
})


def clean(ax):
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.tick_params(length=0)


# 1. Late delivery vs bad reviews
rows = con.sql("select delivery_bucket, orders, bad_review_rate from analytics.mart_delivery_vs_reviews order by 1").fetchall()
labels = [r[0].split(". ", 1)[1] for r in rows]
rates = [r[2] * 100 for r in rows]
colors = [ORANGE if "late" in l else BLUE for l in labels]
fig, ax = plt.subplots(figsize=(9, 4.2), dpi=160)
ax.barh(labels[::-1], rates[::-1], color=colors[::-1], height=0.55)
for y, v in enumerate(rates[::-1]):
    ax.text(v + 1, y, f"{v:.0f}%", va="center", color=INK, fontsize=11)
ax.set_xlim(0, 90)
ax.xaxis.set_visible(False)
clean(ax)
ax.spines["bottom"].set_visible(False)
fig.suptitle("Share of 1-2 star reviews, by delivery timing", x=0.02, ha="left", fontsize=14, fontweight="bold")
fig.tight_layout(rect=(0, 0, 1, 0.9))
fig.text(0.02, 0.87, "Late orders (orange) get 5-9x more bad reviews than early ones (blue) - 96K delivered orders",
         fontsize=10, color=INK_2)
fig.savefig(OUT / "delivery_vs_reviews.png")
plt.close(fig)

# 2. Monthly GMV
rows = con.sql("select order_month, gmv from analytics.mart_monthly_kpis where is_complete_month order by 1").fetchall()
fig, ax = plt.subplots(figsize=(9, 4), dpi=160)
ax.plot([r[0] for r in rows], [float(r[1]) / 1e6 for r in rows], color=BLUE, linewidth=2, solid_capstyle="round")
ax.grid(axis="y", color=GRID, linewidth=0.8)
ax.set_ylabel("GMV (million BRL)")
clean(ax)
last = rows[-1]
ax.annotate(f"{float(last[1]) / 1e6:.2f}M", (last[0], float(last[1]) / 1e6), xytext=(6, 0),
            textcoords="offset points", va="center", color=INK)
fig.suptitle("Monthly GMV, Jan 2017 - Aug 2018", x=0.02, ha="left", fontsize=14, fontweight="bold")
fig.tight_layout()
fig.savefig(OUT / "monthly_gmv.png")
plt.close(fig)

# 3. Upwork cover image (1600x1200): architecture + headline result
fig = plt.figure(figsize=(8, 6), dpi=200)
ax = fig.add_axes([0, 0, 1, 1])
ax.set_xlim(0, 100)
ax.set_ylim(0, 75)
ax.axis("off")
ax.text(6, 66, "Modern Data Stack in a Box", fontsize=24, fontweight="bold")
ax.text(6, 60.5, "dbt  +  DuckDB  +  Dagster  on 100K real e-commerce orders", fontsize=13, color=INK_2)
steps = [("9 raw CSVs", "1M+ rows"), ("dbt staging", "clean + dedupe"), ("dbt marts", "facts, dims, KPIs"), ("Dagster", "daily schedule")]
for i, (title, sub) in enumerate(steps):
    x = 6 + i * 23
    ax.add_patch(FancyBboxPatch((x, 36), 18, 14, boxstyle="round,pad=0,rounding_size=1.5",
                                facecolor=BLUE if i < 3 else ORANGE, edgecolor="none"))
    ax.text(x + 9, 45, title, ha="center", va="center", color="white", fontsize=12, fontweight="bold")
    ax.text(x + 9, 40, sub, ha="center", va="center", color="white", fontsize=9.5)
    if i < 3:
        ax.annotate("", xy=(x + 22.5, 43), xytext=(x + 18.5, 43),
                    arrowprops=dict(arrowstyle="-|>", color=INK_2, lw=1.5))
facts = ["28 assets", "62 automated tests", "incremental models", "CI on every push"]
for i, f in enumerate(facts):
    ax.text(6 + i * 23 + 9, 30, f, ha="center", fontsize=10.5, color=INK)
ax.plot([6, 94], [22, 22], color=GRID, linewidth=1)
ax.text(6, 14, "Finding:", fontsize=13, fontweight="bold")
ax.text(20, 14, "orders 8+ days late get 1-2 stars 79% of the time (vs 9% when early)", fontsize=12)
ax.text(6, 7, "Finding:", fontsize=13, fontweight="bold")
ax.text(20, 7, "97% of customers never buy a second time", fontsize=12)
fig.savefig(OUT / "cover.png", facecolor=SURFACE)
plt.close(fig)
print("charts written to", OUT)
