/*

E-Commerce Data and Customer Retention Analysis with SQL
_________________________________________________________

An e-commerce organization demands some analysis of sales and shipping processes. Thus, the organization hopes to be able to 
predict more easily the opportunities and threats for the future.

According to this scenario, You are asked to make the following analyzes consistant with following the instructions given.

Introduction
- You have to create a database and import into the given csv file. (You should research how to import a .csv file)
- During the import process, you will need to adjust the date columns. You need to carefully observe the data types 
and how they should be.
- The data are not very clean and fully normalized. However, they don't prevent you from performing the given tasks.
- Manually verify the accuracy of your analysis.

*/

CREATE DATABASE ECommerce;

SELECT * FROM ECommerce;

--------------------- Analyze the data by finding the answers to the questions below:


-- 1. Find the top 3 customers who have the maximum count of orders.


SELECT TOP 3 Cust_ID, COUNT(*) AS order_count
FROM ECommerce 
GROUP BY Cust_ID
ORDER BY order_count DESC;




-- 2. Find the customer whose order took the maximum time to get shipping.


SELECT TOP 1 Cust_ID, Customer_Name, DATEDIFF(DAY, Order_Date, Ship_Date) Date_Diff 
FROM ECommerce
ORDER BY Date_Diff DESC



-- 3. Count the total number of unique customers in January and how many of them came back 
-- again in the each one months of 2011.


-- Total number of unique customers in January 2011
SELECT COUNT(DISTINCT Cust_ID) AS january_customers
FROM ECommerce
WHERE YEAR(Order_Date) = 2011
AND MONTH(Order_Date) = 1;

-- Count of customers from January 2011 who returned in each subsequent month of 2011
SELECT MONTH(Order_Date) AS month,
       COUNT(DISTINCT Cust_ID) AS returning_customers
FROM ECommerce
WHERE YEAR(Order_Date) = 2011
AND Cust_ID IN (
    SELECT DISTINCT Cust_ID
    FROM ECommerce
    WHERE YEAR(Order_Date) = 2011
    AND MONTH(Order_Date) = 1)
GROUP BY MONTH(Order_Date)
ORDER BY month;

-- Count the number of customers who made a purchase in January 2011 and 
-- returned to make purchases in each subsequent month of 2011.
SELECT COUNT(DISTINCT Cust_ID) AS returning_customers
FROM ECommerce
WHERE YEAR(Order_Date) = 2011
AND (
    MONTH(Order_Date) != 1
    AND Cust_ID IN (
        SELECT DISTINCT Cust_ID
        FROM ECommerce
        WHERE YEAR(Order_Date) = 2011
        AND MONTH(Order_Date) = 1)
)

--- Combining above queries into a single query using Common Table Expressions (CTEs) 

WITH JanuaryCustomers AS (
    -- Total number of unique customers in January 2011
    SELECT DISTINCT Cust_ID
    FROM ECommerce
    WHERE YEAR(Order_Date) = 2011
    AND MONTH(Order_Date) = 1
),
ReturningCustomers AS (
    -- Customers who made purchases in months other than January 2011
    SELECT DISTINCT Cust_ID
    FROM ECommerce
    WHERE YEAR(Order_Date) = 2011
    AND MONTH(Order_Date) != 1
)
-- Count the number of customers who made a purchase in January 2011 and also made purchases in other months of 2011
SELECT COUNT(DISTINCT jc.Cust_ID) AS returning_customers
FROM JanuaryCustomers jc
JOIN ReturningCustomers rc ON jc.Cust_ID = rc.Cust_ID;



-- 4. Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, 
-- in ascending order by Customer ID.


WITH RankedOrders AS (
    SELECT 
        Distinct Cust_ID,
        order_date,
        DENSE_RANK() OVER (PARTITION BY Cust_ID ORDER BY order_date) AS order_rank
    FROM ECommerce
)
SELECT 
    ro1.Cust_ID,
    DATEDIFF(DAY, ro1.order_date, ro3.order_date) AS days_between_first_and_third_purchase
FROM 
    RankedOrders ro1
    INNER JOIN RankedOrders ro3 ON ro1.Cust_ID = ro3.Cust_ID
WHERE 
    ro1.order_rank = 1
    AND ro3.order_rank = 3
ORDER BY 
    ro1.Cust_ID;

---WITH NULL

WITH ranked_purchases AS (
    SELECT
        Cust_ID,Ord_ID,
        Order_Date,
        dense_rank() OVER (PARTITION BY Cust_ID ORDER BY  Order_Date) AS purchase_rank
    FROM
       ECommerce
)
SELECT
    Cust_ID,
    DATEDIFF(DAY, first_purchase_date, third_purchase_date) AS time_elapsed
