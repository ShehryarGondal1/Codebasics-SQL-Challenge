/* 1. Provide the list of markets in which customer "Atliq Exclusive" 
operates its business in the APAC region. */

SELECT customer,Market,region FROM dim_customer where customer = "Atliq Exclusive" and region = "APAC" ORDER BY market DESC;

/* Query-1-Explaination : This SQL query retrieves the customer name, market, and region from the "dim_customer" table
 where the customer name is "Atliq Exclusive" and the region is "APAC". The results are then ordered 
 in descending order based on the market.
 and region from the "dim_customer" table where the customer name is "Atliq Exclusive" and
 the region is "APAC". The results are then ordered in descending order based on the market. */
 
/* ------------------------------------End of Query 1--------------------------------------------------------- */

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

WITH unique_product_2020 AS
  (SELECT COUNT(DISTINCT product_code) AS unique_products_2020
   FROM fact_sales_monthly
   WHERE fiscal_year = 2020),
     unique_product_2021 AS
  (SELECT COUNT(DISTINCT product_code) AS unique_products_2021
   FROM fact_sales_monthly
   WHERE fiscal_year = 2021)
SELECT unique_products_2020,
       unique_products_2021,
       concat(ROUND((unique_products_2021 - unique_products_2020) / unique_products_2020 * 100, 2), '%') AS percentage_chg
FROM unique_product_2020
INNER JOIN unique_product_2021;

/* Query-2-Explaination : This SQL query uses two "WITH" clauses to create temporary tables,
 "unique_product_2020" and "unique_product_2021", to store the count of unique products for
 the years 2020 and 2021, respectively. Then, it combines the two tables to show the count 
 of unique products for both years and the percentage change between the two. In simpler terms,
 it gives the number of unique products sold in 2020 and 2021 and calculates the percentage
  change between the two years. */
 
/* ------------------------------------End of Query 2--------------------------------------------------------- */


/* 3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count */

SELECT 
	segment, count(DISTINCT (product_code)) as product_count 
FROM dim_product 
GROUP BY segment 
ORDER BY product_count DESC;

/* Query-3-Explaination : This SQL query retrieves the segment and the count of unique 
product codes from the "dim_product" table. The query groups the results by segment and
 counts the number of distinct product codes for each segment. Finally, the results are 
 ordered in descending order based on the product count */
 
/* ------------------------------------End of Query 3--------------------------------------------------------- */


/* 4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */

WITH cte_table_20 AS
  (SELECT p.segment,
          count(DISTINCT (p.product_code)) AS product_count_2020
   FROM dim_product p
   INNER JOIN fact_sales_monthly s ON p.product_code = s.product_code
   WHERE s.fiscal_year = 2020
   GROUP BY p.segment
   ORDER BY product_count_2020 DESC),
     cte_table_21 AS
  (SELECT p.segment,
          count(DISTINCT (p.product_code)) AS product_count_2021
   FROM dim_product p
   INNER JOIN fact_sales_monthly s ON p.product_code = s.product_code
   WHERE s.fiscal_year = 2021
   GROUP BY p.segment
   ORDER BY product_count_2021 DESC)
SELECT cte_table_20.segment,
       product_count_2020,
       product_count_2021,
       product_count_2021-product_count_2020 AS difference
FROM cte_table_20
INNER JOIN cte_table_21 ON cte_table_20.segment = cte_table_21.segment
ORDER BY difference DESC;

/* Query-4-Explaination : This SQL query calculates the count of unique product codes
 for each segment in two different years, 2020 and 2021. It uses two Common Table Expressions
 (CTEs), cte_20 and cte_21, to perform the calculation for each year.
The cte_20 calculates the count of unique product codes for each segment in 2020 and orders
 the results in descending order based on the product count. The cte_21 calculates the count
 of unique product codes for each segment in 2021 and orders the results in descending order
 based on the product count.
Finally, the query joins the results of the two CTEs based on the segment,
 and calculates the difference between the product counts in 2021 and 2020.
 The final results are ordered in descending order based on the difference 
 between the product counts. */
 
