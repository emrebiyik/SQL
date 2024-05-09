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
        Cust_ID,
        order_date,
        ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY order_date) AS order_rank
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



/*

Customer Segmentation
Categorize customers based on their frequency of visits. The following steps
will guide you. If you want, you can track your own way.

*/

-- 1. Create a “view” that keeps visit logs of customers on a monthly basis. (For
-- each log, three field is kept: Cust_id, Year, Month)


-- CREATE VIEW MonthlyVisitLogs AS

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



-- 4. Calculate the monthly time gap between two consecutive visits by each
-- customer.


SELECT 
    V1.Cust_ID,
    V1.Year AS Visit_Year,
    V1.Month AS Visit_Month,
    V2.Year AS Next_Visit_Year,
    V2.Month AS Next_Visit_Month,
    DATEDIFF(MONTH, DATEFROMPARTS(V1.Year, V1.Month, 1), DATEFROMPARTS(V2.Year, V2.Month, 1)) AS Monthly_Time_Gap
FROM 
    MonthlyVisitLogs V1
JOIN 
    MonthlyVisitLogs V2 ON V1.Cust_ID = V2.Cust_ID
                        AND (V1.Year < V2.Year OR (V1.Year = V2.Year AND V1.Month < V2.Month));



/* 5. Categorise customers using average time gaps. Choose the most fitted
labeling model for you.
For example:
o Labeled as churn if the customer hasn't made another purchase in the
months since they made their first purchase.
o Labeled as regular if the customer has made a purchase every month.
Etc. */


WITH CustomerFirstPurchase AS (
    SELECT 
        Cust_ID,
        MIN(Year * 12 + Month) AS First_Purchase_Month
    FROM 
        MonthlyVisitLogs
    GROUP BY 
        Cust_ID
),
CustomerTimeGaps AS (
    SELECT 
        v.Cust_ID,
        AVG(DATEDIFF(MONTH, 
                     DATEFROMPARTS(v.Year, v.Month, 1), 
                     DATEFROMPARTS(v_next.Year, v_next.Month, 1)
                    )) AS Avg_Time_Gap
    FROM 
        MonthlyVisitLogs v
    JOIN 
        MonthlyVisitLogs v_next ON v.Cust_ID = v_next.Cust_ID
                                AND v_next.Year * 12 + v_next.Month > v.Year * 12 + v.Month
    GROUP BY 
        v.Cust_ID
)
SELECT 
    cf.Cust_ID,
    CASE 
        WHEN AVG_Time_Gap IS NULL THEN 'No_Data'  -- No average time gap data available
        WHEN AVG_Time_Gap = 0 THEN 'Regular'     -- Regular customers who purchase every month
        WHEN AVG_Time_Gap >= 6 THEN 'Churned'    -- Churned customers who haven't made another purchase in the last 6 months
        ELSE 'Irregular'                         -- Irregular customers who have varying purchase intervals
    END AS Customer_Label
FROM 
    CustomerFirstPurchase cf
LEFT JOIN 
    CustomerTimeGaps ctg ON cf.Cust_ID = ctg.Cust_ID;


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


-- CREATE VIEW RetainedCustomers AS

SELECT 
    CurrentMonth.Cust_ID,
    CurrentMonth.Year AS Current_Year,
    CurrentMonth.Month AS Current_Month
FROM 
    MonthlyVisitLogs AS CurrentMonth
JOIN 
    MonthlyVisitLogs AS PreviousMonth ON CurrentMonth.Cust_ID = PreviousMonth.Cust_ID
                                      AND (CurrentMonth.Year * 12 + CurrentMonth.Month) 
                                      = (PreviousMonth.Year * 12 + PreviousMonth.Month + 1);



-- 2. Calculate the month-wise retention rate.
-- Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total
-- Number of Customers in the Previous Month

SELECT 
    Current_Year,
    Current_Month,
    COUNT(Retained.Cust_ID) AS Retained_Customers,
    1.0 * COUNT(Retained.Cust_ID) / PreviousMonth.Total_Customers AS Retention_Rate
FROM 
    RetainedCustomers AS Retained
JOIN 
    (SELECT 
         Year AS Prev_Year,
         Month AS Prev_Month,
         COUNT(DISTINCT Cust_ID) AS Total_Customers
     FROM 
         MonthlyVisitLogs
     GROUP BY 
         Year, Month) AS PreviousMonth ON Retained.Current_Year = PreviousMonth.Prev_Year
                                        AND Retained.Current_Month - 1 = PreviousMonth.Prev_Month
GROUP BY 
    Current_Year, Current_Month, PreviousMonth.Total_Customers
ORDER BY 
    Current_Year, Current_Month;







