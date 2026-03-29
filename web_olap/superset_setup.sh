
set -e

CONTAINER="int1422_superset"
ADMIN_USER="admin"
ADMIN_PASS="admin"
ADMIN_EMAIL="admin@int1422.local"

sleep 10

docker exec -u root $CONTAINER pip install psycopg2-binary --target=/app/.venv/lib/python3.10/site-packages/ 2>/dev/null

docker exec $CONTAINER superset db upgrade

docker exec $CONTAINER superset fab create-admin \
  --username $ADMIN_USER \
  --firstname Admin \
  --lastname INT1422 \
  --email $ADMIN_EMAIL \
  --password $ADMIN_PASS 2>/dev/null || echo "Admin user đã tồn tại"

docker exec $CONTAINER superset init

