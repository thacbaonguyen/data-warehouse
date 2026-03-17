# ETL Mapping: IDB → Data Warehouse

## Tổng quan

Tài liệu mô tả cách ánh xạ (mapping) dữ liệu từ CSDL tích hợp (**IDB**) sang các bảng trong kho dữ liệu (**DW**).

---

## 1. dim_thoi_gian ← Sinh tự động

| DW Column | Nguồn | Cách tính |
|-----------|-------|-----------|
| thoi_gian_key | Auto | SERIAL |
| ngay | IDB: don_dat_hang.ngay_dat_hang | Lấy tất cả ngày unique + thêm ngày snapshot tồn kho |
| ngay_trong_tuan | Computed | EXTRACT(ISODOW FROM ngay) |
| ten_thu | Computed | CASE ISODOW: 1→'Thứ Hai', 2→'Thứ Ba'... |
| tuan | Computed | EXTRACT(WEEK FROM ngay) |
| thang | Computed | EXTRACT(MONTH FROM ngay) |
| ten_thang | Computed | CASE: 1→'Tháng 1', 2→'Tháng 2'... |
| quy | Computed | EXTRACT(QUARTER FROM ngay) |
| nam | Computed | EXTRACT(YEAR FROM ngay) |

**Chiến lược**: Sinh sẵn tất cả các ngày trong khoảng 2024-01-01 → 2024-12-31 (366 rows).

---

## 2. dim_khach_hang ← khach_hang + kh_du_lich + kh_buu_dien + van_phong_dai_dien

| DW Column | IDB Source | Phép biến đổi |
|-----------|-----------|---------------|
| khach_hang_key | Auto | SERIAL |
| ma_kh | khach_hang.ma_kh | Copy |
| ten_kh | khach_hang.ten_kh | Copy |
| loai_kh | kh_du_lich + kh_buu_dien | Logic dưới đây |
| huong_dan_vien | khach_hang_du_lich.huong_dan_vien | LEFT JOIN, NULL nếu ko có |
| dia_chi_buu_dien | khach_hang_buu_dien.dia_chi_buu_dien | LEFT JOIN, NULL nếu ko có |
| ten_thanh_pho_kh | van_phong_dai_dien.ten_thanh_pho | JOIN qua khach_hang.ma_thanh_pho |
| bang_kh | van_phong_dai_dien.bang | JOIN qua khach_hang.ma_thanh_pho |
| ngay_dh_dau_tien | khach_hang.ngay_dh_dau_tien | Copy |

**Logic tính `loai_kh`:**
```sql
CASE
    WHEN dl.ma_kh IS NOT NULL AND bd.ma_kh IS NOT NULL THEN 'Cả hai'
    WHEN dl.ma_kh IS NOT NULL THEN 'Du lịch'
    WHEN bd.ma_kh IS NOT NULL THEN 'Bưu điện'
    ELSE 'Thường'
END
```

**SQL trích xuất:**
```sql
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
JOIN van_phong_dai_dien vp ON kh.ma_thanh_pho = vp.ma_thanh_pho;
```

---

## 3. dim_mat_hang ← mat_hang

| DW Column | IDB Source | Phép biến đổi |
|-----------|-----------|---------------|
| mat_hang_key | Auto | SERIAL |
| ma_mat_hang | mat_hang.ma_mat_hang | Copy |
| mo_ta | mat_hang.mo_ta | Copy |
| kich_co | mat_hang.kich_co | Copy |
| trong_luong | mat_hang.trong_luong | Copy |
| gia | mat_hang.gia | Copy |

**SQL trích xuất:**
```sql
INSERT INTO dim_mat_hang (ma_mat_hang, mo_ta, kich_co, trong_luong, gia)
SELECT ma_mat_hang, mo_ta, kich_co, trong_luong, gia
FROM mat_hang;
```

---

## 4. dim_cua_hang ← cua_hang + van_phong_dai_dien

| DW Column | IDB Source | Phép biến đổi |
|-----------|-----------|---------------|
| cua_hang_key | Auto | SERIAL |
| ma_cua_hang | cua_hang.ma_cua_hang | Copy |
| so_dien_thoai | cua_hang.so_dien_thoai | Copy |
| ma_thanh_pho | van_phong_dai_dien.ma_thanh_pho | JOIN |
| ten_thanh_pho | van_phong_dai_dien.ten_thanh_pho | JOIN (denormalize) |
| dia_chi_vp | van_phong_dai_dien.dia_chi_vp | JOIN (denormalize) |
| bang | van_phong_dai_dien.bang | JOIN (denormalize) |

