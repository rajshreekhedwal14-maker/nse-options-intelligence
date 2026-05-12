-- NSE OPTIONS INTELLIGENCE
-- PostgreSQL Schema | April 2026

CREATE TABLE stocks (
    stock_name   VARCHAR(50) PRIMARY KEY,
    sector       VARCHAR(50),
    lot_size     INTEGER,
    index_member VARCHAR(20) DEFAULT 'Nifty 50'
);

CREATE TABLE trades (
    trade_id          VARCHAR(10) PRIMARY KEY,
    stock             VARCHAR(50),
    sector            VARCHAR(50),
    option_type       VARCHAR(2),
    ratio             VARCHAR(5),
    ratio_num         NUMERIC(5,2),
    sell_strike       NUMERIC(10,2),
    sell_price        NUMERIC(8,4),
    sell_lots         INTEGER,
    buy_strike        NUMERIC(10,2),
    buy_price         NUMERIC(8,4),
    buy_lots          INTEGER,
    entry_date        DATE,
    entry_net_premium NUMERIC(10,2),
    exit_date         DATE,
    exit_net_premium  NUMERIC(10,2),
    lot_size          INTEGER,
    pnl_inr           NUMERIC(12,0),
    days_held         INTEGER,
    result            VARCHAR(4)
);

-- QUERY 1: Cumulative P&L by date (Window Function)
SELECT exit_date,
       COUNT(*) AS trades_closed,
       SUM(pnl_inr) AS daily_pnl,
       SUM(SUM(pnl_inr)) OVER (ORDER BY exit_date) AS cumulative_pnl
FROM trades
GROUP BY exit_date
ORDER BY exit_date;

-- QUERY 2: Win rate and avg P&L by ratio
SELECT ratio,
       COUNT(*) AS total_trades,
       SUM(CASE WHEN result = 'Win' THEN 1 ELSE 0 END) AS wins,
       ROUND(100.0 * SUM(CASE WHEN result = 'Win' THEN 1 ELSE 0 END) / COUNT(*), 1) AS win_rate_pct,
       ROUND(AVG(pnl_inr), 0) AS avg_pnl,
       ROUND(SUM(pnl_inr), 0) AS total_pnl
FROM trades
GROUP BY ratio
ORDER BY ratio;

-- QUERY 3: Sector ranking (CTE + RANK)
WITH sector_stats AS (
    SELECT sector,
           COUNT(*) AS trades,
           SUM(pnl_inr) AS total_pnl,
           ROUND(AVG(pnl_inr), 0) AS avg_pnl,
           ROUND(100.0 * SUM(CASE WHEN result = 'Win' THEN 1 ELSE 0 END) / COUNT(*), 1) AS win_rate_pct
    FROM trades
    GROUP BY sector
)
SELECT RANK() OVER (ORDER BY total_pnl DESC) AS rank,
       sector, trades, total_pnl, avg_pnl, win_rate_pct
FROM sector_stats
ORDER BY rank;

-- QUERY 4: Rolling 5-trade average P&L
SELECT trade_id, stock, entry_date, pnl_inr,
       ROUND(AVG(pnl_inr) OVER (
           ORDER BY entry_date, trade_id
           ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
       ), 0) AS rolling_5_avg_pnl
FROM trades
ORDER BY entry_date, trade_id;

-- QUERY 5: Best stocks by win rate (Nested CTE)
WITH stock_stats AS (
    SELECT stock, sector,
           COUNT(*) AS total_trades,
           SUM(CASE WHEN result = 'Win' THEN 1 ELSE 0 END) AS wins,
           SUM(pnl_inr) AS total_pnl
    FROM trades
    GROUP BY stock, sector
),
filtered AS (
    SELECT *, ROUND(100.0 * wins / total_trades, 1) AS win_pct
    FROM stock_stats
    WHERE total_trades >= 2
)
SELECT stock, sector, total_trades, wins, win_pct, total_pnl
FROM filtered
WHERE win_pct >= 70
ORDER BY win_pct DESC, total_pnl DESC;
