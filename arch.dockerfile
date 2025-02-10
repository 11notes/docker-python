# :: Util
  FROM 11notes/util AS util

# :: Build / python3
  FROM 11notes/apk:stable AS build
  ARG APP_VERSION
  ENV ALPINE_VERSION=

  RUN set -ex; \
    case ${APP_VERSION} in \
      "3.11") ALPINE_VERSION=3.19;; \
      "3.12") ALPINE_VERSION=3.21;; \
    esac; \
    amake python3 ${ALPINE_VERSION};

# :: Header
  FROM 11notes/alpine:stable

  # :: arguments
    ARG TARGETARCH
    ARG APP_IMAGE
    ARG APP_NAME
    ARG APP_VERSION
    ARG APP_ROOT

  # :: environment
    ENV APP_IMAGE=${APP_IMAGE}
    ENV APP_NAME=${APP_NAME}
    ENV APP_VERSION=${APP_VERSION}
    ENV APP_ROOT=${APP_ROOT}
    ENV PYTHON_VERSION=

  # :: multi-stage
    COPY --from=util /usr/local/bin/ /usr/local/bin
    COPY --from=build /apk/ /apk

# :: Run
  USER root

  # :: install application
    RUN set -ex; \
      case ${APP_VERSION} in \
        "3.11") PYTHON_VERSION=3.11.11-r0;; \
        "3.12") PYTHON_VERSION=3.12.9-r0;; \
      esac; \
      apk --no-cache --allow-untrusted --repository /apk add \
        python3=${PYTHON_VERSION};

  # :: copy filesystem changes and set correct permissions
    RUN set -ex; \
      chmod +x -R /usr/local/bin; \
      chown -R 1000:1000 \
        /usr/local/bin;

# :: Start
  USER docker