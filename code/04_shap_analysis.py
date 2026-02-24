# ==============================================================================
# 04_shap_analysis.py
# Phase 3: SHAP Value Analysis and Visualization
#
# Study: Heterogeneous Effects of Organized Volunteering on Civic Engagement
# Authors: Hosung You & Suzanna Windon
# ==============================================================================

import numpy as np
import pandas as pd
import shap
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
from sklearn.ensemble import GradientBoostingRegressor
from pathlib import Path
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

# Color palette
COLORS = {
    'primary': '#264653',
    'secondary': '#2A9D8F',
    'accent1': '#E9C46A',
    'accent2': '#F4A261',
    'accent3': '#E63946',
    'rural': '#2A9D8F',
    'urban': '#457B9D'
}


def load_cate_data(outcome_name: str) -> pd.DataFrame:
    """Load CATE export from R causal forest."""
    return pd.read_csv(f"data/cate_export_{outcome_name}.csv")


def train_surrogate_model(X: pd.DataFrame, cate: np.ndarray):
    """
    Train a GBM surrogate model on CATE predictions.
    This enables SHAP decomposition of the causal forest's heterogeneity.
    """
    model = GradientBoostingRegressor(
        n_estimators=500,
        max_depth=5,
        learning_rate=0.05,
        subsample=0.8,
        random_state=20240224
    )
    model.fit(X, cate)

    # Check surrogate fidelity
    r2 = model.score(X, cate)
    print(f"  Surrogate model R² = {r2:.4f}")

    return model


def compute_shap_values(model, X: pd.DataFrame):
    """Compute SHAP values using TreeExplainer."""
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X)
    return explainer, shap_values


def plot_summary(shap_values, X, outcome_name: str):
    """SHAP Summary Plot (Beeswarm)."""
    fig, ax = plt.subplots(figsize=(12, 8))
    shap.summary_plot(
        shap_values, X,
        max_display=20,
        show=False,
        plot_size=None
    )
    plt.title(f"SHAP Summary: Drivers of Volunteering Effect Heterogeneity\n({outcome_name})",
              fontsize=16, fontweight='bold')
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / f"shap_summary_{outcome_name}.png")
    plt.close()
    print(f"  Saved: shap_summary_{outcome_name}.png")


def plot_bar_importance(shap_values, X, outcome_name: str):
    """SHAP Bar Plot (Mean absolute SHAP values)."""
    fig, ax = plt.subplots(figsize=(10, 8))
    shap.summary_plot(
        shap_values, X,
        plot_type="bar",
        max_display=15,
        show=False,
        plot_size=None,
        color=COLORS['primary']
    )
    plt.title(f"Feature Importance (Mean |SHAP|): {outcome_name}",
              fontsize=16, fontweight='bold')
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / f"shap_bar_{outcome_name}.png")
    plt.close()
    print(f"  Saved: shap_bar_{outcome_name}.png")


def plot_dependence(shap_values, X, feature: str, interaction: str,
                    outcome_name: str):
    """SHAP Dependence Plot with interaction coloring."""
    fig, ax = plt.subplots(figsize=(10, 7))
    shap.dependence_plot(
        feature, shap_values, X,
        interaction_index=interaction,
        ax=ax,
        show=False
    )
    ax.set_title(f"SHAP Dependence: {feature} × {interaction}\n({outcome_name})",
                 fontsize=14, fontweight='bold')
    plt.tight_layout()
    fname = f"shap_dep_{feature}_{interaction}_{outcome_name}.png"
    plt.savefig(FIGURES_DIR / fname)
    plt.close()
    print(f"  Saved: {fname}")


