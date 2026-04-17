import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pyodbc
import os

# ==========================================================
# 1. Database Connection
# ==========================================================
DB_CONNECTION = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost,1433;"
    "DATABASE=Datawarehouse;"
    "UID=sa;"
    "PWD=TuPasswordFuerte123;"
    "TrustServerCertificate=yes;"
)

# Set visual style
sns.set_theme(style="whitegrid")
plt.rcParams['figure.dpi'] = 100

# ==========================================================
# 2. Data Acquisition 
# ==========================================================
try:
    print("Connecting to database...")
    conn = pyodbc.connect(DB_CONNECTION)
    
    # Path to the SQL template we just created
    sql_path = '/Users/yulia/analytics/template_growth_diffusion.sql'
    
    if not os.path.exists(sql_path):
        print(f"Error: SQL file {sql_path} not found.")
        exit()

    with open(sql_path, 'r') as f:
        sql_script = f.read()

    print("Executing Growth & Diffusion Analysis...")
    df = pd.read_sql(sql_script, conn)
    conn.close()
    
    # Convert date and sort
    df['date'] = pd.to_datetime(df['date'])
    df = df.sort_values('date')
    
    print(f"Data loaded: {len(df)} days analyzed.")

    # ==========================================================
    # 3. Visualization Dashboard
    # ==========================================================
    if not df.empty:
        fig = plt.figure(figsize=(18, 12))
        gs = fig.add_gridspec(3, 2)
        fig.suptitle('Growth Dynamics & Diffusion Dashboard', fontsize=20, fontweight='bold', y=0.95)

        # --- PLOT 1: Market Share (Adoption S-Curve) ---
        ax1 = fig.add_subplot(gs[0, 0])
        sns.lineplot(data=df, x='date', y='market_share', ax=ax1, color='darkblue', linewidth=3)
        ax1.fill_between(df['date'], df['market_share'], color='blue', alpha=0.1)
        ax1.set_title('Market Penetration (S-Curve)', fontsize=14, fontweight='bold')
        ax1.set_ylabel('Market Share (%)')

        # --- PLOT 2: Conversion Rate vs Polya Inertia ---
        ax2 = fig.add_subplot(gs[0, 1])
        sns.lineplot(data=df, x='date', y='cr_perc', ax=ax2, label='Daily CR %', color='teal', alpha=0.4)
        sns.lineplot(data=df, x='date', y=df['polya_inertia']*100, ax=ax2, label='Polya Momentum (7d)', color='red', linewidth=2)
        ax2.set_title('Conversion Rate vs. Momentum', fontsize=14, fontweight='bold')
        ax2.set_ylabel('Percentage (%)')
        ax2.legend()

        # --- PLOT 3: Capture Efficiency over Time ---
        ax3 = fig.add_subplot(gs[1, 0])
        sns.barplot(data=df, x='date', y='capture_efficiency', ax=ax3, palette='viridis', alpha=0.7)
        ax3.set_title('Daily Capture Efficiency (f(t)/Potential)', fontsize=14, fontweight='bold')
        # Fix date labels for barplot
        ax3.set_xticks(range(0, len(df), max(1, len(df)//10)))
        ax3.set_xticklabels([d.strftime('%Y-%m-%d') for d in df['date'].iloc[::max(1, len(df)//10)]])

        # --- PLOT 4: Shannon Entropy (System Stability) ---
        ax4 = fig.add_subplot(gs[1, 1])
        sns.lineplot(data=df, x='date', y='shannon_entropy', ax=ax4, color='orange', linewidth=2)
        ax4.axhline(0.5, color='gray', linestyle='--', alpha=0.5)
        ax4.set_title('Shannon Entropy (Chaos Level)', fontsize=14, fontweight='bold')
        ax4.set_ylabel('Entropy Bits')
        ax4.text(df['date'].iloc[0], 0.55, 'High Noise Threshold', color='gray')

        # --- PLOT 5: Bass Diffusion Analysis (Efficiency vs Market Share) ---
        ax5 = fig.add_subplot(gs[2, :])
        sns.regplot(data=df, x='market_share', y='capture_efficiency', ax=ax5, 
                    scatter_kws={'alpha':0.5, 'color':'purple'}, line_kws={'color':'red'})
        
        # Get p and q from the dataframe (assuming they are constant/global)
        q = df['q_viral_factor'].iloc[0]
        p = df['p_broadcast_factor'].iloc[0]
        
        ax5.set_title(f'Bass Diffusion Model Fit (p={p:.4f}, q={q:.4f})', fontsize=14, fontweight='bold')
        ax5.set_xlabel('Market Share (F)')
        ax5.set_ylabel('Efficiency (f(t)/[1-F])')
        ax5.text(0.05, df['capture_efficiency'].max()*0.9, 
                 f'Imitation (q): {q:.4f}\nInnovation (p): {p:.4f}', 
                 bbox=dict(facecolor='white', alpha=0.8))

        plt.tight_layout(rect=[0, 0.03, 1, 0.95])
        
        # Save output
        output_path = '/Users/yulia/analytics/growth_diffusion_insights.png'
        plt.savefig(output_path, dpi=300)
        print(f"Dashboard saved to: {output_path}")
        
        plt.show()
    else:
        print("Empty DataFrame. Check your SQL query results.")

except Exception as e:
    print(f"ERROR: {e}")
