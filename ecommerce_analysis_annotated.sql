-- E-COMMERCE CUSTOMER JOURNEY ANALYSIS
-- Annotated copy of the original SQL; original query logic is preserved.
-- Review warnings are comments only; no SQL logic was corrected or changed.
-- CAUTION: Setup/CREATE/LOAD statements have side effects; do not execute the entire script blindly.


-- =====================================================================
-- SECTION 01 — Environment and database setup
-- =====================================================================

-- QUESTION / OBJECTIVE 01: Is local CSV loading enabled on this MySQL server?
SHOW VARIABLES LIKE 'local_infile';


-- QUESTION / OBJECTIVE 02: Can local file imports be enabled for this session/server?
-- NOTE: This changes a global server setting and may require administrator privileges.
SET GLOBAL local_infile = ON;


-- QUESTION / OBJECTIVE 03: How do we create a dedicated database for this project?
CREATE DATABASE ecommerce_analysis;


-- QUESTION / OBJECTIVE 04: Which database should subsequent statements use?
USE ecommerce_analysis;


-- QUESTION / OBJECTIVE 05: What source-table structure will hold the imported event data?
CREATE TABLE events (
    event_time VARCHAR(50),
    event_type VARCHAR(20),
    product_id BIGINT,
    category_id BIGINT,
    category_code VARCHAR(255),
    brand VARCHAR(255),
    price DECIMAL(10,2),
    user_id BIGINT,
    user_session VARCHAR(255)
);


-- QUESTION / OBJECTIVE 06: Are we working in the correct database?
USE ecommerce_analysis;


-- =====================================================================
-- SECTION 02 — Data import and initial inspection
-- =====================================================================

-- QUESTION / OBJECTIVE 07: How many event records exist before the CSV load?
SELECT COUNT(*)
FROM events;


-- QUESTION / OBJECTIVE 08: How do we load the source CSV into MySQL?
-- NOTE: The source file path is machine-specific; change it before rerunning elsewhere.
LOAD DATA LOCAL INFILE 'C:/Users/Youmna/Downloads/Dataset-Electronics/events.csv'
INTO TABLE events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- QUESTION / OBJECTIVE 09: Do the first ten imported records have the expected columns and values?
SELECT *
FROM events
LIMIT 10;


-- QUESTION / OBJECTIVE 10: What does the full imported event table contain?
-- NOTE: Full-table output may be large; use a LIMIT for routine inspection.
select * from events;


-- =====================================================================
-- SECTION 03 — Raw data quality checks
-- =====================================================================

-- QUESTION / OBJECTIVE 11: How many SQL NULL values occur in each source column?
SELECT
    SUM(CASE WHEN event_time IS NULL THEN 1 ELSE 0 END) AS missing_event_time,
    SUM(CASE WHEN event_type IS NULL THEN 1 ELSE 0 END) AS missing_event_type,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS missing_category_id,
    SUM(CASE WHEN category_code IS NULL THEN 1 ELSE 0 END) AS missing_category_code,
    SUM(CASE WHEN brand IS NULL THEN 1 ELSE 0 END) AS missing_brand,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS missing_user_id,
    SUM(CASE WHEN user_session IS NULL THEN 1 ELSE 0 END) AS missing_user_session
FROM events;


-- QUESTION / OBJECTIVE 12: How many missing values exist when blank text is included?
-- Check missing values: NULLs + blank strings
SELECT
    SUM(CASE WHEN event_time IS NULL OR TRIM(event_time) = '' THEN 1 ELSE 0 END) AS missing_event_time,
    SUM(CASE WHEN event_type IS NULL OR TRIM(event_type) = '' THEN 1 ELSE 0 END) AS missing_event_type,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS missing_category_id,
    SUM(CASE WHEN category_code IS NULL OR TRIM(category_code) = '' THEN 1 ELSE 0 END) AS missing_category_code,
    SUM(CASE WHEN brand IS NULL OR TRIM(brand) = '' THEN 1 ELSE 0 END) AS missing_brand,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS missing_user_id,
    SUM(CASE WHEN user_session IS NULL OR TRIM(user_session) = '' THEN 1 ELSE 0 END) AS missing_user_session
FROM events;


-- QUESTION / OBJECTIVE 13: Which identical source records appear more than once?
-- NOTE: Identical rows are not always accidental duplicates; event identifiers are unavailable here.
SELECT
    event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session,
    COUNT(*) AS duplicate_count
