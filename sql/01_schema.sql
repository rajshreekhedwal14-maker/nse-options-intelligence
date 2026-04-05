-- ============================================================
-- NSE OPTIONS RATIO SPREAD INTELLIGENCE SYSTEM
-- 01_schema.sql — Database Structure
-- ============================================================

-- 1. STOCKS TABLE
-- Master list of all stocks traded
CREATE TABLE stocks (
    stock_id        SERIAL PRIMARY KEY,
    symbol          VARCHAR(20) NOT NULL UNIQUE,
    company_name    VARCHAR(100) NOT NULL,
    lot_size        INT NOT NULL,
    -- lot_size is critical — SBI=750, Reliance=250 etc
    sector          VARCHAR(50),
    is_active       BOOLEAN DEFAULT TRUE
);

-- 2. EXPIRY TABLE
-- Tracks each monthly expiry cycle
CREATE TABLE expiry_cycles (
    cycle_id        SERIAL PRIMARY KEY,
    expiry_date     DATE NOT NULL UNIQUE,
    cycle_name      VARCHAR(20) NOT NULL,
    -- e.g. 'APR2026', 'MAY2026'
    trading_start   DATE NOT NULL,
    -- day after previous expiry
    trading_end     DATE NOT NULL
    -- last day before this expiry
);

-- 3. TRADES TABLE
-- Every ratio spread trade entered
CREATE TABLE trades (
    trade_id            SERIAL PRIMARY KEY,
    stock_id            INT NOT NULL REFERENCES stocks(stock_id),
    cycle_id            INT NOT NULL REFERENCES expiry_cycles(cycle_id),
    trade_date          DATE NOT NULL,
    strategy_type       VARCHAR(20) NOT NULL,
    -- 'CALL_SPREAD' or 'PUT_SPREAD'
    market_view         VARCHAR(10) NOT NULL,
    -- 'BEARISH' or 'BULLISH'

    -- BUY LEG
    buy_strike          NUMERIC(10,2) NOT NULL,
    buy_option_type     VARCHAR(4) NOT NULL,
    -- 'CE' or 'PE'
    buy_lots            INT NOT NULL,
    buy_premium_entry   NUMERIC(10,2) NOT NULL,
    buy_delta_entry     NUMERIC(6,4),

    -- SELL LEG
    sell_strike         NUMERIC(10,2) NOT NULL,
    sell_option_type    VARCHAR(4) NOT NULL,
    sell_lots           INT NOT NULL,
    sell_premium_entry  NUMERIC(10,2) NOT NULL,
    sell_delta_entry    NUMERIC(6,4),

    -- RATIO
    ratio               VARCHAR(10) NOT NULL,
    -- '1:2', '1:3', '1:4'

    -- MARGIN AND INFLOW
    margin_used         NUMERIC(12,2) NOT NULL,
    net_inflow          NUMERIC(12,2),
    -- sell premium received - buy premium paid

    -- MARKET CONDITIONS AT ENTRY
    spot_price_entry    NUMERIC(10,2),
    vix_at_entry        NUMERIC(6,2),
    oi_at_entry         BIGINT,

    status              VARCHAR(10) DEFAULT 'OPEN'
    -- 'OPEN' or 'CLOSED'
);

-- 4. TRADE EXITS TABLE
-- When and how each trade was closed
CREATE TABLE trade_exits (
    exit_id             SERIAL PRIMARY KEY,
    trade_id            INT NOT NULL REFERENCES trades(trade_id),
    exit_date           DATE NOT NULL,
    days_held           INT NOT NULL,

    -- EXIT PREMIUMS
    buy_premium_exit    NUMERIC(10,2) NOT NULL,
    sell_premium_exit   NUMERIC(10,2) NOT NULL,

    -- EXIT CONDITIONS
    gap_at_exit         NUMERIC(6,2),
    -- gap between buy and sell premium at exit
    exit_reason         VARCHAR(50),
    -- 'GAP_NARROWED', 'LOW_OI', 'TIME_DECAY', 'STOP_LOSS'

    -- P&L CALCULATION
    buy_leg_pnl         NUMERIC(12,2),
    -- (exit - entry) * lots * lot_size
    sell_leg_pnl        NUMERIC(12,2),
    -- (entry - exit) * lots * lot_size
    gross_pnl           NUMERIC(12,2),
    brokerage           NUMERIC(10,2) DEFAULT 40.00,
    net_pnl             NUMERIC(12,2),
    pnl_percentage      NUMERIC(8,4)
    -- net_pnl / margin_used * 100
);

-- 5. DAILY MARKET DATA TABLE
-- Daily snapshot of stock prices and Greeks
CREATE TABLE daily_market_data (
    data_id         SERIAL PRIMARY KEY,
    stock_id        INT NOT NULL REFERENCES stocks(stock_id),
    data_date       DATE NOT NULL,
    spot_price      NUMERIC(10,2),
    day_high        NUMERIC(10,2),
    day_low         NUMERIC(10,2),
    day_volume      BIGINT,
    india_vix       NUMERIC(6,2),
    UNIQUE(stock_id, data_date)
);

-- 6. PORTFOLIO SUMMARY TABLE
-- Daily portfolio level summary
CREATE TABLE portfolio_summary (
    summary_id          SERIAL PRIMARY KEY,
    summary_date        DATE NOT NULL UNIQUE,
    total_margin_used   NUMERIC(12,2),
    total_capital       NUMERIC(12,2) DEFAULT 7000000,
    -- 70 lakhs
    open_trades         INT,
    closed_trades_today INT,
    daily_pnl           NUMERIC(12,2),
    cumulative_pnl      NUMERIC(12,2),
    capital_utilization NUMERIC(8,4),
    -- margin_used / total_capital * 100
    win_trades_today    INT,
    loss_trades_today   INT
);