FROM (
    SELECT
        Cust_ID,
        MAX(CASE WHEN purchase_rank = 1 THEN Order_Date END) AS first_purchase_date,
        MAX(CASE WHEN purchase_rank = 3 THEN Order_Date END) AS third_purchase_date
    FROM
        ranked_purchases
    WHERE
        purchase_rank IN (1, 3)
    GROUP BY
        Cust_ID
) AS purchase_dates
ORDER BY
    Cust_ID;

-- 5. Write a query that returns customers who purchased both product 11 and product 14, as well as 
-- the ratio of these products to the total number of products purchased by the customer.


SELECT Cust_ID, Prod_ID
FROM ECommerce
WHERE Prod_ID IN ('Prod_11', 'Prod_14') --442 rows


SELECT Cust_ID
FROM ECommerce
WHERE Prod_ID IN ('Prod_11', 'Prod_14')
GROUP BY Cust_ID
HAVING COUNT(DISTINCT Prod_ID) = 2; --17 rows


-- Product Ratio

WITH CustomerProducts AS (
    SELECT 
        Cust_ID,
        COUNT(*) AS total_products_purchased
    FROM 
        ECommerce
    GROUP BY 
        Cust_ID
)
SELECT 
    cp.Cust_ID,
    cp.total_products_purchased,
    SUM(CASE WHEN e.Prod_ID = 'Prod_11' THEN 1 ELSE 0 END) AS product_11_count,
    SUM(CASE WHEN e.Prod_ID = 'Prod_14' THEN 1 ELSE 0 END) AS product_14_count,
    CAST(
        CASE 
            WHEN cp.total_products_purchased > 0 THEN 
                ROUND((SUM(CASE WHEN e.Prod_ID = 'Prod_11' THEN 1 ELSE 0 END) + 
                       SUM(CASE WHEN e.Prod_ID = 'Prod_14' THEN 1 ELSE 0 END)) * 1.0 / cp.total_products_purchased, 3)
            ELSE 0
        END AS DECIMAL(18, 2)
    ) AS product_11_14_ratio
FROM 
    CustomerProducts cp
INNER JOIN 
    ECommerce e ON cp.Cust_ID = e.Cust_ID
WHERE 
    e.Prod_ID IN ('Prod_11', 'Prod_14')
GROUP BY 
    cp.Cust_ID, cp.total_products_purchased
HAVING 
    COUNT(DISTINCT e.Prod_ID) = 2;


-- Quantity Ratio

WITH CustomerProducts AS (
    SELECT 
        Cust_ID,
        SUM(Order_Quantity) AS total_products_purchased
    FROM 
        ECommerce
    GROUP BY 
        Cust_ID
)
SELECT 
    cp.Cust_ID,
    cp.total_products_purchased,
    SUM(CASE WHEN e.Prod_ID = 'Prod_11' THEN e.Order_Quantity ELSE 0 END) AS product_11_quantity,
    SUM(CASE WHEN e.Prod_ID = 'Prod_14' THEN e.Order_Quantity ELSE 0 END) AS product_14_quantity,
    CAST(
        CASE 
            WHEN cp.total_products_purchased > 0 THEN 
                ROUND((SUM(CASE WHEN e.Prod_ID = 'Prod_11' THEN e.Order_Quantity ELSE 0 END) + 
                       SUM(CASE WHEN e.Prod_ID = 'Prod_14' THEN e.Order_Quantity ELSE 0 END)) * 1.0 / cp.total_products_purchased, 3)
            ELSE 0
        END AS DECIMAL(18, 2)
    ) AS product_11_14_ratio
FROM 
    CustomerProducts cp
INNER JOIN 
    ECommerce e ON cp.Cust_ID = e.Cust_ID
WHERE 
    e.Prod_ID IN ('Prod_11', 'Prod_14')
GROUP BY 
    cp.Cust_ID, cp.total_products_purchased
HAVING 
    COUNT(DISTINCT e.Prod_ID) = 2;


-- Quantity Ratio 2

