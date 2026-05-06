# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=0.0


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: PYTHON
  FROM 11notes/alpine:stable AS build
  ARG APP_VERSION \
      BUILD_ROOT=/usr/src/python \
      BUILD_SRC=https://github.com/python/cpython.git
  USER root

  RUN set -eux; \
    apk --update --no-cache --virtual .build-deps add \
      bluez-dev \
      bzip2-dev \
      dpkg-dev dpkg \
      findutils \
      gcc \
      gdbm-dev \
      gnupg \
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
      tar \
      tcl-dev \
      tk \
      tk-dev \
      util-linux-dev \
      xz \
      xz-dev \
      zlib-dev \
      zstd-dev \
      git;

  RUN set -eux; \
    mkdir -p ${BUILD_ROOT}; \
    git clone ${BUILD_SRC} -b v${APP_VERSION} ${BUILD_ROOT};

  RUN set -eux; \
    cd ${BUILD_ROOT}; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    ./configure \
      --build="$gnuArch" \
      --enable-loadable-sqlite-extensions \
      --enable-option-checking=fatal \
      --enable-shared \
      $(test "${gnuArch%%-*}" != 'riscv64' && echo '--with-lto') \
      --with-ensurepip;

  RUN set -eux; \
    cd ${BUILD_ROOT}; \
    EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000"; \
    LDFLAGS="${LDFLAGS:-} -Wl,--strip-all"; \
    ARCH="$(apk --print-arch)"; \
    case "${ARCH}" in \
		  x86_64|aarch64) \
			  EXTRA_CFLAGS="${EXTRA_CFLAGS:-} -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer"; \
			  ;; \
		  *) \
			  EXTRA_CFLAGS="${EXTRA_CFLAGS:-} -fno-omit-frame-pointer"; \
			  ;; \
    esac; \
    make -s -j $(nproc) "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" "LDFLAGS=${LDFLAGS:-}" 2>&1 > /dev/null; \
    rm python; \
    make -s -j $(nproc) "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" "LDFLAGS=${LDFLAGS:-} -Wl,-rpath='\$\$ORIGIN/../lib'" python 2>&1 > /dev/null; \
    make install;

  RUN set -eux; \
    rm -rf /usr/src/python; \
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
    apk del --no-network .build-deps;

  RUN set -eux; \
    for src in idle3 pip3 pydoc3 python3 python3-config; do \
      dst="$(echo "$src" | tr -d 3)"; \
      [ -s "/usr/local/bin/$src" ]; \
      [ ! -e "/usr/local/bin/$dst" ]; \
      ln -svT "$src" "/usr/local/bin/$dst"; \
    done

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
          UV_EXTRA_INDEX_URL="https://11notes.github.io/python-wheels/" \
          PATH=/usr/local/bin:${PATH}

    # :: multi-stage
      COPY --from=build / /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/local/bin/python"]