**SQL trích xuất:**
```sql
INSERT INTO dim_cua_hang (ma_cua_hang, so_dien_thoai, ma_thanh_pho, ten_thanh_pho, dia_chi_vp, bang)
SELECT
    ch.ma_cua_hang,
    ch.so_dien_thoai,
    vp.ma_thanh_pho,
    vp.ten_thanh_pho,
    vp.dia_chi_vp,
    vp.bang
FROM cua_hang ch
JOIN van_phong_dai_dien vp ON ch.ma_thanh_pho = vp.ma_thanh_pho;
```

---

## 5. fact_ban_hang ← don_dat_hang + mat_hang_duoc_dat

| DW Column | IDB Source | Phép biến đổi |
|-----------|-----------|---------------|
| thoi_gian_key | dim_thoi_gian | LOOKUP bằng don_dat_hang.ngay_dat_hang |
| khach_hang_key | dim_khach_hang | LOOKUP bằng don_dat_hang.ma_kh |
| mat_hang_key | dim_mat_hang | LOOKUP bằng mat_hang_duoc_dat.ma_mat_hang |
| cua_hang_key | dim_cua_hang | LOOKUP: CH tại TP của KH (ưu tiên CH đầu tiên) |
| ma_don | don_dat_hang.ma_don | Copy (Degenerate Dimension) |
| so_luong_dat | mat_hang_duoc_dat.so_luong_dat | Copy |
| gia_dat | mat_hang_duoc_dat.gia_dat | Copy |
| doanh_thu | Computed | so_luong_dat × gia_dat |

**Lưu ý về `cua_hang_key`**: Chọn cửa hàng phục vụ đơn = CH đầu tiên (theo mã) tại TP sinh sống của KH có lưu kho MH đó.

**SQL trích xuất:**
```sql
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
    mdd.so_luong_dat * mdd.gia_dat AS doanh_thu
FROM mat_hang_duoc_dat mdd
JOIN don_dat_hang dh ON mdd.ma_don = dh.ma_don
JOIN dim_thoi_gian dt ON dh.ngay_dat_hang = dt.ngay
JOIN dim_khach_hang dk ON dh.ma_kh = dk.ma_kh
JOIN dim_mat_hang dm ON mdd.ma_mat_hang = dm.ma_mat_hang
JOIN khach_hang kh ON dh.ma_kh = kh.ma_kh
JOIN dim_cua_hang dc ON dc.ma_cua_hang = (
    SELECT ch.ma_cua_hang
    FROM cua_hang ch
    JOIN mat_hang_luu_tru mlt ON ch.ma_cua_hang = mlt.ma_cua_hang
    WHERE ch.ma_thanh_pho = kh.ma_thanh_pho
      AND mlt.ma_mat_hang = mdd.ma_mat_hang
    ORDER BY ch.ma_cua_hang
    LIMIT 1
);
```

---

## 6. fact_ton_kho ← mat_hang_luu_tru

| DW Column | IDB Source | Phép biến đổi |
|-----------|-----------|---------------|
| thoi_gian_key | dim_thoi_gian | LOOKUP (dùng ngày snapshot cố định) |
| mat_hang_key | dim_mat_hang | LOOKUP bằng ma_mat_hang |
| cua_hang_key | dim_cua_hang | LOOKUP bằng ma_cua_hang |
| so_luong_kho | mat_hang_luu_tru.so_luong_kho | Copy |

**SQL trích xuất:**
```sql
INSERT INTO fact_ton_kho (thoi_gian_key, mat_hang_key, cua_hang_key, so_luong_kho)
SELECT
    dt.thoi_gian_key,
    dm.mat_hang_key,
    dc.cua_hang_key,
    mlt.so_luong_kho
FROM mat_hang_luu_tru mlt
JOIN dim_mat_hang dm ON mlt.ma_mat_hang = dm.ma_mat_hang
JOIN dim_cua_hang dc ON mlt.ma_cua_hang = dc.ma_cua_hang
CROSS JOIN (SELECT thoi_gian_key FROM dim_thoi_gian WHERE ngay = '2024-12-31') dt;
```

---

## Tóm tắt luồng ETL

```
IDB                           DW
─────────────────────────────────────────────
van_phong_dai_dien ──┬──→ dim_cua_hang
cua_hang ────────────┘
                     └──→ dim_khach_hang (TP, Bang)
khach_hang ──────────┬──→ dim_khach_hang
kh_du_lich ──────────┤
kh_buu_dien ─────────┘
mat_hang ────────────────→ dim_mat_hang
(sinh tự động) ──────────→ dim_thoi_gian

don_dat_hang ────────┬──→ fact_ban_hang
mat_hang_duoc_dat ───┘
mat_hang_luu_tru ────────→ fact_ton_kho
```
