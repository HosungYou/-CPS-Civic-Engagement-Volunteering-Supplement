# ==============================================================================
# 09_shap_interaction_figure.py
# SHAP Interaction: Socialization × Education — Generational Moderator Validation
#
# Validates the regression finding (education × socialization × generation,
# p = .009) using non-parametric TreeSHAP interaction decomposition.
#
# Figure 4: Two-panel figure showing how education moderates socialization's
# SHAP contribution differently for Gen Z vs. older cohorts. The visual gap
# between education groups represents the interaction effect strength.
#
# Method:
#   1. Conditional SHAP dependence: mean SHAP(socialization) stratified by
#      education level at each socialization frequency
#   2. SHAP interaction values φ(socialization, education) from TreeExplainer
#      for quantitative interaction magnitude
# ==============================================================================

import numpy as np
import pandas as pd
import xgboost as xgb
import shap
import matplotlib.pyplot as plt
import matplotlib
from matplotlib.lines import Line2D
from matplotlib.patches import FancyArrowPatch
import warnings
warnings.filterwarnings('ignore')

from pathlib import Path
from sklearn.model_selection import train_test_split

matplotlib.rcParams.update({
    'font.size': 12,
    'font.family': 'serif',
    'axes.labelsize': 13,
    'axes.titlesize': 14,
    'xtick.labelsize': 11,
    'ytick.labelsize': 11,
    'figure.dpi': 300,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight'
})

FIGURES_DIR = Path("figures")

LABEL_MAP = {
    'CESOCIALIZE': 'Socialization Freq.',
    'EDUC': 'Education',
    'AGE': 'Age',
    'faminc_log': 'Family Income (log)',
    'VLSOCMEDIA_rev': 'Civic Social Media',
    'female': 'Female',
    'married': 'Married',
    'employed': 'Employed',
    'metro': 'Metropolitan',
    'region_Northeast': 'Northeast',
    'region_Midwest': 'Midwest',
    'region_South': 'South',
    'gen_Millennial': 'Millennial',
    'gen_GenX': 'Gen X',
    'gen_Boomer': 'Boomer',
    'gen_Silent': 'Silent',
    'post_covid': 'Post-COVID',
}

SOC_LABELS = ['Not\nat all', 'Few\ntimes/yr', 'Once/\nmo',
              'Few\ntimes/mo', 'Few\ntimes/wk', 'Daily']


def load_and_train():
    """Load data and train XGBoost model."""
    df = pd.read_csv("data/cev_for_shap.csv")
    print(f"Loaded N = {len(df):,}")

    features = [
        'CESOCIALIZE', 'EDUC', 'AGE', 'faminc_log',
        'VLSOCMEDIA_rev', 'female', 'married', 'employed', 'metro',
        'region_Northeast', 'region_Midwest', 'region_South',
        'gen_Millennial', 'gen_GenX', 'gen_Boomer', 'gen_Silent',
        'post_covid'
    ]
    available = [f for f in features if f in df.columns]

    X = df[available].copy()
    y = df['volunteered'].values
    weights = df['VLSUPPWT'].values if 'VLSUPPWT' in df.columns else None

    X.rename(columns=LABEL_MAP, inplace=True)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    w_train = weights[X_train.index] if weights is not None else None

    model = xgb.XGBClassifier(
        n_estimators=500, max_depth=6, learning_rate=0.05,
        subsample=0.8, colsample_bytree=0.8, min_child_weight=50,
        random_state=42, eval_metric='logloss', early_stopping_rounds=20
    )
    model.fit(X_train, y_train, sample_weight=w_train,
              eval_set=[(X_test, y_test)], verbose=False)

    from sklearn.metrics import roc_auc_score
    auc = roc_auc_score(y_test, model.predict_proba(X_test)[:, 1])
    print(f"Test AUC: {auc:.4f}")

    return df, model, X, y


