# Mapping: Yêu cầu đề bài → Files trong dự án

> Tài liệu tham khảo để chuẩn bị báo cáo

---

## Bước 1 — Tích hợp dữ liệu (1.5đ)

> Chuyển 2 bộ bảng quan hệ → 2 ER → 1 IER → tạo IDB

| Yêu cầu | File | Đường dẫn |
|----------|------|-----------|
| ER1 (CSDL Văn phòng đại diện) | `ER1.png` | `docs/step1_integration/ER1.png` |
| ER2 (CSDL Bán hàng) | `ER2.png` | `docs/step1_integration/ER2.png` |
| Sơ đồ ER tích hợp (IER) | `IER.png` | `docs/step1_integration/IER.png` |
| Mermaid code ER (tham khảo) | `er_diagrams.md` | `docs/step1_integration/er_diagrams.md` |
| SQL tạo bảng IDB | `idb_schema.sql` | `docs/step1_integration/idb_schema.sql` |
| Đánh giá ER (nội bộ) | `evaluation.md` | `docs/step1_integration/evaluation.md` |

---

## Bước 2 — Sinh dữ liệu mẫu (1đ)

> Tự tạo dữ liệu giả lập cho IDB để demo

| Yêu cầu | File | Đường dẫn |
|----------|------|-----------|
| Dữ liệu mẫu IDB (9 bảng, 342 records) | `idb_sample_data.sql` | `docs/step1_integration/idb_sample_data.sql` |

---

## Bước 3 — Thiết kế Kho DW (2đ)

> Star Schema: Fact + Dimension + ánh xạ ETL

| Yêu cầu | File | Đường dẫn |
|----------|------|-----------|
| Thiết kế Star Schema (tài liệu) | `star_schema_design.md` | `docs/step2_star_schema/star_schema_design.md` |
| Star Schema diagram (vẽ tay) | `star-schema.jpg` | `docs/step2_star_schema/star-schema.jpg` |
| SQL tạo bảng DW (2 Fact + 4 Dim) | `dw_schema.sql` | `docs/step2_star_schema/dw_schema.sql` |
| Ánh xạ ETL: IDB → DW | `etl_mapping.md` | `docs/step2_star_schema/etl_mapping.md` |
| SQL sinh dữ liệu DW | `dw_sample_data.sql` | `docs/step2_star_schema/dw_sample_data.sql` |

---

## Bước 4 — OLAP Cubes (2.5đ)

> Phân cấp chiều + Cube + Materialized Views + 9 truy vấn

| Yêu cầu | File | Đường dẫn |
|----------|------|-----------|
| Phân cấp chiều (Hierarchy) | `hierarchy_design.md` | `docs/step3_olap/hierarchy_design.md` |
| Thiết kế 3 Cubes | `cube_design.md` | `docs/step3_olap/cube_design.md` |
| SQL: 3 MV + 9 truy vấn + 5 phép OLAP | `cube_queries.sql` | `docs/step3_olap/cube_queries.sql` |

---

## Bước 5 — Metadata & Index (1đ)

> Metadata mô tả kho + index hỗ trợ truy vấn

| Yêu cầu | File | Đường dẫn |
|----------|------|-----------|
| Metadata (bảng, cột, ETL, MV) | `metadata.md` | `docs/step3_olap/metadata.md` |
| Index files (31 indexes) | `indexes.sql` | `docs/step3_olap/indexes.sql` |

---

## Bước 6 — Giao diện Web OLAP (2đ)

> Apache Superset: Dashboard + 9 truy vấn + 5 phép OLAP

| Yêu cầu | File | Đường dẫn |
|----------|------|-----------|
| Docker Compose (PG + Superset) | `docker-compose.yml` | `docker-compose.yml` |
| Script khởi tạo Superset | `superset_setup.sh` | `web_olap/superset_setup.sh` |
| Hướng dẫn tạo charts/dashboard | `superset_guide.md` | `web_olap/superset_guide.md` |
| Dashboard Superset | _(trên UI)_ | `http://localhost:8088` |

---

## Cây thư mục tổng hợp

```
int1422/
├── context.md                          ← Context toàn dự án
├── docker-compose.yml                  ← Bước 6: Docker
│
├── docs/
│   ├── step1_integration/              ← Bước 1 + 2
│   │   ├── ER1.png, ER2.png, IER.png  ← Sơ đồ ER
│   │   ├── er_diagrams.md             ← Mermaid code
│   │   ├── evaluation.md             ← Đánh giá ER
│   │   ├── idb_schema.sql            ← Bước 1: Schema IDB
│   │   └── idb_sample_data.sql       ← Bước 2: Dữ liệu mẫu
│   │
│   ├── step2_star_schema/              ← Bước 3
│   │   ├── star_schema_design.md      ← Tài liệu thiết kế
│   │   ├── star-schema.jpg            ← Diagram vẽ tay
│   │   ├── dw_schema.sql             ← DDL cho DW
│   │   ├── etl_mapping.md            ← Ánh xạ ETL
│   │   └── dw_sample_data.sql        ← Dữ liệu DW
│   │
│   └── step3_olap/                     ← Bước 4 + 5
│       ├── hierarchy_design.md        ← Phân cấp chiều
│       ├── cube_design.md             ← Thiết kế 3 Cubes
│       ├── cube_queries.sql           ← MV + Queries + OLAP
│       ├── metadata.md               ← Metadata
│       └── indexes.sql               ← 31 Indexes
│
└── web_olap/                           ← Bước 6
    ├── superset_setup.sh              ← Init script
    └── superset_guide.md              ← Hướng dẫn UI
```
