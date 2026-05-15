import pyodbc
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os

# Database Connection Configuration
conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost,1433;"
    "DATABASE=Datawarehouse;"
    "UID=sa;"
    "PWD=TuPasswordFuerte123;"
    "TrustServerCertificate=yes;"
)

def run_behavioral_physics_visualization():
    try:
        print("Connecting to database...")
        conn = pyodbc.connect(conn_str)
        
        # 1. Read the SQL analysis file
        sql_file_path = '/Users/yulia/analytics/improved_duration_behavior_analysis.sql'
        if not os.path.exists(sql_file_path):
            print(f"Error: {sql_file_path} not found.")
            return
            
        with open(sql_file_path, 'r') as file:
            sql_script = file.read()
        
        # 2. Execute SQL and get data
        print(f"Executing {sql_file_path}...")
        df = pd.read_sql(sql_script, conn)
        conn.close()

        if df.empty:
            print("No data returned from the query.")
            return

        # --- CRITICAL: Sort by minutes and reset index to ensure row N = bar N ---
        df = df.sort_values('minutes').reset_index(drop=True)

        # 3. Setup Plots (2 Subplots)
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(15, 14), sharex=False)
        sns.set_style("whitegrid")

        # Define exact color palette for actions
        palette = {
            'FORCE: Simplify the UI': '#e74c3c',   # Red
            'INERTIA: Monetize': '#2ecc71',        # Green
            'EQUILIBRIUM: keep doing it': '#3498db',# Blue
            'TRANSITION: Pin user': '#9b59b6'      # Purple
        }

        # --- GRAPH 1: SUCCESS DISTRIBUTION, QUALITY & TIPPING POINT ---
        print("Generating success distribution and quality...")
        # Seaborn barplots treat the x-axis as categorical (positions 0, 1, 2...)
        sns.barplot(
            data=df, 
            x='minutes', 
            y='success_cnt', 
            hue='action',
            palette=palette,
            dodge=False,
            width=0.8,
            ax=ax1
        )
        
        # Use range(len(df)) for all line plots to match categorical bar positions (0, 1, 2...)
        x_indices = np.arange(len(df))

        # Add minute labels on top of each bar
        for i, p in enumerate(ax1.patches):
            height = p.get_height()
            if height > 0:
                # Find the categorical index of the bar
                m_idx = int(round(p.get_x() + p.get_width()/2. - 0.5))
                if 0 <= m_idx < len(df):
                    ax1.text(p.get_x() + p.get_width()/2., height + (ax1.get_ylim()[1]*0.01),
                             f'{int(df["minutes"].iloc[m_idx])}m', 
                             ha='center', va='bottom', fontsize=7, rotation=90, alpha=0.6, fontweight='bold')

        # Ensure x-axis ticks are visible
        ax1.tick_params(labelbottom=True)
        
        # Secondary axis for Success Rate (Quality)
        ax1_rate = ax1.twinx()
        ax1_rate.plot(x_indices, df['success_rate'], color='#f1c40f', linewidth=2, marker='s', alpha=0.6, label='Success Rate (Quality)')
        ax1_rate.set_ylabel('Success Rate (%)', color='#f39c12', fontweight='bold')
        ax1_rate.grid(False)
        
        # Third axis for Tipping Point (Shift)
        ax1_tip = ax1.twinx()
        ax1_tip.spines['right'].set_position(('outward', 60))
        ax1_tip.plot(x_indices, df['tipping_point'], color='#e67e22', linewidth=2, linestyle='-.', alpha=0.8, label='Tipping Point (Shift)')
        
        # Add numeric labels to Tipping Point for validation (e.g. -0.427 at minute 8)
        for i, val in enumerate(df['tipping_point']):
            ax1_tip.text(x_indices[i], val, f'{val:.3f}', 
                         color='#e67e22', fontsize=8, fontweight='bold',
                         ha='center', va='bottom' if val >= 0 else 'top')

        ax1_tip.set_ylabel('Tipping Point (Delta)', color='#e67e22', fontweight='bold')
        ax1_tip.axhline(0, color='#e67e22', alpha=0.2, linestyle=':')
        ax1_tip.grid(False)

        ax1.set_title('SUCCESS DISTRIBUTION, QUALITY & TIPPING POINT', fontsize=16, fontweight='bold')
        ax1.set_ylabel('Success Count', fontsize=12)
        
        # Consolidate Legends
        lines1, labels1 = ax1_rate.get_legend_handles_labels()
        lines2, labels2 = ax1_tip.get_legend_handles_labels()
        ax1.legend(title='Recommended Action', bbox_to_anchor=(1.25, 1), loc='upper left')
        ax1_rate.legend(lines1 + lines2, labels1 + labels2, loc='upper right', bbox_to_anchor=(1.25, 0.6))

        # --- GRAPH 2: BEHAVIORAL PHYSICS (Z-SCORES) & SIGNIFICANCE ---
        print("Generating physics trend lines and significance shading...")
        
        # Sync ax2 ticks with categorical positions
        ax2.set_xticks(x_indices)
        ax2.set_xticklabels(df['minutes'].astype(int).astype(str))

        # Significance Shading
        ax2.axhspan(1, df['z_momentum'].max() + 0.5 if not df.empty else 2, color='gray', alpha=0.05, label='Significant Zone')
        ax2.axhspan(-1, df['z_momentum'].min() - 0.5 if not df.empty else -2, color='gray', alpha=0.05)

        # Momentum (Bold Green)
        ax2.plot(x_indices, df['z_momentum'], color='#2ecc71', linewidth=4, label='Momentum (Action)', marker='o')
        # Instability (Red)
        ax2.plot(x_indices, df['z_instability'], color='#e74c3c', linewidth=2, linestyle='--', label='Instability (Noise)', marker='x')
        
        # Annotate Peak Momentum
        peak_idx = df['z_momentum'].idxmax()
        ax2.annotate(f'Peak Momentum: {df["z_momentum"].max():.2f}', 
                     xy=(peak_idx, df['z_momentum'].max()), 
                     xytext=(peak_idx, df['z_momentum'].max() + 0.3),
                     arrowprops=dict(facecolor='black', shrink=0.05, width=1, headwidth=5),
                     fontsize=10, fontweight='bold', ha='center')

        ax2.set_title('BEHAVIORAL PHYSICS TRENDS & SIGNIFICANCE', fontsize=16, fontweight='bold')
        ax2.set_xlabel('Session Duration (Minutes)', fontsize=12)
        ax2.set_ylabel('Z-Score (Std Deviations)', fontsize=12)
        ax2.axhline(0, color='black', alpha=0.3, linestyle='-')
        ax2.legend(loc='upper right')

        # --- VERTICAL PHASE TRANSITION MARKERS (Across both plots) ---
        for i in range(len(df)-1):
            if df['action'].iloc[i] != df['action'].iloc[i+1]:
                # Draw line across both subplots
                for ax in [ax1, ax2]:
                    ax.axvline(i + 0.5, color='black', alpha=0.2, linestyle=':', linewidth=2)
                
                # Label the transition on the top plot
                ax1.text(i + 0.5, ax1.get_ylim()[1] * 0.9, ' PHASE SHIFT', 
                         rotation=90, verticalalignment='top', fontsize=8, alpha=0.4, fontweight='bold')

        plt.tight_layout()
        
        # Save output
        output_image = 'behavioral_physics_distribution.png'
        plt.savefig(output_image, dpi=300)
        print(f"\nGraph successfully saved to {output_image}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    run_behavioral_physics_visualization()
