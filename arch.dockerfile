# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID= \
      APP_GID= \
      APP_VERSION=0.0

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:tini AS distroless-tini


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: PYTHON
  FROM python:${APP_VERSION}-alpine AS build
  COPY --from=distroless / /
  COPY --from=distroless-tini / /

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
          PYTHONUNBUFFERED=1 \
          PIP_ROOT_USER_ACTION=ignore \
          PIP_BREAK_SYSTEM_PACKAGES=1 \
          PIP_DISABLE_PIP_VERSION_CHECK=1 \
          PIP_NO_CACHE_DIR=1 \
          PIP_FIND_LINKS="https://11notes.github.io/python-wheels/" \
          UV_NO_CACHE=true \
          UV_SYSTEM_PYTHON=true \
          UV_EXTRA_INDEX_URL="https://11notes.github.io/python-wheels/"

    # :: multi-stage
      COPY --from=build / /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/local/bin/python"]