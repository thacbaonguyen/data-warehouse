-- ================================================================
-- OLAP Cube Queries & Operations
-- Bài tập lớn Kho dữ liệu - INT1422
-- ================================================================
-- Gồm:
--   Phần A: Materialized Views (tính sẵn cube)
--   Phần B: 9 truy vấn OLAP theo đề bài
--   Phần C: Demo 4 phép toán OLAP
-- ================================================================

-- ================================================================
-- PHẦN A: MATERIALIZED VIEWS (Tính sẵn Cube)
-- ================================================================

-- A1. Cube Bán hàng – ROLLUP theo thời gian + địa lý
DROP MATERIALIZED VIEW IF EXISTS mv_cube_ban_hang;
CREATE MATERIALIZED VIEW mv_cube_ban_hang AS
SELECT
    dt.nam, dt.quy, dt.thang, dt.ten_thang,
    dc.bang, dc.ten_thanh_pho, dc.ma_cua_hang, dc.so_dien_thoai,
    dk.ma_kh, dk.ten_kh, dk.loai_kh, dk.ten_thanh_pho_kh, dk.bang_kh,
    dm.ma_mat_hang, dm.mo_ta, dm.kich_co, dm.trong_luong, dm.gia AS gia_goc,
    f.ma_don,
    SUM(f.so_luong_dat) AS tong_so_luong,
    SUM(f.doanh_thu) AS tong_doanh_thu,
    AVG(f.gia_dat) AS gia_dat_tb,
    COUNT(*) AS so_dong
FROM fact_ban_hang f
JOIN dim_thoi_gian dt ON f.thoi_gian_key = dt.thoi_gian_key
JOIN dim_khach_hang dk ON f.khach_hang_key = dk.khach_hang_key
JOIN dim_mat_hang dm ON f.mat_hang_key = dm.mat_hang_key
JOIN dim_cua_hang dc ON f.cua_hang_key = dc.cua_hang_key
GROUP BY
    dt.nam, dt.quy, dt.thang, dt.ten_thang,
    dc.bang, dc.ten_thanh_pho, dc.ma_cua_hang, dc.so_dien_thoai,
    dk.ma_kh, dk.ten_kh, dk.loai_kh, dk.ten_thanh_pho_kh, dk.bang_kh,
    dm.ma_mat_hang, dm.mo_ta, dm.kich_co, dm.trong_luong, dm.gia,
    f.ma_don;

-- A2. Cube Tồn kho – ROLLUP theo địa lý
DROP MATERIALIZED VIEW IF EXISTS mv_cube_ton_kho;
CREATE MATERIALIZED VIEW mv_cube_ton_kho AS
SELECT
    dc.bang, dc.ten_thanh_pho, dc.ma_cua_hang, dc.so_dien_thoai,
    dc.dia_chi_vp,
    dm.ma_mat_hang, dm.mo_ta, dm.kich_co, dm.trong_luong, dm.gia,
    SUM(f.so_luong_kho) AS tong_ton_kho,
    COUNT(*) AS so_dong
FROM fact_ton_kho f
JOIN dim_mat_hang dm ON f.mat_hang_key = dm.mat_hang_key
JOIN dim_cua_hang dc ON f.cua_hang_key = dc.cua_hang_key
GROUP BY
    dc.bang, dc.ten_thanh_pho, dc.ma_cua_hang, dc.so_dien_thoai,
    dc.dia_chi_vp,
    dm.ma_mat_hang, dm.mo_ta, dm.kich_co, dm.trong_luong, dm.gia;

-- A3. Cube Khách hàng
DROP MATERIALIZED VIEW IF EXISTS mv_cube_khach_hang;
CREATE MATERIALIZED VIEW mv_cube_khach_hang AS
SELECT
    dk.ma_kh, dk.ten_kh, dk.loai_kh,
    dk.huong_dan_vien, dk.dia_chi_buu_dien,
    dk.ten_thanh_pho_kh, dk.bang_kh,
    dk.ngay_dh_dau_tien
FROM dim_khach_hang dk;

-- ================================================================
-- PHẦN B: 9 TRUY VẤN OLAP THEO ĐỀ BÀI
-- ================================================================

