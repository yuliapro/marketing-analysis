import pyodbc
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Database Connection
conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost,1433;"
    "DATABASE=Datawarehouse;"
    "UID=sa;"
    "PWD=TuPasswordFuerte123;"
    "TrustServerCertificate=yes;"
)

def run_bass_prediction():
    try:
        print("Connecting to database...")
        conn = pyodbc.connect(conn_str)
        
        # 1. Get Factors (p and q) from the SQL model
        with open('simeple_broad_cast_model.sql', 'r') as f:
            factors_query = f.read()
        
        factors_df = pd.read_sql(factors_query, conn)
        p = factors_df['p_factor_broadcast'].iloc[0] / 100.0  # Convert from % to decimal
        q = factors_df['q_factor_contagio'].iloc[0] / 100.0   # Convert from % to decimal
        
        # Ensure factors are not negative (noise in small datasets)
        p = max(p, 0.00001)
        q = max(q, 0.00001)
        
        print(f"Calculated p (Innovation/Broadcast): {p:.6f}")
        print(f"Calculated q (Imitation/Contagion): {q:.6f}")

        # 2. Get Historical Data
        historical_query = "SELECT date, conversion_rate, users, cumulative_success_users FROM gold.dim_by_date_no_outliers ORDER BY date"
        historical_df = pd.read_sql(historical_query, conn)
        conn.close()

        # 3. Simulation Parameters
        M = 100000  # Market Potential assumed in SQL
        days_to_predict = 365 * 5  # 5 years
        t = np.arange(0, days_to_predict)
        
        # Analytical solution for Bass Model cumulative adopters
        N_t = M * (1 - np.exp(-(p + q) * t)) / (1 + (q / p) * np.exp(-(p + q) * t))

        # 4. Find Saturation (e.g., 95% of M)
        saturation_level = 0.95 * M
        day_of_saturation = np.where(N_t >= saturation_level)[0]
        if len(day_of_saturation) > 0:
            sat_day = day_of_saturation[0]
            print(f"Market Saturation (95%) reached at day: {sat_day}")
        else:
            sat_day = None
            print("Saturation not reached within prediction window.")

        # 5. Plotting
        plt.figure(figsize=(12, 7))
        
        # Plot Predicted Cumulative Users
        plt.plot(t, N_t, label='Predicted Cumulative Users (Bass Model)', color='blue', linewidth=2)
        
        # Plot Historical Data
        historical_days = np.arange(len(historical_df))
        plt.scatter(historical_days, historical_df['cumulative_success_users'], 
                    color='red', label='Historical Cumulative Users', s=30, alpha=0.8, edgecolors='black')

        if sat_day:
            plt.axvline(x=sat_day, color='green', linestyle='--', label=f'Saturation Point (Day {sat_day})')
            plt.scatter([sat_day], [N_t[sat_day]], color='green', s=100, zorder=5)
            plt.annotate(f'Saturation\nDay {sat_day}', 
                         xy=(sat_day, N_t[sat_day]), 
                         xytext=(sat_day - 50, N_t[sat_day] - 10000),
                         arrowprops=dict(facecolor='black', shrink=0.05, width=1, headwidth=5))

        plt.title('Market Saturation Prediction - Bass Diffusion Model', fontsize=14)
        plt.xlabel('Days from Launch', fontsize=12)
        plt.ylabel('Total Adopters (Users)', fontsize=12)
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.ylim(0, M * 1.1)
        
        output_file = 'market_saturation_prediction.png'
        plt.savefig(output_file)
        print(f"Prediction graph saved to {output_file}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    run_bass_prediction()
