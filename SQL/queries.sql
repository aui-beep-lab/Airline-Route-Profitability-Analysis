-- ============================================================
-- Airline Route Profitability - SQL Analysis
-- Database: SQLite (airline.db, table: flights)
-- ============================================================


-- ============================================================
-- SECTION 1: DATA OVERVIEW
-- ============================================================

-- 1.1 Row count, date range, number of distinct routes and aircraft types
SELECT
    COUNT(*)                    AS total_flights,
    MIN(Flight_Date)            AS first_date,
    MAX(Flight_Date)            AS last_date,
    COUNT(DISTINCT Route)       AS distinct_routes,
    COUNT(DISTINCT Aircraft_Type) AS distinct_aircraft_types
FROM flights;

-- 1.2 Flights and revenue by season
SELECT
    Season,
    COUNT(*)                        AS flights,
    ROUND(SUM(Total_Revenue), 2)    AS total_revenue,
    ROUND(AVG(Load_Factor), 3)      AS avg_load_factor
FROM flights
GROUP BY Season
ORDER BY total_revenue DESC;


-- ============================================================
-- SECTION 2: ROUTE PROFITABILITY
-- ============================================================

-- 2.1 Route level summary: revenue, cost, profit, margin
SELECT
    Route,
    Route_Category,
    COUNT(*)                              AS flights,
    ROUND(AVG(Load_Factor), 3)            AS avg_load_factor,
    ROUND(SUM(Total_Revenue), 2)          AS total_revenue,
    ROUND(SUM(Total_Cost), 2)             AS total_cost,
    ROUND(SUM(Profit), 2)                 AS total_profit,
    ROUND(AVG(Profit_Margin), 2)          AS avg_profit_margin
FROM flights
GROUP BY Route, Route_Category
ORDER BY total_profit DESC;

-- 2.2 Routes that lose money overall, worst first
SELECT
    Route,
    COUNT(*)                     AS flights,
    ROUND(SUM(Profit), 2)        AS total_profit,
    ROUND(AVG(Profit_Margin), 2) AS avg_profit_margin
FROM flights
GROUP BY Route
HAVING SUM(Profit) < 0
ORDER BY total_profit ASC;

-- 2.3 Rank routes by total profit within each route category
-- Demonstrates window function partitioned by category
WITH route_totals AS (
    SELECT
        Route,
        Route_Category,
        SUM(Profit) AS total_profit
    FROM flights
    GROUP BY Route, Route_Category
)
SELECT
    Route,
    Route_Category,
    ROUND(total_profit, 2) AS total_profit,
    RANK() OVER (
        PARTITION BY Route_Category
        ORDER BY total_profit DESC
    ) AS rank_in_category
FROM route_totals
ORDER BY Route_Category, rank_in_category;

-- 2.4 Each route's profit compared to the overall average
-- Correlated subquery in the SELECT list
SELECT
    Route,
    ROUND(SUM(Profit), 2) AS route_profit,
    ROUND(
        SUM(Profit) - (SELECT SUM(Profit) FROM flights) / COUNT(DISTINCT Route)
    , 2) AS diff_from_avg_route_profit
FROM flights
GROUP BY Route
ORDER BY route_profit DESC;


-- ============================================================
-- SECTION 3: SEASONALITY AND TIME TRENDS
-- ============================================================

-- 3.1 Monthly revenue, cost and profit
SELECT
    strftime('%Y-%m', Flight_Date) AS year_month,
    ROUND(SUM(Total_Revenue), 2)   AS revenue,
    ROUND(SUM(Total_Cost), 2)      AS cost,
    ROUND(SUM(Profit), 2)          AS profit
FROM flights
GROUP BY year_month
ORDER BY year_month;

-- 3.2 Month over month profit change using LAG()
WITH monthly AS (
    SELECT
        strftime('%Y-%m', Flight_Date) AS year_month,
        SUM(Profit) AS profit
    FROM flights
    GROUP BY year_month
)
SELECT
    year_month,
    ROUND(profit, 2)                                   AS profit,
    ROUND(profit - LAG(profit) OVER (ORDER BY year_month), 2) AS profit_change_vs_prev_month,
    ROUND(
        100.0 * (profit - LAG(profit) OVER (ORDER BY year_month))
        / NULLIF(LAG(profit) OVER (ORDER BY year_month), 0)
    , 2) AS profit_pct_change
FROM monthly
ORDER BY year_month;

-- 3.3 Three month rolling average profit
WITH monthly AS (
    SELECT
        strftime('%Y-%m', Flight_Date) AS year_month,
        SUM(Profit) AS profit
    FROM flights
    GROUP BY year_month
)
SELECT
    year_month,
    ROUND(profit, 2) AS profit,
    ROUND(
        AVG(profit) OVER (
            ORDER BY year_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )
    , 2) AS rolling_3month_avg_profit
FROM monthly
ORDER BY year_month;

-- 3.4 Profit margin by season, ranked
SELECT
    Season,
    ROUND(AVG(Profit_Margin), 2) AS avg_profit_margin,
    RANK() OVER (ORDER BY AVG(Profit_Margin) DESC) AS margin_rank
FROM flights
GROUP BY Season;


-- ============================================================
-- SECTION 4: FLEET AND AIRCRAFT PERFORMANCE
-- ============================================================

-- 4.1 Aircraft level summary with unit economics (RASK / CASK proxy)
SELECT
    Aircraft_Type,
    COUNT(*)                            AS flights,
    ROUND(AVG(Load_Factor), 3)          AS avg_load_factor,
    ROUND(AVG(Profit_Margin), 2)        AS avg_profit_margin,
    ROUND(SUM(Total_Revenue) / SUM(Aircraft_Capacity * Flight_Hours), 2) AS rask,
    ROUND(SUM(Total_Cost) / SUM(Aircraft_Capacity * Flight_Hours), 2)    AS cask
