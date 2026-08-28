-- ============================================================
-- E-Commerce Customer Funnel & Conversion Analysis
-- Database: MySQL
-- ============================================================

USE customer_funnel_analysis;

-- ============================================================
-- QUERY 01: Executive KPIs
-- ============================================================

SELECT
    COUNT(*) AS total_sessions,

    COUNT(DISTINCT CustomerID) AS unique_customers,

    SUM(IsConverted) AS total_orders,

    SUM(IsReturned) AS total_returns,

    ROUND(
        100.0 * SUM(IsConverted) / COUNT(*),
        2
    ) AS conversion_rate,

    ROUND(
        100.0 * SUM(IsReturned) / SUM(IsConverted),
        2
    ) AS return_rate,

    ROUND(
        SUM(CASE
            WHEN IsConverted = 1 THEN Revenue
            ELSE 0
        END),
        2
    ) AS total_revenue,

    ROUND(
        SUM(CASE
            WHEN IsConverted = 1 THEN Profit
            ELSE 0
        END),
        2
    ) AS total_profit,

    ROUND(
        SUM(CASE
            WHEN IsConverted = 1 THEN Revenue
            ELSE 0
        END)
        / SUM(IsConverted),
        2
    ) AS average_order_value,

    ROUND(
        100.0 *
        SUM(CASE
            WHEN IsConverted = 1 THEN Profit
            ELSE 0
        END)
        /
        SUM(CASE
            WHEN IsConverted = 1 THEN Revenue
            ELSE 0
        END),
        2
    ) AS profit_margin

FROM customer360;

-- ============================================================
-- QUERY 02: Funnel Performance
-- ============================================================

WITH funnel AS (

    SELECT
        'Sessions' AS funnel_stage,
        COUNT(*) AS stage_count,
        1 AS stage_order
    FROM customer360

    UNION ALL

    SELECT
        'Confirmed Orders' AS funnel_stage,
        SUM(IsConverted) AS stage_count,
        2 AS stage_order
    FROM customer360

    UNION ALL

    SELECT
        'Non-Returned Orders' AS funnel_stage,
        SUM(
            CASE
                WHEN IsConverted = 1
                 AND IsReturned = 0
                THEN 1
                ELSE 0
            END
        ) AS stage_count,
        3 AS stage_order
    FROM customer360
)

SELECT
    funnel_stage,
    stage_count,

    ROUND(
        100.0 *
        stage_count /
        LAG(stage_count) OVER (
            ORDER BY stage_order
        ),
        2
    ) AS conversion_from_previous_stage

FROM funnel
ORDER BY stage_order;

-- ============================================================
-- QUERY 03: Campaign Performance
-- ============================================================

SELECT
    CampaignSchema AS campaign,

    COUNT(*) AS sessions,

    SUM(IsConverted) AS orders,

    ROUND(
        100.0 * SUM(IsConverted) / COUNT(*),
        2
    ) AS conversion_rate,

    ROUND(
        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ),
        2
    ) AS revenue,

    ROUND(
        SUM(
            CASE
                WHEN IsConverted = 1 THEN Profit
                ELSE 0
            END
        ),
        2
    ) AS profit,

    ROUND(
        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        )
        / SUM(IsConverted),
        2
    ) AS average_order_value,

    SUM(IsReturned) AS returns,

    ROUND(
        100.0 * SUM(IsReturned) / SUM(IsConverted),
        2
    ) AS return_rate

FROM customer360

GROUP BY CampaignSchema

ORDER BY revenue DESC;

-- ============================================================
-- QUERY 04: Category Performance
-- ============================================================

SELECT
    Category AS category,

    COUNT(*) AS sessions,

    SUM(IsConverted) AS orders,

    ROUND(
        100.0 * SUM(IsConverted) / COUNT(*),
        2
    ) AS conversion_rate,

    ROUND(
        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ),
        2
    ) AS revenue,

    ROUND(
        SUM(
            CASE
                WHEN IsConverted = 1 THEN Profit
                ELSE 0
            END
        ),
        2
    ) AS profit,

    ROUND(
        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ) / SUM(IsConverted),
        2
    ) AS average_order_value,

    SUM(IsReturned) AS returns,

    ROUND(
        100.0 * SUM(IsReturned) / SUM(IsConverted),
        2
    ) AS return_rate

FROM customer360

GROUP BY Category

ORDER BY revenue DESC;

-- ============================================================
-- QUERY 05: Category Revenue Contribution
-- ============================================================

WITH category_sales AS (

    SELECT
        Category AS category,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ) AS revenue

    FROM customer360

    GROUP BY Category
)

SELECT
    category,

    ROUND(revenue, 2) AS revenue,

    ROUND(
        100.0 * revenue / SUM(revenue) OVER (),
        2
    ) AS revenue_share_percent

FROM category_sales

ORDER BY revenue DESC;

-- ============================================================
-- QUERY 05: Category Revenue Contribution
-- ============================================================

WITH category_sales AS (

    SELECT
        Category AS category,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ) AS revenue

    FROM customer360

    GROUP BY Category
)

