# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=3.13.5

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:tini AS distroless-tini
  FROM 11notes/distroless:upx AS distroless-upx
  FROM 11notes/distroless:ds AS distroless-ds


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: PYTHON
  FROM python:${APP_VERSION}-alpine AS build
  COPY --from=distroless / /
  COPY --from=distroless-tini / /
  COPY --from=distroless-ds / /

  RUN set -ex; \
    find / -type f -executable -not -name "*.py" -not -name "*.so*" -exec /usr/local/bin/ds "{}" ";"; \
    /usr/local/bin/ds --bye;

# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM scratch

    # :: default arguments
      ARG TARGETPLATFORM \
          TARGETOS \
          TARGETARCH \
          TARGETVARIANT \
          APP_IMAGE \
          APP_NAME \
          APP_VERSION \
          APP_ROOT \
          APP_UID \
          APP_GID \
          APP_NO_CACHE

    # :: default environment
      ENV APP_IMAGE=${APP_IMAGE} \
          APP_NAME=${APP_NAME} \
          APP_VERSION=${APP_VERSION} \
          APP_ROOT=${APP_ROOT}

    # :: app specific environment
      ENV PYTHONDONTWRITEBYTECODE=1 \
          PYTHONUNBUFFERED=1

    # :: multi-stage
      COPY --from=build / /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/local/bin/python"]