# Hướng dẫn Superset – Step by Step

> **URL**: http://localhost:8088 | **Login**: admin / admin
> **Database đã kết nối**: int1422_idb (PostgreSQL)

---

## PHẦN 1: TẠO DATASETS

### 1.1 Tạo Dataset `mv_cube_ban_hang`

1. Menu trên → **Data** → **Datasets**
2. Click **+ Dataset** (góc phải)
3. Chọn:
   - Database: **int1422_idb**
   - Schema: **public**
   - Table: **mv_cube_ban_hang**
4. Click **Create Dataset and Create Chart** (hoặc **Add**)
5. Bấm **Back** nếu nó mở chart editor

### 1.2 Tạo Dataset `mv_cube_ton_kho`

- Lặp lại bước 1.1, chọn Table: **mv_cube_ton_kho**

### 1.3 Tạo Dataset `mv_cube_khach_hang`

- Lặp lại bước 1.1, chọn Table: **mv_cube_khach_hang**

### 1.4 Tạo Dataset `fact_ban_hang` (cho Q2)

- Lặp lại bước 1.1, chọn Table: **fact_ban_hang**

### 1.5 Tạo Dataset `dim_khach_hang`

- Lặp lại bước 1.1, chọn Table: **dim_khach_hang**

### 1.6 Tạo Dataset `dim_thoi_gian`

- Lặp lại bước 1.1, chọn Table: **dim_thoi_gian**

> **Tổng: 6 datasets**

---

## PHẦN 2: TẠO 9 CHARTS TRUY VẤN OLAP

> Tất cả 9 truy vấn tạo bằng **SQL Lab** → **Save as Chart**

### Cách chung:

1. Menu trên → **SQL** → **SQL Lab**
2. Chọn Database: **int1422_idb**, Schema: **public**
3. Paste SQL vào editor
4. Click **Run** (▶️) → xem kết quả
5. Click **Save** → **Save as new** → đặt tên → chọn Dashboard: "**INT1422 OLAP**" (tạo mới nếu chưa có)

---

### Q1: Cửa hàng + MH bán ở kho

**SQL:**
```sql
SELECT
    c.ma_cua_hang AS "Mã CH",
    c.ten_thanh_pho AS "Thành phố",
    c.bang AS "Bang",
    c.so_dien_thoai AS "SĐT",
    c.mo_ta AS "Mặt hàng",
    c.kich_co AS "Kích cỡ",
    c.trong_luong AS "Trọng lượng",
    c.gia AS "Đơn giá",
    c.tong_ton_kho AS "SL Kho"
FROM mv_cube_ton_kho c
ORDER BY c.ma_cua_hang, c.ma_mat_hang
```

- **Save as**: `Q1 - Cửa hàng & Mặt hàng kho`
- **Add to Dashboard**: `INT1422 OLAP`

---

### Q2: Đơn hàng + KH + Ngày đặt

**SQL:**
```sql
SELECT DISTINCT
    f.ma_don AS "Mã đơn",
    dk.ten_kh AS "Khách hàng",
    dt.ngay AS "Ngày đặt hàng"
FROM fact_ban_hang f
JOIN dim_khach_hang dk ON f.khach_hang_key = dk.khach_hang_key
JOIN dim_thoi_gian dt ON f.thoi_gian_key = dt.thoi_gian_key
ORDER BY dk.ten_kh, f.ma_don
```

- **Save as**: `Q2 - Đơn hàng & Khách hàng`

---

### Q3: CH bán MH đặt bởi KH

**SQL:**
```sql
SELECT DISTINCT
    c.ma_cua_hang AS "Mã CH",
    c.ten_thanh_pho AS "Thành phố",
    c.so_dien_thoai AS "SĐT",
    c.ten_kh AS "Khách hàng"
FROM mv_cube_ban_hang c
ORDER BY c.ten_kh, c.ma_cua_hang
```

- **Save as**: `Q3 - Cửa hàng bán cho KH`

> **Tip**: Khi thêm vào Dashboard, có thể thêm Filter cho cột "Khách hàng"

---

### Q4: VPĐD có MH kho > ngưỡng

**SQL:**
```sql
SELECT DISTINCT
    c.dia_chi_vp AS "Địa chỉ VPĐD",
    c.ten_thanh_pho AS "Thành phố",
    c.bang AS "Bang",
    c.ma_cua_hang AS "Mã CH",
    c.mo_ta AS "Mặt hàng",
    c.tong_ton_kho AS "SL Kho"
FROM mv_cube_ton_kho c
WHERE c.tong_ton_kho > 50
ORDER BY c.tong_ton_kho DESC
```

