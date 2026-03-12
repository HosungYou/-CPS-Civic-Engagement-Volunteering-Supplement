# ==============================================================================
# 04_gbm_shap_analysis.py
# SUPPLEMENTARY ANALYSIS B: GBM + TreeSHAP
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
#
# Design: 4-wave pooled (2017/2019/2021/2023), N ≈ 201,000
#
# Purpose: Validate logistic regression findings with nonlinear ML model.
#          Confirm socialization as top predictor; capture threshold effects.
#          Compare feature importance across ALL generations.
# ==============================================================================

import numpy as np
import pandas as pd
import xgboost as xgb
import shap
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score, classification_report
import warnings
warnings.filterwarnings('ignore')

# Publication-quality settings
matplotlib.rcParams.update({
    'font.size': 12,
    'font.family': 'serif',
    'axes.labelsize': 14,
    'axes.titlesize': 16,
    'xtick.labelsize': 11,
    'ytick.labelsize': 11,
    'legend.fontsize': 11,
    'figure.dpi': 300,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight'
})

FIGURES_DIR = Path("figures")
FIGURES_DIR.mkdir(exist_ok=True)

GEN_COLORS = {
    'Gen Z': '#E63946',
    'Millennial': '#457B9D',
    'Gen X': '#2A9D8F',
    'Boomer': '#E9C46A',
    'Silent': '#264653'
}

GENERATION_ORDER = ['Gen Z', 'Millennial', 'Gen X', 'Boomer', 'Silent']


def load_data():
    """Load cleaned CPS-CEV 4-wave data exported from R."""
    df = pd.read_csv("data/cev_for_shap.csv")
    print(f"Loaded N = {len(df):,} (4-wave pooled)")
    print(f"\nWave distribution:")
    print(df['wave'].value_counts().sort_index())
    print(f"\nGeneration distribution:")
    print(df['generation'].value_counts().reindex(GENERATION_ORDER))
    return df


def prepare_features(df):
    """Prepare feature matrix and target for XGBoost."""
    target = 'volunteered'

    features = [
        'CESOCIALIZE', 'EDUC', 'AGE', 'faminc_log',
        'VLSOCMEDIA_rev',   # reverse-coded: higher = more use
        'female', 'married', 'employed', 'metro',
        'region_Northeast', 'region_Midwest', 'region_South',
        'gen_Millennial', 'gen_GenX', 'gen_Boomer', 'gen_Silent',
        'post_covid'
    ]

    # Filter to available columns
    available = [f for f in features if f in df.columns]
    missing = [f for f in features if f not in df.columns]
    if missing:
        print(f"Warning: Missing features: {missing}")

    X = df[available].copy()
    y = df[target].values
    weights = df['VLSUPPWT'].values if 'VLSUPPWT' in df.columns else None

    # Human-readable labels for publication figures
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
    X.rename(columns=LABEL_MAP, inplace=True)
    available = [LABEL_MAP.get(f, f) for f in available]

    return X, y, weights, available


def train_gbm(X, y, weights=None):
    """Train XGBoost model predicting volunteering."""
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    if weights is not None:
        idx_train = X_train.index
        idx_test = X_test.index
        w_train = weights[idx_train]
        w_test = weights[idx_test]
    else:
        w_train, w_test = None, None

    model = xgb.XGBClassifier(
        n_estimators=500,
        max_depth=6,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        min_child_weight=50,
        random_state=42,
        eval_metric='logloss',
        early_stopping_rounds=20
    )

    model.fit(
        X_train, y_train,
        sample_weight=w_train,
        eval_set=[(X_test, y_test)],
        verbose=False
    )

    y_pred = model.predict_proba(X_test)[:, 1]
    auc = roc_auc_score(y_test, y_pred)
    print(f"Test AUC: {auc:.4f}")

    return model


def shap_analysis_full(model, X):
    """SHAP analysis on full sample."""
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X)

    # Summary beeswarm
    plt.figure(figsize=(12, 8))
    shap.summary_plot(shap_values, X, show=False, max_display=15)
    plt.title("SHAP Summary: Predictors of Volunteering (2017–2023)",
              fontweight='bold')
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_summary_full.png")
    plt.close()

    # Bar importance
    plt.figure(figsize=(10, 8))
    shap.summary_plot(shap_values, X, plot_type="bar", show=False,
                      max_display=15)
    plt.title("Feature Importance (Mean |SHAP|)", fontweight='bold')
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_bar_full.png")
    plt.close()

    return explainer, shap_values


