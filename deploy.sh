#!/bin/bash
# ============================================================
# INT1422 Data Warehouse - One-click Deploy Script
# Tự động: Docker → DB init → Superset setup → Import dashboards
# ============================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONTAINER_PG="int1422_postgres"
CONTAINER_SS="int1422_superset"
ADMIN_USER="admin"
ADMIN_PASS="admin"
ADMIN_EMAIL="admin@int1422.local"
EXPORT_FILE="web_olap/dashboard_export.zip"

log() { echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"; }
ok()  { echo -e "${GREEN}  ✔ $1${NC}"; }
err() { echo -e "${RED}  ✘ $1${NC}"; exit 1; }
warn(){ echo -e "${YELLOW}  ⚠ $1${NC}"; }

# ─── Step 0: Pre-checks ───
log "Step 0: Kiểm tra Docker..."
command -v docker >/dev/null 2>&1 || err "Docker chưa cài. Vui lòng cài Docker trước."
docker info >/dev/null 2>&1 || err "Docker daemon chưa chạy. Khởi động Docker trước."
ok "Docker OK"

if [ ! -f "docker-compose.yml" ]; then
  err "Không tìm thấy docker-compose.yml. Chạy script từ thư mục gốc project."
fi

# ─── Step 1: Start containers ───
log "Step 1: Khởi động containers (PostgreSQL + Superset)..."
docker compose down --remove-orphans 2>/dev/null || true
docker compose up -d

ok "Containers đã khởi tạo"

# ─── Step 2: Wait for PostgreSQL healthy ───
log "Step 2: Đợi PostgreSQL sẵn sàng..."
RETRIES=0
MAX_RETRIES=30
until docker exec $CONTAINER_PG pg_isready -U int1422 -d int1422_idb >/dev/null 2>&1; do
  RETRIES=$((RETRIES + 1))
  if [ $RETRIES -ge $MAX_RETRIES ]; then
    err "PostgreSQL không sẵn sàng sau ${MAX_RETRIES}s"
  fi
  sleep 1
done
ok "PostgreSQL healthy"

# ─── Step 3: Verify database data ───
log "Step 3: Kiểm tra dữ liệu trong DB..."
sleep 3  # Đợi init scripts chạy xong

TABLES=("van_phong_dai_dien" "cua_hang" "mat_hang" "khach_hang" "don_dat_hang"
        "dim_thoi_gian" "dim_khach_hang" "dim_mat_hang" "dim_cua_hang"
        "fact_ban_hang" "fact_ton_kho"
        "mv_cube_ban_hang" "mv_cube_ton_kho" "mv_cube_khach_hang")

for tbl in "${TABLES[@]}"; do
  COUNT=$(docker exec $CONTAINER_PG psql -U int1422 -d int1422_idb -t -c "SELECT count(*) FROM $tbl" 2>/dev/null | tr -d ' ')
  if [ -z "$COUNT" ] || [ "$COUNT" = "0" ]; then
    warn "$tbl: ${COUNT:-MISSING}"
  else
    ok "$tbl: $COUNT rows"
  fi
done

# ─── Step 4: Wait for Superset container ───
log "Step 4: Đợi Superset sẵn sàng..."
RETRIES=0
MAX_RETRIES=60
until docker exec $CONTAINER_SS curl -s -o /dev/null -w "%{http_code}" http://localhost:8088/health 2>/dev/null | grep -q "200"; do
  RETRIES=$((RETRIES + 1))
  if [ $RETRIES -ge $MAX_RETRIES ]; then
    warn "Superset health check timeout, tiếp tục..."
    break
  fi
  sleep 2
done
ok "Superset container running"

# ─── Step 5: Install psycopg2 driver ───
log "Step 5: Cài PostgreSQL driver (psycopg2) cho Superset..."
docker exec -u root $CONTAINER_SS pip install psycopg2-binary \
  --target=/app/.venv/lib/python3.10/site-packages/ \
  --force-reinstall --no-deps -q 2>/dev/null
ok "psycopg2-binary đã cài"

# ─── Step 6: Init Superset (DB upgrade + admin user) ───
log "Step 6: Khởi tạo Superset (DB upgrade + tạo admin)..."
docker exec $CONTAINER_SS /app/.venv/bin/superset db upgrade 2>/dev/null
ok "DB upgrade done"

docker exec $CONTAINER_SS /app/.venv/bin/superset fab create-admin \
  --username $ADMIN_USER \
  --firstname Admin \
  --lastname INT1422 \
  --email $ADMIN_EMAIL \
  --password $ADMIN_PASS 2>/dev/null || warn "Admin user đã tồn tại"
ok "Admin user: $ADMIN_USER / $ADMIN_PASS"

docker exec $CONTAINER_SS /app/.venv/bin/superset init 2>/dev/null
ok "Superset init done"

# ─── Step 7: Restart Superset to load psycopg2 ───
log "Step 7: Restart Superset để nhận driver mới..."
docker restart $CONTAINER_SS
sleep 15

RETRIES=0
until docker exec $CONTAINER_SS curl -s -o /dev/null -w "%{http_code}" http://localhost:8088/health 2>/dev/null | grep -q "200"; do
  RETRIES=$((RETRIES + 1))
  if [ $RETRIES -ge $MAX_RETRIES ]; then
    warn "Superset restart timeout, tiếp tục..."
    break
  fi
  sleep 2
done
ok "Superset restarted"

# ─── Step 8: Import dashboards ───
log "Step 8: Import dashboards, charts, datasets..."
if [ -f "$EXPORT_FILE" ]; then
  docker cp "$EXPORT_FILE" $CONTAINER_SS:/tmp/dashboard_export.zip
  
  docker exec $CONTAINER_SS /app/.venv/bin/superset import-dashboards \
    -p /tmp/dashboard_export.zip \
    -u $ADMIN_USER 2>/dev/null
  ok "Import thành công!"
else
  warn "Không tìm thấy $EXPORT_FILE → bỏ qua import"
  warn "Bạn có thể import thủ công qua Superset UI"
fi

# ─── Done ───
echo ""
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ DEPLOY THÀNH CÔNG!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo ""
echo -e "  🌐 Superset:  ${BLUE}http://localhost:8088${NC}"
echo -e "  👤 Login:     ${YELLOW}admin / admin${NC}"
echo -e "  🐘 PostgreSQL: localhost:5432"
echo -e "     DB: int1422_idb | User: int1422 | Pass: int1422_pass"
echo ""
echo -e "  📊 Dashboard: ${BLUE}INT1422 OLAP${NC} (19 charts đã import)"
echo ""