-- ----------------------------------------------------------------
-- Q1: Tìm tất cả cửa hàng cùng với thành phố, bang, SĐT,
--     mô tả, kích cỡ, trọng lượng và đơn giá của tất cả
--     các mặt hàng được bán ở kho đó.
-- Phép OLAP: DICE (lọc CH × MH)
-- ----------------------------------------------------------------
-- Q1:
SELECT
    c.ma_cua_hang, c.ten_thanh_pho, c.bang, c.so_dien_thoai,
    c.mo_ta, c.kich_co, c.trong_luong, c.gia,
    c.tong_ton_kho
FROM mv_cube_ton_kho c
ORDER BY c.ma_cua_hang, c.ma_mat_hang;

-- ----------------------------------------------------------------
-- Q2: Tìm tất cả đơn đặt hàng với tên khách hàng và ngày đặt hàng
--     được thực hiện bởi khách hàng đó.
-- Phép OLAP: SLICE (lọc theo KH)
-- ----------------------------------------------------------------
-- Q2:
SELECT DISTINCT
    c.ma_don, c.ten_kh, dt.ngay AS ngay_dat_hang
FROM mv_cube_ban_hang c
JOIN dim_thoi_gian dt ON c.nam = dt.nam AND c.thang = dt.thang
JOIN fact_ban_hang f ON f.ma_don = c.ma_don
JOIN dim_thoi_gian dt2 ON f.thoi_gian_key = dt2.thoi_gian_key
ORDER BY c.ten_kh, c.ma_don;

-- Q2 (phiên bản đơn giản từ fact trực tiếp):
SELECT DISTINCT
    f.ma_don, dk.ten_kh, dt.ngay AS ngay_dat_hang
FROM fact_ban_hang f
JOIN dim_khach_hang dk ON f.khach_hang_key = dk.khach_hang_key
JOIN dim_thoi_gian dt ON f.thoi_gian_key = dt.thoi_gian_key
ORDER BY dk.ten_kh, f.ma_don;

-- ----------------------------------------------------------------
-- Q3: Tìm tất cả cửa hàng cùng với tên thành phố và SĐT
--     mà có bán các mặt hàng được đặt bởi một KH nào đó.
-- Phép OLAP: DICE (KH × MH × CH)
-- ----------------------------------------------------------------
-- Q3: Ví dụ cho KH 'Nguyễn Văn An' (KH01)
SELECT DISTINCT
    c.ma_cua_hang, c.ten_thanh_pho, c.so_dien_thoai
FROM mv_cube_ban_hang c
WHERE c.ten_kh = 'Nguyễn Văn An'
ORDER BY c.ma_cua_hang;

-- ----------------------------------------------------------------
-- Q4: Tìm địa chỉ VPĐD với tên TP, bang của tất cả CH lưu kho
--     một MH nào đó với số lượng trên mức cụ thể.
-- Phép OLAP: SLICE + FILTER
-- ----------------------------------------------------------------
-- Q4: Ví dụ MH01 với SL > 50
SELECT DISTINCT
    c.dia_chi_vp, c.ten_thanh_pho, c.bang,
    c.ma_cua_hang, c.tong_ton_kho
FROM mv_cube_ton_kho c
WHERE c.ma_mat_hang = 'MH01'
  AND c.tong_ton_kho > 50
ORDER BY c.tong_ton_kho DESC;

-- ----------------------------------------------------------------
-- Q5: Với mỗi đơn đặt hàng của khách, liệt kê các MH được đặt
--     cùng với mô tả, mã CH, tên TP và các CH có bán MH đó.
-- Phép OLAP: DICE (MH × CH × ĐH)
-- ----------------------------------------------------------------
-- Q5:
SELECT
    bh.ma_don, bh.ma_mat_hang, bh.mo_ta,
    bh.ma_cua_hang AS cua_hang_phuc_vu,
    bh.ten_thanh_pho AS tp_phuc_vu,
    tk.ma_cua_hang AS cua_hang_co_ban,
    tk.ten_thanh_pho AS tp_co_ban
FROM mv_cube_ban_hang bh
JOIN mv_cube_ton_kho tk ON bh.ma_mat_hang = tk.ma_mat_hang
WHERE tk.tong_ton_kho > 0
ORDER BY bh.ma_don, bh.ma_mat_hang, tk.ma_cua_hang;

-- ----------------------------------------------------------------
-- Q6: Tìm thành phố và bang mà một KH nào đó sinh sống.
-- Phép OLAP: SLICE (lọc theo KH)
-- ----------------------------------------------------------------
-- Q6: Ví dụ KH01
SELECT
    ma_kh, ten_kh, ten_thanh_pho_kh, bang_kh
