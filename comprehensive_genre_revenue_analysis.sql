-- Top Revenue by Genre per Country - Multiple Approaches
-- Choose the approach that works best with your environment

-- APPROACH 1: Simple Revenue by Genre and Country (No ranking)
-- This shows all genres for all countries sorted by revenue
SELECT 
    c.country,
    g.name as genre_name,
    ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue,
    COUNT(DISTINCT i.customer_id) as unique_customers,
    COUNT(*) as total_tracks_sold,
    SUM(il.quantity) as total_quantity
FROM chinook_raw_grp4___invoice_line il
INNER JOIN chinook_raw_grp4___invoice i ON il.invoice_id = i.invoice_id
INNER JOIN chinook_raw_grp4___customer c ON i.customer_id = c.customer_id
INNER JOIN chinook_raw_grp4___track t ON il.track_id = t.track_id
INNER JOIN chinook_raw_grp4___genre g ON t.genre_id = g.genre_id
GROUP BY c.country, g.name
HAVING SUM(il.unit_price * il.quantity) > 0
ORDER BY c.country, total_revenue DESC;

-- APPROACH 2: Top Genre per Country (Using subquery approach)
-- This shows only the #1 revenue genre for each country
SELECT 
    main.country,
    main.genre_name,
    main.total_revenue,
    main.unique_customers,
    main.total_tracks_sold,
    main.total_quantity
FROM (
    SELECT 
        c.country,
        g.name as genre_name,
        ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue,
        COUNT(DISTINCT i.customer_id) as unique_customers,
        COUNT(*) as total_tracks_sold,
        SUM(il.quantity) as total_quantity
    FROM chinook_raw_grp4___invoice_line il
    INNER JOIN chinook_raw_grp4___invoice i ON il.invoice_id = i.invoice_id
    INNER JOIN chinook_raw_grp4___customer c ON i.customer_id = c.customer_id
    INNER JOIN chinook_raw_grp4___track t ON il.track_id = t.track_id
    INNER JOIN chinook_raw_grp4___genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.name
) main
INNER JOIN (
    SELECT 
        c.country,
        MAX(ROUND(SUM(il.unit_price * il.quantity), 2)) as max_revenue
    FROM chinook_raw_grp4___invoice_line il
    INNER JOIN chinook_raw_grp4___invoice i ON il.invoice_id = i.invoice_id
    INNER JOIN chinook_raw_grp4___customer c ON i.customer_id = c.customer_id
    INNER JOIN chinook_raw_grp4___track t ON il.track_id = t.track_id
    INNER JOIN chinook_raw_grp4___genre g ON t.genre_id = g.genre_id
    GROUP BY c.country
) max_by_country ON main.country = max_by_country.country 
                 AND main.total_revenue = max_by_country.max_revenue
ORDER BY main.country, main.total_revenue DESC;

-- APPROACH 3: Global Top Genres (regardless of country)
-- This shows the top genres globally with country breakdown
SELECT 
    g.name as genre_name,
    c.country,
    ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue,
    COUNT(DISTINCT i.customer_id) as unique_customers,
    COUNT(*) as total_tracks_sold,
    SUM(il.quantity) as total_quantity,
    ROUND(SUM(il.unit_price * il.quantity) / SUM(SUM(il.unit_price * il.quantity)) OVER (PARTITION BY g.name) * 100, 2) as pct_of_genre_revenue
FROM chinook_raw_grp4___invoice_line il
INNER JOIN chinook_raw_grp4___invoice i ON il.invoice_id = i.invoice_id
INNER JOIN chinook_raw_grp4___customer c ON i.customer_id = c.customer_id
INNER JOIN chinook_raw_grp4___track t ON il.track_id = t.track_id
INNER JOIN chinook_raw_grp4___genre g ON t.genre_id = g.genre_id
WHERE g.name IN (
    SELECT genre_name FROM (
        SELECT 
            g2.name as genre_name,
            SUM(il2.unit_price * il2.quantity) as genre_revenue
        FROM chinook_raw_grp4___invoice_line il2
        INNER JOIN chinook_raw_grp4___track t2 ON il2.track_id = t2.track_id
        INNER JOIN chinook_raw_grp4___genre g2 ON t2.genre_id = g2.genre_id
        GROUP BY g2.name
        ORDER BY genre_revenue DESC
        LIMIT 5
    ) top_genres
)
GROUP BY g.name, c.country
ORDER BY g.name, total_revenue DESC;