FROM events
GROUP BY
    event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session
HAVING COUNT(*) > 1
LIMIT 20;


-- QUESTION / OBJECTIVE 14: How many duplicate groups and excess duplicate rows exist?
SELECT
    COUNT(*) AS duplicate_groups,
    SUM(duplicate_count - 1) AS excess_duplicate_rows
FROM (
    SELECT
        event_time,
        event_type,
        product_id,
        category_id,
        category_code,
        brand,
        price,
        user_id,
        user_session,
        COUNT(*) AS duplicate_count
    FROM events
    GROUP BY
        event_time,
        event_type,
        product_id,
        category_id,
        category_code,
        brand,
        price,
        user_id,
        user_session
    HAVING COUNT(*) > 1
) AS duplicates;


-- QUESTION / OBJECTIVE 15: Which event types account for the duplicate records?
SELECT
    event_type,
    COUNT(*) AS duplicate_groups,
    SUM(duplicate_count - 1) AS excess_duplicate_rows
FROM (
    SELECT
        event_time,
        event_type,
        product_id,
        category_id,
        category_code,
        brand,
        price,
        user_id,
        user_session,
        COUNT(*) AS duplicate_count
    FROM events
    GROUP BY
        event_time,
        event_type,
        product_id,
        category_id,
        category_code,
        brand,
        price,
        user_id,
        user_session
    HAVING COUNT(*) > 1
) AS duplicates
GROUP BY event_type
ORDER BY excess_duplicate_rows DESC;


-- QUESTION / OBJECTIVE 16: Are there repeated purchase records with identical recorded attributes?
SELECT
    event_time,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session,
    COUNT(*) AS duplicate_count
FROM events
WHERE event_type = 'purchase'
GROUP BY
    event_time,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session
HAVING COUNT(*) > 1;


-- QUESTION / OBJECTIVE 17: How are event types distributed in the raw data?
SELECT
    event_type,
    COUNT(*) AS event_count
FROM events
GROUP BY event_type
ORDER BY event_count DESC;


-- QUESTION / OBJECTIVE 18: Are prices missing, zero, negative, or outside the observed range?
SELECT
    COUNT(*) AS total_events,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_prices,
    SUM(CASE WHEN price = 0 THEN 1 ELSE 0 END) AS zero_prices,
    SUM(CASE WHEN price < 0 THEN 1 ELSE 0 END) AS negative_prices,
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price,
    ROUND(AVG(price), 2) AS average_price
FROM events;


-- =====================================================================
-- SECTION 04 — Timestamp and session investigation
-- =====================================================================