def shap_dependence_socialization(shap_values, X):
    """SHAP dependence plot for socialization frequency (key finding)."""
    soc_col = 'Socialization Freq.'
    age_col = 'Age'
    if soc_col not in X.columns:
        print(f"{soc_col} not in features, skipping dependence plot.")
        return

    fig, ax = plt.subplots(figsize=(10, 7))
    shap.dependence_plot(
        soc_col, shap_values, X,
        interaction_index=age_col,
        ax=ax, show=False
    )
    ax.set_xlabel("Socialization Frequency\n(1=Not at all → 6=Daily)")
    ax.set_title("SHAP Dependence: Socialization × Age", fontweight='bold')
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_dep_socialization_age.png")
    plt.close()


def shap_by_generation(model, df, X, feature_names):
    """Run SHAP analysis by ALL generations for comparison."""
    gen_col = 'generation'

    results = {}
    explainer = shap.TreeExplainer(model)

    for gen in GENERATION_ORDER:
        mask = df[gen_col] == gen
        if mask.sum() < 100:
            print(f"Skipping {gen}: N={mask.sum()} < 100")
            continue

        X_gen = X.loc[mask]
        sv = explainer.shap_values(X_gen)

        # Feature importance for this generation
        importance = pd.Series(
            np.abs(sv).mean(axis=0),
            index=feature_names
        ).sort_values(ascending=False)

        results[gen] = importance
        print(f"\n=== {gen} Feature Importance (Top 10) ===")
        print(importance.head(10))

    # Multi-generation comparison plot
    if len(results) >= 2:
        n_gens = len(results)
        fig, axes = plt.subplots(1, n_gens, figsize=(5 * n_gens, 8))
        if n_gens == 1:
            axes = [axes]

        for ax, (gen, imp) in zip(axes, results.items()):
            top10 = imp.head(10)
            color = GEN_COLORS.get(gen, '#333333')
            ax.barh(range(len(top10)), top10.values, color=color, alpha=0.8)
            ax.set_yticks(range(len(top10)))
            ax.set_yticklabels(top10.index)
            ax.invert_yaxis()
            ax.set_title(f"{gen}", fontweight='bold', fontsize=14)
            ax.set_xlabel("Mean |SHAP Value|")

        plt.suptitle("Feature Importance by Generation (2017–2023)",
                     fontweight='bold', fontsize=16)
        plt.tight_layout()
        plt.savefig(FIGURES_DIR / "shap_all_generations.png")
        plt.close()

    # Focused comparison: Gen Z vs Boomer
    if 'Gen Z' in results and 'Boomer' in results:
        fig, axes = plt.subplots(1, 2, figsize=(16, 8))
        for ax, gen in zip(axes, ['Gen Z', 'Boomer']):
            top10 = results[gen].head(10)
            color = GEN_COLORS[gen]
            ax.barh(range(len(top10)), top10.values, color=color, alpha=0.8)
            ax.set_yticks(range(len(top10)))
            ax.set_yticklabels(top10.index)
            ax.invert_yaxis()
            ax.set_title(f"{gen}", fontweight='bold', fontsize=14)
            ax.set_xlabel("Mean |SHAP Value|")

        plt.suptitle("Feature Importance: Gen Z vs. Boomers",
                     fontweight='bold', fontsize=16)
        plt.tight_layout()
        plt.savefig(FIGURES_DIR / "shap_genz_vs_boomer.png")
        plt.close()

    return results


# ==============================================================================
# MAIN
# ==============================================================================

def main():
    print("=" * 60)
    print("GBM + SHAP Supplementary Analysis")
    print("Bowling Alone, Scrolling Together")
    print("4-Wave Pooled: 2017/2019/2021/2023")
    print("=" * 60)

    # Load data
    df = load_data()

    # Prepare features
    X, y, weights, feature_names = prepare_features(df)
    print(f"\nFeatures: {len(feature_names)}")
    print(f"Volunteering rate: {y.mean():.1%}")

    # Train model
    print("\nTraining XGBoost model...")
    model = train_gbm(X, y, weights)

    # Full sample SHAP
    print("\nComputing SHAP values (full sample)...")
    explainer, shap_values = shap_analysis_full(model, X)

    # Socialization dependence
    print("\nGenerating socialization dependence plot...")
    shap_dependence_socialization(shap_values, X)

    # All-generation comparison
    print("\nComparing SHAP across all generations...")
    gen_results = shap_by_generation(model, df, X, feature_names)

    print(f"\n{'=' * 60}")
    print("GBM + SHAP analysis complete.")
    print(f"Figures saved to: {FIGURES_DIR.absolute()}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
