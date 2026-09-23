#!/bin/sh
set -eu

IMAPFILTER_ROOT="/var/lib/imapfilter"
CONFIG_ROOT="/etc/imapfilter"
TEMPLATE_DIR="$IMAPFILTER_ROOT/config-template"

mkdir -p "$IMAPFILTER_ROOT" "$TEMPLATE_DIR"

if [ ! -d "$CONFIG_ROOT" ]; then
  echo "Missing $CONFIG_ROOT volume or bind mount. Please mount a writable directory or volume to $CONFIG_ROOT." >&2
  exit 1
fi

if [ -d "$TEMPLATE_DIR" ]; then
  for template in "$TEMPLATE_DIR"/*; do
    if [ -e "$template" ]; then
      target="$CONFIG_ROOT/$(basename "$template")"
      if [ ! -e "$target" ]; then
        cp -a "$template" "$target"
      fi
    fi
  done
fi

if [ ! -f "$IMAPFILTER_ROOT/config.lua" ]; then
  echo "Missing $IMAPFILTER_ROOT/config.lua" >&2
  exit 1
fi

if [ ! -f "$CONFIG_ROOT/accounts.csv" ]; then
  echo "Missing $CONFIG_ROOT/accounts.csv after initialization" >&2
  exit 1
fi

MODE="${1:-loop}"

case "$MODE" in
  once)
    echo "Running imapfilter once..."
    imapfilter -c "$IMAPFILTER_ROOT/config.lua" || true
    echo "Finished one-off test run."
    ;;
  loop)
    while true; do
      echo "Running imapfilter..."
      imapfilter -c "$IMAPFILTER_ROOT/config.lua" || true
      echo "Waiting ${IMAPFILTER_INTERVAL:-300}s before next run..."
      sleep "${IMAPFILTER_INTERVAL:-300}"
    done
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    echo "Usage: $0 [once|loop]" >&2
    exit 1
    ;;
esac
