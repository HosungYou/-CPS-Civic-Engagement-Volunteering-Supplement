#!/usr/bin/env python3
"""
11_conceptual_framework.py

Conceptual Framework Diagram — Publication Quality (Monochrome)
"Bowling Alone, Scrolling Together: In-Person Socialization and
 Volunteering Across Five Generational Cohorts"

Clean, journal-style figure (NVSQ / ASR / AERA).
  - Monochrome: black, white, light gray only
  - Serif typography (Times New Roman)
  - Thin precise lines, no shadows/gradients/3D/rounded corners

Output: ../figures/conceptual_framework.png  (8 x 6 in @ 350 DPI)
"""

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

# ---------------------------------------------------------------------------
# Global style
# ---------------------------------------------------------------------------
plt.rcParams.update({
    "font.family": "serif",
    "font.serif": ["Times New Roman", "Times", "DejaVu Serif"],
    "font.size": 9,
    "text.color": "#000000",
    "figure.facecolor": "white",
    "savefig.facecolor": "white",
    "savefig.edgecolor": "white",
})

BLACK = "#000000"
DGRAY = "#555555"
MGRAY = "#888888"
LGRAY = "#F5F5F5"
SGRAY = "#EDEDED"
WHITE = "#FFFFFF"

LW_BOX = 0.6
LW_MAIN = 1.2
LW_MOD = 0.8
MUT = 9

fig, ax = plt.subplots(figsize=(8, 6))
ax.set_xlim(0, 10)
ax.set_ylim(0, 7.5)
ax.set_aspect("equal")
ax.axis("off")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def rect(ax, x, y, w, h, fill=WHITE, edge=BLACK, lw=LW_BOX,
         ls="solid", zorder=2):
    r = FancyBboxPatch((x, y), w, h, boxstyle="square,pad=0",
                       facecolor=fill, edgecolor=edge,
                       linewidth=lw, linestyle=ls, zorder=zorder)
    ax.add_patch(r)


def arw(ax, a, b, lw=LW_MOD, color=BLACK, head=True,
        shrA=0, shrB=0, ls="solid"):
    sty = "-|>" if head else "-"
    p = FancyArrowPatch(a, b, arrowstyle=sty, mutation_scale=MUT,
                        linewidth=lw, linestyle=ls,
                        edgecolor=color, facecolor=color,
                        shrinkA=shrA, shrinkB=shrB, zorder=2)
    ax.add_patch(p)


def txt(ax, x, y, s, size=9, weight="normal", style="normal",
        color=BLACK, ha="center", va="center", zorder=3):
    ax.text(x, y, s, fontsize=size, fontweight=weight, fontstyle=style,
            color=color, ha=ha, va=va, zorder=zorder)


# ===================================================================
#  LAYOUT — everything referenced from a clear coordinate plan
# ===================================================================
CX = 5.0

# Core IV / DV
BW, BH = 2.2, 0.78
IV_X, IV_Y = 0.5, 4.30
DV_X, DV_Y = 7.3, 4.30
PATH_Y = IV_Y + BH / 2

# Generation (top center)
GW, GH = 2.6, 1.05
GX = CX - GW / 2
GY = 5.85

# Exploratory moderators (center-right, below path)
EW, EH = 3.4, 1.30
EX = CX - EW / 2 + 0.5
EY = 2.45

# Predicted pattern (left, below IV)
FW, FH = 2.5, 0.55
FX = 0.35
FY = 3.05

# Analytic stage boxes
SW, SH = 3.3, 0.50
S1X = CX - SW - 0.2
S2X = CX + 0.2
SY = 0.32
DIV_Y = 1.30


# ===================================================================
#  1. TITLE
# ===================================================================
txt(ax, CX, 7.25, "Conceptual Framework", size=12, weight="bold")


# ===================================================================
#  2. CORE  IV ----------> DV
# ===================================================================
rect(ax, IV_X, IV_Y, BW, BH)
txt(ax, IV_X + BW/2, PATH_Y + 0.12,
    "In-Person Socialization", size=9.5, weight="bold")
txt(ax, IV_X + BW/2, PATH_Y - 0.14,
    "(Frequency, 1\u20136)", size=8, style="italic", color=DGRAY)

rect(ax, DV_X, DV_Y, BW, BH)
txt(ax, DV_X + BW/2, PATH_Y + 0.12,
    "Volunteering", size=9.5, weight="bold")
txt(ax, DV_X + BW/2, PATH_Y - 0.14,
    "(Binary)", size=8, style="italic", color=DGRAY)

# Main horizontal arrow
arw(ax, (IV_X + BW, PATH_Y), (DV_X, PATH_Y), lw=LW_MAIN)

# H1 label centered on the arrow
txt(ax, CX, PATH_Y + 0.20, "H1 (+)", size=9.5, weight="bold")
txt(ax, CX, PATH_Y - 0.20,
    "Universal positive association",
    size=7, style="italic", color=DGRAY)


# ===================================================================
#  3. GENERATION (primary moderator)
# ===================================================================
rect(ax, GX, GY, GW, GH)
txt(ax, CX, GY + GH - 0.16, "Generation", size=10, weight="bold")
txt(ax, CX, GY + GH - 0.38,
    "(Primary Moderator)", size=8, style="italic", color=DGRAY)
txt(ax, CX, GY + 0.28,
    "Gen Z  \u00b7  Millennial  \u00b7  Gen X", size=7.5, color=DGRAY)
txt(ax, CX, GY + 0.10,
    "Boomer  \u00b7  Silent", size=7.5, color=DGRAY)

