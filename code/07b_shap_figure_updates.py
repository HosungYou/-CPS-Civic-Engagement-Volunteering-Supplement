# ==============================================================================
# 07b_shap_figure_updates.py
# Regenerate improved SHAP figures for NVSQ manuscript
#
# 1. Fix SHAP dependence plot (filter invalid socialization values)
# 2. Regenerate 5-panel SHAP at larger size with better readability
# ==============================================================================

import numpy as np
import pandas as pd
import xgboost as xgb
import shap
import matplotlib.pyplot as plt
import matplotlib
import warnings
warnings.filterwarnings('ignore')

from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score

# Publication-quality settings
matplotlib.rcParams.update({
    'font.size': 12,
    'font.family': 'serif',
    'axes.labelsize': 13,
    'axes.titlesize': 15,
    'xtick.labelsize': 11,
    'ytick.labelsize': 11,
    'legend.fontsize': 11,
    'figure.dpi': 300,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight'
})

FIGURES_DIR = Path("figures")

GEN_COLORS = {
    'Gen Z': '#E63946',
    'Millennial': '#457B9D',
    'Gen X': '#2A9D8F',
    'Boomer': '#E9C46A',
    'Silent': '#264653'
}

GENERATION_ORDER = ['Gen Z', 'Millennial', 'Gen X', 'Boomer', 'Silent']

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

    target = 'volunteered'
    features = [
        'CESOCIALIZE', 'EDUC', 'AGE', 'faminc_log',
        'VLSOCMEDIA_rev', 'female', 'married', 'employed', 'metro',
        'region_Northeast', 'region_Midwest', 'region_South',
        'gen_Millennial', 'gen_GenX', 'gen_Boomer', 'gen_Silent',
        'post_covid'
    ]
    available = [f for f in features if f in df.columns]

    X = df[available].copy()
    y = df[target].values
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

    auc = roc_auc_score(y_test, model.predict_proba(X_test)[:, 1])
    print(f"Test AUC: {auc:.4f}")

    return df, model, X, y, feature_names


def fix_shap_dependence(model, X):
    """Fix SHAP dependence plot — filter invalid socialization values."""
    soc_col = 'Socialization Freq.'
    age_col = 'Age'

    # Filter to valid socialization range (1-6)
    valid_mask = (X[soc_col] >= 1) & (X[soc_col] <= 6)
    X_valid = X[valid_mask].copy()
    print(f"Valid socialization values: {valid_mask.sum():,} / {len(X):,}")
    print(f"Filtered out: {(~valid_mask).sum():,} rows with values outside 1-6")

    explainer = shap.TreeExplainer(model)
    sv_valid = explainer.shap_values(X_valid)

    soc_idx = list(X_valid.columns).index(soc_col)
    age_idx = list(X_valid.columns).index(age_col)

    fig, ax = plt.subplots(figsize=(10, 7))

    scatter = ax.scatter(
        X_valid[soc_col].values + np.random.normal(0, 0.08, len(X_valid)),
        sv_valid[:, soc_idx],
        c=X_valid[age_col].values,
        cmap='coolwarm', alpha=0.4, s=8, edgecolors='none'
    )

    cbar = plt.colorbar(scatter, ax=ax, label='Age')
    ax.set_xlabel("Socialization Frequency\n(1=Not at all → 6=Daily)", fontsize=13)
    ax.set_ylabel("SHAP value for\nSocialization Freq.", fontsize=13)
    ax.set_title("SHAP Dependence: Socialization × Age", fontweight='bold', fontsize=15)
    ax.set_xticks([1, 2, 3, 4, 5, 6])
    ax.set_xticklabels(['1\nNot at all', '2\nFew/yr', '3\nOnce/mo',
                        '4\nFew/mo', '5\nFew/wk', '6\nDaily'])
    ax.axhline(0, color='gray', linestyle='--', alpha=0.5)

    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_dep_socialization_age.png")
    plt.close()
    print("Saved: shap_dep_socialization_age.png (fixed)")

    return explainer


def regenerate_gen_shap(model, df, X, feature_names):
    """Regenerate 5-panel SHAP at larger, more readable size."""
    explainer = shap.TreeExplainer(model)
    results = {}

    for gen in GENERATION_ORDER:
        mask = df['generation'] == gen
        if mask.sum() < 100:
            continue
        X_gen = X.loc[mask]
        sv = explainer.shap_values(X_gen)
        importance = pd.Series(
            np.abs(sv).mean(axis=0), index=feature_names
        ).sort_values(ascending=False)
        results[gen] = importance

    # --- 5-panel at larger size (2 rows for readability) ---
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    axes_flat = axes.flatten()

    for i, (gen, imp) in enumerate(results.items()):
        ax = axes_flat[i]
        top10 = imp.head(10)
        color = GEN_COLORS.get(gen, '#333333')
        bars = ax.barh(range(len(top10)), top10.values, color=color, alpha=0.85)
        ax.set_yticks(range(len(top10)))
        ax.set_yticklabels(top10.index, fontsize=10)
        ax.invert_yaxis()
        ax.set_title(gen, fontweight='bold', fontsize=14)
        ax.set_xlabel("Mean |SHAP Value|", fontsize=11)

        # Add value labels
        for bar, val in zip(bars, top10.values):
            ax.text(val + 0.005, bar.get_y() + bar.get_height()/2,
                    f'{val:.3f}', va='center', fontsize=8, color='gray')

    # Hide 6th subplot
    axes_flat[5].set_visible(False)

    plt.suptitle("Feature Importance by Generation (CPS-CEV 2017–2023)",
                 fontweight='bold', fontsize=16, y=1.01)
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_all_generations.png")
    plt.close()
    print("Saved: shap_all_generations.png (improved layout)")

    # --- Gen Z vs Boomer (unchanged but ensure quality) ---
    if 'Gen Z' in results and 'Boomer' in results:
        fig, axes = plt.subplots(1, 2, figsize=(16, 8))
        for ax, gen in zip(axes, ['Gen Z', 'Boomer']):
            top10 = results[gen].head(10)
            color = GEN_COLORS[gen]
            bars = ax.barh(range(len(top10)), top10.values, color=color, alpha=0.85)
            ax.set_yticks(range(len(top10)))
            ax.set_yticklabels(top10.index, fontsize=12)
            ax.invert_yaxis()
            ax.set_title(gen, fontweight='bold', fontsize=16)
            ax.set_xlabel("Mean |SHAP Value|", fontsize=13)

            for bar, val in zip(bars, top10.values):
                ax.text(val + 0.005, bar.get_y() + bar.get_height()/2,
                        f'{val:.3f}', va='center', fontsize=9, color='gray')

        plt.suptitle("Feature Importance: Gen Z vs. Boomers",
                     fontweight='bold', fontsize=18)
        plt.tight_layout()
        plt.savefig(FIGURES_DIR / "shap_genz_vs_boomer.png")
        plt.close()
        print("Saved: shap_genz_vs_boomer.png (improved)")


def main():
    print("=" * 60)
    print("SHAP Figure Updates")
    print("=" * 60)

    df, model, X, y, feature_names = load_and_train()

    print("\n--- Fixing SHAP Dependence Plot ---")
    fix_shap_dependence(model, X)

    print("\n--- Regenerating Generation SHAP Plots ---")
    regenerate_gen_shap(model, df, X, feature_names)

    print("\nAll SHAP figure updates complete.")


if __name__ == "__main__":
    main()