FROM mv_cube_khach_hang
WHERE ma_kh = 'KH01';

-- Q6: Tất cả KH
SELECT
    ma_kh, ten_kh, ten_thanh_pho_kh, bang_kh
FROM mv_cube_khach_hang
ORDER BY ma_kh;

-- ----------------------------------------------------------------
-- Q7: Tìm mức độ tồn kho của một MH cụ thể tại tất cả CH
--     ở một TP cụ thể nào đó.
-- Phép OLAP: DICE (MH × TP)
-- ----------------------------------------------------------------
-- Q7: Ví dụ MH01 tại Hà Nội
SELECT
    c.ma_cua_hang, c.ten_thanh_pho, c.ma_mat_hang, c.mo_ta,
    c.tong_ton_kho
FROM mv_cube_ton_kho c
WHERE c.ma_mat_hang = 'MH01'
  AND c.ten_thanh_pho = 'Hà Nội'
ORDER BY c.ma_cua_hang;

-- ----------------------------------------------------------------
-- Q8: Tìm các MH, số lượng đặt, KH, CH và TP của một đơn hàng.
-- Phép OLAP: DRILL DOWN (chi tiết 1 đơn)
-- ----------------------------------------------------------------
-- Q8: Ví dụ đơn DH01
SELECT
    c.ma_don, c.ma_mat_hang, c.mo_ta,
    c.tong_so_luong AS so_luong_dat,
    c.tong_doanh_thu AS doanh_thu,
    c.ten_kh, c.ma_cua_hang, c.ten_thanh_pho
FROM mv_cube_ban_hang c
WHERE c.ma_don = 'DH01'
ORDER BY c.ma_mat_hang;

-- ----------------------------------------------------------------
-- Q9: Tìm các KH du lịch, KH bưu điện và KH thuộc cả hai loại.
-- Phép OLAP: SLICE (theo loại KH)
-- ----------------------------------------------------------------
-- Q9a: KH Du lịch
SELECT ma_kh, ten_kh, loai_kh, huong_dan_vien
FROM mv_cube_khach_hang
WHERE loai_kh IN ('Du lịch', 'Cả hai')
ORDER BY ma_kh;

-- Q9b: KH Bưu điện
SELECT ma_kh, ten_kh, loai_kh, dia_chi_buu_dien
FROM mv_cube_khach_hang
WHERE loai_kh IN ('Bưu điện', 'Cả hai')
ORDER BY ma_kh;

-- Q9c: KH thuộc cả hai loại
SELECT ma_kh, ten_kh, huong_dan_vien, dia_chi_buu_dien
FROM mv_cube_khach_hang
WHERE loai_kh = 'Cả hai'
ORDER BY ma_kh;

-- Q9d: Thống kê theo loại
SELECT loai_kh, COUNT(*) AS so_luong
FROM mv_cube_khach_hang
GROUP BY loai_kh
ORDER BY loai_kh;


-- ================================================================
-- PHẦN C: DEMO 4 PHÉP TOÁN OLAP
-- ================================================================

-- ----------------------------------------------------------------
-- C1. DRILL DOWN: Doanh thu Năm → Quý → Tháng
-- Đi từ tổng hợp xuống chi tiết
-- ----------------------------------------------------------------

-- Level 1: Doanh thu theo NĂM
SELECT nam, SUM(tong_doanh_thu) AS doanh_thu_nam
FROM mv_cube_ban_hang
GROUP BY nam
ORDER BY nam;

-- Level 2: DRILL DOWN → QUÝ (từ năm 2024)
SELECT nam, quy, SUM(tong_doanh_thu) AS doanh_thu_quy
FROM mv_cube_ban_hang
WHERE nam = 2024
GROUP BY nam, quy
ORDER BY quy;

-- Level 3: DRILL DOWN → THÁNG (từ quý 1)
SELECT nam, quy, thang, ten_thang, SUM(tong_doanh_thu) AS doanh_thu_thang
FROM mv_cube_ban_hang
WHERE nam = 2024 AND quy = 1
GROUP BY nam, quy, thang, ten_thang
ORDER BY thang;

-- ----------------------------------------------------------------
-- C2. ROLL UP: Tồn kho Cửa hàng → Thành phố → Bang → Tổng
-- Đi từ chi tiết lên tổng hợp
-- ----------------------------------------------------------------