WITH t1 AS(SELECT DISTINCT
                Ord_ID,Cust_ID,Prod_ID,Order_Quantity,
                SUM(Order_Quantity) over(PARTITION by Cust_ID) Prod_11_14_Quantity
           FROM ECommerce
           WHERE Cust_ID = any(SELECT DISTINCT Cust_ID
                                FROM ECommerce
                                WHERE Prod_ID = 'Prod_14'
                                INTERSECT
                                SELECT distinct Cust_ID
                                FROM ECommerce
                                WHERE Prod_ID = 'Prod_11')
                AND Prod_ID IN ('Prod_11','Prod_14')
),
t2 AS(SELECT DISTINCT
            Ord_ID,Cust_ID,Prod_ID,Order_Quantity,
            SUM(Order_Quantity) OVER(PARTITION BY Cust_ID) Total_Quantity
      FROM ECommerce
      WHERE Cust_ID = any(SELECT DISTINCT Cust_ID
                            FROM ECommerce
                            WHERE Prod_ID = 'Prod_14'
                            INTERSECT
                            SELECT distinct Cust_ID
                            FROM ECommerce
                            WHERE Prod_ID = 'Prod_11'))
SELECT DISTINCT a.Cust_ID, a.Prod_11_14_Quantity, b.Total_Quantity,
                cast(a.Prod_11_14_Quantity*1.0/b.Total_Quantity AS NUMERIC(3,2)) Products_Ratio
        FROM t1 a
        JOIN t2 b  ON a.Cust_ID=b.Cust_ID


/*

Customer Segmentation
Categorize customers based on their frequency of visits. The following steps
will guide you. If you want, you can track your own way.

*/

-- 1. Create a “view” that keeps visit logs of customers on a monthly basis. (For
-- each log, three field is kept: Cust_id, Year, Month)


--CREATE VIEW MonthlyVisitLogs AS
SELECT 
    Cust_ID,
    YEAR(Order_Date) AS Year,
    MONTH(Order_Date) AS Month
FROM 
    ECommerce;



-- 2. Create a “view” that keeps the number of monthly visits by users. (Show
-- separately all months from the beginning business)


-- CREATE VIEW MonthlyVisitCounts AS
SELECT 
    Cust_ID,
    YEAR(Order_Date) AS Year,
    MONTH(Order_Date) AS Month,
    COUNT(*) AS Visit_Count
FROM 
    ECommerce
GROUP BY 
    Cust_ID,
    YEAR(Order_Date),
    MONTH(Order_Date);



--- 3. For each visit of customers, create the previous or next month of the visit 
-- as a separate column.


-- CREATE VIEW VisitWithAdjacentMonths AS
WITH VisitInfo AS (
    SELECT 
        Cust_ID,
        Order_Date,
        YEAR(Order_Date) AS Year,
        MONTH(Order_Date) AS Month
    FROM 
        ECommerce
)
SELECT 
    Cust_ID,
    Order_Date,
    Year,
    Month,
    LAG(Month) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Previous_Month,
    LEAD(Month) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Next_Month
FROM 
    VisitInfo;


SELECT * from VisitWithAdjacentMonths 



-- 4. Calculate the monthly time gap between two consecutive visits by each
-- customer.


WITH ConsecutiveVisits AS (
    SELECT 
        Cust_ID,
        MIN(DATEFROMPARTS(Year, Month, 1)) AS Visit_Date,
        LEAD(MIN(DATEFROMPARTS(Year, Month, 1))) OVER (PARTITION BY Cust_ID ORDER BY MIN(DATEFROMPARTS(Year, Month, 1))) AS Next_Visit_Date
    FROM 
        MonthlyVisitLogs
    GROUP BY 
        Cust_ID, Year, Month
)
SELECT 
    Cust_ID,
    Visit_Date,
    Next_Visit_Date,
    DATEDIFF(MONTH, Visit_Date, Next_Visit_Date) AS Monthly_Time_Gap
FROM 
    ConsecutiveVisits
WHERE 
    Next_Visit_Date IS NOT NULL;

    

/* 5. Categorise customers using average time gaps. Choose the most fitted
labeling model for you.
For example:
o Labeled as churn if the customer hasn't made another purchase in the
months since they made their first purchase.
o Labeled as regular if the customer has made a purchase every month.
Etc. */


WITH CustomerTimeGaps AS (
    SELECT 
        Cust_ID,
        Visit_Date,
        Next_Visit_Date,
        DATEDIFF(MONTH, Visit_Date, Next_Visit_Date) AS Monthly_Time_Gap
    FROM (
        SELECT 
            Cust_ID,
            MIN(DATEFROMPARTS(Year, Month, 1)) AS Visit_Date,
            LEAD(MIN(DATEFROMPARTS(Year, Month, 1))) OVER (PARTITION BY Cust_ID ORDER BY MIN(DATEFROMPARTS(Year, Month, 1))) AS Next_Visit_Date
        FROM 
            MonthlyVisitLogs
        GROUP BY 
            Cust_ID, Year, Month
    ) ConsecutiveVisits
    WHERE 
        Next_Visit_Date IS NOT NULL
)
SELECT 
    Cust_ID,
    CASE 
        WHEN AVG(Monthly_Time_Gap) <= 1 THEN 'Regular'
        WHEN AVG(Monthly_Time_Gap) <= 3 THEN 'Irregular'
        ELSE 'Churn'
    END AS Customer_Category
