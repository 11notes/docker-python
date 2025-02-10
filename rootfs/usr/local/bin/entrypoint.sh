#!/bin/ash
  if [ -z "${1}" ]; then
    python3
  fi

  exec "$@"