- **Save as**: `Q4 - VPĐD MH kho > ngưỡng`

> **Tip**: Thay `50` bằng số khác để demo filter

---

### Q5: MH đặt + CH bán MH đó

**SQL:**
```sql
SELECT DISTINCT
    bh.ma_don AS "Mã đơn",
    bh.ma_mat_hang AS "Mã MH",
    bh.mo_ta AS "Mô tả MH",
    bh.ma_cua_hang AS "CH phục vụ",
    bh.ten_thanh_pho AS "TP phục vụ",
    tk.ma_cua_hang AS "CH có bán",
    tk.ten_thanh_pho AS "TP có bán"
FROM mv_cube_ban_hang bh
JOIN mv_cube_ton_kho tk ON bh.ma_mat_hang = tk.ma_mat_hang
WHERE tk.tong_ton_kho > 0
ORDER BY bh.ma_don, bh.ma_mat_hang, tk.ma_cua_hang
```

- **Save as**: `Q5 - MH đặt & CH bán`

---

### Q6: TP + Bang nơi KH sinh sống

**SQL:**
```sql
SELECT
    ma_kh AS "Mã KH",
    ten_kh AS "Tên KH",
    ten_thanh_pho_kh AS "Thành phố",
    bang_kh AS "Bang"
FROM mv_cube_khach_hang
ORDER BY ma_kh
```

- **Save as**: `Q6 - Địa lý Khách hàng`

---

### Q7: Tồn kho MH tại TP

**SQL:**
```sql
SELECT
    c.ma_cua_hang AS "Mã CH",
    c.ten_thanh_pho AS "Thành phố",
    c.mo_ta AS "Mặt hàng",
    c.tong_ton_kho AS "SL Kho"
FROM mv_cube_ton_kho c
WHERE c.ma_mat_hang = 'MH01'
  AND c.ten_thanh_pho = 'Hà Nội'
ORDER BY c.ma_cua_hang
```

- **Save as**: `Q7 - Tồn kho MH tại TP`

> **Tip**: Thay `MH01` và `Hà Nội` để demo với giá trị khác

---

### Q8: Chi tiết 1 đơn hàng

**SQL:**
```sql
SELECT
    c.ma_don AS "Mã đơn",
    c.ma_mat_hang AS "Mã MH",
    c.mo_ta AS "Mô tả",
    c.tong_so_luong AS "SL đặt",
    c.tong_doanh_thu AS "Doanh thu",
    c.ten_kh AS "Khách hàng",
    c.ma_cua_hang AS "Mã CH",
    c.ten_thanh_pho AS "Thành phố"
FROM mv_cube_ban_hang c
WHERE c.ma_don = 'DH01'
ORDER BY c.ma_mat_hang
```

- **Save as**: `Q8 - Chi tiết đơn hàng`

---

### Q9: Loại KH (Du lịch, Bưu điện, Cả hai)

**SQL:**
```sql
SELECT
    loai_kh AS "Loại KH",
    COUNT(*) AS "Số lượng"
FROM mv_cube_khach_hang
GROUP BY loai_kh
ORDER BY loai_kh
```

- **Save as**: `Q9 - Phân bổ loại KH`
- Sau khi save, vào Chart → đổi **Chart Type** thành **Pie Chart** để hiển thị đẹp hơn

---

## PHẦN 3: TẠO 5 CHARTS DEMO PHÉP TOÁN OLAP

> ⚠️ **Lưu ý**: Alias SQL dùng KHÔNG DẤU để tránh lỗi parse khi tạo chart

---

### 3.1 DRILL DOWN – Doanh thu Năm → Quý → Tháng

> Tạo 3 charts thể hiện quá trình "khoan sâu" từ tổng → chi tiết

#### Chart 1: Drill Down – Level Năm

**Bước 1**: SQL Lab → paste SQL → **Run**:
```sql
SELECT nam, SUM(tong_doanh_thu) AS doanh_thu
FROM mv_cube_ban_hang
GROUP BY nam ORDER BY nam
```

**Bước 2**: Click **Create chart** (nút bên dưới kết quả)

**Bước 3**: Chọn Chart Type → **Bar Chart**

**Bước 4**: Config bảng bên trái:

| Option | Chọn |
|--------|------|
| X-axis | `nam` |
| Metrics | `doanh_thu` → Aggregate: **MAX** |
| Dimensions | _(để trống)_ |

**Bước 5**: Click **Update chart** → xem preview

**Bước 6**: Click **Save** → Name: `DRILL DOWN - L1 Nam` → Dashboard: `INT1422 OLAP` → **Save & go to Dashboard** hoặc **Save**

