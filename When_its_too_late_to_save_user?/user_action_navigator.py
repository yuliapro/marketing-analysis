"""
=============================================================================
🚀 BEHAVIORAL PHYSICS VISUALIZER - TEMPLATE
=============================================================================
An automated dashboard generator for the Behavioral Physics Engine (BPE).
This script visualizes the interplay between success volume, quality, 
and underlying psychological momentum.

💡 KEY QUESTIONS THIS DASHBOARD ANSWERS:
-----------------------------------------------------------------------------
1. STRATEGIC MANDATE: Where should we Simplify UI vs. Monetize vs. Pin the user?
2. QUALITY VS VOLUME: Is high success driven by traffic or by genuine engagement?
3. PHYSICS DRIVERS: When does user Momentum cross System Instability?
4. PHASE TRANSITIONS: At what exact minute does the user's intent shift?
5. STATISTICAL VALIDATION: Are these trends significant (Z-Score > 1)?

INSTRUCTIONS:
1. Export your BPE analysis results to a CSV file.
2. Update the 'CONFIG' dictionary below with your file path and column names.
3. Run: python behavioral_visualizer_template.py
=============================================================================
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os

# -----------------------------------------------------------------------------
# ⚙️ CONFIGURATION (Update these to match your CSV)
# -----------------------------------------------------------------------------
CONFIG = {
    'FILE_PATH': '/Users/yulia/Downloads/_BEHAVIORAL_PHYSICS_STRATEGIC_ACTION_TEMPLATE_Dynamic_SQL_INSTRU_202605151035.csv',
    
    # Column Mapping
    'COL_MINUTES':       'minutes',
    'COL_SUCCESS_CNT':   'success_cnt',
    'COL_SUCCESS_RATE':  'success_rate',
    'COL_TIPPING_POINT': 'tipping_point',
    'COL_Z_MOMENTUM':    'z_momentum',
    'COL_Z_INSTABILITY': 'z_instability',
    'COL_ACTION':        'action',
    
    # Output Settings
    'OUTPUT_NAME': 'behavioral_physics_dashboard.png',
    'MIN_USERS': 200 # Optional filter for significance
}

def generate_bpe_dashboard():
    try:
        # 1. Load Data
        if not os.path.exists(CONFIG['FILE_PATH']):
            print(f"Error: File not found at {CONFIG['FILE_PATH']}")
            return
            
        print(f"Loading data from {CONFIG['FILE_PATH']}...")
        df = pd.read_csv(CONFIG['FILE_PATH'])
        
        # 2. Pre-processing
        # Sort by minutes and ensure names are mapped correctly
        df = df.sort_values(CONFIG['COL_MINUTES']).reset_index(drop=True)
        
        # Rename for internal logic consistency
        mapping = {
            CONFIG['COL_MINUTES']:       'minutes',
            CONFIG['COL_SUCCESS_CNT']:   'success_cnt',
            CONFIG['COL_SUCCESS_RATE']:  'success_rate',
            CONFIG['COL_TIPPING_POINT']: 'tipping_point',
            CONFIG['COL_Z_MOMENTUM']:    'z_momentum',
            CONFIG['COL_Z_INSTABILITY']: 'z_instability',
            CONFIG['COL_ACTION']:        'action'
        }
        df = df.rename(columns=mapping)

        # 3. Setup Plots (2 Subplots)
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(15, 14), sharex=False)
        sns.set_style("whitegrid")

        # Define strategic palette
        palette = {
            'FORCE: Simplify the UI': '#e74c3c',   # Red
            'INERTIA: Monetize': '#2ecc71',        # Green
            'EQUILIBRIUM: keep doing it': '#3498db',# Blue
            'TRANSITION: Pin user': '#9b59b6'      # Purple
        }

        # --- GRAPH 1: SUCCESS DISTRIBUTION, QUALITY & TIPPING POINT ---
        print("Rendering Top Panel: Success & Quality...")
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
        
        x_indices = np.arange(len(df))

        # Annotate bars with duration
        for i, p in enumerate(ax1.patches):
            height = p.get_height()
            if height > 0:
                m_idx = int(round(p.get_x() + p.get_width()/2. - 0.5))
                if 0 <= m_idx < len(df):
                    ax1.text(p.get_x() + p.get_width()/2., height + (ax1.get_ylim()[1]*0.01),
                             f'{int(df["minutes"].iloc[m_idx])}m', 
                             ha='center', va='bottom', fontsize=7, rotation=90, alpha=0.6, fontweight='bold')

        ax1.tick_params(labelbottom=True)
        
        # Secondary Y-Axis: Success Rate (Quality)
        ax1_rate = ax1.twinx()
        ax1_rate.plot(x_indices, df['success_rate'], color='#f1c40f', linewidth=2, marker='s', alpha=0.6, label='Success Rate (Quality)')
        ax1_rate.set_ylabel('Success Rate (%)', color='#f39c12', fontweight='bold')
        ax1_rate.grid(False)
        
        # Third Y-Axis: Tipping Point (Shift)
        ax1_tip = ax1.twinx()
        ax1_tip.spines['right'].set_position(('outward', 60))
        ax1_tip.plot(x_indices, df['tipping_point'], color='#e67e22', linewidth=2, linestyle='-.', alpha=0.8, label='Tipping Point (Shift)')
        
        # Tipping Point Value Labels (Precision Validation)
        for i, val in enumerate(df['tipping_point']):
            ax1_tip.text(x_indices[i], val, f'{val:.3f}', 
                         color='#e67e22', fontsize=8, fontweight='bold',
                         ha='center', va='bottom' if val >= 0 else 'top')

        ax1_tip.set_ylabel('Tipping Point (Delta)', color='#e67e22', fontweight='bold')
        ax1_tip.axhline(0, color='#e67e22', alpha=0.2, linestyle=':')
        ax1_tip.grid(False)

        ax1.set_title('SUCCESS DISTRIBUTION, QUALITY & TIPPING POINT', fontsize=16, fontweight='bold')
        ax1.set_ylabel('Success Count', fontsize=12)
        
        # Legends
        lines1, labels1 = ax1_rate.get_legend_handles_labels()
        lines2, labels2 = ax1_tip.get_legend_handles_labels()
        ax1.legend(title='Recommended Action', bbox_to_anchor=(1.25, 1), loc='upper left')
        ax1_rate.legend(lines1 + lines2, labels1 + labels2, loc='upper right', bbox_to_anchor=(1.25, 0.6))

        # --- GRAPH 2: BEHAVIORAL PHYSICS (Z-SCORES) & SIGNIFICANCE ---
        print("Rendering Bottom Panel: Behavioral Physics...")
        ax2.set_xticks(x_indices)
        ax2.set_xticklabels(df['minutes'].astype(int).astype(str))

        # Significance Shading
        ax2.axhspan(1, df['z_momentum'].max() + 0.5, color='gray', alpha=0.05, label='Significant Zone')
        ax2.axhspan(-1, df['z_momentum'].min() - 0.5, color='gray', alpha=0.05)

        # Momentum & Instability Trend Lines
        ax2.plot(x_indices, df['z_momentum'], color='#2ecc71', linewidth=4, label='Momentum (Action)', marker='o')
        ax2.plot(x_indices, df['z_instability'], color='#e74c3c', linewidth=2, linestyle='--', label='Instability (Noise)', marker='x')
        
        # Annotate Peak Momentum
        peak_idx = df['z_momentum'].idxmax()
        ax2.annotate(f'Peak Momentum: {df["z_momentum"].max():.2f}', 
                     xy=(peak_idx, df['z_momentum'].max()), 
                     xytext=(peak_idx, df['z_momentum'].max() + 0.3),
                     arrowprops=dict(facecolor='black', shrink=0.05, width=1, headwidth=HEADWIDTH_DEMO if 'HEADWIDTH_DEMO' in globals() else 5),
                     fontsize=10, fontweight='bold', ha='center')

        ax2.set_title('BEHAVIORAL PHYSICS TRENDS & SIGNIFICANCE', fontsize=16, fontweight='bold')
        ax2.set_xlabel('Session Duration (Minutes)', fontsize=12)
        ax2.set_ylabel('Z-Score (Std Deviations)', fontsize=12)
        ax2.axhline(0, color='black', alpha=0.3, linestyle='-')
        ax2.legend(loc='upper right')

        # --- VERTICAL PHASE TRANSITION MARKERS ---
        for i in range(len(df)-1):
            if df['action'].iloc[i] != df['action'].iloc[i+1]:
                for ax in [ax1, ax2]:
                    ax.axvline(i + 0.5, color='black', alpha=0.2, linestyle=':', linewidth=2)
                ax1.text(i + 0.5, ax1.get_ylim()[1] * 0.9, ' PHASE SHIFT', 
                         rotation=90, verticalalignment='top', fontsize=8, alpha=0.4, fontweight='bold')

        plt.tight_layout()
        plt.savefig(CONFIG['OUTPUT_NAME'], dpi=300)
        print(f"\nDashboard successfully saved to {CONFIG['OUTPUT_NAME']}")

    except Exception as e:
        print(f"Error generating dashboard: {e}")

if __name__ == "__main__":
    generate_bpe_dashboard()
