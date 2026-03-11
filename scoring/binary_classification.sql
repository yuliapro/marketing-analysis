WITH stats_table AS (
   SELECT
            donations.donor_id
           ,COUNT(donations.donation_id) AS donation_count
           ,SUM(donations.amount) AS donation_amount
          
       FROM donations 
       GROUP BY donations.donor_id
       ORDER BY donation_count desc
   )
,global_limits AS
   (SELECT
      
       MIN(donation_count) min_count
       ,MIN(donation_amount) min_amount
       ,MAX(donation_count)  max_count
       ,MAX(donation_amount) max_amount
      
   FROM stats_table)
,normalization AS      
   (SELECT
           donor_id
           ,(donation_count-min_count)/NULLIF(max_count-min_count,0) AS norm_count
           ,(donation_amount-min_amount)/NULLIF(max_amount-min_amount,0) AS norm_amount
       FROM stats_table
       CROSS JOIN global_limits
   )
SELECT
   donor_id
   ,norm_count
   ,norm_amount
   ,norm_amount*0.7 + norm_count*0.3 AS donor_score
FROM normalization
ORDER BY donor_score DESC  
  
   ;

