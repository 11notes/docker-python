# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

  # :: FOREIGN IMAGES
  FROM 11notes/util AS util

# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: HEADER
  FROM 11notes/alpine:stable

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

  # :: default python image
    ARG PIP_ROOT_USER_ACTION=ignore \
        PIP_BREAK_SYSTEM_PACKAGES=1 \
        PIP_DISABLE_PIP_VERSION_CHECK=1 \
        PIP_NO_CACHE_DIR=1

  # :: app specific arguments
    ARG EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000" \
        LANG=en_US

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: app specific environment
    ENV PYTHONDONTWRITEBYTECODE=1

  # :: multi-stage
    COPY --from=util /usr/local/bin /usr/local/bin

# :: RUN
  USER root

  # :: install dependencies
    RUN set -ex; \
      eleven printenv; \
      apk --no-cache --update --virtual .build add \
        tar \
        xz \
        bluez-dev \
        bzip2-dev \
        dpkg-dev \
        dpkg \
        findutils \
        gcc \
        gdbm-dev \
        libc-dev \
        libffi-dev \
        libnsl-dev \
        libtirpc-dev \
        linux-headers \
        make \
        ncurses-dev \
        openssl-dev \
        pax-utils \
        readline-dev \
        sqlite-dev \
        tcl-dev \
        tk \
        tk-dev \
        util-linux-dev \
        xz-dev \
        zlib-dev \
        musl-dev \
        musl-locales; \
      curl -SL https://www.python.org/ftp/python/${APP_VERSION}/Python-${APP_VERSION}.tar.xz | tar -xJC /; \
      cd /Python-${APP_VERSION}; \
      ./configure \
        --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
        --enable-loadable-sqlite-extensions \
        --enable-option-checking=fatal \
        --enable-shared \
        --with-lto \
        --with-ensurepip; \
      case "${TARGETARCH}${TARGETVARIANT}" in \
        "amd64"|"arm64") EXTRA_CFLAGS="${EXTRA_CFLAGS:-} -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer" ;;\
      esac; \
      eleven log info "EXTRA_CFLAGS=${EXTRA_CFLAGS}"; \
      make -s -j $(nproc) \
        EXTRA_CFLAGS="${EXTRA_CFLAGS}" \
        LDFLAGS="-Wl,--strip-all"; \
      rm python; \
      make -s -j $(nproc) \
        EXTRA_CFLAGS="${EXTRA_CFLAGS}" \
        LDFLAGS="-Wl,--strip-all,-rpath='\$\$ORIGIN/../lib'" \
        python; \
      make install; \
      rm -rf /Python-${APP_VERSION}; \
      cd /; \
      find /usr/local -depth \
        \( \
          \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
          -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
        \) -exec rm -rf '{}' + \
      ; \
      find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' \
        | tr ',' '\n' \
        | sort -u \
        | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
        | xargs -rt apk add --no-network --virtual .python-rundeps \
      ; \
      apk del --no-network .build; \
      for src in idle3 pip3 pydoc3 python3 python3-config; do \
        dst="$(echo "$src" | tr -d 3)"; \
        [ -s "/usr/local/bin/$src" ]; \
        [ ! -e "/usr/local/bin/$dst" ]; \
        ln -svT "$src" "/usr/local/bin/$dst"; \
      done;

  # :: copy root filesystem and set correct permissions
    RUN set -ex; \
      chmod +x -R /usr/local/bin;

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/bin/ash"]
  CMD ["python3"]