SELECT
    category,

    ROUND(revenue, 2) AS revenue,

    ROUND(
        100.0 * revenue / SUM(revenue) OVER (),
        2
    ) AS revenue_share_percent

FROM category_sales

ORDER BY revenue DESC;

-- ============================================================
-- QUERY 06: Product Revenue Ranking
-- ============================================================

WITH product_sales AS (

    SELECT
        Product AS product,

        Category AS category,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ) AS revenue,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Profit
                ELSE 0
            END
        ) AS profit,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Quantity
                ELSE 0
            END
        ) AS quantity,

        SUM(IsConverted) AS orders

    FROM customer360

    GROUP BY
        Product,
        Category
)

SELECT
    product,
    category,
    orders,
    quantity,
    ROUND(revenue, 2) AS revenue,
    ROUND(profit, 2) AS profit,

    ROUND(
        revenue / orders,
        2
    ) AS average_order_value,

    RANK() OVER (
        ORDER BY revenue DESC
    ) AS revenue_rank

FROM product_sales

ORDER BY revenue_rank;

-- ============================================================
-- QUERY 07: Top Products Within Each Category
-- ============================================================

WITH product_sales AS (

    SELECT
        Product AS product,

        Category AS category,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ) AS revenue,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Profit
                ELSE 0
            END
        ) AS profit,

        SUM(IsConverted) AS orders

    FROM customer360

    GROUP BY
        Product,
        Category
),

ranked_products AS (

    SELECT
        product,
        category,
        orders,
        revenue,
        profit,

        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS category_rank

    FROM product_sales
)

SELECT
    product,
    category,
    orders,
    ROUND(revenue, 2) AS revenue,
    ROUND(profit, 2) AS profit,
    category_rank

FROM ranked_products

WHERE category_rank <= 3

ORDER BY
    category,
    category_rank;
    
-- ============================================================
-- QUERY 08: Return Reasons
-- ============================================================

SELECT
    ReturnReason AS return_reason,

    COUNT(*) AS return_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS return_share_percent

FROM customer360

WHERE IsReturned = 1

GROUP BY ReturnReason

ORDER BY return_count DESC;

-- ============================================================
-- QUERY 09: Age Segment Performance
-- ============================================================

SELECT
    AgeGroup AS age_group,

    COUNT(*) AS sessions,

    SUM(IsConverted) AS orders,

    ROUND(
        100.0 * SUM(IsConverted) / COUNT(*),
        2
    ) AS conversion_rate,

    ROUND(
        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ),
        2
    ) AS revenue,

    ROUND(
        SUM(
            CASE
                WHEN IsConverted = 1 THEN Profit
                ELSE 0
            END
        ),
        2
    ) AS profit,

    ROUND(
        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ) / SUM(IsConverted),
        2
    ) AS average_order_value,

    SUM(IsReturned) AS returns,

    ROUND(
        100.0 * SUM(IsReturned) / SUM(IsConverted),
        2
    ) AS return_rate

FROM customer360

GROUP BY AgeGroup

ORDER BY revenue DESC;

-- ============================================================
-- QUERY 10: Campaign Performance Ranking
-- ============================================================

WITH campaign_performance AS (

    SELECT
        CampaignSchema AS campaign,

        COUNT(*) AS sessions,

        SUM(IsConverted) AS orders,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ) AS revenue,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Profit
                ELSE 0
            END
        ) AS profit

    FROM customer360

    GROUP BY CampaignSchema
)

SELECT
    campaign,

    sessions,

    orders,

    ROUND(
        100.0 * orders / sessions,
        2
    ) AS conversion_rate,

    ROUND(revenue, 2) AS revenue,

    ROUND(profit, 2) AS profit,

    RANK() OVER (
        ORDER BY revenue DESC
    ) AS revenue_rank,

    RANK() OVER (
        ORDER BY profit DESC
    ) AS profit_rank,

    RANK() OVER (
        ORDER BY orders * 1.0 / sessions DESC
    ) AS conversion_rank

FROM campaign_performance

ORDER BY revenue_rank;

-- ============================================================
-- QUERY 11: High-Value Products
-- ============================================================

WITH product_performance AS (

    SELECT
        Product AS product,

        Category AS category,

        SUM(IsConverted) AS orders,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Revenue
                ELSE 0
            END
        ) AS revenue,

        SUM(
            CASE
                WHEN IsConverted = 1 THEN Profit
                ELSE 0
            END
        ) AS profit

    FROM customer360

    GROUP BY
        Product,
        Category
)

SELECT
    product,

    category,

    orders,

    ROUND(revenue, 2) AS revenue,

    ROUND(profit, 2) AS profit,

    ROUND(
        100.0 * profit / revenue,
        2
    ) AS profit_margin

FROM product_performance

WHERE revenue > (
    SELECT AVG(revenue)
    FROM product_performance
)

AND profit > (
    SELECT AVG(profit)
    FROM product_performance
)

ORDER BY profit DESC;