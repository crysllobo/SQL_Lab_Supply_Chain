use supply_db ;

/*  Question: Month-wise NIKE sales

	Description:
		Find the combined month-wise sales and quantities sold for all the Nike products. 
        The months should be formatted as ‘YYYY-MM’ (for example, ‘2019-01’ for January 2019). 
        Sort the output based on the month column (from the oldest to newest). The output should have following columns :
			-Month
			-Quantities_sold
			-Sales
		HINT:
			Use orders, ordered_items, and product_info tables from the Supply chain dataset.
*/		

SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
    SUM(Quantity) AS Quantities_Sold,
    SUM(Sales) AS Sales
FROM
    orders AS ord
        LEFT JOIN
    ordered_items AS ord_itm ON ord.Order_Id = ord_itm.Order_Id
        LEFT JOIN
    product_info AS prod_info ON ord_itm.Item_Id = prod_info.Product_Id
WHERE
    Product_Name LIKE '%nike%'
GROUP BY Month
ORDER BY Month;

-- **********************************************************************************************************************************
/*

Question : Costliest products

Description: What are the top five costliest products in the catalogue? Provide the following information/details:
-Product_Id
-Product_Name
-Category_Name
-Department_Name
-Product_Price

Sort the result in the descending order of the Product_Price.

HINT:
Use product_info, category, and department tables from the Supply chain dataset.


*/

SELECT 
    prod_info.Product_Id,
    prod_info.Product_Name,
    cat.Name AS Category_Name,
    dept.Name AS Department_Name,
    prod_info.Product_Price
FROM
    product_info AS prod_info
        LEFT JOIN
    category AS cat ON prod_info.Category_Id = cat.Id
        LEFT JOIN
    department AS dept ON prod_info.Department_Id = dept.Id
ORDER BY prod_info.Product_Price DESC
LIMIT 5;

-- **********************************************************************************************************************************

/*

Question : Cash customers

Description: Identify the top 10 most ordered items based on sales from all the ‘CASH’ type orders. 
Provide the Product Name, Sales, and Distinct Order count for these items. Sort the table in descending
 order of Order counts and for the cases where the order count is the same, sort based on sales (highest to
 lowest) within that group.
 
HINT: Use orders, ordered_items, and product_info tables from the Supply chain dataset.


*/

SELECT 
    prod_info.Product_Name,
    sum(Sales) AS Sales,
    COUNT(DISTINCT ord_itm.Order_Id) AS 'Distinct_Order_Count'
FROM
    product_info prod_info
        JOIN
    ordered_items ord_itm ON prod_info.Product_Id = ord_itm.Item_Id
        JOIN
    orders ord ON ord.Order_Id = ord_itm.Order_Id
WHERE
    ord.Type = 'Cash'
GROUP BY Product_Name
ORDER BY Distinct_Order_Count DESC
LIMIT 10;

-- **********************************************************************************************************************************
/*
Question : Customers from texas

Obtain all the details from the Orders table (all columns) for customer orders in the state of Texas (TX),
whose street address contains the word ‘Plaza’ but not the word ‘Mountain’. The output should be sorted by the Order_Id.

HINT: Use orders and customer_info tables from the Supply chain dataset.

*/

SELECT 
    ord.*
FROM
    orders ord
        INNER JOIN
    customer_info cust_info ON ord.Customer_Id = cust_info.id
WHERE
    state = 'TX' AND street LIKE '%Plaza%'
        AND street NOT LIKE '%Mountain%'
ORDER BY order_id;


-- **********************************************************************************************************************************
/*
 
Question: Home office

For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging to
“Apparel” or “Outdoors” departments. Compute the total count of such orders. The final output should contain the 
following columns:
-Order_Count

*/

SELECT 
    COUNT(ord.Order_Id) AS Order_Count
FROM
    orders ord
        INNER JOIN
    customer_info cust_info ON ord.Customer_Id = cust_info.Id
        INNER JOIN
    ordered_items ord_itm USING (Order_Id)
        INNER JOIN
    product_info prod_info ON ord_itm.Item_Id = prod_info.Product_Id
        INNER JOIN
    department dept ON prod_info.Department_Id = dept.Id
WHERE
    Segment = 'Home Office'
        AND (dept.Name = 'Apparel'
        OR dept.Name = 'Outdoors');
        

-- **********************************************************************************************************************************
/*

Question : Within state ranking
 
For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging
to “Apparel” or “Outdoors” departments. Compute the count of orders for all combinations of Order_State and Order_City. 
Rank each Order_City within each Order State based on the descending order of their order count (use dense_rank). 
The states should be ordered alphabetically, and Order_Cities within each state should be ordered based on their rank. 
If there is a clash in the city ranking, in such cases, it must be ordered alphabetically based on the city name. 
The final output should contain the following columns:
-Order_State
-Order_City
-Order_Count
-City_rank

HINT: Use orders, ordered_items, product_info, customer_info, and department tables from the Supply chain dataset.

*/

WITH Count_summary AS
(
SELECT 
    ord.Order_Id, count(ord.Order_Id) as Order_Count
FROM
    orders ord
        INNER JOIN
    customer_info cust_info ON ord.Customer_Id = cust_info.Id
        INNER JOIN
    ordered_items ord_itm ON ord_itm.Order_Id = ord.Order_Id
        INNER JOIN
    product_info prod_info ON ord_itm.Item_Id = prod_info.Product_Id
        INNER JOIN
    department dept ON prod_info.Department_Id = dept.Id
WHERE
    Segment = 'Home Office'
         AND (dept.Name = 'Apparel'
        OR dept.Name = 'Outdoors')
group by ord.Order_City
)
SELECT ord.Order_State, ord.Order_City, ord_cnt.Order_Id,
DENSE_RANK() OVER(PARTITION BY Order_State ORDER BY ord.Order_Id DESC) As City_rank
FROM orders ord 
INNER JOIN Count_summary ord_cnt
ON ord.Order_Id = ord_cnt.Order_Id;

-- **********************************************************************************************************************************
/*
Question : Underestimated orders

Rank (using row_number so that irrespective of the duplicates, so you obtain a unique ranking) the 
shipping mode for each year, based on the number of orders when the shipping days were underestimated 
(i.e., Scheduled_Shipping_Days < Real_Shipping_Days). The shipping mode with the highest orders that meet 
the required criteria should appear first. Consider only ‘COMPLETE’ and ‘CLOSED’ orders and those belonging to 
the customer segment: ‘Consumer’. The final output should contain the following columns:
-Shipping_Mode,
-Shipping_Underestimated_Order_Count,
-Shipping_Mode_Rank

HINT: Use orders and customer_info tables from the Supply chain dataset.


*/

SELECT ord.Shipping_Mode,
		COUNT(Scheduled_Shipping_Days < Real_Shipping_Days) AS Shipping_Underestimated_Order_Count,
		ROW_NUMBER()OVER(PARTITION BY YEAR(Order_Date) ORDER BY COUNT(Scheduled_Shipping_Days < Real_Shipping_Days)DESC) AS Shipping_Mode_Rank
FROM Orders ord
INNER JOIN customer_info cust_info
ON ord.Customer_Id = cust_info.Id
WHERE (Order_Status = 'COMPLETE' OR Order_Status = 'CLOSED') AND Segment = 'Consumer'
GROUP BY Shipping_Mode,YEAR(Order_Date);


-- **********************************************************************************************************************************
