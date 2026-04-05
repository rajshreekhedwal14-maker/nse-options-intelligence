
-- ============================================================
-- 02_sample_data.sql — Sample Data
-- ============================================================

-- Stock master data with correct NSE lot sizes
INSERT INTO stocks (symbol, company_name, lot_size, sector) VALUES
('RELIANCE',  'Reliance Industries Ltd',    250,  'Energy'),
('HDFCBANK',  'HDFC Bank Ltd',              550,  'Banking'),
('ICICIBANK', 'ICICI Bank Ltd',             700,  'Banking'),
('AXISBANK',  'Axis Bank Ltd',              1200, 'Banking'),
('SBIN',      'State Bank of India',        1500, 'Banking');
-- Note: lot sizes change every expiry — update as needed

-- Expiry cycles
INSERT INTO expiry_cycles (expiry_date, cycle_name, trading_start, trading_end) VALUES
('2026-03-27', 'MAR2026', '2026-02-27', '2026-03-27'),
('2026-04-24', 'APR2026', '2026-03-28', '2026-04-24'),
('2026-05-28', 'MAY2026', '2026-04-25', '2026-05-28');

-- Sample trades (simulated — real data starts 7th April)
INSERT INTO trades (
    stock_id, cycle_id, trade_date, strategy_type, market_view,
    buy_strike, buy_option_type, buy_lots, buy_premium_entry, buy_delta_entry,
    sell_strike, sell_option_type, sell_lots, sell_premium_entry, sell_delta_entry,
    ratio, margin_used, net_inflow, spot_price_entry, status
) VALUES
-- Trade 1: SBI Bearish Call Spread
(5, 2, '2026-04-07', 'CALL_SPREAD', 'BEARISH',
 840, 'CE', 1, 4.00, 0.28,
 900, 'CE', 4, 1.75, 0.12,
 '1:4', 300000, 2250, 780.00, 'OPEN'),

-- Trade 2: HDFC Bank Bullish Put Spread
(2, 2, '2026-04-07', 'PUT_SPREAD', 'BULLISH',
 840, 'PE', 1, 3.50, -0.25,
 800, 'PE', 4, 1.20, -0.10,
 '1:4', 450000, 1300, 860.00, 'OPEN'),

-- Trade 3: ICICI Bank Bearish Call Spread
(3, 2, '2026-04-08', 'CALL_SPREAD', 'BEARISH',
 1100, 'CE', 1, 5.00, 0.30,
 1150, 'CE', 3, 2.00, 0.15,
 '1:3', 380000, 1000, 1050.00, 'CLOSED');

-- Sample exit for Trade 3
INSERT INTO trade_exits (
    trade_id, exit_date, days_held,
    buy_premium_exit, sell_premium_exit,
    gap_at_exit, exit_reason,
    buy_leg_pnl, sell_leg_pnl,
    gross_pnl, brokerage, net_pnl, pnl_percentage
) VALUES
(3, '2026-04-10', 2,
 2.50, 0.80,
 0.85, 'GAP_NARROWED',
 -- buy leg: (2.50 - 5.00) * 1 * 700 = -1750
 -1750,
 -- sell leg: (2.00 - 0.80) * 3 * 700 = 2520
 2520,
 770, 40, 730,
 -- pnl% = 730/380000 * 100
 0.19);
