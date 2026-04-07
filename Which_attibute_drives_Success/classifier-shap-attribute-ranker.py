import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import pyodbc
import os
import warnings
from sklearn.ensemble import RandomForestClassifier

# ==========================================================
# 1. CONFIGURATION - PUT YOUR INPUTS HERE (AT THE BEGINNING)
# ==========================================================

# Define the columns you want to use for prediction (Your Attributes / X)
# We exclude 'no_exp' so it acts as the baseline (Control Group)
ATTRIBUTES = ['exp_0', 'exp_1', 'exp_2', 'exp_3', 'exp_4', 'exp_5', 'exp_7', 'exp_8', 'exp_9']


# Define the logic for your success criteria (Your Success Column / y)
# Example: Success if they reached level 5
def success(df):
    return (df['max_level_reached'] == 5).astype(int)

# Database Configuration and SQL File Path
SQL_FILE_PATH = '/Users/yulia/analytics/shap_by_exp.sql'
DB_CONNECTION = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost,1433;"
    "DATABASE=Datawarehouse;"
    "UID=sa;"
    "PWD=TuPasswordFuerte123;"
    "TrustServerCertificate=yes;"
)

# ==========================================================
# 2. ANALYSIS FUNCTIONS (DO NOT TOUCH UNLESS NECESSARY)
# ==========================================================

try:
    import shap
except ImportError:
    print("Error: The 'shap' library is required. Install it with: pip install shap")
    exit()

def run_model_and_shap(X, y, output_img='analytics/shapley_importance_results.png'):
    """
    Trains a RandomForest and generates a SHAP importance analysis.
    """
    print(f"\n--- STARTING SHAP ANALYSIS ---")
    
    # Model Training
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X, y)

    # SHAP with a sample of 2000 for speed
    sample_size = min(len(X), 2000)
    X_sample = X.sample(sample_size, random_state=42)
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X_sample)

    # Version compatibility handling
    if isinstance(shap_values, list):
        # For binary classification in older versions, shap_values[1] is the positive class
        shap_obj = shap_values[1]
    elif isinstance(shap_values, np.ndarray) and len(shap_values.shape) == 3:
        # Some versions return [samples, features, classes]
        shap_obj = shap_values[:, :, 1]
    else:
        # Newer versions often return the positive class values directly
        shap_obj = shap_values

    # Generate Plot (Dot/Beeswarm plot shows direction of impact)
    plt.figure(figsize=(14, 9))
    shap.summary_plot(shap_obj, X_sample, show=False)
    
    # Add custom explanatory text for easier interpretation
    plt.title('Attribute Impact on Success (SHAP Values)\nHow each experiment influences reaching Level 5', fontsize=16, pad=20)
    
    # Adding interpretation guides
    plt.text(plt.xlim()[0], plt.ylim()[1] + 0.5, '◀ DECREASES Success Probability', 
             color='blue', fontweight='bold', ha='left', va='center', fontsize=10)
    plt.text(plt.xlim()[1], plt.ylim()[1] + 0.5, 'INCREASES Success Probability ▶', 
             color='red', fontweight='bold', ha='right', va='center', fontsize=10)
    
    # Color meaning annotation (Using transAxes for stable positioning outside the plot)
    plt.text(1.25, 0.5, 
             'COLOR MEANING:\n\n● RED: User IS in\n  this experiment (1)\n\n● BLUE: User is NOT\n  in this experiment (0)', 
             bbox=dict(facecolor='white', alpha=0.8, edgecolor='gray'),
             transform=plt.gca().transAxes,
             ha='left', va='center', fontsize=10)

    plt.savefig(output_img, bbox_inches='tight')
    plt.close()

    # Generate Results Table
    vals = np.abs(shap_obj).mean(0)
    feature_importance = pd.DataFrame(list(zip(X_sample.columns, vals)), columns=['Attribute', 'Importance'])
    feature_importance.sort_values(by=['Importance'], ascending=False, inplace=True)
    
    print("\nIMPORTANCE RESULTS TABLE:")
    print(feature_importance.to_string(index=False))
    print(f"\nPlot saved to: {output_img}")

# ==========================================================
# 3. MAIN PROCESS
# ==========================================================

if __name__ == "__main__":
    try:
        print("Connecting to the database...")
        conn = pyodbc.connect(DB_CONNECTION)
        
        with open(SQL_FILE_PATH, 'r') as f:
            query = f.read()
        
        # Ignore pandas UserWarning about DBAPI2 connections
        warnings.filterwarnings('ignore', category=UserWarning)
        df = pd.read_sql(query, conn)
        conn.close()
        
        print(f"Successfully loaded {len(df)} rows from the database.")

        # Prepare X and y (Attributes and Success Column) using the configuration at the top
        df['is_success'] = success(df)
        
        # Data Cleaning (drop rows with missing values in attributes or success column)
        data_clean = df[ATTRIBUTES + ['is_success']].dropna()
        X = data_clean[ATTRIBUTES]
        y = data_clean['is_success']

        if len(X) > 0:
            run_model_and_shap(X, y)
        else:
            print("Error: No data available after cleaning missing values.")

    except Exception as e:
        print(f"Error during the process: {e}")
