# KitchenOwl for Railway: the official all-in-one image (backend + web app), pinned by version and digest.
FROM tombursch/kitchenowl:v0.8.1@sha256:6a048135399691da25aec04ea107666cb7ce8eb46f5fed9a46a5ac254fe23073

# Keep numpy/BLAS and tokenizers to the service's own CPUs (Railway's small plans have 1 vCPU / 0.5 GB).
ENV OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    NUMEXPR_MAX_THREADS=1 \
    TOKENIZERS_PARALLELISM=false \
    PYTHONUNBUFFERED=1 \
    MALLOC_ARENA_MAX=2

# Import litellm only when an LLM feature is actually used (LLM_MODEL set). Upstream imports it at
# start-up, which costs about 165 MB of RAM per worker even when no LLM is configured. The build
# fails if upstream's import line changes, so a version bump can't silently drop this.
RUN set -e; cd /usr/src/kitchenowl/app/service; \
    for f in ingredient_parsing.py recipe_generation.py recipe_public_scraping.py; do \
      grep -qx 'from litellm import completion' "$f"; \
      sed -i 's/^from litellm import completion$/def completion(*args, **kwargs):\n    from litellm import completion as _completion\n    return _completion(*args, **kwargs)/' "$f"; \
    done; \
    ! grep -rq '^from litellm\|^import litellm' /usr/src/kitchenowl/app

COPY --chmod=755 railway/start.sh /usr/local/bin/railway-start
COPY railway/bootstrap.py railway/dburl.py /usr/local/lib/railway/

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-start"]
CMD ["--ini", "wsgi.ini:web", "--gevent", "200", "--max-fd", "1048576"]
