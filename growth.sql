CREATE TABLE online_retail_raw (
  invoice_no      TEXT,
  stock_code      TEXT,
  description     TEXT,
  quantity        INTEGER,
  invoice_date    TIMESTAMP,
  unit_price      NUMERIC,
  customer_id     BIGINT,
  country         TEXT
);

SELECT COUNT(*) FROM online_retail_raw;

SELECT * FROM online_retail_raw LIMIT 5;

CREATE TABLE online_retail_clean AS
SELECT *
FROM online_retail_raw
WHERE customer_id IS NOT NULL
  AND quantity > 0
  AND unit_price > 0
  AND invoice_no NOT LIKE 'C%';


SELECT COUNT(*) FROM online_retail_raw;
SELECT COUNT(*) FROM online_retail_clean;

CREATE TABLE user_summary AS
SELECT
    customer_id,
    MIN(invoice_date) AS first_transaction_date,
    MAX(invoice_date) AS last_transaction_date,
    COUNT(DISTINCT invoice_no) AS total_transactions,
    SUM(quantity * unit_price) AS total_transaction_value,
    COUNT(DISTINCT DATE(invoice_date)) AS active_days
FROM online_retail_clean
GROUP BY customer_id;

SELECT COUNT(*) AS total_users FROM user_summary;

SELECT AVG(total_transactions) FROM user_summary;

SELECT AVG(total_transaction_value) FROM user_summary;

SELECT MIN(first_transaction_date), MAX(first_transaction_date)
FROM user_summary;

--activation
CREATE TABLE user_activation AS
SELECT
    u.customer_id,
    u.first_transaction_date,
    COUNT(DISTINCT o.invoice_no) AS transactions_in_7d,
    CASE 
        WHEN COUNT(DISTINCT o.invoice_no) >= 2 THEN 1
        ELSE 0
    END AS activated
FROM user_summary u
JOIN online_retail_clean o
  ON u.customer_id = o.customer_id
WHERE o.invoice_date 
      BETWEEN u.first_transaction_date 
      AND u.first_transaction_date + INTERVAL '7 days'
GROUP BY u.customer_id, u.first_transaction_date;

SELECT 
    COUNT(*) AS total_users,
    SUM(activated) AS activated_users,
    ROUND(AVG(activated)::numeric, 4) AS activation_rate
FROM user_activation;

SELECT 
    a.activated,
    COUNT(*) AS users,
    ROUND(AVG(u.total_transaction_value), 2) AS avg_total_value,
    ROUND(AVG(u.total_transactions), 2) AS avg_transactions
FROM user_activation a
JOIN user_summary u
  ON a.customer_id = u.customer_id
GROUP BY a.activated;

--retention
CREATE TABLE user_retention AS
SELECT
    u.customer_id,
    u.first_transaction_date,
    MAX(CASE 
        WHEN o.invoice_date >= u.first_transaction_date + INTERVAL '30 days'
        THEN 1 ELSE 0 
    END) AS retained_30d
FROM user_summary u
JOIN online_retail_clean o
  ON u.customer_id = o.customer_id
WHERE u.first_transaction_date <= '2010-11-09'
GROUP BY u.customer_id, u.first_transaction_date;

SELECT 
    a.activated,
    COUNT(*) AS users,
    ROUND(AVG(r.retained_30d)::numeric, 4) AS retention_30d_rate
FROM user_activation a
JOIN user_retention r
  ON a.customer_id = r.customer_id
GROUP BY a.activated;

SELECT 
    ROUND(AVG(total_transaction_value), 2) AS avg_ltv_activated
FROM user_summary u
JOIN user_activation a
  ON u.customer_id = a.customer_id
WHERE a.activated = 1;

SELECT 
    ROUND(AVG(total_transaction_value), 2) AS avg_ltv_non_activated
FROM user_summary u
JOIN user_activation a
  ON u.customer_id = a.customer_id
WHERE a.activated = 0;

SELECT
    u.customer_id,
    a.activated,
    DATE_TRUNC('month', u.first_transaction_date) AS cohort_month,
    DATE_TRUNC('month', o.invoice_date) AS activity_month,
    EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.invoice_date),
                           DATE_TRUNC('month', u.first_transaction_date))) AS month_number
FROM user_summary u
JOIN online_retail_clean o
  ON u.customer_id = o.customer_id
JOIN user_activation a
  ON u.customer_id = a.customer_id;


WITH cohort_data AS (
    SELECT
        u.customer_id,
        a.activated,
        DATE_TRUNC('month', u.first_transaction_date) AS cohort_month,
        DATE_TRUNC('month', o.invoice_date) AS activity_month,
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', o.invoice_date),
            DATE_TRUNC('month', u.first_transaction_date)
        )) AS month_number
    FROM user_summary u
    JOIN online_retail_clean o
      ON u.customer_id = o.customer_id
    JOIN user_activation a
      ON u.customer_id = a.customer_id
),
cohort_sizes AS (
    SELECT
        activated,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM user_activation
    GROUP BY activated
)
SELECT
    c.activated,
    c.month_number,
    COUNT(DISTINCT c.customer_id) AS active_users,
    ROUND(
        COUNT(DISTINCT c.customer_id)::numeric 
        / s.cohort_size, 
        4
    ) AS retention_rate
FROM cohort_data c
JOIN cohort_sizes s
  ON c.activated = s.activated
GROUP BY c.activated, c.month_number, s.cohort_size
ORDER BY c.activated, c.month_number;

WITH cohort_data AS (
    SELECT
        u.customer_id,
        a.activated,
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', o.invoice_date),
            DATE_TRUNC('month', u.first_transaction_date)
        )) AS month_number
    FROM user_summary u
    JOIN online_retail_clean o
      ON u.customer_id = o.customer_id
    JOIN user_activation a
      ON u.customer_id = a.customer_id
)
SELECT 
    activated, 
    month_number, 
    COUNT(DISTINCT customer_id) AS active_users
FROM cohort_data
GROUP BY activated, month_number
ORDER BY activated, month_number;
