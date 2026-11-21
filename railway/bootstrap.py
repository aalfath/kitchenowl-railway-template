"""Run KitchenOwl's database migrations, then create the first admin account if there are no users.

KitchenOwl's own onboarding lets whoever opens the site first become admin. Creating the
admin here, before the web server starts, closes that window: once a user exists, the
onboarding endpoint refuses new admins.
"""
import os, sys

username = os.environ.get("KITCHENOWL_ADMIN_USERNAME", "admin").strip() or "admin"
password = os.environ.get("KITCHENOWL_ADMIN_PASSWORD", "")

from flask_migrate import upgrade  # noqa: E402
from app import app  # noqa: E402
from app.models import User  # noqa: E402

with app.app_context():
    upgrade(directory="/usr/src/kitchenowl/migrations")
    if User.count() > 0:
        print("railway-bootstrap: users exist, nothing to do", flush=True)
        sys.exit(0)
    if len(password) < 8:
        print("railway-bootstrap: no users yet and KITCHENOWL_ADMIN_PASSWORD is missing or shorter than 8 characters; "
              "set it on the KitchenOwl service and redeploy", file=sys.stderr, flush=True)
        sys.exit(1)
    User.create(username, password, "Admin", admin=True)
    print(f"railway-bootstrap: created admin account '{username.lower()}'", flush=True)
