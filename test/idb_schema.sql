-- ================================================================
-- IDB (Integrated Database) Schema
-- Bài tập lớn Kho dữ liệu - INT1422
-- CSDL: PostgreSQL
-- ================================================================
-- Mô tả: Tạo các bảng cho CSDL tích hợp (IDB) từ mô hình IER
-- Kết quả tích hợp 2 nguồn:
--   Nguồn 1: CSDL Văn phòng đại diện (Khách hàng, KH Du lịch, KH Bưu điện)
--   Nguồn 2: CSDL Bán hàng (VPĐD, Cửa hàng, Mặt hàng, Tồn kho, Đơn hàng, Chi tiết đơn)
-- ================================================================

-- Xóa các bảng nếu đã tồn tại (thứ tự ngược theo dependency)
DROP TABLE IF EXISTS mat_hang_duoc_dat CASCADE;
DROP TABLE IF EXISTS mat_hang_luu_tru CASCADE;
DROP TABLE IF EXISTS don_dat_hang CASCADE;
DROP TABLE IF EXISTS khach_hang_buu_dien CASCADE;
DROP TABLE IF EXISTS khach_hang_du_lich CASCADE;
DROP TABLE IF EXISTS khach_hang CASCADE;
DROP TABLE IF EXISTS mat_hang CASCADE;
DROP TABLE IF EXISTS cua_hang CASCADE;
DROP TABLE IF EXISTS van_phong_dai_dien CASCADE;

-- ================================================================
-- 1. VAN_PHONG_DAI_DIEN (Văn phòng đại diện / Thành phố)
-- Nguồn: CSDL Bán hàng
-- ================================================================
CREATE TABLE van_phong_dai_dien (
    ma_thanh_pho    VARCHAR(10)  PRIMARY KEY,
    ten_thanh_pho   VARCHAR(100) NOT NULL,
    dia_chi_vp      VARCHAR(200),
    bang            VARCHAR(100),
    ngay_thanh_lap  DATE         NOT NULL
);

COMMENT ON TABLE van_phong_dai_dien IS 'Văn phòng đại diện tại mỗi thành phố, quản lý các cửa hàng';
COMMENT ON COLUMN van_phong_dai_dien.ma_thanh_pho IS 'Mã thành phố (PK)';
COMMENT ON COLUMN van_phong_dai_dien.ten_thanh_pho IS 'Tên thành phố';
COMMENT ON COLUMN van_phong_dai_dien.dia_chi_vp IS 'Địa chỉ văn phòng đại diện';
COMMENT ON COLUMN van_phong_dai_dien.bang IS 'Bang (State)';
COMMENT ON COLUMN van_phong_dai_dien.ngay_thanh_lap IS 'Ngày thành lập văn phòng đại diện';

