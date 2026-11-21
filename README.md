[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/kitchenowl-1?utm_medium=integration&utm_source=button&utm_campaign=kitchenowl)

# KitchenOwl on Railway

One-click [KitchenOwl](https://kitchenowl.org) for [Railway](https://railway.com): a self-hosted grocery list, recipe manager, meal planner and expense tracker for households. Built from the official [`tombursch/kitchenowl`](https://hub.docker.com/r/tombursch/kitchenowl) all-in-one image ([TomBursch/kitchenowl](https://github.com/TomBursch/kitchenowl)).

- **KitchenOwl v0.8.1**, pinned as `tombursch/kitchenowl:v0.8.1@sha256:6a048135399691da25aec04ea107666cb7ce8eb46f5fed9a46a5ac254fe23073` (Flask backend under uWSGI plus the Flutter web app).
- **PostgreSQL**: Railway's own Postgres service, reached over the private network.

## What the template deploys

| Service | What it does | Volume |
|---|---|---|
| **KitchenOwl** (this repo) | Web app and API on Railway's `PORT` (8080), public domain, health check `/api/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V` | `/data`: uploaded photos (`/data/upload`) |
| **Postgres** | Database: users, households, shopping lists, recipes, meal plans, expenses | `/var/lib/postgresql/data` |

On every boot the wrapper (`railway/start.sh`) reads `DATABASE_URL`, waits for Postgres, runs KitchenOwl's database migrations, and on the first boot creates the admin account before the web server starts. KitchenOwl's own onboarding screen would otherwise let whoever opens the URL first become the admin; with an account already in place, that screen is closed.

## After deploying

1. Open the KitchenOwl service's public URL.
2. Log in as **admin**. The password is the `KITCHENOWL_ADMIN_PASSWORD` value on the KitchenOwl service's **Variables** tab.
3. Create your household, then add the other members under **Settings → Server → Users** (public sign-up is off).
4. Change the admin password under **Settings → Profile** if you like. Changing the variable afterwards does not change the password: it is only used when the database has no users yet.

The Android and iOS apps work too: enter your Railway URL as the server address.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `PORT` | `8080` | Port uWSGI listens on |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Database connection, read on every boot |
| `FRONT_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL, used for links in emails, CORS and OIDC redirects |
| `JWT_SECRET_KEY` | `${{secret(64)}}` | Signs login sessions; changing it logs everyone out |
| `KITCHENOWL_ADMIN_USERNAME` | `admin` | Admin login created on the first boot |
| `KITCHENOWL_ADMIN_PASSWORD` | `${{secret(24, …)}}` | Admin password, first boot only |

Optional, not in the template (add them on the KitchenOwl service, see [KitchenOwl's advanced options](https://docs.kitchenowl.org/latest/self-hosting/advanced/)): `OPEN_REGISTRATION=true` to let anyone sign up, `SMTP_HOST`/`SMTP_PORT`/`SMTP_USER`/`SMTP_PASS`/`SMTP_FROM` for password-reset and verification emails, `OIDC_ISSUER`/`OIDC_CLIENT_ID`/`OIDC_CLIENT_SECRET` for single sign-on, and `LLM_MODEL` plus a provider key (for example `OPENAI_API_KEY`) for AI ingredient parsing and recipe generation.

## Resources

Runs on Railway's smallest plans (0.5 GB RAM, 1 vCPU per service). Upstream loads the LLM library (`litellm`) at start-up even when no LLM is configured, which puts one worker at about 430 MB; this image loads it only when an LLM feature is used, so KitchenOwl idles at about 280 MB and peaked at about 300 MB in our tests. Math libraries are limited to one thread. If you turn on `LLM_MODEL`, give the service 1 GB.

If setup fails (for example Postgres never answers, or there is no admin password on a fresh database), the container exits with an error, so Railway's restart policy tries again.

## Updates

Each new KitchenOwl release is a commit to `main` here: a new pinned version and digest, plus an entry in [CHANGELOG.md](CHANGELOG.md), with breaking changes first. Railway shows deployers an "update available" notice; when you apply it, the new image runs KitchenOwl's database migrations on start. Your data stays in Postgres and on the `/data` volume. Back up both before a large version jump.

## Files

- `Dockerfile`: the pinned official image, the lazy `litellm` import patch and the wrapper below.
- `railway/start.sh`: Postgres settings from `DATABASE_URL`, wait for the database, migrations, first admin, `PORT`, then upstream's entrypoint.
- `railway/dburl.py`: turns `DATABASE_URL` into KitchenOwl's `DB_*` settings.
- `railway/bootstrap.py`: creates the admin account when the database has no users.

Licence: KitchenOwl is AGPL-3.0. This wrapper is provided under the same licence.
