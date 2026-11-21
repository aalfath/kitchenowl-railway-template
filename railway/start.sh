#!/bin/bash
# Railway wrapper for KitchenOwl: Postgres settings from DATABASE_URL, wait for the database,
# migrate, create the first admin, listen on $PORT, then hand over to the upstream entrypoint.
# Any failure exits non-zero so Railway's ON_FAILURE restart policy tries again.
set -euo pipefail
cd /usr/src/kitchenowl

export STORAGE_PATH="${STORAGE_PATH:-/data}"
PORT="${PORT:-8080}"

if [ -n "${DATABASE_URL:-}" ]; then
  eval "$(python /usr/local/lib/railway/dburl.py)"
  # libpq connect timeout: a database that disappears mid-start fails fast (and Railway restarts us)
  # instead of hanging until the health check gives up.
  export PGCONNECT_TIMEOUT="${PGCONNECT_TIMEOUT:-10}"
  echo "railway-start: using PostgreSQL at ${DB_HOST}:${DB_PORT}/${DB_NAME}"
  deadline=$(( $(date +%s) + ${DB_WAIT_SECONDS:-180} ))
  until python -c 'import os,psycopg; psycopg.connect(host=os.environ["DB_HOST"],port=os.environ["DB_PORT"],dbname=os.environ["DB_NAME"],user=os.environ["DB_USER"],password=os.environ["DB_PASSWORD"],connect_timeout=5).close()' 2>/dev/null; do
    if [ "$(date +%s)" -ge "$deadline" ]; then
      echo "railway-start: PostgreSQL did not answer in time" >&2; exit 1
    fi
    echo "railway-start: waiting for PostgreSQL..."; sleep 3
  done
else
  echo "railway-start: DATABASE_URL not set, using SQLite in ${STORAGE_PATH}"
fi

# Listen on Railway's PORT (upstream hard-codes 8080).
sed -i -E "s/^http = (\[::\])?:[0-9]+$/http = \1:${PORT}/" wsgi.ini

mkdir -p "$STORAGE_PATH/upload"
chown -R kitchenowl:kitchenowl "$STORAGE_PATH"
gosu kitchenowl env PYTHONPATH=/usr/src/kitchenowl python /usr/local/lib/railway/bootstrap.py

# Migrations + first admin in one Python process (railway/bootstrap.py).
# The upstream entrypoint then runs the (now no-op) migration again, updates default items, then execs uWSGI.
exec ./entrypoint.sh "$@"
