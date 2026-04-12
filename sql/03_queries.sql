-- QUERY 3: Strategy Performance (Call vs Put Spread)
SELECT
    strategy_type,
    market_view,
    COUNT(*) AS total_trades,
    COUNT(CASE WHEN te.net_pnl > 0 THEN 1 END) AS wins,
    COUNT(CASE WHEN te.net_pnl <= 0 THEN 1 END) AS losses,
    ROUND(
        COUNT(CASE WHEN te.net_pnl > 0 THEN 1 END) * 100.0
        / COUNT(*), 1
    ) AS win_rate_pct,
    ROUND(SUM(te.net_pnl), 2) AS total_pnl,
    ROUND(AVG(te.net_pnl), 2) AS avg_pnl_per_trade,
    ROUND(AVG(te.pnl_percentage), 4) AS avg_return_pct
FROM trades t
JOIN trade_exits te ON t.trade_id = te.trade_id
GROUP BY strategy_type, market_view
ORDER BY total_pnl DESC;
