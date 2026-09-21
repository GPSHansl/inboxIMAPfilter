#!/bin/sh
set -eu

mkdir -p /var/lib/imapfilter

if [ ! -f /etc/imapfilter/config.lua ]; then
  echo "Missing /etc/imapfilter/config.lua" >&2
  exit 1
fi

if [ ! -f /etc/imapfilter/accounts.csv ]; then
  echo "Missing /etc/imapfilter/accounts.csv" >&2
  exit 1
fi

MODE="${1:-loop}"

case "$MODE" in
  once)
    echo "Running imapfilter once..."
    imapfilter -c /etc/imapfilter/config.lua || true
    echo "Finished one-off test run."
    ;;
  loop)
    while true; do
      echo "Running imapfilter..."
      imapfilter -c /etc/imapfilter/config.lua || true
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
