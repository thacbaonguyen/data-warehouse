# Hướng dẫn bảo vệ: Thiết kế Star Schema + Ánh xạ dữ liệu (ETL)

> 📌 Tài liệu này giúp bạn hiểu từ A-Z phần công việc của mình để trả lời câu hỏi giáo viên.

---

## PHẦN A: KIẾN THỨC NỀN TẢNG

### 1. Star Schema là gì?

Star Schema (Lược đồ hình sao) là cách tổ chức bảng trong kho dữ liệu. Gọi là "hình sao" vì khi vẽ ra, nó trông giống ngôi sao:

- **Ở giữa** là bảng **Fact** (bảng sự kiện) — chứa dữ liệu kinh doanh cần phân tích
- **Xung quanh** là các bảng **Dimension** (bảng chiều) — chứa thông tin mô tả

```
         dim_thoi_gian
              |
dim_khach_hang — FACT_BAN_HANG — dim_mat_hang
              |
         dim_cua_hang
```

### 2. Tại sao dùng Star Schema mà không dùng bảng quan hệ bình thường?

| CSDL quan hệ (IDB) | Star Schema (DW) |
|---|---|
| Tối ưu cho ghi dữ liệu (INSERT/UPDATE) | Tối ưu cho đọc và phân tích (SELECT) |
| Nhiều bảng, nhiều JOIN phức tạp | Ít bảng, JOIN đơn giản |
| Chuẩn hóa (3NF) → tránh dư thừa | Phi chuẩn hóa → cho phép dư thừa để truy vấn nhanh |

**Ví dụ dễ hiểu**: Muốn biết "Doanh thu theo tháng, theo thành phố, chia theo loại KH" — IDB phải JOIN 6-7 bảng, Star Schema chỉ cần 1 Fact + 2-3 Dimension.

### 3. Hai khái niệm quan trọng nhất

**Fact (Sự kiện)** = Đo đếm được bằng số: số lượng đặt, giá, doanh thu, tồn kho

**Dimension (Chiều)** = Góc nhìn phân tích: **Ai** mua (KH), **Khi nào** (thời gian), **Cái gì** (MH), **Ở đâu** (CH)

### 4. Grain = mỗi dòng trong Fact đại diện cho cái gì

- `fact_ban_hang`: 1 dòng = **1 mặt hàng** trong **1 đơn đặt hàng**
- `fact_ton_kho`: 1 dòng = **1 mặt hàng** tại **1 cửa hàng** tại **1 thời điểm**

### 5. Surrogate Key vs Business Key

- **Surrogate Key**: `khach_hang_key = 1, 2, 3...` — tự sinh, dùng làm PK trong DW
- **Business Key**: `ma_kh = 'KH01'` — mã nghiệp vụ thực tế, giữ lại để tra cứu

### 6. Degenerate Dimension

Dimension không có bảng riêng, nằm luôn trong Fact. VD: `ma_don` trong `fact_ban_hang` — mã đơn hàng chỉ là nhãn nhóm, không cần bảng riêng.

---

## PHẦN B: THIẾT KẾ CỤ THỂ CỦA DỰ ÁN

### Tổng quan: 2 Fact + 4 Dimension

#### FACT_BAN_HANG (Transaction Fact — 109 dòng)

| Cột | Loại | Ý nghĩa |
|-----|------|---------|
| thoi_gian_key | FK → dim_thoi_gian | Ngày đặt hàng |
| khach_hang_key | FK → dim_khach_hang | Ai mua |
| mat_hang_key | FK → dim_mat_hang | Mua cái gì |
| cua_hang_key | FK → dim_cua_hang | CH nào phục vụ |
| ma_don | Degenerate Dim | Mã đơn hàng |
| **so_luong_dat** | **Measure (Additive)** | Mua bao nhiêu |
| **gia_dat** | **Measure (Non-additive)** | Giá mua |
| **doanh_thu** | **Measure (Additive)** | = SL × Giá |

#### FACT_TON_KHO (Periodic Snapshot — 104 dòng)

| Cột | Loại | Ý nghĩa |
|-----|------|---------|
| thoi_gian_key | FK | Thời điểm chụp |
| mat_hang_key | FK | MH nào |
| cua_hang_key | FK | Tại CH nào |
| **so_luong_kho** | **Measure** | Bao nhiêu trong kho |

> Fact tồn kho **KHÔNG** có dim_khach_hang vì tồn kho không liên quan đến KH.

#### 4 bảng Dimension

| Dimension | Số dòng | Nguồn IDB | Hierarchy |
|---|---|---|---|
| dim_thoi_gian | 366 | Sinh tự động | Ngày → Tuần → Tháng → Quý → Năm |
| dim_khach_hang | 30 | 4 bảng gộp (flatten ISA) | KH → Loại KH, KH → TP → Bang |
| dim_mat_hang | 15 | Copy thẳng | Flat (không phân cấp) |
| dim_cua_hang | 20 | 2 bảng gộp (denormalize) | CH → TP → Bang |

