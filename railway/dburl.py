"""Print shell exports for KitchenOwl's DB_* settings from DATABASE_URL (postgres://user:pass@host:port/db)."""
import os, shlex
from urllib.parse import urlsplit, unquote

u = urlsplit(os.environ["DATABASE_URL"])
if u.scheme not in ("postgres", "postgresql"):
    raise SystemExit(f"railway-start: DATABASE_URL must be a postgres:// URL, got {u.scheme}://")
vals = {
    "DB_DRIVER": "postgresql+psycopg",
    "DB_HOST": u.hostname or "",
    "DB_PORT": str(u.port or 5432),
    "DB_NAME": (u.path or "/").lstrip("/") or "railway",
    "DB_USER": unquote(u.username or ""),
    "DB_PASSWORD": unquote(u.password or ""),
}
for k, v in vals.items():
    print(f"export {k}={shlex.quote(v)}")