def detect_ba_threshold(edu_values):
    """Detect BA+ threshold from education variable distribution."""
    unique = np.sort(np.unique(edu_values[~np.isnan(edu_values)]))
    print(f"  Education unique values (first 20): {unique[:20]}")
    print(f"  Education range: {edu_values.min():.0f} – {edu_values.max():.0f}")

    # IPUMS CPS EDUC codes: 111=BA, 123=MA, 124=Prof, 125=PhD
    if edu_values.max() > 100:
        threshold = 111
        pct = (edu_values >= threshold).mean() * 100
        print(f"  IPUMS coding detected. BA+ threshold ≥ {threshold} ({pct:.1f}%)")
        return threshold

    # Years of education: 16 = BA
    if edu_values.max() <= 25:
        threshold = 16
        pct = (edu_values >= threshold).mean() * 100
        print(f"  Years coding detected. BA+ threshold ≥ {threshold} ({pct:.1f}%)")
        return threshold

    # Categorical (e.g., 1-5 scale): use upper category
    if edu_values.max() <= 10:
        threshold = np.percentile(edu_values, 70)
        pct = (edu_values >= threshold).mean() * 100
        print(f"  Categorical coding detected. BA+ threshold ≥ {threshold:.0f} ({pct:.1f}%)")
        return threshold

    # Fallback: upper tertile
    threshold = np.percentile(edu_values, 67)
    pct = (edu_values >= threshold).mean() * 100
    print(f"  Fallback threshold ≥ {threshold:.0f} ({pct:.1f}%)")
    return threshold


def compute_conditional_shap(explainer, X_group, soc_col, soc_idx, ba_mask):
    """Compute mean SHAP(socialization) ± SE at each level, split by education."""
    sv = explainer.shap_values(X_group)
    soc_shap = sv[:, soc_idx]
    soc_vals = X_group[soc_col].values

    results = {}
    for is_ba, label in [(True, 'BA+'), (False, 'No BA')]:
        group_mask = ba_mask if is_ba else ~ba_mask
        means, ci_lo, ci_hi, ns = [], [], [], []

        for s in range(1, 7):
            level_mask = (soc_vals == s) & group_mask
            vals = soc_shap[level_mask]
            if len(vals) > 10:
                m = vals.mean()
                se = vals.std() / np.sqrt(len(vals))
                means.append(m)
                ci_lo.append(m - 1.96 * se)
                ci_hi.append(m + 1.96 * se)
                ns.append(len(vals))
            else:
                means.append(np.nan)
                ci_lo.append(np.nan)
                ci_hi.append(np.nan)
                ns.append(0)

        results[label] = {
            'means': np.array(means),
            'ci_lo': np.array(ci_lo),
            'ci_hi': np.array(ci_hi),
            'ns': ns
        }

    # Interaction gap at each level
    gaps = results['BA+']['means'] - results['No BA']['means']
    results['gap'] = gaps
    results['mean_gap'] = np.nanmean(gaps)

    return results


