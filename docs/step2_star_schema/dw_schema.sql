-- ================================================================
-- Data Warehouse Schema (Star Schema)
-- Bài tập lớn Kho dữ liệu - INT1422
-- CSDL: PostgreSQL
-- ================================================================
-- 4 Dimension tables + 2 Fact tables
-- ================================================================

-- Xóa bảng cũ nếu tồn tại (thứ tự ngược dependency)
DROP TABLE IF EXISTS fact_ban_hang CASCADE;
DROP TABLE IF EXISTS fact_ton_kho CASCADE;
DROP TABLE IF EXISTS dim_thoi_gian CASCADE;
DROP TABLE IF EXISTS dim_khach_hang CASCADE;
DROP TABLE IF EXISTS dim_mat_hang CASCADE;
DROP TABLE IF EXISTS dim_cua_hang CASCADE;

-- ================================================================
-- DIMENSION TABLES
-- ================================================================

-- ================================================================
-- 1. DIM_THOI_GIAN (Time Dimension)
-- Hierarchy: Ngày → Tuần → Tháng → Quý → Năm
-- ================================================================
CREATE TABLE dim_thoi_gian (
    thoi_gian_key       SERIAL       PRIMARY KEY,
    ngay                DATE         NOT NULL UNIQUE,
    ngay_trong_tuan     INTEGER      NOT NULL CHECK (ngay_trong_tuan BETWEEN 1 AND 7),
    ten_thu             VARCHAR(20)  NOT NULL,
    tuan                INTEGER      NOT NULL CHECK (tuan BETWEEN 1 AND 53),
    thang               INTEGER      NOT NULL CHECK (thang BETWEEN 1 AND 12),
    ten_thang           VARCHAR(20)  NOT NULL,
    quy                 INTEGER      NOT NULL CHECK (quy BETWEEN 1 AND 4),
    nam                 INTEGER      NOT NULL
);

COMMENT ON TABLE dim_thoi_gian IS 'Dimension Thời gian - Hierarchy: Ngày → Tuần → Tháng → Quý → Năm';

-- ================================================================
-- 2. DIM_KHACH_HANG (Customer Dimension)
-- Hierarchy: KH → Loại KH, KH → Thành phố → Bang
-- Flatten ISA: loai_kh = Du lịch | Bưu điện | Cả hai | Thường
-- ================================================================
CREATE TABLE dim_khach_hang (
    khach_hang_key      SERIAL       PRIMARY KEY,
    ma_kh               VARCHAR(10)  NOT NULL UNIQUE,
    ten_kh              VARCHAR(100) NOT NULL,
    loai_kh             VARCHAR(20)  NOT NULL DEFAULT 'Thường'
                        CHECK (loai_kh IN ('Du lịch', 'Bưu điện', 'Cả hai', 'Thường')),
    huong_dan_vien      VARCHAR(100),
    dia_chi_buu_dien    VARCHAR(200),
    ten_thanh_pho_kh    VARCHAR(100) NOT NULL,
    bang_kh             VARCHAR(100),
    ngay_dh_dau_tien    DATE
);

COMMENT ON TABLE dim_khach_hang IS 'Dimension Khách hàng - gộp ISA (du lịch/bưu điện) vào loai_kh';

-- ================================================================
-- 3. DIM_MAT_HANG (Product Dimension)
-- Flat hierarchy (không phân cấp)
-- ================================================================
CREATE TABLE dim_mat_hang (
    mat_hang_key        SERIAL       PRIMARY KEY,
    ma_mat_hang         VARCHAR(10)  NOT NULL UNIQUE,
    mo_ta               VARCHAR(200),
    kich_co             VARCHAR(50),
    trong_luong         DECIMAL(10,2),
    gia                 DECIMAL(15,2) NOT NULL
);

COMMENT ON TABLE dim_mat_hang IS 'Dimension Mặt hàng - Flat (không phân cấp)';

