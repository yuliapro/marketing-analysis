
📈 Marketing Analysis Toolkit (SQL)
This repository contains a collection of advanced statistical models designed to extract deep behavioral insights from marketing traffic, experiment data, and user behavior.
# 0. When it's not too late to save your user?
<img width="1420" height="1390" alt="image" src="https://github.com/user-attachments/assets/8ee999a9-176b-4329-a785-8a2cdffa57e5" />
Tool link https://github.com/yuliapro/marketing-analysis/tree/main/When_its_too_late_to_save_user%3F
# Behavioral Physics Dashboard 📊🧠

> Turning simple "Duration" metrics into a psychological map of your user's session.

The **Behavioral Physics Dashboard** is built to answer the most critical "Why" and "When" questions about your user journey. By analyzing user behavior through the lens of behavioral physics, it translates raw data into real-time strategic mandates.

---

## 🎯 Strategic Questions Resolved

### 1. The Strategy Question
> *"What should we actually do at this specific minute of the session?"*

* **The Answer:** The action column (color-coded bars) provides a direct mandate:
    * 🔴 **FORCE:** Simplify the UI because users are struggling.
    * 🟢 **INERTIA:** Monetize now because the user is acting by habit.
    * 🔵 **EQUILIBRIUM:** Stay quiet because the interaction is perfectly balanced.
    * 🟡 **TRANSITION:** "Pin" the user with a reward to prevent a drop-off.

### 2. The Bottleneck Question
> *"Where are we losing the most potential value due to friction?"*

* **The Answer:** Look for high **Success Volume** (top bars) coinciding with high **Instability** (red line) and low **Momentum** (green line). These are your "Force" zones where the system is fighting the user’s success.

### 3. The Quality vs. Quantity Question
> *"Are we getting more successes just because there are more users, or is the experience actually better?"*

* **The Answer:** By comparing the **Success Bars (Quantity)** with the **Gold Quality Line (Success Rate)**, you can identify if a specific minute is a *"High Traffic Trap"* or a *"High Conversion Gem."*

### 4. The "Autopilot" Question
> *"At what point does a user stop thinking and start acting by habit?"*

* **The Answer:** The graph identifies the **Inertia Zone**. When the *Green Momentum Line* stays high while the *Red Instability Line* drops, you have found the *"Habitual Autopilot"* zone where conversion is most expensive to lose but easiest to capture.

### 5. The Tipping Point Question
> *"When exactly is it 'too late' to save a session?"*

* **The Answer:** The **Vertical Phase Shift Markers** show the exact minute where user behavior fundamentally changes state (e.g., from *Intent* to *Decay*). This pinpoints the absolute last second to trigger a push notification or a discount.

### 6. The Statistical Significance Question
> *"Is this drop-off a real problem or just a random data flicker?"*

* **The Answer:** The **Gray Shaded Significance Zones** in the bottom graph tell you if the behavior is *"Statistically Unusual"* ($Z\text{-Score} > 1$). If the lines are in the gray, the trend is real and requires a management decision.

### 7. The Momentum Question
> *"Where is the peak psychological 'buy-in' of the user?"*

* **The Answer:** The **Peak Momentum Annotation** points to the exact duration where the user is most engaged with the system, marking the optimal moment for your most important call-to-action (CTA).

---

## 🛠️ Key Metrics Cheat Sheet

| Metric / Visual Cue | What It Represents | Strategic Action |
| :--- | :--- | :--- |
| **Green Line** | Momentum (User Engagement) | Peak indicates ideal CTA timing. |
| **Red Line** | Instability (Friction/Struggle) | High peaks indicate a need for UI simplification. |
| **Gold Line** | Quality (Success Rate) | Differentiates organic conversion from brute traffic volume. |
| **Gray Shaded Zone** | Statistical Significance | $Z\text{-Score} > 1$; marks a real trend, not noise. |
| **Phase Shift Markers** | State Transitions | The boundary line for last-chance retention triggers. |

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
