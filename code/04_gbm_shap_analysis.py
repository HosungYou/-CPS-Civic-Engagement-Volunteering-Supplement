# ==============================================================================
# 04_gbm_shap_analysis.py
# SUPPLEMENTARY ANALYSIS B: GBM + TreeSHAP
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
#
# Purpose: Validate logistic regression findings with nonlinear ML model.
#          Confirm socialization as top predictor; capture threshold effects.
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
    """Load cleaned CPS-CEV data exported from R."""
    # Expected: CSV exported from 00_data_preparation.R
    df = pd.read_csv("data/cev_for_shap.csv")
    print(f"Loaded N = {len(df):,}")
    return df


def prepare_features(df):
    """Prepare feature matrix and target for XGBoost."""
    target = 'volunteered'

    features = [
        'CESOCIALIZE', 'PEEDUCA', 'AGE', 'HEFAMINC',
        'VLSOCMEDIA_rev',   # reverse-coded: higher = more use
        'female', 'married', 'employed', 'metro',
        'region_Northeast', 'region_Midwest', 'region_South',
        'wave_2019', 'wave_2021', 'wave_2023',
        'gen_Millennial', 'gen_GenX', 'gen_Boomer', 'gen_Silent'
    ]

    # Filter to available columns
    available = [f for f in features if f in df.columns]
    missing = [f for f in features if f not in df.columns]
    if missing:
        print(f"Warning: Missing features: {missing}")

    X = df[available].copy()
    y = df[target].values
    weights = df['VLSUPPWT'].values if 'VLSUPPWT' in df.columns else None

    return X, y, weights, available


def train_gbm(X, y, weights=None):
    """Train XGBoost model predicting volunteering."""
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    if weights is not None:
        w_train = weights[:len(X_train)]
        w_test = weights[len(X_train):]
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
    plt.title("SHAP Summary: Predictors of Volunteering", fontweight='bold')
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_summary_full.png")
    plt.close()

    # Bar importance
    plt.figure(figsize=(10, 8))
    shap.summary_plot(shap_values, X, plot_type="bar", show=False, max_display=15)
    plt.title("Feature Importance (Mean |SHAP|)", fontweight='bold')
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_bar_full.png")
    plt.close()

    return explainer, shap_values


def shap_dependence_socialization(shap_values, X):
    """SHAP dependence plot for CESOCIALIZE (key finding)."""
    if 'CESOCIALIZE' not in X.columns:
        print("CESOCIALIZE not in features, skipping dependence plot.")
        return

    fig, ax = plt.subplots(figsize=(10, 7))
    shap.dependence_plot(
        'CESOCIALIZE', shap_values, X,
        interaction_index='AGE',
        ax=ax, show=False
    )
    ax.set_xlabel("Socialization Frequency\n(1=Not at all → 6=Daily)")
    ax.set_title("SHAP Dependence: Socialization × Age", fontweight='bold')
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_dep_socialization_age.png")
    plt.close()


def shap_by_generation(model, df, X, feature_names):
    """Run separate SHAP analysis by generation for comparison."""
    gen_col = None
    for col in ['generation', 'gen_label']:
        if col in df.columns:
            gen_col = col
            break

    if gen_col is None:
        print("No generation column found. Creating from dummies.")
        # Reconstruct from dummy variables
        df = df.copy()
        df['gen_label'] = 'Gen Z'  # reference
        for gen in ['Millennial', 'GenX', 'Boomer', 'Silent']:
            col_name = f'gen_{gen}'
            if col_name in df.columns:
                df.loc[df[col_name] == 1, 'gen_label'] = gen.replace('GenX', 'Gen X')
        gen_col = 'gen_label'

    results = {}
    explainer = shap.TreeExplainer(model)

    for gen in ['Gen Z', 'Boomer']:
        mask = df[gen_col] == gen
        if mask.sum() < 100:
            continue

        X_gen = X[mask]
        sv = explainer.shap_values(X_gen)

        # Feature importance for this generation
        importance = pd.Series(
            np.abs(sv).mean(axis=0),
            index=feature_names
        ).sort_values(ascending=False)

        results[gen] = importance
        print(f"\n=== {gen} Feature Importance (Top 10) ===")
        print(importance.head(10))

    # Comparison plot
    if len(results) == 2:
        fig, axes = plt.subplots(1, 2, figsize=(16, 8))
        for ax, (gen, imp) in zip(axes, results.items()):
            top10 = imp.head(10)
            color = GEN_COLORS.get(gen, '#333333')
            ax.barh(range(len(top10)), top10.values, color=color, alpha=0.8)
            ax.set_yticks(range(len(top10)))
            ax.set_yticklabels(top10.index)
            ax.invert_yaxis()
            ax.set_title(f"{gen}", fontweight='bold', fontsize=14)
            ax.set_xlabel("Mean |SHAP Value|")

        plt.suptitle("Feature Importance Comparison: Gen Z vs. Boomers",
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
    print("=" * 60)

    # Load data
    df = load_data()

    # Prepare features
    X, y, weights, feature_names = prepare_features(df)
    print(f"Features: {len(feature_names)}")
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

    # Generation comparison
    print("\nComparing SHAP by generation...")
    gen_results = shap_by_generation(model, df, X, feature_names)

    print(f"\n{'=' * 60}")
    print("GBM + SHAP analysis complete.")
    print(f"Figures saved to: {FIGURES_DIR.absolute()}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
