# Changelog

Breaking changes are listed first in each entry.

## v0.8.1 (2026-11-21)

First release of this template.

- KitchenOwl v0.8.1 from the official image `tombursch/kitchenowl:v0.8.1@sha256:6a048135399691da25aec04ea107666cb7ce8eb46f5fed9a46a5ac254fe23073`.
- Railway Postgres through `DATABASE_URL`, uploads on the `/data` volume.
- The admin account (`admin`, password from `KITCHENOWL_ADMIN_PASSWORD`) is created before the web server starts, so the public onboarding screen is never open.
- Sized for 0.5 GB services: `litellm` is imported only when an LLM feature is used, `MALLOC_ARENA_MAX=2`, math libraries on one thread. Setup failures exit non-zero so Railway restarts the service.