def plot_force_individual(explainer, shap_values, X, idx: int,
                          outcome_name: str, label: str):
    """SHAP Force Plot for individual observation."""
    shap.force_plot(
        explainer.expected_value,
        shap_values[idx, :],
        X.iloc[idx, :],
        matplotlib=True,
        show=False
    )
    fname = f"shap_force_{label}_{outcome_name}.png"
    plt.savefig(FIGURES_DIR / fname, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {fname}")


def plot_interaction_heatmap(shap_values, X, outcome_name: str, top_n=10):
    """SHAP interaction value heatmap for top features."""
    # Compute mean absolute SHAP values
    mean_abs_shap = np.abs(shap_values).mean(axis=0)
    top_features = np.argsort(-mean_abs_shap)[:top_n]
    top_names = X.columns[top_features]

    # Compute correlation between SHAP values of top features
    shap_df = pd.DataFrame(shap_values[:, top_features], columns=top_names)
    corr = shap_df.corr()

    fig, ax = plt.subplots(figsize=(10, 8))
    sns.heatmap(corr, annot=True, fmt=".2f", cmap="RdBu_r", center=0,
                square=True, ax=ax, linewidths=0.5)
    ax.set_title(f"SHAP Value Correlation (Top {top_n} Features): {outcome_name}",
                 fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / f"shap_interaction_heatmap_{outcome_name}.png")
    plt.close()
    print(f"  Saved: shap_interaction_heatmap_{outcome_name}.png")


def plot_profile_shap_comparison(shap_values, X, outcome_name: str):
    """Compare mean SHAP contributions across LPA profiles."""
    # Find profile columns
    profile_cols = [c for c in X.columns if 'profile' in c.lower()]

    if not profile_cols:
        print("  No profile columns found, skipping profile comparison.")
        return

    # Mean absolute SHAP by profile membership
    top_features_idx = np.argsort(-np.abs(shap_values).mean(axis=0))[:10]
    top_names = X.columns[top_features_idx]

    # Group by profile
    profile_shap = {}
    for col in profile_cols:
        mask = X[col] == 1
        if mask.sum() > 0:
            profile_shap[col] = np.abs(shap_values[mask])[:, top_features_idx].mean(axis=0)

    if profile_shap:
        df = pd.DataFrame(profile_shap, index=top_names).T

        fig, ax = plt.subplots(figsize=(14, 8))
        df.plot(kind='barh', ax=ax, stacked=True, colormap='viridis')
        ax.set_title(f"Mean |SHAP| by Profile (Top 10 Features): {outcome_name}",
                     fontsize=14, fontweight='bold')
        ax.set_xlabel("Mean |SHAP Value|")
        ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
        plt.tight_layout()
        plt.savefig(FIGURES_DIR / f"shap_profile_comparison_{outcome_name}.png")
        plt.close()
        print(f"  Saved: shap_profile_comparison_{outcome_name}.png")


# ==============================================================================
# MAIN ANALYSIS
# ==============================================================================

def main():
    outcomes = ['political', 'giving', 'community', 'membership']

    for outcome_name in outcomes:
        print(f"\n{'='*60}")
        print(f"Processing outcome: {outcome_name}")
        print(f"{'='*60}")

        # Load data
        try:
            df = load_cate_data(outcome_name)
        except FileNotFoundError:
            print(f"  Data file not found for {outcome_name}. Skipping.")
            continue

        cate = df['cate'].values
        X = df.drop(columns=['cate'])

        print(f"  Sample size: {len(X)}")
        print(f"  Features: {X.shape[1]}")
        print(f"  CATE range: [{cate.min():.4f}, {cate.max():.4f}]")

        # Train surrogate model
        print("\n  Training surrogate GBM model...")
        model = train_surrogate_model(X, cate)

        # Compute SHAP values
        print("  Computing SHAP values...")
        explainer, shap_values = compute_shap_values(model, X)

        # Generate visualizations
        print("\n  Generating visualizations...")

        # 1. Summary plot (beeswarm)
        plot_summary(shap_values, X, outcome_name)

        # 2. Bar importance plot
        plot_bar_importance(shap_values, X, outcome_name)

        # 3. Key dependence plots
        key_features = ['is_rural', 'age', 'homeowner']
        interactions = ['age', 'is_rural', 'is_rural']

        for feat, inter in zip(key_features, interactions):
            if feat in X.columns and inter in X.columns:
                plot_dependence(shap_values, X, feat, inter, outcome_name)

        # 4. Force plots for representative individuals
        # Find exemplar cases: highest and lowest CATE
        idx_max = np.argmax(cate)
        idx_min = np.argmin(cate)
        idx_median = np.argsort(cate)[len(cate) // 2]

        plot_force_individual(explainer, shap_values, X, idx_max,
                            outcome_name, "highest_cate")
        plot_force_individual(explainer, shap_values, X, idx_min,
                            outcome_name, "lowest_cate")
        plot_force_individual(explainer, shap_values, X, idx_median,
                            outcome_name, "median_cate")

        # 5. Interaction heatmap
        plot_interaction_heatmap(shap_values, X, outcome_name)

        # 6. Profile comparison
        plot_profile_shap_comparison(shap_values, X, outcome_name)

        print(f"\n  Completed: {outcome_name}")

    print(f"\n{'='*60}")
    print("Phase 3 (SHAP) analysis complete.")
    print(f"All figures saved to: {FIGURES_DIR.absolute()}")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
