-- Grp2 Top Revenue by Genre per Country Analysis
-- Direct SQL query that can be executed against ClickHouse to create the mart table
-- This creates a table that can be accessed in Metabase

CREATE OR REPLACE TABLE mart.g2_top_revenue_by_genre_per_country_shi AS
WITH revenue_by_genre_country AS (
    SELECT 
        c.country,
        g.name as genre_name,
        SUM(il.unit_price * il.quantity) as total_revenue,
        COUNT(DISTINCT i.customer_id) as unique_customers,
        COUNT(il.invoice_line_id) as total_tracks_sold,
        SUM(il.quantity) as total_quantity
    FROM raw.chinook___invoice_line_shi il
    JOIN raw.chinook___invoice_shi i 
        ON il.invoice_id = i.invoice_id
    JOIN raw.chinook___customer_shi c 
        ON i.customer_id = c.customer_id
    JOIN raw.chinook___track_shi t 
        ON il.track_id = t.track_id
    JOIN raw.chinook___genre_shi g 
        ON t.genre_id = g.genre_id
    GROUP BY 
        c.country, 
        g.name
),
ranked_genres AS (
    SELECT 
        country,
        genre_name,
        total_revenue,
        unique_customers,
        total_tracks_sold,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_revenue DESC) as genre_rank
    FROM revenue_by_genre_country
)
SELECT 
    country,
    genre_name,
    ROUND(total_revenue, 2) as total_revenue,
    unique_customers,
    total_tracks_sold,
    total_quantity,
    genre_rank
FROM ranked_genres
WHERE genre_rank <= 5  -- Top 5 genres per country
ORDER BY 
    country ASC,
    total_revenue DESC;