/* ------------------------------------End of Query 4--------------------------------------------------------- */

/* 5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */

SELECT Highest AS Cost,
       p.product_code,
       p.product,
       round(MAX(m.manufacturing_cost), 2) AS manufacturing_cost
FROM fact_manufacturing_cost m
INNER JOIN dim_product p ON m.product_code = p.product_code
WHERE m.manufacturing_cost =
    (SELECT MAX(manufacturing_cost)
     FROM fact_manufacturing_cost)
UNION
SELECT Lowest AS Cost,
       p.product_code,
       p.product,
       round(MIN(m.manufacturing_cost), 2) AS manufacturing_cost
FROM fact_manufacturing_cost m
INNER JOIN dim_product p ON m.product_code = p.product_code
WHERE m.manufacturing_cost =
    (SELECT MIN(manufacturing_cost)
     FROM fact_manufacturing_cost);

/* Query-5-Explaination : This SQL query retrieves two rows of information: the product with the highest manufacturing 
cost and the product with the lowest manufacturing cost. The query uses two UNION statements to retrieve 
this information. The first UNION statement retrieves the product with the highest manufacturing cost by
 joining the "fact_manufacturing_cost" and "dim_product" tables, filtering for the highest manufacturing
 cost value, and rounding the manufacturing cost to 2 decimal places. The second UNION statement retrieves
 the product with the lowest manufacturing cost by using the same process, 
but filtering for the lowest manufacturing cost value instead. The final result is ordered by "Cost" */
 
/* ------------------------------------End of Query 5--------------------------------------------------------- */


/* 6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage */

WITH top_5_customers AS
  (SELECT c.customer_code,
          c.customer,
          concat(round(avg(d.pre_invoice_discount_pct), 2),'%') AS average_discount_percentage,
          rank() over(
                      ORDER BY avg(d.pre_invoice_discount_pct) DESC) AS rankk
   FROM dim_customer c
   INNER JOIN fact_pre_invoice_deductions d ON c.customer_code = d.customer_code
   WHERE d.fiscal_year = 2021
     AND c.market = 'India'
     AND d.pre_invoice_discount_pct >
       (SELECT avg(pre_invoice_discount_pct)
        FROM fact_pre_invoice_deductions)
   GROUP BY c.customer_code,
            c.customer)
SELECT customer_code,
       customer,
       average_discount_percentage
FROM top_5_customers
WHERE rankk <= 5;

/* Query-6-Explaination : This query gets the top 5 customers with the highest average discount percentage
 in India in the year 2021. It first creates a sub-query called top_5_customers, which calculates the average
 discount percentage for each customer, then ranks the customers based on the average discount percentage
 in descending order. Finally, the query returns the customer code, name, and average discount percentage for the customers with the top 5 ranks. */
 
/* ------------------------------------End of Query 6--------------------------------------------------------- */

/* 7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount */

SELECT month(s.date) Month,
                     year(s.date) AS Year,
                     round(sum(s.sold_quantity * g.gross_price), 2) AS Gross_sales_Amount
FROM fact_gross_price g
INNER JOIN fact_sales_monthly s ON g.product_code = s.product_code
INNER JOIN dim_customer c ON c.customer_code = s.customer_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY month(s.date),
         year(s.date)
ORDER BY month(s.date),
         year(s.date);

/* Query-7-Explaination : This SQL query retrieves a report of the gross sales amount for the customer "Atliq Exclusive" 
for each month. It gets the month and year from the "fact_sales_monthly" table and calculates the sum of the sold quantity
 multiplied by the gross price from the "fact_gross_price" table. The results are grouped by the month and year and ordered 
 by the month and year. The report has three columns: Month, Year, and Gross sales Amount. */
 
