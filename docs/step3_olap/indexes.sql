-- ================================================================
-- Index Files cho Data Warehouse
-- Bài tập lớn Kho dữ liệu - INT1422
-- ================================================================
-- Gồm:
--   1. B-tree indexes cho FK trong Fact tables
--   2. Indexes cho Dimension lookup columns
--   3. Composite indexes cho OLAP queries thường dùng
--   4. Indexes cho Materialized Views
-- ================================================================

-- ================================================================
-- 1. INDEXES CHO FACT TABLES (B-tree trên FK)
-- ================================================================

-- fact_ban_hang: index trên từng FK để tăng tốc JOIN
CREATE INDEX IF NOT EXISTS idx_fbh_thoi_gian ON fact_ban_hang(thoi_gian_key);
CREATE INDEX IF NOT EXISTS idx_fbh_khach_hang ON fact_ban_hang(khach_hang_key);
CREATE INDEX IF NOT EXISTS idx_fbh_mat_hang ON fact_ban_hang(mat_hang_key);
CREATE INDEX IF NOT EXISTS idx_fbh_cua_hang ON fact_ban_hang(cua_hang_key);
CREATE INDEX IF NOT EXISTS idx_fbh_ma_don ON fact_ban_hang(ma_don);

-- fact_ton_kho: index trên từng FK
CREATE INDEX IF NOT EXISTS idx_ftk_thoi_gian ON fact_ton_kho(thoi_gian_key);
CREATE INDEX IF NOT EXISTS idx_ftk_mat_hang ON fact_ton_kho(mat_hang_key);
CREATE INDEX IF NOT EXISTS idx_ftk_cua_hang ON fact_ton_kho(cua_hang_key);

-- ================================================================
-- 2. INDEXES CHO DIMENSION TABLES (Lookup columns)
-- ================================================================

-- dim_thoi_gian: lookup theo ngày, tháng, quý, năm
CREATE INDEX IF NOT EXISTS idx_dtg_ngay ON dim_thoi_gian(ngay);
CREATE INDEX IF NOT EXISTS idx_dtg_thang_nam ON dim_thoi_gian(nam, thang);
CREATE INDEX IF NOT EXISTS idx_dtg_quy_nam ON dim_thoi_gian(nam, quy);

-- dim_khach_hang: lookup theo mã KH, loại KH, thành phố
CREATE INDEX IF NOT EXISTS idx_dkh_ma_kh ON dim_khach_hang(ma_kh);
CREATE INDEX IF NOT EXISTS idx_dkh_loai_kh ON dim_khach_hang(loai_kh);
CREATE INDEX IF NOT EXISTS idx_dkh_tp ON dim_khach_hang(ten_thanh_pho_kh);
CREATE INDEX IF NOT EXISTS idx_dkh_bang ON dim_khach_hang(bang_kh);

-- dim_mat_hang: lookup theo mã MH
CREATE INDEX IF NOT EXISTS idx_dmh_ma_mh ON dim_mat_hang(ma_mat_hang);

-- dim_cua_hang: lookup theo mã CH, thành phố, bang
CREATE INDEX IF NOT EXISTS idx_dch_ma_ch ON dim_cua_hang(ma_cua_hang);
CREATE INDEX IF NOT EXISTS idx_dch_tp ON dim_cua_hang(ten_thanh_pho);
CREATE INDEX IF NOT EXISTS idx_dch_bang ON dim_cua_hang(bang);
CREATE INDEX IF NOT EXISTS idx_dch_ma_tp ON dim_cua_hang(ma_thanh_pho);

-- ================================================================
-- 3. COMPOSITE INDEXES CHO OLAP QUERIES
-- ================================================================

-- Q1, Q7: Tồn kho theo MH + CH → composite trên fact_ton_kho
CREATE INDEX IF NOT EXISTS idx_ftk_mh_ch ON fact_ton_kho(mat_hang_key, cua_hang_key);

-- Q2, Q8: Đơn hàng theo KH + thời gian
CREATE INDEX IF NOT EXISTS idx_fbh_kh_tg ON fact_ban_hang(khach_hang_key, thoi_gian_key);

-- Q3: MH đặt bởi KH → composite trên fact_ban_hang
CREATE INDEX IF NOT EXISTS idx_fbh_kh_mh ON fact_ban_hang(khach_hang_key, mat_hang_key);

-- Drill Down/Roll Up theo thời gian
CREATE INDEX IF NOT EXISTS idx_fbh_tg_ch ON fact_ban_hang(thoi_gian_key, cua_hang_key);

-- ================================================================
-- 4. INDEXES CHO MATERIALIZED VIEWS
-- ================================================================

-- mv_cube_ban_hang
CREATE INDEX IF NOT EXISTS idx_mcbh_nam_quy_thang ON mv_cube_ban_hang(nam, quy, thang);
CREATE INDEX IF NOT EXISTS idx_mcbh_bang_tp ON mv_cube_ban_hang(bang, ten_thanh_pho);
CREATE INDEX IF NOT EXISTS idx_mcbh_loai_kh ON mv_cube_ban_hang(loai_kh);
CREATE INDEX IF NOT EXISTS idx_mcbh_ma_don ON mv_cube_ban_hang(ma_don);
CREATE INDEX IF NOT EXISTS idx_mcbh_ma_kh ON mv_cube_ban_hang(ma_kh);
CREATE INDEX IF NOT EXISTS idx_mcbh_ma_mh ON mv_cube_ban_hang(ma_mat_hang);

-- mv_cube_ton_kho
CREATE INDEX IF NOT EXISTS idx_mctk_bang_tp ON mv_cube_ton_kho(bang, ten_thanh_pho);
CREATE INDEX IF NOT EXISTS idx_mctk_ma_mh ON mv_cube_ton_kho(ma_mat_hang);
CREATE INDEX IF NOT EXISTS idx_mctk_ma_ch ON mv_cube_ton_kho(ma_cua_hang);
CREATE INDEX IF NOT EXISTS idx_mctk_mh_tp ON mv_cube_ton_kho(ma_mat_hang, ten_thanh_pho);

-- mv_cube_khach_hang
CREATE INDEX IF NOT EXISTS idx_mckh_loai ON mv_cube_khach_hang(loai_kh);
CREATE INDEX IF NOT EXISTS idx_mckh_tp ON mv_cube_khach_hang(ten_thanh_pho_kh);
CREATE INDEX IF NOT EXISTS idx_mckh_bang ON mv_cube_khach_hang(bang_kh);

-- ================================================================
-- Thống kê tổng: 31 indexes
-- - Fact tables: 8 indexes
-- - Dimension tables: 11 indexes  
-- - Composite (OLAP): 4 indexes
-- - Materialized Views: 13 indexes
-- ================================================================
