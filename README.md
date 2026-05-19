
📈 Marketing Analysis Toolkit (SQL)
This repository contains a collection of advanced statistical models designed to extract deep behavioral insights from marketing traffic, experiment data, and user behavior.
# 0. When it's not too late to save your user?
### 📊 User Journey Statilizer
<img width="1214" height="667" alt="Screenshot 2026-05-19 at 15 19 24" src="https://github.com/user-attachments/assets/425973f0-d09c-4e97-841d-10301c181cb2" />

#### 1. What does "Success" look like in the journey?
* **The Answer:** Success is identified by high PSI ($\psi > 2.0$) and positive Intent Flux. 
* **The Metric:** In the graphs, these are the **Green bubbles (Flow State)**. It marks a coordinate where users exhibit high retention probability and high conversion momentum simultaneously.

---

#### 2. What is the recommended product action right now?
* **The Answer:** The script prescribes four **"Surgical Interventions"** based on the user's current stability matrix:
  * 🚀 **Upsell / Monetize:** For users in "Flow" ($\psi > 2.0$).
  * 💎 **Reward / Incentivize:** For users "At the Edge" ($\psi \in [0.5, 2.0]$).
  * 🗺️ **Guide / Tutorial:** For users in "Stagnant" zones ($\psi \in [0.0, 0.5]$).
  * 🩹 **Recover / Re-engage:** For users in "Conflict" zones ($\psi < 0.0$).

---

#### 3. At what exact minute and level do users lose interest?
* **The Answer:** The *Dual-Axis Stability Graph* shows exactly where the PSI drops below `0.0`. 
* **The Insight:** It pinpoints whether the issue is **Time-based** (e.g., users get bored at Minute 10) or **Complexity-based** (e.g., Level 5 acts as a "wall" causing systemic instability).

---

#### 4. Which parts of the journey are "leaking" energy?
* **The Answer:** Behavioral steps displaying **Negative Intent Flux** or high Instability.
* **The Insight:** These are points where system energy turns chaotic—meaning the product environment is losing users faster than it is converting them.

---

#### 5. Where is the journey's "Tipping Point"?
* **The Answer:** Defined by the **Grip (Tipping Point)** metric.
* **The Insight:** It identifies the micro-moment where a user's survival probability permanently deviates from the baseline average. This represents the **"Point of No Return"** where tactical interventions must be deployed to prevent churn.

---

#### 6. Is the user experience "Healthy" or "Turbulent"?
* **The Answer:** Assessed via the global map distribution within the **Strategic Action Map**.
* **The Insight:** 
  * 🔴 / 🔵 **Mostly Red or Blue:** The user journey is fundamentally unstable and requires immediate UX refactoring.
  * 🟢 / 🟡 **Mostly Green and Yellow:** A high-performing user journey optimized for aggressive monetization.

---

#### 7. Does complexity (Level) scale correctly with time?
* **The Answer:** Evaluated by mapping coordinates across **PSI vs. M/L (Minutes/Level)**. 

By treating user progression as a dynamic physical system, this engine calculates momentum, instability, and intent flux to prescribe surgical product interventions in real-time.

Tool link https://github.com/yuliapro/marketing-analysis/tree/main/What_is_the_current_Session_Health%3F

---
# Momenta 📊🧠

> **The Behavioral Physics Dashboard.** Turning session duration into a psychological map of your user's journey.
### 1. "What should we actually do at this specific minute of the session?"
* **The Answer:** Follow the color-coded action column mandates:
  * 🔴 **FORCE:** Simplify UI (users are struggling).
  * 🟢 **INERTIA:** Monetize now (users are acting by habit).
  * 🔵 **EQUILIBRIUM:** Stay quiet (perfectly balanced interaction).
  * 🟡 **TRANSITION:** Pin the user with a reward (prevent drop-off).

### 2. "Where are we losing the most potential value due to friction?"
* **The Answer:** Look for high **Success Volume** coinciding with high **Instability** (Red Line) and low **Momentum** (Green Line).

