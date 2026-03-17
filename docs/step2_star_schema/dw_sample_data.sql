-- ================================================================
-- Data Warehouse - Sample Data (ETL from IDB)
-- Bài tập lớn Kho dữ liệu - INT1422
-- CSDL: PostgreSQL
-- ================================================================
-- Chạy sau: dw_schema.sql
-- Thứ tự: dim tables trước, fact tables sau
-- ================================================================

-- ================================================================
-- 1. DIM_THOI_GIAN - Sinh tất cả ngày trong năm 2024
-- ================================================================
INSERT INTO dim_thoi_gian (ngay, ngay_trong_tuan, ten_thu, tuan, thang, ten_thang, quy, nam)
SELECT
    d::DATE AS ngay,
    EXTRACT(ISODOW FROM d::DATE)::INTEGER AS ngay_trong_tuan,
    CASE EXTRACT(ISODOW FROM d::DATE)::INTEGER
        WHEN 1 THEN 'Thứ Hai'
        WHEN 2 THEN 'Thứ Ba'
        WHEN 3 THEN 'Thứ Tư'
        WHEN 4 THEN 'Thứ Năm'
        WHEN 5 THEN 'Thứ Sáu'
        WHEN 6 THEN 'Thứ Bảy'
        WHEN 7 THEN 'Chủ Nhật'
    END AS ten_thu,
    EXTRACT(WEEK FROM d::DATE)::INTEGER AS tuan,
    EXTRACT(MONTH FROM d::DATE)::INTEGER AS thang,
    CASE EXTRACT(MONTH FROM d::DATE)::INTEGER
        WHEN 1  THEN 'Tháng 1'
        WHEN 2  THEN 'Tháng 2'
        WHEN 3  THEN 'Tháng 3'
        WHEN 4  THEN 'Tháng 4'
        WHEN 5  THEN 'Tháng 5'
        WHEN 6  THEN 'Tháng 6'
        WHEN 7  THEN 'Tháng 7'
        WHEN 8  THEN 'Tháng 8'
        WHEN 9  THEN 'Tháng 9'
        WHEN 10 THEN 'Tháng 10'
        WHEN 11 THEN 'Tháng 11'
        WHEN 12 THEN 'Tháng 12'
    END AS ten_thang,
    EXTRACT(QUARTER FROM d::DATE)::INTEGER AS quy,
    EXTRACT(YEAR FROM d::DATE)::INTEGER AS nam
FROM generate_series('2024-01-01'::DATE, '2024-12-31'::DATE, '1 day'::INTERVAL) d;
-- Kết quả: 366 rows (2024 là năm nhuận)

-- ================================================================
-- 2. DIM_KHACH_HANG - Từ IDB (khach_hang + subtypes + VPDD)
-- Flatten ISA: tính loai_kh từ kh_du_lich + kh_buu_dien
-- ================================================================
INSERT INTO dim_khach_hang (ma_kh, ten_kh, loai_kh, huong_dan_vien, dia_chi_buu_dien,
                            ten_thanh_pho_kh, bang_kh, ngay_dh_dau_tien)
SELECT
    kh.ma_kh,
    kh.ten_kh,
    CASE
        WHEN dl.ma_kh IS NOT NULL AND bd.ma_kh IS NOT NULL THEN 'Cả hai'
        WHEN dl.ma_kh IS NOT NULL THEN 'Du lịch'
        WHEN bd.ma_kh IS NOT NULL THEN 'Bưu điện'
        ELSE 'Thường'
    END AS loai_kh,
    dl.huong_dan_vien,
    bd.dia_chi_buu_dien,
    vp.ten_thanh_pho,
    vp.bang,
    kh.ngay_dh_dau_tien
FROM khach_hang kh
LEFT JOIN khach_hang_du_lich dl ON kh.ma_kh = dl.ma_kh
LEFT JOIN khach_hang_buu_dien bd ON kh.ma_kh = bd.ma_kh
JOIN van_phong_dai_dien vp ON kh.ma_thanh_pho = vp.ma_thanh_pho
ORDER BY kh.ma_kh;
-- Kết quả: 30 rows
-- loai_kh: Du lịch (8), Bưu điện (8), Cả hai (4), Thường (10)

-- ================================================================
-- 3. DIM_MAT_HANG - Từ IDB (mat_hang) - Copy trực tiếp
-- ================================================================
INSERT INTO dim_mat_hang (ma_mat_hang, mo_ta, kich_co, trong_luong, gia)
SELECT ma_mat_hang, mo_ta, kich_co, trong_luong, gia
FROM mat_hang
ORDER BY ma_mat_hang;
-- Kết quả: 15 rows

-- ================================================================
-- 4. DIM_CUA_HANG - Từ IDB (cua_hang + van_phong_dai_dien)
-- Denormalize: gộp thông tin VPDD vào dimension
-- ================================================================
INSERT INTO dim_cua_hang (ma_cua_hang, so_dien_thoai, ma_thanh_pho, ten_thanh_pho, dia_chi_vp, bang)
SELECT
    ch.ma_cua_hang,
    ch.so_dien_thoai,
    vp.ma_thanh_pho,
    vp.ten_thanh_pho,
    vp.dia_chi_vp,
    vp.bang
