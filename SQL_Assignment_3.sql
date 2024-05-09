
/*
Discount Effects

Using SampleRetail database generate a report, including product IDs and discount effects on whether 
the increase in the discount rate positively impacts the number of orders for the products.

For this, statistical analysis methods can be used. However, this is not expected.

In this assignment, you are expected to generate a solution using SQL with a logical approach. 

Sample Result:
Product_id	Discount Effect
    1	           Positive
    2	           Negative
    3	           Negative
    4	           Neutral
*/

SELECT * FROM sale.order_item
ORDER BY product_id

SELECT product_id, discount, sum(quantity) FROM sale.order_item
GROUP BY product_id, discount
ORDER BY product_id, discount

---

WITH T1 AS (
            SELECT product_id, discount, 
                SUM(quantity) AS total_order,
                ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY discount) AS discount_row,
                AVG(SUM(quantity)) OVER (PARTITION BY product_id ORDER BY discount
                                    ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS avg_ord
            FROM sale.order_item
            GROUP BY product_id, discount
),

T2 AS (
    SELECT *,
        CASE WHEN avg_ord > CAST(LAG(avg_ord) OVER (PARTITION BY product_id ORDER BY discount) AS DECIMAL) THEN 1
             WHEN avg_ord < CAST(LAG(avg_ord) OVER (PARTITION BY product_id ORDER BY discount) AS DECIMAL) THEN -1
            ELSE 0
        END AS discount_change
FROM T1
)

SELECT DISTINCT product_id, 
    CASE 
        WHEN SUM(discount_change) OVER (PARTITION BY product_id) > 1 THEN 'Positive'
        WHEN SUM(discount_change) OVER (PARTITION BY product_id) < 1 THEN 'Negative'
        ELSE 'Neutral'
    END AS Discount_Effect
FROM T2

---





