### 3. "Are we getting more successes just because there are more users, or is the experience actually better?"
* **The Answer:** Compare **Success Bars** (Quantity) against the **Gold Line** (Success Rate) to spot "High Traffic Traps."

### 4. "At what point does a user stop thinking and start acting by habit?"
* **The Answer:** The **Inertia Zone**—where the Green Line (Momentum) stays high but the Red Line (Instability) drops.

### 5. "When exactly is it 'too late' to save a session?"
* **The Answer:** At the **Vertical Phase Shift Markers**. This is your last-second window for a discount or notification.

### 6. "Is this drop-off a real problem or just a random data flicker?"
* **The Answer:** Look at the **Gray Shaded Zones**. If data enters this zone ($Z\text{-Score} > 1$), it is statistically significant.

### 7. "Where is the peak psychological 'buy-in' of the user?"
* **The Answer:** The **Peak Momentum Annotation**—the exact minute the user is most engaged, marking your optimal CTA window.
<img width="1420" height="1390" alt="image" src="https://github.com/user-attachments/assets/8ee999a9-176b-4329-a785-8a2cdffa57e5" />
Tool link https://github.com/yuliapro/marketing-analysis/tree/main/When_its_too_late_to_save_user%3F

---


# 0. The "Growth" Check
<img width="963" height="684" alt="Screenshot 2026-04-17 at 21 21 35" src="https://github.com/user-attachments/assets/ecc3e9ad-fabc-4904-bef2-30dcad770ec3" />

Input 3 columns: date, clicks, conversions and find out now at my Growth-Trustometer here!
https://github.com/yuliapro/marketing-analysis/blob/main/What_is_daily_evolution/Growth-Momentum-Analyzer_auto.sql

# 1. The "Norm" Check
  
===Understand what a "typical" journey looks like and identify if your success is driven by a broad base or a few heavy users===

Business Questions: 
- What is the norm?
- How does the actual user experience deviate from our "average" expectation?
- Segmentation: Are we looking at one unified audience, or are there distinct, hidden user segments?
- Equity vs. Dependence: Is our experience satisfying all users, or are we overly dependent on a few high-value segments?
- Resource Allocation: Is the "input" (value/effort) spread equally, or is it concentrated in a small group?
  
 * * *  Metrics: Distribution graph, Pearson & Fisher Skewness, Gini Coefficient, Running Percentage, Percent Rank * * *



2. The "Consistency" Check
      
===Analyze how varied or uniform your user journeys actually are.===

Business Questions:
- Similar or Diverse? Is the user experience consistent across the board, or is it highly diverse?
- Deviation from the Norm: How much does each individual user experience differ from the "average" or "normal" behavior?
  
 * * *  Metrics:Variance, Standard Deviation,CV * * *




3. The "Bot & VIP" Check
       
===Identify and group users based on their specific behavior to optimize targeting===

Business Questions:
- Unusual Behavior: Which users show irregular or outlier behavior compared to the rest?
- Custom Treatment: Should we treat specific user segments differently to maximize their value?
-  Anomaly Detection: Are there bot users or "bad actors" mixed in with our real traffic?
  
 * * *  Metrics: Categorization, Z-Score, Min-Max Normalization * * *
       <img width="1092" height="719" alt="Screenshot 2026-03-23 at 17 04 23" src="https://github.com/user-attachments/assets/5b486a18-1e37-4c1b-b09f-c7ee09b5895a" />

CLICK HERE TO CREATE YOUR FUNNEL COMPASS:
https://github.com/yuliapro/marketing-analysis/tree/main/the_funnel_compass

===
===


# 4. "Success Formula"
   
Business Questions:
- The Success Formula: What attributes do we have at our "Success Score"?
- Priority Ranking: Which Specific Factors Drive Success? (SHAP Discovery Plot)
  
 * * * Metrics: Random Forest Classification, Scoring, Machine Learning, Shaplay Value * * *
     * 


