# ==============================================================================
# 08_shap_advanced_figures.py
# Advanced SHAP visualizations for NVSQ manuscript
#
# Figure 4: SHAP Beeswarm — Gen Z vs Older Cohorts (2-panel)
# Figure 5: SHAP Dependence Faceted — Socialization effect by generation
# ==============================================================================

import numpy as np
import pandas as pd
import xgboost as xgb
import shap
import matplotlib.pyplot as plt
import matplotlib
import matplotlib.gridspec as gridspec
from matplotlib.lines import Line2D
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
GENERATION_ORDER = ['Gen Z', 'Millennial', 'Gen X', 'Boomer', 'Silent']

GEN_COLORS = {
    'Gen Z': '#E63946',
    'Millennial': '#457B9D',
    'Gen X': '#2A9D8F',
    'Boomer': '#E9C46A',
    'Silent': '#264653'
}

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

SOC_LABELS = {1: 'Not at all', 2: 'Few times/yr', 3: 'Once/mo',
              4: 'Few times/mo', 5: 'Few times/wk', 6: 'Daily'}


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
    feature_names = [LABEL_MAP.get(f, f) for f in available]

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

    return df, model, X, y, feature_names


# ==============================================================================
# FIGURE 4: SHAP Beeswarm — Gen Z vs Older Cohorts
# ==============================================================================

def figure4_beeswarm_comparison(model, df, X, feature_names):
    """Two-panel SHAP beeswarm: Gen Z (left) vs Older Cohorts (right)."""
    explainer = shap.TreeExplainer(model)

    # Split data
    genz_mask = df['generation'] == 'Gen Z'
    older_mask = df['generation'].isin(['Millennial', 'Gen X', 'Boomer', 'Silent'])

    X_genz = X.loc[genz_mask]
    X_older = X.loc[older_mask]

    print(f"Gen Z: N = {len(X_genz):,}")
    print(f"Older cohorts: N = {len(X_older):,}")

    # Subsample older for visual balance (match Gen Z N roughly)
    np.random.seed(42)
    n_genz = len(X_genz)
    if len(X_older) > n_genz * 2:
        idx = np.random.choice(len(X_older), size=n_genz * 2, replace=False)
        X_older_sub = X_older.iloc[idx]
    else:
        X_older_sub = X_older

    # Compute SHAP values
    print("Computing SHAP values for Gen Z...")
    sv_genz = explainer.shap_values(X_genz)
    print("Computing SHAP values for older cohorts...")
    sv_older = explainer.shap_values(X_older_sub)

    # Sort features by Gen Z importance
    genz_importance = np.abs(sv_genz).mean(axis=0)
    older_importance = np.abs(sv_older).mean(axis=0)
    sort_idx = np.argsort(-genz_importance)

    # Top 12 features
    top_n = 12
    top_idx = sort_idx[:top_n]

    fig, axes = plt.subplots(1, 2, figsize=(16, 9))

    for ax_idx, (ax, sv, X_sub, title, n_label) in enumerate([
        (axes[0], sv_genz, X_genz, 'Generation Z', f'N = {len(X_genz):,}'),
        (axes[1], sv_older, X_older_sub, 'Older Cohorts (Millennial–Silent)',
         f'N = {len(X_older_sub):,}')
    ]):
        for rank, feat_idx in enumerate(reversed(top_idx)):
            shap_vals = sv[: , feat_idx]
            feat_vals = X_sub.iloc[:, feat_idx].values

            # Normalize feature values to 0-1 for color
            fmin, fmax = np.nanpercentile(feat_vals, [2, 98])
            if fmax - fmin < 1e-10:
                feat_norm = np.zeros_like(feat_vals)
            else:
                feat_norm = np.clip((feat_vals - fmin) / (fmax - fmin), 0, 1)

            # Jitter y for visibility
            y_jitter = rank + np.random.normal(0, 0.15, len(shap_vals))

            ax.scatter(
                shap_vals, y_jitter,
                c=feat_norm, cmap='coolwarm', s=3, alpha=0.35,
                edgecolors='none', rasterized=True
            )

        ax.set_yticks(range(top_n))
        ax.set_yticklabels([feature_names[i] for i in reversed(top_idx)],
                           fontsize=11)
        ax.axvline(0, color='gray', linestyle='-', alpha=0.4, linewidth=0.8)
        ax.set_xlabel('SHAP value (impact on model output)', fontsize=12)
        ax.set_title(f'{title}\n({n_label})', fontweight='bold', fontsize=13)
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)

        # Highlight top feature name
        ytick_labels = ax.get_yticklabels()
        if ax_idx == 0:
            # Gen Z: socialization is top → highlight last label (top position)
            ytick_labels[-1].set_color('#E63946')
            ytick_labels[-1].set_fontweight('bold')
        else:
            # Older: find education position
            older_sort = np.argsort(-older_importance)
            # Find which position education is in top_idx reversed
            edu_feature = feature_names.index('Education')
            for pos, fidx in enumerate(reversed(top_idx)):
                if fidx == edu_feature:
                    ytick_labels[pos].set_color('#457B9D')
                    ytick_labels[pos].set_fontweight('bold')
                    break

    # Shared colorbar
    sm = plt.cm.ScalarMappable(cmap='coolwarm',
                                norm=plt.Normalize(vmin=0, vmax=1))
    sm.set_array([])
    cbar = fig.colorbar(sm, ax=axes, shrink=0.4, aspect=30, pad=0.02)
    cbar.set_ticks([0, 1])
    cbar.set_ticklabels(['Low', 'High'])
    cbar.set_label('Feature value', fontsize=11)

    plt.suptitle(
        'SHAP Value Distribution: Generation Z vs. Older Cohorts',
        fontweight='bold', fontsize=15, y=1.02
    )
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_beeswarm_genz_vs_older.png",
                bbox_inches='tight')
    plt.close()
    print("Saved: figures/shap_beeswarm_genz_vs_older.png")

    return explainer