# Arrow: Generation -> main path (left of center)
MOD_AX = CX - 1.0
arw(ax, (MOD_AX, GY), (MOD_AX, PATH_Y + 0.08), lw=LW_MOD)

# H2 label
mid_gen = (GY + PATH_Y) / 2 + 0.10
txt(ax, MOD_AX + 0.15, mid_gen + 0.10, "H2",
    size=8.5, weight="bold", ha="left")
txt(ax, MOD_AX + 0.15, mid_gen - 0.12,
    "Gen Z plateau", size=7.5, style="italic",
    color=DGRAY, ha="left")


# ===================================================================
#  4. PREDICTED PATTERN (left, dashed)
# ===================================================================
rect(ax, FX, FY, FW, FH, fill=WHITE, edge=MGRAY, lw=0.5,
     ls=(0, (4, 3)))
txt(ax, FX + FW/2, FY + FH/2 + 0.10,
    "Predicted Pattern", size=8, weight="bold", color="#333333")
txt(ax, FX + FW/2, FY + FH/2 - 0.12,
    "\u201cFirst Step Effect\u201d: Largest marginal gain",
    size=6.8, style="italic", color=DGRAY)

# Connector
arw(ax, (IV_X + BW/2, IV_Y),
    (FX + FW/2, FY + FH),
    lw=0.4, color=MGRAY, head=False)


# ===================================================================
#  5. EXPLORATORY MODERATORS (below path, center-right)
# ===================================================================
rect(ax, EX, EY, EW, EH, fill=LGRAY)

ecx = EX + EW / 2
txt(ax, ecx, EY + EH - 0.13,
    "Exploratory Moderators", size=9, weight="bold")
txt(ax, ecx, EY + EH - 0.35,
    "(Three-Way Interactions)", size=7.5, style="italic", color=DGRAY)

items = [
    ("H3a", "Education (BA+)"),
    ("H3b", "Employment"),
    ("H3c", "Civic Social Media Use"),
    ("H3d", "COVID-19 Period (Pre / Post)"),
]
col_code = EX + 0.30
col_desc = EX + 0.72
top_item = EY + EH - 0.58
sp_item = 0.20

for i, (code, desc) in enumerate(items):
    yy = top_item - i * sp_item
    txt(ax, col_code, yy, code, size=7.5, weight="bold", ha="left")
    txt(ax, col_desc, yy, desc, size=7.5, ha="left")

# Arrow: exploratory moderators -> main path (right of center)
EMOD_X = CX + 1.0
arw(ax, (EMOD_X, EY + EH), (EMOD_X, PATH_Y - 0.08), lw=LW_MOD)

# Three-way label to the right of arrow — positioned to avoid overlap
arw_mid_e = (EY + EH + PATH_Y) / 2 - 0.08
txt(ax, EMOD_X + 0.15, arw_mid_e + 0.12,
    "Socialization \u00d7",
    size=6, style="italic", color=MGRAY, ha="left")
txt(ax, EMOD_X + 0.15, arw_mid_e - 0.06,
    "Generation \u00d7",
    size=6, style="italic", color=MGRAY, ha="left")
txt(ax, EMOD_X + 0.15, arw_mid_e - 0.24,
    "Moderator",
    size=6, style="italic", color=MGRAY, ha="left")


# ===================================================================
#  6. DATA SOURCE
# ===================================================================
txt(ax, CX, 1.68,
    "Data: CPS Civic Engagement & Volunteering Supplement, "
    "2017\u20132023  (N = 201,168)",
    size=6.5, color=MGRAY)


# ===================================================================
#  7. DIVIDER
# ===================================================================
ax.plot([0.4, 9.6], [DIV_Y, DIV_Y], color=BLACK, lw=0.4, zorder=1)


# ===================================================================
#  8. ANALYTIC APPROACH
# ===================================================================
txt(ax, CX, DIV_Y - 0.18, "Analytic Approach",
    size=10, weight="bold", va="top")

rect(ax, S1X, SY, SW, SH, fill=SGRAY)
txt(ax, S1X + SW/2, SY + SH/2 + 0.08,
    "Stage 1: Survey-Weighted Logistic Regression",
    size=7.5, weight="bold")
txt(ax, S1X + SW/2, SY + SH/2 - 0.12,
    "RQ1 \u00b7 Variable-Centered",
    size=7, style="italic", color=DGRAY)

rect(ax, S2X, SY, SW, SH, fill=SGRAY)
txt(ax, S2X + SW/2, SY + SH/2 + 0.08,
    "Stage 2: Latent Profile Analysis",
    size=7.5, weight="bold")
txt(ax, S2X + SW/2, SY + SH/2 - 0.12,
    "RQ2 \u00b7 Person-Centered",
    size=7, style="italic", color=DGRAY)

# Arrow between stages
arw(ax, (S1X + SW + 0.02, SY + SH/2),
    (S2X - 0.02, SY + SH/2),
    lw=0.45, color=MGRAY)


# ===================================================================
#  SAVE
# ===================================================================
out = (
    "/Volumes/External SSD/Projects/Research/"
    "-CPS-Civic-Engagement-Volunteering-Supplement/"
    "figures/conceptual_framework.png"
)

fig.savefig(out, dpi=350, bbox_inches="tight", pad_inches=0.12,
            facecolor="white", edgecolor="none")
plt.close(fig)

print(f"Saved: {out}")
print(f"  Size: 8 x 6 in @ 350 DPI")