-- QUESTION / OBJECTIVE 19: Can raw UTC timestamp strings be parsed into MySQL datetimes?
-- NOTE: This is a parsing preview, not an update to the raw table.
SELECT
    event_time,
    STR_TO_DATE(
        REPLACE(event_time, ' UTC', ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS event_datetime
FROM events;

-- LIMIT 10

-- QUESTION / OBJECTIVE 21: Do session strings contain hidden trailing characters?
SELECT
    user_session,
    LENGTH(user_session) AS session_length,
    HEX(RIGHT(user_session, 1)) AS last_character
FROM events
LIMIT 10;


-- QUESTION / OBJECTIVE 22: How many sessions are missing after removing carriage returns and whitespace?
SELECT
    SUM(
        CASE
            WHEN user_session IS NULL
                 OR TRIM(REPLACE(user_session, '\r', '')) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_user_sessions
FROM events;


-- =====================================================================
-- SECTION 05 — Cleaning and analysis table creation
-- =====================================================================

-- QUESTION / OBJECTIVE 23: How can timestamps and blank category, brand, and session fields be standardized?
-- NOTE: This creates a new table; rerunning without dropping/renaming it will fail.
CREATE TABLE events_clean AS
SELECT
    STR_TO_DATE(
        REPLACE(event_time, ' UTC', ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS event_datetime,

    event_type,
    product_id,
    category_id,

    NULLIF(TRIM(category_code), '') AS category_code,

    NULLIF(TRIM(brand), '') AS brand,

    price,
    user_id,

    NULLIF(
        TRIM(REPLACE(user_session, '\r', '')),
        ''
    ) AS user_session

FROM events;


-- QUESTION / OBJECTIVE 24: How many rows are present in the cleaned table?
SELECT COUNT(*) AS clean_rows
FROM events_clean;


-- QUESTION / OBJECTIVE 25: What missing fields or invalid dates remain after cleaning?
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN event_datetime IS NULL THEN 1 ELSE 0 END)
        AS invalid_dates,

    SUM(CASE WHEN category_code IS NULL THEN 1 ELSE 0 END)
        AS missing_category_code,

    SUM(CASE WHEN brand IS NULL THEN 1 ELSE 0 END)
        AS missing_brand,

    SUM(CASE WHEN user_session IS NULL THEN 1 ELSE 0 END)
        AS missing_user_session

FROM events_clean;


-- QUESTION / OBJECTIVE 26: How many distinct full records remain when creating the analysis table?
-- REVIEW: SELECT DISTINCT * may remove legitimate repeated events. Validate before treating these as duplicates. Rerunning CREATE TABLE also requires handling an existing table.
CREATE TABLE events_analysis AS
SELECT DISTINCT *
FROM events_clean;


-- =====================================================================
-- SECTION 06 — Dataset coverage and KPIs
-- =====================================================================

-- QUESTION / OBJECTIVE 27: What is the first and last recorded event date?
SELECT
    MIN(event_datetime) AS first_event,
    MAX(event_datetime) AS last_event
FROM events_analysis;


-- QUESTION / OBJECTIVE 28: How many distinct users, products, categories, brands, and sessions appear?
SELECT
    COUNT(DISTINCT user_id) AS unique_customers,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT category_id) AS unique_categories,
    COUNT(DISTINCT brand) AS unique_brands,
    COUNT(DISTINCT user_session) AS unique_sessions
FROM events_analysis;


-- QUESTION / OBJECTIVE 29: How many purchase events and purchasing users exist, and what is their recorded value?
SELECT
    COUNT(*) AS purchase_events,
    COUNT(DISTINCT user_id) AS purchasing_customers,
    ROUND(SUM(price), 2) AS total_purchase_revenue,
    ROUND(AVG(price), 2) AS avg_purchase_event_value
FROM events_analysis
WHERE event_type = 'purchase';


-- =====================================================================
-- SECTION 07 — Event and session behavior
-- =====================================================================

-- QUESTION / OBJECTIVE 30: How are event types distributed in the analysis table?
SELECT
    event_type,
    COUNT(*) AS event_count
FROM events_analysis
GROUP BY event_type
ORDER BY event_count DESC;


-- QUESTION / OBJECTIVE 31: How many distinct sessions contain each event type?
SELECT
    event_type,
    COUNT(DISTINCT user_session) AS unique_sessions
FROM events_analysis
WHERE user_session IS NOT NULL
GROUP BY event_type
ORDER BY unique_sessions DESC;


-- QUESTION / OBJECTIVE 32: How do the counts of view, cart, and purchase sessions compare?
-- REVIEW: These rates compare distinct session populations, not confirmed sequential view → cart → purchase paths. Session overlap and order are not enforced; denominators are not protected against zero.
SELECT
    COUNT(DISTINCT CASE
        WHEN event_type = 'view' THEN user_session
    END) AS view_sessions,

    COUNT(DISTINCT CASE
        WHEN event_type = 'cart' THEN user_session
    END) AS cart_sessions,

    COUNT(DISTINCT CASE
        WHEN event_type = 'purchase' THEN user_session
    END) AS purchase_sessions,

    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_session END)
        * 100.0 /
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_session END),
        2
    ) AS view_to_cart_rate,

    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_session END)
        * 100.0 /
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_session END),
        2
    ) AS cart_to_purchase_rate,

    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_session END)
        * 100.0 /
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_session END),
        2
    ) AS view_to_purchase_rate

FROM events_analysis
WHERE user_session IS NOT NULL;


-- =====================================================================
-- SECTION 08 — Product performance
-- =====================================================================

-- QUESTION / OBJECTIVE 33: Which product-and-brand combinations have the most purchase events?
SELECT
     product_id,brand,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS purchase_revenue
FROM events_analysis
WHERE event_type = 'purchase'
GROUP BY product_id , brand
ORDER BY purchase_events DESC
LIMIT 10;


-- QUESTION / OBJECTIVE 34: Which product IDs have the most purchase events regardless of brand?
SELECT
     product_id,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS purchase_revenue
FROM events_analysis
WHERE event_type = 'purchase'
GROUP BY product_id 
ORDER BY purchase_events DESC
LIMIT 10;


