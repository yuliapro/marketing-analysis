
📈 Marketing Analysis Toolkit (SQL)
This repository contains a collection of advanced statistical models designed to extract deep behavioral insights from marketing traffic, experiment data, and user behavior.

1. The "Norm" Check
  
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


4. The "Success Formula"
   
===Create a single score from multiple attributes to rank users and identify dependencies===

Business Questions:
- The Success Formula: What attributes do we have at our "Success Score"?
- Priority Ranking: Which Specific Factors Drive Success? (SHAP Discovery Plot)
  
 * * * Metrics: Random Forest Classification, Scoring, Machine Learning, Shaplay Value * * *
Based on SHAP and Lift analyses, here is the streamlined Success Probability Score
(0–100):$$Score = (Z_{pts} \times 0.65) + (Cat_{pts} \times 0.20) + (Exp_{pts} \times 0.15)$$
1.Z-Score Points (65% – Individual Performance)
Normalizes effort while capping outliers:Z $\leq$ -1: 0 pts (Underperformer).Z = 0: 50 pts (Average).Z $\geq$ 2.5: 100 pts (Top Performer).
2. Category Lift (20% – Historical Context)0% Lift: 50 pts.+50% Lift: 100 pts.
3. 3. Experiment Boost (15% – Test Impact)Follows Category logic but with lower weight due to its temporary nature.
<img width="1004" height="894" alt="attributes_analyzer_img" src="https://github.com/user-attachments/assets/bcbeccab-dd08-4a2d-98c7-1cd2a3dc1763" />

 ANALYZE YOUR ATTRIBUTES AUTOMATICALLY here https://github.com/yuliapro/marketing-analysis/blob/main/Which_attibute_drives_Success/attributes_analyzer.py
<br/>


===
===

5. The "Intelligence" Check
   
=== Measure the productivity of your marketing funnel and the ROI of your user experience===

Business Questions:
- Funnel Intelligence: How efficient is our current user experience? Is it "intelligent" at converting effort into value?
- Value Identification: Is this a high-value user, or are we over-investing in a low-value segment?
- Resource Optimization: Can I earn more with the same resources? Am I wasting effort, or am I spending it intelligently?
  
 * * * Metrics: Solow Growth Model, Efficiency * * *

<img width="786" height="565" alt="Screenshot 2026-03-25 at 17 34 11" src="https://github.com/user-attachments/assets/e2d664d9-2d37-4aee-8e8b-40f76d4808e8" />

<br/>

CLICK HERE TO CHECK YOUR FUNNEL AT FUNNEL_ANALYZER:
https://github.com/yuliapro/marketing-analysis/tree/main/funnel_analyzer

===
===

6. The "Game Changer" Check
   
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
