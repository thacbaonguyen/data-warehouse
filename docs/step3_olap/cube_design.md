# Thiết kế Cube OLAP

## 1. Tổng quan

Thiết kế 3 Cube OLAP dựa trên 2 Fact tables và 4 Dimension tables, phục vụ 9 truy vấn OLAP yêu cầu.

---

## 2. Cube 1: Cube Bán hàng (Sales Cube)

### Cấu trúc

| Thành phần | Chi tiết |
|-----------|---------|
| **Fact** | fact_ban_hang |
| **Dimensions** | dim_thoi_gian × dim_khach_hang × dim_mat_hang × dim_cua_hang |
| **Measures** | SUM(so_luong_dat), SUM(doanh_thu), AVG(gia_dat), COUNT(*) |
| **Grain** | 1 mặt hàng × 1 đơn hàng |

### Các khối tổng hợp (Aggregation)

| Khối | Group By | Measure | Phục vụ |
|------|---------|---------|---------|
| Doanh thu theo Tháng | thang, nam | SUM(doanh_thu) | Roll Up thời gian |
| Doanh thu theo Quý | quy, nam | SUM(doanh_thu) | Roll Up thời gian |
| Doanh thu theo Năm | nam | SUM(doanh_thu) | Roll Up thời gian |
| Doanh thu theo TP | ten_thanh_pho | SUM(doanh_thu) | Roll Up địa lý |
| Doanh thu theo Bang | bang | SUM(doanh_thu) | Roll Up địa lý |
| Doanh thu theo Loại KH | loai_kh | SUM(doanh_thu) | Slice loại KH |
| Doanh thu theo MH | ma_mat_hang, mo_ta | SUM(doanh_thu), SUM(so_luong_dat) | Dice mặt hàng |

### Truy vấn phục vụ: Q2, Q3, Q5, Q8

---

## 3. Cube 2: Cube Tồn kho (Inventory Cube)

### Cấu trúc

| Thành phần | Chi tiết |
|-----------|---------|
| **Fact** | fact_ton_kho |
| **Dimensions** | dim_thoi_gian × dim_mat_hang × dim_cua_hang |
| **Measures** | SUM(so_luong_kho), AVG(so_luong_kho), COUNT(*) |
| **Grain** | 1 mặt hàng × 1 cửa hàng × 1 thời điểm |

### Các khối tổng hợp

| Khối | Group By | Measure | Phục vụ |
|------|---------|---------|---------|
| Tồn kho theo CH | ma_cua_hang | SUM(so_luong_kho) | Base level |
| Tồn kho theo TP | ten_thanh_pho | SUM(so_luong_kho) | Roll Up TP |
| Tồn kho theo Bang | bang | SUM(so_luong_kho) | Roll Up Bang |
| Tồn kho theo MH | ma_mat_hang, mo_ta | SUM(so_luong_kho) | Slice MH |
| Tồn kho MH × TP | ma_mat_hang, ten_thanh_pho | SUM(so_luong_kho) | Dice MH+TP |

### Truy vấn phục vụ: Q1, Q4, Q7

---

## 4. Cube 3: Cube Khách hàng (Customer Cube)

### Cấu trúc

| Thành phần | Chi tiết |
|-----------|---------|
| **Fact** | dim_khach_hang (dùng dimension trực tiếp) |
| **Dimensions** | Loại KH × Thành phố × Bang |
| **Measures** | COUNT(*) |
| **Grain** | 1 khách hàng |

### Các khối tổng hợp

| Khối | Group By | Measure | Phục vụ |
|------|---------|---------|---------|
| KH theo Loại | loai_kh | COUNT(*) | Q9 |
| KH theo TP | ten_thanh_pho_kh | COUNT(*) | Q6 |
| KH theo Bang | bang_kh | COUNT(*) | Q6 Roll Up |

### Truy vấn phục vụ: Q6, Q9

---

## 5. Chiến lược tính sẵn Cube

Dùng PostgreSQL **MATERIALIZED VIEW** để tính sẵn các khối:

```sql
-- Cube Bán hàng: ROLLUP theo thời gian + địa lý
CREATE MATERIALIZED VIEW mv_cube_ban_hang AS
SELECT
    dt.nam, dt.quy, dt.thang,
    dc.bang, dc.ten_thanh_pho, dc.ma_cua_hang,
    dk.loai_kh,
    dm.ma_mat_hang, dm.mo_ta,
    SUM(f.so_luong_dat) AS tong_so_luong,
    SUM(f.doanh_thu) AS tong_doanh_thu,
    COUNT(*) AS so_dong
FROM fact_ban_hang f
JOIN dim_thoi_gian dt ON f.thoi_gian_key = dt.thoi_gian_key
JOIN dim_khach_hang dk ON f.khach_hang_key = dk.khach_hang_key
JOIN dim_mat_hang dm ON f.mat_hang_key = dm.mat_hang_key
JOIN dim_cua_hang dc ON f.cua_hang_key = dc.cua_hang_key
GROUP BY CUBE (
    (dt.nam, dt.quy, dt.thang),
    (dc.bang, dc.ten_thanh_pho, dc.ma_cua_hang),
    dk.loai_kh,
    (dm.ma_mat_hang, dm.mo_ta)
);
```

---

## 6. Mapping 9 truy vấn → Cube + OLAP Operation

| Q | Mô tả | Cube | Phép OLAP | Chi tiết |
|---|--------|------|-----------|---------|
| 1 | CH + MH bán ở kho | Tồn kho | **Dice** | Lọc theo CH × MH |
| 2 | ĐH + KH + ngày | Bán hàng | **Slice** | Lọc theo KH |
| 3 | CH bán MH cho KH | Bán hàng | **Dice** | KH × MH × CH |
| 4 | VPĐD có MH kho > ngưỡng | Tồn kho | **Slice + Filter** | Lọc MH, SL > n |
| 5 | MH đặt + CH bán | Bán hàng + Tồn kho | **Dice** | MH × CH |
| 6 | TP + Bang KH | KH | **Slice** | Lọc theo KH |
| 7 | Tồn kho MH tại TP | Tồn kho | **Dice** | MH × TP |
| 8 | Chi tiết đơn hàng | Bán hàng | **Drill Down** | Xem chi tiết 1 đơn |
| 9 | Loại KH | KH | **Slice** | Group by loai_kh |
