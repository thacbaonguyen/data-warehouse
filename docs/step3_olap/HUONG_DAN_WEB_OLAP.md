# Hướng dẫn bảo vệ: Setup & Thiết kế Web OLAP

> 📌 Tài liệu giải thích phần cài đặt hạ tầng và xử lý phân tích trực tuyến (OLAP) trên web.

---

## PHẦN A: KIẾN THỨC NỀN TẢNG

### 1. OLAP là gì?

OLAP = **O**nline **A**nalytical **P**rocessing (Xử lý phân tích trực tuyến).

Là khả năng nhìn dữ liệu từ **nhiều góc độ khác nhau** (chiều thời gian, chiều địa lý, chiều sản phẩm...) và thực hiện các phép toán phân tích.

### 2. Materialized View là gì?

Là **bảng ảo được tính sẵn** và lưu kết quả vào đĩa. Thay vì mỗi lần truy vấn phải JOIN 4-5 bảng, ta tính sẵn 1 lần rồi lưu lại.

Dự án có **3 Materialized View**:

| MV | Mục đích | Nguồn |
|---|---|---|
| `mv_cube_ban_hang` | Cube bán hàng (JOIN 4 dim + fact) | fact_ban_hang + 4 dim |
| `mv_cube_ton_kho` | Cube tồn kho | fact_ton_kho + 2 dim |
| `mv_cube_khach_hang` | Thông tin KH | dim_khach_hang |

### 3. Năm phép toán OLAP

| Phép toán | Tiếng Việt | Ý nghĩa | Ví dụ |
|---|---|---|---|
| **Drill Down** | Khoan sâu | Từ tổng → chi tiết | Năm → Quý → Tháng |
| **Roll Up** | Cuộn lên | Từ chi tiết → tổng | CH → TP → Bang → Tổng |
| **Slice** | Cắt lát | Lọc theo **1 chiều** | Chỉ xem KH Du lịch |
| **Dice** | Cắt khối | Lọc theo **nhiều chiều** | KH Hà Nội + MH > 500K + Q1 |
| **Pivot** | Xoay | Chuyển dòng ↔ cột | Bảng chéo Bang × Tháng |

---

## PHẦN B: HẠ TẦNG CÔNG NGHỆ

### 1. Kiến trúc hệ thống

```
┌──────────────────────────────────────────────────┐
│                   DOCKER                          │
│                                                   │
│  ┌─────────────┐      ┌──────────────────────┐   │
│  │ PostgreSQL   │ ←──→ │  Apache Superset     │   │
│  │ (Port 5432)  │      │  (Port 8088)         │   │
│  │              │      │                      │   │
│  │ • IDB (9 bảng)      │ • Dashboard          │   │
│  │ • DW  (6 bảng)      │ • 19 Charts          │   │
│  │ • MV  (3 views)     │ • SQL Lab            │   │
│  └─────────────┘      └──────────────────────┘   │
└──────────────────────────────────────────────────┘
```

### 2. Tại sao chọn các công nghệ này?

| Công nghệ | Vai trò | Lý do chọn |
|---|---|---|
| **PostgreSQL** | CSDL | Hỗ trợ Materialized View, Window Function, CUBE/ROLLUP |
| **Apache Superset** | Dashboard OLAP | Mã nguồn mở, hỗ trợ SQL Lab, nhiều loại chart |
| **Docker** | Đóng gói | Cài 1 lần, chạy mọi nơi, không lo xung đột |

### 3. Kết nối Superset → PostgreSQL

- **Driver**: `psycopg2-binary` (cài sẵn trong Dockerfile tùy chỉnh)
- **Connection string**: `postgresql+psycopg2://int1422:int1422_pass@postgres-idb:5432/int1422_idb`
- `postgres-idb` là hostname nội bộ Docker (2 container cùng mạng)

---

## PHẦN C: 19 CHARTS VÀ Ý NGHĨA

### Nhóm 1: 9 truy vấn OLAP theo đề bài (Q1–Q9)

