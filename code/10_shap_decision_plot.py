# ==============================================================================
# 10_shap_decision_plot.py
# SHAP Decision Plot: Prediction Path Comparison — Gen Z vs Older Cohorts
#
# Manual implementation for full visual control.
# Each line = one person's cumulative SHAP path from base value to prediction.
# Red = volunteer, Blue = non-volunteer.
# Thick lines = group means showing the typical prediction path.
# Where lines spread most = the feature with greatest heterogeneity.
# ==============================================================================

import numpy as np
import pandas as pd
import xgboost as xgb
import shap
import matplotlib.pyplot as plt
import matplotlib
from matplotlib.lines import Line2D
import warnings
warnings.filterwarnings('ignore')

from pathlib import Path
from sklearn.model_selection import train_test_split
from scipy.special import expit  # logistic function

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


def figure4_decision_plot(model, df, X, y):
    """Manual SHAP decision plot with clear color separation."""
    explainer = shap.TreeExplainer(model)
    ev = explainer.expected_value
    base_value = float(np.asarray(ev).flatten()[0])

    # Masks
    genz_mask = df['generation'] == 'Gen Z'
    older_mask = df['generation'].isin(['Millennial', 'Gen X', 'Boomer', 'Silent'])

    # Subsample: stratified by outcome
    n_per_outcome = 150
    np.random.seed(42)

    samples = {}
    for label, mask in [('Gen Z', genz_mask), ('Older Cohorts', older_mask)]:
        X_group = X.loc[mask]
        y_group = y[mask.values]

        valid = (X_group['Socialization Freq.'] >= 1) & (X_group['Socialization Freq.'] <= 6)
        X_group = X_group[valid]
        y_group = y_group[valid.values]

        vol_idx = np.where(y_group == 1)[0]
        nonvol_idx = np.where(y_group == 0)[0]
        n_each = min(n_per_outcome, len(vol_idx), len(nonvol_idx))

        sel_vol = np.random.choice(vol_idx, size=n_each, replace=False)
        sel_nonvol = np.random.choice(nonvol_idx, size=n_each, replace=False)
        sel = np.sort(np.concatenate([sel_vol, sel_nonvol]))

        X_sel = X_group.iloc[sel]
        y_sel = y_group[sel]

        sv = explainer.shap_values(X_sel)
        samples[label] = {'X': X_sel, 'y': y_sel, 'shap': sv}
        print(f"{label}: n={len(sv)} (vol={y_sel.sum()}, non-vol={len(y_sel)-y_sel.sum()})")

    # Global feature importance for ordering
    all_shap = np.vstack([samples['Gen Z']['shap'], samples['Older Cohorts']['shap']])
    global_importance = np.abs(all_shap).mean(axis=0)
    feature_names = list(X.columns)

    # Top 10 features (by global importance)
    top_n = 10
    sorted_idx = np.argsort(-global_importance)
    top_features = sorted_idx[:top_n]

    # In decision plot: most important at BOTTOM, least at TOP
    # So display order = reversed top_features (least important first)
    display_order = list(reversed(top_features))

    # Feature labels for y-axis
    y_labels = [feature_names[i] for i in display_order]

    print("\nFeature display order (top to bottom):")
    for i, fidx in enumerate(display_order):
        print(f"  {i+1}. {feature_names[fidx]} (|SHAP| = {global_importance[fidx]:.3f})")

    # --- Draw (log-odds scale for visible spread) ---
    fig, axes = plt.subplots(1, 2, figsize=(16, 8.5))

    # Colors
    VOL_COLOR = '#C0392B'
    NONVOL_COLOR = '#2471A3'
    VOL_LIGHT = '#E74C3C'
    NONVOL_LIGHT = '#5DADE2'

    # Compute x-limits in log-odds space
    all_final_logodds = []
    for label in ['Gen Z', 'Older Cohorts']:
        sv = samples[label]['shap']
        finals = sv.sum(axis=1) + base_value
        all_final_logodds.extend(finals)
    xlim = [np.percentile(all_final_logodds, 2) - 0.3,
            np.percentile(all_final_logodds, 98) + 0.3]

    panel_configs = [
        ('Gen Z', axes[0], 'Generation Z'),
        ('Older Cohorts', axes[1], 'Older Cohorts (Millennial–Silent)')
    ]

    for label, ax, title in panel_configs:
        sv = samples[label]['shap']
        y_group = samples[label]['y']
        n_obs = len(sv)

        y_positions = np.arange(top_n + 1)

        # Draw individual lines (non-volunteers first, then volunteers on top)
        for outcome, color, alpha_val in [
            (0, NONVOL_LIGHT, 0.15),
            (1, VOL_LIGHT, 0.15)
        ]:
            for i in np.where(y_group == outcome)[0]:
                cumsum = base_value
                x_path = [cumsum]
                for feat_idx in display_order:
                    cumsum += sv[i, feat_idx]
                    x_path.append(cumsum)
                ax.plot(x_path, y_positions, color=color, alpha=alpha_val,
                        linewidth=0.7, solid_capstyle='round', rasterized=True)

        # Draw MEAN lines (thick, on top)
        for outcome, color, lbl in [
            (0, NONVOL_COLOR, 'Non-volunteer (mean path)'),
            (1, VOL_COLOR, 'Volunteer (mean path)')
        ]:
            mask_out = y_group == outcome
            cumsum = np.full(mask_out.sum(), base_value)
            x_means = [base_value]
            for feat_idx in display_order:
                cumsum = cumsum + sv[mask_out, feat_idx]
                x_means.append(cumsum.mean())

            ax.plot(x_means, y_positions, color=color, linewidth=3,
                    alpha=0.95, zorder=10, label=lbl,
                    marker='o', markersize=5, markeredgecolor='white',
                    markeredgewidth=1)

        # Formatting
        ax.set_yticks(y_positions)
        ylabels = ['Base value'] + y_labels
        ax.set_yticklabels(ylabels, fontsize=10.5)
        ax.set_xlim(xlim)
        ax.set_title(f'{title}\n(n = {n_obs})', fontweight='bold', fontsize=13)

        # Base value reference line
        ax.axvline(base_value, color='gray', linestyle=':', alpha=0.4,
                   linewidth=1, zorder=1)

        ax.xaxis.grid(True, alpha=0.15, linestyle='-')
        ax.set_axisbelow(True)
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.invert_yaxis()

        # Add probability tick labels on top x-axis
        ax2 = ax.twiny()
        ax2.set_xlim(xlim)
        prob_ticks_logodds = np.log([0.1/0.9, 0.2/0.8, 0.3/0.7, 0.5/0.5, 0.7/0.3, 0.8/0.2])
        prob_labels = ['10%', '20%', '30%', '50%', '70%', '80%']
        valid = [(lo, pl) for lo, pl in zip(prob_ticks_logodds, prob_labels)
                 if xlim[0] <= lo <= xlim[1]]
        if valid:
            ax2.set_xticks([v[0] for v in valid])
            ax2.set_xticklabels([v[1] for v in valid], fontsize=9, color='gray')
        ax2.set_xlabel('Predicted Probability', fontsize=10, color='gray')
        ax2.spines['top'].set_visible(True)
        ax2.spines['top'].set_color('lightgray')
        ax2.tick_params(axis='x', colors='gray')

    axes[0].set_xlabel('Log-Odds (Model Output)', fontsize=11)
    axes[1].set_xlabel('Log-Odds (Model Output)', fontsize=11)

    # Compute actual divergence points for annotation
    for panel_label, ax, anno_color in [
        ('Gen Z', axes[0], VOL_COLOR),
        ('Older Cohorts', axes[1], '#1A5276')
    ]:
        sv = samples[panel_label]['shap']
        y_grp = samples[panel_label]['y']

        # Measure divergence (gap between vol and nonvol mean paths) at each step
        divergences = []
        cum_vol = np.full((y_grp == 1).sum(), base_value)
        cum_nonvol = np.full((y_grp == 0).sum(), base_value)
        prev_gap = 0

        for feat_idx in display_order:
            cum_vol = cum_vol + sv[y_grp == 1, feat_idx]
            cum_nonvol = cum_nonvol + sv[y_grp == 0, feat_idx]
            gap = abs(cum_vol.mean() - cum_nonvol.mean())
            divergences.append(gap - prev_gap)  # marginal divergence
            prev_gap = gap

        # Feature with largest MARGINAL divergence
        max_div_idx = np.argmax(divergences)
        max_div_feat = y_labels[max_div_idx]
        max_div_val = divergences[max_div_idx]
        y_anno = max_div_idx + 1  # +1 for base value offset

        # Get x position for annotation (midpoint of vol/nonvol at that level)
        cum_vol2 = base_value + sv[y_grp == 1, :][:, display_order[:max_div_idx+1]].sum(axis=1)
        cum_nonvol2 = base_value + sv[y_grp == 0, :][:, display_order[:max_div_idx+1]].sum(axis=1)
        x_mid = (cum_vol2.mean() + cum_nonvol2.mean()) / 2

        ax.annotate(
            f'Largest marginal\ndivergence\n({max_div_feat})',
            xy=(x_mid, y_anno),
            xytext=(xlim[1] - 0.4, max(1, y_anno - 3)),
            fontsize=9, fontstyle='italic', color=anno_color,
            ha='center', fontweight='bold',
            arrowprops=dict(arrowstyle='->', color=anno_color, lw=1.5),
            bbox=dict(boxstyle='round,pad=0.3', facecolor='white',
                      edgecolor=anno_color, alpha=0.8)
        )

        print(f"\n{panel_label} marginal divergences:")
        for i, (fname, div) in enumerate(zip(y_labels, divergences)):
            marker = " <<<" if i == max_div_idx else ""
            print(f"  {fname}: Δ = {div:.3f}{marker}")

    # Bold key feature labels
    for ax, key_feat, color in [
        (axes[0], 'Socialization Freq.', VOL_COLOR),
        (axes[1], 'Education', '#1A5276')
    ]:
        for yl in ax.get_yticklabels():
            if yl.get_text() == key_feat:
                yl.set_color(color)
                yl.set_fontweight('bold')

    # Shared legend
    legend_elements = [
        Line2D([0], [0], color=VOL_COLOR, linewidth=3, marker='o',
               markersize=5, label='Volunteer (mean path)'),
        Line2D([0], [0], color=NONVOL_COLOR, linewidth=3, marker='o',
               markersize=5, label='Non-volunteer (mean path)'),
        Line2D([0], [0], color=VOL_LIGHT, linewidth=1, alpha=0.4,
               label='Individual paths (volunteer)'),
        Line2D([0], [0], color=NONVOL_LIGHT, linewidth=1, alpha=0.4,
               label='Individual paths (non-volunteer)'),
    ]
    fig.legend(handles=legend_elements, loc='lower center', ncol=4,
               fontsize=10, frameon=True, framealpha=0.9,
               bbox_to_anchor=(0.5, -0.02))

    plt.suptitle(
        'SHAP Decision Paths: How Features Cumulatively Shape\n'
        'Volunteering Predictions for Gen Z vs. Older Cohorts',
        fontweight='bold', fontsize=15, y=1.06
    )
    plt.tight_layout(rect=[0, 0.04, 1, 0.98])
    plt.savefig(FIGURES_DIR / "shap_decision_genz_vs_older.png",
                bbox_inches='tight')
    plt.close()
    print("\nSaved: figures/shap_decision_genz_vs_older.png")

    # --- Key statistics ---
    print("\n--- Feature Importance by Group ---")
    for label in ['Gen Z', 'Older Cohorts']:
        sv = samples[label]['shap']
        imp = pd.Series(np.abs(sv).mean(axis=0), index=feature_names)
        imp = imp.sort_values(ascending=False)
        print(f"\n{label} top 5:")
        for fname, val in imp.head(5).items():
            print(f"  {fname}: {val:.3f}")


def main():
    print("=" * 60)
    print("SHAP Decision Plot: Gen Z vs Older Cohorts")
    print("=" * 60)

    df, model, X, y = load_and_train()

    print("\n--- Figure 4: SHAP Decision Plot ---")
    figure4_decision_plot(model, df, X, y)

    print("\nDone.")


if __name__ == "__main__":
    main()
