# Metadata – Kho dữ liệu INT1422

## 1. Thông tin chung

| Thuộc tính | Giá trị |
|-----------|---------|
| **Tên kho** | INT1422 Data Warehouse |
| **Mô tả** | Kho dữ liệu cho hệ thống xử lý đặt hàng |
| **CSDL** | PostgreSQL 16 |
| **Schema mô hình** | Galaxy Schema (Fact Constellation) |
| **Số Fact tables** | 2 |
| **Số Dimension tables** | 4 |
| **Tổng records (DW)** | ~644 |
| **Nguồn dữ liệu** | IDB (9 bảng, 342 records) |
| **Tần suất refresh** | Batch (cuối ngày) |
| **Ngày tạo** | 2026-03-16 |

---

## 2. Metadata bảng Fact

### 2.1 fact_ban_hang

| Thuộc tính | Giá trị |
|-----------|---------|
| Mô tả | Ghi nhận giao dịch bán hàng (chi tiết đơn) |
| Grain | 1 mặt hàng × 1 đơn đặt hàng |
| Loại Fact | Transaction Fact |
| Số records | ~109 |
| Nguồn IDB | don_dat_hang + mat_hang_duoc_dat |

| Cột | Kiểu | Loại | Nguồn IDB | Mô tả |
|-----|------|------|-----------|-------|
| fact_ban_hang_id | SERIAL | PK | Auto | Surrogate key |
| thoi_gian_key | INT | FK-Dim | don_dat_hang.ngay_dat_hang → lookup | → dim_thoi_gian |
| khach_hang_key | INT | FK-Dim | don_dat_hang.ma_kh → lookup | → dim_khach_hang |
| mat_hang_key | INT | FK-Dim | mat_hang_duoc_dat.ma_mat_hang → lookup | → dim_mat_hang |
| cua_hang_key | INT | FK-Dim | CH tại TP KH có lưu MH → lookup | → dim_cua_hang |
| ma_don | VARCHAR(10) | DD | don_dat_hang.ma_don | Degenerate Dimension |
| so_luong_dat | INT | Measure | mat_hang_duoc_dat.so_luong_dat | Additive |
| gia_dat | DECIMAL(15,2) | Measure | mat_hang_duoc_dat.gia_dat | Semi-additive |
| doanh_thu | DECIMAL(15,2) | Measure | Computed: SL × Giá | Additive |

### 2.2 fact_ton_kho

| Thuộc tính | Giá trị |
|-----------|---------|
| Mô tả | Snapshot tồn kho tại cửa hàng |
| Grain | 1 mặt hàng × 1 cửa hàng × 1 thời điểm |
| Loại Fact | Periodic Snapshot |
| Số records | ~104 |
| Nguồn IDB | mat_hang_luu_tru |

| Cột | Kiểu | Loại | Nguồn IDB | Mô tả |
|-----|------|------|-----------|-------|
| fact_ton_kho_id | SERIAL | PK | Auto | Surrogate key |
| thoi_gian_key | INT | FK-Dim | Ngày snapshot (2024-12-31) | → dim_thoi_gian |
| mat_hang_key | INT | FK-Dim | mat_hang_luu_tru.ma_mat_hang → lookup | → dim_mat_hang |
| cua_hang_key | INT | FK-Dim | mat_hang_luu_tru.ma_cua_hang → lookup | → dim_cua_hang |
| so_luong_kho | INT | Measure | mat_hang_luu_tru.so_luong_kho | Semi-additive |

---

## 3. Metadata bảng Dimension

### 3.1 dim_thoi_gian

| Thuộc tính | Giá trị |
|-----------|---------|
| Mô tả | Chiều thời gian |
| Hierarchy | Ngày → Tháng → Quý → Năm |
| Số records | 366 (năm 2024) |
| Nguồn | Sinh tự động (generate_series) |
| SCD Type | N/A (static) |

| Cột | Kiểu | Nguồn | Level | Mô tả |
|-----|------|-------|-------|-------|
| thoi_gian_key | SERIAL PK | Auto | – | Surrogate key |
| ngay | DATE UNIQUE | Generated | L1 | Ngày đầy đủ |
| ngay_trong_tuan | INT | ISODOW | – | 1(T2) – 7(CN) |
| ten_thu | VARCHAR(20) | CASE | – | Tên thứ |
| tuan | INT | WEEK | L1.5 | Tuần trong năm |
| thang | INT | MONTH | L2 | Tháng (1-12) |
| ten_thang | VARCHAR(20) | CASE | L2 | Tên tháng |
| quy | INT | QUARTER | L3 | Quý (1-4) |
| nam | INT | YEAR | L4 | Năm |

### 3.2 dim_khach_hang

| Thuộc tính | Giá trị |
|-----------|---------|
| Mô tả | Chiều khách hàng (flatten ISA) |
| Hierarchy 1 | KH → Loại KH |
| Hierarchy 2 | KH → TP → Bang |
| Số records | 30 |
| Nguồn IDB | khach_hang + kh_du_lich + kh_buu_dien + van_phong_dai_dien |
| SCD Type | Type 1 (overwrite) |

