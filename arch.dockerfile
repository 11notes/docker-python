# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=3.13.5


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM python:${APP_VERSION}-alpine
  COPY ./rootfs /

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

# :: INSTALL
  ARG APP_NO_CACHE
  RUN set -ex; \
    apk --no-cache --update --repository https://dl-cdn.alpinelinux.org/alpine/edge/main add \
      sqlite-libs \
      ca-certificates \
      curl \
      tzdata; \
    apk --no-cache --update --repository https://dl-cdn.alpinelinux.org/alpine/edge/community add \
      shadow \
      tini; \
    apk --no-cache --update --repository https://dl-cdn.alpinelinux.org/alpine/edge/main \
      upgrade; \
    addgroup --gid 1000 -S docker; \
    adduser --uid 1000 -D -S -h ${APP_ROOT} -s /sbin/nologin -G docker docker; \
    chmod +x -R /usr/local/bin;

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]