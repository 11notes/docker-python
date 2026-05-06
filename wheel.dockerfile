# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# :: GLOBAL 
  ARG APP_VERSION=0.0

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: WHEEL
  FROM 11notes/python:${APP_VERSION} AS build
  COPY --from=util-bin / /
  ENV UV_SYSTEM_PYTHON=true
  USER root

  RUN set -ex; \
    apk --no-cache --update --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community add \
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
      zlib-dev \
      ninja;

  RUN set -ex; \
    pip install \
      -f https://11notes.github.io/python-wheels/ \
      uv;

  RUN set -ex; \
    uv pip install \
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
      ninja \
      meson;

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
      ENV PYTHONDONTWRITEBYTECODE=1 \
          PYTHONUNBUFFERED=1 \
          PIP_ROOT_USER_ACTION=ignore \
          PIP_BREAK_SYSTEM_PACKAGES=1 \
          PIP_DISABLE_PIP_VERSION_CHECK=1 \
          PIP_NO_CACHE_DIR=0 \
          PIP_FIND_LINKS="https://11notes.github.io/python-wheels/" \
          UV_NO_CACHE=false \
          UV_SYSTEM_PYTHON=true \
          UV_EXTRA_INDEX_URL="https://11notes.github.io/python-wheels/"

    # :: multi-stage
      COPY --from=build / /

# :: EXECUTE
  USER root
  ENTRYPOINT ["/bin/ash"]