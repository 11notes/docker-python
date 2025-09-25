# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# :: GLOBAL 
  ARG APP_VERSION=3.13

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: WHEEL
  FROM 11notes/python:${APP_VERSION} AS build
  COPY --from=util-bin / /

  USER root

  RUN set -ex; \
    apk --no-cache --update add \
      git \
      g++ \
      cargo \
      build-base \
      patchelf \
      linux-headers \
      openssl-dev \
      libffi-dev;

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
      auditwheel;

  COPY ./rootfs/wheel/ /

  RUN set -ex; \
    chmod +x -R /usr/local/bin;

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
      ENV PIP_NO_CACHE_DIR=0

    # :: multi-stage
      COPY --from=build / /

# :: EXECUTE
  USER root
  ENTRYPOINT ["/usr/local/bin/python"]