-- ================================================================
-- 2. CUA_HANG (Cửa hàng)
-- Nguồn: CSDL Bán hàng
-- ================================================================
CREATE TABLE cua_hang (
    ma_cua_hang     VARCHAR(10)  PRIMARY KEY,
    ma_thanh_pho    VARCHAR(10)  NOT NULL,
    so_dien_thoai   VARCHAR(20),
    ngay_khai_truong DATE        NOT NULL,
    CONSTRAINT fk_cua_hang_thanh_pho
        FOREIGN KEY (ma_thanh_pho) REFERENCES van_phong_dai_dien(ma_thanh_pho)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

COMMENT ON TABLE cua_hang IS 'Các cửa hàng thuộc doanh nghiệp';
COMMENT ON COLUMN cua_hang.ma_cua_hang IS 'Mã cửa hàng (PK)';
COMMENT ON COLUMN cua_hang.ma_thanh_pho IS 'Mã thành phố (FK → van_phong_dai_dien)';
COMMENT ON COLUMN cua_hang.ngay_khai_truong IS 'Ngày khai trương cửa hàng';

-- ================================================================
-- 3. MAT_HANG (Mặt hàng)
-- Nguồn: CSDL Bán hàng
-- ================================================================
CREATE TABLE mat_hang (
    ma_mat_hang     VARCHAR(10)  PRIMARY KEY,
    mo_ta           VARCHAR(200),
    kich_co         VARCHAR(50),
    trong_luong     DECIMAL(10,2),
    gia             DECIMAL(15,2) NOT NULL,
    ngay_bat_dau_ban DATE        NOT NULL DEFAULT DATE '2024-01-01'
);

COMMENT ON TABLE mat_hang IS 'Danh mục mặt hàng';
COMMENT ON COLUMN mat_hang.ma_mat_hang IS 'Mã mặt hàng (PK)';
COMMENT ON COLUMN mat_hang.gia IS 'Đơn giá mặt hàng';
COMMENT ON COLUMN mat_hang.ngay_bat_dau_ban IS 'Ngày bắt đầu bán mặt hàng';

-- ================================================================
-- 4. KHACH_HANG (Khách hàng - supertype)
-- Nguồn: CSDL Văn phòng đại diện
-- ================================================================
CREATE TABLE khach_hang (
    ma_kh            VARCHAR(10)  PRIMARY KEY,
    ten_kh           VARCHAR(100) NOT NULL,
    ma_thanh_pho     VARCHAR(10)  NOT NULL,
    ngay_dh_dau_tien DATE,
    CONSTRAINT fk_khach_hang_thanh_pho
        FOREIGN KEY (ma_thanh_pho) REFERENCES van_phong_dai_dien(ma_thanh_pho)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

COMMENT ON TABLE khach_hang IS 'Khách hàng (supertype) - bao gồm cả KH du lịch và KH bưu điện';
COMMENT ON COLUMN khach_hang.ma_kh IS 'Mã khách hàng (PK)';
COMMENT ON COLUMN khach_hang.ngay_dh_dau_tien IS 'Ngày đặt hàng đầu tiên của khách';

-- ================================================================
-- 5. KHACH_HANG_DU_LICH (Khách hàng du lịch - subtype ISA)
-- Nguồn: CSDL Văn phòng đại diện
-- Overlapping & Partial specialization
-- ================================================================
CREATE TABLE khach_hang_du_lich (
    ma_kh            VARCHAR(10)  PRIMARY KEY,
    huong_dan_vien   VARCHAR(100),
    ngay_du_lich     DATE         NOT NULL,
    CONSTRAINT fk_kh_du_lich
        FOREIGN KEY (ma_kh) REFERENCES khach_hang(ma_kh)
        ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE khach_hang_du_lich IS 'Khách hàng du lịch (subtype) - được dẫn bởi hướng dẫn viên';
COMMENT ON COLUMN khach_hang_du_lich.ngay_du_lich IS 'Ngày du lịch của khách hàng du lịch';

-- ================================================================
-- 6. KHACH_HANG_BUU_DIEN (Khách hàng bưu điện - subtype ISA)
-- Nguồn: CSDL Văn phòng đại diện
-- Overlapping & Partial specialization
-- ================================================================
CREATE TABLE khach_hang_buu_dien (
    ma_kh            VARCHAR(10)  PRIMARY KEY,
    dia_chi_buu_dien VARCHAR(200),
    ngay_cap_nhat_dia_chi DATE    NOT NULL,
    CONSTRAINT fk_kh_buu_dien
        FOREIGN KEY (ma_kh) REFERENCES khach_hang(ma_kh)
        ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE khach_hang_buu_dien IS 'Khách hàng bưu điện (subtype) - đặt hàng qua đường bưu điện';
COMMENT ON COLUMN khach_hang_buu_dien.ngay_cap_nhat_dia_chi IS 'Ngày cập nhật địa chỉ của khách hàng bưu điện';

-- ================================================================
-- 7. DON_DAT_HANG (Đơn đặt hàng)
-- Nguồn: CSDL Bán hàng
-- ================================================================
CREATE TABLE don_dat_hang (
    ma_don           VARCHAR(10)  PRIMARY KEY,
    ngay_dat_hang    DATE         NOT NULL,
    ma_kh            VARCHAR(10)  NOT NULL,
    CONSTRAINT fk_don_hang_khach_hang
        FOREIGN KEY (ma_kh) REFERENCES khach_hang(ma_kh)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

COMMENT ON TABLE don_dat_hang IS 'Đơn đặt hàng của khách hàng';
COMMENT ON COLUMN don_dat_hang.ma_don IS 'Mã đơn đặt hàng (PK)';

-- ================================================================
-- 8. MAT_HANG_LUU_TRU (Mặt hàng được lưu trữ - M:N CỬA_HÀNG × MẶT_HÀNG)
-- Nguồn: CSDL Bán hàng
-- ================================================================
CREATE TABLE mat_hang_luu_tru (
    ma_cua_hang     VARCHAR(10),
    ma_mat_hang     VARCHAR(10),
    so_luong_kho    INTEGER      DEFAULT 0 CHECK (so_luong_kho >= 0),
    ngay_quyet_toan DATE         NOT NULL DEFAULT DATE '2024-12-31',
    PRIMARY KEY (ma_cua_hang, ma_mat_hang),
    CONSTRAINT fk_luu_tru_cua_hang
        FOREIGN KEY (ma_cua_hang) REFERENCES cua_hang(ma_cua_hang)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_luu_tru_mat_hang
        FOREIGN KEY (ma_mat_hang) REFERENCES mat_hang(ma_mat_hang)
        ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE mat_hang_luu_tru IS 'Liên kết M:N: mặt hàng được lưu kho tại cửa hàng';
COMMENT ON COLUMN mat_hang_luu_tru.ngay_quyet_toan IS 'Ngày quyết toán tồn kho cho mặt hàng tại cửa hàng';

-- ================================================================
-- 9. MAT_HANG_DUOC_DAT (Mặt hàng được đặt - M:N ĐƠN_HÀNG × MẶT_HÀNG)
-- Nguồn: CSDL Bán hàng
-- ================================================================
CREATE TABLE mat_hang_duoc_dat (
    ma_don          VARCHAR(10),
    ma_mat_hang     VARCHAR(10),
    so_luong_dat    INTEGER      NOT NULL CHECK (so_luong_dat > 0),
    gia_dat         DECIMAL(15,2) NOT NULL,
    thoi_diem_xac_nhan TIMESTAMP NOT NULL DEFAULT TIMESTAMP '2024-01-01 08:00:00',
    PRIMARY KEY (ma_don, ma_mat_hang),
    CONSTRAINT fk_duoc_dat_don_hang
        FOREIGN KEY (ma_don) REFERENCES don_dat_hang(ma_don)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_duoc_dat_mat_hang
        FOREIGN KEY (ma_mat_hang) REFERENCES mat_hang(ma_mat_hang)
        ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON TABLE mat_hang_duoc_dat IS 'Liên kết M:N: chi tiết mặt hàng trong đơn đặt hàng';
COMMENT ON COLUMN mat_hang_duoc_dat.thoi_diem_xac_nhan IS 'Thời điểm xác nhận mặt hàng trong đơn đặt hàng';

-- ================================================================
-- Indexes để tối ưu truy vấn
-- ================================================================
CREATE INDEX idx_cua_hang_thanh_pho ON cua_hang(ma_thanh_pho);
CREATE INDEX idx_khach_hang_thanh_pho ON khach_hang(ma_thanh_pho);
CREATE INDEX idx_don_hang_khach_hang ON don_dat_hang(ma_kh);
CREATE INDEX idx_don_hang_ngay ON don_dat_hang(ngay_dat_hang);
CREATE INDEX idx_luu_tru_mat_hang ON mat_hang_luu_tru(ma_mat_hang);
CREATE INDEX idx_duoc_dat_mat_hang ON mat_hang_duoc_dat(ma_mat_hang);