---

#### Chart 2: Drill Down – Level Quý

**Bước 1**: SQL Lab → tab mới (+) → paste SQL → **Run**:
```sql
SELECT 'Q' || quy AS quy_label, quy, SUM(tong_doanh_thu) AS doanh_thu
FROM mv_cube_ban_hang
WHERE nam = 2024
GROUP BY quy ORDER BY quy
```

**Bước 2**: Click **Create chart**

**Bước 3**: Chart Type → **Bar Chart**

**Bước 4**: Config:

| Option | Chọn |
|--------|------|
| X-axis | `quy_label` |
| Metrics | `doanh_thu` → Aggregate: **MAX** |

**Bước 5**: **Update chart** → **Save** → Name: `DRILL DOWN - L2 Quy` → Dashboard: `INT1422 OLAP`

---

#### Chart 3: Drill Down – Level Tháng

**Bước 1**: SQL Lab → tab mới → paste SQL → **Run**:
```sql
SELECT ten_thang, thang, SUM(tong_doanh_thu) AS doanh_thu
FROM mv_cube_ban_hang
WHERE nam = 2024
GROUP BY thang, ten_thang ORDER BY thang
```

**Bước 2**: Click **Create chart**

**Bước 3**: Chart Type → **Bar Chart**

**Bước 4**: Config:

| Option | Chọn |
|--------|------|
| X-axis | `ten_thang` |
| Metrics | `doanh_thu` → Aggregate: **MAX** |

**Bước 5**: **Update chart** → **Save** → Name: `DRILL DOWN - L3 Thang` → Dashboard: `INT1422 OLAP`

> ✅ **Ý nghĩa Drill Down**: 3 chart này thể hiện quá trình khoan sâu:
> Năm (57.14M) → Quý (Q1: 18.12M, Q2: 14.87M...) → Tháng (T1: 5.46M, T2: 5.33M...)

---

### 3.2 ROLL UP – Tồn kho CH → TP → Bang → Tổng

> Tạo 4 charts thể hiện quá trình "cuộn lên" từ chi tiết → tổng

#### Chart 4: Roll Up – Level Cửa hàng

**Bước 1**: SQL Lab → tab mới → paste SQL → **Run**:
```sql
SELECT ma_cua_hang, ten_thanh_pho, bang, SUM(tong_ton_kho) AS ton_kho
FROM mv_cube_ton_kho
GROUP BY ma_cua_hang, ten_thanh_pho, bang
ORDER BY ma_cua_hang
```

**Bước 2**: Click **Create chart**

**Bước 3**: Chart Type → **Bar Chart**

**Bước 4**: Config:

| Option | Chọn |
|--------|------|
| X-axis | `ma_cua_hang` |
| Metrics | `ton_kho` → Aggregate: **MAX** |

**Bước 5**: **Update chart** → **Save** → Name: `ROLL UP - L1 Cua hang` → Dashboard: `INT1422 OLAP`

---

#### Chart 5: Roll Up – Level Thành phố

**Bước 1**: SQL Lab → tab mới → paste SQL → **Run**:
```sql
SELECT ten_thanh_pho, bang, SUM(tong_ton_kho) AS ton_kho
FROM mv_cube_ton_kho
GROUP BY ten_thanh_pho, bang
ORDER BY ton_kho DESC
```

**Bước 2**: Click **Create chart**

**Bước 3**: Chart Type → **Bar Chart**

**Bước 4**: Config:

| Option | Chọn |
|--------|------|
| X-axis | `ten_thanh_pho` |
| Metrics | `ton_kho` → Aggregate: **MAX** |

**Bước 5**: **Update chart** → **Save** → Name: `ROLL UP - L2 Thanh pho` → Dashboard: `INT1422 OLAP`

---

#### Chart 6: Roll Up – Level Bang

**Bước 1**: SQL Lab → tab mới → paste SQL → **Run**:
```sql
SELECT bang, SUM(tong_ton_kho) AS ton_kho
FROM mv_cube_ton_kho
GROUP BY bang ORDER BY ton_kho DESC
```

**Bước 2**: Click **Create chart**

**Bước 3**: Chart Type → **Bar Chart**

**Bước 4**: Config:

| Option | Chọn |
|--------|------|
| X-axis | `bang` |
| Metrics | `ton_kho` → Aggregate: **MAX** |

**Bước 5**: **Update chart** → **Save** → Name: `ROLL UP - L3 Bang` → Dashboard: `INT1422 OLAP`

---

#### Chart 7: Roll Up – Level Tổng

