# ==============================================================================
# 07c_shap_focused_comparison.py
# Generate focused SHAP figure: Socialization vs Education across 5 generations
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

matplotlib.rcParams.update({
    'font.size': 13,
    'font.family': 'serif',
    'axes.labelsize': 14,
    'axes.titlesize': 16,
    'xtick.labelsize': 12,
    'ytick.labelsize': 12,
    'figure.dpi': 300,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight'
})

FIGURES_DIR = Path("figures")
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


def main():
    # Load and prepare
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

    # Train model
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

    # Compute SHAP by generation
    explainer = shap.TreeExplainer(model)
    soc_shap = []
    edu_shap = []

    for gen in GENERATION_ORDER:
        mask = df['generation'] == gen
        X_gen = X.loc[mask]
        sv = explainer.shap_values(X_gen)
        importance = pd.Series(np.abs(sv).mean(axis=0), index=feature_names)
        soc_shap.append(importance['Socialization Freq.'])
        edu_shap.append(importance['Education'])
        print(f"{gen}: Socialization={importance['Socialization Freq.']:.3f}, "
              f"Education={importance['Education']:.3f}")

    # --- Create focused comparison figure ---
    x = np.arange(len(GENERATION_ORDER))
    width = 0.35

    fig, ax = plt.subplots(figsize=(10, 6.5))

    bars_soc = ax.bar(x - width/2, soc_shap, width,
                       label='Socialization Frequency',
                       color='#E63946', alpha=0.85, edgecolor='white',
                       linewidth=0.8)
    bars_edu = ax.bar(x + width/2, edu_shap, width,
                       label='Education',
                       color='#457B9D', alpha=0.85, edgecolor='white',
                       linewidth=0.8)

    # Value labels
    for bar, val in zip(bars_soc, soc_shap):
        ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.008,
                f'{val:.3f}', ha='center', va='bottom', fontsize=10,
                fontweight='bold', color='#E63946')
    for bar, val in zip(bars_edu, edu_shap):
        ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.008,
                f'{val:.3f}', ha='center', va='bottom', fontsize=10,
                fontweight='bold', color='#457B9D')

    # Annotation: arrow highlighting the reversal
    # Gen Z: socialization > education
    ax.annotate('Socialization\ndominates',
                xy=(x[0] - width/2, soc_shap[0]),
                xytext=(x[0] - 0.6, soc_shap[0] + 0.06),
                fontsize=9, fontstyle='italic', color='#E63946',
                ha='center',
                arrowprops=dict(arrowstyle='->', color='#E63946', lw=1.2))

    ax.set_xlabel('')
    ax.set_ylabel('Mean |SHAP Value|', fontsize=14)
    ax.set_title('Predictor Importance Reversal: Socialization vs. Education',
                 fontweight='bold', fontsize=15, pad=12)
    ax.set_xticks(x)
    ax.set_xticklabels(GENERATION_ORDER, fontsize=12)
    ax.legend(fontsize=12, loc='upper right', framealpha=0.9)

    # Subtle grid
    ax.yaxis.grid(True, alpha=0.3, linestyle='--')
    ax.set_axisbelow(True)

    # Clean spines
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)

    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "shap_soc_vs_edu_generations.png")
    plt.close()
    print("\nSaved: figures/shap_soc_vs_edu_generations.png")


if __name__ == "__main__":
    main()
