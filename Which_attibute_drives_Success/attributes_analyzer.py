import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import pyodbc
import os
import warnings
from sklearn.ensemble import RandomForestClassifier

# ==========================================================
# 1. CONFIGURATION - ANALYZE YOUR ATTRIBUTES AUTOMATICALLY
# ==========================================================

# List of attributes to analyze (can be TEXT or NUMERIC)
ATTRIBUTES = [
    'funnel_category', 
    'experiment_name', 
    'z_segmentation'
   
    
]

# Success Criteria: Reaching Level 5
def success_logic(df):
    return (df['max_level_reached'] == 5).astype(int)

# SQL Source and Connection
SQL_FILE_PATH = '/Users/yulia/analytics/user-attr.sql'
DB_CONNECTION = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost,1433;"
    "DATABASE=Datawarehouse;"
    "UID=sa;"
    "PWD=TuPasswordFuerte123;"
    "TrustServerCertificate=yes;"
)

# ==========================================================
# 2. ANALYSIS CORE
# ==========================================================

try:
    import shap
except ImportError:
    print("Error: The 'shap' library is required. Install it with: pip install shap")
    exit()

def run_automated_shap(X, y, output_img='analytics/shap_automated_results.png'):
    print(f"\n--- STARTING AUTOMATED SHAP ANALYSIS ---")
    
    # 1. AUTOMATIC ENCODING (One-Hot Encoding)
    # This turns 'funnel_type' into 'funnel_type_web', 'funnel_type_app', etc.
    print("Converting text attributes to numeric binary columns (Encoding)...")
    X_encoded = pd.get_dummies(X)
    print(f"Features created after encoding: {len(X_encoded.columns)}")
    
    # 2. Train Model
    print(f"Training RandomForest with {len(X_encoded)} records...")
    model = RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1)
    model.fit(X_encoded, y)

    # 3. SHAP Analysis (Sample of 2000 for efficiency)
    sample_size = min(len(X_encoded), 2000)
    print(f"Calculating SHAP values (sample size: {sample_size})...")
    X_sample = X_encoded.sample(sample_size, random_state=42)
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X_sample)

    # Handle SHAP version differences
    if isinstance(shap_values, list):
        shap_obj = shap_values[1]
    elif isinstance(shap_values, np.ndarray) and len(shap_values.shape) == 3:
        shap_obj = shap_values[:, :, 1]
    else:
        shap_obj = shap_values

    # 4. Visualization
    plt.figure(figsize=(14, 12))
    shap.summary_plot(shap_obj, X_sample, show=False)
    
    plt.title('Impact of Each Attribute on Success (SHAP Values)\nAnalyzed via Automated Encoding', fontsize=16, pad=30)
    
    # Interpretation guides
    plt.text(plt.xlim()[0], plt.ylim()[1] + 0.5, '◀ DECREASES Success Probability', 
             color='blue', fontweight='bold', ha='left', va='center', fontsize=10)
    plt.text(plt.xlim()[1], plt.ylim()[1] + 0.5, 'INCREASES Success Probability ▶', 
             color='red', fontweight='bold', ha='right', va='center', fontsize=10)
    
    # Custom Legend Box
    plt.text(1.25, 0.5, 
             'INTERPRETATION GUIDE:\n\n'
             '● RED POINT (Right):\n  The presence of this attribute\n  greatly HELPS success.\n\n'
             '● RED POINT (Left):\n  The presence of this attribute\n  greatly HURTS success.\n\n'
             '● BLUE POINT:\n  The absence of this attribute.', 
             bbox=dict(facecolor='white', alpha=0.9, edgecolor='gray'),
             transform=plt.gca().transAxes,
             ha='left', va='center', fontsize=10)

    plt.savefig(output_img, bbox_inches='tight')
    plt.close()
    
    # 5. Table Output
    vals = np.abs(shap_obj).mean(0)
    importance_df = pd.DataFrame(list(zip(X_sample.columns, vals)), columns=['Attribute', 'Impact_Score'])
    importance_df = importance_df.sort_values(by='Impact_Score', ascending=False)
    
    print("\nTOP 20 MOST INFLUENTIAL ATTRIBUTES:")
    print(importance_df.head(20).to_string(index=False))
    print(f"\nFull graph saved to: {output_img}")

# ==========================================================
# 3. EXECUTION FLOW
# ==========================================================

if __name__ == "__main__":
    try:
        print("Connecting to SQL Server...")
        conn = pyodbc.connect(DB_CONNECTION)
        
        with open(SQL_FILE_PATH, 'r') as f:
            query = f.read()
        
        warnings.filterwarnings('ignore', category=UserWarning)
        df = pd.read_sql(query, conn)
        conn.close()
        
        print(f"Data loaded: {len(df)} rows.")

        # Prepare Target and Features
        df['is_success'] = success_logic(df)
        
        # Clean data (select specified attributes + target, drop empty rows)
        final_cols = ATTRIBUTES + ['is_success']
        data_clean = df[final_cols].dropna()
        
        X = data_clean[ATTRIBUTES]
        y = data_clean['is_success']

        if len(X) > 10:
            run_automated_shap(X, y)
        else:
            print("Error: Not enough data for analysis (less than 10 rows).")

    except Exception as e:
        print(f"Fatal Error: {e}")