**Bước 1**: SQL Lab → tab mới → paste SQL → **Run**:
```sql
SELECT 'Toan he thong' AS pham_vi, SUM(tong_ton_kho) AS tong_ton_kho
FROM mv_cube_ton_kho
```

**Bước 2**: Click **Create chart**

**Bước 3**: Chart Type → giữ **Table** (vì chỉ 1 dòng, 1 số)

**Bước 4**: Không cần config gì thêm

**Bước 5**: **Update chart** → **Save** → Name: `ROLL UP - L4 Tong` → Dashboard: `INT1422 OLAP`

> ✅ **Ý nghĩa Roll Up**: 4 chart thể hiện cuộn lên:
> 20 CH → 10 TP → 3 Bang (MB:1607, MN:1718, MT:1383) → Tổng (4708)

---

### 3.3 SLICE – Cắt theo 1 chiều

> Lọc dữ liệu theo **1 dimension duy nhất**, giữ nguyên các chiều còn lại

#### Chart 8: Slice – KH Du lịch

**Bước 1**: SQL Lab → tab mới → paste SQL → **Run**:
```sql
SELECT ten_thanh_pho, ten_thang, thang, SUM(tong_doanh_thu) AS doanh_thu
FROM mv_cube_ban_hang
WHERE loai_kh = 'Du lịch'
GROUP BY ten_thanh_pho, thang, ten_thang
ORDER BY ten_thanh_pho, thang
```

**Bước 2**: Click **Create chart**

**Bước 3**: Chart Type → **Table** (hiển thị dạng bảng rõ ràng)

**Bước 4**: Không cần config thêm

**Bước 5**: **Update chart** → **Save** → Name: `SLICE - KH Du lich` → Dashboard: `INT1422 OLAP`

> ✅ **Ý nghĩa Slice**: Cắt cube bán hàng theo chiều `loai_kh = 'Du lịch'`, kết quả hiện doanh thu theo TP × Tháng chỉ của KH du lịch

---

### 3.4 DICE – Cắt theo nhiều chiều

> Lọc dữ liệu theo **nhiều dimensions cùng lúc**

#### Chart 9: Dice – KH Hà Nội + MH > 500K + Q1

**Bước 1**: SQL Lab → tab mới → paste SQL → **Run**:
```sql
SELECT ten_kh, mo_ta, gia_goc, thang, ten_thang,
       tong_so_luong, tong_doanh_thu
FROM mv_cube_ban_hang
WHERE ten_thanh_pho_kh = 'Hà Nội'
  AND gia_goc > 500000
  AND quy = 1
ORDER BY ten_kh, thang
```

**Bước 2**: Click **Create chart**

**Bước 3**: Chart Type → **Table**

**Bước 4**: Không cần config thêm

**Bước 5**: **Update chart** → **Save** → Name: `DICE - HN gia500K Q1` → Dashboard: `INT1422 OLAP`

> ✅ **Ý nghĩa Dice**: Cắt cube theo 3 chiều cùng lúc:
> - Chiều KH: TP = Hà Nội
> - Chiều MH: Giá > 500K
> - Chiều thời gian: Quý 1

---

### 3.5 PIVOT – Xoay dữ liệu (dòng ↔ cột)

> Chuyển giá trị dòng thành cột để tạo bảng chéo

#### Chart 10: Pivot – Doanh thu Bang × Tháng

**Bước 1**: SQL Lab → tab mới → paste SQL → **Run**:
```sql
SELECT
    bang,
    SUM(CASE WHEN thang = 1 THEN tong_doanh_thu ELSE 0 END) AS t1,
    SUM(CASE WHEN thang = 2 THEN tong_doanh_thu ELSE 0 END) AS t2,
    SUM(CASE WHEN thang = 3 THEN tong_doanh_thu ELSE 0 END) AS t3,
    SUM(CASE WHEN thang = 4 THEN tong_doanh_thu ELSE 0 END) AS t4,
    SUM(CASE WHEN thang = 5 THEN tong_doanh_thu ELSE 0 END) AS t5,
    SUM(CASE WHEN thang = 6 THEN tong_doanh_thu ELSE 0 END) AS t6,
    SUM(CASE WHEN thang = 7 THEN tong_doanh_thu ELSE 0 END) AS t7,
    SUM(CASE WHEN thang = 8 THEN tong_doanh_thu ELSE 0 END) AS t8,
    SUM(CASE WHEN thang = 9 THEN tong_doanh_thu ELSE 0 END) AS t9,
    SUM(CASE WHEN thang = 10 THEN tong_doanh_thu ELSE 0 END) AS t10,
    SUM(CASE WHEN thang = 11 THEN tong_doanh_thu ELSE 0 END) AS t11,
    SUM(CASE WHEN thang = 12 THEN tong_doanh_thu ELSE 0 END) AS t12,
    SUM(tong_doanh_thu) AS tong
FROM mv_cube_ban_hang
GROUP BY bang
ORDER BY bang
```

