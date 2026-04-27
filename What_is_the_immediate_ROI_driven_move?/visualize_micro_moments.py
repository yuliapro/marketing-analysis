import pyodbc
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

# --- CONFIGURATION ---
CONN_STR = 'DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost,1433;DATABASE=Datawarehouse;UID=sa;PWD=TuPasswordFuerte123;TrustServerCertificate=yes'
SQL_FILE = 'analytics/micro_moment_detector.sql'
OUTPUT_FILE = 'micro_moment_growth_analysis.png'

def load_data():
    if not os.path.exists(SQL_FILE):
        raise FileNotFoundError(f"SQL file not found: {SQL_FILE}")
    
    with open(SQL_FILE, 'r') as f:
        query = f.read()
    
    # Remove the final ORDER BY DESC to ensure time-series plotting works correctly
    # or we can just sort in pandas. 
    print("Connecting to database and executing Micro-Moment Detector...")
    try:
        with pyodbc.connect(CONN_STR) as conn:
            df = pd.read_sql(query, conn)
        return df
    except Exception as e:
        print(f"Database connection failed: {e}")
        print("Attempting to find local CSV for demonstration...")
        # Fallback to local CSV if exists (common in these environments)
        if os.path.exists('query_output.csv'):
            return pd.read_csv('query_output.csv')
        raise

def create_visualization(df):
    # Prepare data
    df['date'] = pd.to_datetime(df['date'])
    df = df.sort_values('date')
    
    # 1. Rolling Average for Smoothing Trends
    df['consensus_smooth'] = df['consensus'].rolling(window=10).mean()
    df['inertia_smooth'] = df['inertia'].rolling(window=10).mean()

    # Create Figure
    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(16, 18), gridspec_kw={'height_ratios': [2, 1, 1]})
    plt.subplots_adjust(hspace=0.4)

    # --- TOP PLOT: GROWTH MOMENTUM ---
    # ... (rest of ax1 logic)
    ax1.plot(df['date'], df['consensus_smooth'], label='Current Consensus (Winning Streak)', color='#2ecc71', linewidth=2)
    ax1.plot(df['date'], df['inertia_smooth'], label='Historical Inertia (Trend)', color='#34495e', linestyle='--', alpha=0.7)
    
    # Highlight "Growth Breakouts" (Where Lyapunov Delta is positive and Consensus > Inertia)
    breakouts = df[(df['lyapunov_delta'] > 0) & (df['consensus'] > df['inertia'])]
    if not breakouts.empty:
        ax1.scatter(breakouts['date'], breakouts['consensus'], color='#f1c40f', s=20, label='Growth Breakout (Bifurcation)', alpha=0.5)

    # Fill area between lines to show over/under performance
    ax1.fill_between(df['date'], df['consensus_smooth'], df['inertia_smooth'], 
                     where=(df['consensus_smooth'] >= df['inertia_smooth']), 
                     color='#2ecc71', alpha=0.1, label='Overperforming Trend')
    
    ax1.set_title('Growth Trend Momentum: Consensus vs. Inertia', fontsize=16, fontweight='bold', loc='left')
    ax1.set_ylabel('Success Probability / Rate')
    ax1.legend(loc='upper left')
    ax1.grid(True, linestyle=':', alpha=0.6)

    # Add Actionable Annotations based on the latest data
    latest = df.iloc[-1]
    ax1.annotate(f"CURRENT STATUS: {latest['momentum_verdict']}\nACTION: {latest['action_plan']}", 
                 xy=(0.02, 0.05), xycoords='axes fraction', 
                 bbox=dict(boxstyle="round,pad=0.5", fc="#ecf0f1", ec="#bdc3c7", alpha=0.9),
                 fontsize=12, fontweight='bold')

    # --- MIDDLE PLOT: SOCIAL ROLE CLASSIFICATION ---
    role_counts = pd.crosstab(df['date'], df['social_role'])
    role_resampled = role_counts.resample('D').sum() if len(role_counts) > 50 else role_counts
    
    role_colors = {'Follower': '#3498db', 'Outlier': '#e74c3c', 'Caos': '#95a5a6'}
    role_resampled.plot(kind='area', stacked=True, ax=ax2, color=[role_colors.get(x, '#333') for x in role_resampled.columns], alpha=0.8)

    ax2.set_title('User Classification by Social Role (Dynamic Segmentation)', fontsize=14, fontweight='bold', loc='left')
    ax2.set_ylabel('User Volume')
    ax2.legend(title='Social Role', loc='upper left')
    ax2.grid(True, linestyle=':', alpha=0.4)

    # --- BOTTOM PLOT: RETARGETING OPPORTUNITIES (Cellular Pressure) ---
    # Separate users based on the retargeting threshold (0.5 from the SQL action_plan)
    high_pressure = df[df['pressure'] >= 0.5]
    normal_pressure = df[df['pressure'] < 0.5]

    ax3.scatter(normal_pressure['date'], normal_pressure['pressure'], color='#3498db', s=15, alpha=0.4, label='Stable Users')
    ax3.scatter(high_pressure['date'], high_pressure['pressure'], color='#2ecc71', s=30, alpha=0.8, label='RETARGET: High Pressure Opportunity')
    
    ax3.axhline(y=0.5, color='#e74c3c', linestyle='--', alpha=0.6, label='Opportunity Threshold (0.5)')
    
    ax3.set_title('Retargeting Diagnostics: Cellular Pressure Analysis', fontsize=14, fontweight='bold', loc='left')
    ax3.set_ylabel('Cellular Pressure')
    ax3.set_xlabel('Date')
    ax3.legend(loc='upper left')
    ax3.grid(True, linestyle=':', alpha=0.4)

    # Final Styling
    plt.suptitle(f"Micro-Moment Diagnostic: {latest['dim_1']} | {latest['dim_2']}", fontsize=18, y=0.96)
    
    # Save and Show
    plt.savefig(OUTPUT_FILE, dpi=300, bbox_inches='tight')
    print(f"Successfully generated visualization: {OUTPUT_FILE}")
    plt.show()

if __name__ == "__main__":
    try:
        data = load_data()
        if not data.empty:
            create_visualization(data)
        else:
            print("No data available to visualize.")
    except Exception as e:
        print(f"Critical Error: {e}")