-- ================================================================
-- 4. DIM_CUA_HANG (Store Dimension)
-- Hierarchy: Cửa hàng → Thành phố → Bang
-- Denormalized: gộp VPĐD info vào dimension
-- ================================================================
CREATE TABLE dim_cua_hang (
    cua_hang_key        SERIAL       PRIMARY KEY,
    ma_cua_hang         VARCHAR(10)  NOT NULL UNIQUE,
    so_dien_thoai       VARCHAR(20),
    ma_thanh_pho        VARCHAR(10)  NOT NULL,
    ten_thanh_pho       VARCHAR(100) NOT NULL,
    dia_chi_vp          VARCHAR(200),
    bang                VARCHAR(100)
);

COMMENT ON TABLE dim_cua_hang IS 'Dimension Cửa hàng - Hierarchy: Cửa hàng → Thành phố → Bang';

-- ================================================================
-- FACT TABLES
-- ================================================================

-- ================================================================
-- 5. FACT_BAN_HANG (Sales Transaction Fact)
-- Grain: 1 mặt hàng × 1 đơn hàng
-- Measures: so_luong_dat, gia_dat, doanh_thu
-- ================================================================
CREATE TABLE fact_ban_hang (
    fact_ban_hang_id    SERIAL       PRIMARY KEY,
    thoi_gian_key       INTEGER      NOT NULL REFERENCES dim_thoi_gian(thoi_gian_key),
    khach_hang_key      INTEGER      NOT NULL REFERENCES dim_khach_hang(khach_hang_key),
    mat_hang_key        INTEGER      NOT NULL REFERENCES dim_mat_hang(mat_hang_key),
    cua_hang_key        INTEGER      NOT NULL REFERENCES dim_cua_hang(cua_hang_key),
    ma_don              VARCHAR(10)  NOT NULL,  -- Degenerate Dimension
    so_luong_dat        INTEGER      NOT NULL CHECK (so_luong_dat > 0),
    gia_dat             DECIMAL(15,2) NOT NULL,
    doanh_thu           DECIMAL(15,2) NOT NULL  -- = so_luong_dat * gia_dat
);

COMMENT ON TABLE fact_ban_hang IS 'Fact Bán hàng - Transaction fact, grain: 1 MH × 1 đơn hàng';

-- Indexes cho Fact Bán hàng
CREATE INDEX idx_fact_bh_thoi_gian ON fact_ban_hang(thoi_gian_key);
CREATE INDEX idx_fact_bh_khach_hang ON fact_ban_hang(khach_hang_key);
CREATE INDEX idx_fact_bh_mat_hang ON fact_ban_hang(mat_hang_key);
CREATE INDEX idx_fact_bh_cua_hang ON fact_ban_hang(cua_hang_key);
CREATE INDEX idx_fact_bh_ma_don ON fact_ban_hang(ma_don);

-- ================================================================
-- 6. FACT_TON_KHO (Inventory Snapshot Fact)
-- Grain: 1 mặt hàng × 1 cửa hàng × 1 thời điểm
-- Measures: so_luong_kho
-- ================================================================
CREATE TABLE fact_ton_kho (
    fact_ton_kho_id     SERIAL       PRIMARY KEY,
    thoi_gian_key       INTEGER      NOT NULL REFERENCES dim_thoi_gian(thoi_gian_key),
    mat_hang_key        INTEGER      NOT NULL REFERENCES dim_mat_hang(mat_hang_key),
    cua_hang_key        INTEGER      NOT NULL REFERENCES dim_cua_hang(cua_hang_key),
    so_luong_kho        INTEGER      NOT NULL CHECK (so_luong_kho >= 0)
);

COMMENT ON TABLE fact_ton_kho IS 'Fact Tồn kho - Periodic snapshot, grain: 1 MH × 1 CH × 1 thời điểm';

-- Indexes cho Fact Tồn kho
CREATE INDEX idx_fact_tk_thoi_gian ON fact_ton_kho(thoi_gian_key);
CREATE INDEX idx_fact_tk_mat_hang ON fact_ton_kho(mat_hang_key);
CREATE INDEX idx_fact_tk_cua_hang ON fact_ton_kho(cua_hang_key);
