# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# :: GLOBAL 
  ARG APP_VERSION=0

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: WHEEL
  FROM python:${APP_VERSION}-alpine AS build
  COPY --from=util-bin / /

  USER root

  RUN set -ex; \
    apk --no-cache --update add --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
      git \
      g++ \
      make \
      cmake \
      cargo \
      libtool \
      automake \
      autoconf \
      rust \
      build-base \
      binutils-gold \
      patchelf \
      linux-headers \
      openssl-dev \
      libffi-dev \
      zlib-dev;

  RUN set -ex; \
    pip install \
      gpep517 \
      pkgconfig \
      setuptools \
      setuptools-rust \
      maturin \
      wheel \
      virtualenv \
      cython \
      poetry \
      pur \
      auditwheel \
      uv;

  COPY ./rootfs/wheel/ /

  RUN set -ex; \
    chmod +x -R /usr/local/bin;

  RUN set -ex; \
    rm -rf /tmp/*; \
    mkdir -p /.dist;

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
      ENV PIP_NO_CACHE_DIR=0 \
          PYTHONDONTWRITEBYTECODE=1 \
          PYTHONUNBUFFERED=1 \
          PIP_ROOT_USER_ACTION=ignore \
          PIP_BREAK_SYSTEM_PACKAGES=1 \
          PIP_DISABLE_PIP_VERSION_CHECK=1 \
          UV_NO_CACHE=false \
          UV_SYSTEM_PYTHON=true \
          UV_EXTRA_INDEX_URL="https://11notes.github.io/python-wheels/"

    # :: multi-stage
      COPY --from=build / /

# :: EXECUTE
  USER root
  ENTRYPOINT ["/bin/ash"]