# ==============================================================================
# FIGURE 5: SHAP Dependence — Socialization by Generation (Faceted)
# ==============================================================================

def figure5_dependence_faceted(model, df, X, feature_names):
    """Faceted SHAP dependence plot for socialization, by generation."""
    explainer = shap.TreeExplainer(model)

    soc_col = 'Socialization Freq.'
    soc_idx = list(X.columns).index(soc_col)

    fig, axes = plt.subplots(1, 2, figsize=(16, 7))

    panels = [
        ('Gen Z', ['Gen Z']),
        ('Older Cohorts', ['Millennial', 'Gen X', 'Boomer', 'Silent'])
    ]

    for ax, (panel_title, gens) in zip(axes, panels):
        for gen in gens:
            mask = df['generation'] == gen
            X_gen = X.loc[mask]

            # Filter valid socialization
            valid = (X_gen[soc_col] >= 1) & (X_gen[soc_col] <= 6)
            X_gen = X_gen[valid]

            # Subsample for speed if large
            if len(X_gen) > 8000:
                np.random.seed(42)
                idx = np.random.choice(len(X_gen), size=8000, replace=False)
                X_gen = X_gen.iloc[idx]

            sv = explainer.shap_values(X_gen)
            soc_vals = X_gen[soc_col].values
            shap_vals = sv[:, soc_idx]

            # Jitter x
            jitter = np.random.normal(0, 0.1, len(soc_vals))

            ax.scatter(
                soc_vals + jitter, shap_vals,
                c=GEN_COLORS[gen], alpha=0.25, s=10,
                edgecolors='none', label=gen, rasterized=True
            )

            # LOESS-like smooth: mean SHAP per socialization level
            means = []
            ci_lo = []
            ci_hi = []
            for s in range(1, 7):
                vals = shap_vals[soc_vals == s]
                if len(vals) > 10:
                    means.append(vals.mean())
                    se = vals.std() / np.sqrt(len(vals))
                    ci_lo.append(vals.mean() - 1.96 * se)
                    ci_hi.append(vals.mean() + 1.96 * se)
                else:
                    means.append(np.nan)
                    ci_lo.append(np.nan)
                    ci_hi.append(np.nan)

            xs = np.arange(1, 7)
            ax.plot(xs, means, color=GEN_COLORS[gen], linewidth=2.5,
                    alpha=0.9, zorder=5)
            ax.fill_between(xs, ci_lo, ci_hi, color=GEN_COLORS[gen],
                            alpha=0.15, zorder=4)

        ax.axhline(0, color='gray', linestyle='--', alpha=0.5, linewidth=0.8)
        ax.set_xticks(range(1, 7))
        ax.set_xticklabels(['Not\nat all', 'Few\ntimes/yr', 'Once/\nmo',
                            'Few\ntimes/mo', 'Few\ntimes/wk', 'Daily'],
                           fontsize=9)
        ax.set_xlabel('In-Person Socialization Frequency', fontsize=12)
        ax.set_ylabel('SHAP Value for Socialization', fontsize=12)
        ax.set_title(panel_title, fontweight='bold', fontsize=14)
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.legend(fontsize=10, loc='upper left', framealpha=0.9)

    # Annotate key patterns
    # Gen Z panel: mark plateau
    axes[0].annotate(
        'Plateau',
        xy=(5, axes[0].get_children()[0].get_offsets()[:, 1].mean()
            if hasattr(axes[0].get_children()[0], 'get_offsets') else 0.4),
        xytext=(5.3, 0.65),
        fontsize=10, fontstyle='italic', color='#E63946',
        arrowprops=dict(arrowstyle='->', color='#E63946', lw=1.5),
        ha='center'
    )

    # Gen Z panel: mark First Step
    axes[0].annotate(
        'First Step\nEffect',
        xy=(1.5, -0.3),
        xytext=(2.8, -0.7),
        fontsize=10, fontstyle='italic', color='#E63946',
        arrowprops=dict(arrowstyle='->', color='#E63946', lw=1.5),
        ha='center'
    )

    plt.suptitle(
        'SHAP Dependence: How Socialization Drives Volunteering Predictions',
        fontweight='bold', fontsize=15, y=1.02
    )
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_dependence_soc_faceted.png",
                bbox_inches='tight')
    plt.close()
    print("Saved: figures/shap_dependence_soc_faceted.png")


# ==============================================================================
# MAIN
# ==============================================================================

def main():
    print("=" * 60)
    print("Advanced SHAP Visualizations")
    print("=" * 60)

    df, model, X, y, feature_names = load_and_train()

    print("\n--- Figure 4: SHAP Beeswarm (Gen Z vs Older) ---")
    figure4_beeswarm_comparison(model, df, X, feature_names)

    print("\n--- Figure 5: SHAP Dependence Faceted ---")
    figure5_dependence_faceted(model, df, X, feature_names)

    print("\nAll advanced SHAP figures complete.")


if __name__ == "__main__":
    main()