**Bước 2**: Click **Create chart**

**Bước 3**: Chart Type → **Table**

**Bước 4**: Không cần config thêm

**Bước 5**: **Update chart** → **Save** → Name: `PIVOT - DT Bang x Thang` → Dashboard: `INT1422 OLAP`

> ✅ **Ý nghĩa Pivot**: Xoay chiều Tháng từ dòng thành cột, tạo bảng chéo Bang × Tháng

---

### Tóm tắt 10 charts Phần 3

| # | Tên chart | Chart Type | Phép OLAP |
|---|----------|-----------|-----------|
| 1 | DRILL DOWN - L1 Nam | Bar | Drill Down |
| 2 | DRILL DOWN - L2 Quy | Bar | Drill Down |
| 3 | DRILL DOWN - L3 Thang | Bar | Drill Down |
| 4 | ROLL UP - L1 Cua hang | Bar | Roll Up |
| 5 | ROLL UP - L2 Thanh pho | Bar | Roll Up |
| 6 | ROLL UP - L3 Bang | Bar | Roll Up |
| 7 | ROLL UP - L4 Tong | Table | Roll Up |
| 8 | SLICE - KH Du lich | Table | Slice |
| 9 | DICE - HN gia500K Q1 | Table | Dice |
| 10 | PIVOT - DT Bang x Thang | Table | Pivot |

---

## PHẦN 4: TẠO DASHBOARD

### 4.1 Tạo Dashboard mới (nếu chưa có)
1. Menu → **Dashboards** → **+ Dashboard**
2. Tên: **INT1422 - OLAP Data Warehouse**
3. Click **Save**

### 4.2 Thêm Charts vào Dashboard
1. Mở Dashboard vừa tạo → click **Edit Dashboard** (✏️ góc phải)
2. Tab **Charts** bên phải → kéo từng chart vào vùng trống
3. **Bố cục đề xuất:**

```
┌─────────────────────────────────────────────┐
│           INT1422 - OLAP Data Warehouse     │
├─────────────────────────────────────────────┤
│ [Q9 - Pie Chart]  │  [DRILL DOWN L1,L2,L3] │
├───────────────────┼─────────────────────────┤
│ [Q1 - Table]      │  [ROLL UP L1-L4]       │
├───────────────────┼─────────────────────────┤
│ [Q2 - Table]      │  [SLICE - Table]       │
├───────────────────┼─────────────────────────┤
│ [Q6 - Table]      │  [DICE - Table]        │
├───────────────────┴─────────────────────────┤
│ [PIVOT - Doanh thu Bang × Tháng]           │
├─────────────────────────────────────────────┤
│ [Q3] [Q4] [Q5] [Q7] [Q8]                   │
└─────────────────────────────────────────────┘
```

4. Click **Save** (💾)

### 4.3 Thêm Filter (Tùy chọn)
1. Trong Edit mode → click **Filter** icon (🔍) bên trái
2. **+ Add/Edit Filters** → **+ Filter**
3. Thêm các filter:
   - Filter name: `Khách hàng` → Dataset: mv_cube_ban_hang → Column: ten_kh
   - Filter name: `Thành phố` → Dataset: mv_cube_ban_hang → Column: ten_thanh_pho
   - Filter name: `Loại KH` → Dataset: mv_cube_khach_hang → Column: loai_kh
4. **Save**

---

## PHẦN 5: CHỤP ẢNH CHO BÁO CÁO

Sau khi tạo xong, chụp screenshot các phần sau cho báo cáo:

| # | Screenshot | Mục đích |
|---|-----------|---------|
| 1 | Dashboard tổng quan | Chương 6 báo cáo |
| 2 | Q1–Q9 từng chart | Chương 6 – 9 truy vấn OLAP |
| 3 | Drill Down 3 levels | Chương 6 – phép khoan sâu |
| 4 | Roll Up 4 levels | Chương 6 – phép cuộn lên |
| 5 | Slice result | Chương 6 – phép chiếu |
| 6 | Dice result | Chương 6 – phép chọn |
| 7 | Pivot table | Chương 6 – phép xoay |
| 8 | SQL Lab chạy query | Chương 5 – cài đặt cube |
| 9 | Database connection | Chương 5 – kết nối DW |
