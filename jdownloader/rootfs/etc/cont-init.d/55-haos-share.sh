#!/bin/sh
#
# Create the download target folder on the HAOS share.
# Range 50-59 is the one the base image reserves for derived images.
#
set -e

DOWNLOAD_DIR="${DOWNLOAD_DIR:-/share/jdownloader}"

mkdir -p "$DOWNLOAD_DIR"
chown "${USER_ID:-0}:${GROUP_ID:-0}" "$DOWNLOAD_DIR"

echo "[cont-init.d] download folder ready: $DOWNLOAD_DIR"