Based on the SHAP analysis and Lift metrics, this formula calculates a **Success Probability Score (0–100)**. It prioritizes individual effort while adjusting for the historical context of the category and the specific experiment.

### The Formula
$$Score = (Z_{pts} \times 0.65) + (Cat_{pts} \times 0.20) + (Exp_{pts} \times 0.15)$$

---

### 1. Z-Score Points (65% – Individual Performance)
The primary driver of the score. This normalizes individual effort while capping extreme outliers:
* **Z-Score $\leq$ -1**: 0 pts (Underperformer)
* **Z-Score = 0**: 50 pts (Average)
* **Z-Score $\geq$ 2.5**: 100 pts (Top Performer)

### 2. Category Lift (20% – Historical Context)
Adjusts the score based on the performance of the user's funnel:
* **0% Lift**: 50 pts
* **+50% Lift or higher**: 100 pts

### 3. Experiment Boost (15% – Test Impact)
An additional boost based on the success of the current experiment. It follows the same logic as the Category Lift but carries lower weight due to the temporary nature of experiments.

<img width="1004" height="894" alt="attributes_analyzer_img" src="https://github.com/user-attachments/assets/bcbeccab-dd08-4a2d-98c7-1cd2a3dc1763" />

 ANALYZE YOUR ATTRIBUTES AUTOMATICALLY here https://github.com/yuliapro/marketing-analysis/blob/main/Which_attibute_drives_Success/attributes_analyzer.py
<br/>


===
===

# 5. The "Intelligence" Check
   
=== Measure the productivity of your marketing funnel and the ROI of your user experience===

Business Questions:
- Funnel Intelligence: How efficient is our current user experience? Is it "intelligent" at converting effort into value?
- Value Identification: Is this a high-value user, or are we over-investing in a low-value segment?
- Resource Optimization: Can I earn more with the same resources? Am I wasting effort, or am I spending it intelligently?
  
 * * * Metrics: Solow Growth Model, Efficiency * * *
<img width="963" height="638" alt="Screenshot 2026-04-17 at 19 05 22" src="https://github.com/user-attachments/assets/f0d523a1-022d-47a8-8485-9a93733f11eb" />


<img width="786" height="565" alt="Screenshot 2026-03-25 at 17 34 11" src="https://github.com/user-attachments/assets/e2d664d9-2d37-4aee-8e8b-40f76d4808e8" />

<br/>

CLICK HERE TO CHECK YOUR FUNNEL AT FUNNEL_ANALYZER:
https://github.com/yuliapro/marketing-analysis/tree/main/funnel_analyzer

===
===

#6. The "Game Changer" Check
   
===Calculate the true marginal impact of every experiment or funnel step===

Business Questions:
- Performance Comparison: Which specific test or experiment worked better than the baseline?
- The "Game Changer": Was this test a significant driver of change, or just a minor improvement?
- Funnel Importance: How much weight does this specific step carry in the overall user journey toward success?
  
 * * * Metrics: Shapley Value (Marginal Contribution analysis) * * *
       
  <img width="1056" height="682" alt="Screenshot 2026-03-23 at 17 05 58" src="https://github.com/user-attachments/assets/d7876f54-f9cc-422b-9ccd-8b0733bf4a8c" />

CLICK HERE TO CHECK YOUR EXPERIMENT AT LIFT_SEGMENT_ANALYZER:
https://github.com/yuliapro/marketing-analysis/tree/main/exp_lift_analyzer

======================================================================================================================================

🚀 How to Use These Templates
1. Define your Dimension: (e.g., campaign_id, region, or user_id).
2. Define your Metric: (e.g., sessions, revenue, or donations).
3. Plug & Play: Each SQL file is modular. Update the base_data CTE at the top, and the statistical calculations will update automatically.

🛠 Tech Stack
Language: SQL (Optimized for BigQuery, Snowflake, and Redshift).
Math: Descriptive Statistics, Linear Normalization, and Attribution Modeling.