---

## PHẦN C: ÁNH XẠ DỮ LIỆU (ETL)

### ETL = Extract → Transform → Load

Lấy dữ liệu từ IDB (9 bảng) → Biến đổi → Đổ vào DW (6 bảng).

### Sơ đồ luồng

```
IDB (9 bảng)                              DW (6 bảng)
───────────────────────────────────────────────────────
van_phong_dai_dien ──┬──→ dim_cua_hang  (DENORMALIZE)
cua_hang ────────────┘

khach_hang ──────────┬──→ dim_khach_hang (FLATTEN ISA)
kh_du_lich ──────────┤
kh_buu_dien ─────────┤
van_phong_dai_dien ──┘

mat_hang ───────────────→ dim_mat_hang   (COPY)
(sinh tự động) ─────────→ dim_thoi_gian  (GENERATE)

don_dat_hang ────────┬──→ fact_ban_hang  (JOIN + LOOKUP)
mat_hang_duoc_dat ───┘
mat_hang_luu_tru ───────→ fact_ton_kho   (JOIN + LOOKUP)
```

### Phép biến đổi quan trọng nhất

#### 1. FLATTEN ISA (dim_khach_hang)

Gộp 3 bảng khách hàng → 1 bảng, dùng cột `loai_kh`:

```sql
CASE
  WHEN có trong du_lich VÀ buu_dien → 'Cả hai'    (4 KH)
  WHEN chỉ có trong du_lich        → 'Du lịch'    (8 KH)
  WHEN chỉ có trong buu_dien       → 'Bưu điện'   (8 KH)
  ELSE                             → 'Thường'     (10 KH)
END
```

#### 2. DENORMALIZE (dim_cua_hang)

Gộp `cua_hang` + `van_phong_dai_dien` → 1 bảng. Lấy `ten_thanh_pho`, `dia_chi_vp`, `bang` nhét cùng dòng với CH.

#### 3. LOOKUP cua_hang_key (fact_ban_hang)

Logic chọn CH phục vụ đơn: Theo đề bài, ưu tiên lấy hàng từ CH tại TP khách sinh sống → chọn CH đầu tiên (theo mã) tại TP đó mà có lưu kho MH được đặt.

---

## PHẦN D: CÂU HỎI THƯỜNG GẶP

**Q: Tại sao có 2 bảng Fact?**
→ 2 nghiệp vụ khác nhau: Bán hàng (transaction) vs Tồn kho (snapshot). Grain, measure, dimension đều khác.

**Q: Hierarchy dùng để làm gì?**
→ Drill Down (khoan sâu): 2024 → Q1 → Tháng 1. Roll Up (cuộn lên): CH01 → Hà Nội → Miền Bắc.

**Q: Denormalize là gì? Tại sao cần?**
→ Cho phép dư thừa dữ liệu để truy vấn nhanh hơn (không cần JOIN).

**Q: Flatten ISA là gì?**
→ Gộp bảng chuyên biệt hóa (subtype) vào 1 bảng bằng 1 cột phân loại.

**Q: Measures nào additive?**
→ `so_luong_dat`, `doanh_thu`, `so_luong_kho` = Additive. `gia_dat` = Non-additive.

**Q: 9 truy vấn OLAP được đáp ứng thế nào?**

| Q | Fact | Dimensions |
|---|------|------------|
| 1 | fact_ton_kho | dim_cua_hang, dim_mat_hang |
| 2 | fact_ban_hang | dim_khach_hang, dim_thoi_gian |
| 3 | fact_ban_hang | dim_khach_hang, dim_mat_hang, dim_cua_hang |
| 4 | fact_ton_kho | dim_cua_hang, dim_mat_hang |
| 5 | fact_ban_hang + fact_ton_kho | dim_mat_hang, dim_cua_hang |
| 6 | không cần Fact | dim_khach_hang |
| 7 | fact_ton_kho | dim_mat_hang, dim_cua_hang |
| 8 | fact_ban_hang | tất cả 4 dim |
| 9 | không cần Fact | dim_khach_hang (loai_kh) |

---

## PHẦN E: TÓM TẮT 1 PHÚT

> "Em đảm nhận phần **Thiết kế Star Schema và Ánh xạ dữ liệu ETL**.
>
> Từ 9 bảng IDB, em thiết kế kho dữ liệu gồm **2 bảng Fact** (Bán hàng và Tồn kho) và **4 bảng Dimension** (Thời gian, Khách hàng, Mặt hàng, Cửa hàng).
>
> Phần phức tạp nhất là **flatten ISA** — gộp 3 bảng khách hàng thành 1 với cột loai_kh, và **denormalize** — gộp VPĐD vào dim_cua_hang để tối ưu truy vấn.
>
> Kết quả: Star Schema đáp ứng đầy đủ **cả 9 truy vấn OLAP** và hỗ trợ Drill Down, Roll Up, Slice, Dice, Pivot qua hierarchy của từng dimension."