FROM flights
GROUP BY Aircraft_Type
ORDER BY avg_profit_margin DESC;

-- 4.2 Best performing aircraft type per route (highest average margin)
-- Demonstrates window function + filtering to the top row per group
WITH aircraft_route AS (
    SELECT
        Route,
        Aircraft_Type,
        AVG(Profit_Margin) AS avg_margin,
        ROW_NUMBER() OVER (
            PARTITION BY Route
            ORDER BY AVG(Profit_Margin) DESC
        ) AS rn
    FROM flights
    GROUP BY Route, Aircraft_Type
)
SELECT
    Route,
    Aircraft_Type AS best_aircraft,
    ROUND(avg_margin, 2) AS avg_profit_margin
FROM aircraft_route
WHERE rn = 1
ORDER BY avg_profit_margin DESC;


-- ============================================================
-- SECTION 5: DEMAND AND LOAD FACTOR
-- ============================================================

-- 5.1 Load factor buckets and their average profit margin
SELECT
    CASE
        WHEN Load_Factor < 0.60 THEN 'Under 60%'
        WHEN Load_Factor < 0.70 THEN '60-70%'
        WHEN Load_Factor < 0.80 THEN '70-80%'
        WHEN Load_Factor < 0.90 THEN '80-90%'
        ELSE '90% and above'
    END AS load_factor_band,
    COUNT(*)                     AS flights,
    ROUND(AVG(Profit_Margin), 2) AS avg_profit_margin
FROM flights
GROUP BY load_factor_band
ORDER BY MIN(Load_Factor);

-- 5.2 Demand level versus profitability
SELECT
    Demand_Level,
    COUNT(*)                     AS flights,
    ROUND(AVG(Load_Factor), 3)   AS avg_load_factor,
    ROUND(AVG(Profit_Margin), 2) AS avg_profit_margin
FROM flights
GROUP BY Demand_Level
ORDER BY avg_profit_margin DESC;

-- 5.3 Quartile split of routes by average profit margin using NTILE
WITH route_margin AS (
    SELECT
        Route,
        AVG(Profit_Margin) AS avg_margin
    FROM flights
    GROUP BY Route
)
SELECT
    Route,
    ROUND(avg_margin, 2) AS avg_profit_margin,
    NTILE(4) OVER (ORDER BY avg_margin DESC) AS profit_quartile
FROM route_margin
ORDER BY avg_margin DESC;


-- ============================================================
-- SECTION 6: COST STRUCTURE
-- ============================================================

-- 6.1 Average cost breakdown per flight, grouped into direct, service, indirect
SELECT
    ROUND(AVG(Fuel_Cost + Maintenance_Cost + Crew_Cost + Depreciation_Cost + Insurance_Cost), 2) AS avg_direct_op_cost,
    ROUND(AVG(Airport_Fees + Catering_Cost + Handling_Cost + Navigation_Fees), 2)                AS avg_service_cost,
    ROUND(AVG(Sales_Distribution_Cost + Passenger_Service_Cost + Overhead_Cost + Marketing_Cost + IT_Systems_Cost), 2) AS avg_indirect_cost
FROM flights;

-- 6.2 Routes where fuel cost eats the largest share of total cost
SELECT
    Route,
    ROUND(AVG(Fuel_Cost), 2)                       AS avg_fuel_cost,
    ROUND(AVG(Total_Cost), 2)                      AS avg_total_cost,
    ROUND(100.0 * AVG(Fuel_Cost) / AVG(Total_Cost), 2) AS fuel_pct_of_cost
FROM flights
GROUP BY Route
ORDER BY fuel_pct_of_cost DESC
LIMIT 10;


-- ============================================================
-- SECTION 7: REUSABLE VIEWS
-- ============================================================

-- 7.1 A view summarizing every route, ready to query directly
DROP VIEW IF EXISTS route_summary;
CREATE VIEW route_summary AS
SELECT
    Route,
    Route_Category,
    Demand_Level,
    COUNT(*)                     AS flights,
    ROUND(AVG(Load_Factor), 3)   AS avg_load_factor,
    ROUND(SUM(Total_Revenue), 2) AS total_revenue,
    ROUND(SUM(Total_Cost), 2)    AS total_cost,
    ROUND(SUM(Profit), 2)        AS total_profit,
    ROUND(AVG(Profit_Margin), 2) AS avg_profit_margin
FROM flights
GROUP BY Route, Route_Category, Demand_Level;

-- Example use of the view
SELECT * FROM route_summary ORDER BY total_profit DESC LIMIT 5;

-- 7.2 A view classifying each route into a BCG style tier
DROP VIEW IF EXISTS route_segments;
CREATE VIEW route_segments AS
SELECT
    Route,
    avg_load_factor,
    avg_profit_margin,
    CASE
        WHEN avg_profit_margin >= (SELECT AVG(avg_profit_margin) FROM route_summary)
             AND avg_load_factor >= (SELECT AVG(avg_load_factor) FROM route_summary)
            THEN 'Star'
        WHEN avg_profit_margin >= (SELECT AVG(avg_profit_margin) FROM route_summary)
             AND avg_load_factor < (SELECT AVG(avg_load_factor) FROM route_summary)
            THEN 'Cash Cow'
        WHEN avg_profit_margin < (SELECT AVG(avg_profit_margin) FROM route_summary)
             AND avg_load_factor >= (SELECT AVG(avg_load_factor) FROM route_summary)
            THEN 'Question Mark'
        ELSE 'Underperformer'
    END AS segment
FROM route_summary;

-- Example use of the segmentation view
SELECT segment, COUNT(*) AS routes
FROM route_segments
GROUP BY segment
ORDER BY routes DESC;