def figure4_interaction(model, df, X):
    """
    SHAP Interaction: Education moderates socialization's civic return.

    Left:  Gen Z — weak interaction (lines close, plateau in both)
    Right: Older Cohorts — strong interaction (lines diverge, continuous climb)
    """
    explainer = shap.TreeExplainer(model)

    soc_col = 'Socialization Freq.'
    edu_col = 'Education'
    soc_idx = list(X.columns).index(soc_col)
    edu_idx = list(X.columns).index(edu_col)

    # Detect education threshold
    print("\nDetecting education threshold:")
    edu_threshold = detect_ba_threshold(X[edu_col].values)

    # Define groups
    genz_mask = df['generation'] == 'Gen Z'
    older_mask = df['generation'].isin(['Millennial', 'Gen X', 'Boomer', 'Silent'])

    # --- Compute conditional SHAP for each group ---
    panel_data = {}
    for label, mask in [('Gen Z', genz_mask), ('Older Cohorts', older_mask)]:
        X_group = X.loc[mask].copy()
        valid = (X_group[soc_col] >= 1) & (X_group[soc_col] <= 6)
        X_group = X_group[valid]

        # Subsample for computation (keep enough for stable estimates)
        if len(X_group) > 15000:
            np.random.seed(42)
            idx = np.random.choice(len(X_group), size=15000, replace=False)
            X_group = X_group.iloc[idx]

        ba_mask_group = X_group[edu_col].values >= edu_threshold
        n_ba = ba_mask_group.sum()
        n_noba = (~ba_mask_group).sum()
        print(f"\n{label}: N = {len(X_group):,} (BA+: {n_ba:,}, No BA: {n_noba:,})")

        results = compute_conditional_shap(
            explainer, X_group, soc_col, soc_idx, ba_mask_group
        )
        panel_data[label] = results

        print(f"  Mean interaction gap (Δ SHAP): {results['mean_gap']:.4f}")
        for s in range(6):
            print(f"    Level {s+1}: BA+ = {results['BA+']['means'][s]:.3f}, "
                  f"No BA = {results['No BA']['means'][s]:.3f}, "
                  f"Δ = {results['gap'][s]:.3f}")

    # --- Compute SHAP interaction values for numeric reporting ---
    print("\nComputing SHAP interaction values (subsample)...")
    phi_stats = {}
    for label, mask in [('Gen Z', genz_mask), ('Older Cohorts', older_mask)]:
        X_sub = X.loc[mask].copy()
        valid = (X_sub[soc_col] >= 1) & (X_sub[soc_col] <= 6)
        X_sub = X_sub[valid]

        n_inter = min(3000, len(X_sub))
        np.random.seed(42)
        idx = np.random.choice(len(X_sub), size=n_inter, replace=False)
        X_sub = X_sub.iloc[idx]

        print(f"  Computing φ(soc,edu) for {label} (n={n_inter})...")
        sv_inter = explainer.shap_interaction_values(X_sub)
        phi_soc_edu = sv_inter[:, soc_idx, edu_idx]

        mean_phi = phi_soc_edu.mean()
        abs_phi = np.abs(phi_soc_edu).mean()
        phi_stats[label] = {'mean': mean_phi, 'abs_mean': abs_phi}
        print(f"    mean φ(soc,edu) = {mean_phi:.4f}, mean |φ| = {abs_phi:.4f}")

    # --- Create Figure ---
    fig, axes = plt.subplots(1, 2, figsize=(14, 6.5), sharey=True)
    xs = np.arange(1, 7)

    configs = [
        ('Gen Z', axes[0], '#C0392B', '#E74C3C', '#F1948A'),
        ('Older Cohorts', axes[1], '#1A5276', '#2E86C1', '#85C1E9')
    ]

    for label, ax, color_ba, color_ba_light, color_noba in configs:
        data = panel_data[label]
        phi = phi_stats[label]

        # BA+ line (solid, darker)
        ax.plot(xs, data['BA+']['means'], color=color_ba, linewidth=2.8,
                linestyle='-', marker='o', markersize=7, markeredgecolor='white',
                markeredgewidth=1.2, label="Bachelor's degree or higher",
                zorder=6)
        ax.fill_between(xs, data['BA+']['ci_lo'], data['BA+']['ci_hi'],
                        color=color_ba, alpha=0.12, zorder=3)

        # No BA line (dashed, lighter)
        ax.plot(xs, data['No BA']['means'], color=color_noba, linewidth=2.8,
                linestyle='--', marker='s', markersize=6, markeredgecolor='white',
                markeredgewidth=1.2, label='Less than bachelor\'s',
                zorder=6)
        ax.fill_between(xs, data['No BA']['ci_lo'], data['No BA']['ci_hi'],
                        color=color_noba, alpha=0.12, zorder=3)

        # Shade interaction gap between lines
        ax.fill_between(xs, data['No BA']['means'], data['BA+']['means'],
                        color=color_ba_light, alpha=0.15, zorder=2)

        # Interaction magnitude annotation
        gap_text = (f"Mean interaction gap: Δ = {data['mean_gap']:.3f}\n"
                    f"SHAP φ(soc,edu) = {phi['mean']:.4f}")
        ax.text(0.97, 0.03, gap_text, transform=ax.transAxes,
                fontsize=9, ha='right', va='bottom',
                bbox=dict(boxstyle='round,pad=0.4', facecolor='white',
                          edgecolor='gray', alpha=0.9))

        # Zero line
        ax.axhline(0, color='gray', linestyle='--', alpha=0.4, linewidth=0.8)

        # Formatting
        ax.set_xticks(range(1, 7))
        ax.set_xticklabels(SOC_LABELS, fontsize=9.5)
        ax.set_xlabel('In-Person Socialization Frequency', fontsize=12)
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.yaxis.grid(True, alpha=0.15, linestyle='-')
        ax.set_axisbelow(True)

    # Panel-specific annotations
    # Gen Z: note plateau and weak gap
    genz_data = panel_data['Gen Z']
    if not np.isnan(genz_data['BA+']['means'][3]):
        # Mark where plateau begins (~level 4-5)
        axes[0].annotate(
            'Plateau persists\nregardless of education',
            xy=(5, (genz_data['BA+']['means'][4] + genz_data['No BA']['means'][4]) / 2),
            xytext=(3.5, genz_data['BA+']['means'][4] + 0.15),
            fontsize=9, fontstyle='italic', color='#C0392B',
            ha='center',
            arrowprops=dict(arrowstyle='->', color='#C0392B', lw=1.3)
        )

    # Older: note diverging gap
    older_data = panel_data['Older Cohorts']
    if not np.isnan(older_data['gap'][4]):
        # Mark widening gap at high socialization
        mid_y = (older_data['BA+']['means'][4] + older_data['No BA']['means'][4]) / 2
        axes[1].annotate(
            'Education amplifies\ncivic return',
            xy=(5, mid_y),
            xytext=(3.0, older_data['BA+']['means'][4] + 0.12),
            fontsize=9, fontstyle='italic', color='#1A5276',
            ha='center',
            arrowprops=dict(arrowstyle='->', color='#1A5276', lw=1.3)
        )

    # Titles and labels
    axes[0].set_title('Generation Z', fontweight='bold', fontsize=14)
    axes[1].set_title('Older Cohorts (Millennial–Silent)', fontweight='bold',
                      fontsize=14)
    axes[0].set_ylabel('SHAP Value for Socialization\n(contribution to prediction)',
                       fontsize=12)

    # Shared legend at bottom
    handles = [
        Line2D([0], [0], color='#555', linewidth=2.5, linestyle='-',
               marker='o', markersize=6, label="Bachelor's degree or higher"),
        Line2D([0], [0], color='#999', linewidth=2.5, linestyle='--',
               marker='s', markersize=5, label="Less than bachelor's"),
        plt.Rectangle((0, 0), 1, 1, fc='gray', alpha=0.2,
                       label='Education interaction gap')
    ]
    fig.legend(handles=handles, loc='lower center', ncol=3, fontsize=11,
               frameon=True, framealpha=0.9, bbox_to_anchor=(0.5, -0.02))

    plt.suptitle(
        'SHAP Interaction: How Education Moderates\n'
        'the Socialization–Volunteering Relationship',
        fontweight='bold', fontsize=15, y=1.04
    )
    plt.tight_layout(rect=[0, 0.04, 1, 1])
    plt.savefig(FIGURES_DIR / "shap_interaction_soc_edu.png",
                bbox_inches='tight')
    plt.close()
    print("\nSaved: figures/shap_interaction_soc_edu.png")

    # Summary
    genz_gap = panel_data['Gen Z']['mean_gap']
    older_gap = panel_data['Older Cohorts']['mean_gap']
    if abs(genz_gap) > 0.001:
        ratio = older_gap / genz_gap
        print(f"\nInteraction ratio: Older/GenZ = {ratio:.1f}x")
    print(f"Gen Z φ(soc,edu): {phi_stats['Gen Z']['mean']:.4f}")
    print(f"Older φ(soc,edu): {phi_stats['Older Cohorts']['mean']:.4f}")


def main():
    print("=" * 60)
    print("SHAP Interaction: Socialization × Education")
    print("=" * 60)

    df, model, X, y = load_and_train()

    print("\n--- Figure 4: SHAP Interaction ---")
    figure4_interaction(model, df, X)

    print("\nDone.")


if __name__ == "__main__":
    main()