| Chart | Yêu cầu | Dữ liệu từ | Loại chart |
|---|---|---|---|
| Q1 | CH + MH bán ở kho | mv_cube_ton_kho | Table |
| Q2 | ĐH + KH + ngày đặt | fact_ban_hang + dim | Table |
| Q3 | CH bán MH cho 1 KH | mv_cube_ban_hang | Table |
| Q4 | VPĐD có kho > ngưỡng | mv_cube_ton_kho | Table |
| Q5 | MH đặt + CH bán MH đó | mv_cube_ban_hang + mv_cube_ton_kho | Table |
| Q6 | TP + Bang KH sinh sống | mv_cube_khach_hang | Table |
| Q7 | Tồn kho MH tại 1 TP | mv_cube_ton_kho | Table |
| Q8 | Chi tiết 1 đơn hàng | mv_cube_ban_hang | Table |
| Q9 | Phân loại KH | mv_cube_khach_hang | Pie Chart |

### Nhóm 2: 10 charts demo phép toán OLAP

| Chart | Phép toán | Ý nghĩa |
|---|---|---|
| DRILL DOWN L1 – Năm | Drill Down | Doanh thu tổng theo năm |
| DRILL DOWN L2 – Quý | Drill Down | Khoan sâu từ năm → 4 quý |
| DRILL DOWN L3 – Tháng | Drill Down | Khoan sâu từ quý → 12 tháng |
| ROLL UP L1 – Cửa hàng | Roll Up | Tồn kho chi tiết 20 CH |
| ROLL UP L2 – Thành phố | Roll Up | Cuộn lên → 10 thành phố |
| ROLL UP L3 – Bang | Roll Up | Cuộn lên → 3 bang (MB, MN, MT) |
| ROLL UP L4 – Tổng | Roll Up | Cuộn lên → 1 số tổng (4708) |
| SLICE – KH Du lịch | Slice | Cắt theo 1 chiều: loại KH = Du lịch |
| DICE – HN + >500K + Q1 | Dice | Cắt theo 3 chiều cùng lúc |
| PIVOT – DT Bang × Tháng | Pivot | Xoay dòng thành cột |

---

## PHẦN D: GIẢI THÍCH 5 PHÉP OLAP (CHI TIẾT)

### 1. DRILL DOWN (Khoan sâu)

**Là gì?** Đi từ mức tổng hợp xuống mức chi tiết hơn, theo phân cấp (hierarchy).

**Ví dụ cụ thể trong dự án:**
- **Level 1**: Doanh thu cả năm 2024 = **57.14 triệu**
- **Level 2**: Khoan sâu → Q1: 18.12M, Q2: 14.87M, Q3: 12.85M, Q4: 11.30M
- **Level 3**: Khoan sâu Q1 → T1: 5.46M, T2: 5.33M, T3: 7.33M

**SQL cốt lõi:**
```sql
-- Level 1 (Năm)
SELECT nam, SUM(tong_doanh_thu) FROM mv_cube_ban_hang GROUP BY nam

-- Level 2 (Quý) — thêm WHERE nam = 2024
SELECT quy, SUM(tong_doanh_thu) FROM mv_cube_ban_hang WHERE nam = 2024 GROUP BY quy

-- Level 3 (Tháng) — thêm WHERE quy = 1
SELECT thang, SUM(tong_doanh_thu) FROM mv_cube_ban_hang WHERE nam = 2024 GROUP BY thang
```

**Hierarchy sử dụng:** `dim_thoi_gian: Năm → Quý → Tháng`

### 2. ROLL UP (Cuộn lên)

**Là gì?** Ngược lại với Drill Down — đi từ chi tiết lên tổng hợp.

**Ví dụ cụ thể:**
- **Level 1**: Tồn kho từng cửa hàng (20 dòng)
- **Level 2**: Cuộn lên → từng thành phố (10 dòng)
- **Level 3**: Cuộn lên → từng bang (3 dòng): MB:1607, MN:1718, MT:1383
- **Level 4**: Cuộn lên → tổng toàn hệ thống: **4708**

**Hierarchy sử dụng:** `dim_cua_hang: Cửa hàng → Thành phố → Bang`

### 3. SLICE (Cắt lát)

**Là gì?** Lọc dữ liệu theo **1 chiều duy nhất**, giữ nguyên các chiều khác.

**Ví dụ:** Cắt cube bán hàng theo `loai_kh = 'Du lịch'`
→ Kết quả: chỉ hiển thị doanh thu của KH du lịch, vẫn chia theo TP × Tháng.