FROM 
    CustomerTimeGaps
GROUP BY 
    Cust_ID;



/*
Month-Wise Retention Rate

Find month-by-month customer retention ratei since the start of the business.
There are many different variations in the calculation of Retention Rate. But we will
try to calculate the month-wise retention rate in this project.
So, we will be interested in how many of the customers in the previous month could
be retained in the next month.

Proceed step by step by creating “views”. You can use the view you got at the end of
the Customer Segmentation section as a source.

1. Find the number of customers retained month-wise. (You can use time gaps)
2. Calculate the month-wise retention rate.
Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total
Number of Customers in the Previous Month
*/


-- 1. Find the number of customers retained month-wise. (You can use time gaps)


WITH PreviousMonthCustomers AS (
    SELECT 
        Cust_ID,
        Year,
        Month
    FROM 
        MonthlyVisitLogs
),
CurrentMonthCustomers AS (
    SELECT 
        Cust_ID,
        Year,
        Month
    FROM 
        MonthlyVisitLogs
)
SELECT 
    COUNT(DISTINCT cm.Cust_ID) AS Retained_Customers,
    cm.Year AS Current_Year,
    cm.Month AS Current_Month
FROM 
    CurrentMonthCustomers cm
JOIN 
    PreviousMonthCustomers pm ON cm.Cust_ID = pm.Cust_ID
WHERE 
    DATEADD(MONTH, 1, DATEFROMPARTS(pm.Year, pm.Month, 1)) = DATEFROMPARTS(cm.Year, cm.Month, 1)
GROUP BY 
    cm.Year,
    cm.Month
ORDER BY
    Current_Year


--

WITH MonthlyVisitLogs AS (
    SELECT 
        Cust_ID,
        YEAR(Order_Date) AS Year,
        MONTH(Order_Date) AS Month
    FROM 
        ECommerce
),
Cust_Month AS (
    SELECT 
        Cust_ID,   
        CONCAT(Year, '-', 
              CASE WHEN LEN(Month) = 1 THEN CONCAT('0', Month) ELSE CAST(Month AS VARCHAR(2)) END
             ) AS month,
        DATEDIFF(MONTH, LAG(DATEFROMPARTS(Year, Month, 1)) OVER (PARTITION BY Cust_ID ORDER BY Year, Month), DATEFROMPARTS(Year, Month, 1)) AS TotalMonthDifference
    FROM 
        MonthlyVisitLogs
)
SELECT  
    month,
    COUNT(CASE WHEN TotalMonthDifference = 1 THEN Cust_ID END) AS RetentionCounts
FROM    
    Cust_Month
GROUP BY 
    month
ORDER BY 
    month;



-- 2. Calculate the month-wise retention rate.
-- Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total Number of Customers in the Previous Month


WITH MonthlyVisitLogs AS (
    SELECT 
        Cust_ID,
        YEAR(Order_Date) AS Year,
        MONTH(Order_Date) AS Month
    FROM 
        ECommerce
),
Cust_Month AS (
    SELECT 
        Cust_ID,   
        CONCAT(Year, '-', 
              CASE WHEN LEN(Month) = 1 THEN CONCAT('0', Month) ELSE CAST(Month AS VARCHAR(2)) END
             ) AS month,
        DATEDIFF(MONTH, LAG(DATEFROMPARTS(Year, Month, 1)) OVER (PARTITION BY Cust_ID ORDER BY Year, Month), DATEFROMPARTS(Year, Month, 1)) AS TotalMonthDifference
    FROM 
        MonthlyVisitLogs
)
SELECT  
    month,
    COUNT(CASE WHEN TotalMonthDifference = 1 THEN Cust_ID END) AS RetainedCustomers,
    LAG(COUNT(Cust_ID)) OVER (ORDER BY month) AS TotalCustomersPreviousMonth,
    CASE
        WHEN LAG(COUNT(Cust_ID)) OVER (ORDER BY month) = 0 THEN 0
        ELSE 1.0 * COUNT(CASE WHEN TotalMonthDifference = 1 THEN Cust_ID END) / LAG(COUNT(Cust_ID)) OVER (ORDER BY month)
    END AS RetentionRate
FROM    
    Cust_Month
GROUP BY 
    month
ORDER BY 
    month;









