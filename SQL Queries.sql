#Request No-1  
#Provide a list of products with a base price greater than 500 and
#that are featured in the PROMO TYPE of 'BOGOF'.
SELECT 
	DISTINCT product_name, 
	base_price
FROM
    fact_events
INNER JOIN
    dim_products 
USING 
	(product_code)
WHERE
	base_price > 500
	AND promo_type = 'BOGOF';


# Request No-2
#Generate a report that provides an overview of the number of stores in each city.
SElECT 
    city,
    COUNT(*) AS store_count
FROM
    dim_stores
GROUP BY 
	city
ORDER BY 
	store_count DESC;


# Request No-3
#Generate a report that displays each campaign along with
#the total revenue generated before and after the campaign.
WITH  fact_new AS  (
SELECT 
	campaign_name,
	base_price,
	`quantity_sold(before_promo)` AS quantity_sold_before_promo,
CASE
	WHEN promo_type='25% OFF' THEN base_price*0.75
	WHEN promo_type='33% OFF' THEN base_price*0.67
	WHEN promo_type='50% OFF' THEN base_price*0.5
	WHEN promo_type='500 Cashback' THEN base_price-500
	WHEN promo_type='BOGOF' THEN base_price*0.5
	END AS promo_price,
CASE
	WHEN promo_type='BOGOF' THEN `quantity_sold(after_promo)`*2 ELSE `quantity_sold(after_promo)`
	END AS quantity_sold_after_promo
FROM 
	fact_events
INNER JOIN 
	dim_campaigns
USING 
	(campaign_id)
)
SELECT 
	campaign_name,
	CONCAT(ROUND(SUM(base_price*quantity_sold_before_promo)/1000000,1),"M") AS total_revenue_before_promotion,
	CONCAT(ROUND(SUM(promo_price*quantity_sold_after_promo)/1000000,1),"M") AS total_revenue_after_promotion
FROM 
	fact_new
GROUP BY 
	campaign_name;


# Request No-4
#Produce a report that calculates the Incremental Sold Quantity(ISU%) 
#for each cateogry during the Diwali campaign along with their ranking based on ISU%.
WITH incremental_sold_qty AS  (
SELECT 
	category,
	SUM(`quantity_sold(before_promo)`) AS total_qty_before_promo,
	SUM(CASE WHEN promo_type='BOGOF' THEN `quantity_sold(after_promo)`*2 ELSE `quantity_sold(after_promo)`END)
    - SUM(`quantity_sold(before_promo)`) AS ISU
FROM 
	fact_events
INNER JOIN 
	dim_products
USING 
	(product_code)
WHERE 
	campaign_id='CAMP_DIW_01'
GROUP BY 
	category
)
SELECT 
	category,
	CONCAT(ROUND(100.0*ISU/total_qty_before_promo,1),"%") AS ISU_pct,
    RANK() OVER(ORDER BY ISU/total_qty_before_promo DESC) AS rank_order
FROM
	incremental_sold_qty;


# Request No-5
#Create a report featuring the TOP-5 products, 
#ranked by incremental revenue percentage(IR%) across all campaigns.
WITH fact_new AS (
SELECT 
	product_name,
	category,
	base_price,
	`quantity_sold(before_promo)` AS quantity_sold_before_promo,
CASE
	WHEN promo_type='25% OFF' THEN base_price*0.75
	WHEN promo_type='33% OFF' THEN base_price*0.67
	WHEN promo_type='50% OFF' THEN base_price*0.5
	WHEN promo_type='500 Cashback' THEN base_price-500
	WHEN promo_type='BOGOF' THEN base_price*0.5
	END AS promo_price,
CASE
	WHEN promo_type='BOGOF' THEN `quantity_sold(after_promo)`*2 ELSE `quantity_sold(after_promo)`
	END AS quantity_sold_after_promo
FROM 
	fact_events
INNER JOIN 
	dim_products
USING 
	(product_code)
)
SELECT 
	product_name,
    category,
	CONCAT(ROUND(100.0*(SUM(promo_price*quantity_sold_after_promo) - SUM(base_price*quantity_sold_before_promo))
	/SUM(base_price*quantity_sold_before_promo),1),"%") AS IR_pct
FROM 
	fact_new
GROUP BY
	product_name,category
ORDER BY 
	IR_pct DESC
LIMIT 5;