| Cột | Kiểu | Nguồn IDB | Biến đổi | Level |
|-----|------|-----------|---------|-------|
| khach_hang_key | SERIAL PK | Auto | – | – |
| ma_kh | VARCHAR(10) | khach_hang.ma_kh | Copy | L1 |
| ten_kh | VARCHAR(100) | khach_hang.ten_kh | Copy | L1 |
| loai_kh | VARCHAR(20) | JOIN logic | CASE ISA→flatten | L2 (H1) |
| huong_dan_vien | VARCHAR(100) | kh_du_lich.huong_dan_vien | LEFT JOIN | L1 |
| dia_chi_buu_dien | VARCHAR(200) | kh_buu_dien.dia_chi_buu_dien | LEFT JOIN | L1 |
| ten_thanh_pho_kh | VARCHAR(100) | van_phong_dai_dien.ten_thanh_pho | JOIN | L2 (H2) |
| bang_kh | VARCHAR(100) | van_phong_dai_dien.bang | JOIN | L3 (H2) |
| ngay_dh_dau_tien | DATE | khach_hang.ngay_dh_dau_tien | Copy | L1 |

### 3.3 dim_mat_hang

| Thuộc tính | Giá trị |
|-----------|---------|
| Mô tả | Chiều mặt hàng |
| Hierarchy | Flat (1 cấp) |
| Số records | 15 |
| Nguồn IDB | mat_hang |
| SCD Type | Type 1 |

| Cột | Kiểu | Nguồn IDB | Biến đổi |
|-----|------|-----------|---------|
| mat_hang_key | SERIAL PK | Auto | – |
| ma_mat_hang | VARCHAR(10) | mat_hang.ma_mat_hang | Copy |
| mo_ta | VARCHAR(200) | mat_hang.mo_ta | Copy |
| kich_co | VARCHAR(50) | mat_hang.kich_co | Copy |
| trong_luong | DECIMAL(10,2) | mat_hang.trong_luong | Copy |
| gia | DECIMAL(15,2) | mat_hang.gia | Copy |

### 3.4 dim_cua_hang

| Thuộc tính | Giá trị |
|-----------|---------|
| Mô tả | Chiều cửa hàng (denormalize VPĐD) |
| Hierarchy | CH → TP → Bang |
| Số records | 20 |
| Nguồn IDB | cua_hang + van_phong_dai_dien |
| SCD Type | Type 1 |

| Cột | Kiểu | Nguồn IDB | Biến đổi | Level |
|-----|------|-----------|---------|-------|
| cua_hang_key | SERIAL PK | Auto | – | – |
| ma_cua_hang | VARCHAR(10) | cua_hang.ma_cua_hang | Copy | L1 |
| so_dien_thoai | VARCHAR(20) | cua_hang.so_dien_thoai | Copy | L1 |
| ma_thanh_pho | VARCHAR(10) | van_phong_dai_dien.ma_thanh_pho | JOIN | L2 |
| ten_thanh_pho | VARCHAR(100) | van_phong_dai_dien.ten_thanh_pho | JOIN | L2 |
| dia_chi_vp | VARCHAR(200) | van_phong_dai_dien.dia_chi_vp | JOIN | L2 |
| bang | VARCHAR(100) | van_phong_dai_dien.bang | JOIN | L3 |

---

## 4. Metadata Materialized Views (Cube)

| View | Nguồn | Dimensions | Measures | Mục đích |
|------|-------|-----------|---------|---------|
| mv_cube_ban_hang | fact_ban_hang + 4 dims | TG×KH×MH×CH | tong_so_luong, tong_doanh_thu, gia_dat_tb | OLAP bán hàng |
| mv_cube_ton_kho | fact_ton_kho + 2 dims | MH×CH | tong_ton_kho | OLAP tồn kho |
| mv_cube_khach_hang | dim_khach_hang | KH×Loại×TP | – | OLAP khách hàng |

---

## 5. Metadata ETL

| Bảng đích | Nguồn | Phép biến đổi chính | Tần suất |
|-----------|-------|---------------------|---------|
| dim_thoi_gian | generate_series | Tự sinh ngày + tính cột dẫn xuất | 1 lần/năm |
| dim_khach_hang | 4 bảng IDB | LEFT JOIN ISA + CASE flatten | Khi có KH mới |
| dim_mat_hang | mat_hang | Copy trực tiếp | Khi có MH mới |
| dim_cua_hang | 2 bảng IDB | JOIN denormalize VPĐD | Khi có CH mới |
| fact_ban_hang | 2 bảng IDB | JOIN + lookup keys + compute doanh_thu | Cuối ngày |
| fact_ton_kho | mat_hang_luu_tru | JOIN + lookup keys | Cuối ngày |