FROM cua_hang ch
JOIN van_phong_dai_dien vp ON ch.ma_thanh_pho = vp.ma_thanh_pho
ORDER BY ch.ma_cua_hang;
-- Kết quả: 20 rows

-- ================================================================
-- 5. FACT_BAN_HANG - Từ IDB (don_dat_hang + mat_hang_duoc_dat)
-- Grain: 1 mặt hàng × 1 đơn hàng
-- cua_hang_key: CH đầu tiên tại TP KH có lưu kho MH đó
-- ================================================================
INSERT INTO fact_ban_hang (thoi_gian_key, khach_hang_key, mat_hang_key, cua_hang_key,
                           ma_don, so_luong_dat, gia_dat, doanh_thu)
SELECT
    dt.thoi_gian_key,
    dk.khach_hang_key,
    dm.mat_hang_key,
    dc.cua_hang_key,
    dh.ma_don,
    mdd.so_luong_dat,
    mdd.gia_dat,
    (mdd.so_luong_dat * mdd.gia_dat) AS doanh_thu
FROM mat_hang_duoc_dat mdd
JOIN don_dat_hang dh ON mdd.ma_don = dh.ma_don
JOIN dim_thoi_gian dt ON dh.ngay_dat_hang = dt.ngay
JOIN dim_khach_hang dk ON dh.ma_kh = dk.ma_kh
JOIN dim_mat_hang dm ON mdd.ma_mat_hang = dm.ma_mat_hang
JOIN khach_hang kh ON dh.ma_kh = kh.ma_kh
JOIN dim_cua_hang dc ON dc.ma_cua_hang = (
    SELECT ch2.ma_cua_hang
    FROM cua_hang ch2
    JOIN mat_hang_luu_tru mlt ON ch2.ma_cua_hang = mlt.ma_cua_hang
    WHERE ch2.ma_thanh_pho = kh.ma_thanh_pho
      AND mlt.ma_mat_hang = mdd.ma_mat_hang
    ORDER BY ch2.ma_cua_hang
    LIMIT 1
)
ORDER BY dh.ma_don, mdd.ma_mat_hang;
-- Kết quả: ~110 rows

-- ================================================================
-- 6. FACT_TON_KHO - Từ IDB (mat_hang_luu_tru)
-- Snapshot tại ngày 2024-12-31
-- ================================================================
INSERT INTO fact_ton_kho (thoi_gian_key, mat_hang_key, cua_hang_key, so_luong_kho)
SELECT
    dt.thoi_gian_key,
    dm.mat_hang_key,
    dc.cua_hang_key,
    mlt.so_luong_kho
FROM mat_hang_luu_tru mlt
JOIN dim_mat_hang dm ON mlt.ma_mat_hang = dm.ma_mat_hang
JOIN dim_cua_hang dc ON mlt.ma_cua_hang = dc.ma_cua_hang
CROSS JOIN (SELECT thoi_gian_key FROM dim_thoi_gian WHERE ngay = '2024-12-31') dt
ORDER BY dc.ma_cua_hang, dm.ma_mat_hang;
-- Kết quả: ~100 rows

-- ================================================================
-- KIỂM TRA DỮ LIỆU
-- ================================================================

-- Đếm số records mỗi bảng
-- SELECT 'dim_thoi_gian' AS bang, COUNT(*) AS so_dong FROM dim_thoi_gian
-- UNION ALL SELECT 'dim_khach_hang', COUNT(*) FROM dim_khach_hang
-- UNION ALL SELECT 'dim_mat_hang', COUNT(*) FROM dim_mat_hang
-- UNION ALL SELECT 'dim_cua_hang', COUNT(*) FROM dim_cua_hang
-- UNION ALL SELECT 'fact_ban_hang', COUNT(*) FROM fact_ban_hang
-- UNION ALL SELECT 'fact_ton_kho', COUNT(*) FROM fact_ton_kho;

-- Kiểm tra phân bổ loại KH (cho truy vấn Q9)
-- SELECT loai_kh, COUNT(*) FROM dim_khach_hang GROUP BY loai_kh ORDER BY loai_kh;

-- Kiểm tra tổng doanh thu theo tháng
-- SELECT dt.ten_thang, dt.nam, SUM(f.doanh_thu) AS tong_doanh_thu
-- FROM fact_ban_hang f
-- JOIN dim_thoi_gian dt ON f.thoi_gian_key = dt.thoi_gian_key
-- GROUP BY dt.thang, dt.ten_thang, dt.nam
-- ORDER BY dt.thang;

-- Kiểm tra tồn kho theo TP
-- SELECT dc.ten_thanh_pho, SUM(f.so_luong_kho) AS tong_ton_kho
-- FROM fact_ton_kho f
-- JOIN dim_cua_hang dc ON f.cua_hang_key = dc.cua_hang_key
-- GROUP BY dc.ten_thanh_pho
-- ORDER BY tong_ton_kho DESC;