-- QUESTION / OBJECTIVE 35: Which product-and-brand combinations generate the most purchase revenue?
SELECT
    product_id,
    brand,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS purchase_revenue
FROM events_analysis
WHERE event_type = 'purchase'
GROUP BY product_id, brand
ORDER BY purchase_revenue DESC
LIMIT 10;


-- QUESTION / OBJECTIVE 36: How many view and purchase events does each product receive?
SELECT
    product_id,
    SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases
FROM events_analysis
GROUP BY product_id;


-- QUESTION / OBJECTIVE 37: Which product-and-brand combinations receive the most views?
SELECT
    product_id,
    brand,
    SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases
FROM events_analysis
GROUP BY product_id , brand
ORDER BY views DESC
LIMIT 10;


-- QUESTION / OBJECTIVE 38: Which product-and-brand combinations have the highest purchase-event-to-view-event ratios?
-- REVIEW: Event-count ratio, not user/session conversion; values above 100% are possible. Low view counts can distort ranking.
SELECT
    product_id,
    brand,
    SUM(CASE WHEN event_type = 'view'
        THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 'purchase'
        THEN 1 ELSE 0 END) AS purchases,
    ROUND(
        SUM(CASE WHEN event_type = 'purchase'
            THEN 1 ELSE 0 END) * 100.0
        /
        NULLIF(
            SUM(CASE WHEN event_type = 'view'
                THEN 1 ELSE 0 END), 0
        ), 2
    ) AS view_to_purchase_pct
FROM events_analysis
GROUP BY product_id, brand
HAVING views > 0
ORDER BY view_to_purchase_pct DESC
LIMIT 10;


-- =====================================================================
-- SECTION 09 — Daily revenue trends
-- =====================================================================

-- QUESTION / OBJECTIVE 39: How many purchase events and how much revenue are recorded each day?
SELECT
    DATE(event_datetime) AS purchase_date,
    COUNT(*) AS total_purchases,
    ROUND(SUM(price), 2) AS daily_revenue
FROM events_analysis
WHERE event_type = 'purchase'
GROUP BY DATE(event_datetime)
ORDER BY purchase_date ASC;


-- QUESTION / OBJECTIVE 40: How does average purchase-event value vary by day?
SELECT
    DATE(event_datetime) AS purchase_date,
    COUNT(*) AS total_purchases,
    ROUND(SUM(price), 2) AS daily_revenue,
    ROUND(AVG(price), 2) AS avg_purchase_value
FROM events_analysis
WHERE event_type = 'purchase'
GROUP BY DATE(event_datetime)
ORDER BY purchase_date ASC;


-- =====================================================================
-- SECTION 10 — Brand revenue and missingness
-- =====================================================================

-- QUESTION / OBJECTIVE 41: Which brands account for the most recorded purchase revenue?
-- NOTE: NULL brand is an unattributed group, not a real brand.
SELECT
    brand,
    COUNT(*) AS total_purchases,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(AVG(price), 2) AS avg_purchase_value
FROM events_analysis
WHERE event_type = 'purchase'
GROUP BY brand
ORDER BY total_revenue DESC
LIMIT 10;


-- QUESTION / OBJECTIVE 42: How much purchase activity and revenue lack a recorded brand?
SELECT
    COUNT(*) AS total_purchases,
    SUM(CASE WHEN brand IS NULL
        OR TRIM(brand) = ''
        THEN 1 ELSE 0 END) AS missing_brand_purchases,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(SUM(CASE
        WHEN brand IS NULL OR TRIM(brand) = ''
        THEN price ELSE 0 END), 2) AS missing_brand_revenue
FROM events_analysis
WHERE event_type = 'purchase';


-- =====================================================================
-- SECTION 11 — Revenue reconciliation
-- =====================================================================

-- QUESTION / OBJECTIVE 43: Does aggregating revenue by day reproduce the overall purchase revenue total?
-- NOTE: Intermediate daily values are not rounded before summation.
WITH daily_sales AS (
    SELECT
        DATE(event_datetime) AS purchase_date,
        SUM(price) AS daily_revenue
    FROM events_analysis
    WHERE event_type = 'purchase'
    GROUP BY DATE(event_datetime)
)
SELECT
    ROUND(SUM(daily_revenue), 2) AS reconciled_revenue
FROM daily_sales;
