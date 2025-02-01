1. What is the count of purchases per month (excluding refunded purchases)?

SELECT DATE_FORMAT(purchase_time, '%Y-%m') AS month, COUNT(*) AS total_purchases
FROM transactions
WHERE refund_time IS NULL
GROUP BY month
ORDER BY month;

2. How many stores receive at least 5 orders/transactions in October 2020?

SELECT store_id
FROM transactions
WHERE YEAR(purchase_time) = 2020 AND MONTH(purchase_time) = 10
GROUP BY store_id
HAVING COUNT(transaction_id) >= 5;

3. For each store, what is the shortest interval (in min) from purchase to refund time?

SELECT store_id, MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_time)) AS min_refund_time
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id;

4. What is the gross_transaction_value of every store’s first order?

WITH first_orders AS (
    SELECT store_id, MIN(purchase_time) AS first_order_time
    FROM transactions
    GROUP BY store_id
)
SELECT t.store_id, t.gross_transaction_value
FROM transactions t
JOIN first_orders fo
ON t.store_id = fo.store_id 
AND t.purchase_time = fo.first_order_time;

5. What is the most popular item name that buyers order on their first purchase?

WITH first_purchases AS (
    SELECT buyer_id, MIN(purchase_time) AS first_purchase_time
    FROM transactions
    GROUP BY buyer_id
)
SELECT i.item_name, COUNT(*) AS order_count
FROM items i
JOIN transactions t ON i.transaction_id = t.transaction_id
JOIN first_purchases fp ON t.buyer_id = fp.buyer_id
AND t.purchase_time = fp.first_purchase_time
GROUP BY i.item_name
ORDER BY order_count DESC
LIMIT 1;

6. Create a flag in the transaction items table indicating whether the refund can be processed or
not. The condition for a refund to be processed is that it has to happen within 72 of Purchase
time.
Expected Output: Only 1 of the three refunds would be processed in this case

SELECT transaction_id,
  CASE 
   WHEN refund_time IS NOT NULL 
   AND TIMESTAMPDIFF(HOUR, purchase_time, refund_time) <= 72 
   THEN 'Eligible' 
   ELSE 'Not Eligible' 
   END AS refund_flag
FROM transactions;

7. Create a rank by buyer_id column in the transaction items table and filter for only the second
purchase per buyer. (Ignore refunds here)
Expected Output: Only the second purchase of buyer_id 3 should the output

WITH ranked_transactions AS (
    SELECT transaction_id, buyer_id, purchase_time, 
	RANK() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS purchase_rank
    FROM transactions
    WHERE refund_time IS NULL
)
SELECT transaction_id, buyer_id, purchase_time
FROM ranked_transactions
WHERE purchase_rank = 2;


8. How will you find the second transaction time per buyer (don’t use min/max; assume there
were more transactions per buyer in the table)
Expected Output: Only the second purchase of buyer_id along with a timestamp

WITH ordered_transactions AS (
    SELECT transaction_id, buyer_id, purchase_time,
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS row_num
    FROM transactions
)
SELECT transaction_id, buyer_id, purchase_time
FROM ordered_transactions
WHERE row_num = 2;