/* ------------------------------------End of Query 7--------------------------------------------------------- */
         
/* 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
hint : derive the Month from the date and assign a Quarter. Note that fiscal_year
for Atliq Hardware starts from September(09)
 */

SELECT CASE
           WHEN monthname(date) in ('September','October','November') THEN 1
           WHEN monthname(date) in ('December','January','February') THEN 2
           WHEN monthname(date) in ('March','April','May') THEN 3
           WHEN monthname(date) in ('June','July','August') THEN 4
       END AS Quarter,
       sum(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020 
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;

/* Query-8-Explaination : This SQL query gets the total sold quantity of items grouped by quarter in a fiscal year 2020.
 The quarters are divided based on the months of the year, such as September to November, December to February,
 March to May, and June to August. The result will show the quarter and its total sold quantity in descending 
 order based on the total sold quantity. */
 
/* ------------------------------------End of Query 8--------------------------------------------------------- */

/* 9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage */

SELECT c.channel,
       round(sum(p.gross_price*s.sold_quantity), 2) AS gross_sales_mln,
       concat(round(sum(p.gross_price*s.sold_quantity)/2628033151.53*100, 2), '%') AS percentage
FROM fact_sales_monthly s
INNER JOIN fact_gross_price p ON s.product_code = p.product_code
INNER JOIN dim_customer c ON c.customer_code = s.customer_code
WHERE s.fiscal_year = 2021
GROUP BY c.channel
UNION
SELECT Total,
       round(sum(p.gross_price*s.sold_quantity), 2) AS total_gross_sales_mln,
       concat(round(sum(p.gross_price*s.sold_quantity)/sum(p.gross_price*s.sold_quantity)*100, 2), '%') AS total_percentage
FROM fact_sales_monthly s
INNER JOIN fact_gross_price p ON s.product_code = p.product_code
INNER JOIN dim_customer c ON c.customer_code = s.customer_code
WHERE s.fiscal_year = 2021;

/* Query-9-Explaination :This SQL query is used to get the gross sales amount for each channel in a specific fiscal year (2021) 
and calculate the percentage of the total gross sales. The query retrieves the data from two tables (fact_sales_monthly and fact_gross_price)
 and joins it with the dim_customer table based on the customer_code. The data is grouped by channel, and the sum of the gross sales amount
 is calculated. The final result shows the gross sales amount in million and the percentage of total gross sales for each channel.
 The query then adds a total row at the end which shows the total gross sales amount in million and the total percentage of the total gross sales. */
 
/* ------------------------------------End of Query 9--------------------------------------------------------- */


/* 10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
division
product_code
product
total_sold_quantity
rank_order
*/

WITH top_3_products AS
  (SELECT p.division,
          p.product_code,
          p.product,
          sum(s.sold_quantity) AS total_sold_quantity,
          DENSE_RANK() OVER(PARTITION BY p.division
                            ORDER BY sum(s.sold_quantity) DESC) AS rank_order
   FROM dim_product p
   INNER JOIN fact_sales_monthly s ON p.product_code = s.product_code
   WHERE s.fiscal_year = 2021
   GROUP BY p.division,
            p.product_code,
            p.product)
SELECT *
FROM top_3_products
WHERE rank_order <= 3;

/* Query-10-Explaination : This SQL query returns a report of the top three selling products in each division 
for a specified fiscal year (2021 in this case). The report is generated by first creating a subquery named 
"top_3_products". In this subquery, we join two tables "dim_product" and "fact_sales_monthly" to get the 
information about the product and its sales quantity. We group the data by division, product code and product
 to get the total sold quantity for each product. We then use the "DENSE_RANK" function to rank the products
 based on their sold quantity within each division, with 1 being the top seller. The final result only shows 
 the rows with a rank_order of 1, 2 or 3 (top 3 sellers).*/
 
/* ------------------------------------End of Query 10--------------------------------------------------------- */