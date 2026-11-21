# KitchenOwl for Railway: the official all-in-one image (backend + web app), pinned by version and digest.
FROM tombursch/kitchenowl:v0.8.1@sha256:6a048135399691da25aec04ea107666cb7ce8eb46f5fed9a46a5ac254fe23073

# Keep numpy/BLAS and tokenizers to the service's own CPUs (Railway's small plans have 1 vCPU / 0.5 GB).
ENV OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    NUMEXPR_MAX_THREADS=1 \
    TOKENIZERS_PARALLELISM=false \
    PYTHONUNBUFFERED=1

COPY --chmod=755 railway/start.sh /usr/local/bin/railway-start
COPY railway/bootstrap.py railway/dburl.py /usr/local/lib/railway/

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-start"]
CMD ["--ini", "wsgi.ini:web", "--gevent", "200", "--max-fd", "1048576"]
