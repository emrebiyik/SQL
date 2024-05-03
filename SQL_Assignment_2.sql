
/*
1. Product Sales
You need to create a report on whether customers who purchased the product named '2TB Red 5400 rpm SATA III 3.5 Internal NAS HDD' buy the product below or not.

1. 'Polk Audio - 50 W Woofer - Black' -- (other_product)

To generate this report, you are required to use the appropriate SQL Server Built-in functions or expressions as well as basic SQL knowledge.

*/



SELECT Cu.customer_id, Cu.first_name, Cu.last_name,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM sale.orders AS Ord
            INNER JOIN sale.order_item AS It 
                ON It.order_id = Ord.order_id
            INNER JOIN product.product AS Prod 
                ON Prod.product_id = It.product_id
            WHERE Ord.customer_id = Cu.customer_id
            AND Prod.product_name = 'Polk Audio - 50 W Woofer - Black'
        )
        THEN 'Yes'
        ELSE 'No'
    END AS Other_Product
FROM sale.customer AS Cu
INNER JOIN sale.orders AS O 
    ON O.customer_id = Cu.customer_id
INNER JOIN sale.order_item AS I 
    ON I.order_id = O.order_id 
WHERE I.product_id = (
    SELECT product_id
    FROM product.product
    WHERE product_name = '2TB Red 5400 rpm SATA III 3.5 Internal NAS HDD'
)
ORDER BY Cu.customer_id;

/*
2. Conversion Rate
Below you see a table of the actions of customers visiting the website by clicking on two different types 
of advertisements given by an E-Commerce company. Write a query to return the conversion rate for each 
Advertisement type.

Actions:

Visitor_ID

Adv_Type

Action


A

0.33

B

0.25

 
a.    Create above table (Actions) and insert values, 

b.    Retrieve count of total Actions and Orders for each Advertisement Type,

c.    Calculate Orders (Conversion) rates for each Advertisement Type by dividing by total count of actions casting as float by multiplying by 1.0.
*/


CREATE TABLE Actions (
    Visitor_ID INT,
    Adv_Type CHAR(1),
    Action VARCHAR(10)
);

INSERT INTO Actions (Visitor_ID, Adv_Type, Action) VALUES
(1, 'A', 'Left'),
(2, 'A', 'Order'),
(3, 'B', 'Left'),
(4, 'A', 'Order'),
(5, 'A', 'Review'),
(6, 'A', 'Left'),
(7, 'B', 'Left'),
(8, 'B', 'Order'),
(9, 'B', 'Review'),
(10, 'A', 'Review');

SELECT
    Adv_Type,
    COUNT(*) AS Total_Actions,
    SUM(CASE WHEN Action = 'Order' THEN 1 ELSE 0 END) AS Total_Orders
FROM
    Actions
GROUP BY
    Adv_Type;


SELECT
    Adv_Type,
    CAST(ROUND(COUNT(CASE WHEN Action = 'Order' THEN 1 END)*1.0 / COUNT(Action), 2) AS DECIMAL(10,2)) AS Conversion_Rate
FROM
    Actions
GROUP BY
    Adv_Type;