-- Level 1: Tồn kho theo CỬA HÀNG
SELECT ma_cua_hang, ten_thanh_pho, bang, SUM(tong_ton_kho) AS ton_kho
FROM mv_cube_ton_kho
GROUP BY ma_cua_hang, ten_thanh_pho, bang
ORDER BY ma_cua_hang;

-- Level 2: ROLL UP → THÀNH PHỐ
SELECT ten_thanh_pho, bang, SUM(tong_ton_kho) AS ton_kho_tp
FROM mv_cube_ton_kho
GROUP BY ten_thanh_pho, bang
ORDER BY ton_kho_tp DESC;

-- Level 3: ROLL UP → BANG
SELECT bang, SUM(tong_ton_kho) AS ton_kho_bang
FROM mv_cube_ton_kho
GROUP BY bang
ORDER BY ton_kho_bang DESC;

-- Level 4: ROLL UP → TỔNG
SELECT SUM(tong_ton_kho) AS tong_ton_kho_toan_he_thong
FROM mv_cube_ton_kho;

-- ----------------------------------------------------------------
-- C3. SLICE: Lọc theo 1 dimension
-- Cắt cube theo 1 chiều, giữ nguyên các chiều còn lại
-- ----------------------------------------------------------------

-- Slice theo Loại KH = 'Du lịch'
SELECT ten_thanh_pho, thang, ten_thang,
       SUM(tong_doanh_thu) AS doanh_thu
FROM mv_cube_ban_hang
WHERE loai_kh = 'Du lịch'
GROUP BY ten_thanh_pho, thang, ten_thang
ORDER BY ten_thanh_pho, thang;

-- Slice theo Thành phố = 'Hà Nội'
SELECT ma_mat_hang, mo_ta, thang, ten_thang,
       SUM(tong_so_luong) AS so_luong, SUM(tong_doanh_thu) AS doanh_thu
FROM mv_cube_ban_hang
WHERE ten_thanh_pho = 'Hà Nội'
GROUP BY ma_mat_hang, mo_ta, thang, ten_thang
ORDER BY thang, ma_mat_hang;

-- ----------------------------------------------------------------
-- C4. DICE: Lọc theo nhiều dimensions
-- Cắt cube theo nhiều chiều cùng lúc
-- ----------------------------------------------------------------

-- Dice: KH ở Hà Nội + MH giá > 500K + Quý 1
SELECT
    c.ten_kh, c.ma_mat_hang, c.mo_ta, c.gia_goc,
    c.thang, c.ten_thang,
    c.tong_so_luong, c.tong_doanh_thu
FROM mv_cube_ban_hang c
WHERE c.ten_thanh_pho_kh = 'Hà Nội'
  AND c.gia_goc > 500000
  AND c.quy = 1
ORDER BY c.ten_kh, c.thang;

-- ----------------------------------------------------------------
-- C5. PIVOT: Xoay chiều (chuyển dòng thành cột)
-- ----------------------------------------------------------------

-- Pivot: Doanh thu theo Tháng (cột) × Bang (dòng)
SELECT
    bang,
    SUM(CASE WHEN thang = 1 THEN tong_doanh_thu ELSE 0 END) AS "T1",
    SUM(CASE WHEN thang = 2 THEN tong_doanh_thu ELSE 0 END) AS "T2",
    SUM(CASE WHEN thang = 3 THEN tong_doanh_thu ELSE 0 END) AS "T3",
    SUM(CASE WHEN thang = 4 THEN tong_doanh_thu ELSE 0 END) AS "T4",
    SUM(CASE WHEN thang = 5 THEN tong_doanh_thu ELSE 0 END) AS "T5",
    SUM(CASE WHEN thang = 6 THEN tong_doanh_thu ELSE 0 END) AS "T6",
    SUM(CASE WHEN thang = 7 THEN tong_doanh_thu ELSE 0 END) AS "T7",
    SUM(CASE WHEN thang = 8 THEN tong_doanh_thu ELSE 0 END) AS "T8",
    SUM(CASE WHEN thang = 9 THEN tong_doanh_thu ELSE 0 END) AS "T9",
    SUM(CASE WHEN thang = 10 THEN tong_doanh_thu ELSE 0 END) AS "T10",
    SUM(CASE WHEN thang = 11 THEN tong_doanh_thu ELSE 0 END) AS "T11",
    SUM(CASE WHEN thang = 12 THEN tong_doanh_thu ELSE 0 END) AS "T12",
    SUM(tong_doanh_thu) AS "Tổng"
FROM mv_cube_ban_hang
GROUP BY bang
ORDER BY bang;
