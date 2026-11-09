#!/bin/sh
set -e

# Wait for the database to accept connections (when PostgreSQL is configured)
if [ -n "$POSTGRES_HOST" ]; then
    echo "Waiting for PostgreSQL at ${POSTGRES_HOST}:${POSTGRES_PORT:-5432}..."
    python - <<'EOF'
import os, sys, time
import psycopg

for attempt in range(30):
    try:
        psycopg.connect(
            host=os.environ["POSTGRES_HOST"],
            port=os.environ.get("POSTGRES_PORT", "5432"),
            dbname=os.environ.get("POSTGRES_DB", "polls"),
            user=os.environ.get("POSTGRES_USER", "polls"),
            password=os.environ.get("POSTGRES_PASSWORD", ""),
            connect_timeout=2,
        ).close()
        print("PostgreSQL is available")
        sys.exit(0)
    except psycopg.OperationalError:
        time.sleep(2)
print("PostgreSQL is unavailable - giving up", file=sys.stderr)
sys.exit(1)
EOF
fi

if [ "${DJANGO_RUN_MIGRATIONS:-true}" = "true" ]; then
    python manage.py migrate --noinput
fi

exec "$@"