```sql
SELECT ten_thanh_pho, ten_thang, SUM(tong_doanh_thu)
FROM mv_cube_ban_hang
WHERE loai_kh = 'Du lịch'   -- ← Slice: chỉ lọc 1 chiều
GROUP BY ten_thanh_pho, thang, ten_thang
```

### 4. DICE (Cắt khối)

**Là gì?** Lọc theo **nhiều chiều cùng lúc** (so với Slice chỉ 1 chiều).

**Ví dụ:** Lọc đồng thời:
- Chiều KH: TP sinh sống = Hà Nội
- Chiều MH: Giá > 500,000 VNĐ
- Chiều thời gian: Quý 1

```sql
SELECT ten_kh, mo_ta, tong_doanh_thu
FROM mv_cube_ban_hang
WHERE ten_thanh_pho_kh = 'Hà Nội'   -- ← Chiều 1
  AND gia_goc > 500000               -- ← Chiều 2
  AND quy = 1                        -- ← Chiều 3
```

### 5. PIVOT (Xoay)

**Là gì?** Chuyển giá trị của 1 chiều từ dòng thành cột, tạo bảng chéo.

**Ví dụ:** Doanh thu theo Bang (dòng) × Tháng (cột):

```
         | T1   | T2   | T3   | ... | T12  | Tổng
---------|------|------|------|-----|------|------
Miền Bắc | 5.2M | 3.1M | 4.8M | ... | 2.1M | 21M
Miền Nam | 3.8M | 2.9M | ...  | ... | ...  | 18M
Miền Trung | ... | ...  | ...  | ... | ...  | 18M
```

**SQL dùng CASE WHEN:**
```sql
SELECT bang,
  SUM(CASE WHEN thang = 1 THEN tong_doanh_thu ELSE 0 END) AS t1,
  SUM(CASE WHEN thang = 2 THEN tong_doanh_thu ELSE 0 END) AS t2,
  ...
FROM mv_cube_ban_hang GROUP BY bang
```

---

## PHẦN E: CÂU HỎI THƯỜNG GẶP

**Q: Tại sao dùng Materialized View mà không query trực tiếp từ Fact + Dim?**
→ MV tính sẵn kết quả JOIN. Query trực tiếp mỗi lần phải JOIN 4-5 bảng → chậm. MV chỉ cần SELECT 1 bảng → nhanh.

**Q: Slice khác Dice chỗ nào?**
→ Slice lọc **1 chiều** (VD: chỉ KH du lịch). Dice lọc **nhiều chiều cùng lúc** (VD: KH Hà Nội + MH > 500K + Q1).

**Q: Drill Down khác Roll Up chỗ nào?**
→ Drill Down đi **xuống** (tổng → chi tiết). Roll Up đi **lên** (chi tiết → tổng). Cùng 1 hierarchy, ngược chiều nhau.

**Q: Pivot dùng trong trường hợp nào?**
→ Khi muốn so sánh chéo 2 chiều. VD: so sánh doanh thu 3 bang qua 12 tháng → bảng 3 dòng × 12 cột dễ đọc hơn bảng 36 dòng × 2 cột.

**Q: Superset kết nối database bằng gì?**
→ Dùng driver `psycopg2` qua SQLAlchemy URI. Hostname `postgres-idb` là DNS nội bộ Docker.

**Q: Tại sao dùng Docker mà không cài trực tiếp?**
→ Docker đảm bảo môi trường giống nhau trên mọi máy (dev, server, GCP). Không cần cài PostgreSQL hay Superset thủ công.

---

## PHẦN F: TÓM TẮT 1 PHÚT

> "Phần Web OLAP bao gồm **thiết lập hạ tầng** và **xây dựng dashboard**.
>
> Hạ tầng gồm PostgreSQL + Apache Superset chạy trên Docker. Dữ liệu được tính sẵn qua **3 Materialized View** để truy vấn nhanh.
>
> Dashboard gồm **19 charts**: 9 charts cho 9 truy vấn OLAP theo đề bài, và 10 charts demo 5 phép toán OLAP (Drill Down, Roll Up, Slice, Dice, Pivot).
>
> Drill Down khoan sâu doanh thu từ Năm → Quý → Tháng. Roll Up cuộn tồn kho từ CH → TP → Bang → Tổng. Slice cắt theo 1 chiều. Dice cắt nhiều chiều. Pivot xoay dòng thành cột."
