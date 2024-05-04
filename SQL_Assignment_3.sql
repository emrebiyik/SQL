
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

SELECT *,
    Product_id,
    CASE
        WHEN avg_orders_increase > 0 THEN 'Positive'
        WHEN avg_orders_increase < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Discount_Effect
FROM
    (
        SELECT
            Product_id,
            AVG(Orders) AS avg_orders,
            AVG(Orders) - LAG(AVG(Orders), 1, 0) OVER (PARTITION BY Product_id ORDER BY Discount_Rate) AS avg_orders_increase
        FROM
            YourTableNameHere -- Replace YourTableNameHere with the appropriate table name
        GROUP BY
            Product_id, Discount_Rate
    ) AS OrderStats
GROUP BY
    product_id;



select * from sale.order_item

SELECT
            product_id,
            AVG(quantity) AS avg_quantity,
            AVG(quantity) - LAG(AVG(quantity), 1, 0) OVER (PARTITION BY product_id ORDER BY discount) AS avg_orders_increase
        FROM
            sale.order_item 
        GROUP BY
            product_id, discount


SELECT 
    product_id,
    CASE
        WHEN avg_orders_increase > 0 THEN 'Positive'
        WHEN avg_orders_increase < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS discount_effect
FROM
    (
     SELECT
            product_id,
            AVG(quantity) AS avg_quantity,
            AVG(quantity) - LAG(AVG(quantity), 1, 0) OVER (PARTITION BY product_id ORDER BY discount) AS avg_orders_increase
        FROM
            sale.order_item 
        GROUP BY
            product_id, discount
    ) AS OrderStats












