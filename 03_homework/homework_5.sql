-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
SELECT *, 
	CASE 
		WHEN hyphen_position > 0
			THEN rtrim(ltrim(substr(product_name, hyphen_position+2)))
			ELSE NULL
		END AS product_description
FROM (
	SELECT *, instr(product_name, '-') AS hyphen_position
	FROM product
	);

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
SELECT *
FROM product
WHERE product_size REGEXP '\d';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
DROP TABLE IF EXISTS temp.daily_sales;
CREATE TEMP TABLE temp.daily_sales AS
	SELECT market_date, sum(quantity * cost_to_customer_per_qty)
		AS total_sales
	FROM customer_purchases
	GROUP BY market_date ORDER BY market_date;
SELECT market_date, max(total_sales) AS max_and_min_daily_sales
FROM temp.daily_sales
UNION
SELECT market_date, min(total_sales)
FROM temp.daily_sales;

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
SELECT vendor_name, product_name, SUM(original_price*5) AS purchase_amount
FROM (
	SELECT DISTINCT v.vendor_name, p.product_name, vi.original_price
	FROM vendor_inventory vi
	LEFT JOIN vendor v ON vi.vendor_id = v.vendor_id
	LEFT JOIN product p ON vi.product_id = p.product_id
	) x
CROSS JOIN customer
GROUP BY vendor_name, product_name;

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
DROP TABLE IF EXISTS product_units;
CREATE TABLE product_units AS
	SELECT *, CURRENT_TIMESTAMP AS snapshot_timestamp
	FROM product
	WHERE product_qty_type = 'unit';

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
INSERT INTO product_units VALUES (
	24, 'Apple Pie', '6"', 3, 'unit', CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
DELETE FROM product_units
WHERE product_id = 7;

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */
ALTER TABLE product_units
ADD current_quantity INT;

UPDATE product_units 
	SET current_quantity = y.last_quantity
	FROM (
		SELECT pu.product_id, coalesce(x.quantity, 0) AS last_quantity, x.last_date
		FROM product_units pu
		LEFT JOIN (
			SELECT product_id, quantity, max(market_date) AS last_date
			FROM vendor_inventory
			GROUP BY vendor_id, product_id 
			) x ON pu.product_id = x.product_id
	) y
	WHERE product_units.product_id = y.product_id;

